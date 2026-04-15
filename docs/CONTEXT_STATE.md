# PROJECT CONTEXT STATE — TabGis (Para uso com IA)

> **Leitura obrigatória antes de qualquer sessão de desenvolvimento.**
> Este ficheiro é a fonte de verdade do estado operacional da POC.
> Actualize-o sempre que um componente mudar de estado.

---

## Ambiente de execução

| Componente | Detalhe |
|------------|---------|
| **Servidor de execução** | `homeserver` — Linux (Ubuntu), acesso via SSH |
| **Desenvolvimento** | Cursor IDE com extensão **Remote SSH** (qualquer notebook → `ssh homeserver`) |
| **Repositório** | `/home/wesley/projects/TabGis` no homeserver |
| **Orquestração** | Docker Compose em `infra/docker-compose.yml` |

> **Atenção:** Existe também um `docker-compose.yml` na raiz do repositório (composição experimental com pgRouting/kartoza). **Não** é o alvo dos runbooks actuais — usar sempre `infra/docker-compose.yml`.

---

## Versionamento e código-fonte

| Artefacto | Local / URL |
|-----------|-------------|
| **Repositório Git (remoto)** | `https://github.com/wesleyspo/TabGis.git` |
| **Cópia de trabalho (homeserver)** | `/home/wesley/projects/TabGis` |
| **Release V0 (POC completo)** | **v0.1.0** — *tag* anotada Git |
| **Ficheiro de versão** | `VERSION` na raiz (ex.: `0.1.0`) |

O código da aplicação (frontend, `infra/`, `backend/`, SQL, documentação) está versionado neste repositório Git. A linha temporal oficial é o histórico de *commits* em `main`; marcos estáveis assinalam-se com *tags* `vMAJOR.MINOR.PATCH` (SemVer). Dados pesados e artefactos gerados localmente **não** entram no Git — ver `.gitignore` (`data/raw/`, `*.mbtiles`, `*.mbtiles.tmp`, etc.).

Comandos úteis no homeserver:

```bash
git describe --tags --always     # tag actual ou commit abreviado
git tag -l 'v*'                  # listar releases
git show v0.1.0 --no-patch       # nota da tag V0
```

Para publicar alterações no remoto (após `git commit`):

```bash
git push origin main
git push origin v0.1.0           # ou: git push origin --tags
```

---

## Stack Docker — estado actual (todos healthy)

| Container | Imagem | Porta host | Função |
|-----------|--------|-----------|--------|
| `infra-db-1` | `postgis/postgis:15-3.3` | **5432** | PostgreSQL + PostGIS |
| `infra-geoserver-1` | `oscarfonts/geoserver:latest` | **8080** | WMS / WFS / SLD |
| `infra-tileserver-1` | `maptiler/tileserver-gl:latest` | **8081** | MBTiles raster (satélite local) |
| `infra-web-1` | `nginx:alpine` | **8088** | Frontend + proxy `/geoserver`, `/tiles`, `/api` |
| `infra-api-1` | build `backend/` (Node) | **3000** | API REST — traduções `GET /api/translations/:lang` (acesso directo; em uso normal via `:8088/api/`) |
| `infra-mongodb-1` | `mongo:latest` | **27017** | Logs / event_report (uso futuro) |

### Portas de acesso (de outro notebook na mesma rede ou via SSH tunnel)

| Serviço | URL directa | Observação |
|---------|-------------|------------|
| **Frontend (recomendado)** | `http://homeserver:8088/` | nginx — same-origin para WMS, WFS, tiles e `/api` |
| GeoServer UI | `http://homeserver:8080/geoserver/web` | Admin directo |
| TileServer | `http://homeserver:8081/` | Acesso directo (diagnóstico) |
| PostGIS | `homeserver:5432` | Só admin / psql |
| MongoDB | `homeserver:27017` | Só admin |

### Credenciais POC (trocar em produção)

| Serviço | Utilizador | Password |
|---------|-----------|---------|
| PostGIS | `tabgis_admin` | ver `infra/docker-compose.yml` |
| GeoServer | `admin` | `geoserver` (imagem padrão) |

---

## Dados e schemas

O banco de dados foi estruturado em quatro *schemas* fundamentais para sustentar o comportamento da aplicação em ambiente agnóstico de idioma e localidade:

1. **`landbase`**: Contém todos os dados geográficos e topológicos puros do basemap e da rede (antigo `basemap`). Todas as camadas do GeoServer apontam para cá.
2. **`config`**: Estruturas de parametrização dinâmica (`config.parameter`), traduções globais (`config.translation`) e idiomas suportados (`config.language`: EN, PT, ES, IT).
3. **`security`**: Controle de acessos de usuário, autenticação e roles de visualização (`ADMIN`, `CONSULTA`, `OPERACAO`).
4. **`audit`**: Histórico detalhado gerado por Triggers no PostGIS, gravando alterações em parâmetros (`audit.parameter_history`) e sessões de usuário (`audit.login_history`).

