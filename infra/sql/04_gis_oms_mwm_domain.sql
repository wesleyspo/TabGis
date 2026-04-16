-- TabGis — domínio utilities: ref, audit.domain_event, gis, oms, mwm
-- Alinhado a docs/Database_Structure_Context.md (+ owner_id, locked_by_id em oms.work_order)
-- Ordem de aplicação: após 01–03 (ver docs/DEPLOY_POC.md)

-- Bases já criadas com 03 antigo: garantir colunas em operations.work_order
ALTER TABLE operations.work_order
    ADD COLUMN IF NOT EXISTS owner_id INTEGER REFERENCES security.users(id) ON DELETE SET NULL;
ALTER TABLE operations.work_order
    ADD COLUMN IF NOT EXISTS locked_by_id INTEGER REFERENCES security.users(id) ON DELETE SET NULL;

ALTER TABLE security.users ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE security.users ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS gis;
CREATE SCHEMA IF NOT EXISTS oms;
CREATE SCHEMA IF NOT EXISTS mwm;

-- ---- Tabelas de domínio (TYPE / STATUS) — cadastro mínimo POC
CREATE TABLE IF NOT EXISTS ref.consumer_account_status (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.consumer_account_status (id, code, label_en, label_pt) VALUES
    (1, 'active', 'Active', 'Activo'),
    (2, 'suspended', 'Suspended', 'Suspenso')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.consumer_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.consumer_type (id, code, label_en, label_pt) VALUES
    (1, 'residential', 'Residential', 'Residencial'),
    (2, 'commercial', 'Commercial', 'Comercial')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.contract_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.contract_type (id, code, label_en, label_pt) VALUES
    (1, 'standard', 'Standard', 'Padrão')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.equipment_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.equipment_type (id, code, label_en, label_pt) VALUES
    (1, 'substation', 'Substation', 'Subestação'),
    (2, 'feeder', 'Feeder', 'Alimentador')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.network_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.network_type (id, code, label_en, label_pt) VALUES
    (1, 'primary', 'Primary', 'Primário'),
    (2, 'secondary', 'Secondary', 'Secundário')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.network_level (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.network_level (id, code, label_en, label_pt) VALUES
    (1, 'aerial', 'Aerial', 'Aéreo'),
    (2, 'underground', 'Underground', 'Subterrâneo')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.connection_state (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.connection_state (id, code, label_en, label_pt) VALUES
    (1, 'connected', 'Connected', 'Ligado'),
    (2, 'disconnected', 'Disconnected', 'Desligado'),
    (3, 'predicted', 'Predicted', 'Previsto')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.call_type (
    id INTEGER PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.call_type (id, code, label_en, label_pt) VALUES
    (1, 'outage', 'Outage', 'Interrupção'),
    (2, 'complaint', 'Complaint', 'Reclamação')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.feedback_channel (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.feedback_channel (id, code, label_en, label_pt) VALUES
    (1, 'human', 'Human agent', 'Agente humano'),
    (2, 'automatic', 'Automatic', 'Automático')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.work_order_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.work_order_type (id, code, label_en, label_pt) VALUES
    (1, 'repair', 'Repair', 'Reparo'),
    (2, 'inspection', 'Inspection', 'Inspecção')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.task_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.task_type (id, code, label_en, label_pt) VALUES
    (1, 'field_work', 'Field work', 'Trabalho de campo')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.task_status (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.task_status (id, code, label_en, label_pt) VALUES
    (1, 'open', 'Open', 'Aberta'),
    (2, 'done', 'Done', 'Concluída')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.network_event_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.network_event_type (id, code, label_en, label_pt) VALUES
    (1, 'fault', 'Fault', 'Falha'),
    (2, 'switching', 'Switching', 'Manobra')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.crew_status (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.crew_status (id, code, label_en, label_pt) VALUES
    (1, 'available', 'Available', 'Disponível'),
    (2, 'busy', 'Busy', 'Ocupada')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.crew_type (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.crew_type (id, code, label_en, label_pt) VALUES
    (1, 'line', 'Line crew', 'Equipa de linha')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.callback_status (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.callback_status (id, code, label_en, label_pt) VALUES
    (0, 'none', 'None', 'Nenhum'),
    (1, 'pending', 'Pending', 'Pendente')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.system_message_template (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.system_message_template (id, code, label_en, label_pt) VALUES
    (1, 'sms_generic', 'Generic SMS', 'SMS genérico')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS ref.order_handling_process (
    id SMALLINT PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    label_en VARCHAR(120),
    label_pt VARCHAR(120)
);
INSERT INTO ref.order_handling_process (id, code, label_en, label_pt) VALUES
    (1, 'dispatcher', 'Dispatcher', 'Despacho')
ON CONFLICT (id) DO NOTHING;

-- ---- Evento de domínio (rastreio)
CREATE TABLE IF NOT EXISTS audit.domain_event (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actor_user_id INTEGER REFERENCES security.users(id) ON DELETE SET NULL,
    source VARCHAR(32),
    payload JSONB,
    correlation_id VARCHAR(64)
);

CREATE INDEX IF NOT EXISTS idx_domain_event_occurred ON audit.domain_event (occurred_at);
CREATE INDEX IF NOT EXISTS idx_domain_event_actor ON audit.domain_event (actor_user_id);

COMMENT ON TABLE audit.domain_event IS 'Append-only domain change correlation; referenced by event_id on business tables.';

-- ---- GIS
CREATE TABLE IF NOT EXISTS gis.equipment (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    type_id SMALLINT REFERENCES ref.equipment_type(id),
    network_type_id SMALLINT REFERENCES ref.network_type(id),
    network_level_id SMALLINT REFERENCES ref.network_level(id),
    status_0 SMALLINT REFERENCES ref.connection_state(id),
    status_1 SMALLINT REFERENCES ref.connection_state(id),
    status_2 SMALLINT REFERENCES ref.connection_state(id),
    status_3 SMALLINT REFERENCES ref.connection_state(id),
    normal_status_0 SMALLINT REFERENCES ref.connection_state(id),
    normal_status_1 SMALLINT REFERENCES ref.connection_state(id),
    normal_status_2 SMALLINT REFERENCES ref.connection_state(id),
    normal_status_3 SMALLINT REFERENCES ref.connection_state(id),
    monitoring_status_id SMALLINT,
    parent_equipment_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
    location_desc VARCHAR(80),
    geom geometry(Geometry, 4326)
);

CREATE INDEX IF NOT EXISTS idx_gis_equipment_geom ON gis.equipment USING GIST (geom);

CREATE TABLE IF NOT EXISTS gis.consumer (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    account_number VARCHAR(30) NOT NULL UNIQUE,
    status_id SMALLINT REFERENCES ref.consumer_account_status(id),
    type_id SMALLINT REFERENCES ref.consumer_type(id),
    equipment_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
    parent_equipment_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
    last_name VARCHAR(64),
    first_name VARCHAR(64),
    email VARCHAR(255),
    identity_document_type VARCHAR(16),
    identity_document_number VARCHAR(32),
    contract_type_id SMALLINT REFERENCES ref.contract_type(id),
    first_connection_date DATE,
    connection_start_date DATE,
    connection_end_date DATE,
    street_type VARCHAR(64),
    street_name VARCHAR(64),
    house_number VARCHAR(10),
    apartment_number VARCHAR(10),
    postal_code VARCHAR(10),
    city VARCHAR(30),
    state VARCHAR(30),
    primary_phone_number VARCHAR(16),
    secondary_phone_number VARCHAR(16),
    description VARCHAR(80),
    smart_meter BOOLEAN DEFAULT FALSE,
    location_desc VARCHAR(80),
    geom geometry(Point, 4326),
    accepts_proactive_contact BOOLEAN DEFAULT FALSE,
    utility_domain VARCHAR(16)
);

CREATE INDEX IF NOT EXISTS idx_gis_consumer_geom ON gis.consumer USING GIST (geom);

-- ---- OMS: work_order primeiro (referências circulares resolvidas depois)
CREATE TABLE IF NOT EXISTS oms.work_order (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    order_number VARCHAR(24) NOT NULL UNIQUE,
    status VARCHAR(32),
    type_id SMALLINT REFERENCES ref.work_order_type(id),
    order_group VARCHAR(14),
    aval_dif SMALLINT,
    metric_tp NUMERIC,
    metric_tl NUMERIC,
    metric_tr NUMERIC,
    metric_ta NUMERIC,
    base_op TEXT,
    micro_region TEXT,
    feeder TEXT,
    outage_count INTEGER,
    customers_interrupted_current INTEGER,
    number_of_calls INTEGER,
    last_call_at TIMESTAMPTZ,
    duration_minutes INTEGER,
    chi TEXT,
    dm_partial NUMERIC,
    chi_projected NUMERIC,
    equipment_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
    equipment_type_code VARCHAR(10),
    crew_count INTEGER,
    prep_crew_1 NUMERIC,
    prep_crew_2 NUMERIC,
    etr TIMESTAMPTZ,
    auto_callback_status SMALLINT REFERENCES ref.callback_status(id),
    human_callback_status SMALLINT REFERENCES ref.callback_status(id),
    organization_label VARCHAR(50),
    etd TEXT,
    complaint_summary VARCHAR(512),
    priority INTEGER,
    comment VARCHAR(1000),
    customer_message VARCHAR(255),
    organization_id INTEGER,
    order_created_at TIMESTAMPTZ,
    outage_start_time TIMESTAMPTZ,
    crew_owner_id BIGINT,
    main_crew_id BIGINT,
    owner_id INTEGER REFERENCES security.users(id) ON DELETE SET NULL,
    locked_by_id INTEGER REFERENCES security.users(id) ON DELETE SET NULL,
    assigned_at TIMESTAMPTZ,
    dispatched_at TIMESTAMPTZ,
    enroute_at TIMESTAMPTZ,
    on_site_at TIMESTAMPTZ,
    released_at TIMESTAMPTZ,
    rank_priority NUMERIC,
    repeat_incident VARCHAR(3),
    incident_status VARCHAR(40),
    planned_flag SMALLINT,
    operational_type VARCHAR(16),
    burst_et_calls INTEGER,
    sectioned_wire_calls INTEGER,
    distinct_calls INTEGER,
    broken_tree INTEGER,
    broken_pole INTEGER,
    operational_unit TEXT,
    location_desc VARCHAR(80),
    geom geometry(Geometry, 4326),
    critical_customers INTEGER
);

CREATE INDEX IF NOT EXISTS idx_oms_work_order_geom ON oms.work_order USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_oms_work_order_status ON oms.work_order (status);

CREATE TABLE IF NOT EXISTS oms.call (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    processor_id BIGINT,
    type_id INTEGER REFERENCES ref.call_type(id),
    simple_area_id BIGINT,
    consumer_id BIGINT REFERENCES gis.consumer(id) ON DELETE SET NULL,
    account_number VARCHAR(30),
    originating_number VARCHAR(32),
    description VARCHAR(50),
    field_time_received TIMESTAMPTZ,
    system_time_received TIMESTAMPTZ,
    received_by VARCHAR(6),
    comments VARCHAR(500),
    status VARCHAR(16) DEFAULT 'open',
    scheduled_start_time TIMESTAMPTZ,
    informative BOOLEAN DEFAULT FALSE,
    predict BOOLEAN DEFAULT FALSE,
    caller_name VARCHAR(80),
    contact_no VARCHAR(32),
    email VARCHAR(50),
    callback BOOLEAN DEFAULT FALSE,
    work_order_id BIGINT REFERENCES oms.work_order(id) ON DELETE SET NULL,
    handled_by SMALLINT REFERENCES ref.order_handling_process(id),
    system_generated BOOLEAN DEFAULT FALSE,
    auto_callback_status SMALLINT REFERENCES ref.callback_status(id),
    human_callback_status SMALLINT REFERENCES ref.callback_status(id),
    location_resolved BOOLEAN DEFAULT FALSE,
    location_desc VARCHAR(80),
    geom geometry(Point, 4326)
);

CREATE INDEX IF NOT EXISTS idx_oms_call_work_order ON oms.call (work_order_id);

CREATE TABLE IF NOT EXISTS oms.call_feedback (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    call_id BIGINT REFERENCES oms.call(id) ON DELETE SET NULL,
    channel_id SMALLINT REFERENCES ref.feedback_channel(id),
    system_msg_id SMALLINT REFERENCES ref.system_message_template(id),
    human_msg VARCHAR(1000)
);

-- ---- MWM crew (FKs para work_order adiados)
CREATE TABLE IF NOT EXISTS mwm.crew (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    crew_code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    status_id SMALLINT REFERENCES ref.crew_status(id),
    type_id SMALLINT REFERENCES ref.crew_type(id),
    leader_name VARCHAR(120),
    time_in_service INTERVAL,
    last_order_id BIGINT,
    current_order_id BIGINT,
    next_order_id BIGINT,
    idle_time INTERVAL,
    base_op VARCHAR(120),
    organization_id INTEGER,
    last_crew_update_at TIMESTAMPTZ,
    last_coord_update_at TIMESTAMPTZ,
    current_neighborhood_id BIGINT,
    geom geometry(Point, 4326)
);

CREATE INDEX IF NOT EXISTS idx_mwm_crew_geom ON mwm.crew USING GIST (geom);

ALTER TABLE oms.work_order DROP CONSTRAINT IF EXISTS fk_oms_wo_crew_owner;
ALTER TABLE oms.work_order
    ADD CONSTRAINT fk_oms_wo_crew_owner FOREIGN KEY (crew_owner_id) REFERENCES mwm.crew(id) ON DELETE SET NULL;
ALTER TABLE oms.work_order DROP CONSTRAINT IF EXISTS fk_oms_wo_main_crew;
ALTER TABLE oms.work_order
    ADD CONSTRAINT fk_oms_wo_main_crew FOREIGN KEY (main_crew_id) REFERENCES mwm.crew(id) ON DELETE SET NULL;

ALTER TABLE mwm.crew DROP CONSTRAINT IF EXISTS fk_mwm_crew_last_order;
ALTER TABLE mwm.crew
    ADD CONSTRAINT fk_mwm_crew_last_order FOREIGN KEY (last_order_id) REFERENCES oms.work_order(id) ON DELETE SET NULL;
ALTER TABLE mwm.crew DROP CONSTRAINT IF EXISTS fk_mwm_crew_current_order;
ALTER TABLE mwm.crew
    ADD CONSTRAINT fk_mwm_crew_current_order FOREIGN KEY (current_order_id) REFERENCES oms.work_order(id) ON DELETE SET NULL;
ALTER TABLE mwm.crew DROP CONSTRAINT IF EXISTS fk_mwm_crew_next_order;
ALTER TABLE mwm.crew
    ADD CONSTRAINT fk_mwm_crew_next_order FOREIGN KEY (next_order_id) REFERENCES oms.work_order(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS mwm.crew_order_assignment (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    work_order_id BIGINT NOT NULL REFERENCES oms.work_order(id) ON DELETE RESTRICT,
    task_id BIGINT,
    crew_id BIGINT NOT NULL REFERENCES mwm.crew(id) ON DELETE RESTRICT,
    status VARCHAR(16),
    assigned_time TIMESTAMPTZ,
    dispatched_time TIMESTAMPTZ,
    enroute_time TIMESTAMPTZ,
    arrived_time TIMESTAMPTZ,
    released_time TIMESTAMPTZ,
    is_main_crew BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_mwm_assign_wo ON mwm.crew_order_assignment (work_order_id);
CREATE INDEX IF NOT EXISTS idx_mwm_assign_crew ON mwm.crew_order_assignment (crew_id);

CREATE TABLE IF NOT EXISTS oms.task (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    work_order_id BIGINT NOT NULL REFERENCES oms.work_order(id) ON DELETE RESTRICT,
    crew_assignment_id BIGINT REFERENCES mwm.crew_order_assignment(id) ON DELETE SET NULL,
    type_id SMALLINT REFERENCES ref.task_type(id),
    status_id SMALLINT REFERENCES ref.task_status(id),
    field_date TIMESTAMPTZ,
    system_date TIMESTAMPTZ,
    equipment_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
    comments TEXT,
    parent_task_id BIGINT REFERENCES oms.task(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_oms_task_wo ON oms.task (work_order_id);

ALTER TABLE mwm.crew_order_assignment DROP CONSTRAINT IF EXISTS fk_mwm_assign_task;
ALTER TABLE mwm.crew_order_assignment
    ADD CONSTRAINT fk_mwm_assign_task FOREIGN KEY (task_id) REFERENCES oms.task(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS oms.network_event (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    work_order_id BIGINT REFERENCES oms.work_order(id) ON DELETE SET NULL,
    type_id SMALLINT REFERENCES ref.network_event_type(id),
    field_date TIMESTAMPTZ,
    system_date TIMESTAMPTZ,
    equipment_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
    status_0 SMALLINT REFERENCES ref.connection_state(id),
    status_1 SMALLINT REFERENCES ref.connection_state(id),
    status_2 SMALLINT REFERENCES ref.connection_state(id),
    status_3 SMALLINT REFERENCES ref.connection_state(id),
    task_id BIGINT REFERENCES oms.task(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS oms.customer_interruption (
    id BIGSERIAL PRIMARY KEY,
    consumer_id BIGINT NOT NULL REFERENCES gis.consumer(id) ON DELETE RESTRICT,
    start_event_id BIGINT,
    end_event_id BIGINT,
    CONSTRAINT fk_ci_start_ne FOREIGN KEY (start_event_id) REFERENCES oms.network_event(id) ON DELETE SET NULL,
    CONSTRAINT fk_ci_end_ne FOREIGN KEY (end_event_id) REFERENCES oms.network_event(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS mwm.crew_shift (
    id BIGSERIAL PRIMARY KEY,
    crew_id BIGINT NOT NULL REFERENCES mwm.crew(id) ON DELETE RESTRICT,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    shift_availability_start TIMESTAMPTZ,
    shift_availability_end TIMESTAMPTZ,
    last_change_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS mwm.crew_route_daily (
    id BIGSERIAL PRIMARY KEY,
    crew_id BIGINT NOT NULL REFERENCES mwm.crew(id) ON DELETE RESTRICT,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    locations_today JSONB,
    locations_yesterday JSONB,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mwm.crew_route_history (
    id BIGSERIAL PRIMARY KEY,
    crew_id BIGINT NOT NULL REFERENCES mwm.crew(id) ON DELETE RESTRICT,
    event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    route_geom geometry(MultiLineString, 4326),
    source VARCHAR(64)
);

CREATE INDEX IF NOT EXISTS idx_mwm_route_hist_geom ON mwm.crew_route_history USING GIST (route_geom);

-- ---- Dados mínimos para API / UI (idempotente)
INSERT INTO security.users (username, email, first_name, last_name, access_type, status) VALUES
    ('admin', 'sistema@operacao.tabgis.local', 'Sistema', 'TabGis', 'ADMIN', 'offline'),
    ('operador1', 'ricardo.almeida@operacao.tabgis.local', 'Ricardo', 'Almeida', 'OPERACAO', 'offline')
ON CONFLICT (username) DO NOTHING;

INSERT INTO operations.team (team_code, name, leader_name, skill, team_type, owner_org, zone, member_count, status)
VALUES
    ('EQ-ALPHA', 'Equipa Alpha', 'Ana Costa', 'BT / MT', 'Linha', 'UO Centro', 'Zona Leste', 4, 'active'),
    ('EQ-BETA', 'Equipa Beta', 'Bruno Dias', 'Subestações', 'Linha', 'UO Centro', 'Zona Sul', 3, 'active'),
    ('EQ-GAMA', 'Equipa Gama', 'Carla Mota', 'Telecomando', 'Apoio', 'UO Norte', 'Zona Norte', 2, 'standby')
ON CONFLICT (team_code) DO NOTHING;

INSERT INTO operations.work_order (order_code, category, summary, description, status, priority, assigned_team_id, owner_id)
SELECT v.order_code, v.category, v.summary, v.description, v.status, v.priority, t.id, u.id
FROM (VALUES
    ('ORD-2026-0142', 'repair', 'Inspecção subestação SE-Tatuapé', 'Termografia em barramentos e isoladores 23 kV.', 'open', 'P1', 'EQ-ALPHA'),
    ('ORD-2026-0143', 'complaint', 'Reclamação BT — interrupção parcial', 'Atendimento prioritário; verificar ramal de baixa tensão.', 'in_progress', 'P2', 'EQ-BETA'),
    ('TSK-2026-0088', 'task', 'Leitura de campo e AMI', 'Conferência de medidor inteligente e registo fotográfico.', 'scheduled', 'P3', 'EQ-ALPHA'),
    ('EVT-2026-0004', 'event', 'Manobra programada — alimentador 12', 'Comunicação prévia a clientes e religação assistida.', 'planned', 'P2', 'EQ-GAMA')
) AS v(order_code, category, summary, description, status, priority, team_code)
JOIN operations.team t ON t.team_code = v.team_code
JOIN security.users u ON u.username = 'operador1'
ON CONFLICT (order_code) DO NOTHING;
