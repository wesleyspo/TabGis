#!/usr/bin/env bash
set -euo pipefail

# Basemap Sao Paulo Centro (recorte): IBGE municipios + OSM local -> GeoServer base_sp:*
# Runbook: docs/RUNBOOK_BASEMAP_SP.md | Deploy: docs/DEPLOY_POC.md
#
# Reproducible setup for Sao Paulo Centro offline landbase.
# Requires: docker compose, psql client, shp2pgsql, osm2pgsql.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/infra/docker-compose.yml"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-tabgis_db}"
DB_USER="${DB_USER:-tabgis_admin}"
DB_PASS="${DB_PASS:-password123}"

GEOSERVER_URL="${GEOSERVER_URL:-http://localhost:8080/geoserver}"
GS_USER="${GS_USER:-admin}"
GS_PASS="${GS_PASS:-geoserver}"
WORKSPACE="${WORKSPACE:-base_sp}"
STORE="${STORE:-tabgis_postgis}"
SCHEMA="${SCHEMA:-landbase}"

IBGE_ZIP="${IBGE_ZIP:-${ROOT_DIR}/data/raw/ibge/BR_Municipios_2024.zip}"
OSM_CENTRO="${OSM_CENTRO:-${ROOT_DIR}/data/raw/osm/centro_highways.osm}"

export PGPASSWORD="${DB_PASS}"

echo "[1/7] Verifying dependencies and input files..."
for cmd in docker psql shp2pgsql osm2pgsql curl python3; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "Missing dependency: ${cmd}"; exit 1; }
done
[[ -f "${IBGE_ZIP}" ]] || { echo "File not found: ${IBGE_ZIP}"; exit 1; }
[[ -f "${OSM_CENTRO}" ]] || { echo "File not found: ${OSM_CENTRO}"; exit 1; }

echo "[2/7] Ensuring stack is running..."
docker compose -f "${COMPOSE_FILE}" up -d db geoserver >/dev/null

echo "[3/7] Creating PostGIS schema/extensions..."
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE SCHEMA IF NOT EXISTS landbase;
DROP TABLE IF EXISTS landbase.municipios_br CASCADE;
DROP TABLE IF EXISTS landbase.municipio_sp CASCADE;
DROP TABLE IF EXISTS landbase.aoi_centro_sp CASCADE;
DROP TABLE IF EXISTS public.osm_centro_line CASCADE;
DROP TABLE IF EXISTS landbase.vias_centro_sp CASCADE;
SQL

echo "[4/7] Importing IBGE municipal boundaries..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
python3 - <<PY
import zipfile
zip_path = r"${IBGE_ZIP}"
target = r"${TMP_DIR}"
with zipfile.ZipFile(zip_path, "r") as zf:
    zf.extractall(target)
PY
SHAPE_MUN="$(python3 - <<PY
import glob
import os
base = r"${TMP_DIR}"
candidates = sorted(glob.glob(os.path.join(base, "**", "*.shp"), recursive=True))
if not candidates:
    raise SystemExit(1)
print(candidates[0])
PY
)"
shp2pgsql -I -s 4674 "${SHAPE_MUN}" landbase.municipios_br | psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" >/dev/null

echo "[5/7] Building AOI and roads..."
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE TABLE landbase.municipio_sp AS
SELECT * FROM landbase.municipios_br WHERE cd_mun = '3550308';
CREATE INDEX municipio_sp_gix ON landbase.municipio_sp USING gist(geom);

CREATE TABLE landbase.aoi_centro_sp AS
SELECT ST_Intersection(
  ST_SetSRID(ST_MakeEnvelope(-46.70, -23.58, -46.58, -23.50), 4674),
  geom
) AS geom
FROM landbase.municipio_sp;
CREATE INDEX aoi_centro_sp_gix ON landbase.aoi_centro_sp USING gist(geom);
SQL

osm2pgsql \
  --create \
  --database "${DB_NAME}" \
  --host "${DB_HOST}" \
  --port "${DB_PORT}" \
  -U "${DB_USER}" \
  --hstore \
  --prefix osm_centro \
  "${OSM_CENTRO}" >/dev/null

psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE TABLE landbase.vias_centro_sp AS
SELECT way AS geom, highway, name
FROM public.osm_centro_line
WHERE highway IS NOT NULL;
CREATE INDEX vias_centro_sp_gix ON landbase.vias_centro_sp USING gist(geom);
SQL

echo "[6/7] Publishing datastore and layers on GeoServer..."
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
  "${GEOSERVER_URL}/rest/workspaces" \
  -d "<workspace><name>${WORKSPACE}</name></workspace>" >/dev/null || true

curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: application/json" -XPOST \
  "${GEOSERVER_URL}/rest/workspaces/${WORKSPACE}/datastores" \
  -d "{
    \"dataStore\": {
      \"name\": \"${STORE}\",
      \"connectionParameters\": {
        \"host\": \"db\",
        \"port\": \"5432\",
        \"database\": \"${DB_NAME}\",
        \"user\": \"${DB_USER}\",
        \"passwd\": \"${DB_PASS}\",
        \"dbtype\": \"postgis\",
        \"schema\": \"${SCHEMA}\"
      }
    }
  }" >/dev/null || true

for layer in municipio_sp aoi_centro_sp vias_centro_sp; do
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
    "${GEOSERVER_URL}/rest/workspaces/${WORKSPACE}/datastores/${STORE}/featuretypes" \
    -d "<featureType><name>${layer}</name></featureType>" >/dev/null || true
done

echo "[7/7] Uploading and applying SLD styles..."
for style in base_sp_municipio_outline base_sp_aoi_focus base_sp_vias_zoom_scales; do
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
    "${GEOSERVER_URL}/rest/styles" \
    -d "<style><name>${style}</name><filename>${style}.sld</filename></style>" >/dev/null || true
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: application/vnd.ogc.sld+xml" -XPUT \
    "${GEOSERVER_URL}/rest/styles/${style}" \
    --data-binary "@${ROOT_DIR}/infra/geoserver/styles/${style}.sld" >/dev/null
done

curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:municipio_sp" \
  -d "<layer><defaultStyle><name>base_sp_municipio_outline</name></defaultStyle></layer>" >/dev/null
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:aoi_centro_sp" \
  -d "<layer><defaultStyle><name>base_sp_aoi_focus</name></defaultStyle></layer>" >/dev/null
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:vias_centro_sp" \
  -d "<layer><defaultStyle><name>base_sp_vias_zoom_scales</name></defaultStyle></layer>" >/dev/null

echo "Done. Layers ready at ${GEOSERVER_URL}/wms?service=WMS&request=GetCapabilities"
