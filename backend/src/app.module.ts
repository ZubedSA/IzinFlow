import { Module } from '@nestjs/common';
import { AuthModule } from './modules/auth/auth.module';
import { PermissionModule } from './modules/permission/permission.module';
import { LetterModule } from './modules/letter/letter.module';
import { NotificationModule } from './modules/notification/notification.module';
import { OrganizationModule } from './modules/organization/organization.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    PermissionModule,
    LetterModule,
    NotificationModule,
    OrganizationModule,
  ],
})
export class AppModule {}
