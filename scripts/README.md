# Scripts TabGis

Organização de automação e laboratório. **Pipelines de dados e landbase** continuam em `infra/scripts/` (ver `docs/CONTEXT_STATE.md`).

| Pasta / ficheiro | Função |
|------------------|--------|
| `autonomy/run_10h.sh` | Ondas: git/docker, E2E, stress leve, grep legado, diff — relatório em `autonomy-logs/run_*`. |
| `autonomy/run_window_10h.sh` | Repete `run_10h.sh` durante 10 horas com pausa entre ciclos. |
| `autonomy/run_until_0700.sh` | Repete até às **07:00** locais (próxima ocorrência). |
| `stress/stress_api.sh` | Carga HTTP sobre `/api/*` (variáveis `STRESS_*` — ver `docs/AUTONOMY_RUNBOOK.md`). |

## Requisitos

- **GNU date** para `run_until_0700.sh`.
- **curl** para stress; **Node + npm** no `PATH` (ou `.tools/node/current/bin`) para E2E no runner de autonomia.
