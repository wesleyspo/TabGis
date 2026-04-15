#!/usr/bin/env bash
set -euo pipefail

# Cria tabela landbase.via_zoom_config, envia SLD base_sp_vias_zoom_scales e aplica a vias_sp e vias_alvo_sp.

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

export PGPASSWORD="${DB_PASS}"

echo "[1/3] Applying SQL via_zoom_config..."
docker compose -f "${COMPOSE_FILE}" up -d db geoserver >/dev/null
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${ROOT_DIR}/infra/sql/via_zoom_config.sql"

echo "[2/3] Uploading style base_sp_vias_zoom_scales..."
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
  "${GEOSERVER_URL}/rest/styles" \
  -d "<style><name>base_sp_vias_zoom_scales</name><filename>base_sp_vias_zoom_scales.sld</filename></style>" >/dev/null || true
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: application/vnd.ogc.sld+xml" -XPUT \
  "${GEOSERVER_URL}/rest/styles/base_sp_vias_zoom_scales" \
  --data-binary "@${ROOT_DIR}/infra/geoserver/styles/base_sp_vias_zoom_scales.sld" >/dev/null

echo "[3/3] Binding style to road layers..."
for layer in vias_sp vias_alvo_sp; do
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
    "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:${layer}" \
    -d "<layer><defaultStyle><name>base_sp_vias_zoom_scales</name></defaultStyle></layer>" >/dev/null
done

echo "Done. Road layers use scale-dependent style; see landbase.via_zoom_config"
