-- ============================================================================
-- TabGis — Encaixe de trajectórias na rede viária (landbase.vias_alvo_sp)
-- ============================================================================
-- Gera LineString 4326 seguindo vias públicas dos municípios-alvo, sem cortar
-- blocos em linha recta. Usado por operations.team_route (seed 24) e reutilizável
-- noutros pipelines MWM.
--
-- Estratégia: segmentar o trajecto origem→destino em passos (~60 m), projectar
-- cada vértice na via OSM mais próxima (ST_ClosestPoint), remover duplicados
-- consecutivos e unir numa LineString.
--
-- Pré-requisito: landbase.vias_alvo_sp populada (setup_municipios_alvo_sp.sh).
-- Documentação: docs/mds/OPERATIONS_MWM.md
-- ============================================================================

CREATE OR REPLACE FUNCTION landbase.route_line_snapped_to_vias(
  p_origin geometry,
  p_dest geometry,
  p_step_m double precision DEFAULT 60
) RETURNS geometry(LineString, 4326)
LANGUAGE sql
STABLE
AS $$
  WITH norm AS (
    SELECT
      CASE
        WHEN p_origin IS NULL OR p_dest IS NULL THEN NULL
        WHEN ST_Distance(p_origin::geography, p_dest::geography) < 8 THEN NULL
        ELSE ST_SetSRID(ST_MakePoint(ST_X(p_origin), ST_Y(p_origin)), 4326)
      END AS o4326,
      CASE
        WHEN p_origin IS NULL OR p_dest IS NULL THEN NULL
        WHEN ST_Distance(p_origin::geography, p_dest::geography) < 8 THEN NULL
        ELSE ST_SetSRID(ST_MakePoint(ST_X(p_dest), ST_Y(p_dest)), 4326)
      END AS d4326,
      GREATEST(COALESCE(p_step_m, 60), 25) AS step_m
  ),
  dense AS (
    SELECT
      (dp).path[1] AS ord,
      (dp).geom AS pt4326
    FROM norm n,
    LATERAL ST_DumpPoints(
      ST_Segmentize(ST_MakeLine(n.o4326, n.d4326)::geography, n.step_m)::geometry
    ) AS dp
    WHERE n.o4326 IS NOT NULL
  ),
  snapped AS (
    SELECT
      d.ord,
      ST_Transform(
        ST_ClosestPoint(v.geom, ST_Transform(d.pt4326, 4674)),
        4326
      ) AS pt4326
    FROM dense d
    JOIN LATERAL (
      SELECT geom
      FROM landbase.vias_alvo_sp
      ORDER BY geom <-> ST_Transform(d.pt4326, 4674)
      LIMIT 1
    ) v ON TRUE
  ),
  dedup AS (
    SELECT s.ord, s.pt4326
    FROM snapped s
    WHERE NOT EXISTS (
      SELECT 1
      FROM snapped prev
      WHERE prev.ord = s.ord - 1
        AND ST_DWithin(prev.pt4326::geography, s.pt4326::geography, 8)
    )
  ),
  line AS (
    SELECT ST_MakeLine(array_agg(pt4326 ORDER BY ord)) AS g
    FROM dedup
    HAVING COUNT(*) >= 2
  )
  SELECT g FROM line;
$$;

COMMENT ON FUNCTION landbase.route_line_snapped_to_vias(geometry, geometry, double precision) IS
  'Aproxima origem→destino (4326) à rede landbase.vias_alvo_sp (4674); passo default 60 m.';

-- Métrica auxiliar: distância média (m) da linha à via mais próxima — útil em sanidade.
CREATE OR REPLACE FUNCTION landbase.avg_distance_route_to_vias_m(
  p_line geometry
) RETURNS double precision
LANGUAGE sql
STABLE
AS $$
  WITH pts AS (
    SELECT (dp).geom AS pt4326
    FROM ST_DumpPoints(
      ST_Segmentize(COALESCE(p_line, ST_GeomFromText('LINESTRING EMPTY', 4326))::geography, 40)::geometry
    ) AS dp
  )
  SELECT AVG(
    ST_Distance(
      pt4326::geography,
      ST_Transform(
        ST_ClosestPoint(v.geom, ST_Transform(pt4326, 4674)),
        4326
      )::geography
    )
  )
  FROM pts
  JOIN LATERAL (
    SELECT geom
    FROM landbase.vias_alvo_sp
    ORDER BY geom <-> ST_Transform(pt4326, 4674)
    LIMIT 1
  ) v ON TRUE;
$$;

COMMENT ON FUNCTION landbase.avg_distance_route_to_vias_m(geometry) IS
  'Distância média (m) dos vértices amostrados da linha à via OSM mais próxima — ideal < 15 m.';

-- Projecta um ponto 4326 para o ponto mais próximo na via OSM mais próxima.
CREATE OR REPLACE FUNCTION landbase.snap_point_to_nearest_via(
  p_pt geometry
) RETURNS geometry(Point, 4326)
LANGUAGE sql
STABLE
AS $$
  SELECT ST_Transform(
    ST_ClosestPoint(v.geom, ST_Transform(ST_SetSRID(ST_MakePoint(ST_X(p_pt), ST_Y(p_pt)), 4326), 4674)),
    4326
  )
  FROM landbase.vias_alvo_sp v
  ORDER BY v.geom <-> ST_Transform(ST_SetSRID(ST_MakePoint(ST_X(p_pt), ST_Y(p_pt)), 4326), 4674)
  LIMIT 1;
$$;

-- Trecho de patrulha sobre a via mais próxima (~comprimento em metros a partir do ponto).
CREATE OR REPLACE FUNCTION landbase.route_patrol_nearest_via(
  p_origin geometry,
  p_length_m double precision DEFAULT 700
) RETURNS geometry(LineString, 4326)
LANGUAGE sql
STABLE
AS $$
  WITH snap AS (
    SELECT landbase.snap_point_to_nearest_via(p_origin) AS pt4326
  ),
  via AS (
    SELECT v.geom AS geom4674
    FROM snap s
    JOIN landbase.vias_alvo_sp v
      ON v.geom = (
        SELECT geom
        FROM landbase.vias_alvo_sp
        ORDER BY geom <-> ST_Transform(s.pt4326, 4674)
        LIMIT 1
      )
  ),
  loc AS (
    SELECT
      ST_LineLocatePoint(v.geom4674, ST_Transform(s.pt4326, 4674)) AS frac
    FROM snap s, via v
  ),
  seg AS (
    SELECT ST_LineSubstring(
      v.geom4674,
      GREATEST(0, l.frac - (p_length_m / 2) / NULLIF(ST_Length(v.geom4674::geography), 0)),
      LEAST(1, l.frac + (p_length_m / 2) / NULLIF(ST_Length(v.geom4674::geography), 0))
    ) AS g4674
    FROM via v, loc l
  )
  SELECT ST_Transform(g4674, 4326) FROM seg WHERE g4674 IS NOT NULL;
$$;

COMMENT ON FUNCTION landbase.snap_point_to_nearest_via(geometry) IS
  'Encaixa ponto 4326 na via landbase.vias_alvo_sp mais próxima.';
COMMENT ON FUNCTION landbase.route_patrol_nearest_via(geometry, double precision) IS
  'Patrulha lineal sobre a via mais próxima (~p_length_m metros centrados no ponto encaixado).';
