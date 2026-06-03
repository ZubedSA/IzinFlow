import { IsNotEmpty, MinLength } from 'class-validator';

export class ChangePasswordDto {
  @IsNotEmpty({ message: 'Password lama wajib diisi.' })
  oldPassword: string;

  @IsNotEmpty({ message: 'Password baru wajib diisi.' })
  @MinLength(6, { message: 'Password baru minimal 6 karakter.' })
  newPassword: string;
}
