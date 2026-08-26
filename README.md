# Supabase VaultManager

Secure Coolify-friendly UI for the official Supabase three-file backup flow.

## Run locally

1. Generate a password hash: `npm run hash-password -- "use-a-long-password"`.
2. Copy `.env.example` to `.env`, set the hash and a random encryption key. For plain HTTP local development, add `COOKIE_SECURE=false` (production must use HTTPS).
3. Start with `docker compose up --build` and open `http://localhost:3000`.

The application accepts bcrypt hashes such as `$2a$12$...` and its own colon-separated scrypt hashes. Set `ADMIN_PASSWORD_HASH_B64` to base64 of the complete hash so Compose never parses bcrypt's `$` characters. Example: `node -e "process.stdout.write(Buffer.from(process.argv[1]).toString('base64'))" '$2a$12$your-hash'`.

Connection strings are encrypted at rest with AES-256-GCM. They are never returned to the browser or logged. Backups are archived as `.tar.gz` files. Use `BACKUP_STORAGE=local` for the named `vaultmanager_data` volume, or `BACKUP_STORAGE=s3` with `S3_BUCKET`, `S3_REGION`, and AWS credentials for object storage. S3 downloads use 15-minute presigned URLs.

## Scheduled backups and history

Set `BACKUP_CRON` to a five-field cron expression and `CRON_TARGET_ID` to the target UUID in `data/vault.json` after adding a connection. Example: `30 2 * * *` runs daily at 02:30 in the container timezone. Completed and failed backups are recorded in `history.json` and shown in the dashboard; successful backups have a Download action. For critical environments, prefer an external scheduler or Coolify scheduled task because the in-process timer stops when the container is stopped.

## Coolify

Deploy this repository as a Docker Compose resource. Set the three required environment variables in Coolify, expose port `3000`, and attach HTTPS. For a Supabase database in another service, use its private network hostname in the PostgreSQL URL. Do not expose PostgreSQL publicly just for this app.

Do not paste the bcrypt hash or other secrets into `docker-compose.yml`. The Compose file intentionally uses pass-through entries such as `- ADMIN_PASSWORD_HASH`; set the values in Coolify's Environment Variables section. This prevents `$2a$12$...` from being parsed as YAML or Compose interpolation.

Restore requires the exact backup folder name and typing `RESTORE`. The server validates target names and folder names, serializes jobs to prevent overlapping operations, and executes child processes with argument arrays, never a shell command string. Use HTTPS in Coolify and never commit `.env` or `data/`.
