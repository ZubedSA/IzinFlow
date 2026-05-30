import * as fs from 'fs';
import * as path from 'path';

// 1. Resolve absolute path of .env relative to the project root
const envPath = path.resolve(process.cwd(), '.env');

if (fs.existsSync(envPath)) {
  const envConfig = fs.readFileSync(envPath, 'utf8');
  for (const line of envConfig.split('\n')) {
    const trimmed = line.trim();
    // Ignore empty lines and comments
    if (trimmed && !trimmed.startsWith('#')) {
      const separatorIndex = trimmed.indexOf('=');
      if (separatorIndex !== -1) {
        const key = trimmed.substring(0, separatorIndex).trim();
        const val = trimmed.substring(separatorIndex + 1).trim().replace(/^"|"$/g, '').replace(/^'|'$/g, '');
        if (key && val) {
          // Explicitly assign to process.env
          process.env[key] = val;
        }
      }
    }
  }
}
