# Topologia nativa de rede (PostGIS Topology)

Este documento descreve **o que** o modelo entrega ao produto TabGis e **como** está construído tecnicamente sobre a extensão oficial **`postgis_topology`**.

---

## 1. Perspectiva funcional

### Objetivo

Representar **segmentos lineares da rede** (conductores, tubagens, cabos, etc.) como linhas que **partilham vértices de forma consistente**: quando dois segmentos coincidem num ponto dentro da **tolerância** definida para a topologia, o PostGIS garante o **mesmo nó topológico**. Isso evita “pontos duplicados” que não se ligam entre si em análises de continuidade.

### O que o operador ou integrador ganha

- **Continuidade explícita**: primitivas `node` / `edge_data` no schema da topologia (`tabgis_utilities_topo`) reflectem a malha administrada pelo motor topológico.
- **Dupla representação legível**:
  - **`span_geom`** (`geometry(LineString,4326)`): interoperável (GeoJSON na API, WFS no futuro).
  - **`topo_geom`** (`topology.TopoGeometry`): referência à topologia nativa, adequada a operações que respeitam nós partilhados.
- **Pontos de ligação ao cadastro**: `equipment_from_id` / `equipment_to_id` opcionais para associar segmentos a `gis.equipment` quando fizer sentido de negócio.

### O que ainda não é (marcos futuros)

- **Edição de vértices existentes no mapa** (mover/inserir vértices de um segmento já gravado); hoje o desenho cria novos segmentos; alterações de geometria usam `PATCH /api/topology/spans/:id`.
- **CRS projetado** para tolerância em metros constantes em toda a área — ver secção 5.

---

## 2. Perspectiva técnica

### Extensão e topologia nomeada

1. **`CREATE EXTENSION postgis_topology`** — carrega funções e catálogos globais (`topology.topology`, `topology.layer`, …).
2. **`topology.CreateTopology(name, srid, precision)`** — cria um **schema** com o nome da topologia (ex.: `tabgis_utilities_topo`) contendo as tabelas internas:
   - **`edge_data`** — arestas dirigidas;
   - **`node`** — vértices;
   - **`face`** — faces (úteis se mais tarde existirem polígonos de zona ou subdivisão planar);
   - **`relation`** — associação entre feições e primitivas.

Parâmetros TabGis:

| Parâmetro | Valor actual | Notas |
|-----------|--------------|-------|
| Nome | `tabgis_utilities_topo` | Constante acordada no código (`backend/server.js`) e na migração SQL. |
| SRID | **4326** | Alinhado a `gis.equipment.geom` / restantes camadas utilities em graus. |
| `precision` | **1e-6** graus | Ordem de grandeza ~cm–dm conforme latitude; afinar se necessário. |

### Camada de TopoGeometry

**`topology.AddTopoGeometryColumn(topology, schema, table, column, type)`** regista uma camada e adiciona a coluna. Para segmentos lineares usamos tipo **`LINE`** (equivalente a LineString na camada).

### População: `toTopoGeom`

**`topology.toTopoGeom(geom, topology_name, layer_id, tolerance)`** converte a geometria simples em `TopoGeometry` e **materializa** primitivas na topologia. A tolerância efectiva utilizada na migração é a **`precision`** registada em `topology.topology` para esta topologia (compatível com a versão PostGIS em uso — valores negativos como “usar padrão” não são aceites em todas as builds).

### Artefactos de negócio em `gis`

| Objeto | Função |
|--------|--------|
| **`gis.network_span`** | Um segmento linear com `span_geom` obrigatório, `topo_geom` preenchido após conversão e `updated_at` para rastrear edições REST. |
| **`gis.v_network_span_readable`** | Vista com comprimento geodésico aproximado (`length_m_approx`) para leitura humana. |
| **`gis.v_network_span_wms`** | Vista de publicação GeoServer (sem a coluna `TopoGeometry`, que o datastore PostGIS do GeoServer não reconhece); coluna geométrica `geom`. |

### Migrações versionadas

| Ficheiro | Conteúdo |
|----------|----------|
| **`infra/sql/21_postgis_topology_utilities.sql`** | Extensão, topologia, tabela, camada TopoGeometry, três segmentos demo que partilham vértices (validação de fusão de nós). |
| **`infra/sql/22_topology_span_write_support.sql`** | Coluna `updated_at`; trigger **BEFORE DELETE** de arquivo em `audit.operations_row_archive` (mesma função genérica do schema `operations`); vista `gis.v_network_span_wms`. |
| **`infra/sql/23_topology_prune_orphan_primitives.sql`** | Função `gis.prune_orphan_topology_primitives(dry_run)` — remove arestas órfãs e nós isolados; exposta em `POST /api/topology/maintenance/prune`. |

