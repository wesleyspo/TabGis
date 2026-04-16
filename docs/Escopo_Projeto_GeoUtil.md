# Escopo do Projecto: TabGis — Gestão e Visualização de Redes de Utilities

> **Nome da solução:** TabGis
> **Contexto académico:** Projecto de doutoramento em Geoprocessamento com IA (GeoUtil)
> **Estado operacional detalhado:** `docs/CONTEXT_STATE.md`
> **Código-fonte (Git):** `https://github.com/wesleyspo/TabGis.git` — marco V0 assinalado pela *tag* **`v0.1.0`** (ver também `VERSION` na raiz).

---

## 1. Objectivos do Sistema

Desenvolver uma plataforma Web para gestão de activos de **utilities** (redes técnicas genéricas: energia, telecomunicações, águas, gás, etc.) com foco em:

- **Versionamento bi-temporal** — diferenciação entre instâncias reais e históricas
- **Topologia de rede** — modelação e validação de conectividade em PostGIS
- **Ligação esquemático ↔ mapa** — cada elemento do esquemático tem metadado obrigatório **"Ir para o Mapa"**

---

## 2. Arquitectura de Software e Dados

| Componente | Tecnologia | Função |
|------------|-----------|--------|
| Base de dados espacial | PostgreSQL 15 + PostGIS 3.3 | **landbase**, **config**, **security**, **audit**, **operations** (equipas, ordens, deslocamentos, rotas; ver `infra/sql/03_operations_schema.sql`) |
| Servidor de mapas | GeoServer (oscarfonts) | Publicação WMS/WFS a partir do PostGIS (`landbase`) |
| Servidor de tiles raster | TileServer GL (maptiler) | MBTiles satélite offline |
| Proxy / frontend | nginx:alpine | Serve `frontend/`, proxy `/geoserver`, `/tiles` e `/api` |
| API de configuração / i18n | Node.js (Express) em `backend/` | `GET /api/translations/:lang` → `config.translation` no PostGIS |
| Logs / eventos | MongoDB | `event_report`, histórico de BOTs (uso futuro) |
| Orquestração | Docker Compose (`infra/docker-compose.yml`) | Stack local reprodutível |

> A IA (Ollama) para consulta em linguagem natural está prevista numa fase posterior à estabilização dos dados.

---

## 3. Requisitos Funcionais

### 3.1 Mapa geográfico
- Basemap offline: limites IBGE (UF + municípios) + vias OSM, publicados via GeoServer WMS
- Recorte **municípios-alvo** (24), **bairros-alvo**, **vias-alvo** com estilos SLD versionados (`infra/geoserver/styles/`)
- Satélite offline: MBTiles raster (capital SP, zoom 10–17) servidos por TileServer GL
- Satélite online: tiles XYZ Esri (requer Internet)
- **Busca** (não «filtro» de painel tabular): município e bairro via WFS (GeoServer)
- Identificação de feições ao clique (GetFeatureInfo WMS)
- Vista inicial calibrada por **inset** (tela cheia vs. mapa com painel 50%); botão Inicial reproduz a mesma lógica do primeiro carregamento

### 3.2 Esquemático (fase futura)
- Vista lógica/sequencial da rede
- Cada elemento deve permitir navegação para a posição geográfica correspondente no mapa

### 3.3 Versionamento bi-temporal (fase futura)
- Separação entre estado real (actual) e estados históricos
- Persistência em PostGIS com campos de validade temporal

### 3.4 IA / Consulta em linguagem natural (fase futura)
- Interface Ollama sobre os dados da rede para suporte à decisão operacional

---

## 4. Incremento actual: Basemap offline (POC operacional)

### 4.1 Componentes entregues

| Componente | Estado | Detalhe |
|------------|--------|---------|
| Limites IBGE (UF + municípios SP) | ✅ Operacional | `landbase.uf_sp`, `landbase.municipios_sp` → GeoServer |
| Vias OSM (estado SP) | ✅ Operacional | `landbase.vias_sp` com estilos por zoom |
| Municípios-alvo (24 RMSP) | ✅ Operacional | `landbase.municipios_alvo_sp` → GeoServer |
| Bairros municípios-alvo | ✅ Operacional | `landbase.bairros_alvo_sp` → GeoServer |
| Vias municípios-alvo | ✅ Operacional | `landbase.vias_alvo_sp` → GeoServer |
| Satélite online (Esri XYZ) | ✅ Operacional | Requer Internet |
| Satélite offline MBTiles | ✅ Operacional | Zoom 10–17 (~3 GB), capital SP |
| Frontend web | ✅ Operacional | `http://homeserver:8088/` |

