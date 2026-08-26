const bcrypt = require('bcryptjs');
const password = process.argv[2];
if (!password || password.length < 12) { console.error('Usage: npm run hash-bcrypt -- "a-password-of-at-least-12-characters"'); process.exit(1); }
const hash = bcrypt.hashSync(password, 12);
console.log('Bcrypt hash:');
console.log(hash);
console.log('\nCoolify ADMIN_PASSWORD_HASH_B64:');
console.log(Buffer.from(hash, 'utf8').toString('base64'));
