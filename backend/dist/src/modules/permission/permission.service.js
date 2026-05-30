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
exports.PermissionService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
let PermissionService = class PermissionService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async onModuleInit() {
        console.log('--- DATABASE AUTO-RECONCILIATION FOR ORG_ADMIN STARTED ---');
        try {
            await this.prisma.$executeRawUnsafe('ALTER TABLE "ApprovalLog" ALTER COLUMN "teacherId" DROP NOT NULL;');
            console.log('SUCCESS: Table "ApprovalLog" updated! Column "teacherId" is optional.');
        }
        catch (err) {
            console.log('Database auto-reconciliation message:', err.message);
        }
    }
    async create(tenantId, userId, userRole, dto) {
        const student = await this.prisma.student.findUnique({
            where: { userId },
        });
        if (!student || userRole !== client_1.UserRole.STUDENT) {
            throw new common_1.ForbiddenException('Hanya siswa yang dapat mengajukan surat izin.');
        }
        const permission = await this.prisma.$transaction(async (tx) => {
            const request = await tx.permissionRequest.create({
                data: {
                    organizationId: tenantId,
                    studentId: student.id,
                    type: dto.type,
                    status: client_1.PermissionStatus.PENDING,
                    reason: dto.reason,
                    startDate: new Date(dto.startDate),
                    endDate: new Date(dto.endDate),
                },
            });
            if (dto.attachments && dto.attachments.length > 0) {
                await tx.permissionAttachment.createMany({
                    data: dto.attachments.map((file) => ({
                        permissionRequestId: request.id,
                        fileUrl: file.fileUrl,
                        fileName: file.fileName,
                        fileSize: file.fileSize,
                    })),
                });
            }
            await tx.auditLog.create({
                data: {
                    organizationId: tenantId,
                    userId,
                    action: 'CREATE_PERMISSION_REQUEST',
                    details: JSON.stringify({
                        requestId: request.id,
                        type: request.type,
                        startDate: request.startDate,
                        endDate: request.endDate,
                    }),
                },
            });
            return request;
        });
        return {
            message: 'Pengajuan izin berhasil dibuat.',
            permissionId: permission.id,
        };
    }
    async findAll(tenantId, userId, role) {
        if (role === client_1.UserRole.STUDENT) {
            const student = await this.prisma.student.findUnique({ where: { userId } });
            if (!student)
                return [];
            return this.prisma.permissionRequest.findMany({
                where: { organizationId: tenantId, studentId: student.id, deletedAt: null },
                include: { attachments: true, approvals: { include: { teacher: { include: { user: true } } } } },
                orderBy: { createdAt: 'desc' },
            });
        }
        if (role === client_1.UserRole.TEACHER) {
            const teacher = await this.prisma.teacher.findUnique({ where: { userId } });
            if (!teacher)
                return [];
            return this.prisma.permissionRequest.findMany({
                where: {
                    organizationId: tenantId,
                    deletedAt: null,
                    student: {
                        classRoom: { homeroomTeacherId: teacher.id },
                    },
                },
                include: { student: { include: { user: true, classRoom: true } }, attachments: true },
                orderBy: { createdAt: 'desc' },
            });
        }
        return this.prisma.permissionRequest.findMany({
            where: { organizationId: tenantId, deletedAt: null },
            include: { student: { include: { user: true, classRoom: true } }, attachments: true },
            orderBy: { createdAt: 'desc' },
        });
    }
    async findOne(tenantId, id) {
        const request = await this.prisma.permissionRequest.findFirst({
            where: { id, organizationId: tenantId, deletedAt: null },
            include: {
                student: { include: { user: true, classRoom: true } },
                attachments: true,
                approvals: { include: { teacher: { include: { user: true } } } },
            },
        });
        if (!request) {
            throw new common_1.NotFoundException('Pengajuan izin tidak ditemukan.');
        }
        return request;
    }
    async approve(tenantId, id, teacherUserId, dto) {
        console.log(`[APPROVE] Starting approval for permission=${id}, user=${teacherUserId}, tenant=${tenantId}`);
        const request = await this.prisma.permissionRequest.findFirst({
            where: { id, organizationId: tenantId, deletedAt: null },
            include: { student: { include: { user: true, classRoom: true } } },
        });
        if (!request) {
            throw new common_1.NotFoundException('Pengajuan izin tidak ditemukan.');
        }
        if (request.status !== client_1.PermissionStatus.PENDING) {
            throw new common_1.BadRequestException('Pengajuan izin sudah tidak berstatus pending.');
        }
        const teacher = await this.prisma.teacher.findUnique({
            where: { userId: teacherUserId },
        });
        let approverName = 'Wali Kelas / Guru';
        let teacherId = null;
        if (teacher) {
            teacherId = teacher.id;
            const user = await this.prisma.user.findUnique({ where: { id: teacherUserId } });
            if (user)
                approverName = user.fullName;
            console.log(`[APPROVE] Approver is TEACHER: ${approverName} (teacherId=${teacherId})`);
        }
        else {
            const user = await this.prisma.user.findUnique({
                where: { id: teacherUserId },
            });
            if (!user || user.role !== client_1.UserRole.ORG_ADMIN) {
                throw new common_1.ForbiddenException('Hanya pengajar terdaftar atau admin lembaga yang bisa memberikan persetujuan.');
            }
            approverName = user.fullName;
            console.log(`[APPROVE] Approver is ORG_ADMIN: ${approverName} (no teacherId)`);
        }
        try {
            return await this.prisma.$transaction(async (tx) => {
                console.log('[APPROVE] Step 1: Updating status to APPROVED...');
                await tx.permissionRequest.update({
                    where: { id },
                    data: { status: client_1.PermissionStatus.APPROVED },
                });
                console.log(`[APPROVE] Step 2: Creating ApprovalLog via raw SQL (teacherId=${teacherId})...`);
                const approvalLogId = require('crypto').randomUUID();
                await tx.$executeRawUnsafe(`INSERT INTO "ApprovalLog" ("id", "permissionRequestId", "teacherId", "status", "note", "createdAt") VALUES ($1, $2, $3, $4::\"PermissionStatus\", $5, NOW())`, approvalLogId, id, teacherId, client_1.PermissionStatus.APPROVED, dto.note || null);
                const logId = approvalLogId;
                console.log(`[APPROVE] Step 2 done: approvalLogId=${logId}`);
                const uniqueSuffix = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
                const className = request.student?.classRoom?.name || 'UMUM';
                const letterNumber = `${uniqueSuffix.toUpperCase()}/IZIN-FLOW/${className}/${new Date().getFullYear()}`;
                console.log(`[APPROVE] Step 3: Creating GeneratedLetter (letterNumber=${letterNumber})...`);
                await tx.generatedLetter.create({
                    data: {
                        organizationId: tenantId,
                        permissionRequestId: id,
                        letterNumber,
                        pdfUrl: `/letters/${id}/download`,
                    },
                });
                console.log('[APPROVE] Step 3 done.');
                console.log('[APPROVE] Step 4: Creating notification...');
                await tx.notification.create({
                    data: {
                        organizationId: tenantId,
                        userId: request.student.userId,
                        title: 'Izin Disetujui! 🎉',
                        body: `Pengajuan izin Anda (${request.type}) telah disetujui oleh ${approverName}. Surat izin digital siap diunduh.`,
                    },
                });
                console.log('[APPROVE] Step 5: Creating AuditLog...');
                await tx.auditLog.create({
                    data: {
                        organizationId: tenantId,
                        userId: teacherUserId,
                        action: 'APPROVE_PERMISSION',
                        details: JSON.stringify({ requestId: id, approvalLogId: logId }),
                    },
                });
                console.log('[APPROVE] ✅ Transaction completed successfully!');
                return {
                    message: 'Pengajuan izin berhasil disetujui.',
                    status: client_1.PermissionStatus.APPROVED,
                };
            });
        }
        catch (error) {
            console.error('[APPROVE] ❌ Transaction FAILED with error:');
            console.error('[APPROVE] Error name:', error.name);
            console.error('[APPROVE] Error message:', error.message);
            console.error('[APPROVE] Error code:', error.code);
            console.error('[APPROVE] Error meta:', JSON.stringify(error.meta || {}));
            console.error('[APPROVE] Full error:', error);
            throw error;
        }
    }
    async reject(tenantId, id, teacherUserId, dto) {
        const request = await this.prisma.permissionRequest.findFirst({
            where: { id, organizationId: tenantId, deletedAt: null },
            include: { student: true },
        });
        if (!request) {
            throw new common_1.NotFoundException('Pengajuan izin tidak ditemukan.');
        }
        if (request.status !== client_1.PermissionStatus.PENDING) {
            throw new common_1.BadRequestException('Pengajuan izin sudah tidak berstatus pending.');
        }
        const teacher = await this.prisma.teacher.findUnique({
            where: { userId: teacherUserId },
        });
        let approverName = 'Wali Kelas / Guru';
        let teacherId = null;
        if (teacher) {
            teacherId = teacher.id;
            const user = await this.prisma.user.findUnique({ where: { id: teacherUserId } });
            if (user)
                approverName = user.fullName;
        }
        else {
            const user = await this.prisma.user.findUnique({
                where: { id: teacherUserId },
            });
            if (!user || user.role !== client_1.UserRole.ORG_ADMIN) {
                throw new common_1.ForbiddenException('Hanya pengajar terdaftar atau admin lembaga yang bisa memberikan penolakan.');
            }
            approverName = user.fullName;
        }
        return this.prisma.$transaction(async (tx) => {
            await tx.permissionRequest.update({
                where: { id },
                data: { status: client_1.PermissionStatus.REJECTED },
            });
            const approvalLogId = require('crypto').randomUUID();
            await tx.$executeRawUnsafe(`INSERT INTO "ApprovalLog" ("id", "permissionRequestId", "teacherId", "status", "note", "createdAt") VALUES ($1, $2, $3, $4::\"PermissionStatus\", $5, NOW())`, approvalLogId, id, teacherId, client_1.PermissionStatus.REJECTED, dto.note || null);
            const logId = approvalLogId;
            await tx.notification.create({
                data: {
                    organizationId: tenantId,
                    userId: request.student.userId,
                    title: 'Izin Ditolak ❌',
                    body: `Pengajuan izin Anda (${request.type}) telah ditolak oleh ${approverName}. Alasan: ${dto.note || '-'}`,
                },
            });
            await tx.auditLog.create({
                data: {
                    organizationId: tenantId,
                    userId: teacherUserId,
                    action: 'REJECT_PERMISSION',
                    details: JSON.stringify({ requestId: id, approvalLogId: logId }),
                },
            });
            return {
                message: 'Pengajuan izin berhasil ditolak.',
                status: client_1.PermissionStatus.REJECTED,
            };
        });
    }
    async getOrgStats(tenantId) {
        const [students, teachers, pending, approved, rejected] = await Promise.all([
            this.prisma.student.count({ where: { organizationId: tenantId, deletedAt: null } }),
            this.prisma.teacher.count({ where: { organizationId: tenantId, deletedAt: null } }),
            this.prisma.permissionRequest.count({ where: { organizationId: tenantId, status: client_1.PermissionStatus.PENDING, deletedAt: null } }),
            this.prisma.permissionRequest.count({ where: { organizationId: tenantId, status: client_1.PermissionStatus.APPROVED, deletedAt: null } }),
            this.prisma.permissionRequest.count({ where: { organizationId: tenantId, status: client_1.PermissionStatus.REJECTED, deletedAt: null } }),
        ]);
        return {
            totalStudents: students,
            totalTeachers: teachers,
            pendingCount: pending,
            approvedCount: approved,
            rejectedCount: rejected,
        };
    }
    async getGlobalStats() {
        const [orgs, users, letters, pending, approved] = await Promise.all([
            this.prisma.organization.count({ where: { isActive: true } }),
            this.prisma.user.count({ where: { isActive: true, deletedAt: null } }),
            this.prisma.generatedLetter.count(),
            this.prisma.permissionRequest.count({ where: { status: client_1.PermissionStatus.PENDING, deletedAt: null } }),
            this.prisma.permissionRequest.count({ where: { status: client_1.PermissionStatus.APPROVED, deletedAt: null } }),
        ]);
        const organizations = await this.prisma.organization.findMany({
            orderBy: { createdAt: 'desc' },
            take: 10,
        });
        return {
            totalOrganizations: orgs,
            totalUsers: users,
            totalLettersGenerated: letters,
            totalPendingRequests: pending,
            totalApprovedRequests: approved,
            organizations,
        };
    }
};
exports.PermissionService = PermissionService;
exports.PermissionService = PermissionService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PermissionService);
//# sourceMappingURL=permission.service.js.map