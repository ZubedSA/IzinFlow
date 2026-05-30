const { execSync } = require('child_process');
try {
  console.log("Starting Prisma DB Push via child_process...");
  const output = execSync('npx.cmd prisma db push --accept-data-loss', { encoding: 'utf-8', stdio: 'pipe' });
  console.log("DB PUSH SUCCESS:");
  console.log(output);
} catch (error) {
  console.log("DB PUSH ERROR:");
  if (error.stdout) console.log("STDOUT:\n" + error.stdout);
  if (error.stderr) console.log("STDERR:\n" + error.stderr);
  console.log("MESSAGE:\n" + error.message);
}
