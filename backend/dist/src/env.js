"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const fs = require("fs");
const path = require("path");
const envPath = path.resolve(process.cwd(), '.env');
if (fs.existsSync(envPath)) {
    const envConfig = fs.readFileSync(envPath, 'utf8');
    for (const line of envConfig.split('\n')) {
        const trimmed = line.trim();
        if (trimmed && !trimmed.startsWith('#')) {
            const separatorIndex = trimmed.indexOf('=');
            if (separatorIndex !== -1) {
                const key = trimmed.substring(0, separatorIndex).trim();
                const val = trimmed.substring(separatorIndex + 1).trim().replace(/^"|"$/g, '').replace(/^'|'$/g, '');
                if (key && val) {
                    process.env[key] = val;
                }
            }
        }
    }
}
//# sourceMappingURL=env.js.map