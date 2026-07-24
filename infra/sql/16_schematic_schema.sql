-- Esquemático / unifilar / rótulos de fluxo (qualitativos).
-- Ordem: após gis/operations estabelecidos; opcional: equipment_id → gis.equipment.
-- Aplicar: docker exec -i <postgis> psql -U tabgis_admin -d tabgis_db < infra/sql/16_schematic_schema.sql

CREATE SCHEMA IF NOT EXISTS schematic;

CREATE TABLE IF NOT EXISTS schematic.network_view (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  view_kind VARCHAR(32) NOT NULL DEFAULT 'unifilar' CHECK (view_kind IN ('unifilar', 'power_flow', 'hybrid')),
  description TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS schematic.view_node (
  id BIGSERIAL PRIMARY KEY,
  view_id BIGINT NOT NULL REFERENCES schematic.network_view(id) ON DELETE CASCADE,
  seq_no INT NOT NULL DEFAULT 0,
  label VARCHAR(200) NOT NULL,
  symbol_code VARCHAR(32),
  equipment_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
  focus_lat DOUBLE PRECISION,
  focus_lng DOUBLE PRECISION,
  props JSONB NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT schematic_node_seq_nonneg CHECK (seq_no >= 0)
);

CREATE TABLE IF NOT EXISTS schematic.view_edge (
  id BIGSERIAL PRIMARY KEY,
  view_id BIGINT NOT NULL REFERENCES schematic.network_view(id) ON DELETE CASCADE,
  from_node_id BIGINT NOT NULL REFERENCES schematic.view_node(id) ON DELETE CASCADE,
  to_node_id BIGINT NOT NULL REFERENCES schematic.view_node(id) ON DELETE CASCADE,
  edge_kind VARCHAR(32),
  label VARCHAR(120),
  active_power_kw NUMERIC(14, 3),
  reactive_power_kvar NUMERIC(14, 3),
  props JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_schematic_node_view ON schematic.view_node (view_id, seq_no);
CREATE INDEX IF NOT EXISTS idx_schematic_edge_view ON schematic.view_edge (view_id);
CREATE INDEX IF NOT EXISTS idx_schematic_edge_from ON schematic.view_edge (from_node_id);
CREATE INDEX IF NOT EXISTS idx_schematic_edge_to ON schematic.view_edge (to_node_id);

COMMENT ON SCHEMA schematic IS 'Vistas esquemáticas estáticas/sequenciais; ligação geográfica via focus_lat/focus_lng (Ir para o mapa).';
COMMENT ON TABLE schematic.network_view IS 'Uma vista = unifilar e/ou anotação de fluxo; metadata livre p.ex. alimentador, tensão nominal.';
COMMENT ON TABLE schematic.view_node IS 'Nó ordenado (seq_no) no desenho; equipment_id opcional ao inventário GIS.';
COMMENT ON TABLE schematic.view_edge IS 'Aresta; P/Q em kW/kVAr para indicação de fluxo (MVP qualitativo).';

-- Dados de demonstração (cadeia linear — compatível com renderização em escada).
INSERT INTO schematic.network_view (code, name, view_kind, description, metadata)
  VALUES (
    'demo_feeder_central',
    'Alimentador demonstração (centro)',
    'hybrid',
    'Unifilar sequencial com valores de P/Q de exemplo (não de estudo de carga).',
    jsonb_build_object('voltage_kv', 13.8, 'feeder_code', 'A-DEMO-01')
  )
ON CONFLICT (code) DO NOTHING;

DO $$
DECLARE
  vid BIGINT;
  n1 BIGINT;
  n2 BIGINT;
  n3 BIGINT;
  n4 BIGINT;
BEGIN
  SELECT id INTO vid FROM schematic.network_view WHERE code = 'demo_feeder_central' LIMIT 1;
  IF vid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM schematic.view_node WHERE view_id = vid AND seq_no = 1) THEN
    INSERT INTO schematic.view_node (view_id, seq_no, label, symbol_code, focus_lat, focus_lng, props)
      VALUES
        (vid, 1, 'SE Centro', 'substation', -23.5505, -46.6333, jsonb_build_object('voltage_kv', 13.8)),
        (vid, 2, 'Recl. A1', 'breaker', -23.5512, -46.6360, jsonb_build_object('state', 'closed')),
        (vid, 3, 'TR-01 300 kVA', 'trafo', -23.5520, -46.6385, jsonb_build_object('sn_kva', 300)),
        (vid, 4, 'Carga agregada', 'load', -23.5528, -46.6408, jsonb_build_object('contract_kw', 210));
  END IF;

  IF vid IS NULL THEN
    RAISE NOTICE 'schematic: demo_feeder_central not found, skip node/edge seed';
  ELSE
    SELECT id INTO n1 FROM schematic.view_node WHERE view_id = vid AND seq_no = 1;
    SELECT id INTO n2 FROM schematic.view_node WHERE view_id = vid AND seq_no = 2;
    SELECT id INTO n3 FROM schematic.view_node WHERE view_id = vid AND seq_no = 3;
    SELECT id INTO n4 FROM schematic.view_node WHERE view_id = vid AND seq_no = 4;
    IF n1 IS NOT NULL AND n2 IS NOT NULL AND n3 IS NOT NULL AND n4 IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM schematic.view_edge WHERE view_id = vid AND from_node_id = n1 AND to_node_id = n2) THEN
      INSERT INTO schematic.view_edge (view_id, from_node_id, to_node_id, edge_kind, label, active_power_kw, reactive_power_kvar, props)
        VALUES
          (vid, n1, n2, 'line', 'A-DEMO-01 tramo 1', 1200, 85, '{}'::jsonb),
          (vid, n2, n3, 'line', 'A-DEMO-01 tramo 2', 1180, 80, '{}'::jsonb),
          (vid, n3, n4, 'line', 'BT agregada', 205, 48, jsonb_build_object('loss_kw_qualitative', 5));
    END IF;
  END IF;
END $$;
