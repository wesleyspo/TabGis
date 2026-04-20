#!/usr/bin/env sh
# Repara data/tiles/geosampa_offline.mbtiles: insere apenas tiles em falta na tabela `tiles`.
# Mesmo venv e dependências que build_geosampa_offline_mbtiles.sh
#
# Exemplo em background:
#   nohup ./infra/scripts/repair_geosampa_offline_mbtiles.sh >> /tmp/geosampa_repair.log 2>&1 &
#
# Variáveis úteis (opcional): DELAY_MS=120 WMS_MAX_ATTEMPTS=6 MBTILES_OUT=...
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
exec "$VENV/bin/python" "$ROOT/infra/scripts/repair_geosampa_mbtiles.py"
