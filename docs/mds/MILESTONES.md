# TabGis — Marcos de desenvolvimento

Registo cronológico dos marcos entregues (ajustes validados com testes e documentação).  
Estado operacional detalhado: [`CONTEXT_STATE.md`](./CONTEXT_STATE.md).

---

## Convenção

Cada marco deve deixar:

1. **Código** funcional na stack Docker (`infra/docker-compose.yml`).
2. **Testes** automatizados (unitários `backend` e/ou E2E Playwright).
3. **Documentação** actualizada em `docs/mds/` (e ajuda do operador quando a UI muda).
4. **Commit** local em `main` com mensagem orientada ao *porquê*.

---

## M1 — Topologia nativa (leitura)

| Campo | Valor |
|-------|--------|
| **Entrega** | Extensão `postgis_topology`, schema `tabgis_utilities_topo`, tabela `gis.network_span`, `GET /api/topology/meta` e `GET /api/topology/spans` |
| **SQL** | `infra/sql/21_postgis_topology_utilities.sql` |
| **Docs** | `TOPOLOGY_NATIVE_POSTGIS.md` |
| **Estado** | ✅ |

## M2 — Edição REST + camada mapa + auditoria

| Campo | Valor |
|-------|--------|
| **Entrega** | `POST`/`PATCH`/`DELETE /api/topology/spans`; eventos `gis.topology.network_span.*`; arquivo pré-delete; vista WMS `gis.v_network_span_wms`; toggle no frontend; GetFeatureInfo |
| **SQL / scripts** | `22_topology_span_write_support.sql`, `publish_network_span_layer.sh`, SLD `gis_network_span.sld` |
| **Testes** | `lib/topology/validateSpanWrite.test.js`; E2E toggle WMS |
| **Estado** | ✅ |

## M3 — Limpeza de primitivas órfãs

| Campo | Valor |
|-------|--------|
| **Entrega** | `gis.prune_orphan_topology_primitives` + `POST /api/topology/maintenance/prune` |
| **SQL** | `23_topology_prune_orphan_primitives.sql` |
| **Docs** | `TOPOLOGY_NATIVE_POSTGIS.md` §5 |
| **Estado** | ✅ |

## M4 — Desenho interactivo no mapa + código auto

| Campo | Valor |
|-------|--------|
| **Entrega** | Botão «Desenhar segmento» (Leaflet); `POST` sem `code` gera `SEG_YYYYMMDD_HHMMSSmmm`; i18n `UI_NETWORK_SPAN_DRAW_*` |
| **Código** | `frontend/main.js` (modo desenho); `backend/lib/topology/generateSpanCode.js` |
| **Testes** | `generateSpanCode.test.js`; E2E «desenho de segmento no mapa cria via POST» |
| **Docs** | Este ficheiro; `TOPOLOGY_NATIVE_POSTGIS.md`; `CONTEXT_STATE.md`; `help.html` |
| **Estado** | ✅ (2026-07-24) |

## M5 — Consolidação APIs de operação / rotas 48h

| Campo | Valor |
|-------|--------|
| **Entrega** | `GET /api/mwm/team-routes?hours=` e `GET /api/mwm/displacements`; seed `24_mwm_team_routes_48h_demo.sql`; resumo 48h na aba MWM; overlay GeoJSON no mapa (ciano); docs `OPERATIONS_MWM.md` |
| **Testes** | `lib/mwm/parseTeamRoutesQuery.test.js`; E2E team-routes + resumo UI MWM (9 smoke verdes) |
| **Estado** | ✅ (2026-07-24) |

## M5b — Rotas de equipa encaixadas em vias OSM

| Campo | Valor |
|-------|--------|
| **Entrega** | `25_landbase_route_snap_vias.sql` (snap/patrulha); seed `24` reescrito — trajectórias sobre `landbase.vias_alvo_sp` (sem linhas rectas); fallback de patrulha se aderência &gt; 50 m |
| **Sanidade** | `landbase.avg_distance_route_to_vias_m` — alvo &lt; 15 m por equipa |
| **Estado** | ✅ (2026-07-24) |

## M6 — Endurecimento de segurança (produção)

| Campo | Valor |
|-------|--------|
| **Objectivo** | Credenciais, TLS, sessão real para além de `SECURITY_ENFORCE` + header |
| **Estado** | ⏸ Fora do âmbito da fase actual |

## M7 — Fase 2: logística · entidades · dinamismo · auditoria (em planeamento)

| Campo | Valor |
|-------|--------|
| **Objectivo** | Normalização completa do produto operacional em torno dos quatro pilares (ver `CONTEXT_STATE.md` § Direcção estratégica) |
| **Primeira entrega alvo** | Commit M5b + mapa OMS; decisão routing; padrão de ficha entidade |
| **Estado** | 🔄 2026-09-04 — L1 decisão + L2/L4 API; commit M5b + push em curso |

### Entregas em curso (M7)

| # | Entrega | Estado |
|---|--------|--------|
| M5b | Rotas encaixadas em vias OSM | ✅ |
| L1 | Decisão routing (pgRouting vs OSRM) | ✅ documentada |
| L2 | PATCH `displacements` | ✅ |
| L4 | PATCH `teams` (última posição) | ✅ |

---

## Índice rápido de documentação técnica

| Tema | Ficheiro |
|------|----------|
| Estado da stack | `CONTEXT_STATE.md` |
| Topologia PostGIS | `TOPOLOGY_NATIVE_POSTGIS.md` |
| Eventos / export Mongo | `EVENTS_ARCHITECTURE.md` |
| Deploy | `DEPLOY.md` |
| Autonomia / stress | `AUTONOMY_RUNBOOK.md` |
| Escopo produto | `Escopo_Projeto_TabGis.md` |
| Home docs | `../README.md` |
