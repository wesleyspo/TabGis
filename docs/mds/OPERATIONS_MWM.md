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

Ficheiros: **`infra/sql/25_landbase_route_snap_vias.sql`** (funções de encaixe) + **`infra/sql/24_mwm_team_routes_48h_demo.sql`**

- Apaga apenas linhas com `source = 'demo_seed_48h'`.
- Trajectórias **seguem vias OSM** (`landbase.vias_alvo_sp`): segmentos origem→destino amostrados a ~55 m e projectados na rua mais próxima; paragens de ordens limitadas a **12 km** da equipa e **3 paragens** máx.
- Funções: `landbase.route_line_snapped_to_vias`, `landbase.snap_point_to_nearest_via`, `landbase.route_patrol_nearest_via`, `landbase.avg_distance_route_to_vias_m` (sanidade).

```bash
docker exec -i infra-db-1 psql -U tabgis_admin -d tabgis_db -v ON_ERROR_STOP=1 \
  < infra/sql/25_landbase_route_snap_vias.sql
docker exec -i infra-db-1 psql -U tabgis_admin -d tabgis_db -v ON_ERROR_STOP=1 \
  < infra/sql/24_mwm_team_routes_48h_demo.sql
```

Sanidade (distância média à via &lt; 15 m é o alvo):

```sql
SELECT t.team_code,
       round(landbase.avg_distance_route_to_vias_m(tr.route_geom)::numeric, 1) AS avg_dist_m
FROM operations.team_route tr
JOIN operations.team t ON t.id = tr.team_id
WHERE tr.source = 'demo_seed_48h';
```

---

## 2. API HTTP

Todas as rotas MWM exigem privilégio **`module.mwm`** quando `SECURITY_ENFORCE=1` (header `X-TabGis-User-Id`).

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/teams` | Lista `operations.team` com `lat`/`lng` da última posição. |
| `PATCH` | `/api/teams/:id` | Actualiza última posição (`last_known_lat`/`last_known_lng`) ou `status` (active/inactive/paused). |
| `GET` | `/api/equipment/:id` | Ficha GIS (E2; `module.oms`). |
| `GET` | `/api/consumers/:id` | Ficha consumidor (E2; `module.oms`). |
| `GET` | `/api/mwm/demo-routes` | Rotas demo (`mwm.demo_field_*`) dos últimos ~2 dias com array `points`. |
| `GET` | `/api/mwm/team-routes` | Rotas operacionais `operations.team_route` na janela. Query: `hours` (1–168, **default 48**), `team_id` (opcional). Resposta: `{ hours, count, routes[] }` com `route_geojson`, `length_m_approx`. |
| `GET` | `/api/mwm/displacements` | Deslocamentos equipa–ordem. Query: `team_id`, `work_order_id`, `limit` (≤500). |
| `PATCH` | `/api/mwm/displacements/:id` | Actualiza horários planeados/real e `notes` (campos opcionais, null limpa). |
| `GET` | `/api/mwm/teams/:id` | Detalhe equipa: ficha + ordens + rotas 48h + deslocamentos (L3). |

Validação de query: **`backend/lib/mwm/parseTeamRoutesQuery.js`**; de patch: **`parseDisplacementPatch`** / **`parseTeamPatch`** (`node:test`).

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

## 6. Decisão de routing (L1)

**Decisão (2026-09-04):** o encaixe heurístico (`landbase.route_*` em vias OSM) permanece como **MVP de demos e seeds**. Para o routing operacional real (ordem → equipa → via), adoptamos a **stack open-source** abaixo:

| Opção | Prós | Contras | Uso |
|-------|------|---------|-----|
| **pgRouting (PostGIS)** | Nativo no PostGIS, zero serviço extra, pathfinding SQL | Complexidade de topologia de via, não optimizado para “time-dependent” | Preferido para MVP em campo |
| **OSRM / Valhalla (serviço)** | Routing multi-modal, melhor latência | Deploy e ops externos; dependência de rede | Alternativa para real-time |

**Runbook de decisão (fase seguinte):**
1. Instalar `pgRouting` no contentor `db` (`postgis/postgis` com `CREATE EXTENSION postgis_routing` se disponível, ou imagem `postgis/postgis` com módulo).
2. Criar função `operations.route_via_pgRouting(...)` que usa `pgr_routing` ou `pgr_shortestPath` sobre `landbase.vias_alvo_sp`.
3. Substituir o seed `24` / snap heurístico por um pipeline que grava `team_route` via a função SQL.
4. Se o volume de pedidos exigir, externalizar OSRM/Valhalla e manter o mesmo contrato REST (`GET /api/mwm/team-routes`).

**Não** implementamos pgRouting neste marco: a decisão e o runbook ficam documentados; a entrega de código fica em M7/L1.

---
