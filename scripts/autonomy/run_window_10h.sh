#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WINDOW_SECONDS=$((10 * 60 * 60))
SLEEP_BETWEEN_CYCLES=300
START_TS="$(date +%s)"
END_TS=$((START_TS + WINDOW_SECONDS))

echo "TabGis autonomy window start: $(date -d "@${START_TS}" '+%Y-%m-%d %H:%M:%S')"
echo "TabGis autonomy window end:   $(date -d "@${END_TS}" '+%Y-%m-%d %H:%M:%S')"

cycle=1
while true; do
  now="$(date +%s)"
  if (( now >= END_TS )); then
    echo "Autonomy window complete after ${cycle} cycles."
    break
  fi

  echo
  echo "===== Cycle ${cycle} started at $(date '+%Y-%m-%d %H:%M:%S') ====="
  bash "${ROOT_DIR}/scripts/autonomy/run_10h.sh"

  now="$(date +%s)"
  remaining=$((END_TS - now))
  if (( remaining <= 0 )); then
    echo "Autonomy window complete after cycle ${cycle}."
    break
  fi

  sleep_for="${SLEEP_BETWEEN_CYCLES}"
  if (( remaining < sleep_for )); then
    sleep_for="${remaining}"
  fi
  echo "Cycle ${cycle} finished. Waiting ${sleep_for}s before next cycle."
  sleep "${sleep_for}"
  cycle=$((cycle + 1))
done
