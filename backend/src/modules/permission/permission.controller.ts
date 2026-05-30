import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  UseInterceptors,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { PermissionService } from './permission.service';
import { CreatePermissionDto } from './dto/create-permission.dto';
import { ApprovePermissionDto } from './dto/approve-permission.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { TenantInterceptor } from '../../common/interceptors/tenant.interceptor';
import { CurrentTenant } from '../../common/decorators/tenant.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '@prisma/client';

@Controller('permissions')
@UseGuards(JwtAuthGuard, RolesGuard)
@UseInterceptors(TenantInterceptor)
export class PermissionController {
  constructor(private readonly permissionService: PermissionService) {}

  @Post()
  @Roles(UserRole.STUDENT)
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentTenant() tenantId: string,
    @Req() req: any,
    @Body() dto: CreatePermissionDto,
  ) {
    return this.permissionService.create(tenantId, req.user.userId, req.user.role, dto);
  }

  @Get()
  async findAll(@CurrentTenant() tenantId: string, @Req() req: any) {
    return this.permissionService.findAll(tenantId, req.user.userId, req.user.role);
  }

  @Get('org-stats')
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  async getOrgStats(@CurrentTenant() tenantId: string) {
    return this.permissionService.getOrgStats(tenantId);
  }

  @Get('global-stats')
  @Roles(UserRole.SUPER_ADMIN)
  async getGlobalStats() {
    return this.permissionService.getGlobalStats();
  }

  @Get(':id')
  async findOne(@CurrentTenant() tenantId: string, @Param('id') id: string) {
    return this.permissionService.findOne(tenantId, id);
  }

  @Post(':id/approve')
  @Roles(UserRole.TEACHER, UserRole.ORG_ADMIN)
  @HttpCode(HttpStatus.OK)
  async approve(
    @CurrentTenant() tenantId: string,
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: ApprovePermissionDto,
  ) {
    return this.permissionService.approve(tenantId, id, req.user.userId, dto);
  }

  @Post(':id/reject')
  @Roles(UserRole.TEACHER, UserRole.ORG_ADMIN)
  @HttpCode(HttpStatus.OK)
  async reject(
    @CurrentTenant() tenantId: string,
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: ApprovePermissionDto,
  ) {
    return this.permissionService.reject(tenantId, id, req.user.userId, dto);
  }
}
