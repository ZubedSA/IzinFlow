import { LetterService } from './letter.service';
import { Response } from 'express';
export declare class LetterController {
    private readonly letterService;
    constructor(letterService: LetterService);
    downloadPDF(permissionRequestId: string, res: Response): Promise<void>;
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
}
