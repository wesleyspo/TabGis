-- TabGis — agrupamento espacial de ordens OMS (estilo marker cluster / Supercluster)
-- Agregação por grelha métrica em EPSG:31983 (UTM 23S). Evita encadeamento do DBSCAN
-- que fundia toda a região metropolitana num único grupo.
-- A API envia o tamanho da célula (metros) derivado do zoom Leaflet.
-- Idempotente. Aplicar após 06+ e dados operacionais.

DROP FUNCTION IF EXISTS operations.fn_oms_orders_spatial_clusters(double precision, integer);

CREATE OR REPLACE FUNCTION operations.fn_oms_orders_spatial_clusters(
  p_cell_m double precision,
  p_min_points integer DEFAULT 1
)
RETURNS TABLE (
  cluster_id integer,
  orders_count integer,
  center_lat double precision,
  center_lng double precision,
  first_started_at timestamptz,
  last_updated_at timestamptz,
  area_hint text
)
LANGUAGE sql
STABLE
PARALLEL SAFE
AS $fn$
  WITH base AS (
    SELECT
      wo.id,
      wo.started_at,
      wo.updated_at,
      wo.municipality_name,
      wo.neighborhood_name,
      ST_Transform(
        ST_SetSRID(ST_MakePoint(wo.focus_lng, wo.focus_lat), 4326),
        31983
      ) AS geom_m
    FROM operations.work_order wo
    WHERE COALESCE(wo.order_type, '') <> 'event'
      AND COALESCE(wo.category, '') <> 'event'
      AND wo.focus_lat IS NOT NULL
      AND wo.focus_lng IS NOT NULL
  ),
  gridded AS (
    SELECT
      ST_SnapToGrid(b.geom_m, p_cell_m, p_cell_m) AS cell_g,
      b.geom_m,
      b.started_at,
      b.updated_at,
      b.municipality_name,
      b.neighborhood_name
    FROM base b
  ),
  agg AS (
    SELECT
      g.cell_g,
      COUNT(*)::integer AS orders_count,
      ST_Centroid(ST_Collect(g.geom_m)) AS center_m,
      MIN(g.started_at) AS first_started_at,
      MAX(g.updated_at) AS last_updated_at,
      LEFT(
        STRING_AGG(DISTINCT NULLIF(TRIM(COALESCE(g.municipality_name, '')), ''), ' · '),
        160
      ) AS area_hint
    FROM gridded g
    GROUP BY g.cell_g
    HAVING COUNT(*) >= p_min_points
  )
  SELECT
    ROW_NUMBER() OVER (ORDER BY a.orders_count DESC, a.cell_g::text)::integer AS cluster_id,
    a.orders_count,
    ST_Y(ST_Transform(a.center_m, 4326)) AS center_lat,
    ST_X(ST_Transform(a.center_m, 4326)) AS center_lng,
    a.first_started_at,
    a.last_updated_at,
    a.area_hint
  FROM agg a;
$fn$;

COMMENT ON FUNCTION operations.fn_oms_orders_spatial_clusters(double precision, integer) IS
  'Agrupa ordens OMS por célula métrica (UTM 23S). p_cell_m = lado da célula em metros.';
