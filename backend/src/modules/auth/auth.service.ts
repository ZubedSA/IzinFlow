import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterOrgDto } from './dto/register-org.dto';
import * as bcrypt from 'bcryptjs';
import { UserRole } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async login(dto: LoginDto) {
    // 1. Fetch user by email (Global lookup across domains)
    const user = await this.prisma.user.findFirst({
      where: { email: dto.email, isActive: true, deletedAt: null },
      include: { organization: true },
    });

    if (!user) {
      throw new UnauthorizedException('Kredensial login salah atau akun tidak aktif.');
    }

    // 2. Validate password
    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Kredensial login salah.');
    }

    // 3. Issue JSON Web Token (JWT)
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

  async registerOrganization(dto: RegisterOrgDto) {
    // 1. Check if organization slug is already taken
    const existingOrg = await this.prisma.organization.findUnique({
      where: { slug: dto.orgSlug },
    });

    if (existingOrg) {
      throw new ConflictException('Slug organisasi sudah terdaftar. Gunakan slug lain.');
    }

    // 2. Check if admin email already registered in this organization scope
    const existingUser = await this.prisma.user.findFirst({
      where: { email: dto.adminEmail },
    });

    if (existingUser) {
      throw new ConflictException('Email administrator sudah digunakan.');
    }

    // 3. Hash administrator password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(dto.adminPassword, saltRounds);

    // 4. Create Organization and Administrator transactionally
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
          role: UserRole.ORG_ADMIN,
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

  async createClassroom(tenantId: string, dto: any) {
    return this.prisma.classRoom.create({
      data: {
        organizationId: tenantId,
        name: dto.name,
      },
    });
  }

  async getClassrooms(tenantId: string) {
    return this.prisma.classRoom.findMany({
      where: { organizationId: tenantId, deletedAt: null },
      include: { homeroomTeacher: { include: { user: true } } },
    });
  }

  async createTeacher(tenantId: string, dto: any) {
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(dto.password, saltRounds);

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          organizationId: tenantId,
          email: dto.email,
          passwordHash,
          role: UserRole.TEACHER,
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

  async getTeachers(tenantId: string) {
    return this.prisma.teacher.findMany({
      where: { organizationId: tenantId, deletedAt: null },
      include: { user: true },
    });
  }

  async createStudent(tenantId: string, dto: any) {
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(dto.password, saltRounds);

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          organizationId: tenantId,
          email: dto.email,
          passwordHash,
          role: UserRole.STUDENT,
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

  async getStudents(tenantId: string) {
    return this.prisma.student.findMany({
      where: { organizationId: tenantId, deletedAt: null },
      include: { user: true, classRoom: true },
    });
  }

  // UPDATE & DELETE Endpoints

  async updateClassroom(tenantId: string, id: string, dto: any) {
    return this.prisma.classRoom.update({
      where: { id, organizationId: tenantId },
      data: { name: dto.name },
    });
  }

  async deleteClassroom(tenantId: string, id: string) {
    return this.prisma.classRoom.update({
      where: { id, organizationId: tenantId },
      data: { deletedAt: new Date() },
    });
  }

  async updateTeacher(tenantId: string, id: string, dto: any) {
    return this.prisma.$transaction(async (tx) => {
      const teacher = await tx.teacher.findUnique({ where: { id, organizationId: tenantId } });
      if (!teacher) throw new UnauthorizedException('Teacher not found');

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

  async deleteTeacher(tenantId: string, id: string) {
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

  async updateStudent(tenantId: string, id: string, dto: any) {
    return this.prisma.$transaction(async (tx) => {
      const student = await tx.student.findUnique({ where: { id, organizationId: tenantId } });
      if (!student) throw new UnauthorizedException('Student not found');

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

  async deleteStudent(tenantId: string, id: string) {
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

  async deleteOrganization(id: string) {
    return this.prisma.organization.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
