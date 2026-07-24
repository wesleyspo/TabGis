# TabGis — Operação MWM (equipas, rotas 48h, deslocamentos)

Contrato das APIs de **Mobile Workforce Management** sobre o schema `operations` (equipas reais) e, em paralelo, as rotas de demonstração `mwm.demo_field_*` usadas no mapa.

Marcos: [`MILESTONES.md`](./MILESTONES.md) (M5). Estado da stack: [`CONTEXT_STATE.md`](./CONTEXT_STATE.md).

---

## 1. Modelo de dados

| Objecto | Função |
|---------|--------|
| `operations.team` | Equipas de campo (código, zona, última posição `last_known_geom`). |
| `operations.team_route` | Geometria de rota (`MultiLineString` 4326) para uma janela `[window_start, window_end]` — tipicamente **últimas 48 h**. |
| `operations.team_order_displacement` | Ligação equipa ↔ ordem com horários planeados/efectivos de deslocamento. |
| `mwm.demo_field_crew` / `demo_field_route` / `demo_field_route_point` | Massa de demonstração rica para a aba MWM no mapa (pontos sequenciais). |

Arquivo pré-delete: triggers em `team`, `team_route`, `team_order_displacement` → `audit.operations_row_archive` (ver `infra/sql/03_operations_schema.sql`).

### Seed de rotas 48h

Ficheiro: **`infra/sql/24_mwm_team_routes_48h_demo.sql`**

- Apaga apenas linhas com `source = 'demo_seed_48h'`.
- Insere uma rota por equipa com geometria, janela `now()-48h` … `now()`.
- Preenche deslocamentos em falta para ordens com `assigned_team_id`.

```bash
docker exec -i infra-db-1 psql -U tabgis_admin -d tabgis_db -v ON_ERROR_STOP=1 \
  < infra/sql/24_mwm_team_routes_48h_demo.sql
```

---

## 2. API HTTP

Todas as rotas MWM exigem privilégio **`module.mwm`** quando `SECURITY_ENFORCE=1` (header `X-TabGis-User-Id`).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/teams` | Lista `operations.team` com `lat`/`lng` da última posição. |
| `GET` | `/api/mwm/demo-routes` | Rotas demo (`mwm.demo_field_*`) dos últimos ~2 dias com array `points`. |
| `GET` | `/api/mwm/team-routes` | Rotas operacionais `operations.team_route` na janela. Query: `hours` (1–168, **default 48**), `team_id` (opcional). Resposta: `{ hours, count, routes[] }` com `route_geojson`, `length_m_approx`. |
| `GET` | `/api/mwm/displacements` | Deslocamentos equipa–ordem. Query: `team_id`, `work_order_id`, `limit` (≤500). |

Validação de query: **`backend/lib/mwm/parseTeamRoutesQuery.js`** (`node:test`).

### Exemplos

```bash
curl -s 'http://homeserver:8088/api/mwm/team-routes?hours=48' | jq '.count,.routes[0].team_code'
curl -s 'http://homeserver:8088/api/mwm/displacements?limit=20' | jq 'length'
curl -s 'http://homeserver:8088/api/teams' | jq '.[].team_code'
```

---

## 3. Frontend (aba MWM)

- Tabela de equipas: `GET /api/teams`.
- Overlay no mapa: `GET /api/mwm/demo-routes` (triângulos + polilinhas) e `GET /api/mwm/team-routes` (MultiLineString ciano tracejado, janela 48h).
- Resumo operacional 48h: contagem e comprimento no painel MWM.

---

## 4. Testes

| Tipo | Onde |
|------|------|
| Unitário | `backend/lib/mwm/parseTeamRoutesQuery.test.js` |
| E2E | `e2e/specs/smoke.spec.ts` — «API MWM team-routes 48h responde» |
| Stress | endpoints existentes em `scripts/stress/stress_api.sh` (expansão opcional) |

---

## 5. Evolução

- Ingestão contínua de tracker (substituir `demo_seed_48h` por `source=tracker`).
- `POST`/`PATCH` de rotas e deslocamentos com eventos `mwm.*` no diário `events`.
- Filtro espacial (bbox) nas rotas para mapas com zoom elevado.
