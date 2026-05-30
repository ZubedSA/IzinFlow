import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import * as PDFDocument from 'pdfkit';
import * as QRCode from 'qrcode';

@Injectable()
export class LetterService {
  constructor(private readonly prisma: PrismaService) {}

  async generatePDF(permissionRequestId: string): Promise<Buffer> {
    const request = await this.prisma.permissionRequest.findUnique({
      where: { id: permissionRequestId },
      include: {
        student: {
          include: {
            user: true,
            classRoom: true,
          },
        },
        organization: true,
      },
    });

    if (!request) {
      throw new NotFoundException('Pengajuan izin tidak ditemukan.');
    }

    // 1. Initiate PDF A4 Document
    const doc = new PDFDocument({
      size: 'A4',
      margins: { top: 50, bottom: 50, left: 50, right: 50 },
    });

    const chunks: Buffer[] = [];
    doc.on('data', (chunk) => chunks.push(chunk));

    // 2. Organization Header Branding
    if (request.organization.logoUrl) {
      // Mock logo or placeholder space
      doc.fontSize(10).text('[ LOGO LEMBAGA ]', 50, 45, { align: 'left' });
    }
    
    doc.font('Helvetica-Bold').fontSize(18).text(request.organization.name.toUpperCase(), { align: 'center' });
    doc.font('Helvetica').fontSize(9).text(request.organization.address || 'Alamat Lembaga Belum Ditentukan', { align: 'center' });
    doc.fontSize(9).text(`Kontak: ${request.organization.contact || '-'}`, { align: 'center' });
    doc.moveDown();
    
    // Draw Elegant Header Line
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown(2);

    // 3. Document Letter Identification Number
    const generatedLetter = await this.prisma.generatedLetter.findFirst({
      where: { permissionRequestId },
    });
    const letterNumber = generatedLetter?.letterNumber || '000/MOCK/IZIN/2026';

    doc.font('Helvetica-Bold').fontSize(14).text('SURAT KETERANGAN IZIN BELAJAR', { align: 'center', underline: true });
    doc.font('Helvetica').fontSize(10).text(`Nomor: ${letterNumber}`, { align: 'center' });
    doc.moveDown(2);

    // 4. Content Body details
    const template = await this.prisma.letterTemplate.findFirst({
      where: { organizationId: request.organizationId, isActive: true }
    });
    const introText = template?.contentHtml || 'Dengan ini, Pihak Sekolah menerangkan bahwa siswa berikut:';

    doc.fontSize(11).text(introText, { lineGap: 6 });
    doc.moveDown();

    const currentY = doc.y;
    doc.text('Nama Siswa', 70, currentY);
    doc.text(`:   ${request.student.user.fullName}`, 180, currentY);

    doc.text('Nomor Induk (NISN)', 70, currentY + 20);
    doc.text(`:   ${request.student.studentIdNumber || '-'}`, 180, currentY + 20);

    doc.text('Kelas', 70, currentY + 40);
    doc.text(`:   ${request.student.classRoom.name}`, 180, currentY + 40);

    doc.text('Jenis Izin', 70, currentY + 60);
    doc.text(`:   ${request.type}`, 180, currentY + 60);

    doc.text('Alasan Ketidakhadiran', 70, currentY + 80);
    doc.text(`:   ${request.reason}`, 180, currentY + 80);

    const startDateStr = new Date(request.startDate).toLocaleDateString('id-ID', { dateStyle: 'long' });
    const endDateStr = new Date(request.endDate).toLocaleDateString('id-ID', { dateStyle: 'long' });
    doc.text('Rentang Tanggal', 70, currentY + 100);
    doc.text(`:   ${startDateStr} s/d ${endDateStr}`, 180, currentY + 100);

    doc.moveDown(7);

    // 5. Digital Seal Verification & Bottom Signatures
    doc.fontSize(10).text('Surat izin ini sah secara hukum dan diterbitkan secara elektronik melalui sistem IzinFlow.', 50, doc.y);
    doc.moveDown(2);

    const signY = doc.y;

    // Generate Verification QR code linking to direct web status check
    const verificationToken = generatedLetter?.verificationToken || 'dummy-token';
    const verifyUrl = `https://izinflow.com/verify/${verificationToken}`;
    const qrDataUrl = await QRCode.toDataURL(verifyUrl);
    const qrBuffer = Buffer.from(qrDataUrl.replace(/^data:image\/png;base64,/, ''), 'base64');
    
    // QR Code Placement
    doc.image(qrBuffer, 50, signY, { width: 90 });
    doc.fontSize(8).text('Pindai QR ini untuk verifikasi keaslian dokumen.', 50, signY + 95, { width: 100, align: 'center' });

    // Official Homeroom/Administrator Signature Placeholder
    doc.fontSize(10).text('Tanda Tangan Pengesah,', 380, signY);
    doc.moveDown(3);
    doc.font('Helvetica-Bold').text('( Wali Kelas / ORG ADMIN )', 380, doc.y);
    
    doc.end();

    return new Promise((resolve) => {
      doc.on('end', () => {
        resolve(Buffer.concat(chunks));
      });
    });
  }

