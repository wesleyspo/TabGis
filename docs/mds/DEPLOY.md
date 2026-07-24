# Deploy TabGis

Este documento e a referencia principal de deploy para ambiente TabGis moderno.

## Ambiente padrao
- Orquestracao: `infra/docker-compose.yml`
- Frontend/proxy: `http://<host>:8088/`
- GeoServer: `http://<host>:8080/geoserver/web`
- TileServer: `http://<host>:8081/`

## Sequencia recomendada
1. Subir stack:
   - `docker compose -f infra/docker-compose.yml up -d`
2. Verificar containers:
   - `docker ps --format "table {{.Names}}\t{{.Status}}"`
3. Validar frontend:
   - abrir `http://<host>:8088/`

## 2. Banco e scripts SQL

Executar scripts versionados em `infra/sql/` na ordem indicada em `docs/mds/CONTEXT_STATE.md` (tabela *Scripts versionados*) ou, para o passo-a-passo alargado, em `docs/mds/DEPLOY_POC.md` (secção 2).

Incluir **`infra/sql/15_events_schema.sql`** antes de depender de `GET /api/events`, **`GET /api/events/export`** ou de emissão de eventos na API (pode aplicar-se após `01_init_schemas.sql`; ver `docs/mds/EVENTS_ARCHITECTURE.md`).

Para **RBAC** (grupos/privilégios na UI e enforcement opcional na API), aplicar **`infra/sql/18_security_groups_privileges.sql`** após `01`. Para **esquemático** REST/UI (**ESQ**): **`16_schematic_schema.sql`** e, se existir massa POC em `gis.equipment`, **`17_schematic_link_poc_equipment.sql`**. Opcional pós-pipeline de bairros: **`19_fix_bairros_alvo_mapping.sql`**, **`20_sanity_bairros_alvo_sp.sql`** (este último falha se ainda houver ruído «bairro = município»).

Para **topologia nativa de rede** (`postgis_topology`, segmentos lineares `gis.network_span`, API `/api/topology/*`): aplicar em ordem **`infra/sql/21_postgis_topology_utilities.sql`**, **`infra/sql/22_topology_span_write_support.sql`**, **`infra/sql/23_topology_prune_orphan_primitives.sql`** — ver **`docs/mds/TOPOLOGY_NATIVE_POSTGIS.md`** e marcos em **`docs/mds/MILESTONES.md`**. Publicar a camada WMS: `bash infra/scripts/publish_network_span_layer.sh`. Rótulos regionalizados: reaplicar também **`infra/sql/02_populate_translations.sql`** quando o glossário i18n mudar.

## Diagnostico rapido
- Preferir acesso via `:8088` para garantir same-origin (`/geoserver`, `/tiles`, `/api`).
- Em caso de recreacao do TileServer, reiniciar `web` para re-resolver DNS interno Docker.

## Referencias complementares
- `docs/README.md` — home do índice de documentação (Markdown) e ligação a `docs/html/` e `docs/pdfs/`
- `docs/mds/ARCHITECTURE_BPMN.md` — diagrama de módulos (Mermaid) e deploy
- `.github/workflows/pages.yml` — GitHub Pages (HTML gerado a partir de `docs/*.md` + ajuda)
- `docs/mds/CONTEXT_STATE.md`
- `docs/mds/DEPLOY_POC.md` (legado com detalhes historicos e troubleshooting estendido)
