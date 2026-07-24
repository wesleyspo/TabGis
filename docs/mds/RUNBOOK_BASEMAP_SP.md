# Runbook — Basemap Offline (São Paulo Centro)

> **Atenção:** Este runbook é **legado / ensaios**. O fluxo oficial para produto em escala estadual está em `docs/mds/RUNBOOK_BASEMAP_SP_ESTADO.md`.

Guia para carga localizada (capital, recorte Centro) e publicação no GeoServer.
Útil para testes rápidos em área reduzida ou desenvolvimento isolado.

**POC TabGis actual:** a interface completa (topbar, Busca WFS, painel Operação, proxy same-origin) assume o frontend servido por **nginx** em **`http://<host>:8088/`** com `infra/docker-compose.yml`. Estado da stack, SQL `01`–`03`, SLD do recorte alvo e i18n: `docs/mds/CONTEXT_STATE.md` e `docs/mds/DEPLOY_POC.md`.

---

## 1. Objectivo

- Fundo cartográfico offline para desenho de rede em área reduzida
- Estrutura reutilizável para trocar a área (outro município, outra bbox) sem reescrever o pipeline

---

## 2. Pré-requisitos

Stack activa (`db`, `geoserver`) via `infra/docker-compose.yml`:

```bash
docker compose -f infra/docker-compose.yml up -d db geoserver
```

Ferramentas no host: `psql`, `shp2pgsql`, `osm2pgsql`, `curl`, `python3`

Dados de entrada:
- `data/raw/ibge/BR_Municipios_2024.zip`
- `data/raw/osm/centro_highways.osm` (ou equivalente Overpass)

---

## 3. Execução

```bash
./infra/scripts/setup_landbase_sp.sh
```

---

## 4. Entregáveis PostGIS

| Tabela | Conteúdo |
|--------|---------|
| `landbase.municipios_br` | Municípios Brasil (IBGE) |
| `landbase.municipio_sp` | Município São Paulo (capital) |
| `landbase.aoi_centro_sp` | Área de interesse — Centro SP |
| `landbase.vias_centro_sp` | Vias OSM no recorte Centro |

---

## 5. Entregáveis GeoServer

- **Workspace:** `base_sp`
- **Datastore:** `tabgis_postgis`
- **Camadas:** `base_sp:municipio_sp`, `base_sp:aoi_centro_sp`, `base_sp:vias_centro_sp`

### Estilos

| Ficheiro SLD | Aplicação |
|-------------|-----------|
| `infra/geoserver/styles/base_sp_municipio_outline.sld` | Limite do município |
| `infra/geoserver/styles/base_sp_aoi_focus.sld` | Área de interesse |
| `infra/geoserver/styles/base_sp_vias_googleish.sld` | Vias estilo Google |

---

## 6. Validação

```bash
curl -s "http://localhost:8080/geoserver/wms?service=WMS&request=GetCapabilities" \
  | grep -o 'base_sp:[^<]*' | head
```

---

## 7. Personalização

Ajustar `cd_mun`, envelope `ST_MakeEnvelope` e ficheiro OSM no script; re-executar.
