import { IsEmail, IsNotEmpty, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: 'Format email tidak valid.' })
  @IsNotEmpty({ message: 'Email wajib diisi.' })
  email: string;

  @IsNotEmpty({ message: 'Password wajib diisi.' })
  @MinLength(6, { message: 'Password minimal 6 karakter.' })
  password: string;
}