### Camada de mapa (GeoServer + Leaflet)

- **Publicação**: `infra/scripts/publish_network_span_layer.sh` cria o datastore **`base_sp:tabgis_postgis_gis`** (schema `gis`), publica **`base_sp:v_network_span_wms`** e aplica o estilo **`gis_network_span`** (`infra/geoserver/styles/gis_network_span.sld` — linha âmbar com halo claro e rótulo `code` ao longo da linha).
- **Frontend**: toggle **Camadas → Rede técnica → «Segmentos lineares da rede»** (`#network_span_layer`); botão **«Desenhar segmento»** (`#network_span_draw_btn`) — clique adiciona vértices, Enter/duplo clique grava via `POST /api/topology/spans` (código auto `SEG_YYYYMMDD_HHMMSSmmm` se omitido), Esc cancela; GetFeatureInfo inclui a camada. Chaves i18n: `UI_LAYER_GROUP_NETWORK`, `UI_LAYER_NETWORK_SPANS`, `UI_LAYER_NETWORK_SPANS_HINT`, `UI_NETWORK_SPAN_DRAW_*`.
- **E2E**: fumo activa o toggle WMS; segundo teste desenha dois vértices, confirma `POST` 201 e limpa com `DELETE` + `prune`.

---

## 3. API HTTP (leitura e edição)

Requer o mesmo perfil que operações sobre ordens quando **`SECURITY_ENFORCE=1`**: privilégio **`module.oms`** e cabeçalho **`X-TabGis-User-Id`** válido.

| Método | Rota | Resposta / efeito |
|--------|------|-------------------|
| `GET` | `/api/topology/meta` | Estado da topologia `tabgis_utilities_topo`, camadas em `topology.layer`, contagens de `edges` / `nodes` / `faces`. Se a topologia não existir, `{ ok, installed: false, hint }`. |
| `GET` | `/api/topology/spans?limit=` | Lista segmentos lineares com `span_geojson`, `has_topo_geom`, `length_m_approx` (máx. 500). |
| `GET` | `/api/topology/spans/:id` | Detalhe de um segmento (inclui `metadata` e `updated_at`). |
| `POST` | `/api/topology/spans` | Cria segmento: `coordinates` obrigatório (`[[lng,lat],…]`, ≥2 vértices); `code` **opcional** — se omitido, a API gera `SEG_YYYYMMDD_HHMMSSmmm` (`generateSpanCode`); opcionais `description`, `utility_domain`, `equipment_from_id`, `equipment_to_id`, `metadata`. Insere `span_geom` e materializa `topo_geom` com `toTopoGeom` na mesma transacção. `409` em código duplicado. Emite **`gis.topology.network_span.created`**. |
| `PATCH` | `/api/topology/spans/:id` | Atualização parcial; `coordinates` retraça a geometria (limpa a TopoGeometry anterior com `clearTopoGeom` e re-materializa). `code` é imutável. Emite **`gis.topology.network_span.updated`**. |
| `DELETE` | `/api/topology/spans/:id` | Limpa a TopoGeometry, apaga a linha — o trigger BEFORE DELETE arquiva o snapshot em `audit.operations_row_archive` antes da remoção. Emite **`gis.topology.network_span.deleted`**. |
| `POST` | `/api/topology/maintenance/prune` | Remove primitivas órfãs (arestas sem referência em `relation`, depois nós isolados) com `ST_RemEdgeModFace` / `ST_RemIsoNode`. Corpo opcional `{"dry_run": true}` só conta. Emite **`gis.topology.maintenance.pruned`** quando remove. Função: `gis.prune_orphan_topology_primitives` (`infra/sql/23`). |

Validação dos corpos em **`backend/lib/topology/validateSpanWrite.js`**; geração de código em **`backend/lib/topology/generateSpanCode.js`** (ambos com `node:test` — `npm test`).

Sem enforcement de segurança (ambiente dev típico), as rotas respondem sem cabeçalho.

### Exemplo de criação (código explícito ou auto)

