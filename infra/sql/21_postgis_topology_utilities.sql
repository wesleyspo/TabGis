-- ============================================================================
-- TabGis — Topologia nativa PostGIS (extensão postgis_topology)
-- ============================================================================
-- Descrição funcional:
--   Modelo topológico oficial do PostGIS para segmentos lineares da rede (conductores /
--   canalizações) onde vértices coincidentes dentro da tolerância partilham o
--   mesmo nó topológico — continuidade física explícita sem duplicar pontos.
--
-- Ordem de aplicação: após 04_gis_oms_mwm_domain.sql (tabela gis.equipment).
--
-- Documentação: docs/mds/TOPOLOGY_NATIVE_POSTGIS.md
--
-- SRID: 4326 (alinhado a gis.equipment.geom). Para redes densas em metros,
--       avaliar topologia dedicada em CRS projetado (ex.: UTM 23S) num ambiente
--       futuro — ver documentação.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Cria o “universo” topológico: schema homónimo + metadados em topology.topology
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM topology.topology WHERE name = 'tabgis_utilities_topo'
  ) THEN
    PERFORM topology.CreateTopology('tabgis_utilities_topo', 4326, 0.000001);
  END IF;
END $$;

COMMENT ON SCHEMA tabgis_utilities_topo IS
  'Topologia PostGIS nativa TabGis — primitivas edge_data/node/face geridas pelo motor; segmentos lineares da rede em gis.network_span.';

-- Segmento linear da rede = geometria simples + TopoGeometry que referencia primitivas partilhadas
CREATE TABLE IF NOT EXISTS gis.network_span (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(96) NOT NULL UNIQUE,
  description TEXT,
  utility_domain VARCHAR(16),
  equipment_from_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
  equipment_to_id BIGINT REFERENCES gis.equipment(id) ON DELETE SET NULL,
  span_geom geometry(LineString, 4326) NOT NULL,
  event_id BIGINT REFERENCES audit.domain_event(id) ON DELETE SET NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT network_span_geom_nonempty CHECK (NOT ST_IsEmpty(span_geom))
);

CREATE INDEX IF NOT EXISTS idx_network_span_geom ON gis.network_span USING GIST (span_geom);
CREATE INDEX IF NOT EXISTS idx_network_span_from ON gis.network_span (equipment_from_id);
CREATE INDEX IF NOT EXISTS idx_network_span_to ON gis.network_span (equipment_to_id);

COMMENT ON TABLE gis.network_span IS
  'Segmento linear da rede (LineString 4326). Coluna topo_geom (TopoGeometry) referencia primitivas na topologia tabgis_utilities_topo — nós coincidentes são fundidos pela tolerância da topologia.';
COMMENT ON COLUMN gis.network_span.span_geom IS
  'Geometria “apelo” humana e interoperável (GeoJSON, WFS). Mantida mesmo quando topo_geom está preenchido.';

-- Regista camada LINE na topologia e cria a coluna topo_geom (API oficial)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'gis'
      AND table_name = 'network_span'
      AND column_name = 'topo_geom'
  ) THEN
    PERFORM topology.AddTopoGeometryColumn(
      'tabgis_utilities_topo',
      'gis',
      'network_span',
      'topo_geom',
      'LINE'
    );
  END IF;
END $$;

COMMENT ON COLUMN gis.network_span.topo_geom IS
  'Referência topológica nativa (partilha de nós/arestas entre segmentos). Preenchido via topology.toTopoGeom.';

-- Vista legível: comprimento geodésico aproximado (metros)
CREATE OR REPLACE VIEW gis.v_network_span_readable AS
SELECT
  ns.id,
  ns.code,
  ns.description,
  ns.utility_domain,
  ns.equipment_from_id,
  ns.equipment_to_id,
  ns.span_geom,
  ns.topo_geom,
  round((ST_Length(ns.span_geom::geography))::numeric, 2) AS length_m_approx,
  ns.created_at
FROM gis.network_span ns;

COMMENT ON VIEW gis.v_network_span_readable IS
  'Vista operacional: segmentos lineares com comprimento aproximado em metros (geografia sobre LineString 4326).';

-- ---------------------------------------------------------------------------
-- Dados de demonstração (idempotentes por code)
-- ---------------------------------------------------------------------------
INSERT INTO gis.network_span (code, description, utility_domain, span_geom)
VALUES
  (
    'TOPO_DEMO_SEG_01',
    'Demonstração topologia nativa: primeiro segmento linear (dois vértices em SP centro).',
    'electric',
    ST_SetSRID(
      ST_MakeLine(
        ST_MakePoint(-46.63330, -23.55050),
        ST_MakePoint(-46.63600, -23.55120)
      ),
      4326
    )
  ),
  (
    'TOPO_DEMO_SEG_02',
    'Demonstração: segundo segmento linear com vértice inicial coincidente com o fim do primeiro — deve partilhar nó topológico.',
    'electric',
    ST_SetSRID(
      ST_MakeLine(
        ST_MakePoint(-46.63600, -23.55120),
        ST_MakePoint(-46.63850, -23.55200)
      ),
      4326
    )
  ),
  (
    'TOPO_DEMO_SEG_03',
    'Demonstração: ramificação a partir do segundo segmento.',
    'electric',
    ST_SetSRID(
      ST_MakeLine(
        ST_MakePoint(-46.63850, -23.55200),
        ST_MakePoint(-46.64080, -23.55280)
      ),
      4326
    )
  )
ON CONFLICT (code) DO NOTHING;

-- Materializa primitivas topológicas a partir das LineStrings (tolerância = precision da topologia)
UPDATE gis.network_span ns
SET topo_geom = topology.toTopoGeom(ns.span_geom, 'tabgis_utilities_topo', lyr.layer_id, lyr.precision)
FROM (
  SELECT l.layer_id, t.precision
  FROM topology.layer l
  INNER JOIN topology.topology t ON t.id = l.topology_id
  WHERE t.name = 'tabgis_utilities_topo'
    AND l.schema_name = 'gis'
    AND l.table_name = 'network_span'
    AND l.feature_column = 'topo_geom'
) lyr
WHERE ns.span_geom IS NOT NULL
  AND ns.topo_geom IS NULL;

ANALYZE gis.network_span;
