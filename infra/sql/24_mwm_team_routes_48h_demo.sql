-- ============================================================================
-- TabGis — Rotas operacionais 48h (operations.team_route) + deslocamentos demo
-- ============================================================================
-- Ordem: após 03_operations_schema.sql e 05_operational_demo_data.sql (equipas com geom).
-- Idempotente: limpa apenas rotas com source='demo_seed_48h' antes de reinsirir.
-- Documentação: docs/mds/OPERATIONS_MWM.md
-- ============================================================================

-- Remove seeds anteriores deste script (não toca rotas de tracker reais)
DELETE FROM operations.team_route WHERE source = 'demo_seed_48h';

-- Uma MultiLineString curta por equipa activa com última posição conhecida,
-- janela [now-48h, now], deslocamento ~300–600 m a partir do last_known_geom.
INSERT INTO operations.team_route (team_id, window_start, window_end, route_geom, source, recorded_at)
SELECT
  t.id,
  now() - INTERVAL '48 hours',
  now(),
  ST_Multi(
    ST_MakeLine(ARRAY[
      t.last_known_geom,
      ST_Translate(t.last_known_geom, 0.0025, 0.0012),
      ST_Translate(t.last_known_geom, 0.0040, -0.0008),
      ST_Translate(t.last_known_geom, 0.0015, -0.0020)
    ])
  ),
  'demo_seed_48h',
  now()
FROM operations.team t
WHERE t.last_known_geom IS NOT NULL
  AND COALESCE(t.status, 'active') <> 'inactive';

-- Deslocamentos equipa↔ ordem (só se ainda não existir o par)
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
