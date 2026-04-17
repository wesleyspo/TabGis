-- Tabelas isoladas (sem FK directa a oms.work_order) mas alinhadas à realidade:
-- rotas seguem a rede viária (landbase.vias_alvo_sp) e passam por focos de ordens.

CREATE SCHEMA IF NOT EXISTS mwm;

DROP TABLE IF EXISTS mwm.demo_field_route_point CASCADE;
DROP TABLE IF EXISTS mwm.demo_field_route CASCADE;
DROP TABLE IF EXISTS mwm.demo_field_crew CASCADE;

CREATE TABLE mwm.demo_field_crew (
  id SERIAL PRIMARY KEY,
  crew_code VARCHAR(32) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  vehicle_type VARCHAR(16) NOT NULL CHECK (vehicle_type IN ('CARRINHO', 'CARRO', 'MOTO')),
  status VARCHAR(24) NOT NULL DEFAULT 'active',
  base_lat DOUBLE PRECISION NOT NULL,
  base_lng DOUBLE PRECISION NOT NULL
);

CREATE TABLE mwm.demo_field_route (
  id SERIAL PRIMARY KEY,
  crew_id INTEGER NOT NULL REFERENCES mwm.demo_field_crew(id) ON DELETE CASCADE,
  route_date DATE NOT NULL,
  label TEXT,
  UNIQUE (crew_id, route_date)
);

CREATE TABLE mwm.demo_field_route_point (
  id SERIAL PRIMARY KEY,
  route_id INTEGER NOT NULL REFERENCES mwm.demo_field_route(id) ON DELETE CASCADE,
  seq_no INTEGER NOT NULL,
  geom geometry(Point, 4326) NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL,
  UNIQUE (route_id, seq_no)
);

CREATE INDEX idx_mwm_demo_route_point_geom ON mwm.demo_field_route_point USING GIST (geom);
CREATE INDEX idx_mwm_demo_route_point_route ON mwm.demo_field_route_point (route_id, seq_no);

-- 18 equipas: mistura de veículos, bases espalhadas na RMSP
INSERT INTO mwm.demo_field_crew (crew_code, name, vehicle_type, status, base_lat, base_lng) VALUES
  ('DMW-C01', 'Cesta Zona Leste I', 'CARRINHO', 'active', -23.541, -46.576),
  ('DMW-C02', 'Cesta Zona Leste II', 'CARRINHO', 'active', -23.558, -46.548),
  ('DMW-C03', 'Cesta Guarulhos', 'CARRINHO', 'active', -23.454, -46.533),
  ('DMW-C04', 'Cesta Mauá', 'CARRINHO', 'active', -23.668, -46.461),
  ('DMW-V01', 'Viatura Sul I', 'CARRO', 'active', -23.653, -46.620),
  ('DMW-V02', 'Viatura Sul II', 'CARRO', 'active', -23.682, -46.598),
  ('DMW-V03', 'Viatura Oeste Osasco', 'CARRO', 'active', -23.533, -46.792),
  ('DMW-V04', 'Viatura Barueri', 'CARRO', 'active', -23.511, -46.876),
  ('DMW-V05', 'Viatura ABC', 'CARRO', 'active', -23.714, -46.532),
  ('DMW-V06', 'Viatura Norte', 'CARRO', 'active', -23.479, -46.632),
  ('DMW-M01', 'Moto Centro', 'MOTO', 'active', -23.548, -46.638),
  ('DMW-M02', 'Moto Paulista', 'MOTO', 'active', -23.562, -46.660),
  ('DMW-M03', 'Moto Pinheiros', 'MOTO', 'active', -23.567, -46.692),
  ('DMW-M04', 'Moto Santana', 'MOTO', 'active', -23.482, -46.626),
  ('DMW-M05', 'Moto Tatuapé', 'MOTO', 'active', -23.541, -46.576),
  ('DMW-M06', 'Moto Interlagos', 'MOTO', 'active', -23.704, -46.700),
  ('DMW-V07', 'Viatura Litoral (demo)', 'CARRO', 'active', -23.964, -46.333),
  ('DMW-C05', 'Cesta Santo André', 'CARRINHO', 'active', -23.654, -46.528);

INSERT INTO mwm.demo_field_route (crew_id, route_date, label)
SELECT id, CURRENT_DATE, 'Rota ' || crew_code || ' — ' || to_char(CURRENT_DATE, 'YYYY-MM-DD')
FROM mwm.demo_field_crew;

-- Ontem: segunda rota por equipa (histórico curto para testes)
INSERT INTO mwm.demo_field_route (crew_id, route_date, label)
SELECT id, CURRENT_DATE - 1, 'Rota ' || crew_code || ' — ontem'
FROM mwm.demo_field_crew;

