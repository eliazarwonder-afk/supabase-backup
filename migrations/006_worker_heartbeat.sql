CREATE TABLE IF NOT EXISTS worker_heartbeats (
  worker_id text PRIMARY KEY,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  active_run_id uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);
