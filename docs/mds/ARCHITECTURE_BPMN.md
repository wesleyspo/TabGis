# Arquitectura TabGis — vista de colaboração (notação BPMN-like)

Este documento resume **módulos externos e internos** do TabGis numa vista próxima de **diagrama de colaboração BPMN** (pools e fluxos de mensagem). A sintaxe é [Mermaid](https://mermaid.js.org/) (renderiza em GitHub, VS Code e no HTML gerado a partir deste MD).

> **Nota:** não é ficheiro BPMN 2.0 XML; para editar em [bpmn.io](https://bpmn.io/) pode transpor manualmente os pools abaixo. O ficheiro [`TabGis.drawio`](./TabGis.drawio) continua disponível para diagramas genéricos.

---

## Diagrama — colaboração entre sistemas

```mermaid
flowchart TB
  subgraph GH["Pool: GitHub"]
    direction TB
    GH_REPO[("Repositório Git<br/>código + docs MD")]
    GH_ACT["GitHub Actions<br/>CI + Pages"]
    GH_PAGES["GitHub Pages<br/>site estático"]
  end

  subgraph OPS["Pool: Operação / homeserver"]
    direction TB
    DC["Docker Compose<br/>infra/docker-compose.yml"]
    NG["nginx :8088<br/>estáticos + proxy"]
    API["Node.js API :3000<br/>Express"]
    PG[("PostgreSQL / PostGIS<br/>:5433")]
    GS["GeoServer :8080<br/>WMS/WFS/SLD"]
    TS["TileServer GL :8081<br/>MBTiles raster"]
    MG[("MongoDB :27017<br/><b>PENDENTE</b><br/>recepção event_report / réplica")]
  end

  subgraph EXT["Pool: Origens externas (online)"]
    OSM["OpenStreetMap<br/>Nominatim / dados vias"]
    IBGE["IBGE<br/>administrativo"]
    GSP["GeoSampa / PMSP<br/>WMS ortofoto"]
    ESRI["Esri World Imagery<br/>tiles XYZ"]
    OWM["Open-Meteo / RainViewer<br/>TMP"]
  end

  IDE["Cursor / IDE<br/>Remote SSH"]

  IDE -->|git push| GH_REPO
  GH_REPO --> GH_ACT
  GH_ACT -->|npm test| GH_REPO
  GH_ACT -->|deploy estático| GH_PAGES

  IDE -->|HTTP browser| NG
  DC --> NG
  DC --> API
  DC --> PG
  DC --> GS
  DC --> TS
  DC --> MG
  NG -->|/api| API
  NG -->|/geoserver| GS
  NG -->|/tiles| TS

  API -->|SQL| PG
  GS -->|SQL| PG

  API -.->|"futuro: sink eventos"| MG

  IBGE -->|import scripts| PG
  OSM -->|import scripts| PG
  GSP -->|build MBTiles / WMS| TS

  API -->|geocode online| OSM
  NG -->|tiles raster cliente| ESRI
  API -->|previsão TMP| OWM
```

**Legenda:** setas sólidas = fluxo actual típico; tracejado = **planeado** (recepção de eventos no Mongo sem perder Postgres como fonte de verdade).

---

## Tabela — módulos e papel

| Módulo | Papel no TabGis |
|--------|-----------------|
| **GitHub** | Versionamento; **Actions** (CI `npm test`, **Pages** para site estático). |
| **PostgreSQL / PostGIS** | Dados operacionais, landbase, `events`, topologia `tabgis_utilities_topo`, `config.translation`. |
| **GeoServer** | Serviço de mapas vectoriais (WMS/WFS), estilos SLD. |
| **GeoSampa** | Fonte de ortofoto / dados municipais; pipeline offline documentado. |
| **TileServer GL** | Servir MBTiles (satélite local, GeoSampa offline). |
| **nginx** | Frontend, proxy same-origin para API, GeoServer e tiles. |
| **Node.js / API** | REST, i18n, OMS, eventos, topologia, esquemático. |
| **MongoDB** | **Pendente** como destino de **recepção** de cópias de eventos / `event_report` (Postgres mantém-se canónico). |
| **Regionalização** | Tabela `config.translation` + `02_populate_translations.sql` (EN, PT, ES, IT). |

---

## Linguagens utilizadas

| Linguagem / formato | Onde |
|---------------------|------|
| **JavaScript** (Node + browser) | `backend/`, `frontend/main.js` |
| **HTML / CSS** | `frontend/index.html`, `help.html`, `styles.css` |
| **SQL** | `infra/sql/*.sql` |
| **Shell** | `infra/scripts/`, `scripts/` |
| **Python** | Scripts de tiles / reparação (`infra/scripts/*.py`) |
| **YAML** | `docker-compose`, GitHub Actions |
| **TypeScript** | `e2e/` (Playwright) |

---

## Deploy

| Camada | Documentação |
|--------|----------------|
| Docker Compose (homeserver) | [DEPLOY.md](./DEPLOY.md), [CONTEXT_STATE.md](./CONTEXT_STATE.md) |
| GitHub Pages | [.github/workflows/pages.yml](../.github/workflows/pages.yml) |

---

## Mapas offline — baseline de referência

| Pacote | Referência detalhada |
|--------|----------------------|
| Satélite SP (MBTiles) | [CONTEXT_STATE.md](./CONTEXT_STATE.md) (secção MBTiles) e [MAPS_AND_SOURCES.md](./MAPS_AND_SOURCES.md) |
| GeoSampa | [GeoSampa_offline_operacao.md](./GeoSampa_offline_operacao.md) |

Data de **snapshot** sugerida para relatórios: ver campo no topo de [MAPS_AND_SOURCES.md](./MAPS_AND_SOURCES.md).
