import { Controller, Get, Param, Res, UseGuards, HttpStatus } from '@nestjs/common';
import { LetterService } from './letter.service';
import { Response } from 'express';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Controller('letters')
export class LetterController {
  constructor(private readonly letterService: LetterService) {}

  // 1. Authenticated endpoint to download a signed permission letter as PDF
  @Get(':permissionRequestId/download')
  @UseGuards(JwtAuthGuard)
  async downloadPDF(
    @Param('permissionRequestId') permissionRequestId: string,
    @Res() res: Response,
  ) {
    const pdfBuffer = await this.letterService.generatePDF(permissionRequestId);
    
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename=Surat-Izin-${permissionRequestId}.pdf`,
      'Content-Length': pdfBuffer.length,
    });

    res.status(HttpStatus.OK).send(pdfBuffer);
  }

  // 2. Public endpoint to verify the authenticity of printed letter via scanned QR Code token
  @Get('verify/:token')
  async verifyLetter(@Param('token') token: string) {
    return this.letterService.verifyLetter(token);
  }
}
