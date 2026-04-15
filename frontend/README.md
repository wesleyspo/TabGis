# Frontend Basemap SP

Cliente Web leve (**HTML + CSS + JavaScript**) com **Leaflet** (via CDN) para visualizar camadas WMS do GeoServer no workspace `base_sp`, com **busca por município e bairro (WFS)** e **identificação ao clique (GetFeatureInfo)**.

## Modo recomendado (mesma origem, sem CORS)

Com a stack Docker, o serviço **nginx** (`web`) expõe:

- Mapa e ficheiros estáticos: `http://<host>:8088/`
- GeoServer (proxy): `http://<host>:8088/geoserver/`

Subir os serviços (na raiz do projeto):

```bash
docker compose -f infra/docker-compose.yml up -d
```

Abrir [http://127.0.0.1:8088/](http://127.0.0.1:8088/) (ou o IP da máquina na LAN).

Neste modo, [main.js](main.js) usa `GeoServer` em `window.location.origin + '/geoserver'`, permitindo `fetch` a WFS e GetFeatureInfo.

## Modo desenvolvimento (apenas tiles)

```bash
cd frontend
python3 -m http.server 5173 --bind 0.0.0.0
```

Abrir `http://<host>:5173` — o mapa aponta WMS para **`http://<host>:8080/geoserver`**. Busca (WFS) e clique (GetFeatureInfo) podem falhar por **CORS**; use o modo `:8088` para essas funções.

## Funcionalidades

- Lista de municípios-alvo (WFS `base_sp:municipios_alvo_sp`) + zoom.
- Bairro: escolher município, digitar ≥ 2 letras, escolher resultado (WFS + `CQL_FILTER`).
- Clique no mapa: popup com atributos (WMS GetFeatureInfo nas camadas visíveis).
- **Satélite (online):** tiles Esri (256 px); requer Internet. Com satélite, UF e limites municipais ficam mais transparentes para ver a imagem.
- **Satélite (MBTiles local):** tiles servidos em `:8088/tiles/...` (TileServer GL no compose); em modo `:5173` o script resolve `:8088/tiles`. Geração do ficheiro: `infra/scripts/build_sp_satellite_mbtiles.sh` (ver `docs/DEPLOY_POC.md`).
- **Vias:** estilo `base_sp_vias_zoom_scales` — tipos de via aparecem conforme o zoom (definido em `landbase.via_zoom_config` no PostGIS e no SLD).

## Camadas usadas

- Estado / metrópole: `base_sp:uf_sp`, `base_sp:municipios_sp`, `base_sp:vias_sp`
- Recorte alvo: `base_sp:municipios_alvo_sp`, `base_sp:bairros_alvo_sp`, `base_sp:vias_alvo_sp`

## Offline total

Para ambiente sem Internet, descarregar Leaflet para `frontend/vendor/` e alterar `index.html` para apontar para ficheiros locais em vez do `unpkg.com`.

## Documentação relacionada

- Deploy completo: [docs/DEPLOY_POC.md](../docs/DEPLOY_POC.md)
- Importação de dados: [docs/RUNBOOK_BASEMAP_SP_ESTADO.md](../docs/RUNBOOK_BASEMAP_SP_ESTADO.md)
