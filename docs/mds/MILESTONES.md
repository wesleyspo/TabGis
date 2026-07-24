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

## M5 — Consolidação APIs de operação / rotas 48h *(em curso / seguinte)*

| Campo | Valor |
|-------|--------|
| **Objectivo** | Endurecer superfície MWM (equipas, deslocamentos, rotas por janela temporal) com testes e documentação de contrato |
| **Estado** | 🔄 Próximo |

## M6 — Endurecimento de segurança (produção)

| Campo | Valor |
|-------|--------|
| **Objectivo** | Credenciais, TLS, sessão real para além de `SECURITY_ENFORCE` + header |
| **Estado** | ⏸ Fora do âmbito da fase actual |

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
