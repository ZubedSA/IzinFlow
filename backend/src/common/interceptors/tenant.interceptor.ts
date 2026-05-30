import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  BadRequestException,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class TenantInterceptor implements NestInterceptor {
  constructor(private readonly prisma: PrismaService) {}

  async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest();
    
    // 1. Resolve organization identifier from header or decoded JWT user payload
    const organizationId = request.headers['x-organization-id'] || request.user?.organizationId;

    if (!organizationId) {
      throw new BadRequestException('Organization identifier ("X-Organization-Id" header) is missing in request context.');
    }

    // 2. Validate existence and activity status of organization
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!org) {
      throw new BadRequestException('The requested Organization does not exist.');
    }

    if (!org.isActive) {
      throw new BadRequestException('The requested Organization is currently inactive.');
    }

    // 3. Attach validated tenant reference to request
    request.tenantId = organizationId;

    // 4. Bind session context variable for Postgres Row Level Security (RLS) policies
    await this.prisma.$executeRawUnsafe(
      `SET LOCAL app.current_organization_id = '${organizationId}';`
    );

    return next.handle();
  }
}
