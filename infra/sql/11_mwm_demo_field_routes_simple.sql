-- TabGis — rotas demo simples: trajectórias sintéticas aproximadas às ruas (snapping em landbase.vias_alvo_sp)

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

INSERT INTO mwm.demo_field_route (crew_id, route_date, label)
SELECT id, CURRENT_DATE - 1, 'Rota ' || crew_code || ' — ontem'
FROM mwm.demo_field_crew;

WITH base_pts AS (
  SELECT
    r.id AS route_id,
    r.route_date,
    gs.n AS seq_no,
    ST_SetSRID(
      ST_MakePoint(
        c.base_lng
          + (gs.n * 0.00035) * cos(radians((40 + (c.id * 19) % 140)::double precision))
          + (sin(gs.n::double precision / 3.0) * 0.00025),
        c.base_lat
          + (gs.n * 0.00026) * sin(radians((40 + (c.id * 19) % 140)::double precision))
          + (cos(gs.n::double precision / 3.8) * 0.00020)
      ),
      4326
    ) AS geom_raw
  FROM mwm.demo_field_route r
  JOIN mwm.demo_field_crew c ON c.id = r.crew_id
  CROSS JOIN generate_series(1, 40) AS gs(n)
),
snapped AS (
  SELECT
    b.route_id,
    b.seq_no,
    ST_ClosestPoint(v.geom4326, b.geom_raw) AS geom,
    b.route_date
  FROM base_pts b
  JOIN LATERAL (
    SELECT ST_Transform(geom, 4326) AS geom4326
    FROM landbase.vias_alvo_sp
    ORDER BY ST_Transform(geom, 4326) <-> b.geom_raw
    LIMIT 1
  ) v ON TRUE
)
INSERT INTO mwm.demo_field_route_point (route_id, seq_no, geom, recorded_at)
SELECT
  route_id,
  seq_no,
  geom,
  CURRENT_TIMESTAMP - ((MAX(seq_no) OVER (PARTITION BY route_id) - seq_no) * INTERVAL '75 seconds')
FROM snapped
ORDER BY route_id, seq_no;

