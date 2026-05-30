import { IsOptional, IsString } from 'class-validator';

export class ApprovePermissionDto {
  @IsOptional()
  @IsString({ message: 'Catatan persetujuan harus berupa string.' })
  note?: string;
}
