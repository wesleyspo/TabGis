-- TabGis — folha da ordem: código diário (America/Sao_Paulo), tarefas, reclamações
-- Eventos não entram na listagem OMS (order_type/category = event excluídos na API; category legacy)
-- Aplicar após 03_operations_schema.sql (e dados 05 se existirem)

-- Alterações de colunas (idempotente)
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS order_type VARCHAR(24) DEFAULT 'incident';
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS organization_label VARCHAR(120);
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS municipality_name VARCHAR(120);
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS neighborhood_name VARCHAR(120);
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS equipment_code VARCHAR(64);
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS feeder_code VARCHAR(64);
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS affected_customers_count INTEGER DEFAULT 0;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS complaints_linked_count INTEGER DEFAULT 0;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS flag_safety_risk BOOLEAN DEFAULT FALSE;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS flag_critical_infra BOOLEAN DEFAULT FALSE;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS flag_customer_callback BOOLEAN DEFAULT FALSE;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS priority_score SMALLINT;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS focus_lat DOUBLE PRECISION;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS focus_lng DOUBLE PRECISION;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE operations.work_order ADD COLUMN IF NOT EXISTS callback_auto BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN operations.work_order.order_type IS 'Tipo operacional da ordem (repair, maintenance, inspection, emergency, restoration, incident). Não usar event aqui.';
COMMENT ON COLUMN operations.work_order.complaints_linked_count IS 'Número de reclamações ligadas (denormalizado; actualizado por trigger).';
COMMENT ON COLUMN operations.work_order.started_at IS 'Início operacional da ordem (grelha OMS); alinhado a created_at quando nulo.';
COMMENT ON COLUMN operations.work_order.callback_auto IS 'Callback automático (IVR/BOT); complementa flag_customer_callback (humano).';

UPDATE operations.work_order wo SET started_at = COALESCE(wo.started_at, wo.created_at) WHERE wo.started_at IS NULL;

