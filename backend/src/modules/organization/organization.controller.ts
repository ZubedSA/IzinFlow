import { Controller, Get, Put, Body, UseGuards, Request, Post, Res } from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { UpdateOrgSettingsDto } from './dto/update-settings.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { LetterService } from '../letter/letter.service';
import { Response } from 'express';

@Controller('organizations')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrganizationController {
  constructor(
    private readonly organizationService: OrganizationService,
    private readonly letterService: LetterService,
  ) {}

  @Get('settings')
  @Roles(UserRole.ORG_ADMIN)
  getSettings(@Request() req: any) {
    return this.organizationService.getSettings(req.user.organizationId);
  }

  @Put('settings')
  @Roles(UserRole.ORG_ADMIN)
  updateSettings(@Request() req: any, @Body() dto: UpdateOrgSettingsDto) {
    return this.organizationService.updateSettings(req.user.organizationId, dto);
  }

  @Post('settings/preview')
  @Roles(UserRole.ORG_ADMIN)
  async previewSettings(@Request() req: any, @Body() dto: UpdateOrgSettingsDto, @Res() res: Response) {
    const org = await this.organizationService.getSettings(req.user.organizationId);
    const orgName = org.organization.name;
    
    const pdfBuffer = await this.letterService.generatePreviewPDF(dto, orgName);
    
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename=Surat-Izin-Preview.pdf`,
      'Content-Length': pdfBuffer.length,
    });

    res.end(pdfBuffer);
  }
}
