const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Load .env
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

async function main() {
  console.log('--- DIRECT PG DRIVER CONNECTIVITY TEST ---');
  // Strip Prisma-specific query params from DATABASE_URL for pg client compatibility
  const dbUrl = process.env.DATABASE_URL.split('?')[0] + '?sslmode=require';
  console.log('Target URL:', dbUrl);

  const client = new Client({
    connectionString: dbUrl,
  });

  try {
    await client.connect();
    console.log('✅ DATABASE CONNECTED SUCCESSFULLY!');
    
    const res = await client.query('SELECT id, email, role FROM "User";');
    console.log('✅ QUERY SUCCESS! ROWS:', res.rows);
  } catch (err) {
    console.error('❌ PG CONNECTION EXCEPTION:', err);
  } finally {
    await client.end();
  }
}

main();
