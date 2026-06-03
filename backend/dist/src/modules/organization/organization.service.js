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
exports.OrganizationService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let OrganizationService = class OrganizationService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getSettings(organizationId) {
        const org = await this.prisma.organization.findUnique({
            where: { id: organizationId },
        });
        if (!org) {
            throw new common_1.NotFoundException('Organisasi tidak ditemukan');
        }
        const template = await this.prisma.letterTemplate.findFirst({
            where: { organizationId, isActive: true },
        });
        return {
            organization: org,
            template: template || null,
        };
    }
    async updateSettings(organizationId, dto) {
        const org = await this.prisma.organization.findUnique({
            where: { id: organizationId },
        });
        if (!org) {
            throw new common_1.NotFoundException('Organisasi tidak ditemukan');
        }
        return this.prisma.$transaction(async (tx) => {
            const updatedOrg = await tx.organization.update({
                where: { id: organizationId },
                data: {
                    name: dto.name !== undefined ? dto.name : undefined,
                    logoUrl: dto.logoUrl !== undefined ? dto.logoUrl : undefined,
                    address: dto.address !== undefined ? dto.address : undefined,
                    contact: dto.contact !== undefined ? dto.contact : undefined,
                },
            });
            let updatedTemplate = null;
            if (dto.templateContentHtml !== undefined) {
                const existingTemplate = await tx.letterTemplate.findFirst({
                    where: { organizationId, isActive: true },
                });
                if (existingTemplate) {
                    updatedTemplate = await tx.letterTemplate.update({
                        where: { id: existingTemplate.id },
                        data: { contentHtml: dto.templateContentHtml },
                    });
                }
                else {
                    updatedTemplate = await tx.letterTemplate.create({
                        data: {
                            organizationId,
                            title: 'Template Surat Izin Default',
                            contentHtml: dto.templateContentHtml,
                        },
                    });
                }
            }
            else {
                updatedTemplate = await tx.letterTemplate.findFirst({
                    where: { organizationId, isActive: true },
                });
            }
            return {
                message: 'Pengaturan berhasil disimpan.',
                organization: updatedOrg,
                template: updatedTemplate,
            };
        });
    }
    async getAuditLogs(organizationId, limit = 20) {
        return this.prisma.auditLog.findMany({
            where: { organizationId },
            orderBy: { createdAt: 'desc' },
            take: limit,
            include: {
                user: {
                    select: {
                        id: true,
                        fullName: true,
                        email: true,
                        role: true,
                        avatarUrl: true,
                    },
                },
            },
        });
    }
};
exports.OrganizationService = OrganizationService;
exports.OrganizationService = OrganizationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], OrganizationService);
//# sourceMappingURL=organization.service.js.map