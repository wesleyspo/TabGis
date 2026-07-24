-- Renomear basemap → landbase apenas se existir (bases novas podem já usar landbase)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'basemap') THEN
        EXECUTE 'ALTER SCHEMA basemap RENAME TO landbase';
    END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS landbase;

-- ==========================================
-- 1. SCHEMA CONFIG (Parâmetros e Traduções)
-- ==========================================
CREATE SCHEMA IF NOT EXISTS config;

-- Idiomas suportados
CREATE TABLE IF NOT EXISTS config.language (
    id SERIAL PRIMARY KEY,
    code VARCHAR(5) UNIQUE NOT NULL, -- en, pt, es, it
    name VARCHAR(50) NOT NULL
);

INSERT INTO config.language (code, name) VALUES
    ('en', 'English'),
    ('pt', 'Português'),
    ('es', 'Español'),
    ('it', 'Italiano')
ON CONFLICT (code) DO NOTHING;

-- Tabela de Parâmetros do Sistema
CREATE TABLE IF NOT EXISTS config.parameter (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(50) NOT NULL, -- string, integer, boolean, json, etc
    value TEXT,
    is_visible BOOLEAN DEFAULT TRUE,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Traduções (Aplica-se aos parâmetros e outros objetos no Landbase)
CREATE TABLE IF NOT EXISTS config.translation (
    id SERIAL PRIMARY KEY,
    object_id VARCHAR(100) NOT NULL, -- ID do objeto (ex: parameter name ou feature id)
    language_id INTEGER REFERENCES config.language(id),
    translated_text TEXT NOT NULL,
    UNIQUE (object_id, language_id)
);

-- ==========================================
-- 2. SCHEMA SECURITY (Controle de Acesso)
-- ==========================================
CREATE SCHEMA IF NOT EXISTS security;

-- Migração idempotente: legado security."user" → security.users (ver docs/mds/Database_Structure_Context.md)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'security' AND table_name = 'user'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'security' AND table_name = 'users'
    ) THEN
        EXECUTE 'ALTER TABLE security."user" RENAME TO users';
    END IF;
END $$;

-- Utilizadores (tabela canónica: security.users)
CREATE TABLE IF NOT EXISTS security.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    status VARCHAR(20) DEFAULT 'offline',
    last_login_host VARCHAR(50),
    last_login_time TIMESTAMP,
    access_type VARCHAR(20) DEFAULT 'CONSULTA',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 3. SCHEMA AUDIT (Auditoria do Sistema)
-- ==========================================
CREATE SCHEMA IF NOT EXISTS audit;

-- Histórico de alterações de parâmetros
CREATE TABLE IF NOT EXISTS audit.parameter_history (
    id SERIAL PRIMARY KEY,
    parameter_id INTEGER NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by_user_id INTEGER REFERENCES security.users(id) ON DELETE SET NULL
);

-- Histórico de acessos/logins
CREATE TABLE IF NOT EXISTS audit.login_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES security.users(id) ON DELETE SET NULL,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    login_host VARCHAR(50),
    status VARCHAR(20) -- 'SUCCESS', 'FAILED'
);

-- ==========================================
-- 4. TRIGGERS DE AUDITORIA E ATUALIZAÇÃO
-- ==========================================

-- Atualiza updated_at no parameter
CREATE OR REPLACE FUNCTION config.update_parameter_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_parameter_updated_at ON config.parameter;
CREATE TRIGGER trg_parameter_updated_at
BEFORE UPDATE ON config.parameter
FOR EACH ROW
EXECUTE FUNCTION config.update_parameter_timestamp();

-- Audita mudanças de valor no parameter
CREATE OR REPLACE FUNCTION audit.log_parameter_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF OLD.value IS DISTINCT FROM NEW.value THEN
            INSERT INTO audit.parameter_history (parameter_id, old_value, new_value)
            VALUES (OLD.id, OLD.value, NEW.value);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_parameter ON config.parameter;
CREATE TRIGGER trg_audit_parameter
AFTER UPDATE ON config.parameter
FOR EACH ROW
EXECUTE FUNCTION audit.log_parameter_changes();