| Artefacto | Origem | Tabelas PostGIS | Camadas GeoServer |
|-----------|--------|-----------------|-------------------|
| **SP estado** (activo) | IBGE UF + municípios; OSM PBF | `landbase.uf_sp`, `landbase.municipios_sp`, `landbase.vias_sp` | `base_sp:uf_sp`, `base_sp:municipios_sp`, `base_sp:vias_sp` |
| **SP Centro** (legado) | IBGE municípios; OSM Overpass | `landbase.municipio_sp`, `landbase.aoi_centro_sp`, `landbase.vias_centro_sp` | camadas homólogas |

- **SRID administrativo (IBGE):** EPSG:4674 (SIRGAS 2000)
- **OSM (`osm2pgsql`):** EPSG:3857 na coluna `way`; `landbase.vias_sp` usa `ST_Transform(way, 4674)`
- **Vias por zoom:** tabela `landbase.via_zoom_config` + SLD `base_sp_vias_zoom_scales` — script de aplicação: `infra/scripts/apply_via_zoom_config_and_style.sh`

---

## Recorte prioritário — municípios-alvo (RMSP ampliada)

24 municípios: São Paulo (capital), Barueri, Cajamar, Carapicuíba, Cotia, Diadema, Embu-Guaçu, Embu das Artes, Itapecerica da Serra, Itapevi, Jandira, Juquitiba, Mauá, Osasco, Pirapora do Bom Jesus, Ribeirão Pires, Rio Grande da Serra, Santana de Parnaíba, Santo André, São Bernardo do Campo, São Caetano do Sul, São Lourenço da Serra, Taboão da Serra, Vargem Grande Paulista.

| Entregável | Tabela PostGIS | Camada GeoServer |
|------------|---------------|-----------------|
| Municípios-alvo destacados | `landbase.municipios_alvo_sp` | `base_sp:municipios_alvo_sp` |
| Bairros dos municípios-alvo | `landbase.bairros_alvo_sp` | `base_sp:bairros_alvo_sp` |
| Vias públicas dos municípios-alvo | `landbase.vias_alvo_sp` | `base_sp:vias_alvo_sp` |

Script de geração: `infra/scripts/setup_municipios_alvo_sp.sh`

---

## Scripts versionados

| Script | Função | Runbook |
|--------|--------|---------|
| `infra/scripts/setup_landbase_sp_estado.sh` | Importa IBGE + OSM → PostGIS + GeoServer (SP estado) | `docs/RUNBOOK_BASEMAP_SP_ESTADO.md` |
| `infra/scripts/setup_landbase_sp.sh` | Basemap São Paulo Centro (legado) | `docs/RUNBOOK_BASEMAP_SP.md` |
| `infra/scripts/setup_municipios_alvo_sp.sh` | Municípios-alvo + bairros + vias | — |
| `infra/scripts/apply_via_zoom_config_and_style.sh` | Aplica SLD de vias por zoom | — |
| `infra/scripts/build_sp_satellite_mbtiles.sh` | Gera MBTiles raster (satélite offline) | ver secção abaixo |

Estilos SLD versionados: `infra/geoserver/styles/*.sld`

---

## MBTiles — satélite raster local

### Estado actual do pacote

| Campo | Valor |
|-------|-------|
| Ficheiro | `data/tiles/sp_satellite.mbtiles` |
| Tiles | **175 306** |
| Zoom | **10–17** |
| Bounds | `-47.2, -24.1, -46.2, -23.2` (capital SP) |
| Tamanho | **~3 GB** |
| Resolução | **1,2 m/px** (zoom 17) |

### Escala por ZMAX (bbox capital SP)

| ZMAX | Tiles | Tempo est. | Disco est. | Resolução |
|------|-------|------------|------------|-----------|
| 14 | 2 959 | ~4 min | ~50 MB | 9 m/px |
| 15 | 11 331 | ~25 min | ~200 MB | 5 m/px |
| 16 | 44 271 | ~1h15 | ~763 MB | 2,4 m/px |
| **17** | **175 306** | **~3,5 h** | **~3 GB** | **1,2 m/px** ← instalado |
| 18 | 697 270 | ~14 h | ~12 GB | 0,6 m/px (impraticável POC) |

### Procedimento de upgrade (aprovado: ZMAX=17)

```bash
# Gerar novo pacote (escreve em .tmp, substituição atómica no fim)
ZMAX=17 ./infra/scripts/build_sp_satellite_mbtiles.sh

# Após conclusão, reiniciar tileserver E web (nginx re-resolve DNS Docker)
docker compose -f infra/docker-compose.yml restart tileserver web
```