-- Criação de tabelas de filhos (idempotente)
CREATE TABLE IF NOT EXISTS operations.work_order_task (
    id SERIAL PRIMARY KEY,
    work_order_id INTEGER NOT NULL REFERENCES operations.work_order(id) ON DELETE CASCADE,
    sequence_no SMALLINT NOT NULL DEFAULT 1,
    summary TEXT NOT NULL,
    status VARCHAR(24) DEFAULT 'open',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_wo_task_order ON operations.work_order_task (work_order_id);

CREATE TABLE IF NOT EXISTS operations.work_order_complaint (
    id SERIAL PRIMARY KEY,
    work_order_id INTEGER NOT NULL REFERENCES operations.work_order(id) ON DELETE CASCADE,
    complaint_ref VARCHAR(40),
    channel VARCHAR(32),
    caller_name VARCHAR(120),
    contact_phone VARCHAR(32),
    status VARCHAR(24) DEFAULT 'open',
    summary TEXT,
    received_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_wo_complaint_order ON operations.work_order_complaint (work_order_id);

-- Updates e Inserts de dados de exemplo (idempotente)
-- Remover prefixos de ordens existentes para alinhar com o novo formato.
UPDATE operations.work_order wo SET
    order_code = REPLACE(REPLACE(REPLACE(wo.order_code, 'ORD-', ''), 'EVT-', ''), 'TSK-', '')
WHERE wo.order_code LIKE 'ORD-%'
   OR wo.order_code LIKE 'EVT-%'
   OR wo.order_code LIKE 'TSK-%';

UPDATE operations.work_order wo SET
    organization_label = COALESCE(wo.organization_label, 'UO RMSP — Operações'),
    municipality_name = COALESCE(wo.municipality_name, 'São Paulo'),
    neighborhood_name = COALESCE(wo.neighborhood_name, (ARRAY['Tatuapé', 'Vila Prudente', 'Pinheiros', 'Osasco Centro', 'Guarulhos Centro'])[((wo.id - 1) % 5) + 1]),
    equipment_code = COALESCE(wo.equipment_code, 'TR-' || (1000 + wo.id)::text),
    feeder_code = COALESCE(wo.feeder_code, 'AF-' || (7 + (wo.id % 5))::text),
    affected_customers_count = COALESCE(NULLIF(wo.affected_customers_count, 0), 12 + (wo.id % 80)),
    flag_safety_risk = COALESCE(wo.flag_safety_risk, (wo.id % 5) = 0),
    flag_critical_infra = COALESCE(wo.flag_critical_infra, (wo.id % 7) = 0),
    flag_customer_callback = COALESCE(wo.flag_customer_callback, wo.category = 'complaint'),
    priority_score = COALESCE(wo.priority_score, CASE wo.priority WHEN 'P1' THEN 1 WHEN 'P2' THEN 2 WHEN 'P3' THEN 3 ELSE 4 END),
    focus_lat = COALESCE(wo.focus_lat, -23.55 - (wo.id % 10) * 0.012),
    focus_lng = COALESCE(wo.focus_lng, -46.63 - (wo.id % 8) * 0.015),
    order_type = CASE
        WHEN wo.category = 'event' THEN 'event'
        ELSE CASE wo.category
            WHEN 'repair' THEN 'repair'
            WHEN 'task' THEN 'maintenance'
            WHEN 'complaint' THEN 'incident'
            ELSE COALESCE(NULLIF(btrim(COALESCE(wo.order_type, '')), ''), 'incident')
        END
    END;

INSERT INTO operations.work_order_task (work_order_id, sequence_no, summary, status)
SELECT wo.id, 1, 'Deslocamento e reconhecimento de campo', 'in_progress'
FROM operations.work_order wo
WHERE wo.category <> 'event'
  AND NOT EXISTS (SELECT 1 FROM operations.work_order_task t WHERE t.work_order_id = wo.id)
LIMIT 20;

INSERT INTO operations.work_order_task (work_order_id, sequence_no, summary, status)
SELECT wo.id, 2, 'Execução do serviço e fecho documental', 'open'
FROM operations.work_order wo
WHERE wo.category NOT IN ('event', 'complaint')
  AND EXISTS (SELECT 1 FROM operations.work_order_task t WHERE t.work_order_id = wo.id AND t.sequence_no = 1)
  AND NOT EXISTS (SELECT 1 FROM operations.work_order_task t2 WHERE t2.work_order_id = wo.id AND t2.sequence_no = 2)
LIMIT 15;

INSERT INTO operations.work_order_complaint (work_order_id, complaint_ref, channel, caller_name, contact_phone, status, summary, received_at)
SELECT wo.id,
       'REC-' || to_char(CURRENT_DATE, 'YYYYMMDD') || lpad((wo.id % 999)::text, 3, '0'),
       CASE (wo.id % 3) WHEN 0 THEN 'telefone' WHEN 1 THEN 'portal' ELSE 'CC' END,
       'Cliente ' || (wo.id % 50),
       '11 9' || lpad((1000 + wo.id)::text, 4, '0'),
       'open',
       'Reclamação associada à ordem — acompanhamento em campo.',
       CURRENT_TIMESTAMP - ((wo.id % 48) || ' hours')::interval
FROM operations.work_order wo
WHERE COALESCE(wo.order_type, wo.category) <> 'event'
  AND NOT EXISTS (SELECT 1 FROM operations.work_order_complaint c WHERE c.work_order_id = wo.id)
LIMIT 15;

INSERT INTO operations.work_order_complaint (work_order_id, complaint_ref, channel, caller_name, status, summary)
SELECT wo.id, 'REC-2-' || wo.id::text, 'telefone', 'Morador', 'open', 'Reclamação adicional na mesma ordem.'
FROM operations.work_order wo
WHERE wo.category = 'complaint'
  AND (SELECT COUNT(*) FROM operations.work_order_complaint c WHERE c.work_order_id = wo.id) = 1
LIMIT 4;

UPDATE operations.work_order wo SET complaints_linked_count = cnt FROM (
    SELECT work_order_id, COUNT(*)::int AS cnt FROM operations.work_order_complaint GROUP BY work_order_id
) s WHERE wo.id = s.work_order_id; 