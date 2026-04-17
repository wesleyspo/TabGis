#!/usr/bin/env python3
"""
TabGis — MBTiles raster a partir do WMS GeoSampa (ortofoto).

Fonte: https://raster.geosampa.prefeitura.sp.gov.br/geoserver/geoportal/wms
Respeitar termos de uso da PMSP; uso POC / laboratório.

Variáveis de ambiente (opcional):
  MBTILES_OUT   saída (default: data/tiles/geosampa_offline.mbtiles)
  BBOX          west,south,east,north em WGS84
  ZMIN, ZMAX    zoom WebMercator (default: 10 e 19 — máximo típico WebMercator)
  WMS_LAYER     camada publicada (default: geoportal:MOSAICO_ORTO_RGB_10CM_20CM)
  WMS_BASE      URL base do WMS (default: .../geoportal/wms)
  DELAY_MS      pausa entre pedidos (default: 100)
  USER_AGENT    User-Agent HTTP
  TIMEOUT_SEC   timeout por pedido
  WMS_MAX_ATTEMPTS  tentativas por tile, incl. a 1.ª (default: 3)
  RETRY_DELAY_MS    pausa base entre tentativas (default: 500); multiplica pelo índice da tentativa
"""
from __future__ import annotations

import os
import sqlite3
import sys
import time
import urllib.parse
from pathlib import Path

import mercantile
import requests

# Município de São Paulo (aprox. IBGE) — ajustável via BBOX=
DEFAULT_BBOX = (-46.84, -24.02, -46.36, -23.35)

DEFAULT_WMS_BASE = (
    "https://raster.geosampa.prefeitura.sp.gov.br/geoserver/geoportal/wms"
)
# Mosaico RGB com trechos a 10 cm (nome do serviço); alternativa: geoportal:ORTO_RGB_2020
DEFAULT_LAYER = "geoportal:MOSAICO_ORTO_RGB_10CM_20CM"


def flip_y_to_mbtiles_row(z: int, y_xyz: int) -> int:
    return (2**z - 1) - y_xyz


def init_mbtiles_db(
    path: Path,
    bounds: tuple[float, float, float, float],
    zmin: int,
    zmax: int,
    name: str,
    attribution: str,
) -> sqlite3.Connection:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    conn = sqlite3.connect(str(path))
    conn.execute("PRAGMA journal_mode=OFF;")
    conn.execute("PRAGMA synchronous=OFF;")
    conn.executescript(
        """
        CREATE TABLE metadata (name text, value text);
        CREATE TABLE tiles (zoom_level integer, tile_column integer, tile_row integer, tile_data blob);
        CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row);
        """
    )
    west, south, east, north = bounds
    meta = [
        ("name", name),
        ("type", "overlay"),
        ("version", "1.1"),
        ("format", "png"),
        ("bounds", f"{west},{south},{east},{north}"),
        ("minzoom", str(zmin)),
        ("maxzoom", str(zmax)),
        ("attribution", attribution),
    ]
    conn.executemany("INSERT INTO metadata (name, value) VALUES (?, ?)", meta)
    conn.commit()
    return conn


def build_wms_url(
    base: str,
    layer: str,
    left: float,
    bottom: float,
    right: float,
    top: float,
    width: int,
    height: int,
) -> str:
    params = {
        "SERVICE": "WMS",
        "VERSION": "1.1.1",
        "REQUEST": "GetMap",
        "LAYERS": layer,
        "STYLES": "",
        "SRS": "EPSG:3857",
        "BBOX": f"{left},{bottom},{right},{top}",
        "WIDTH": str(width),
        "HEIGHT": str(height),
        "FORMAT": "image/png",
        "TRANSPARENT": "TRUE",
    }
    return f"{base.rstrip('?')}?{urllib.parse.urlencode(params)}"


def _wms_body_is_error_png(content: bytes) -> bool:
    if not content:
        return True
    if content[:50].lstrip().startswith(b"<?xml"):
        return True
    if b"ServiceException" in content[:800]:
        return True
    if content[:5].lower() == b"<html":
        return True
    return False


def _http_status_retryable(code: int) -> bool:
    return code in (408, 429) or code >= 500


