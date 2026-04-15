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
| Base de dados espacial | PostgreSQL 15 + PostGIS 3.3 | **landbase** (áreas geográficas, topologia), **config** (parâmetros, tradução), **security** (acessos), **audit** (logs) |
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
- Satélite offline: MBTiles raster (capital SP, zoom 10–17) servidos por TileServer GL
- Satélite online: tiles XYZ Esri (requer Internet)
- Busca por município e bairro via WFS (GeoServer)
- Identificação de feições ao clique (GetFeatureInfo WMS)

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
- **Controlos sem dependências:** toggle switches CSS puro, `<details>` HTML nativo em dropdown, checkboxes com múltipla seleção
- **Modal de Traduções (Configurações):** UI de engrenagem para seleção de idioma (EN, PT, ES, IT) e tela tabular para gerir traduções e parâmetros globais do sistema
- **Feedback padronizado:** mensagens de erro no padrão `"Falha em [X]. [Remediação] (ver docs/DEPLOY_POC.md)."` visíveis no rodapé da sidebar sem abrir consola
- **Código comentado:** todos os blocos funcionais de `main.js` têm comentários JSDoc

### 4.4 Documentação operacional

| Documento | Conteúdo |
|-----------|---------|
| `docs/CONTEXT_STATE.md` | Estado actual da stack, portas, credenciais, acesso remoto |
| `docs/DEPLOY_POC.md` | Procedimento completo de deploy e manutenção |
| `docs/RUNBOOK_BASEMAP_SP_ESTADO.md` | Pipeline de dados SP estado (referência principal) |
| `docs/RUNBOOK_BASEMAP_SP.md` | Pipeline SP Centro (legado / ensaios) |

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
| 2 | Interface split-screen (50% mapa, 50% painel de operação) | ✅ Concluído |
| 3 | Modelagem da topologia de rede em PostGIS (schema dedicado) | Alta |
| 4 | APIs REST (backend Node/Python) para edição e logs MongoDB | Média |
| 5 | Vista esquemática com ligação "Ir para o Mapa" | Média |
| 6 | Integração IA (Ollama) para consulta sobre a rede | Baixa (fase posterior) |
| 7 | Endurecimento de segurança (TLS, credenciais, reverse proxy público) | Fora do âmbito POC |