### 4.2 Recorte operacional prioritário

24 municípios-alvo (capital e entorno metropolitano ampliado) — ver lista completa em `docs/CONTEXT_STATE.md`.

Scripts: `infra/scripts/setup_municipios_alvo_sp.sh`

### 4.3 Interface de visualização (frontend)

Princípios de UX estabelecidos:

- **Design-system dark:** topbar e painel esquerdo (split-screen 50/50) `#0f172a`, tokens CSS centralizados, tipografia Inter
- **Topbar única (60px):** esquerda TabGis + Início + Operação; centro camada de títulos **Mapa** (tela cheia) ou **Centro de Controle | Mapa** (vista dividida); direita Busca, Camadas, estado (`#status`), configurações
- **Operação:** guias OMS → MWM → DMS → IND → SMT → TMP → AUD; primeira guia OMS; cabeçalho compacto (guias + fechar); mocks alinhados a `operations.*`
- **Controlos:** toggles CSS, `<details>` para Busca/Camadas, checkboxes e *pills* por camada
- **Modal de Traduções:** idioma EN/PT/ES/IT + grelha de chaves (espelho parcial de `config.translation`)
- **i18n:** `data-i18n` + API; ver `infra/sql/02_populate_translations.sql` e `docs/CONTEXT_STATE.md`
- **Feedback padronizado:** mensagens de erro no padrão `"Falha em [X]. [Remediação] (ver docs/DEPLOY_POC.md)."` na barra de estado da topbar
- **Código:** blocos principais comentados em `main.js`

### 4.4 Centro de controlo operacional (POC)

| Aspecto | Detalhe |
|---------|---------|
| **Persistência** | Schema `operations`: `team`, `work_order`, `team_order_displacement`, `team_route` |
| **Auditoria** | `audit.operations_row_archive` + triggers `BEFORE DELETE` — JSON da linha antes de eliminar |
| **UI** | Mocks até existir API; política: sem `DELETE` em `operations` sem arquivo |

### 4.5 Documentação operacional

| Documento | Conteúdo |
|-----------|---------|
| `docs/CONTEXT_STATE.md` | Stack, frontend detalhado, SQL, SLD, zoom, i18n |
| `docs/DEPLOY_POC.md` | Deploy, ordem SQL, estilos GeoServer |
| `docs/RUNBOOK_BASEMAP_SP_ESTADO.md` | Pipeline landbase SP estado |
| `docs/RUNBOOK_BASEMAP_SP.md` | Pipeline SP Centro (legado) |
| `frontend/README.md` | Cliente web |

---

## 5. Princípios de governança

- **Open source:** apenas ferramentas e dados de licença aberta no pipeline
- **Desacoplamento:** landbase e rede de utilities são independentes — trocar área geográfica não exige reescrita do modelo de rede
- **Rastreabilidade de erros:** qualquer falha visível ao utilizador inclui instrução de remediação e referência ao runbook, tanto no frontend como nos scripts shell
- **Credenciais:** valores de POC definidos no `infra/docker-compose.yml`; rever antes de qualquer exposição pública

---

## 6. Próximos passos (roadmap)

| # | Tarefa | Prioridade |
|---|--------|-----------|
| 1 | Upgrade satélite MBTiles ZMAX=17 (1,2 m/px, ~3,5 h geração) | ✅ Concluído |
| 2 | Interface split-screen + topbar com títulos Mapa / Centro de Controle + Busca | ✅ Concluído (POC) |
| 3 | Schema `operations` + arquivo obrigatório pré-DELETE | ✅ Concluído (SQL); API pendente |
| 4 | Modelagem da topologia de rede em PostGIS (schema dedicado) | Alta |
| 5 | APIs REST para `operations`, rotas 48h, edição e logs MongoDB | Média |
| 6 | Vista esquemática com ligação "Ir para o Mapa" | Média |
| 7 | Integração IA (Ollama) para consulta sobre a rede | Baixa (fase posterior) |
| 8 | Endurecimento de segurança (TLS, credenciais, reverse proxy público) | Fora do âmbito POC |
