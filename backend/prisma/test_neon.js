const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

// Manually load env variables
const envPath = path.resolve(__dirname, '../.env');
if (fs.existsSync(envPath)) {
  const envConfig = fs.readFileSync(envPath, 'utf8');
  for (const line of envConfig.split('\n')) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const parts = trimmed.split('=');
      if (parts.length >= 2) {
        const key = parts[0].trim();
        const val = parts.slice(1).join('=').trim().replace(/^"|"$/g, '').replace(/^'|'$/g, '');
        process.env[key] = val;
      }
    }
  }
}

const prisma = new PrismaClient();

async function main() {
  console.log('--- DIRECT NEON QUERY START ---');
  try {
    const user = await prisma.user.findFirst({
      where: { email: 'student@majujaya.sch.id' },
      include: { organization: true }
    });
    console.log('QUERY SUCCESS! USER FOUND:', user ? {
      email: user.email,
      fullName: user.fullName,
      orgName: user.organization.name
    } : 'NOT FOUND');
  } catch (err) {
    console.error('QUERY EXCEPTION OCCURRED:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
