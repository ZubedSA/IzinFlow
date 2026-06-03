import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateOrgSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class OrganizationService {
  constructor(private readonly prisma: PrismaService) {}

  async getSettings(organizationId: string) {
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!org) {
      throw new NotFoundException('Organisasi tidak ditemukan');
    }

    // Ambil letter template pertama jika ada
    const template = await this.prisma.letterTemplate.findFirst({
      where: { organizationId, isActive: true },
    });

    return {
      organization: org,
      template: template || null,
    };
  }

  async updateSettings(organizationId: string, dto: UpdateOrgSettingsDto) {
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!org) {
      throw new NotFoundException('Organisasi tidak ditemukan');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Update Organization
      const updatedOrg = await tx.organization.update({
        where: { id: organizationId },
        data: {
          name: dto.name !== undefined ? dto.name : undefined,
          logoUrl: dto.logoUrl !== undefined ? dto.logoUrl : undefined,
          address: dto.address !== undefined ? dto.address : undefined,
          contact: dto.contact !== undefined ? dto.contact : undefined,
        },
      });

      // 2. Update or Create Letter Template
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
        } else {
          updatedTemplate = await tx.letterTemplate.create({
            data: {
              organizationId,
              title: 'Template Surat Izin Default',
              contentHtml: dto.templateContentHtml,
            },
          });
        }
      } else {
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

  async getAuditLogs(organizationId: string, limit = 20) {
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
}
