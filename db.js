const fs = require('node:fs');
const path = require('node:path');
const { Pool } = require('pg');

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, max: Number(process.env.DB_POOL_SIZE || 10), ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : undefined });

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('CREATE TABLE IF NOT EXISTS schema_migrations (filename text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())');
    const dir = path.join(__dirname, 'migrations');
    for (const filename of fs.readdirSync(dir).filter(x => x.endsWith('.sql')).sort()) {
      const exists = await client.query('SELECT 1 FROM schema_migrations WHERE filename=$1', [filename]);
      if (exists.rowCount) continue;
      await client.query('BEGIN');
      try { await client.query(fs.readFileSync(path.join(dir, filename), 'utf8')); await client.query('INSERT INTO schema_migrations(filename) VALUES($1)', [filename]); await client.query('COMMIT'); } catch (e) { await client.query('ROLLBACK'); throw e; }
    }
  } finally { client.release(); }
}

async function query(text, params) { return pool.query(text, params); }
async function close() { await pool.end(); }
module.exports = { pool, migrate, query, close };
