# Runbook — Basemap Offline (Estado de São Paulo)

Guia oficial para carga e publicação do landbase **SP completo** (escala estadual).
Pipeline versionado e repetível — referência principal para o produto.

> **Deploy completo da stack:** ver `docs/DEPLOY_POC.md`
> **Estado operacional actual:** ver `docs/CONTEXT_STATE.md`

---

## 1. Objectivo

- Disponibilizar fundo cartográfico offline e livre para operação de utilities em todo o estado de SP
- Garantir reprodutibilidade (script único, sem passos manuais)
- Manter compatibilidade com GeoServer (WMS/WFS) e evolução futura para tiles vectoriais

---

## 2. Pré-requisitos

Stack activa (`db`, `geoserver`) via `infra/docker-compose.yml`:

```bash
docker compose -f infra/docker-compose.yml up -d db geoserver
```

Ferramentas no host: `psql`, `shp2pgsql`, `osm2pgsql`, `curl`, `python3`

---

## 3. Entradas de dados

| Ficheiro | Origem | Observação |
|---------|--------|------------|
| `data/raw/ibge/BR_UF_2024.zip` | IBGE | Shapefile UF Brasil |
| `data/raw/ibge/BR_Municipios_2024.zip` | IBGE | Shapefile municípios Brasil |
| `data/raw/osm/sao-paulo-latest.osm.pbf` | Geofabrik | **Preferido** — extrato estadual |
| `data/raw/osm/sudeste-latest.osm.pbf` | Geofabrik | **Fallback automático** — usado se o PBF estadual for inválido |

O script descarrega automaticamente os ficheiros IBGE se ausentes. O download do OSM deve ser feito manualmente (tamanho elevado):

```bash
# Extrato SP (~100 MB)
curl -fL -o data/raw/osm/sao-paulo-latest.osm.pbf \
  https://download.geofabrik.de/south-america/brazil/sudeste/sao-paulo-latest.osm.pbf
```

---

## 4. Execução

Na raiz do repositório:

```bash
./infra/scripts/setup_landbase_sp_estado.sh
```

O script é idempotente — pode ser re-executado sem duplicar dados.

---

## 5. Entregáveis

### PostGIS (schema `landbase`)

| Tabela | Conteúdo | SRID |
|--------|---------|------|
| `landbase.uf_sp` | Polígono UF SP (IBGE) | EPSG:4674 |
| `landbase.municipios_sp` | Municípios com geometria intersectando UF SP | EPSG:4674 |
| `landbase.vias_sp` | Linhas OSM com tag `highway`, recortadas ao estado | EPSG:4674 |

Tabelas intermediárias `public.osm_sp_*` (prefixo `osm_sp`) geradas pelo `osm2pgsql`.

### GeoServer (workspace `base_sp`)

| Camada | Estilo SLD |
|--------|-----------|
| `base_sp:uf_sp` | `base_sp_uf_outline` |
| `base_sp:municipios_sp` | `base_sp_municipios_outline` |
| `base_sp:vias_sp` | `base_sp_vias_zoom_scales` |

Estilos SLD versionados em `infra/geoserver/styles/`.

---

## 6. Validação

```bash
# WMS GetCapabilities
curl -s "http://localhost:8080/geoserver/wms?service=WMS&request=GetCapabilities" \
  | grep -o 'base_sp:[^<]*' | head

# Contagem PostGIS
PGPASSWORD=password123 psql -h localhost -p 5432 -U tabgis_admin -d tabgis_db -c \
  "SELECT 'uf_sp' AS tabela, COUNT(*) FROM landbase.uf_sp
   UNION ALL SELECT 'municipios_sp', COUNT(*) FROM landbase.municipios_sp
   UNION ALL SELECT 'vias_sp', COUNT(*) FROM landbase.vias_sp;"
```

---

## 7. Escalabilidade

- Para outro estado: alterar filtro `sigla_uf` em `landbase.uf_sp`, ajustar `SP_BBOX` (ou usar PBF do estado), re-executar
- Variáveis configuráveis: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`, `GEOSERVER_URL`, `GS_USER`, `GS_PASS`, `OSM_SP`, `OSM_SUDESTE`, `SP_BBOX`
