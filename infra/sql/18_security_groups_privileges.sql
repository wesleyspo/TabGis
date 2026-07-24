-- RBAC básico para TabGis: colaborador -> grupo -> N privilégios.
-- Ordem: após 01_init_schemas.sql.
-- Aplicar: docker exec -i infra-db-1 psql -U tabgis_admin -d tabgis_db < infra/sql/18_security_groups_privileges.sql

CREATE TABLE IF NOT EXISTS security.privilege (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(80) UNIQUE NOT NULL,
  label_pt VARCHAR(140) NOT NULL,
  label_en VARCHAR(140),
  description TEXT
);

CREATE TABLE IF NOT EXISTS security.user_group (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(48) UNIQUE NOT NULL,
  name VARCHAR(120) NOT NULL,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  is_system BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS security.group_privilege (
  group_id BIGINT NOT NULL REFERENCES security.user_group(id) ON DELETE CASCADE,
  privilege_id BIGINT NOT NULL REFERENCES security.privilege(id) ON DELETE CASCADE,
  PRIMARY KEY (group_id, privilege_id)
);

CREATE TABLE IF NOT EXISTS security.user_group_member (
  user_id INTEGER NOT NULL REFERENCES security.users(id) ON DELETE CASCADE,
  group_id BIGINT NOT NULL REFERENCES security.user_group(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, group_id)
);

ALTER TABLE security.users
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

UPDATE security.users
SET is_active = CASE
  WHEN lower(COALESCE(status, '')) IN ('inactive', 'disabled', 'desativado') THEN FALSE
  ELSE TRUE
END
WHERE is_active IS DISTINCT FROM CASE
  WHEN lower(COALESCE(status, '')) IN ('inactive', 'disabled', 'desativado') THEN FALSE
  ELSE TRUE
END;

-- Catálogo de privilégios (módulos e configuração).
INSERT INTO security.privilege (code, label_pt, label_en, description) VALUES
  ('module.oms', 'Módulo OMS', 'OMS module', 'Acesso operacional a ordens e folha OMS'),
  ('module.mwm', 'Módulo MWM', 'MWM module', 'Acesso a equipas, rotas e deslocamentos'),
  ('module.ind', 'Módulo IND', 'IND module', 'Acesso a indicadores operacionais'),
  ('module.smt', 'Módulo SMT', 'SMT module', 'Acesso a instalações e telemetria'),
  ('module.tmp', 'Módulo TMP', 'TMP module', 'Acesso a clima e operações de campo'),
  ('module.aud', 'Módulo AUD', 'AUD module', 'Acesso a auditoria e conformidade'),
  ('module.esq', 'Módulo ESQ', 'ESQ module', 'Acesso a esquemático e unifilar'),
  ('module.dms', 'Módulo DMS', 'DMS module', 'Acesso a telecomando remoto'),
  ('config.parameters', 'Parâmetros', 'Parameters', 'Gestão de parâmetros/configuração sensível'),
  ('config.users', 'Utilizadores', 'Users', 'Gestão de utilizadores, grupos e privilégios'),
  ('config.ref_types', 'Tipos de domínio ref.*', 'Reference types', 'Gestão de labels ref.*'),
  ('config.translations', 'Traduções', 'Translations', 'Gestão de traduções'),
  ('config.visualization', 'Visualização', 'Visualization', 'Gestão de preferências de visualização'),
  ('action.callback_only', 'Apenas callback', 'Callback only', 'Operação limitada a callbacks')
ON CONFLICT (code) DO UPDATE
SET label_pt = EXCLUDED.label_pt,
    label_en = EXCLUDED.label_en,
    description = EXCLUDED.description;

INSERT INTO security.user_group (code, name, is_admin, is_system) VALUES
  ('ADMIN', 'Administrador', TRUE, TRUE),
  ('CALL_CENTER', 'Call-Center', FALSE, TRUE),
  ('CALLBACK_ONLY', 'Apenas Callback', FALSE, TRUE),
  ('OPER_NO_DMS_NO_PARAMS', 'Operação (sem DMS e sem parâmetros)', FALSE, TRUE),
  ('OPER_DMS_NO_PARAMS', 'Operação + DMS (sem parâmetros)', FALSE, TRUE),
  ('DMS_ONLY', 'DMS (apenas DMS)', FALSE, TRUE),
  ('READ_ONLY_ALL', 'Consulta (somente visualização)', FALSE, TRUE)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    is_admin = EXCLUDED.is_admin;

WITH grp AS (
  SELECT id, code, is_admin FROM security.user_group
),
prv AS (
  SELECT id, code FROM security.privilege
),
pairs AS (
  -- ADMIN: todos os privilégios
  SELECT g.id AS group_id, p.id AS privilege_id
  FROM grp g
  JOIN prv p ON TRUE
  WHERE g.is_admin = TRUE

  UNION ALL
  -- CALL CENTER
  SELECT g.id, p.id FROM grp g JOIN prv p ON p.code IN (
    'module.oms', 'module.mwm', 'module.tmp', 'module.ind', 'module.aud', 'action.callback_only'
  ) WHERE g.code = 'CALL_CENTER'

  UNION ALL
  -- APENAS CALLBACK
  SELECT g.id, p.id FROM grp g JOIN prv p ON p.code IN (
    'module.oms', 'action.callback_only'
  ) WHERE g.code = 'CALLBACK_ONLY'

  UNION ALL
  -- OPERAÇÃO (SEM DMS/PARÂMETROS)
  SELECT g.id, p.id FROM grp g JOIN prv p ON p.code IN (
    'module.oms', 'module.mwm', 'module.ind', 'module.smt', 'module.tmp', 'module.aud', 'module.esq'
  ) WHERE g.code = 'OPER_NO_DMS_NO_PARAMS'

  UNION ALL
  -- OPERAÇÃO + DMS (SEM PARÂMETROS)
  SELECT g.id, p.id FROM grp g JOIN prv p ON p.code IN (
    'module.oms', 'module.mwm', 'module.ind', 'module.smt', 'module.tmp', 'module.aud', 'module.esq', 'module.dms'
  ) WHERE g.code = 'OPER_DMS_NO_PARAMS'

  UNION ALL
  -- DMS APENAS
  SELECT g.id, p.id FROM grp g JOIN prv p ON p.code IN (
    'module.dms'
  ) WHERE g.code = 'DMS_ONLY'

  UNION ALL
  -- CONSULTA (VISUALIZAÇÃO)
  SELECT g.id, p.id FROM grp g JOIN prv p ON p.code IN (
    'module.oms', 'module.mwm', 'module.ind', 'module.smt', 'module.tmp', 'module.aud', 'module.esq', 'module.dms'
  ) WHERE g.code = 'READ_ONLY_ALL'
)
INSERT INTO security.group_privilege (group_id, privilege_id)
SELECT DISTINCT group_id, privilege_id
FROM pairs
ON CONFLICT DO NOTHING;

-- Backfill mínimo: ADMIN -> admin, OPER -> operação, CONSULTA -> leitura.
INSERT INTO security.user_group_member (user_id, group_id)
SELECT u.id, g.id
FROM security.users u
JOIN security.user_group g
  ON g.code = CASE
    WHEN upper(COALESCE(u.access_type, '')) = 'ADMIN' THEN 'ADMIN'
    WHEN upper(COALESCE(u.access_type, '')) = 'OPERACAO' THEN 'OPER_NO_DMS_NO_PARAMS'
    ELSE 'READ_ONLY_ALL'
  END
WHERE NOT EXISTS (
  SELECT 1
  FROM security.user_group_member m
  WHERE m.user_id = u.id
);
