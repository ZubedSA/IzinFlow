import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AuthService } from '../src/modules/auth/auth.service';

async function bootstrap() {
  console.log('--- NEST DIAGNOSTIC BOOTSTRAP ---');
  try {
    const app = await NestFactory.createApplicationContext(AppModule);
    const authService = app.get(AuthService);
    console.log('DI Context populated. Calling login service...');
    
    const result = await authService.login({
      email: 'student@majujaya.sch.id',
      password: 'student123',
    });
    
    console.log('✅ LOGIN EXPERIMENT SUCCESS:', result);
    await app.close();
    process.exit(0);
  } catch (err) {
    console.error('❌ NEST RUNTIME CRASH CAPTURED:');
    console.error(err);
    process.exit(1);
  }
}
bootstrap();
