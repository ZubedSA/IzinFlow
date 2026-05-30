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
exports.LetterService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const PDFDocument = require("pdfkit");
const QRCode = require("qrcode");
let LetterService = class LetterService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async generatePDF(permissionRequestId) {
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
            throw new common_1.NotFoundException('Pengajuan izin tidak ditemukan.');
        }
        const doc = new PDFDocument({
            size: 'A4',
            margins: { top: 50, bottom: 50, left: 50, right: 50 },
        });
        const chunks = [];
        doc.on('data', (chunk) => chunks.push(chunk));
        if (request.organization.logoUrl) {
            doc.fontSize(10).text('[ LOGO LEMBAGA ]', 50, 45, { align: 'left' });
        }
        doc.font('Helvetica-Bold').fontSize(18).text(request.organization.name.toUpperCase(), { align: 'center' });
        doc.font('Helvetica').fontSize(9).text(request.organization.address || 'Alamat Lembaga Belum Ditentukan', { align: 'center' });
        doc.fontSize(9).text(`Kontak: ${request.organization.contact || '-'}`, { align: 'center' });
        doc.moveDown();
        doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
        doc.moveDown(2);
        const generatedLetter = await this.prisma.generatedLetter.findFirst({
            where: { permissionRequestId },
        });
        const letterNumber = generatedLetter?.letterNumber || '000/MOCK/IZIN/2026';
        doc.font('Helvetica-Bold').fontSize(14).text('SURAT KETERANGAN IZIN BELAJAR', { align: 'center', underline: true });
        doc.font('Helvetica').fontSize(10).text(`Nomor: ${letterNumber}`, { align: 'center' });
        doc.moveDown(2);
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
        doc.fontSize(10).text('Surat izin ini sah secara hukum dan diterbitkan secara elektronik melalui sistem IzinFlow.', 50, doc.y);
        doc.moveDown(2);
        const signY = doc.y;
        const verificationToken = generatedLetter?.verificationToken || 'dummy-token';
        const verifyUrl = `https://izinflow.com/verify/${verificationToken}`;
        const qrDataUrl = await QRCode.toDataURL(verifyUrl);
        const qrBuffer = Buffer.from(qrDataUrl.replace(/^data:image\/png;base64,/, ''), 'base64');
        doc.image(qrBuffer, 50, signY, { width: 90 });
        doc.fontSize(8).text('Pindai QR ini untuk verifikasi keaslian dokumen.', 50, signY + 95, { width: 100, align: 'center' });
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
    async verifyLetter(token) {
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
            throw new common_1.NotFoundException('Dokumen surat izin tidak terverifikasi atau palsu.');
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
    async generatePreviewPDF(dto, orgName) {
        const doc = new PDFDocument({
            size: 'A4',
            margins: { top: 50, bottom: 50, left: 50, right: 50 },
        });
        const chunks = [];
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
};
exports.LetterService = LetterService;
exports.LetterService = LetterService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], LetterService);
//# sourceMappingURL=letter.service.js.map