"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const auth_service_1 = require("../src/modules/auth/auth.service");
async function bootstrap() {
    console.log('--- NEST DIAGNOSTIC BOOTSTRAP ---');
    try {
        const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
        const authService = app.get(auth_service_1.AuthService);
        console.log('DI Context populated. Calling login service...');
        const result = await authService.login({
            email: 'student@majujaya.sch.id',
            password: 'student123',
        });
        console.log('✅ LOGIN EXPERIMENT SUCCESS:', result);
        await app.close();
        process.exit(0);
    }
    catch (err) {
        console.error('❌ NEST RUNTIME CRASH CAPTURED:');
        console.error(err);
        process.exit(1);
    }
}
bootstrap();
//# sourceMappingURL=run_login.js.map