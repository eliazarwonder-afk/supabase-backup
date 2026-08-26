CREATE TABLE IF NOT EXISTS app_settings (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notification_configs (
  id uuid PRIMARY KEY,
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('webhook')),
  endpoint_encrypted text,
  enabled boolean NOT NULL DEFAULT true,
  events jsonb NOT NULL DEFAULT '["backup.failed", "restore.failed"]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS audit_logs_project_created_idx ON audit_logs(project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS backup_runs_target_status_idx ON backup_runs(database_target_id, status, completed_at DESC);
