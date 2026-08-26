ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS cancel_requested boolean NOT NULL DEFAULT false;
ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS attempt integer NOT NULL DEFAULT 1;
