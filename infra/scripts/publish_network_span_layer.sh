#!/usr/bin/env bash
set -euo pipefail

# Publica a camada de segmentos lineares da rede (gis.v_network_span_wms) no GeoServer.
# Pré-requisitos: infra/sql/21 e infra/sql/22 aplicados; stack docker em execução.
# Documentação: docs/mds/TOPOLOGY_NATIVE_POSTGIS.md

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

GEOSERVER_URL="${GEOSERVER_URL:-http://localhost:8080/geoserver}"
GS_USER="${GS_USER:-admin}"
GS_PASS="${GS_PASS:-geoserver}"
WORKSPACE="${WORKSPACE:-base_sp}"
STORE="${STORE:-tabgis_postgis_gis}"

DB_HOST_IN_DOCKER="${DB_HOST_IN_DOCKER:-db}"
DB_NAME="${DB_NAME:-tabgis_db}"
DB_USER="${DB_USER:-tabgis_admin}"
DB_PASS="${DB_PASS:-password123}"

LAYER="v_network_span_wms"
STYLE="gis_network_span"

echo "[1/4] Ensuring datastore ${WORKSPACE}:${STORE} (schema gis)..."
if ! curl -sf -u "${GS_USER}:${GS_PASS}" \
  "${GEOSERVER_URL}/rest/workspaces/${WORKSPACE}/datastores/${STORE}.json" >/dev/null 2>&1; then
  curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
    "${GEOSERVER_URL}/rest/workspaces/${WORKSPACE}/datastores" \
    -d "<dataStore>
          <name>${STORE}</name>
          <connectionParameters>
            <host>${DB_HOST_IN_DOCKER}</host>
            <port>5432</port>
            <database>${DB_NAME}</database>
            <schema>gis</schema>
            <user>${DB_USER}</user>
            <passwd>${DB_PASS}</passwd>
            <dbtype>postgis</dbtype>
          </connectionParameters>
        </dataStore>"
  echo "  datastore created."
else
  echo "  datastore already exists."
fi

echo "[2/4] Publishing feature type ${LAYER}..."
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
  "${GEOSERVER_URL}/rest/workspaces/${WORKSPACE}/datastores/${STORE}/featuretypes" \
  -d "<featureType>
        <name>${LAYER}</name>
        <nativeName>${LAYER}</nativeName>
        <srs>EPSG:4326</srs>
      </featureType>" >/dev/null || true

echo "[3/4] Uploading style ${STYLE}..."
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPOST \
  "${GEOSERVER_URL}/rest/styles" \
  -d "<style><name>${STYLE}</name><filename>${STYLE}.sld</filename></style>" >/dev/null || true
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: application/vnd.ogc.sld+xml" -XPUT \
  "${GEOSERVER_URL}/rest/styles/${STYLE}" \
  --data-binary "@${ROOT_DIR}/infra/geoserver/styles/${STYLE}.sld" >/dev/null

echo "[4/4] Applying default style..."
curl -s -u "${GS_USER}:${GS_PASS}" -H "Content-Type: text/xml" -XPUT \
  "${GEOSERVER_URL}/rest/layers/${WORKSPACE}:${LAYER}" \
  -d "<layer><defaultStyle><name>${STYLE}</name></defaultStyle></layer>" >/dev/null

echo "Done. Layer: ${WORKSPACE}:${LAYER} (WMS/WFS), style: ${STYLE}"
