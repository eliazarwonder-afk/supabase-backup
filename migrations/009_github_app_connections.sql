CREATE TABLE IF NOT EXISTS github_app_connections (
  id uuid PRIMARY KEY,
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  app_id bigint NOT NULL CHECK (app_id > 0),
  installation_id bigint NOT NULL CHECK (installation_id > 0),
  owner text NOT NULL,
  repository text NOT NULL,
  workflow_file text NOT NULL DEFAULT '.github/workflows/supabase-backup.yml',
  default_ref text NOT NULL DEFAULT 'main',
  api_base_url text NOT NULL DEFAULT 'https://api.github.com',
  private_key_encrypted text NOT NULL,
  webhook_secret_encrypted text,
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(project_id, name)
);

CREATE INDEX IF NOT EXISTS github_app_connections_project_idx
  ON github_app_connections(project_id, created_at DESC);
