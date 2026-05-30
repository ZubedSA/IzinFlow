import { OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePermissionDto } from './dto/create-permission.dto';
import { ApprovePermissionDto } from './dto/approve-permission.dto';
import { UserRole } from '@prisma/client';
export declare class PermissionService implements OnModuleInit {
    private readonly prisma;
    constructor(prisma: PrismaService);
    onModuleInit(): Promise<void>;
    create(tenantId: string, userId: string, userRole: string, dto: CreatePermissionDto): Promise<{
        message: string;
        permissionId: string;
    }>;
    findAll(tenantId: string, userId: string, role: UserRole): Promise<({
        attachments: {
            id: string;
            createdAt: Date;
            permissionRequestId: string;
            fileUrl: string;
            fileName: string;
            fileSize: number;
        }[];
        approvals: ({
            teacher: {
                user: {
                    id: string;
                    createdAt: Date;
                    updatedAt: Date;
                    deletedAt: Date | null;
                    organizationId: string;
                    isActive: boolean;
                    email: string;
                    passwordHash: string;
                    role: import(".prisma/client").$Enums.UserRole;
                    fullName: string;
                    avatarUrl: string | null;
                };
            } & {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                organizationId: string;
                userId: string;
                employeeNumber: string | null;
            };
        } & {
            id: string;
            status: import(".prisma/client").$Enums.PermissionStatus;
            createdAt: Date;
            permissionRequestId: string;
            teacherId: string;
            note: string | null;
        })[];
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PermissionType;
        status: import(".prisma/client").$Enums.PermissionStatus;
        reason: string;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        organizationId: string;
        studentId: string;
    })[] | ({
        student: {
            user: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                organizationId: string;
                isActive: boolean;
                email: string;
                passwordHash: string;
                role: import(".prisma/client").$Enums.UserRole;
                fullName: string;
                avatarUrl: string | null;
            };
            classRoom: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                organizationId: string;
                name: string;
                homeroomTeacherId: string | null;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
            organizationId: string;
            userId: string;
            classRoomId: string;
            parentId: string | null;
            studentIdNumber: string | null;
        };
        attachments: {
            id: string;
            createdAt: Date;
            permissionRequestId: string;
            fileUrl: string;
            fileName: string;
            fileSize: number;
        }[];
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PermissionType;
        status: import(".prisma/client").$Enums.PermissionStatus;
        reason: string;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        organizationId: string;
        studentId: string;
    })[]>;
    findOne(tenantId: string, id: string): Promise<{
        student: {
            user: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                organizationId: string;
                isActive: boolean;
                email: string;
                passwordHash: string;
                role: import(".prisma/client").$Enums.UserRole;
                fullName: string;
                avatarUrl: string | null;
            };
            classRoom: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                organizationId: string;
                name: string;
                homeroomTeacherId: string | null;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
            organizationId: string;
            userId: string;
            classRoomId: string;
            parentId: string | null;
            studentIdNumber: string | null;
        };
        attachments: {
            id: string;
            createdAt: Date;
            permissionRequestId: string;
            fileUrl: string;
            fileName: string;
            fileSize: number;
        }[];
        approvals: ({
            teacher: {
                user: {
                    id: string;
                    createdAt: Date;
                    updatedAt: Date;
                    deletedAt: Date | null;
                    organizationId: string;
                    isActive: boolean;
                    email: string;
                    passwordHash: string;
                    role: import(".prisma/client").$Enums.UserRole;
                    fullName: string;
                    avatarUrl: string | null;
                };
            } & {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                organizationId: string;
                userId: string;
                employeeNumber: string | null;
            };
        } & {
            id: string;
            status: import(".prisma/client").$Enums.PermissionStatus;
            createdAt: Date;
            permissionRequestId: string;
            teacherId: string;
            note: string | null;
        })[];
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PermissionType;
        status: import(".prisma/client").$Enums.PermissionStatus;
        reason: string;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        organizationId: string;
        studentId: string;
    }>;
    approve(tenantId: string, id: string, teacherUserId: string, dto: ApprovePermissionDto): Promise<{
        message: string;
        status: "APPROVED";
    }>;
    reject(tenantId: string, id: string, teacherUserId: string, dto: ApprovePermissionDto): Promise<{
        message: string;
        status: "REJECTED";
    }>;
    getOrgStats(tenantId: string): Promise<{
        totalStudents: number;
        totalTeachers: number;
        pendingCount: number;
        approvedCount: number;
        rejectedCount: number;
    }>;
    getGlobalStats(): Promise<{
        totalOrganizations: number;
        totalUsers: number;
        totalLettersGenerated: number;
        totalPendingRequests: number;
        totalApprovedRequests: number;
        organizations: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            name: string;
            slug: string;
            logoUrl: string | null;
            brandColor: string;
            address: string | null;
            contact: string | null;
            isActive: boolean;
        }[];
    }>;
}
