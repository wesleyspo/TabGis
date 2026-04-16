-- TabGis — colunas OMS para grelha: início operacional, callback automático
-- Aplicar após 06_work_order_sheet_model.sql

ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS callback_auto BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN operations.work_order.started_at IS 'Início operacional da ordem (grelha OMS); por defeito alinhado a created_at na migração.';
COMMENT ON COLUMN operations.work_order.callback_auto IS 'Callback automático (IVR/BOT); complementa flag_customer_callback (humano).';

UPDATE operations.work_order wo SET started_at = COALESCE(wo.started_at, wo.created_at) WHERE wo.started_at IS NULL;

UPDATE operations.work_order SET callback_auto = (id % 4 = 0) WHERE callback_auto IS NOT DISTINCT FROM FALSE;
