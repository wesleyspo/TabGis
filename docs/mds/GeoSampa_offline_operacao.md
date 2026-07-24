# GeoSampa offline — Guia operacional (TabGis)

Documento **funcional**: o que precisa de correr no servidor e como validar no mapa. Sem detalhes de implementação Python.

---

## 1. O que é

Ortofoto do **GeoSampa** (PMSP) armazenada localmente em **MBTiles** (`geosampa_offline.mbtiles`), servida pelo **TileServer GL** atrás do nginx em `/tiles/`. O TabGis activa a camada **«GeoSampa - Offline»** nas Camadas depois de verificar que o TileServer expõe o dataset.

---

## 2. Pré-requisitos

- Docker Compose (`infra/docker-compose.yml`) com **db**, **tileserver**, **web** a correr.
- Espaço em disco suficiente (o pacote completo ZMAX=19 pode ocupar **dezenas de GB**).
- Acesso de rede ao WMS GeoSampa durante a **geração** ou **reparação** (pedidos `GetMap`).

---

## 3. Gerar o MBTiles (primeira vez ou recriar)

Na raiz do repositório:

```bash
./infra/scripts/build_geosampa_offline_mbtiles.sh
```

Pode demorar muitas horas. Ao terminar, o script indica reinício do TileServer:

```bash
docker compose -f infra/docker-compose.yml restart tileserver
```

Se o `web` (nginx) resolver mal o hostname `tileserver`, reinicie também `web` (ver `docs/mds/CONTEXT_STATE.md`).

---

## 4. Reparar só tiles em falta

Após um build com falhas parciais (buracos no mapa), **não** é necessário apagar o ficheiro inteiro:

```bash
./infra/scripts/repair_geosampa_offline_mbtiles.sh
```

Em **background** com registo:

```bash
nohup ./infra/scripts/repair_geosampa_offline_mbtiles.sh >> /tmp/geosampa_repair.log 2>&1 &
tail -f /tmp/geosampa_repair.log
```

Variáveis opcionais (mais conservador no WMS): `DELAY_MS=120` `WMS_MAX_ATTEMPTS=6`.

Após reparações grandes, volte a **reiniciar o TileServer** (e `web` se aplicável).

---

## 5. Validar no cliente

1. Abrir `http://<servidor>:8088/`.
2. **Camadas** → activar **GeoSampa - Offline** (desligue outros fundos raster se necessário).
3. Percorrer zoom e pan na área de São Paulo; buracos isolados devem desaparecer após a reparação.

---

## 6. Termos e uso

Respeite os **termos de uso** do GeoSampa / PMSP. Uso académico / POC conforme o projecto GeoUtil.

---

## Ligação à documentação técnica

Ver [`GeoSampa_offline_tecnico.md`](./GeoSampa_offline_tecnico.md) (mesmo repositório).
