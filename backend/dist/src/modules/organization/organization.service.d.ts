import { PrismaService } from '../../prisma/prisma.service';
import { UpdateOrgSettingsDto } from './dto/update-settings.dto';
export declare class OrganizationService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getSettings(organizationId: string): Promise<{
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
    updateSettings(organizationId: string, dto: UpdateOrgSettingsDto): Promise<{
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
}
