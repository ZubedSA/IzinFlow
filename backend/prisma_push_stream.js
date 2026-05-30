const { spawn } = require('child_process');
const fs = require('fs');
const logFile = fs.createWriteStream('prisma_push_output.log');

console.log("Starting streamed Prisma DB Push...");
logFile.write("--- PRIMA DB PUSH STREAM START ---\n");

const child = spawn('npx.cmd', ['prisma', 'db', 'push', '--accept-data-loss'], { shell: true });

child.stdout.on('data', (data) => {
  const msg = data.toString();
  process.stdout.write(msg);
  logFile.write(msg);
});

child.stderr.on('data', (data) => {
  const msg = data.toString();
  process.stderr.write("STDERR: " + msg);
  logFile.write("STDERR: " + msg);
});

child.on('close', (code) => {
  console.log(`\nChild process exited with code ${code}`);
  logFile.write(`\nExited with code ${code}\n`);
});
