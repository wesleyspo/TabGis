#!/usr/bin/env sh
# Gera data/tiles/sp_satellite.mbtiles a partir de tiles Esri (XYZ).
# Cria infra/scripts/.venv e instala requirements-mbtiles.txt (PEP 668 seguro).
#
# Defaults: BBOX = capital SP com margem W/E extra (ver DEFAULT_BBOX no .py), ZMIN=10, ZMAX=17.
#
#   Escala de tempo e disco por ZMAX (bbox capital SP ~1°×0.9°):
#     ZMAX=14 →    2 959 tiles  ~  4 min   ~  50 MB   (rápido, resolução 9 m/px)
#     ZMAX=15 →   11 331 tiles  ~ 14 min   ~ 200 MB   (bom compromisso)
#     ZMAX=16 →   44 271 tiles  ~ 55 min   ~ 800 MB   (resolução 2.4 m/px)
#     ZMAX=17 →  175 306 tiles  ~ 3.5 h    ~   3 GB   (default: resolução 1.2 m/px)
#     ZMAX=18 →  697 270 tiles  ~ 14 h     ~  12 GB   (impraticável para POC)
#
#   Para geração rápida (primeiros testes), usar ZMAX=15:
#     ZMAX=15 ./build_sp_satellite_mbtiles.sh
#
#   Para estado inteiro em baixa resolução:
#     BBOX="-53.2,-25.4,-44.0,-19.7" ZMAX=12 ./build_sp_satellite_mbtiles.sh
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
VENV="$ROOT/infra/scripts/.venv"
if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/pip" install -q -r "$ROOT/infra/scripts/requirements-mbtiles.txt"
export MBTILES_OUT="${MBTILES_OUT:-$ROOT/data/tiles/sp_satellite.mbtiles}"
export ZMIN="${ZMIN:-10}"
export ZMAX="${ZMAX:-17}"
exec "$VENV/bin/python" "$ROOT/infra/scripts/build_mbtiles_esri.py"
