import { PermissionType } from '@prisma/client';
export declare class CreatePermissionDto {
    type: PermissionType;
    reason: string;
    startDate: string;
    endDate: string;
    attachments?: {
        fileUrl: string;
        fileName: string;
        fileSize: number;
    }[];
}
