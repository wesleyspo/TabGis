-- TabGis — schema operations + arquivo obrigatório antes de DELETE
-- Tabelas em inglês. Regra: nada é removido de operations.* sem snapshot em audit.operations_row_archive
-- (trigger BEFORE DELETE).

CREATE SCHEMA IF NOT EXISTS operations;

-- Equipas em campo (primeiro foco)
CREATE TABLE IF NOT EXISTS operations.team (
    id SERIAL PRIMARY KEY,
    team_code VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(120) NOT NULL,
    leader_name VARCHAR(120),
    skill VARCHAR(120),
    team_type VARCHAR(64),
    owner_org VARCHAR(120),
    zone VARCHAR(120),
    member_count INTEGER DEFAULT 0,
    status VARCHAR(32) DEFAULT 'active',
    last_coordinate_at TIMESTAMPTZ,
    last_updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_known_geom geometry(Point, 4326),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_team_status ON operations.team (status);
CREATE INDEX IF NOT EXISTS idx_team_last_coord ON operations.team (last_coordinate_at);

COMMENT ON TABLE operations.team IS 'Field teams; links to work orders via team_order_displacement; routes in team_route.';

-- Ordens: tarefas, reparos, reclamações, eventos
CREATE TABLE IF NOT EXISTS operations.work_order (
    id SERIAL PRIMARY KEY,
    order_code VARCHAR(40) UNIQUE NOT NULL,
    category VARCHAR(24) NOT NULL,
    summary TEXT,
    description TEXT,
    status VARCHAR(32) DEFAULT 'open',
    priority VARCHAR(24),
    assigned_team_id INTEGER REFERENCES operations.team(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_work_order_category ON operations.work_order (category);
CREATE INDEX IF NOT EXISTS idx_work_order_status ON operations.work_order (status);

COMMENT ON TABLE operations.work_order IS 'Work orders: task, repair, complaint, event (category).';

-- Relacionamento equipa ↔ ordem + horários de deslocamento
CREATE TABLE IF NOT EXISTS operations.team_order_displacement (
    id SERIAL PRIMARY KEY,
    team_id INTEGER NOT NULL REFERENCES operations.team(id) ON DELETE RESTRICT,
    work_order_id INTEGER NOT NULL REFERENCES operations.work_order(id) ON DELETE RESTRICT,
    planned_departure_at TIMESTAMPTZ,
    planned_arrival_at TIMESTAMPTZ,
    actual_departure_at TIMESTAMPTZ,
    actual_arrival_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (team_id, work_order_id)
);

CREATE INDEX IF NOT EXISTS idx_displacement_team ON operations.team_order_displacement (team_id);
CREATE INDEX IF NOT EXISTS idx_displacement_order ON operations.team_order_displacement (work_order_id);

COMMENT ON TABLE operations.team_order_displacement IS 'Team assignment to orders with planned/actual displacement windows.';

-- Rota acumulada (ex.: janela móvel 48h) — geometria MultiLineString ou LineString
CREATE TABLE IF NOT EXISTS operations.team_route (
    id BIGSERIAL PRIMARY KEY,
    team_id INTEGER NOT NULL REFERENCES operations.team(id) ON DELETE RESTRICT,
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    route_geom geometry(MultiLineString, 4326),
    source VARCHAR(64) DEFAULT 'tracker',
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_team_route_team ON operations.team_route (team_id);
CREATE INDEX IF NOT EXISTS idx_team_route_window ON operations.team_route (window_start, window_end);

COMMENT ON TABLE operations.team_route IS 'Full route geometry for a time window (e.g. last 48h per team).';

-- Arquivo obrigatório antes de DELETE nas tabelas principais de operations
CREATE TABLE IF NOT EXISTS audit.operations_row_archive (
    id BIGSERIAL PRIMARY KEY,
    source_schema TEXT NOT NULL,
    source_table TEXT NOT NULL,
    source_id TEXT NOT NULL,
    row_data JSONB NOT NULL,
    archived_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    archive_reason TEXT,
    archived_by_user_id INTEGER REFERENCES security.user(id)
);

CREATE INDEX IF NOT EXISTS idx_ops_archive_table ON audit.operations_row_archive (source_table, source_id);

COMMENT ON TABLE audit.operations_row_archive IS 'Mandatory snapshot before DELETE from operations.*; never delete from main without inserting here first (enforced by trigger).';

CREATE OR REPLACE FUNCTION audit.archive_operations_row_before_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit.operations_row_archive (source_schema, source_table, source_id, row_data, archive_reason)
    VALUES (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        OLD.id::TEXT,
        to_jsonb(row_to_json(OLD)),
        'BEFORE_DELETE'
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_team_archive_delete ON operations.team;
CREATE TRIGGER trg_team_archive_delete
    BEFORE DELETE ON operations.team
    FOR EACH ROW
    EXECUTE FUNCTION audit.archive_operations_row_before_delete();

DROP TRIGGER IF EXISTS trg_work_order_archive_delete ON operations.work_order;
CREATE TRIGGER trg_work_order_archive_delete
    BEFORE DELETE ON operations.work_order
    FOR EACH ROW
    EXECUTE FUNCTION audit.archive_operations_row_before_delete();

DROP TRIGGER IF EXISTS trg_displacement_archive_delete ON operations.team_order_displacement;
CREATE TRIGGER trg_displacement_archive_delete
    BEFORE DELETE ON operations.team_order_displacement
    FOR EACH ROW
    EXECUTE FUNCTION audit.archive_operations_row_before_delete();

DROP TRIGGER IF EXISTS trg_team_route_archive_delete ON operations.team_route;
CREATE TRIGGER trg_team_route_archive_delete
    BEFORE DELETE ON operations.team_route
    FOR EACH ROW
    EXECUTE FUNCTION audit.archive_operations_row_before_delete();
