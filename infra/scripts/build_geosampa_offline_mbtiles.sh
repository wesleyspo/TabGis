#!/usr/bin/env sh
# Gera data/tiles/geosampa_offline.mbtiles a partir do WMS GeoSampa (ortofoto).
# Reutiliza o mesmo venv Python que build_sp_satellite_mbtiles.sh.
#
# Exemplos:
#   ./infra/scripts/build_geosampa_offline_mbtiles.sh
#   Por defeito ZMAX=19 (máx. resolução típica no mapa) — ~1M tiles na BBOX do município.
#   Compromisso mais rápido: ZMAX=18 (~250k tiles).
#   WMS_LAYER=geoportal:ORTO_RGB_2020 ZMAX=19 ./infra/scripts/build_geosampa_offline_mbtiles.sh
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
VENV="$ROOT/infra/scripts/.venv"
if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/pip" install -q -r "$ROOT/infra/scripts/requirements-mbtiles.txt"
export MBTILES_OUT="${MBTILES_OUT:-$ROOT/data/tiles/geosampa_offline.mbtiles}"
export ZMIN="${ZMIN:-10}"
export ZMAX="${ZMAX:-19}"
exec "$VENV/bin/python" "$ROOT/infra/scripts/build_geosampa_mbtiles.py"
