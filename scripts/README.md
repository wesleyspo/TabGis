# Scripts TabGis

Organização de automação e laboratório. **Pipelines de dados e landbase** continuam em `infra/scripts/` (ver `docs/mds/CONTEXT_STATE.md`).

| Pasta / ficheiro | Função |
|------------------|--------|
| `autonomy/run_10h.sh` | Ondas: git/docker, E2E, stress leve, grep legado, diff — relatório em `autonomy-logs/run_*`. |
| `autonomy/run_window_10h.sh` | Repete `run_10h.sh` durante 10 horas com pausa entre ciclos. |
| `autonomy/run_until_0700.sh` | Repete até às **07:00** locais (próxima ocorrência). |
| `stress/stress_api.sh` | Carga HTTP sobre `/api/*` (variáveis `STRESS_*` — ver `docs/mds/AUTONOMY_RUNBOOK.md`). |
| `scripts/docs/build-pages-site.sh` | Gera `docs/html/*.html` e `docs/pdfs/*.pdf` a partir de `docs/mds/*.md`, e `_site/` para GitHub Pages (Pandoc; PDF com Docker `pandoc/extra:3.1` se disponível). Ver `docs/README.md`. |

SQL canónico do diário: `../infra/sql/15_events_schema.sql` (schema `events`). Esquemático: `../infra/sql/16_schematic_schema.sql` (+ opcional `17_…link_poc_equipment.sql`). RBAC: `../infra/sql/18_security_groups_privileges.sql`.

## Requisitos

- **GNU date** para `run_until_0700.sh`.
- **curl** para stress; **Node + npm** no `PATH` (ou `.tools/node/current/bin`) para E2E no runner de autonomia.
- **Pandoc** *ou* **Docker** (`pandoc/core` para HTML; `pandoc/extra` para PDF) para `scripts/docs/build-pages-site.sh`. **Sem sudo:** binário em `~/.local/bin` (ex.: [release Pandoc](https://github.com/jgm/pandoc/releases)) — garantir `export PATH="$HOME/.local/bin:$PATH"` na sessão ou no `~/.profile`.
