# Frontend TabGis (landbase `base_sp`)

Cliente web **HTML + CSS + JavaScript** com **Leaflet** (CDN) para WMS/WFS, **GetFeatureInfo**, satélite online/offline e painel **Operação**. O mapa consome o workspace GeoServer `base_sp` e textos dinâmicos via **`GET /api/translations/:lang`** (tabela `config.translation`).

## Modo recomendado (mesma origem, sem CORS)

Com a stack Docker, o **nginx** (`web` em `infra/docker-compose.yml`) expõe:

- Mapa e estáticos: `http://<host>:8088/`
- GeoServer (proxy): `http://<host>:8088/geoserver/`
- TileServer: `http://<host>:8088/tiles/`
- API traduções: `http://<host>:8088/api/translations/<lang>`

Na raiz do repositório:

```bash
docker compose -f infra/docker-compose.yml up -d
```

Abrir `http://127.0.0.1:8088/` (ou o IP do homeserver na LAN).

Em [main.js](main.js), `GEOSERVER_BASE = window.location.origin + '/geoserver'` — WFS e GetFeatureInfo funcionam sem CORS.

Garantir que os scripts SQL `01` → `03` foram aplicados na PostGIS e que `02` foi seguido de `restart api` se as traduções mudaram (ver [docs/mds/DEPLOY.md](../docs/mds/DEPLOY.md) e [docs/mds/DEPLOY_POC.md](../docs/mds/DEPLOY_POC.md) para detalhe legado).

## Modo desenvolvimento (servidor estático)

```bash
cd frontend
python3 -m http.server 5173 --bind 0.0.0.0
```

Abrir `http://<host>:5173`. O script aponta WMS frequentemente para `:8080/geoserver`; **WFS, GetFeatureInfo e `/api`** podem falhar por CORS ou origem diferente. Use **:8088** para validar funcionalidade completa.

## Topbar e layout

- **Uma barra superior (~60px):** esquerda marca + **Início** + **Operação**; centro títulos **Mapa** (tela cheia) ou **Centro de Controle | Mapa** (split); direita atalho **clima** (TMP), **Busca**, **Camadas**, estado, engrenagem (**Configurações**: idioma, visualização, utilizadores/grupos/privilégios, tipos `ref.*`, traduções, ajuda).
- **Operação:** abre split 50/50 (`aside#left-panel` + mapa). Guias por defeito: **OMS** → **MWM** → **DMS** → **IND** → **SMT** → **ESQ** (esquemático via `/api/schematic/*`) → **TMP** → **AUD**; OMS e ESQ consomem REST real; outras guias podem estar em mock.
- **Busca** (rótulo `UI_MENU_SEARCH`): municípios-alvo e bairros via WFS — não confundir com *filtro* tabular futuro.

## Mapa — vista inicial e zoom

- **Insets:** `HOME_INSET_FULL` = `0.9 × 1.04` (tela cheia); `HOME_INSET_SPLIT` = `HOME_INSET_FULL / 1.08` (com painel aberto). Bboxes em [main.js](main.js) (`fitBoundsHomeInset`, `setHomeView`).
- **Arranque:** `map.whenReady` + `requestAnimationFrame` + `runInitialMapLayout()`; *fallback* `setTimeout(..., 400)` e flag `mapInitialStatusDone` para o layout flex estável.
- **Bairros vs municípios-alvo:** a partir de zoom **≥ 12**, com checkbox **Bairros** activa, mostram-se bairros e retiram-se municípios-alvo da vista; abaixo de 12, comportamento regional padrão. Ver [docs/mds/CONTEXT_STATE.md](../docs/mds/CONTEXT_STATE.md).

## Funcionalidades principais

- Lista de municípios-alvo (WFS `base_sp:municipios_alvo_sp`) + zoom.
- Bairro: município + texto ≥ 2 caracteres + escolha na lista (WFS + `CQL_FILTER`).
- Clique: popup GetFeatureInfo nas camadas visíveis.
- **Satélite online:** tiles Esri (requer Internet); opacidade ajustada para ver limites.
- **Satélite local:** MBTiles via `/tiles/...`; toggle verifica `sp_sat.json` antes de activar.
- **Esquemático (guia ESQ):** lista de vistas, renderização em escada (SVG), P/Q nas arestas; **Ir para o mapa** com foco do nó ou geometria de equipamento POC (`17_schematic_link_poc_equipment.sql`). Com `SECURITY_ENFORCE=1` na API, necessário privilégio `module.esq`.
- **Topologia nativa (REST):** `GET /api/topology/meta` e `GET /api/topology/spans` — segmentos lineares `gis.network_span` / schema `tabgis_utilities_topo` (`docs/mds/TOPOLOGY_NATIVE_POSTGIS.md`); com enforcement, privilégio `module.oms`. Chaves de glossário: `UI_GLOSSARY_*`, `UI_HELP_*` em `infra/sql/02_populate_translations.sql`.
- **Vias:** SLD `base_sp_vias_zoom_scales` + `landbase.via_zoom_config` (ver script `apply_via_zoom_config_and_style.sh`).

## Camadas usadas

- Estado: `base_sp:uf_sp`, `base_sp:municipios_sp`, `base_sp:vias_sp`
- Recorte alvo: `base_sp:municipios_alvo_sp`, `base_sp:bairros_alvo_sp`, `base_sp:vias_alvo_sp`

## Internacionalização (i18n)

- Atributos `data-i18n` no HTML; [main.js](main.js) carrega o mapa de chaves da API e aplica ao DOM.
- Chaves novas ou alteradas: editar [infra/sql/02_populate_translations.sql](../infra/sql/02_populate_translations.sql), reaplicar na BD, reiniciar `api`. Lista e convenções: [docs/mds/CONTEXT_STATE.md](../docs/mds/CONTEXT_STATE.md).

## Mensagens de erro

Padrão: `Falha em [recurso]. [Remediação] (ver docs/mds/DEPLOY.md).` — texto no elemento `#status` da topbar.

## Offline total (Leaflet)

Sem Internet, copiar Leaflet para `frontend/vendor/` e alterar [index.html](index.html) para apontar para ficheiros locais em vez do CDN.

## Documentação relacionada

| Ficheiro | Conteúdo |
|----------|----------|
| [docs/mds/DEPLOY.md](../docs/mds/DEPLOY.md) | Deploy principal, same-origin, diagnóstico rápido |
| [docs/mds/DEPLOY_POC.md](../docs/mds/DEPLOY_POC.md) | Legado: Compose alargado, ordem SQL, SLD |
| [docs/mds/CONTEXT_STATE.md](../docs/mds/CONTEXT_STATE.md) | Stack, frontend detalhado, SLD alvo, i18n |
| [docs/mds/Escopo_Projeto_TabGis.md](../docs/mds/Escopo_Projeto_TabGis.md) | Escopo de produto e roadmap |
| [docs/mds/Escopo_Projeto_GeoUtil.md](../docs/mds/Escopo_Projeto_GeoUtil.md) | Referência histórica |
| [docs/mds/RUNBOOK_BASEMAP_SP_ESTADO.md](../docs/mds/RUNBOOK_BASEMAP_SP_ESTADO.md) | Pipeline landbase SP estado |
