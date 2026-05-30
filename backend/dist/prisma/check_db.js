"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('--- ALTERING DATABASE TABLE START ---');
    try {
        await prisma.$executeRawUnsafe('ALTER TABLE "ApprovalLog" ALTER COLUMN "teacherId" DROP NOT NULL;');
        console.log('SUCCESS: Table altered successfully! Column "teacherId" is now optional.');
    }
    catch (err) {
        console.error('DATABASE ALTER ERROR:', err);
    }
    finally {
        await prisma.$disconnect();
    }
}
main();
//# sourceMappingURL=check_db.js.map