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
exports.RegisterOrgDto = void 0;
const class_validator_1 = require("class-validator");
class RegisterOrgDto {
}
exports.RegisterOrgDto = RegisterOrgDto;
__decorate([
    (0, class_validator_1.IsNotEmpty)({ message: 'Nama organisasi wajib diisi.' }),
    __metadata("design:type", String)
], RegisterOrgDto.prototype, "orgName", void 0);
__decorate([
    (0, class_validator_1.IsNotEmpty)({ message: 'Slug unik organisasi wajib diisi.' }),
    __metadata("design:type", String)
], RegisterOrgDto.prototype, "orgSlug", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], RegisterOrgDto.prototype, "orgAddress", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], RegisterOrgDto.prototype, "orgContact", void 0);
__decorate([
    (0, class_validator_1.IsEmail)({}, { message: 'Format email tidak valid.' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Email administrator wajib diisi.' }),
    __metadata("design:type", String)
], RegisterOrgDto.prototype, "adminEmail", void 0);
__decorate([
    (0, class_validator_1.IsNotEmpty)({ message: 'Password administrator wajib diisi.' }),
    (0, class_validator_1.MinLength)(6, { message: 'Password minimal 6 karakter.' }),
    __metadata("design:type", String)
], RegisterOrgDto.prototype, "adminPassword", void 0);
__decorate([
    (0, class_validator_1.IsNotEmpty)({ message: 'Nama lengkap administrator wajib diisi.' }),
    __metadata("design:type", String)
], RegisterOrgDto.prototype, "adminFullName", void 0);
//# sourceMappingURL=register-org.dto.js.map