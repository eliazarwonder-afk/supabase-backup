ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS backup_folder text;
ALTER TABLE backup_runs ADD COLUMN IF NOT EXISTS storage_key text;
