ALTER TABLE notification_configs DROP CONSTRAINT IF EXISTS notification_configs_provider_check;
ALTER TABLE notification_configs ADD CONSTRAINT notification_configs_provider_check CHECK (provider IN ('webhook', 'smtp'));
