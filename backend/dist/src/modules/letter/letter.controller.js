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
exports.LetterController = void 0;
const common_1 = require("@nestjs/common");
const letter_service_1 = require("./letter.service");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
let LetterController = class LetterController {
    constructor(letterService) {
        this.letterService = letterService;
    }
    async downloadPDF(permissionRequestId, res) {
        const pdfBuffer = await this.letterService.generatePDF(permissionRequestId);
        res.set({
            'Content-Type': 'application/pdf',
            'Content-Disposition': `attachment; filename=Surat-Izin-${permissionRequestId}.pdf`,
            'Content-Length': pdfBuffer.length,
        });
        res.status(common_1.HttpStatus.OK).send(pdfBuffer);
    }
    async verifyLetter(token) {
        return this.letterService.verifyLetter(token);
    }
};
exports.LetterController = LetterController;
__decorate([
    (0, common_1.Get)(':permissionRequestId/download'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('permissionRequestId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], LetterController.prototype, "downloadPDF", null);
__decorate([
    (0, common_1.Get)('verify/:token'),
    __param(0, (0, common_1.Param)('token')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], LetterController.prototype, "verifyLetter", null);
exports.LetterController = LetterController = __decorate([
    (0, common_1.Controller)('letters'),
    __metadata("design:paramtypes", [letter_service_1.LetterService])
], LetterController);
//# sourceMappingURL=letter.controller.js.map