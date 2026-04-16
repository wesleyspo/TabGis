-- TabGis — enriquecimento de dados operacionais fictícios (RMSP / utilities genérico)
-- Idempotente. Aplicar após 04_gis_oms_mwm_domain.sql

-- Perfis e contactos mais realistas (actualiza registos já existentes)
UPDATE security.users SET
    first_name = 'Sistema',
    last_name = 'TabGis',
    email = 'sistema@operacao.tabgis.local'
WHERE username = 'admin';

UPDATE security.users SET
    first_name = 'Ricardo',
    last_name = 'Almeida',
    email = 'ricardo.almeida@operacao.tabgis.local'
WHERE username = 'operador1';

INSERT INTO security.users (username, email, first_name, last_name, access_type, status) VALUES
    ('marina.silva', 'marina.silva@operacao.tabgis.local', 'Marina', 'Silva', 'OPERACAO', 'offline'),
    ('despacho.centro', 'despacho.centro@operacao.tabgis.local', 'Centro', 'Despacho', 'OPERACAO', 'offline'),
    ('gilberto.nunes', 'gilberto.nunes@operacao.tabgis.local', 'Gilberto', 'Nunes', 'ADMIN', 'offline'),
    ('ana.miranda', 'ana.miranda@operacao.tabgis.local', 'Ana', 'Miranda', 'CONSULTA', 'offline')
ON CONFLICT (username) DO NOTHING;

-- Última posição conhecida (WGS84) e carimbo temporal — equipas em campo
UPDATE operations.team SET
    last_known_geom = ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326),
    last_coordinate_at = CURRENT_TIMESTAMP - INTERVAL '42 minutes',
    last_updated_at = CURRENT_TIMESTAMP
WHERE team_code = 'EQ-ALPHA';

UPDATE operations.team SET
    last_known_geom = ST_SetSRID(ST_MakePoint(-46.6544, -23.5629), 4326),
    last_coordinate_at = CURRENT_TIMESTAMP - INTERVAL '2 hours 15 minutes',
    last_updated_at = CURRENT_TIMESTAMP
WHERE team_code = 'EQ-BETA';

UPDATE operations.team SET
    last_known_geom = ST_SetSRID(ST_MakePoint(-46.7021, -23.5988), 4326),
    last_coordinate_at = CURRENT_TIMESTAMP - INTERVAL '26 hours',
    last_updated_at = CURRENT_TIMESTAMP
WHERE team_code = 'EQ-GAMA';

INSERT INTO operations.team (team_code, name, leader_name, skill, team_type, owner_org, zone, member_count, status, last_known_geom, last_coordinate_at, last_updated_at)
VALUES
    ('EQ-DELTA', 'Equipa Delta', 'Mariana Oliveira', 'Emergência BT / desligamentos', 'Linha', 'UO Leste', 'Guarulhos', 5, 'active',
     ST_SetSRID(ST_MakePoint(-46.5333, -23.4542), 4326), CURRENT_TIMESTAMP - INTERVAL '28 minutes', CURRENT_TIMESTAMP),
    ('EQ-EPSILON', 'Equipa Épsilon', 'Paulo Ferreira', 'Rede subterrânea / cabos', 'Linha', 'UO Oeste', 'Osasco', 4, 'active',
     ST_SetSRID(ST_MakePoint(-46.7917, -23.5329), 4326), CURRENT_TIMESTAMP - INTERVAL '1 hour 20 minutes', CURRENT_TIMESTAMP),
    ('EQ-ZETA', 'Equipa Zeta', 'Fernanda Rocha', 'Telemetria e religadores', 'Apoio', 'UO Norte', 'Mairiporã', 3, 'standby',
     ST_SetSRID(ST_MakePoint(-46.5833, -23.3189), 4326), CURRENT_TIMESTAMP - INTERVAL '8 hours', CURRENT_TIMESTAMP)
ON CONFLICT (team_code) DO UPDATE SET
    name = EXCLUDED.name,
    leader_name = EXCLUDED.leader_name,
    skill = EXCLUDED.skill,
    zone = EXCLUDED.zone,
    member_count = EXCLUDED.member_count,
    status = EXCLUDED.status,
    last_known_geom = EXCLUDED.last_known_geom,
    last_coordinate_at = EXCLUDED.last_coordinate_at,
    last_updated_at = EXCLUDED.last_updated_at;

-- Ordens adicionais (vários responsáveis)
INSERT INTO operations.work_order (order_code, category, summary, description, status, priority, assigned_team_id, owner_id)
SELECT v.order_code, v.category, v.summary, v.description, v.status, v.priority, t.id, u.id
FROM (VALUES
    ('ORD-2026-0142', 'repair', 'Inspecção subestação SE-Tatuapé', 'Termografia em barramentos e isoladores 23 kV.', 'open', 'P1', 'EQ-ALPHA', 'operador1'),
    ('ORD-2026-0201', 'repair', 'Substituição seccionadora AF-07', 'Zona industrial — corte programado com cliente informado.', 'open', 'P1', 'EQ-DELTA', 'despacho.centro'),
    ('ORD-2026-0204', 'complaint', 'Tensão instável BT — Vila Prudente', 'Reclamação recorrente; verificar ramal e transformador.', 'in_progress', 'P2', 'EQ-BETA', 'marina.silva'),
    ('ORD-2026-0208', 'task', 'Leitura e conferência AMI', 'Medidor inteligente Av. Paulista — ciclo de leitura.', 'scheduled', 'P3', 'EQ-EPSILON', 'ana.miranda'),
    ('EVT-2026-0102', 'event', 'Manobra programada alimentador 12', 'Comunicação prévia a clientes prioritários.', 'planned', 'P2', 'EQ-GAMA', 'gilberto.nunes'),
    ('TSK-2026-0155', 'task', 'Poda preventiva sob rede', 'Via pública com AVCB e escolta municipal.', 'scheduled', 'P3', 'EQ-ZETA', 'marina.silva'),
    ('ORD-2026-0211', 'repair', 'Religador 3F disparado — rearme', 'Análise de registos DFR e inspecção de campo.', 'open', 'P1', 'EQ-EPSILON', 'despacho.centro'),
    ('ORD-2026-0214', 'complaint', 'Odores / arco visível em poste', 'Prioridade segurança pública; desligamento condicional.', 'in_progress', 'P1', 'EQ-DELTA', 'operador1')
) AS v(order_code, category, summary, description, status, priority, team_code, owner_username)
JOIN operations.team t ON t.team_code = v.team_code
JOIN security.users u ON u.username = v.owner_username
ON CONFLICT (order_code) DO UPDATE SET
    summary = EXCLUDED.summary,
    description = EXCLUDED.description,
    status = EXCLUDED.status,
    priority = EXCLUDED.priority,
    assigned_team_id = EXCLUDED.assigned_team_id,
    owner_id = EXCLUDED.owner_id,
    updated_at = CURRENT_TIMESTAMP;
