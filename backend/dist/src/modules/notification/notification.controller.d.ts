import { NotificationService } from './notification.service';
export declare class NotificationController {
    private readonly notificationService;
    constructor(notificationService: NotificationService);
    findAll(tenantId: string, req: any): Promise<{
        id: string;
        createdAt: Date;
        organizationId: string;
        userId: string;
        title: string;
        body: string;
        isRead: boolean;
    }[]>;
    read(tenantId: string, id: string, req: any): Promise<{
        id: string;
        createdAt: Date;
        organizationId: string;
        userId: string;
        title: string;
        body: string;
        isRead: boolean;
    }>;
}