```bash
# Código explícito
curl -X POST http://homeserver:8088/api/topology/spans \
  -H 'Content-Type: application/json' \
  -d '{"code":"SEG_FEEDER_A1","utility_domain":"electric",
       "coordinates":[[-46.6408,-23.5528],[-46.6430,-23.5540]]}'

# Código gerado pela API (desenho no mapa usa este modo)
curl -X POST http://homeserver:8088/api/topology/spans \
  -H 'Content-Type: application/json' \
  -d '{"coordinates":[[-46.6408,-23.5528],[-46.6430,-23.5540]],
       "metadata":{"source":"map_draw"}}'
```

---

## 4. Operação e validação

### Aplicar ou repetir a migração

```bash
docker exec -i infra-db-1 psql -U tabgis_admin -d tabgis_db -v ON_ERROR_STOP=1 \
  < infra/sql/21_postgis_topology_utilities.sql
```

### Verificações rápidas em SQL

```sql
SELECT name, srid, precision FROM topology.topology WHERE name = 'tabgis_utilities_topo';

SELECT COUNT(*) AS edges FROM tabgis_utilities_topo.edge_data;
SELECT COUNT(*) AS nodes FROM tabgis_utilities_topo.node;

SELECT id, code, topo_geom IS NOT NULL AS has_topo FROM gis.network_span ORDER BY id;
```

### Validar integridade topológica (opcional)

```sql
SELECT * FROM topology.ValidateTopology('tabgis_utilities_topo');
```

Corrigir erros reportados antes de confiar em análises de continuidade em produção.

---

## 5. Limitações e boas práticas

0. **Primitivas órfãs**: o DELETE de um segmento não remove primitivas partilháveis de imediato — execute periodicamente `POST /api/topology/maintenance/prune` (ou `SELECT * FROM gis.prune_orphan_topology_primitives(false)`). No **dry-run**, a contagem de nós isolados subestima: nós só ficam isolados depois de removidas as arestas órfãs. Cada primitiva falhada é registada com `RAISE NOTICE` e a rotina continua.
1. **Geografia vs geometria**: comprimentos na vista/API usam cast para **geografia** sobre 4326 — adequado para ordens de grandeza operacional; estudos de perfil eléctrico finos podem exigir modelo projetado.
2. **Tolerância em graus**: redes muito extensas podem preferir uma topologia separada em **EPSG projectivo local** com `precision` em metros.
3. **Redes não planares**: múltiplos circuitos sobrepostos podem exigir modelação avançada (várias camadas ou grafos além deste MVP).
4. **Rollback**: remover a topologia destrói primitivas — usar `DROP SCHEMA tabgis_utilities_topo CASCADE` apenas em consciência (impacto total nos `TopoGeometry` dependentes).

---

## 6. Referências cruzadas

| Documento | Conteúdo relacionado |
|-----------|----------------------|
| `docs/mds/CONTEXT_STATE.md` | Estado da stack, lista de scripts SQL, rotas da API. |
| `docs/mds/Database_Structure_Context.md` | Modelo conceptual `gis` / utilities. |
| `docs/mds/DEPLOY.md` | Ordem de aplicação de migrações. |

---

## 7. Regionalização (traduções EN / PT / ES / IT)

Textos de interface e glossário técnico **sem ambiguidade coloquial** estão cadastrados em **`infra/sql/02_populate_translations.sql`** (tabela `config.translation`), com `ON CONFLICT DO UPDATE` para reaplicação segura:

| Chave | Uso |
|-------|-----|
| `UI_GLOSSARY_LINEAR_NETWORK_SEGMENT` | Definição de *segmento linear da rede* (SIG / utilities). |
| `UI_GLOSSARY_POSTGIS_TOPOLOGY` | Definição da extensão `postgis_topology`. |
| `UI_HELP_STACK_POSTGIS_TOPOLOGY` | Linha de ajuda: stack PostGIS + `gis.network_span`. |
| `UI_HELP_API_TOPOLOGY` | Linha de ajuda: endpoints `/api/topology/*`. |
| `UI_LAYER_GROUP_NETWORK` / `UI_LAYER_NETWORK_SPANS` / `UI_LAYER_NETWORK_SPANS_HINT` | Menu Camadas — grupo e toggle da rede. |
| `UI_NETWORK_SPAN_DRAW_*` | Botão, dicas, cancelamento e confirmação do desenho interactivo. |

Após alterar o ficheiro SQL, executar `psql` contra a base e **reiniciar** o contentor **`api`** para o cliente voltar a carregar o mapa de traduções.
