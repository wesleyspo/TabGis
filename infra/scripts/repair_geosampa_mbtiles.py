#!/usr/bin/env python3
"""
TabGis — Reparação incremental do MBTiles GeoSampa offline.

Compara o conjunto de tiles esperado (mercantile × BBOX × ZMIN–ZMAX) com as
linhas presentes em `tiles` e volta a pedir ao WMS apenas os que faltam.

Reutiliza a lógica HTTP de `build_geosampa_mbtiles.py` (import do mesmo directório).

Variáveis de ambiente (alinhadas ao build):
  MBTILES_OUT   ficheiro a reparar (default: data/tiles/geosampa_offline.mbtiles)
  BBOX, ZMIN, ZMAX, WMS_LAYER, WMS_BASE, DELAY_MS, TIMEOUT_SEC,
  WMS_MAX_ATTEMPTS, RETRY_DELAY_MS, USER_AGENT, TILE_WIDTH, TILE_HEIGHT

  REPAIR_COMMIT_EVERY  commits SQLite a cada N inserções (default: 200)
"""
from __future__ import annotations

import os
import sqlite3
import sys
import time
from pathlib import Path

import mercantile
import requests

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

import build_geosampa_mbtiles as bg  # noqa: E402


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    target = Path(
        os.environ.get(
            "MBTILES_OUT", str(repo_root / "data/tiles/geosampa_offline.mbtiles")
        )
    )
    if not target.is_file():
        print(f"MBTiles não encontrado: {target}", file=sys.stderr)
        return 2

    bbox_s = os.environ.get("BBOX", "").strip()
    if bbox_s:
        parts = [float(x.strip()) for x in bbox_s.split(",")]
        if len(parts) != 4:
            print("BBOX deve ser west,south,east,north", file=sys.stderr)
            return 2
        west, south, east, north = parts
    else:
        west, south, east, north = bg.DEFAULT_BBOX

    zmin = int(os.environ.get("ZMIN", "10"))
    zmax = int(os.environ.get("ZMAX", "19"))
    if zmin < 0 or zmax < zmin or zmax > 22:
        print("ZMIN/ZMAX inválidos", file=sys.stderr)
        return 2

    wms_base = os.environ.get("WMS_BASE", bg.DEFAULT_WMS_BASE).strip() or bg.DEFAULT_WMS_BASE
    layer = os.environ.get("WMS_LAYER", bg.DEFAULT_LAYER).strip() or bg.DEFAULT_LAYER
    delay_ms = float(os.environ.get("DELAY_MS", "100"))
    timeout = float(os.environ.get("TIMEOUT_SEC", "60"))
    max_attempts = int(os.environ.get("WMS_MAX_ATTEMPTS", "5"))
    retry_delay_s = float(os.environ.get("RETRY_DELAY_MS", "800")) / 1000.0
    ua = os.environ.get(
        "USER_AGENT",
        "TabGis-POC/1.0 (GeoSampa MBTiles repair; academic research)",
    )
    tile_w = int(os.environ.get("TILE_WIDTH", "256"))
    tile_h = int(os.environ.get("TILE_HEIGHT", "256"))
    commit_every = max(1, int(os.environ.get("REPAIR_COMMIT_EVERY", "200")))

    tiles = list(mercantile.tiles(west, south, east, north, range(zmin, zmax + 1)))
    total_expected = len(tiles)

    print(f"Reparar ficheiro : {target}")
    print(f"BBOX WGS84       : {west}, {south}, {east}, {north}")
    print(f"Zoom             : {zmin}–{zmax} | {total_expected:,} tiles esperados")
    print(f"WMS              : {wms_base}")
    print(f"Layer            : {layer}")
    print(f"Retentativas     : até {max(1, max_attempts)} / tile; commit a cada {commit_every}")
    print()

    conn = sqlite3.connect(str(target))
    conn.execute("PRAGMA journal_mode=OFF;")
    conn.execute("PRAGMA synchronous=OFF;")

    t_read = time.time()
    print("A ler chaves existentes em `tiles`…", flush=True)
    existing: set[tuple[int, int, int]] = set()
    for row in conn.execute("SELECT zoom_level, tile_column, tile_row FROM tiles"):
        existing.add((int(row[0]), int(row[1]), int(row[2])))
    print(f"… {len(existing):,} tiles no MBTiles ({time.time() - t_read:.1f}s)", flush=True)

    missing = []
    for tile in tiles:
        z, x, y_xyz = tile.z, tile.x, tile.y
        row = bg.flip_y_to_mbtiles_row(z, y_xyz)
        if (z, x, row) not in existing:
            missing.append(tile)

    n_miss = len(missing)
    print(f"Tiles em falta   : {n_miss:,} ({100.0 * n_miss / max(total_expected, 1):.2f}%)", flush=True)
    if n_miss == 0:
        print("Nada a reparar.")
        conn.close()
        return 0

    session = requests.Session()
    session.headers.update({"User-Agent": ua})

    ok = 0
    fail = 0
    t0 = time.time()
    for i, tile in enumerate(missing):
        z, x, y_xyz = tile.z, tile.x, tile.y
        b = mercantile.xy_bounds(tile)
        url = bg.build_wms_url(
            wms_base, layer, b.left, b.bottom, b.right, b.top, tile_w, tile_h
        )
        png = bg.fetch_wms_tile_png(
            session,
            url,
            timeout=timeout,
            max_attempts=max_attempts,
            retry_delay_s=retry_delay_s,
        )
        row = bg.flip_y_to_mbtiles_row(z, y_xyz)
        if png is None:
            fail += 1
        else:
            conn.execute(
                "INSERT OR REPLACE INTO tiles "
                "(zoom_level, tile_column, tile_row, tile_data) VALUES (?,?,?,?)",
                (z, x, row, png),
            )
            ok += 1
            existing.add((z, x, row))
        if delay_ms > 0:
            time.sleep(delay_ms / 1000.0)
        if (i + 1) % commit_every == 0:
            conn.commit()
        if (i + 1) % 50 == 0 or i + 1 == n_miss:
            elapsed = max(time.time() - t0, 1e-6)
            rate = (i + 1) / elapsed
            eta = (n_miss - (i + 1)) / rate if rate > 0 else 0
            print(
                f"  {i + 1:>6}/{n_miss} em falta | ok={ok} fail={fail} "
                f"| {rate:.2f} tiles/s | ETA ~{eta/60:.1f} min",
                flush=True,
            )

    conn.commit()
    conn.close()

    elapsed_total = time.time() - t0
    print()
    print(
        f"Reparação concluída em {elapsed_total:.1f}s — inseridos {ok:,}, "
        f"ainda em falha {fail:,}. Tamanho ficheiro ~{target.stat().st_size // 1024 // 1024:,} MiB"
    )
    print("Recomenda-se reiniciar o TileServer após reparações grandes:")
    print("  docker compose -f infra/docker-compose.yml restart tileserver")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
