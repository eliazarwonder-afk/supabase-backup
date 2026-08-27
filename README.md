# Supabase VaultManager

Secure Coolify-friendly UI for the official Supabase three-file backup flow.

## Run locally

1. Copy `.env.example` to `.env`, set `ADMIN_USERNAME`, a strong `ADMIN_INITIAL_PASSWORD`, and a random encryption key. The initial password is converted to bcrypt and stored in the control database on first successful login; for legacy deployments, `ADMIN_PASSWORD_HASH_B64` remains supported. For plain HTTP local development, add `COOKIE_SECURE=false` (production must use HTTPS).
3. Start with `docker compose up --build` and open `http://localhost:3000`.

The Compose stack includes an independent PostgreSQL control database and a separate `vaultmanager-worker` service. Set `CONTROL_DB_PASSWORD` and do not point `DATABASE_URL` at a target Supabase database. New backup runs are dispatched to GitHub Actions; the worker handles scheduling, dispatching, lifecycle updates, and restores.

The application accepts bcrypt hashes such as `$2a$12$...` and its own colon-separated scrypt hashes. `ADMIN_PASSWORD_HASH_B64` is a legacy bootstrap option; normal deployments should use `ADMIN_INITIAL_PASSWORD`, then remove it from Coolify after the first successful login. Password changes are performed in the Security screen and stored as bcrypt hashes.

Connection strings are encrypted at rest with AES-256-GCM. They are never returned to the browser or logged. Backups are archived as `.tar.gz` files. Use `BACKUP_STORAGE=local` for the named `vaultmanager_data` volume, or `BACKUP_STORAGE=s3` with `S3_BUCKET`, `S3_REGION`, and AWS credentials for object storage. S3 downloads use 15-minute presigned URLs. The official Supabase CLI dump workflow requires a Docker-compatible runtime because it runs a filtered `pg_dump` inside a Supabase Postgres image; the worker therefore fails clearly when Docker is unavailable instead of silently producing a generic dump.

## GitHub Actions backup runner

Backups run in GitHub Actions, not inside the Coolify container. The Action uses the official Supabase CLI and Docker-enabled GitHub-hosted runner to create `roles.sql`, `schema.sql`, and `data.sql`. It uploads each file directly to VaultManager; VaultManager creates and verifies the archive, then keeps it on the local volume or uploads it to the configured S3 storage.

### One-time setup

1. Copy [`github-workflow/supabase-backup.yml`](github-workflow/supabase-backup.yml) into the connected repository at `.github/workflows/supabase-backup.yml`.
2. Add a repository secret named `VAULTMANAGER_URL`, containing the public HTTPS URL of this installation.
3. Create a GitHub App and install it only on that repository. Give it **Actions: Read and write** and **Metadata: Read-only** repository permissions. Keep all other permissions disabled.
4. In VaultManager, open **GitHub App**, enter the App ID, installation ID, owner, repository, workflow filename, and the downloaded RSA private-key PEM. Save it and press **Test**.
5. Select local or S3 storage in VaultManager/Coolify. The current backup pipeline uses the configured `BACKUP_STORAGE` destination and verifies the S3 object with `head-object` before marking the run successful.

For the automatic **Connect GitHub App through GitHub** button, configure `GITHUB_APP_ID`, `GITHUB_APP_SLUG`, and `GITHUB_APP_PRIVATE_KEY` in Coolify. Set the GitHub App **Setup URL** to `https://your-vaultmanager-domain.example/api/github/callback`. The user must already be signed in to VaultManager; GitHub handles approval and redirects back. VaultManager validates the signed state and installation through GitHub’s API, then stores the installation and first accessible repository without asking the user to paste IDs or keys.

Pressing **Run backup** dispatches the workflow with a random, expiring, one-time runner token. The token is stored only as a SHA-256 hash in PostgreSQL. The Action uses it to fetch the target connection over HTTPS and upload the three files. The target URL, GitHub private key, and installation token are never written to logs or returned by the normal browser API.

The included workflow pins Supabase CLI `2.115.0`. Update that version deliberately after testing in a non-production repository; do not use an unpinned `latest` download in production.

Keep `APP_ENCRYPTION_KEY` stable. If it is changed, existing target connection strings, storage credentials, notification credentials, and GitHub private keys cannot be decrypted. Rotate the GitHub private key in GitHub and replace the stored connection if it is exposed. Never commit the PEM or paste it into logs.

## Scheduled backups and history

Set `BACKUP_CRON` to a five-field UTC cron expression. The default job created for each target uses this schedule, and scheduling is performed by the worker from PostgreSQL with row locking. `CRON_TARGET_ID` is retained only for compatibility and is no longer required. Example: `30 2 * * *` runs daily at 02:30 UTC. Completed and failed backups are recorded durably in the control database and shown in the dashboard; successful backups have a Download action. `RETENTION_COUNT` removes older local archives and S3 objects after a successful run. For critical environments, prefer an external scheduler or Coolify scheduled task because the in-process timer stops when the container is stopped.

Set `NOTIFY_WEBHOOK_URL` in Coolify to receive non-secret JSON notifications for `backup.completed` and `backup.failed`. The endpoint is never returned to the browser and connection strings are excluded from notification payloads. Audit activity is stored in PostgreSQL and is available through the authenticated activity endpoint. Application settings are stored in PostgreSQL through the authenticated settings endpoint; secrets remain environment-managed.

`GET /api/system/health` is intentionally public for platform probes. It checks the control database and requires a worker heartbeat less than 45 seconds old; it never exposes credentials or connection strings.

## Coolify

Deploy this repository as a Docker Compose resource. Set the three required environment variables in Coolify, expose port `3000`, and attach HTTPS. For a Supabase database in another service, use its private network hostname in the PostgreSQL URL. Do not expose PostgreSQL publicly just for this app.

Do not paste the bcrypt hash or other secrets into `docker-compose.yml`. Set `ADMIN_PASSWORD_HASH_B64` in Coolify's Environment Variables section. This prevents `$2a$12$...` from being parsed as YAML or Compose interpolation. After changing any secret, redeploy the resource so both the web and worker containers receive the same values.

Restore requires the exact backup folder name and typing `RESTORE`. Restore operations are queued in PostgreSQL and executed by the worker, so a web-container restart does not silently interrupt them. The server validates target names and folder names, and child processes receive argument arrays, never a shell command string. Use HTTPS in Coolify and never commit `.env` or `data/`.
