ALTER TABLE restore_jobs ADD COLUMN IF NOT EXISTS backup_folder text;
CREATE INDEX IF NOT EXISTS restore_jobs_status_idx ON restore_jobs(status, started_at);
