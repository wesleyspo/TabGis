# Escopo do Projeto: TabGis

## Visao
TabGis e uma plataforma web para gestao operacional de redes de utilities com integracao entre mapa geografico, operacao de campo, auditoria e configuracoes de dominio.

## Objetivos centrais
- Operar rede tecnica com contexto geografico e operacional unificado.
- Garantir rastreabilidade (auditoria) de alteracoes criticas.
- Manter arquitetura aberta, modular e preparada para escalabilidade.
- Suportar evolucao de modulos OMS, MWM, DMS, IND, SMT, ESQ (esquemático), TMP e AUD.
- Entregar vista esquematica com metadado obrigatorio "Ir para o Mapa".

## Arquitetura de referencia
- Frontend web servido por nginx.
- API Node.js/Express.
- PostgreSQL/PostGIS para dados geoespaciais e operacionais.
- Schema PostgreSQL **`events`** para trilhas de eventos (exportáveis a Mongo/externo; ver `docs/mds/EVENTS_ARCHITECTURE.md`).
- GeoServer para WMS/WFS.
- TileServer GL para raster MBTiles.

## Requisitos de produto
- Layout responsivo com modos de tela definidos (full, split e foco no centro de controle).
- Operacao modular por abas: OMS, MWM, DMS, IND, SMT, ESQ, TMP e AUD.
- Gestao de configuracoes por dominio: idioma, visualizacao, utilizadores, tipos `ref.*`, traducoes e ajuda.
- Trilhas de auditoria com politica de arquivo pre-delete no dominio operacional.

## Prioridades de evolucao
1. **Fase 2 — quatro pilares:** logística (MWM/rotas/deslocamentos), detalhes das entidades (fichas canónicas), dinamismo (`config`, `events`, integrações), auditoria (arquivo pré-delete + trilha exportável).
2. Normalização técnica: Git/docs/schemas/UI placeholders (ver `CONTEXT_STATE.md` § Dívida técnica).
3. Topologia de rede: edição de vértices existentes, CRS projectado onde necessário (`TOPOLOGY_NATIVE_POSTGIS.md`).
4. Endurecimento de segurança e readiness de producao (M6).

## Fonte de estado
Estado operacional detalhado: `docs/mds/CONTEXT_STATE.md`.
Marcos entregues: `docs/mds/MILESTONES.md`.
