#!/usr/bin/env bash
# TabGis — carga HTTP sobre endpoints REST (laboratório / CI).
# Variáveis:
#   STRESS_BASE_URL      (default http://127.0.0.1:8088)
#   STRESS_ITERATIONS    (default 50) — número de ondas
#   STRESS_CONCURRENCY   (default 1) — pedidos paralelos por onda (1 = sequencial clássico)
#   STRESS_REPORT_FILE   opcional
#   STRESS_REPORT_DIR    (default autonomy-logs)
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_URL="${STRESS_BASE_URL:-http://127.0.0.1:8088}"
ITERATIONS="${STRESS_ITERATIONS:-50}"
CONCURRENCY="${STRESS_CONCURRENCY:-1}"
REPORT_DIR="${STRESS_REPORT_DIR:-${ROOT_DIR}/autonomy-logs}"
REPORT_FILE="${STRESS_REPORT_FILE:-}"

PATHS=(
  "/api/translations/pt"
  "/api/work-orders"
  "/api/teams"
  "/api/oms/work-orders/aggregate"
)

mkdir -p "${REPORT_DIR}"

ok=0
fail=0
start_ts="$(date +%s)"

one_curl() {
  local path="$1"
  if curl -sfS --connect-timeout 4 --max-time 25 "${BASE_URL}${path}" -o /dev/null; then
    return 0
  fi
  return 1
}

req() {
  local path="$1"
  if one_curl "${path}"; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
  fi
}

parallel_wave() {
  local tmpd
  tmpd="$(mktemp -d)"
  local j=0
  while (( j < CONCURRENCY )); do
    local path="${PATHS[$((j % ${#PATHS[@]}))]}"
    (
      if one_curl "${path}"; then
        : >"${tmpd}/${j}.ok"
      else
        : >"${tmpd}/${j}.fail"
      fi
    ) &
    j=$((j + 1))
  done
  wait
  shopt -s nullglob
  for f in "${tmpd}"/*.ok; do ok=$((ok + 1)); done
  for f in "${tmpd}"/*.fail; do fail=$((fail + 1)); done
  shopt -u nullglob
  rm -rf "${tmpd}"
}

i=0
while (( i < ITERATIONS )); do
  i=$((i + 1))
  if (( CONCURRENCY <= 1 )); then
    req "${PATHS[0]}"
    req "${PATHS[1]}"
    req "${PATHS[2]}"
    req "${PATHS[3]}"
  else
    parallel_wave
  fi
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
  printf '  "concurrency": %s,\n' "${CONCURRENCY}"
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
