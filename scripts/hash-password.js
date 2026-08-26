const crypto = require('node:crypto');
const password = process.argv[2];
if (!password) { console.error('Usage: npm run hash-password -- "your-password"'); process.exit(1); }
const salt = crypto.randomBytes(16).toString('hex');
// ':' avoids Docker Compose treating '$' in a hash as variable interpolation.
console.log(`${salt}:${crypto.scryptSync(password, salt, 64).toString('hex')}`);
