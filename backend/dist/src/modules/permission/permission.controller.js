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
exports.PermissionController = void 0;
const common_1 = require("@nestjs/common");
const permission_service_1 = require("./permission.service");
const create_permission_dto_1 = require("./dto/create-permission.dto");
const approve_permission_dto_1 = require("./dto/approve-permission.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const tenant_interceptor_1 = require("../../common/interceptors/tenant.interceptor");
const tenant_decorator_1 = require("../../common/decorators/tenant.decorator");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const roles_guard_1 = require("../../common/guards/roles.guard");
const client_1 = require("@prisma/client");
let PermissionController = class PermissionController {
    constructor(permissionService) {
        this.permissionService = permissionService;
    }
    async create(tenantId, req, dto) {
        return this.permissionService.create(tenantId, req.user.userId, req.user.role, dto);
    }
    async findAll(tenantId, req) {
        return this.permissionService.findAll(tenantId, req.user.userId, req.user.role);
    }
    async getOrgStats(tenantId) {
        return this.permissionService.getOrgStats(tenantId);
    }
    async getGlobalStats() {
        return this.permissionService.getGlobalStats();
    }
    async findOne(tenantId, id) {
        return this.permissionService.findOne(tenantId, id);
    }
    async approve(tenantId, id, req, dto) {
        return this.permissionService.approve(tenantId, id, req.user.userId, dto);
    }
    async reject(tenantId, id, req, dto) {
        return this.permissionService.reject(tenantId, id, req.user.userId, dto);
    }
};
exports.PermissionController = PermissionController;
__decorate([
    (0, common_1.Post)(),
    (0, roles_decorator_1.Roles)(client_1.UserRole.STUDENT),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Req)()),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, create_permission_dto_1.CreatePermissionDto]),
    __metadata("design:returntype", Promise)
], PermissionController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], PermissionController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)('org-stats'),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN, client_1.UserRole.SUPER_ADMIN),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], PermissionController.prototype, "getOrgStats", null);
__decorate([
    (0, common_1.Get)('global-stats'),
    (0, roles_decorator_1.Roles)(client_1.UserRole.SUPER_ADMIN),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], PermissionController.prototype, "getGlobalStats", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], PermissionController.prototype, "findOne", null);
__decorate([
    (0, common_1.Post)(':id/approve'),
    (0, roles_decorator_1.Roles)(client_1.UserRole.TEACHER, client_1.UserRole.ORG_ADMIN),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Req)()),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, approve_permission_dto_1.ApprovePermissionDto]),
    __metadata("design:returntype", Promise)
], PermissionController.prototype, "approve", null);
__decorate([
    (0, common_1.Post)(':id/reject'),
    (0, roles_decorator_1.Roles)(client_1.UserRole.TEACHER, client_1.UserRole.ORG_ADMIN),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, tenant_decorator_1.CurrentTenant)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Req)()),
    __param(3, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, approve_permission_dto_1.ApprovePermissionDto]),
    __metadata("design:returntype", Promise)
], PermissionController.prototype, "reject", null);
exports.PermissionController = PermissionController = __decorate([
    (0, common_1.Controller)('permissions'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.UseInterceptors)(tenant_interceptor_1.TenantInterceptor),
    __metadata("design:paramtypes", [permission_service_1.PermissionService])
], PermissionController);
//# sourceMappingURL=permission.controller.js.map