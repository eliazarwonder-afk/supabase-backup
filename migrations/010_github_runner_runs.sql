ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS execution_provider text NOT NULL DEFAULT 'local';
ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS runner_token_hash text;
ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS runner_token_expires_at timestamptz;
ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS runner_dispatched_at timestamptz;
ALTER TABLE backup_runs ALTER COLUMN execution_provider SET DEFAULT 'github';
ALTER TABLE backup_runs ADD CONSTRAINT backup_runs_execution_provider_check CHECK (execution_provider IN ('local', 'github'));
CREATE INDEX IF NOT EXISTS backup_runs_runner_token_idx ON backup_runs(runner_token_hash) WHERE runner_token_hash IS NOT NULL;
ALTER TABLE backup_jobs ADD COLUMN IF NOT EXISTS execution_provider text NOT NULL DEFAULT 'github';
ALTER TABLE backup_jobs ADD CONSTRAINT backup_jobs_execution_provider_check CHECK (execution_provider IN ('local', 'github'));
