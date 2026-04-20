# GeoSampa offline — Referência técnica (TabGis)

Documento **técnico**: ficheiros, variáveis de ambiente, esquema MBTiles, APIs externas e semântica de falhas.

---

## 1. Ficheiros relevantes

| Ficheiro | Função |
|----------|--------|
| `infra/scripts/build_geosampa_mbtiles.py` | Geração completa (apaga `.tmp`, preenche todos os tiles, substitui o `.mbtiles`). |
| `infra/scripts/build_geosampa_offline_mbtiles.sh` | Wrapper: venv, `pip`, env `MBTILES_OUT`, `ZMIN`, `ZMAX`. |
| `infra/scripts/repair_geosampa_mbtiles.py` | **Reparação incremental**: compara mercantile × BBOX com `SELECT` em `tiles`; só faz `GetMap` para chaves em falta. |
| `infra/scripts/repair_geosampa_offline_mbtiles.sh` | Wrapper da reparação (mesmo venv). |
| `data/tiles/config.json` | Registo `geosampa_offline` para o TileServer. |
| `frontend/main.js` | `geosampaOfflineLayer`, `checkLocalRasterHealth("geosampa_offline")`. |

---

## 2. Variáveis de ambiente (build e reparação)

| Variável | Descrição |
|----------|-----------|
| `MBTILES_OUT` | Caminho do ficheiro MBTiles (default `data/tiles/geosampa_offline.mbtiles`). |
| `BBOX` | `west,south,east,north` WGS84 (default recorte SP aproximado no script). |
| `ZMIN`, `ZMAX` | Zoom Web Mercator (default 10–19). |
| `WMS_BASE`, `WMS_LAYER` | Endpoint e camada WMS (ex. mosaico RGB). |
| `DELAY_MS` | Pausa entre pedidos HTTP (rate limit cortesia). |
| `TIMEOUT_SEC` | Timeout por `GetMap`. |
| `WMS_MAX_ATTEMPTS`, `RETRY_DELAY_MS` | Retentativas (build e reparação). |
| `REPAIR_COMMIT_EVERY` | *(só reparação)* `COMMIT` SQLite a cada N inserções (default 200). |

---

## 3. Modelo de dados MBTiles

- Tabela `tiles` (`zoom_level`, `tile_column`, `tile_row`, `tile_data` BLOB PNG).
- `tile_row` segue convenção **MBTiles** (eixo Y invertido face ao XYZ); o código usa `flip_y_to_mbtiles_row` em `build_geosampa_mbtiles.py`.
- A reparação considera «em falta» qualquer tile **esperado** pela grelha mercantile que **não** tenha linha correspondente.

---

## 4. Fontes HTTP

- **WMS:** `raster.geosampa.prefeitura.sp.gov.br` — `GetMap` PNG transparente, EPSG:3857.
- **Reparação:** reutiliza `build_wms_url` e `fetch_wms_tile_png` via import do módulo Python no mesmo directório.

---

## 5. Falhas e contadores

- **`fail` no build:** pedidos que, após retentativas, não produzem PNG válido (HTTP, XML `ServiceException`, corpo vazio, etc.). O build **continua** e promove o ficheiro se `ok > 0`.
- **Reparação:** só tenta tiles **ausentes** na BD; `fail` indica tiles que continuam sem inserção após retentativas.

---

## 6. Desempenho e disco

- Leitura inicial da reparação: `SELECT zoom_level, tile_column, tile_row FROM tiles` — para ~1M linhas pode demorar **minutos** e usar memória para o `set` de chaves.
- I/O: `PRAGMA synchronous=OFF` durante reparação (como no build) para acelerar escrita; risco de corrupção em falha de energia — aceitável em laboratório.

---

## Guia operacional

Ver [`GeoSampa_offline_operacao.md`](./GeoSampa_offline_operacao.md).
