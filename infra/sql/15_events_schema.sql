-- Schema events: diário append-only alinhado a documentos (Mongo / DB externo).
-- Cada linha ≈ um documento BSON exportável (event_uuid, domain, event_type, payload, metadata).
-- Idempotência futura: event_uuid único; dedupe por cliente via metadata->>'client_event_id'.

CREATE SCHEMA IF NOT EXISTS events;

CREATE TABLE IF NOT EXISTS events.event (
  id BIGSERIAL PRIMARY KEY,
  event_uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  schema_version SMALLINT NOT NULL DEFAULT 1 CHECK (schema_version >= 1),
  domain VARCHAR(32) NOT NULL,
  event_type VARCHAR(160) NOT NULL,
  aggregate_type VARCHAR(80),
  aggregate_id VARCHAR(128),
  correlation_id UUID,
  causation_id UUID,
  actor_type VARCHAR(32) NOT NULL DEFAULT 'api',
  actor_id VARCHAR(64),
  source VARCHAR(80) NOT NULL DEFAULT 'tabgis-api',
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT events_domain_lower CHECK (domain = lower(domain))
);

COMMENT ON SCHEMA events IS 'Event store canónico (compatível mentalmente com coleção Mongo event_report).';
COMMENT ON TABLE events.event IS 'Um evento = um registo imutável; payload/metadata em JSONB para evolução sem ALTER frequente.';

CREATE INDEX IF NOT EXISTS idx_events_occurred ON events.event (occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_domain_type ON events.event (domain, event_type);
CREATE INDEX IF NOT EXISTS idx_events_aggregate ON events.event (aggregate_type, aggregate_id);
CREATE INDEX IF NOT EXISTS idx_events_correlation ON events.event (correlation_id) WHERE correlation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_events_payload_gin ON events.event USING GIN (payload);

-- Ponto único de escrita (API, triggers futuros, jobs) → facilita replicação / ETL para Mongo.
CREATE OR REPLACE FUNCTION events.append_event(
  p_domain TEXT,
  p_event_type TEXT,
  p_payload JSONB,
  p_aggregate_type TEXT DEFAULT NULL,
  p_aggregate_id TEXT DEFAULT NULL,
  p_correlation_id UUID DEFAULT NULL,
  p_causation_id UUID DEFAULT NULL,
  p_actor_type TEXT DEFAULT 'api',
  p_actor_id TEXT DEFAULT NULL,
  p_source TEXT DEFAULT 'tabgis-api',
  p_metadata JSONB DEFAULT '{}'::JSONB
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_uuid UUID;
BEGIN
  INSERT INTO events.event (
    domain,
    event_type,
    aggregate_type,
    aggregate_id,
    correlation_id,
    causation_id,
    actor_type,
    actor_id,
    source,
    payload,
    metadata
  ) VALUES (
    lower(btrim(p_domain)),
    btrim(p_event_type),
    NULLIF(btrim(p_aggregate_type), ''),
    NULLIF(btrim(p_aggregate_id), ''),
    p_correlation_id,
    p_causation_id,
    lower(btrim(p_actor_type)),
    NULLIF(btrim(p_actor_id), ''),
    btrim(p_source),
    COALESCE(p_payload, '{}'::JSONB),
    COALESCE(p_metadata, '{}'::JSONB)
  )
  RETURNING event_uuid INTO v_uuid;
  RETURN v_uuid;
END;
$$;

COMMENT ON FUNCTION events.append_event IS 'Inserção canónica de evento; usar a partir da API ou de triggers PL/pgSQL.';
