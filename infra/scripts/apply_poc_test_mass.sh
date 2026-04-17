#!/usr/bin/env bash
# Aplica massa de teste reprodutível (equipamento + rede + consumidores POC).
# Uso: a partir da raiz do repositório, com Docker Compose a correr:
#   ./infra/scripts/apply_poc_test_mass.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT/infra/docker-compose.yml")

echo "[apply_poc_test_mass] Aplicar infra/sql/14_gis_equipment_network_demo.sql …"
"${COMPOSE[@]}" exec -T db psql -U tabgis_admin -d tabgis_db -v ON_ERROR_STOP=1 \
  < "$ROOT/infra/sql/14_gis_equipment_network_demo.sql"
echo "[apply_poc_test_mass] Concluído. Ver gis.equipment / gis.consumer (prefixo POC_DEMO_ / POC-DEMO-)."
