# Supabase VaultManager

Secure Coolify-friendly UI for the official Supabase three-file backup flow.

## Run locally

1. Generate a password hash: `npm run hash-password -- "use-a-long-password"`.
2. Copy `.env.example` to `.env`, set the hash and a random encryption key. For plain HTTP local development, add `COOKIE_SECURE=false` (production must use HTTPS).
3. Start with `docker compose up --build` and open `http://localhost:3000`.

If an older deployment used a `$`-separated password hash, regenerate it with the command above and replace the Coolify secret with the new colon-separated value. An unescaped `$` in a Compose `.env` value can be interpreted as variable interpolation.

Connection strings are encrypted at rest with AES-256-GCM. They are never returned to the browser or logged. Backups are archived as `.tar.gz` files. Use `BACKUP_STORAGE=local` for the named `vaultmanager_data` volume, or `BACKUP_STORAGE=s3` with `S3_BUCKET`, `S3_REGION`, and AWS credentials for object storage. S3 downloads use 15-minute presigned URLs.

## Scheduled backups and history

Set `BACKUP_CRON` to a five-field cron expression and `CRON_TARGET_ID` to the target UUID in `data/vault.json` after adding a connection. Example: `30 2 * * *` runs daily at 02:30 in the container timezone. Completed and failed backups are recorded in `history.json` and shown in the dashboard; successful backups have a Download action. For critical environments, prefer an external scheduler or Coolify scheduled task because the in-process timer stops when the container is stopped.

## Coolify

Deploy this repository as a Docker Compose resource. Set the three required environment variables in Coolify, expose port `3000`, and attach HTTPS. For a Supabase database in another service, use its private network hostname in the PostgreSQL URL. Do not expose PostgreSQL publicly just for this app.

Restore requires the exact backup folder name and typing `RESTORE`. The server validates target names and folder names, serializes jobs to prevent overlapping operations, and executes child processes with argument arrays, never a shell command string. Use HTTPS in Coolify and never commit `.env` or `data/`.
