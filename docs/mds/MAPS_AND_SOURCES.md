# Mapas offline e origens dos dados

> **Nota de actualização:** os números concretos (tiles, zoom, tamanho em disco) devem coincidir com a secção **MBTiles — satélite raster local** em [CONTEXT_STATE.md](./CONTEXT_STATE.md). **Snapshot deste documento:** 14 de maio de 2026 (revisar após regenerar pacotes).

## Satélite local (capital SP)

| Campo | Valor de referência (verificar em CONTEXT_STATE) |
|-------|-----------------------------------------------------|
| Ficheiro | `data/tiles/sp_satellite.mbtiles` |
| Zoom nativo | 10–17 |
| Origem dos pixels | Construção local via `infra/scripts/build_sp_satellite_mbtiles.sh` (fonte online no script — tipicamente tiles de satélite respeitando licença/OSM policy na geração) |
| Serviço | TileServer GL (`/tiles/` atrás do nginx) |

## GeoSampa offline (ortofoto PMSP)

| Aspecto | Origem / procedimento |
|---------|-------------------------|
| Dados | WMS GeoSampa / PMSP (uso conforme termos municipais) |
| Empacotamento | Scripts em `infra/scripts/` — ver [GeoSampa_offline_tecnico.md](./GeoSampa_offline_tecnico.md) e [GeoSampa_offline_operacao.md](./GeoSampa_offline_operacao.md) |
| Serviço | TileServer GL, registo em `data/tiles/config.json` |

## Vector / basemap (PostGIS + GeoServer)

| Camada / tema | Origem |
|---------------|--------|
| UF, municípios SP estado, vias | IBGE + OpenStreetMap (processamento em `infra/scripts/setup_landbase_sp_estado.sh` — ver [RUNBOOK_BASEMAP_SP_ESTADO.md](./RUNBOOK_BASEMAP_SP_ESTADO.md)) |
| Municípios-alvo, bairros, vias alvo | Recorte RMSP ampliada — `infra/scripts/setup_municipios_alvo_sp.sh` |
| SP Centro (legado) | [RUNBOOK_BASEMAP_SP.md](./RUNBOOK_BASEMAP_SP.md) |

## Mapa online (referência)

| Camada | Origem |
|--------|--------|
| Satélite Esri World Imagery | Tiles XYZ Esri no cliente (requer Internet; ver termos Esri). |

## Baseline offline (referência de auditoria)

| Baseline | Data do pacote | Conteúdo | Notas |
|----------|------------------|-----------|--------|
| Satélite SP (capital) | **2026-05-14** (snapshot documental) | `sp_satellite.mbtiles`, ZMAX **17**, ~**175 306** tiles, ~**3 GB** | Valores operacionais em [CONTEXT_STATE.md](./CONTEXT_STATE.md) — secção *MBTiles — satélite raster local*; actualizar esta linha quando o pacote for regenerado. |
