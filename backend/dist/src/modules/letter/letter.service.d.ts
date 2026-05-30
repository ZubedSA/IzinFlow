import { PrismaService } from '../../prisma/prisma.service';
export declare class LetterService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    generatePDF(permissionRequestId: string): Promise<Buffer>;
    verifyLetter(token: string): Promise<{
        status: string;
        letterNumber: string;
        organizationName: string;
        studentName: string;
        classRoom: string;
        permissionType: import(".prisma/client").$Enums.PermissionType;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
    }>;
    generatePreviewPDF(dto: any, orgName: string): Promise<Buffer>;
}
