import { IsEmail, IsNotEmpty, IsOptional, MinLength } from 'class-validator';

export class RegisterOrgDto {
  // Organization settings
  @IsNotEmpty({ message: 'Nama organisasi wajib diisi.' })
  orgName: string;

  @IsNotEmpty({ message: 'Slug unik organisasi wajib diisi.' })
  orgSlug: string; // e.g., 'sman1-jakarta'

  @IsOptional()
  orgAddress?: string;

  @IsOptional()
  orgContact?: string;

  // Admin user details
  @IsEmail({}, { message: 'Format email tidak valid.' })
  @IsNotEmpty({ message: 'Email administrator wajib diisi.' })
  adminEmail: string;

  @IsNotEmpty({ message: 'Password administrator wajib diisi.' })
  @MinLength(6, { message: 'Password minimal 6 karakter.' })
  adminPassword: string;

  @IsNotEmpty({ message: 'Nama lengkap administrator wajib diisi.' })
  adminFullName: string;
}
