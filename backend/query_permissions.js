const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const pending = await prisma.permissionRequest.findMany({
      where: { status: 'PENDING' },
      include: {
        student: {
          include: {
            user: true,
            classRoom: true,
          },
        },
      },
    });
    console.log('--- PENDING PERMISSIONS ---');
    console.log(JSON.stringify(pending, null, 2));
  } catch (err) {
    console.error('ERROR:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
