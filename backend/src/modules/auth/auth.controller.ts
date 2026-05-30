import {
  Controller,
  Post,
  Get,
  Put,
  Delete,
  Param,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterOrgDto } from './dto/register-org.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { TenantInterceptor } from '../../common/interceptors/tenant.interceptor';
import { CurrentTenant } from '../../common/decorators/tenant.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('register-organization')
  @HttpCode(HttpStatus.CREATED)
  async registerOrg(@Body() dto: RegisterOrgDto) {
    return this.authService.registerOrganization(dto);
  }

  @Post('classrooms')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  @HttpCode(HttpStatus.CREATED)
  async createClassroom(@CurrentTenant() tenantId: string, @Body() dto: any) {
    return this.authService.createClassroom(tenantId, dto);
  }

  @Get('classrooms')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async getClassrooms(@CurrentTenant() tenantId: string) {
    return this.authService.getClassrooms(tenantId);
  }

  @Post('teachers')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  @HttpCode(HttpStatus.CREATED)
  async createTeacher(@CurrentTenant() tenantId: string, @Body() dto: any) {
    return this.authService.createTeacher(tenantId, dto);
  }

  @Get('teachers')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async getTeachers(@CurrentTenant() tenantId: string) {
    return this.authService.getTeachers(tenantId);
  }

  @Post('students')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  @HttpCode(HttpStatus.CREATED)
  async createStudent(@CurrentTenant() tenantId: string, @Body() dto: any) {
    return this.authService.createStudent(tenantId, dto);
  }

  @Get('students')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async getStudents(@CurrentTenant() tenantId: string) {
    return this.authService.getStudents(tenantId);
  }

  @Put('classrooms/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async updateClassroom(@CurrentTenant() tenantId: string, @Param('id') id: string, @Body() dto: any) {
    return this.authService.updateClassroom(tenantId, id, dto);
  }

  @Delete('classrooms/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async deleteClassroom(@CurrentTenant() tenantId: string, @Param('id') id: string) {
    return this.authService.deleteClassroom(tenantId, id);
  }

  @Put('teachers/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async updateTeacher(@CurrentTenant() tenantId: string, @Param('id') id: string, @Body() dto: any) {
    return this.authService.updateTeacher(tenantId, id, dto);
  }

  @Delete('teachers/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async deleteTeacher(@CurrentTenant() tenantId: string, @Param('id') id: string) {
    return this.authService.deleteTeacher(tenantId, id);
  }

  @Put('students/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async updateStudent(@CurrentTenant() tenantId: string, @Param('id') id: string, @Body() dto: any) {
    return this.authService.updateStudent(tenantId, id, dto);
  }

  @Delete('students/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ORG_ADMIN, UserRole.SUPER_ADMIN)
  @UseInterceptors(TenantInterceptor)
  async deleteStudent(@CurrentTenant() tenantId: string, @Param('id') id: string) {
    return this.authService.deleteStudent(tenantId, id);
  }

  @Delete('organizations/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  async deleteOrganization(@Param('id') id: string) {
    return this.authService.deleteOrganization(id);
  }
}
