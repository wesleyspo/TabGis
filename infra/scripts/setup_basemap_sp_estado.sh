#!/usr/bin/env bash
set -euo pipefail

# Basemap SP (estado completo): IBGE + OSM -> PostGIS landbase.* -> GeoServer base_sp:*
# Runbook: docs/RUNBOOK_BASEMAP_SP_ESTADO.md | Deploy: docs/DEPLOY_POC.md
#
# Reproducible setup for Sao Paulo state offline landbase.
# Requires: docker compose, psql client, shp2pgsql, osm2pgsql, curl, python3.

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

IBGE_MUN_ZIP="${IBGE_MUN_ZIP:-${ROOT_DIR}/data/raw/ibge/BR_Municipios_2024.zip}"
IBGE_UF_ZIP="${IBGE_UF_ZIP:-${ROOT_DIR}/data/raw/ibge/BR_UF_2024.zip}"
OSM_SP="${OSM_SP:-${ROOT_DIR}/data/raw/osm/sao-paulo-latest.osm.pbf}"
OSM_SP_URL="${OSM_SP_URL:-https://download.geofabrik.de/south-america/brazil/sudeste/sao-paulo-latest.osm.pbf}"
OSM_SUDESTE="${OSM_SUDESTE:-${ROOT_DIR}/data/raw/osm/sudeste-latest.osm.pbf}"
SP_BBOX="${SP_BBOX:--53.2,-25.4,-44.0,-19.7}"

export PGPASSWORD="${DB_PASS}"

echo "[1/8] Verifying dependencies and source data..."
for cmd in docker psql shp2pgsql osm2pgsql curl python3; do
  command -v "${cmd}" >/dev/null 2>&1 || { echo "Missing dependency: ${cmd}"; exit 1; }
done
[[ -f "${IBGE_MUN_ZIP}" ]] || { echo "File not found: ${IBGE_MUN_ZIP}"; exit 1; }
[[ -f "${IBGE_UF_ZIP}" ]] || { echo "File not found: ${IBGE_UF_ZIP}"; exit 1; }
if [[ ! -f "${OSM_SP}" ]]; then
  echo "OSM state extract not found. Downloading from Geofabrik..."
  mkdir -p "$(dirname "${OSM_SP}")"
  if ! curl -fL "${OSM_SP_URL}" -o "${OSM_SP}"; then
    rm -f "${OSM_SP}"
    echo "Download failed (HTTP error or URL changed). Place a valid PBF at ${OSM_SP} or ensure ${OSM_SUDESTE} exists for bbox fallback."
  fi
fi

OSM_SOURCE="${OSM_SP}"
if ! python3 - <<PY
from pathlib import Path
p = Path(r"${OSM_SP}")
b = p.read_bytes()[:200] if p.exists() else b""
raise SystemExit(0 if (len(b) > 4 and not b.startswith(b"<!DOCTYPE html")) else 1)
PY
then
  echo "State extract is not a valid PBF. Falling back to sudeste extract with SP bbox..."
  [[ -f "${OSM_SUDESTE}" ]] || { echo "Fallback file not found: ${OSM_SUDESTE}"; exit 1; }
  OSM_SOURCE="${OSM_SUDESTE}"
fi

echo "[2/8] Ensuring stack is running..."
docker compose -f "${COMPOSE_FILE}" up -d db geoserver >/dev/null

echo "[3/8] Preparing PostGIS schema..."
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE SCHEMA IF NOT EXISTS landbase;

DROP TABLE IF EXISTS landbase.uf_br CASCADE;
DROP TABLE IF EXISTS landbase.municipios_br CASCADE;
DROP TABLE IF EXISTS landbase.uf_sp CASCADE;
DROP TABLE IF EXISTS landbase.municipios_sp CASCADE;
DROP TABLE IF EXISTS landbase.vias_sp CASCADE;
DROP TABLE IF EXISTS public.osm_sp_line CASCADE;
SQL

