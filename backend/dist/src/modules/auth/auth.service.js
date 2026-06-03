"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const prisma_service_1 = require("../../prisma/prisma.service");
const bcrypt = require("bcryptjs");
const client_1 = require("@prisma/client");
let AuthService = class AuthService {
    constructor(prisma, jwtService) {
        this.prisma = prisma;
        this.jwtService = jwtService;
    }
    async login(dto) {
        const user = await this.prisma.user.findFirst({
            where: { email: dto.email, isActive: true, deletedAt: null },
            include: { organization: true },
        });
        if (!user) {
            throw new common_1.UnauthorizedException('Kredensial login salah atau akun tidak aktif.');
        }
        const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
        if (!isPasswordValid) {
            throw new common_1.UnauthorizedException('Kredensial login salah.');
        }
        const payload = {
            userId: user.id,
            email: user.email,
            role: user.role,
            organizationId: user.organizationId,
        };
        const token = await this.jwtService.signAsync(payload);
        return {
            accessToken: token,
            user: {
                id: user.id,
                email: user.email,
                fullName: user.fullName,
                role: user.role,
                avatarUrl: user.avatarUrl,
            },
            organization: {
                id: user.organization.id,
                name: user.organization.name,
                slug: user.organization.slug,
                logoUrl: user.organization.logoUrl,
                brandColor: user.organization.brandColor,
            },
        };
    }
    async registerOrganization(dto) {
        const existingOrg = await this.prisma.organization.findUnique({
            where: { slug: dto.orgSlug },
        });
        if (existingOrg) {
            throw new common_1.ConflictException('Slug organisasi sudah terdaftar. Gunakan slug lain.');
        }
        const existingUser = await this.prisma.user.findFirst({
            where: { email: dto.adminEmail },
        });
        if (existingUser) {
            throw new common_1.ConflictException('Email administrator sudah digunakan.');
        }
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(dto.adminPassword, saltRounds);
        const result = await this.prisma.$transaction(async (tx) => {
            const org = await tx.organization.create({
                data: {
                    name: dto.orgName,
                    slug: dto.orgSlug.toLowerCase(),
                    address: dto.orgAddress,
                    contact: dto.orgContact,
                },
            });
            const user = await tx.user.create({
                data: {
                    organizationId: org.id,
                    email: dto.adminEmail,
                    passwordHash,
                    role: client_1.UserRole.ORG_ADMIN,
                    fullName: dto.adminFullName,
                },
            });
            return { org, user };
        });
        return {
            message: 'Organisasi dan Administrator berhasil didaftarkan.',
            organizationId: result.org.id,
            slug: result.org.slug,
        };
    }
    async createClassroom(tenantId, dto) {
        return this.prisma.classRoom.create({
            data: {
                organizationId: tenantId,
                name: dto.name,
            },
        });
    }
    async getClassrooms(tenantId) {
        return this.prisma.classRoom.findMany({
            where: { organizationId: tenantId, deletedAt: null },
            include: { homeroomTeacher: { include: { user: true } } },
        });
    }
    async createTeacher(tenantId, dto) {
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(dto.password, saltRounds);
        return this.prisma.$transaction(async (tx) => {
            const user = await tx.user.create({
                data: {
                    organizationId: tenantId,
                    email: dto.email,
                    passwordHash,
                    role: client_1.UserRole.TEACHER,
                    fullName: dto.fullName,
                },
            });
            const teacher = await tx.teacher.create({
                data: {
                    organizationId: tenantId,
                    userId: user.id,
                    employeeNumber: dto.employeeNumber,
                },
            });
            if (dto.classRoomId) {
                await tx.classRoom.update({
                    where: { id: dto.classRoomId },
                    data: { homeroomTeacherId: teacher.id },
                });
            }
            return teacher;
        });
    }
    async getTeachers(tenantId) {
        return this.prisma.teacher.findMany({
            where: { organizationId: tenantId, deletedAt: null },
            include: { user: true },
        });
    }
    async createStudent(tenantId, dto) {
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(dto.password, saltRounds);
        return this.prisma.$transaction(async (tx) => {
            const user = await tx.user.create({
                data: {
                    organizationId: tenantId,
                    email: dto.email,
                    passwordHash,
                    role: client_1.UserRole.STUDENT,
                    fullName: dto.fullName,
                },
            });
            const student = await tx.student.create({
                data: {
                    organizationId: tenantId,
                    userId: user.id,
                    classRoomId: dto.classRoomId,
                    studentIdNumber: dto.studentIdNumber,
                },
            });
            return student;
        });
    }
    async getStudents(tenantId) {
        return this.prisma.student.findMany({
            where: { organizationId: tenantId, deletedAt: null },
            include: { user: true, classRoom: true },
        });
    }
    async updateClassroom(tenantId, id, dto) {
        return this.prisma.classRoom.update({
            where: { id, organizationId: tenantId },
            data: { name: dto.name },
        });
    }
    async deleteClassroom(tenantId, id) {
        return this.prisma.classRoom.update({
            where: { id, organizationId: tenantId },
            data: { deletedAt: new Date() },
        });
    }
    async updateTeacher(tenantId, id, dto) {
        return this.prisma.$transaction(async (tx) => {
            const teacher = await tx.teacher.findUnique({ where: { id, organizationId: tenantId } });
            if (!teacher)
                throw new common_1.UnauthorizedException('Teacher not found');
            await tx.user.update({
                where: { id: teacher.userId },
                data: {
                    fullName: dto.fullName,
                    email: dto.email,
                    ...(dto.password ? { passwordHash: await bcrypt.hash(dto.password, 10) } : {}),
                },
            });
            const updatedTeacher = await tx.teacher.update({
                where: { id },
                data: { employeeNumber: dto.employeeNumber },
            });
            if (dto.classRoomId) {
                await tx.classRoom.update({
                    where: { id: dto.classRoomId },
                    data: { homeroomTeacherId: teacher.id },
                });
            }
            return updatedTeacher;
        });
    }
    async deleteTeacher(tenantId, id) {
        return this.prisma.$transaction(async (tx) => {
            const teacher = await tx.teacher.update({
                where: { id, organizationId: tenantId },
                data: { deletedAt: new Date() },
            });
            await tx.user.update({
                where: { id: teacher.userId },
                data: { deletedAt: new Date() },
            });
            return teacher;
        });
    }
    async updateStudent(tenantId, id, dto) {
        return this.prisma.$transaction(async (tx) => {
            const student = await tx.student.findUnique({ where: { id, organizationId: tenantId } });
            if (!student)
                throw new common_1.UnauthorizedException('Student not found');
            await tx.user.update({
                where: { id: student.userId },
                data: {
                    fullName: dto.fullName,
                    email: dto.email,
                    ...(dto.password ? { passwordHash: await bcrypt.hash(dto.password, 10) } : {}),
                },
            });
            return tx.student.update({
                where: { id },
                data: {
                    classRoomId: dto.classRoomId,
                    studentIdNumber: dto.studentIdNumber,
                },
            });
        });
    }
    async deleteStudent(tenantId, id) {
        return this.prisma.$transaction(async (tx) => {
            const student = await tx.student.update({
                where: { id, organizationId: tenantId },
                data: { deletedAt: new Date() },
            });
            await tx.user.update({
                where: { id: student.userId },
                data: { deletedAt: new Date() },
            });
            return student;
        });
    }
    async getProfile(userId) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            include: {
                organization: true,
                studentProfile: { include: { classRoom: true } },
                teacherProfile: true,
            },
        });
        if (!user) {
            throw new common_1.NotFoundException('User tidak ditemukan.');
        }
        return {
            id: user.id,
            email: user.email,
            fullName: user.fullName,
            role: user.role,
            avatarUrl: user.avatarUrl,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            organization: {
                id: user.organization.id,
                name: user.organization.name,
                slug: user.organization.slug,
                logoUrl: user.organization.logoUrl,
                brandColor: user.organization.brandColor,
                address: user.organization.address,
                contact: user.organization.contact,
                createdAt: user.organization.createdAt,
            },
        };
    }
    async updateProfile(userId, dto) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (!user) {
            throw new common_1.NotFoundException('User tidak ditemukan.');
        }
        if (dto.email && dto.email !== user.email) {
            const existingUser = await this.prisma.user.findFirst({
                where: {
                    email: dto.email,
                    organizationId: user.organizationId,
                    id: { not: userId },
                },
            });
            if (existingUser) {
                throw new common_1.ConflictException('Email sudah digunakan oleh pengguna lain.');
            }
        }
        const updatedUser = await this.prisma.user.update({
            where: { id: userId },
            data: {
                ...(dto.fullName !== undefined ? { fullName: dto.fullName } : {}),
                ...(dto.email !== undefined ? { email: dto.email } : {}),
                ...(dto.avatarUrl !== undefined ? { avatarUrl: dto.avatarUrl } : {}),
            },
        });
        return {
            message: 'Profil berhasil diperbarui.',
            user: {
                id: updatedUser.id,
                email: updatedUser.email,
                fullName: updatedUser.fullName,
                avatarUrl: updatedUser.avatarUrl,
                role: updatedUser.role,
            },
        };
    }
    async changePassword(userId, oldPassword, newPassword) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (!user) {
            throw new common_1.NotFoundException('User tidak ditemukan.');
        }
        const isOldPasswordValid = await bcrypt.compare(oldPassword, user.passwordHash);
        if (!isOldPasswordValid) {
            throw new common_1.BadRequestException('Password lama tidak sesuai.');
        }
        const newPasswordHash = await bcrypt.hash(newPassword, 10);
        await this.prisma.user.update({
            where: { id: userId },
            data: { passwordHash: newPasswordHash },
        });
        return { message: 'Password berhasil diubah.' };
    }
    async deleteOrganization(id) {
        return this.prisma.organization.update({
            where: { id },
            data: { isActive: false },
        });
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        jwt_1.JwtService])
], AuthService);
//# sourceMappingURL=auth.service.js.map