-- ============================================================================
-- TabGis — Rotas operacionais 48h (operations.team_route) + deslocamentos demo
-- ============================================================================
-- Ordem: após 03, 05, 25_landbase_route_snap_vias.sql (função de encaixe em vias).
-- Idempotente: limpa apenas rotas com source='demo_seed_48h' antes de reinsirir.
-- Trajectórias seguem landbase.vias_alvo_sp (sem linhas rectas a cortar quarteirões).
-- Documentação: docs/mds/OPERATIONS_MWM.md
-- ============================================================================

DELETE FROM operations.team_route WHERE source = 'demo_seed_48h';

WITH team_stops AS (
  SELECT
    t.id AS team_id,
    t.team_code,
    landbase.snap_point_to_nearest_via(t.last_known_geom) AS geom4326,
    0 AS stop_ord
  FROM operations.team t
  WHERE t.last_known_geom IS NOT NULL
    AND COALESCE(t.status, 'active') <> 'inactive'

  UNION ALL

  SELECT
    t.id,
    t.team_code,
    landbase.snap_point_to_nearest_via(
      ST_SetSRID(ST_MakePoint(wo.focus_lng, wo.focus_lat), 4326)
    ),
    ROW_NUMBER() OVER (
      PARTITION BY t.id
      ORDER BY t.last_known_geom <-> ST_SetSRID(ST_MakePoint(wo.focus_lng, wo.focus_lat), 4326)
    ) AS stop_ord
  FROM operations.team t
  JOIN operations.work_order wo ON wo.assigned_team_id = t.id
  WHERE t.last_known_geom IS NOT NULL
    AND COALESCE(t.status, 'active') <> 'inactive'
    AND wo.focus_lat IS NOT NULL
    AND wo.focus_lng IS NOT NULL
    AND COALESCE(wo.order_type, wo.category, '') <> 'event'
    AND ST_DWithin(
      ST_SetSRID(ST_MakePoint(wo.focus_lng, wo.focus_lat), 4326)::geography,
      t.last_known_geom::geography,
      12000
    )
),
team_stops_limited AS (
  SELECT * FROM team_stops WHERE stop_ord <= 3
),
segments AS (
  SELECT
    a.team_id,
    a.stop_ord AS seg_ord,
    a.geom4326 AS origin_geom,
    b.geom4326 AS dest_geom
  FROM team_stops_limited a
  JOIN team_stops_limited b
    ON b.team_id = a.team_id
   AND b.stop_ord = a.stop_ord + 1
),
segment_routes AS (
  SELECT
    s.team_id,
    s.seg_ord,
    landbase.route_line_snapped_to_vias(s.origin_geom, s.dest_geom, 55) AS seg_geom
  FROM segments s
),
merged AS (
  SELECT
    team_id,
    ST_Multi(ST_LineMerge(ST_Collect(seg_geom ORDER BY seg_ord))) AS route_geom
  FROM segment_routes
  WHERE seg_geom IS NOT NULL
  GROUP BY team_id
  HAVING ST_LineMerge(ST_Collect(seg_geom ORDER BY seg_ord)) IS NOT NULL
)
INSERT INTO operations.team_route (team_id, window_start, window_end, route_geom, source, recorded_at)
SELECT
  m.team_id,
  now() - INTERVAL '48 hours',
  now(),
  m.route_geom,
  'demo_seed_48h',
  now()
FROM merged m;

-- Rotas com aderência fraca (> 50 m média à via): substituir por patrulha local sobre a via
UPDATE operations.team_route tr
SET route_geom = ST_Multi(landbase.route_patrol_nearest_via(t.last_known_geom, 1200))
FROM operations.team t
WHERE tr.team_id = t.id
  AND tr.source = 'demo_seed_48h'
  AND landbase.avg_distance_route_to_vias_m(tr.route_geom) > 50
  AND landbase.route_patrol_nearest_via(t.last_known_geom, 1200) IS NOT NULL;

-- Fallback: patrulha sobre a via mais próxima (equipa sem ordens com foco ou segmentos inválidos)
INSERT INTO operations.team_route (team_id, window_start, window_end, route_geom, source, recorded_at)
SELECT
  t.id,
  now() - INTERVAL '48 hours',
  now(),
  ST_Multi(landbase.route_patrol_nearest_via(t.last_known_geom, 900)),
  'demo_seed_48h',
  now()
FROM operations.team t
WHERE t.last_known_geom IS NOT NULL
  AND COALESCE(t.status, 'active') <> 'inactive'
  AND NOT EXISTS (
    SELECT 1 FROM operations.team_route tr
    WHERE tr.team_id = t.id AND tr.source = 'demo_seed_48h'
  )
  AND landbase.route_patrol_nearest_via(t.last_known_geom, 900) IS NOT NULL;

INSERT INTO operations.team_order_displacement (
  team_id, work_order_id,
  planned_departure_at, planned_arrival_at,
  actual_departure_at, actual_arrival_at, notes
)
SELECT
  wo.assigned_team_id,
  wo.id,
  now() - INTERVAL '6 hours',
  now() - INTERVAL '5 hours 20 minutes',
  now() - INTERVAL '5 hours 50 minutes',
  CASE WHEN wo.status IN ('closed', 'done', 'completed') THEN now() - INTERVAL '4 hours' ELSE NULL END,
  'Seed demo M5 — deslocamento operacional'
FROM operations.work_order wo
WHERE wo.assigned_team_id IS NOT NULL
  AND wo.category <> 'event'
ON CONFLICT (team_id, work_order_id) DO NOTHING;

ANALYZE operations.team_route;
ANALYZE operations.team_order_displacement;