  async verifyLetter(token: string) {
    const letter = await this.prisma.generatedLetter.findUnique({
      where: { verificationToken: token },
      include: {
        permissionRequest: {
          include: {
            student: {
              include: {
                user: true,
                classRoom: true,
              },
            },
          },
        },
        organization: true,
      },
    });

    if (!letter) {
      throw new NotFoundException('Dokumen surat izin tidak terverifikasi atau palsu.');
    }

    return {
      status: 'VERIFIED',
      letterNumber: letter.letterNumber,
      organizationName: letter.organization.name,
      studentName: letter.permissionRequest.student.user.fullName,
      classRoom: letter.permissionRequest.student.classRoom.name,
      permissionType: letter.permissionRequest.type,
      startDate: letter.permissionRequest.startDate,
      endDate: letter.permissionRequest.endDate,
      createdAt: letter.createdAt,
    };
  }

  async generatePreviewPDF(dto: any, orgName: string): Promise<Buffer> {
    const doc = new PDFDocument({
      size: 'A4',
      margins: { top: 50, bottom: 50, left: 50, right: 50 },
    });

    const chunks: Buffer[] = [];
    doc.on('data', (chunk) => chunks.push(chunk));

    if (dto.logoUrl) {
      doc.fontSize(10).text('[ LOGO LEMBAGA ]', 50, 45, { align: 'left' });
    }
    
    doc.font('Helvetica-Bold').fontSize(18).text(dto.name?.toUpperCase() || orgName.toUpperCase(), { align: 'center' });
    doc.font('Helvetica').fontSize(9).text(dto.address || 'Alamat Lembaga Belum Ditentukan', { align: 'center' });
    doc.fontSize(9).text(`Kontak: ${dto.contact || '-'}`, { align: 'center' });
    doc.moveDown();
    
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown(2);

    doc.font('Helvetica-Bold').fontSize(14).text('SURAT KETERANGAN IZIN BELAJAR', { align: 'center', underline: true });
    doc.font('Helvetica').fontSize(10).text(`Nomor: 000/MOCK/PREVIEW/2026`, { align: 'center' });
    doc.moveDown(2);

    const introText = dto.templateContentHtml || 'Dengan ini, Pihak Sekolah menerangkan bahwa siswa berikut:';
    doc.fontSize(11).text(introText, { lineGap: 6 });
    doc.moveDown();

    const currentY = doc.y;
    doc.text('Nama Siswa', 70, currentY);
    doc.text(`:   [NAMA SISWA PREVIEW]`, 180, currentY);

    doc.text('Nomor Induk (NISN)', 70, currentY + 20);
    doc.text(`:   1234567890`, 180, currentY + 20);

    doc.text('Kelas', 70, currentY + 40);
    doc.text(`:   [KELAS PREVIEW]`, 180, currentY + 40);

    doc.text('Jenis Izin', 70, currentY + 60);
    doc.text(`:   SICK (Sakit)`, 180, currentY + 60);

    doc.text('Alasan Ketidakhadiran', 70, currentY + 80);
    doc.text(`:   (Alasan Izin Preview)`, 180, currentY + 80);

    doc.text('Rentang Tanggal', 70, currentY + 100);
    doc.text(`:   28 Mei 2026 s/d 29 Mei 2026`, 180, currentY + 100);

    doc.moveDown(7);

    doc.fontSize(10).text('Surat izin ini sah secara hukum dan diterbitkan secara elektronik melalui sistem IzinFlow.', 50, doc.y);
    doc.moveDown(2);

    const signY = doc.y;
    
    doc.fontSize(10).text('Tanda Tangan Pengesah,', 380, signY);
    doc.moveDown(3);
    doc.font('Helvetica-Bold').text('( Wali Kelas / ORG ADMIN )', 380, doc.y);
    
    doc.end();

    return new Promise((resolve) => {
      doc.on('end', () => {
        resolve(Buffer.concat(chunks));
      });
    });
  }
}
