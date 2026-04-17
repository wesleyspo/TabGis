-- TabGis — volume extra de ordens com coordenadas agrupadas em núcleos geográficos (hotspots RMSP)
-- Objetivo: mapa com vários «aglomerados» reais para testar agrupamento espacial (DBSCAN).
-- 30 núcleos × 12 ordens ≈ 360 linhas. Idempotente (ON CONFLICT order_code).
-- Aplicar após 05, 06, 08.

WITH spots AS (
  SELECT * FROM (VALUES
    (1, -23.5505::double precision, -46.6333::double precision, 'São Paulo'::text, 'Sé'::text),
    (2, -23.5412, -46.5750, 'São Paulo', 'Tatuapé'),
    (3, -23.5632, -46.6883, 'São Paulo', 'Pinheiros'),
    (4, -23.5945, -46.5758, 'São Paulo', 'Vila Prudente'),
    (5, -23.5329, -46.7917, 'Osasco', 'Centro'),
    (6, -23.4538, -46.5333, 'Guarulhos', 'Centro'),
    (7, -23.6632, -46.5278, 'Santo André', 'Centro'),
    (8, -23.6677, -46.4612, 'Mauá', 'Centro'),
    (9, -23.6939, -46.5650, 'São Bernardo do Campo', 'Centro'),
    (10, -23.6231, -46.7750, 'Taboão da Serra', 'Centro'),
    (11, -23.5227, -46.8358, 'Carapicuíba', 'Centro'),
    (12, -23.5057, -46.8760, 'Barueri', 'Centro'),
    (13, -23.4821, -46.4644, 'São Paulo', 'Itaquera'),
    (14, -23.4439, -46.9178, 'Santana de Parnaíba', 'Centro'),
    (15, -23.6496, -46.8512, 'Embu das Artes', 'Centro'),
    (16, -23.6023, -46.9187, 'Cotia', 'Centro'),
    (17, -23.7111, -46.4277, 'Ribeirão Pires', 'Centro'),
    (18, -23.6875, -46.6228, 'Diadema', 'Centro'),
    (19, -23.6528, -46.7564, 'São Paulo', 'Jardim São Luís'),
    (20, -23.5702, -46.7222, 'São Paulo', 'Butantã'),
    (21, -23.5235, -46.7021, 'São Paulo', 'Lapa'),
    (22, -23.6050, -46.4083, 'São Paulo', 'Cidade Tiradentes'),
    (23, -23.5250, -46.5460, 'São Paulo', 'Penha de França'),
    (24, -23.5968, -46.4787, 'São Paulo', 'São Mateus'),
    (25, -23.6467, -46.6422, 'São Paulo', 'Jabaquara'),
    (26, -23.6328, -46.7564, 'São Paulo', 'Campo Limpo'),
    (27, -23.5390, -46.6740, 'São Paulo', 'Perdizes'),
    (28, -23.5417, -46.6183, 'São Paulo', 'Mooca'),
    (29, -23.4789, -46.5853, 'São Paulo', 'Jaçanã'),
    (30, -23.4855, -46.7244, 'São Paulo', 'Pirituba')
  ) AS t(idx, clat, clng, mun, bairro)
),
cells AS (
  SELECT s.*, k.k
  FROM spots s
  CROSS JOIN generate_series(0, 11) AS k(k)
),
numbered AS (
  SELECT
    row_number() OVER (ORDER BY idx, k) AS n,
    idx,
    clat,
    clng,
    mun,
    bairro,
    k
  FROM cells
)
INSERT INTO operations.work_order (
  order_code, category, summary, description, status, priority,
  assigned_team_id, owner_id,
  municipality_name, neighborhood_name,
  focus_lat, focus_lng, started_at, order_type, organization_label,
  equipment_code, feeder_code, affected_customers_count,
  priority_score, flag_safety_risk, flag_critical_infra, flag_customer_callback
)
SELECT
  '2026-' || LPAD((9200 + q.n)::text, 4, '0'),
  CASE (q.n % 3) WHEN 0 THEN 'repair' WHEN 1 THEN 'complaint' ELSE 'task' END,
  'Carga demo — núcleo ' || q.idx::text || ' · ' || q.bairro,
  'Ordem sintética para teste de agrupamento espacial no mapa.',
  CASE (q.n % 4) WHEN 0 THEN 'open' WHEN 1 THEN 'in_progress' WHEN 2 THEN 'scheduled' ELSE 'open' END,
  CASE (q.n % 3) WHEN 0 THEN 'P1' WHEN 1 THEN 'P2' ELSE 'P3' END,
  t.id,
  u.id,
  q.mun,
  q.bairro,
  q.clat + ((q.k % 4) - 1.5) * 0.00105 + (q.k / 4) * 0.00032,
  q.clng + ((q.k / 4 % 4) - 1.5) * 0.00105 + (q.idx % 3) * 0.00012,
  CURRENT_TIMESTAMP - (q.n || ' hours')::interval,
  CASE (q.n % 3) WHEN 0 THEN 'repair' WHEN 1 THEN 'incident' ELSE 'maintenance' END,
  'UO RMSP — Operações',
  'TR-D' || LPAD(q.n::text, 4, '0'),
  'AF-' || (8 + (q.n % 7))::text,
  20 + (q.n % 110),
  CASE (q.n % 3) WHEN 0 THEN 1 WHEN 1 THEN 2 ELSE 3 END,
  (q.n % 11) = 0,
  (q.n % 13) = 0,
  (q.n % 3) = 1
FROM numbered q
JOIN operations.team t ON t.team_code = (
  ARRAY['EQ-ALPHA', 'EQ-BETA', 'EQ-GAMA', 'EQ-DELTA', 'EQ-EPSILON', 'EQ-ZETA']
)[1 + ((q.n + q.idx + q.k) % 6)]
JOIN security.users u ON u.username = (
  ARRAY['operador1', 'marina.silva', 'despacho.centro', 'ana.miranda', 'gilberto.nunes']
)[1 + (q.n % 5)]
ON CONFLICT (order_code) DO UPDATE SET
  summary = EXCLUDED.summary,
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  priority = EXCLUDED.priority,
  assigned_team_id = EXCLUDED.assigned_team_id,
  owner_id = EXCLUDED.owner_id,
  municipality_name = EXCLUDED.municipality_name,
  neighborhood_name = EXCLUDED.neighborhood_name,
  focus_lat = EXCLUDED.focus_lat,
  focus_lng = EXCLUDED.focus_lng,
  started_at = EXCLUDED.started_at,
  order_type = EXCLUDED.order_type,
  organization_label = EXCLUDED.organization_label,
  equipment_code = EXCLUDED.equipment_code,
  feeder_code = EXCLUDED.feeder_code,
  affected_customers_count = EXCLUDED.affected_customers_count,
  priority_score = EXCLUDED.priority_score,
  flag_safety_risk = EXCLUDED.flag_safety_risk,
  flag_critical_infra = EXCLUDED.flag_critical_infra,
  flag_customer_callback = EXCLUDED.flag_customer_callback,
  updated_at = CURRENT_TIMESTAMP;

UPDATE operations.work_order wo SET complaints_linked_count = cnt FROM (
  SELECT work_order_id, COUNT(*)::int AS cnt FROM operations.work_order_complaint GROUP BY work_order_id
) s WHERE wo.id = s.work_order_id;
