import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- ALTERING DATABASE TABLE START ---');
  try {
    // Run raw SQL to alter teacherId to be nullable
    await prisma.$executeRawUnsafe('ALTER TABLE "ApprovalLog" ALTER COLUMN "teacherId" DROP NOT NULL;');
    console.log('SUCCESS: Table altered successfully! Column "teacherId" is now optional.');
  } catch (err) {
    console.error('DATABASE ALTER ERROR:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
