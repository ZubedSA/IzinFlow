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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const common_1 = require("@nestjs/common");
const auth_service_1 = require("./auth.service");
const login_dto_1 = require("./dto/login.dto");
const register_org_dto_1 = require("./dto/register-org.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const tenant_interceptor_1 = require("../../common/interceptors/tenant.interceptor");
const tenant_decorator_1 = require("../../common/decorators/tenant.decorator");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let AuthController = class AuthController {
    constructor(authService) {
        this.authService = authService;
    }
    async login(dto) {
        return this.authService.login(dto);
    }
    async registerOrg(dto) {
        return this.authService.registerOrganization(dto);
    }
    async createClassroom(tenantId, dto) {
        return this.authService.createClassroom(tenantId, dto);
    }
    async getClassrooms(tenantId) {
        return this.authService.getClassrooms(tenantId);
    }
    async createTeacher(tenantId, dto) {
        return this.authService.createTeacher(tenantId, dto);
    }
    async getTeachers(tenantId) {
        return this.authService.getTeachers(tenantId);
    }
    async createStudent(tenantId, dto) {
        return this.authService.createStudent(tenantId, dto);
    }
    async getStudents(tenantId) {
        return this.authService.getStudents(tenantId);
    }
    async updateClassroom(tenantId, id, dto) {
        return this.authService.updateClassroom(tenantId, id, dto);
    }
    async deleteClassroom(tenantId, id) {
        return this.authService.deleteClassroom(tenantId, id);
    }
    async updateTeacher(tenantId, id, dto) {
        return this.authService.updateTeacher(tenantId, id, dto);
    }
    async deleteTeacher(tenantId, id) {
        return this.authService.deleteTeacher(tenantId, id);
    }
    async updateStudent(tenantId, id, dto) {
        return this.authService.updateStudent(tenantId, id, dto);
    }
    async deleteStudent(tenantId, id) {
        return this.authService.deleteStudent(tenantId, id);
    }
    async deleteOrganization(id) {
        return this.authService.deleteOrganization(id);
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Post)('login'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [login_dto_1.LoginDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "login", null);
__decorate([
    (0, common_1.Post)('register-organization'),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [register_org_dto_1.RegisterOrgDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "registerOrg", null);
__decorate([
    (0, common_1.Post)('classrooms'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "createClassroom", null);
__decorate([
    (0, common_1.Get)('classrooms'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getClassrooms", null);
__decorate([
    (0, common_1.Post)('teachers'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "createTeacher", null);
__decorate([
    (0, common_1.Get)('teachers'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getTeachers", null);
__decorate([
    (0, common_1.Post)('students'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "createStudent", null);
__decorate([
    (0, common_1.Get)('students'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getStudents", null);
__decorate([
    (0, common_1.Put)('classrooms/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "updateClassroom", null);
__decorate([
    (0, common_1.Delete)('classrooms/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "deleteClassroom", null);
__decorate([
    (0, common_1.Put)('teachers/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "updateTeacher", null);
__decorate([
    (0, common_1.Delete)('teachers/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "deleteTeacher", null);
__decorate([
    (0, common_1.Put)('students/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "updateStudent", null);
__decorate([
    (0, common_1.Delete)('students/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "deleteStudent", null);
__decorate([
    (0, common_1.Delete)('organizations/:id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.UserRole.SUPER_ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "deleteOrganization", null);
exports.AuthController = AuthController = __decorate([
    (0, common_1.Controller)('auth'),
    __metadata("design:paramtypes", [auth_service_1.AuthService])
], AuthController);
//# sourceMappingURL=auth.controller.js.map