-- Construção de trajectos seguindo vias:
-- 1) para cada equipa, escolher 4–6 ordens próximas associadas (operations.work_order.assigned_team_id)
-- 2) ligar pontos base → focos de ordens por segmentos de rua (aproximação: amostras da geometria de vias_alvo_sp)
-- 3) gerar pontos densos (seq_no) ao longo da polilinha resultante.

WITH crew_orders AS (
  SELECT
    c.id AS crew_id,
    c.crew_code,
    c.base_lat,
    c.base_lng,
    wo.id AS work_order_id,
    wo.order_code,
    wo.focus_lat,
    wo.focus_lng,
    ROW_NUMBER() OVER (
      PARTITION BY c.id
      ORDER BY
        (wo.focus_lat - c.base_lat)::numeric(12,8)^2 +
        (wo.focus_lng - c.base_lng)::numeric(12,8)^2
    ) AS rn
  FROM mwm.demo_field_crew c
  JOIN operations.work_order wo
    ON wo.assigned_team_id = c.id
   AND wo.focus_lat IS NOT NULL
   AND wo.focus_lng IS NOT NULL
  WHERE COALESCE(wo.order_type, '') <> 'event'
),
crew_orders_limited AS (
  SELECT *
  FROM crew_orders
  WHERE rn <= 6
),
crew_routes AS (
  SELECT
    r.id AS route_id,
    co.crew_id,
    co.crew_code,
    co.base_lat,
    co.base_lng,
    COALESCE(
      ARRAY_AGG(row(col.focus_lat, col.focus_lng) ORDER BY col.rn),
      ARRAY[]::record[]
    ) AS stops
  FROM mwm.demo_field_route r
  JOIN (
    SELECT DISTINCT ON (crew_id)
      crew_id,
      crew_code,
      base_lat,
      base_lng
    FROM crew_orders
    ORDER BY crew_id, rn
  ) co ON co.crew_id = r.crew_id
  LEFT JOIN crew_orders_limited col ON col.crew_id = r.crew_id
  GROUP BY r.id, co.crew_id, co.crew_code, co.base_lat, co.base_lng
),
segments AS (
  -- Constrói segmentos base → ordem1 → ordem2 → ...
  SELECT
    cr.route_id,
    seq,
    ST_MakeLine(ARRAY[
      ST_SetSRID(ST_MakePoint(origin_lng, origin_lat), 4326),
      ST_SetSRID(ST_MakePoint(dest_lng, dest_lat), 4326)
    ]) AS raw_line
  FROM (
    SELECT
      cr.route_id,
      0 AS seq,
      cr.base_lat AS origin_lat,
      cr.base_lng AS origin_lng,
      (cr.stops[1]).f1::double precision AS dest_lat,
      (cr.stops[1]).f2::double precision AS dest_lng
    FROM crew_routes cr
    WHERE array_length(cr.stops, 1) >= 1

    UNION ALL

    SELECT
      cr.route_id,
      idx AS seq,
      (cr.stops[idx]).f1::double precision AS origin_lat,
      (cr.stops[idx]).f2::double precision AS origin_lng,
      (cr.stops[idx+1]).f1::double precision AS dest_lat,
      (cr.stops[idx+1]).f2::double precision AS dest_lng
    FROM crew_routes cr
    CROSS JOIN LATERAL generate_subscripts(cr.stops, 1) AS idx
    WHERE idx >= 1 AND idx < array_length(cr.stops, 1)
  ) s
),
segments_snapped AS (
  -- Para cada segmento, aproxima o trajecto à via mais próxima amostrando vértices da geometria de rua
  SELECT
    s.route_id,
    s.seq,
    ST_LineMerge(
      ST_Collect(
        ST_Segmentize(
          ST_LineSubstring(
            v.geom,
            0.0,
            1.0
          ),
          80.0
        )
      )
    ) AS snapped_line
  FROM segments s
  JOIN LATERAL (
    SELECT geom
    FROM landbase.vias_alvo_sp
    ORDER BY geom <-> ST_LineInterpolatePoint(s.raw_line, 0.5)
    LIMIT 8
  ) v ON TRUE
  GROUP BY s.route_id, s.seq
),
route_full AS (
  SELECT
    route_id,
    ST_LineMerge(ST_Collect(snapped_line)) AS full_geom
  FROM segments_snapped
  GROUP BY route_id
)
INSERT INTO mwm.demo_field_route_point (route_id, seq_no, geom, recorded_at)
SELECT
  rf.route_id,
  gs.n AS seq_no,
  ST_LineInterpolatePoint(rf.full_geom, (gs.n::double precision - 1) / 99.0) AS geom,
  CURRENT_TIMESTAMP - ((100 - gs.n) * INTERVAL '60 seconds') AS recorded_at
FROM route_full rf
CROSS JOIN generate_series(1, 100) AS gs(n)
WHERE rf.full_geom IS NOT NULL;