def fetch_wms_tile_png(
    session: requests.Session,
    url: str,
    *,
    timeout: float,
    max_attempts: int,
    retry_delay_s: float,
) -> bytes | None:
    """
    Obtém bytes PNG de um GetMap. Retentativas em falhas de rede, 5xx/429,
    corpo vazio ou resposta XML/HTML de erro WMS.
    """
    max_attempts = max(1, max_attempts)
    for attempt in range(max_attempts):
        try:
            r = session.get(url, timeout=timeout)
        except requests.RequestException:
            if attempt + 1 >= max_attempts:
                return None
            time.sleep(retry_delay_s * (attempt + 1))
            continue

        if r.status_code == 200 and r.content and not _wms_body_is_error_png(r.content):
            return r.content

        retry = attempt + 1 < max_attempts and (
            _http_status_retryable(r.status_code)
            or r.status_code != 200
            or not r.content
            or _wms_body_is_error_png(r.content)
        )
        if retry:
            time.sleep(retry_delay_s * (attempt + 1))
            continue
        return None

    return None


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    final_out = Path(
        os.environ.get(
            "MBTILES_OUT", str(repo_root / "data/tiles/geosampa_offline.mbtiles")
        )
    )
    tmp_out = final_out.with_suffix(".mbtiles.tmp")

    bbox_s = os.environ.get("BBOX", "").strip()
    if bbox_s:
        parts = [float(x.strip()) for x in bbox_s.split(",")]
        if len(parts) != 4:
            print("BBOX deve ser west,south,east,north", file=sys.stderr)
            return 2
        west, south, east, north = parts
    else:
        west, south, east, north = DEFAULT_BBOX

    zmin = int(os.environ.get("ZMIN", "10"))
    zmax = int(os.environ.get("ZMAX", "19"))
    if zmin < 0 or zmax < zmin or zmax > 22:
        print("ZMIN/ZMAX inválidos", file=sys.stderr)
        return 2

    wms_base = os.environ.get("WMS_BASE", DEFAULT_WMS_BASE).strip() or DEFAULT_WMS_BASE
    layer = os.environ.get("WMS_LAYER", DEFAULT_LAYER).strip() or DEFAULT_LAYER
    delay_ms = float(os.environ.get("DELAY_MS", "100"))
    timeout = float(os.environ.get("TIMEOUT_SEC", "60"))
    max_attempts = int(os.environ.get("WMS_MAX_ATTEMPTS", "3"))
    retry_delay_s = float(os.environ.get("RETRY_DELAY_MS", "500")) / 1000.0
    ua = os.environ.get(
        "USER_AGENT",
        "TabGis-POC/1.0 (GeoSampa MBTiles; academic research)",
    )
    tile_w = int(os.environ.get("TILE_WIDTH", "256"))
    tile_h = int(os.environ.get("TILE_HEIGHT", "256"))

    bounds = (west, south, east, north)
    conn = init_mbtiles_db(
        tmp_out,
        bounds,
        zmin,
        zmax,
        "geosampa_offline",
        "Prefeitura Municipal de São Paulo — GeoSampa (uso sujeito a termos)",
    )
    session = requests.Session()
    session.headers.update({"User-Agent": ua})

    tiles = list(mercantile.tiles(west, south, east, north, range(zmin, zmax + 1)))
    total = len(tiles)
    if total > 150_000:
        est_h = (total * max(delay_ms, 1) / 1000) / 3600
        print(
            f"Aviso: {total:,} tiles — tempo mínimo só em pausas ~{est_h:.1f} h "
            f"(sem contar rede). Disco: possivelmente dezenas de GB. "
            f"Para menos carga use ZMAX=18 ou reduza BBOX.",
            file=sys.stderr,
        )
    print(f"Destino final : {final_out}")
    print(f"Ficheiro temp : {tmp_out}")
    print(f"BBOX WGS84    : {west}, {south}, {east}, {north}")
    print(f"WMS           : {wms_base}")
    print(f"Layer         : {layer}")
    print(f"Zoom          : {zmin}–{zmax} | {total:,} tiles")
    print(f"Retentativas  : até {max(1, max_attempts)} tentativas/tile; pausa base {retry_delay_s * 1000:.0f} ms entre falhas")
    print()

    ok = 0
    fail = 0
    t0 = time.time()
    for i, tile in enumerate(tiles):
        z, x, y_xyz = tile.z, tile.x, tile.y
        b = mercantile.xy_bounds(tile)
        url = build_wms_url(
            wms_base, layer, b.left, b.bottom, b.right, b.top, tile_w, tile_h
        )
        png = fetch_wms_tile_png(
            session,
            url,
            timeout=timeout,
            max_attempts=max_attempts,
            retry_delay_s=retry_delay_s,
        )
        if png is None:
            fail += 1
        else:
            row = flip_y_to_mbtiles_row(z, y_xyz)
            conn.execute(
                "INSERT OR REPLACE INTO tiles "
                "(zoom_level, tile_column, tile_row, tile_data) VALUES (?,?,?,?)",
                (z, x, row, png),
            )
            ok += 1
        if delay_ms > 0:
            time.sleep(delay_ms / 1000.0)
        if (i + 1) % 50 == 0 or i + 1 == total:
            elapsed = max(time.time() - t0, 1e-6)
            rate = (i + 1) / elapsed
            eta = (total - (i + 1)) / rate if rate > 0 else 0
            print(
                f"  {i + 1:>6}/{total} tiles | ok={ok} fail={fail} "
                f"| {rate:.2f} tiles/s | ETA ~{eta/60:.1f} min"
            )

    conn.commit()
    conn.close()

    if ok == 0:
        print("Nenhum tile descarregado — ficheiro temporário não foi promovido.", file=sys.stderr)
        tmp_out.unlink(missing_ok=True)
        return 1

    tmp_out.replace(final_out)
    elapsed_total = time.time() - t0
    print()
    print(
        f"Concluído em {elapsed_total:.1f}s — {final_out} "
        f"({final_out.stat().st_size // 1024 // 1024} MiB)"
    )
    print("Reinicie o TileServer:")
    print("  docker compose -f infra/docker-compose.yml restart tileserver")
    return 0


if __name__ == "__main__":
    sys.exit(main())
