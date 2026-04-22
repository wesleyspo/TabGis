#!/usr/bin/env bash
# Executa ciclos de `run_10h.sh` até às 07:00 do relógio local (próxima ocorrência se já passou hoje).
# Uso: bash scripts/autonomy/run_until_0700.sh
# Entre ciclos: SLEEP_BETWEEN_CYCLES (default 300s), igual a run_window_10h.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SLEEP_BETWEEN_CYCLES="${SLEEP_BETWEEN_CYCLES:-300}"

next_0700_epoch() {
  local today7 tomorrow7 now
  now="$(date +%s)"
  today7="$(date -d 'today 07:00:00' +%s 2>/dev/null || true)"
  tomorrow7="$(date -d 'tomorrow 07:00:00' +%s 2>/dev/null || true)"
  if [[ -z "${today7}" || -z "${tomorrow7}" ]]; then
    echo "Este script requer GNU date (Linux): date -d 'today 07:00'." >&2
    exit 1
  fi
  if (( now < today7 )); then
    echo "${today7}"
  else
    echo "${tomorrow7}"
  fi
}

END_TS="$(next_0700_epoch)"
echo "TabGis run_until_0700: fim agendado em $(date -d "@${END_TS}" '+%Y-%m-%d %H:%M:%S %z')"

cycle=1
while true; do
  now="$(date +%s)"
  if (( now >= END_TS )); then
    echo "Janela terminada às $(date '+%Y-%m-%d %H:%M:%S'). Ciclos: $((cycle - 1))."
    break
  fi
  echo ""
  echo "===== Ciclo ${cycle} @ $(date '+%Y-%m-%d %H:%M:%S') ====="
  bash "${ROOT_DIR}/scripts/autonomy/run_10h.sh"

  now="$(date +%s)"
  if (( now >= END_TS )); then
    echo "Janela terminada após ciclo ${cycle}."
    break
  fi
  remaining=$((END_TS - now))
  sleep_for="${SLEEP_BETWEEN_CYCLES}"
  if (( remaining < sleep_for )); then
    sleep_for="${remaining}"
  fi
  if (( sleep_for > 0 )); then
    echo "Aguardar ${sleep_for}s até próximo ciclo."
    sleep "${sleep_for}"
  fi
  cycle=$((cycle + 1))
done
