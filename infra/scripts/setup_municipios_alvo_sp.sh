#!/usr/bin/env bash
set -euo pipefail

# Municipios-alvo SP: destaque, bairros e vias publicas.
# Requer base OSM estadual ja importada (public.osm_sp_line/polygon/point).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/infra/docker-compose.yml"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_NAME="${DB_NAME:-tabgis_db}"
DB_USER="${DB_USER:-tabgis_admin}"
DB_PASS="${DB_PASS:-password123}"

GEOSERVER_URL="${GEOSERVER_URL:-http://localhost:8080/geoserver}"
GS_USER="${GS_USER:-admin}"
GS_PASS="${GS_PASS:-geoserver}"
WORKSPACE="${WORKSPACE:-base_sp}"
STORE="${STORE:-tabgis_postgis}"

export PGPASSWORD="${DB_PASS}"

echo "[1/5] Ensuring db and geoserver are running..."
docker compose -f "${COMPOSE_FILE}" up -d db geoserver >/dev/null

echo "[2/5] Building target municipalities and thematic tables..."
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE SCHEMA IF NOT EXISTS landbase;

DROP TABLE IF EXISTS landbase.municipios_alvo_sp CASCADE;
DROP TABLE IF EXISTS landbase.municipios_alvo_sp_labels CASCADE;
DROP TABLE IF EXISTS landbase.vias_alvo_sp CASCADE;
DROP TABLE IF EXISTS landbase.bairros_alvo_sp CASCADE;

CREATE TABLE landbase.municipios_alvo_sp AS
SELECT *
FROM landbase.municipios_sp
WHERE nm_mun IN (
  'São Paulo',
  'Barueri',
  'Cajamar',
  'Carapicuíba',
  'Cotia',
  'Diadema',
  'Embu-Guaçu',
  'Embu das Artes',
  'Itapecerica da Serra',
  'Itapevi',
  'Jandira',
  'Juquitiba',
  'Mauá',
  'Osasco',
  'Pirapora do Bom Jesus',
  'Ribeirão Pires',
  'Rio Grande da Serra',
  'Santana de Parnaíba',
  'Santo André',
  'São Bernardo do Campo',
  'São Caetano do Sul',
  'São Lourenço da Serra',
  'Taboão da Serra',
  'Vargem Grande Paulista'
);
CREATE INDEX municipios_alvo_sp_gix ON landbase.municipios_alvo_sp USING gist(geom);

CREATE TABLE landbase.municipios_alvo_sp_labels AS
SELECT
  nm_mun,
  ST_PointOnSurface(geom) AS geom
FROM landbase.municipios_alvo_sp;
CREATE INDEX municipios_alvo_sp_labels_gix ON landbase.municipios_alvo_sp_labels USING gist(geom);

CREATE TABLE landbase.vias_alvo_sp AS
SELECT
  ST_Transform(l.way, 4674) AS geom,
  l.highway,
  l.name,
  m.nm_mun AS municipio_nome
FROM public.osm_sp_line l
JOIN landbase.municipios_alvo_sp m
  ON ST_Intersects(ST_Transform(l.way, 4674), m.geom)
WHERE l.highway IS NOT NULL
  AND l.highway NOT IN ('footway', 'path', 'cycleway', 'steps', 'proposed', 'construction');
CREATE INDEX vias_alvo_sp_gix ON landbase.vias_alvo_sp USING gist(geom);

CREATE TABLE landbase.bairros_alvo_sp AS
WITH bairro_src AS (
  SELECT
    ST_Transform(p.way, 4674) AS geom,
    p.name AS bairro_nome,
    COALESCE(p.place, p.boundary) AS tipo
  FROM public.osm_sp_polygon p
  WHERE p.name IS NOT NULL
    AND (
      (p.boundary = 'administrative' AND p.admin_level IN ('9', '10', '11'))
      OR p.place IN ('suburb', 'neighbourhood', 'quarter')
    )
)
SELECT
  b.bairro_nome,
  b.tipo,
  m.nm_mun AS municipio_nome,
  'osm_polygon'::text AS origem,
  b.geom
FROM bairro_src b
JOIN landbase.municipios_alvo_sp m
  ON ST_Intersects(b.geom, m.geom);
CREATE INDEX bairros_alvo_sp_gix ON landbase.bairros_alvo_sp USING gist(geom);
SQL

echo "[3/5] Publishing new layers on GeoServer..."
for layer in municipios_alvo_sp municipios_alvo_sp_labels bairros_alvo_sp vias_alvo_sp; do
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
    "${GEOSERVER_URL}/rest/workspaces/${WORKSPACE}/datastores/${STORE}/featuretypes" \
    -d "<featureType><name>${layer}</name></featureType>" >/dev/null || true
done

echo "[4/5] Uploading and applying styles..."
for style in base_sp_municipios_alvo_highlight base_sp_bairros_alvo base_sp_vias_zoom_scales; do
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
    "${GEOSERVER_URL}/rest/styles" \
    -d "<style><name>${style}</name><filename>${style}.sld</filename></style>" >/dev/null || true
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: application/vnd.ogc.sld+xml" -XPUT \
    "${GEOSERVER_URL}/rest/styles/${style}" \
    --data-binary "@${ROOT_DIR}/infra/geoserver/styles/${style}.sld" >/dev/null
done

curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:municipios_alvo_sp" \
  -d "<layer><defaultStyle><name>base_sp_municipios_alvo_highlight</name></defaultStyle></layer>" >/dev/null
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:bairros_alvo_sp" \
  -d "<layer><defaultStyle><name>base_sp_bairros_alvo</name></defaultStyle></layer>" >/dev/null
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:vias_alvo_sp" \
  -d "<layer><defaultStyle><name>base_sp_vias_zoom_scales</name></defaultStyle></layer>" >/dev/null

echo "[5/5] Done."
echo "Layers: ${WORKSPACE}:municipios_alvo_sp, ${WORKSPACE}:bairros_alvo_sp, ${WORKSPACE}:vias_alvo_sp"