echo "[4/8] Importing IBGE UF and municipal boundaries..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
python3 - <<PY
import zipfile
zipfiles = [r"${IBGE_UF_ZIP}", r"${IBGE_MUN_ZIP}"]
target = r"${TMP_DIR}"
for item in zipfiles:
    with zipfile.ZipFile(item, "r") as zf:
        zf.extractall(target)
PY

SHAPE_UF="$(python3 - <<PY
import glob
import os
base = r"${TMP_DIR}"
for path in sorted(glob.glob(os.path.join(base, "**", "*.shp"), recursive=True)):
    if "UF" in os.path.basename(path).upper():
        print(path)
        break
else:
    raise SystemExit(1)
PY
)"

SHAPE_MUN="$(python3 - <<PY
import glob
import os
base = r"${TMP_DIR}"
for path in sorted(glob.glob(os.path.join(base, "**", "*.shp"), recursive=True)):
    if "MUNICIP" in os.path.basename(path).upper():
        print(path)
        break
else:
    raise SystemExit(1)
PY
)"

shp2pgsql -I -s 4674 "${SHAPE_UF}" landbase.uf_br | psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" >/dev/null
shp2pgsql -I -s 4674 "${SHAPE_MUN}" landbase.municipios_br | psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" >/dev/null

echo "[5/8] Deriving SP state layers..."
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE TABLE landbase.uf_sp AS
SELECT * FROM landbase.uf_br WHERE sigla_uf = 'SP';
CREATE INDEX uf_sp_gix ON landbase.uf_sp USING gist(geom);

CREATE TABLE landbase.municipios_sp AS
SELECT m.*
FROM landbase.municipios_br m
JOIN landbase.uf_sp sp
  ON ST_Intersects(m.geom, sp.geom);
CREATE INDEX municipios_sp_gix ON landbase.municipios_sp USING gist(geom);
SQL

echo "[6/8] Importing state OSM roads and creating thematic roads table..."
osm2pgsql \
  --create \
  --database "${DB_NAME}" \
  --host "${DB_HOST}" \
  --port "${DB_PORT}" \
  -U "${DB_USER}" \
  --hstore \
  --bbox "${SP_BBOX}" \
  --prefix osm_sp \
  "${OSM_SOURCE}" >/dev/null

psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE TABLE landbase.vias_sp AS
SELECT ST_Transform(l.way, 4674) AS geom, l.highway, l.name
FROM public.osm_sp_line l
JOIN landbase.uf_sp sp
  ON ST_Intersects(ST_Transform(l.way, 4674), sp.geom)
WHERE l.highway IS NOT NULL;
CREATE INDEX vias_sp_gix ON landbase.vias_sp USING gist(geom);
SQL

echo "[7/8] Publishing layers in GeoServer..."
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

for layer in uf_sp municipios_sp vias_sp; do
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
    "${GEOSERVER_URL}/rest/workspaces/${WORKSPACE}/datastores/${STORE}/featuretypes" \
    -d "<featureType><name>${layer}</name></featureType>" >/dev/null || true
done

echo "[8/8] Uploading and applying state styles..."
for style in base_sp_uf_outline base_sp_municipios_outline base_sp_vias_zoom_scales; do
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
    "${GEOSERVER_URL}/rest/styles" \
    -d "<style><name>${style}</name><filename>${style}.sld</filename></style>" >/dev/null || true
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: application/vnd.ogc.sld+xml" -XPUT \
    "${GEOSERVER_URL}/rest/styles/${style}" \
    --data-binary "@${ROOT_DIR}/infra/geoserver/styles/${style}.sld" >/dev/null
done

curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:uf_sp" \
  -d "<layer><defaultStyle><name>base_sp_uf_outline</name></defaultStyle></layer>" >/dev/null
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:municipios_sp" \
  -d "<layer><defaultStyle><name>base_sp_municipios_outline</name></defaultStyle></layer>" >/dev/null
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:vias_sp" \
  -d "<layer><defaultStyle><name>base_sp_vias_zoom_scales</name></defaultStyle></layer>" >/dev/null

echo "Done. State layers published at ${GEOSERVER_URL}/wms?service=WMS&request=GetCapabilities"
