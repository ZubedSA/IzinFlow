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
exports.OrganizationController = void 0;
const common_1 = require("@nestjs/common");
const organization_service_1 = require("./organization.service");
const update_settings_dto_1 = require("./dto/update-settings.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
const letter_service_1 = require("../letter/letter.service");
let OrganizationController = class OrganizationController {
    constructor(organizationService, letterService) {
        this.organizationService = organizationService;
        this.letterService = letterService;
    }
    getSettings(req) {
        return this.organizationService.getSettings(req.user.organizationId);
    }
    updateSettings(req, dto) {
        return this.organizationService.updateSettings(req.user.organizationId, dto);
    }
    async previewSettings(req, dto, res) {
        const org = await this.organizationService.getSettings(req.user.organizationId);
        const orgName = org.organization.name;
        const pdfBuffer = await this.letterService.generatePreviewPDF(dto, orgName);
        res.set({
            'Content-Type': 'application/pdf',
            'Content-Disposition': `attachment; filename=Surat-Izin-Preview.pdf`,
            'Content-Length': pdfBuffer.length,
        });
        res.end(pdfBuffer);
    }
};
exports.OrganizationController = OrganizationController;
__decorate([
    (0, common_1.Get)('settings'),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], OrganizationController.prototype, "getSettings", null);
__decorate([
    (0, common_1.Put)('settings'),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_settings_dto_1.UpdateOrgSettingsDto]),
    __metadata("design:returntype", void 0)
], OrganizationController.prototype, "updateSettings", null);
__decorate([
    (0, common_1.Post)('settings/preview'),
    (0, roles_decorator_1.Roles)(client_1.UserRole.ORG_ADMIN),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_settings_dto_1.UpdateOrgSettingsDto, Object]),
    __metadata("design:returntype", Promise)
], OrganizationController.prototype, "previewSettings", null);
exports.OrganizationController = OrganizationController = __decorate([
    (0, common_1.Controller)('organizations'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [organization_service_1.OrganizationService,
        letter_service_1.LetterService])
], OrganizationController);
//# sourceMappingURL=organization.controller.js.map