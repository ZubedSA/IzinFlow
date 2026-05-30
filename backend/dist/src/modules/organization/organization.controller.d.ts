import { OrganizationService } from './organization.service';
import { UpdateOrgSettingsDto } from './dto/update-settings.dto';
import { LetterService } from '../letter/letter.service';
import { Response } from 'express';
export declare class OrganizationController {
    private readonly organizationService;
    private readonly letterService;
    constructor(organizationService: OrganizationService, letterService: LetterService);
    getSettings(req: any): Promise<{
        organization: {
            id: string;
            slug: string;
            name: string;
            logoUrl: string | null;
            brandColor: string;
            address: string | null;
            contact: string | null;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
        };
        template: {
            id: string;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
            organizationId: string;
            title: string;
            contentHtml: string;
        };
    }>;
    updateSettings(req: any, dto: UpdateOrgSettingsDto): Promise<{
        message: string;
        organization: {
            id: string;
            slug: string;
            name: string;
            logoUrl: string | null;
            brandColor: string;
            address: string | null;
            contact: string | null;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
        };
        template: any;
    }>;
    previewSettings(req: any, dto: UpdateOrgSettingsDto, res: Response): Promise<void>;
}
