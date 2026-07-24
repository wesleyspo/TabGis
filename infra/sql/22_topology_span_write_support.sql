-- ============================================================================
-- TabGis — Suporte à edição REST de segmentos lineares da rede (gis.network_span)
-- ============================================================================
-- Ordem de aplicação: após 21_postgis_topology_utilities.sql.
--
-- 1) Coluna updated_at para rastrear alterações via PATCH /api/topology/spans/:id.
-- 2) Regra de ouro de auditoria estendida ao domínio gis: nada é removido de
--    gis.network_span sem snapshot prévio em audit.operations_row_archive
--    (mesma função genérica usada pelo schema operations).
--
-- Documentação: docs/mds/TOPOLOGY_NATIVE_POSTGIS.md
-- ============================================================================

ALTER TABLE gis.network_span
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

COMMENT ON COLUMN gis.network_span.updated_at IS
  'Última alteração via API de edição (PATCH /api/topology/spans/:id). NULL = nunca editado.';

-- Arquivo obrigatório antes de DELETE (função genérica de 03_operations_schema.sql)
DROP TRIGGER IF EXISTS trg_network_span_archive_before_delete ON gis.network_span;
CREATE TRIGGER trg_network_span_archive_before_delete
  BEFORE DELETE ON gis.network_span
  FOR EACH ROW
  EXECUTE FUNCTION audit.archive_operations_row_before_delete();

COMMENT ON TRIGGER trg_network_span_archive_before_delete ON gis.network_span IS
  'Snapshot JSONB em audit.operations_row_archive antes de qualquer DELETE (inclui span_geom em WKB e referência topo_geom).';

-- 3) Vista de publicação WMS/WFS (GeoServer): sem a coluna TopoGeometry, cujo
--    tipo composto não é reconhecido pelo datastore PostGIS do GeoServer.
CREATE OR REPLACE VIEW gis.v_network_span_wms AS
SELECT
  ns.id,
  ns.code,
  ns.description,
  ns.utility_domain,
  ns.equipment_from_id,
  ns.equipment_to_id,
  round((ST_Length(ns.span_geom::geography))::numeric, 2) AS length_m_approx,
  (ns.topo_geom IS NOT NULL) AS has_topo_geom,
  ns.created_at,
  ns.updated_at,
  ns.span_geom AS geom
FROM gis.network_span ns;

COMMENT ON VIEW gis.v_network_span_wms IS
  'Publicação GeoServer (base_sp:v_network_span_wms) — segmentos lineares da rede sem coluna TopoGeometry. Script: infra/scripts/publish_network_span_layer.sh.';
