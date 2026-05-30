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
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreatePermissionDto = void 0;
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class CreatePermissionDto {
}
exports.CreatePermissionDto = CreatePermissionDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.PermissionType, { message: 'Jenis izin tidak valid.' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Jenis izin wajib dipilih.' }),
    __metadata("design:type", String)
], CreatePermissionDto.prototype, "type", void 0);
__decorate([
    (0, class_validator_1.IsString)({ message: 'Alasan wajib berupa teks.' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Alasan izin wajib diisi.' }),
    __metadata("design:type", String)
], CreatePermissionDto.prototype, "reason", void 0);
__decorate([
    (0, class_validator_1.IsISO8601)({}, { message: 'Format tanggal mulai salah (ISO8601).' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Tanggal mulai wajib diisi.' }),
    __metadata("design:type", String)
], CreatePermissionDto.prototype, "startDate", void 0);
__decorate([
    (0, class_validator_1.IsISO8601)({}, { message: 'Format tanggal selesai salah (ISO8601).' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Tanggal selesai wajib diisi.' }),
    __metadata("design:type", String)
], CreatePermissionDto.prototype, "endDate", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Array)
], CreatePermissionDto.prototype, "attachments", void 0);
//# sourceMappingURL=create-permission.dto.js.map