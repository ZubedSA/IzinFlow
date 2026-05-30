import { PrismaService } from '../../prisma/prisma.service';
export declare class NotificationService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findAllForUser(tenantId: string, userId: string): Promise<{
        id: string;
        createdAt: Date;
        organizationId: string;
        userId: string;
        title: string;
        body: string;
        isRead: boolean;
    }[]>;
    markAsRead(tenantId: string, id: string, userId: string): Promise<{
        id: string;
        createdAt: Date;
        organizationId: string;
        userId: string;
        title: string;
        body: string;
        isRead: boolean;
    }>;
}
