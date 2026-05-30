import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NotificationService {
  constructor(private readonly prisma: PrismaService) {}

  async findAllForUser(tenantId: string, userId: string) {
    return this.prisma.notification.findMany({
      where: { organizationId: tenantId, userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAsRead(tenantId: string, id: string, userId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, organizationId: tenantId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notifikasi tidak ditemukan.');
    }

    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }
}
