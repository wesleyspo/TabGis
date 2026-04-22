#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/autonomy-logs"
STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="${LOG_DIR}/run_${STAMP}"
REPORT_FILE="${RUN_DIR}/final_report.md"
LOCAL_NODE_BIN="${ROOT_DIR}/.tools/node/current/bin"

mkdir -p "${RUN_DIR}"

log() {
  local msg="$1"
  printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "${msg}" | tee -a "${RUN_DIR}/timeline.log"
}

run_step() {
  local step_id="$1"
  local description="$2"
  shift 2
  local cmd="$*"
  local out_file="${RUN_DIR}/${step_id}.log"

  log "STEP ${step_id} START - ${description}"
  log "CMD: ${cmd}"
  bash -lc "${cmd}" >"${out_file}" 2>&1
  local code=$?
  if [[ ${code} -eq 0 ]]; then
    log "STEP ${step_id} OK"
  else
    log "STEP ${step_id} FAIL (${code}) - continue"
  fi
  printf '| %s | %s | %s |\n' "${step_id}" "${description}" "${code}" >> "${RUN_DIR}/status_table.md"
}

wait_checkpoint() {
  local seconds="$1"
  local reason="$2"
  log "WAIT ${seconds}s - ${reason}"
  sleep "${seconds}"
}

wave_header() {
  local title="$1"
  log "===== ${title} ====="
  printf '\n## %s\n\n' "${title}" >> "${RUN_DIR}/notes.md"
}

init_report() {
  cat > "${REPORT_FILE}" <<EOF
# TabGis - Relatorio de execucao autonoma

- Inicio: $(date +'%Y-%m-%d %H:%M:%S')
- Repositorio: ${ROOT_DIR}
- Pasta de logs: ${RUN_DIR}

## Resultado por etapa

| Etapa | Descricao | Exit code |
|---|---|---|
EOF
}

finalize_report() {
  {
    cat "${RUN_DIR}/status_table.md"
    cat <<EOF

## Linha do tempo

\`\`\`
$(cat "${RUN_DIR}/timeline.log")
\`\`\`

## Observacoes

- Este pipeline foi desenhado para nao parar em falhas isoladas.
- Etapas com falha ficam registradas com log dedicado em \`${RUN_DIR}\`.
- Caso o ambiente nao tenha dependencias (ex.: npm), as etapas relacionadas sao marcadas como falha e o fluxo segue.
EOF
  } >> "${REPORT_FILE}"
}

main() {
  init_report
  log "Run folder: ${RUN_DIR}"
  cd "${ROOT_DIR}" || exit 1
  if [[ -d "${LOCAL_NODE_BIN}" ]]; then
    export PATH="${LOCAL_NODE_BIN}:${PATH}"
    log "Local Node enabled from ${LOCAL_NODE_BIN}"
  fi

  wave_header "Onda 1 - baseline e diagnostico"
  run_step "1.1" "Git status" "git status --short"
  run_step "1.2" "Listar docs principais" "ls docs"
  run_step "1.3" "Checar stack docker" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
  wait_checkpoint 10 "avaliacao temporaria apos baseline"

  wave_header "Onda 2 - validacao automatizada"
  run_step "2.0" "Testes unitarios backend (node:test)" "command -v node >/dev/null && cd backend && npm test || { echo 'backend test falhou'; exit 2; }"
  run_step "2.1" "Instalar dependencias e2e (se npm existir)" "command -v npm >/dev/null && cd e2e && npm install || { echo 'npm indisponivel'; exit 2; }"
  run_step "2.2" "Instalar Chromium Playwright (se npm existir)" "command -v npx >/dev/null && cd e2e && npx playwright install chromium || { echo 'npx/playwright indisponivel'; exit 2; }"
  run_step "2.3" "Executar testes e2e (se npm existir)" "command -v npm >/dev/null && cd e2e && npm test || { echo 'npm indisponivel'; exit 2; }"
  run_step "2.4" "Stress API leve (curl)" "command -v curl >/dev/null && STRESS_ITERATIONS=50 STRESS_BASE_URL=\"\${PLAYWRIGHT_BASE_URL:-http://127.0.0.1:8088}\" bash \"${ROOT_DIR}/scripts/stress/stress_api.sh\" || { echo 'curl ou stress indisponivel'; exit 2; }"
  wait_checkpoint 20 "avaliacao temporaria apos validacao automatizada"

  wave_header "Onda 3 - qualidade de codigo e contexto"
  run_step "3.1" "Buscar termos legados em docs/frontend" "if command -v rg >/dev/null; then rg -n 'GeoUtil|POC|poc' docs frontend; else git grep -n -E 'GeoUtil|POC|poc' -- docs frontend; fi"
  run_step "3.2" "Resumo de arquivos modificados" "git diff --name-only"
  wait_checkpoint 10 "avaliacao temporaria apos qualidade de codigo"

  wave_header "Onda 4 - consolidacao"
  run_step "4.1" "Gerar resumo rapido do diff" "git diff --stat"
  run_step "4.2" "Status final" "git status --short"

  finalize_report
  log "Execucao concluida. Relatorio: ${REPORT_FILE}"
}

main "$@"
