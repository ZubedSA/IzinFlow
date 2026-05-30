import { Controller, Get, Post, Param, UseGuards, UseInterceptors, Req } from '@nestjs/common';
import { NotificationService } from './notification.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { TenantInterceptor } from '../../common/interceptors/tenant.interceptor';
import { CurrentTenant } from '../../common/decorators/tenant.decorator';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
@UseInterceptors(TenantInterceptor)
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get()
  async findAll(@CurrentTenant() tenantId: string, @Req() req: any) {
    return this.notificationService.findAllForUser(tenantId, req.user.userId);
  }

  @Post(':id/read')
  async read(
    @CurrentTenant() tenantId: string,
    @Param('id') id: string,
    @Req() req: any,
  ) {
    return this.notificationService.markAsRead(tenantId, id, req.user.userId);
  }
}
