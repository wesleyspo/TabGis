#!/usr/bin/env bash
# TabGis — carga leve sobre endpoints REST (laboratório / CI).
# Variáveis: STRESS_BASE_URL (default http://127.0.0.1:8088), STRESS_ITERATIONS (default 50),
#           STRESS_REPORT_FILE (opcional; JSON escrito no path indicado).
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_URL="${STRESS_BASE_URL:-http://127.0.0.1:8088}"
ITERATIONS="${STRESS_ITERATIONS:-50}"
REPORT_DIR="${STRESS_REPORT_DIR:-${ROOT_DIR}/autonomy-logs}"
REPORT_FILE="${STRESS_REPORT_FILE:-}"

mkdir -p "${REPORT_DIR}"

ok=0
fail=0
start_ts="$(date +%s)"

req() {
  local path="$1"
  if curl -sfS --connect-timeout 4 --max-time 25 "${BASE_URL}${path}" -o /dev/null; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
  fi
}

i=0
while (( i < ITERATIONS )); do
  i=$((i + 1))
  req "/api/translations/pt"
  req "/api/work-orders"
  req "/api/teams"
  req "/api/oms/work-orders/aggregate"
done

end_ts="$(date +%s)"
duration=$((end_ts - start_ts))
total=$((ok + fail))

if [[ -z "${REPORT_FILE}" ]]; then
  REPORT_FILE="${REPORT_DIR}/stress_$(date +%Y%m%d_%H%M%S).json"
fi

{
  printf '{\n'
  printf '  "baseUrl": "%s",\n' "${BASE_URL//\"/\\\"}"
  printf '  "iterations": %s,\n' "${ITERATIONS}"
  printf '  "requestsOk": %s,\n' "${ok}"
  printf '  "requestsFail": %s,\n' "${fail}"
  printf '  "requestsTotal": %s,\n' "${total}"
  printf '  "durationSec": %s\n' "${duration}"
  printf '}\n'
} >"${REPORT_FILE}"

cat "${REPORT_FILE}"

if (( fail * 2 > total )); then
  echo "stress_api.sh: mais de metade dos pedidos falhou." >&2
  exit 1
fi
exit 0
