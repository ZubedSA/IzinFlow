import { IsEnum, IsNotEmpty, IsString, IsISO8601, IsOptional } from 'class-validator';
import { PermissionType } from '@prisma/client';

export class CreatePermissionDto {
  @IsEnum(PermissionType, { message: 'Jenis izin tidak valid.' })
  @IsNotEmpty({ message: 'Jenis izin wajib dipilih.' })
  type: PermissionType;

  @IsString({ message: 'Alasan wajib berupa teks.' })
  @IsNotEmpty({ message: 'Alasan izin wajib diisi.' })
  reason: string;

  @IsISO8601({}, { message: 'Format tanggal mulai salah (ISO8601).' })
  @IsNotEmpty({ message: 'Tanggal mulai wajib diisi.' })
  startDate: string;

  @IsISO8601({}, { message: 'Format tanggal selesai salah (ISO8601).' })
  @IsNotEmpty({ message: 'Tanggal selesai wajib diisi.' })
  endDate: string;

  @IsOptional()
  attachments?: {
    fileUrl: string;
    fileName: string;
    fileSize: number;
  }[];
}
