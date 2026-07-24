# TabGis — Documentação (home)

Índice central da documentação em Markdown. A **fonte canónica** de texto está em [`mds/`](./mds/). O espelho **HTML** com a mesma árvore de ficheiros (nome base idêntico, extensão `.html`) está em [`html/`](./html/). Os **PDF** homólogos (sempre gerados a partir dos MD) estão em [`pdfs/`](./pdfs/).

| Árvore | Conteúdo |
|--------|----------|
| [`mds/`](./mds/) | Todos os `.md` autoriais (única origem de verdade textual). |
| [`html/`](./html/) | Hub [`html/index.html`](./html/index.html) + `*.html` gerados por [Pandoc](https://pandoc.org/) a partir de `mds/*.md`. Diagrama HTML legado: [`html/Database_Structure_Context.diagram-legacy.html`](./html/Database_Structure_Context.diagram-legacy.html). |
| [`pdfs/`](./pdfs/) | `*.pdf` homólogos (Docker `pandoc/extra` ou LaTeX local). |

**Build (HTML + PDF + artefacto GitHub Pages):** [`../scripts/docs/build-pages-site.sh`](../scripts/docs/build-pages-site.sh) · [`.github/workflows/pages.yml`](../.github/workflows/pages.yml)

> **Nota de URL (GitHub Pages):** o artefacto `_site/` publica as páginas HTML na **raiz** do site (ex.: `/CONTEXT_STATE.html`). Ligações antigas do tipo `/docs/NOME.html` deixam de ser válidas após esta reorganização.

---

## Arranque rápido

| Documento | Conteúdo |
|-----------|----------|
| [CONTEXT_STATE.md](./mds/CONTEXT_STATE.md) | Estado da stack, portas, SQL, frontend, API — **fonte operacional** |
| [DEPLOY.md](./mds/DEPLOY.md) | Deploy Docker Compose, ordem de migrações |
| [Escopo_Projeto_TabGis.md](./mds/Escopo_Projeto_TabGis.md) | Visão de produto e roadmap |

---

## Arquitectura e dados

| Documento | Conteúdo |
|-----------|----------|
| [ARCHITECTURE_BPMN.md](./mds/ARCHITECTURE_BPMN.md) | Diagrama de colaboração (estilo BPMN) — módulos, GitHub, PostGIS, GeoServer, GeoSampa, Mongo (pendente), deploy |
| [EVENTS_ARCHITECTURE.md](./mds/EVENTS_ARCHITECTURE.md) | Schema `events`, API, exportação |
| [TOPOLOGY_NATIVE_POSTGIS.md](./mds/TOPOLOGY_NATIVE_POSTGIS.md) | Topologia PostGIS nativa, `gis.network_span`, API |
| [MILESTONES.md](./mds/MILESTONES.md) | Marcos M1–M6 (entregas, testes, docs) |
| [Database_Structure_Context.md](./mds/Database_Structure_Context.md) | Modelo de dados utilities (tabelas e FK) |

---

## Regionalização e mapas

| Documento | Conteúdo |
|-----------|----------|
| [REGIONALIZATION.md](./mds/REGIONALIZATION.md) | Tabela de idiomas, `config.translation`, chaves UI e glossário |
| [MAPS_AND_SOURCES.md](./mds/MAPS_AND_SOURCES.md) | Mapas offline (referência de dados), origens (IBGE, OSM, GeoSampa, satélite), actualização |

---

## Runbooks e pipelines

| Documento | Conteúdo |
|-----------|----------|
| [RUNBOOK_BASEMAP_SP_ESTADO.md](./mds/RUNBOOK_BASEMAP_SP_ESTADO.md) | Landbase SP estado (IBGE + OSM) |
| [RUNBOOK_BASEMAP_SP.md](./mds/RUNBOOK_BASEMAP_SP.md) | Landbase SP Centro (legado) |
| [GeoSampa_offline_operacao.md](./mds/GeoSampa_offline_operacao.md) | GeoSampa MBTiles — operação |
| [GeoSampa_offline_tecnico.md](./mds/GeoSampa_offline_tecnico.md) | GeoSampa MBTiles — técnico |

---

## Operação, CI e legado

| Documento | Conteúdo |
|-----------|----------|
| [AUTONOMY_RUNBOOK.md](./mds/AUTONOMY_RUNBOOK.md) | Scripts de autonomia |
| [AUTONOMOUS_EXECUTION_PLAN_10H.md](./mds/AUTONOMOUS_EXECUTION_PLAN_10H.md) | Plano de execução longa |
| [DEPLOY_POC.md](./mds/DEPLOY_POC.md) | Deploy POC / troubleshooting estendido |
| [Escopo_Projeto_GeoUtil.md](./mds/Escopo_Projeto_GeoUtil.md) | Escopo histórico académico |

---

## Artefactos gráficos

| Ficheiro | Conteúdo |
|----------|----------|
| [TabGis.drawio](./mds/TabGis.drawio) | Diagrama editável (draw.io) |

---

## Paridade MD / HTML / PDF

- **Markdown:** apenas em `docs/mds/`.
- **HTML:** `docs/html/` — mesmo conjunto de ficheiros-base que `mds/` (mais `index.html`, `assets/site.css`, legado do diagrama).
- **PDF:** `docs/pdfs/` — um PDF por cada `mds/*.md` (excepto se a geração falhar por falta de Docker/LaTeX).
- **Sem Pandoc no host:** o script usa Docker `pandoc/core:3.1` para HTML; PDF usa `pandoc/extra:3.1`.

## Atalhos na raiz de `docs/` (compatibilidade)

Algumas ferramentas e regras de IDE continuam a apontar para caminhos antigos. Mantêm-se **symlinks** na raiz de `docs/`:

| Atalho | Destino |
|--------|---------|
| [`CONTEXT_STATE.md`](./CONTEXT_STATE.md) | `mds/CONTEXT_STATE.md` |
| [`Escopo_Projeto_TabGis.md`](./Escopo_Projeto_TabGis.md) | `mds/Escopo_Projeto_TabGis.md` |
| [`Escopo_Projeto_GeoUtil.md`](./Escopo_Projeto_GeoUtil.md) | `mds/Escopo_Projeto_GeoUtil.md` |