> **Nota Docker DNS:** o container `web` (nginx) resolve o hostname `tileserver` na rede interna Docker apenas no arranque. Se o `tileserver` for criado ou recriado depois do `web`, o nginx serve `index.html` para todos os pedidos `/tiles/*`. O restart conjunto resolve isso.

### Comportamento da camada no frontend

- O toggle **Satélite local** faz fetch a `/tiles/data/sp_sat.json` antes de activar a camada.
- Se o TileServer responder → activa, mostra mensagem de satélite local activo (capital SP, zoom nativo 10–17).
- Se falhar → desactiva toggle, mostra mensagem com instrução de remediação.
- 404s de tiles fora da bbox são silenciados (cobertura parcial é comportamento normal).
- `minNativeZoom: 10` / `maxNativeZoom: 17` em `main.js` — Leaflet faz upscale acima e abaixo do intervalo.

---

## Frontend

| Ficheiro | Função |
|---------|--------|
| `frontend/index.html` | Markup — topbar horizontal, painel esquerdo "Operação" (split screen 50/50), secções `<details>` dropdown, checkboxes, ícones SVG |
| `frontend/styles.css` | Design-system — layout flex dinâmico, tokens CSS (`--bg-*`, `--accent`, `--radius-*`), Inter font |
| `frontend/main.js` | Lógica Leaflet — WMS, MBTiles, WFS, GetFeatureInfo; i18n via `fetch` a `/api/translations/:lang` e atributos `data-i18n` |
| `backend/server.js` | API Express — lê `config.translation` + `config.language` no PostGIS |

- **Tipografia:** Inter (Google Fonts CDN) — requer Internet para carregar a fonte; fallback `system-ui`
- **Modo recomendado (`:8088`):** `main.js` resolve GeoServer como `window.location.origin + '/geoserver'` (same-origin, sem CORS)
- **Modo dev (`:5173`):** usa `http://homeserver:8080/geoserver`; WFS e GetFeatureInfo podem falhar por CORS

### Convenção de mensagens de erro

Todas as falhas em `main.js` seguem:

```
"Falha em [recurso]. [Instrução de remediação] (ver docs/[RUNBOOK].md)."
```

| Ponto de falha | Mensagem |
|----------------|---------|
| Tiles WMS | `Falha ao carregar tiles WMS. Verifique GeoServer em <URL> (ver docs/DEPLOY_POC.md).` |
| Tiles MBTiles | `Falha tiles MBTiles. Gere sp_satellite.mbtiles e suba tileserver (ver docs/DEPLOY_POC.md).` |
| WFS municípios | `Falha ao carregar municípios (WFS). Prefira http://HOST:8088 e verifique GeoServer (ver docs/DEPLOY_POC.md).` |
| Busca de bairros | `Falha na busca de bairros. Verifique GeoServer em <URL> (ver docs/DEPLOY_POC.md).` |
| GetFeatureInfo | `Falha ao consultar feição. Verifique GeoServer em <URL> (ver docs/DEPLOY_POC.md).` |

---

## Acesso remoto — outro notebook via Cursor SSH

Para continuar o desenvolvimento neste repositório a partir de outro notebook:

1. **Configurar SSH no notebook cliente** (`~/.ssh/config`):
   ```
   Host homeserver
       HostName <IP-do-homeserver>
       User wesley
       IdentityFile ~/.ssh/id_rsa   # ou a chave que já usa
   ```

2. **Abrir no Cursor:** `File → Connect to Remote → homeserver` (extensão Remote SSH)

3. **Abrir pasta:** `/home/wesley/projects/TabGis`

4. **Aceder ao frontend:** `http://homeserver:8088/` (ou `http://<IP>:8088/` se não tiver DNS local)

5. **Verificar stack antes de trabalhar:**
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}"
   # Todos devem aparecer como "Up ... (healthy)" ou "Up ..."
   # Se algum estiver ausente:
   docker compose -f infra/docker-compose.yml up -d
   ```

> **Cursor Rules:** o ficheiro `.cursorrules` na raiz do repositório é lido automaticamente pelo Cursor em cada sessão — contém as regras de contexto e comportamento da IA para este projecto.

---

## Definições técnicas (TabGis)

- O esquemático será **estático/sequencial** com metadado **"Ir para o Mapa"** por objecto.
- O versionamento utilizará lógica de instâncias **reais vs. históricas** (bi-temporal).
- Foco actual: landbase offline operacional; próxima fase — modelagem de rede em PostGIS.

---

## Próximos passos

| Prioridade | Tarefa | Estado |
|------------|--------|--------|
| 1 | Upgrade satélite MBTiles para ZMAX=17 (1,2 m/px) | **✅ Operacional** |
| 2 | Modelagem explícita da topologia de rede (schema PostGIS) | Pendente |
| 3 | APIs/backend para edição e logs MongoDB (`event_report`) | Pendente |
| 4 | Endurecimento de segurança (credenciais, TLS) | Fora do âmbito da POC |
