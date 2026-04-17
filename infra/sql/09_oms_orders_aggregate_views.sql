-- TabGis — vistas para agrupar ordens OMS (operations.work_order) por município / bairro no mapa
-- Idempotente. Aplicar após dados operacionais (05, 06, 08, …).

DROP VIEW IF EXISTS operations.v_oms_orders_agg_bairro;
DROP VIEW IF EXISTS operations.v_oms_orders_agg_municipio;

CREATE VIEW operations.v_oms_orders_agg_municipio AS
SELECT
  COALESCE(wo.municipality_name, '—') AS municipality_name,
  COUNT(*)::int AS orders_count,
  AVG(wo.focus_lat) FILTER (WHERE wo.focus_lat IS NOT NULL) AS center_lat,
  AVG(wo.focus_lng) FILTER (WHERE wo.focus_lng IS NOT NULL) AS center_lng,
  MIN(wo.started_at) AS first_started_at,
  MAX(wo.updated_at) AS last_updated_at
FROM operations.work_order wo
WHERE COALESCE(wo.order_type, '') <> 'event'
  AND COALESCE(wo.category, '') <> 'event'
GROUP BY COALESCE(wo.municipality_name, '—');

CREATE VIEW operations.v_oms_orders_agg_bairro AS
SELECT
  COALESCE(wo.municipality_name, '—') AS municipality_name,
  COALESCE(wo.neighborhood_name, '—') AS neighborhood_name,
  COUNT(*)::int AS orders_count,
  AVG(wo.focus_lat) FILTER (WHERE wo.focus_lat IS NOT NULL) AS center_lat,
  AVG(wo.focus_lng) FILTER (WHERE wo.focus_lng IS NOT NULL) AS center_lng,
  MIN(wo.started_at) AS first_started_at,
  MAX(wo.updated_at) AS last_updated_at
FROM operations.work_order wo
WHERE COALESCE(wo.order_type, '') <> 'event'
  AND COALESCE(wo.category, '') <> 'event'
GROUP BY
  COALESCE(wo.municipality_name, '—'),
  COALESCE(wo.neighborhood_name, '—');

COMMENT ON VIEW operations.v_oms_orders_agg_municipio IS 'Contagem e centro médio das ordens OMS por município (zoom afastado).';
COMMENT ON VIEW operations.v_oms_orders_agg_bairro IS 'Contagem e centro médio das ordens OMS por município + bairro (zoom intermédio).';
