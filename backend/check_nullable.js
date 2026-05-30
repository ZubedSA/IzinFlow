const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const prisma = new PrismaClient();

async function main() {
  let log = '--- DB DIAGNOSTIC START ---\n';
  try {
    log += 'Attempting to run ALTER COLUMN DROP NOT NULL...\n';
    await prisma.$executeRawUnsafe('ALTER TABLE "ApprovalLog" ALTER COLUMN "teacherId" DROP NOT NULL;');
    log += 'ALTER TABLE executed successfully!\n';

    // Query column status
    const result = await prisma.$queryRawUnsafe(
      'SELECT column_name, is_nullable FROM information_schema.columns WHERE table_name = \'ApprovalLog\' AND column_name = \'teacherId\';'
    );
    log += 'COLUMN STATUS: ' + JSON.stringify(result) + '\n';
  } catch (err) {
    log += 'ERROR: ' + err.message + '\n';
  } finally {
    await prisma.$disconnect();
    fs.writeFileSync('db_result.txt', log);
    console.log(log);
  }
}

main();
