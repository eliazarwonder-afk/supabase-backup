# Supabase VaultManager

Secure Coolify-friendly UI for the official Supabase three-file backup flow.

## Run locally

1. Copy `.env.example` to `.env`, set `ADMIN_USERNAME`, a strong `ADMIN_INITIAL_PASSWORD`, and a random encryption key. The initial password is converted to bcrypt and stored in the control database on first successful login; for legacy deployments, `ADMIN_PASSWORD_HASH_B64` remains supported. For plain HTTP local development, add `COOKIE_SECURE=false` (production must use HTTPS).
3. Start with `docker compose up --build` and open `http://localhost:3000`.

The Compose stack includes an independent PostgreSQL control database and a separate `vaultmanager-worker` service. Set `CONTROL_DB_PASSWORD` and do not point `DATABASE_URL` at a target Supabase database. The web service queues backup runs; the worker claims them from PostgreSQL and executes the Supabase CLI.

The application accepts bcrypt hashes such as `$2a$12$...` and its own colon-separated scrypt hashes. `ADMIN_PASSWORD_HASH_B64` is a legacy bootstrap option; normal deployments should use `ADMIN_INITIAL_PASSWORD`, then remove it from Coolify after the first successful login. Password changes are performed in the Security screen and stored as bcrypt hashes.

Connection strings are encrypted at rest with AES-256-GCM. They are never returned to the browser or logged. Backups are archived as `.tar.gz` files. Use `BACKUP_STORAGE=local` for the named `vaultmanager_data` volume, or `BACKUP_STORAGE=s3` with `S3_BUCKET`, `S3_REGION`, and AWS credentials for object storage. S3 downloads use 15-minute presigned URLs.

## Scheduled backups and history

Set `BACKUP_CRON` to a five-field UTC cron expression. The default job created for each target uses this schedule, and scheduling is performed by the worker from PostgreSQL with row locking. `CRON_TARGET_ID` is retained only for compatibility and is no longer required. Example: `30 2 * * *` runs daily at 02:30 UTC. Completed and failed backups are recorded durably in the control database and shown in the dashboard; successful backups have a Download action. `RETENTION_COUNT` removes older local archives and S3 objects after a successful run. For critical environments, prefer an external scheduler or Coolify scheduled task because the in-process timer stops when the container is stopped.

Set `NOTIFY_WEBHOOK_URL` in Coolify to receive non-secret JSON notifications for `backup.completed` and `backup.failed`. The endpoint is never returned to the browser and connection strings are excluded from notification payloads. Audit activity is stored in PostgreSQL and is available through the authenticated activity endpoint. Application settings are stored in PostgreSQL through the authenticated settings endpoint; secrets remain environment-managed.

`GET /api/system/health` is intentionally public for platform probes. It checks the control database and requires a worker heartbeat less than 45 seconds old; it never exposes credentials or connection strings.

## Coolify

Deploy this repository as a Docker Compose resource. Set the three required environment variables in Coolify, expose port `3000`, and attach HTTPS. For a Supabase database in another service, use its private network hostname in the PostgreSQL URL. Do not expose PostgreSQL publicly just for this app.

Do not paste the bcrypt hash or other secrets into `docker-compose.yml`. Set `ADMIN_PASSWORD_HASH_B64` in Coolify's Environment Variables section. This prevents `$2a$12$...` from being parsed as YAML or Compose interpolation. After changing any secret, redeploy the resource so both the web and worker containers receive the same values.

Restore requires the exact backup folder name and typing `RESTORE`. Restore operations are queued in PostgreSQL and executed by the worker, so a web-container restart does not silently interrupt them. The server validates target names and folder names, and child processes receive argument arrays, never a shell command string. Use HTTPS in Coolify and never commit `.env` or `data/`.
