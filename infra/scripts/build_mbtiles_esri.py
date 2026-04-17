#!/usr/bin/env python3
"""
TabGis — Gerador de MBTiles raster a partir de tiles XYZ (Esri World Imagery).

Uso (POC / laboratório): respeitar termos de uso da fonte; não redistribuir
tiles sem licença adequada.

Estratégia de escrita:
  O ficheiro é gerado num caminho temporário (.tmp) e, ao concluir com
  sucesso, substituído atomicamente pelo ficheiro final. Assim o TileServer GL
  nunca serve um pacote incompleto — apenas reinicia a servir após a
  substituição e `docker compose restart tileserver`.

Variáveis de ambiente (opcional):
  MBTILES_OUT   caminho final do .mbtiles (default: data/tiles/sp_satellite.mbtiles)
  BBOX          west,south,east,north em WGS84 (default: recorte capital SP)
  ZMIN, ZMAX    níveis de zoom (default: 10 e 16)
  XYZ_URL       template {z}/{x}/{y} (default: Esri World Imagery)
  DELAY_MS      pausa entre pedidos HTTP em ms (default: 75)
  USER_AGENT    cabeçalho User-Agent
  TIMEOUT_SEC   timeout por tile em segundos (default: 30)
"""
from __future__ import annotations

import os
import sqlite3
import sys
import time
from pathlib import Path

import mercantile
import requests

# Recorte padrão: capital SP + margem W/E (~25–30 km cada lado) para alinhar ao
# enquadramento Home no mapa e reduzir faixas vazias em ecrãs largos (POC).
DEFAULT_BBOX = (-47.5, -24.12, -45.9, -23.18)

# Template XYZ Esri World Imagery (nota: {y} no URL Esri é TMS-row, não XYZ-y;
# a função flip_y_to_mbtiles_row resolve a conversão antes de persistir)
DEFAULT_URL = (
    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
)


def flip_y_to_mbtiles_row(z: int, y_xyz: int) -> int:
    """
    Converte o índice y do esquema XYZ (Leaflet, de norte para sul)
    para tile_row do MBTiles (esquema TMS, de sul para norte).
    """
    return (2**z - 1) - y_xyz


def init_mbtiles_db(
    path: Path, bounds: tuple[float, float, float, float], zmin: int, zmax: int
) -> sqlite3.Connection:
    """
    Cria um novo ficheiro SQLite com o schema MBTiles e os metadados do pacote.
    Usa PRAGMA journal_mode=OFF e synchronous=OFF para máximo desempenho de escrita
    sequencial (aceitável em geração única; não usar em base de dados de produção).
    """
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
        ("name", "sp_satellite"),
        ("type", "overlay"),
        ("version", "1.1"),
        ("format", "png"),
        ("bounds", f"{west},{south},{east},{north}"),
        ("minzoom", str(zmin)),
        ("maxzoom", str(zmax)),
        ("attribution", "Esri / sources — uso POC; ver termos do fornecedor"),
    ]
    conn.executemany("INSERT INTO metadata (name, value) VALUES (?, ?)", meta)
    conn.commit()
    return conn


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    final_out = Path(
        os.environ.get("MBTILES_OUT", str(repo_root / "data/tiles/sp_satellite.mbtiles"))
    )
    # Escrita em ficheiro temporário para não interromper o TileServer durante a geração
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
    zmax = int(os.environ.get("ZMAX", "16"))
    if zmin < 0 or zmax < zmin or zmax > 22:
        print("ZMIN/ZMAX inválidos", file=sys.stderr)
        return 2

    url_tpl = os.environ.get("XYZ_URL", DEFAULT_URL).strip() or DEFAULT_URL
    delay_ms = float(os.environ.get("DELAY_MS", "75"))
    timeout = float(os.environ.get("TIMEOUT_SEC", "30"))
    ua = os.environ.get("USER_AGENT", "TabGis-POC/1.0 (MBTiles builder; +https://github.com/)")

    bounds = (west, south, east, north)
    conn = init_mbtiles_db(tmp_out, bounds, zmin, zmax)
    session = requests.Session()
    session.headers.update({"User-Agent": ua})

    tiles = list(mercantile.tiles(west, south, east, north, range(zmin, zmax + 1)))
    total = len(tiles)
    print(f"Destino final : {final_out}")
    print(f"Ficheiro temp : {tmp_out}")
    print(f"BBOX WGS84    : {west}, {south}, {east}, {north}")
    print(f"Zoom          : {zmin}–{zmax} | {total:,} tiles")
    print()

    ok = 0
    fail = 0
    t0 = time.time()
    for i, tile in enumerate(tiles):
        z, x, y = tile.z, tile.x, tile.y
        url = url_tpl.format(z=z, x=x, y=y)
        try:
            r = session.get(url, timeout=timeout)
            if r.status_code != 200 or not r.content:
                fail += 1
            else:
                row = flip_y_to_mbtiles_row(z, y)
                conn.execute(
                    "INSERT OR REPLACE INTO tiles "
                    "(zoom_level, tile_column, tile_row, tile_data) VALUES (?,?,?,?)",
                    (z, x, row, r.content),
                )
                ok += 1
        except requests.RequestException:
            fail += 1
        if delay_ms > 0:
            time.sleep(delay_ms / 1000.0)
        if (i + 1) % 50 == 0 or i + 1 == total:
            elapsed = max(time.time() - t0, 1e-6)
            rate = (i + 1) / elapsed
            eta = (total - (i + 1)) / rate if rate > 0 else 0
            print(
                f"  {i + 1:>6}/{total} tiles | ok={ok} fail={fail} "
                f"| {rate:.1f} tiles/s | ETA ~{eta/60:.1f} min"
            )

    conn.commit()
    conn.close()

    if ok == 0:
        print("Nenhum tile descarregado — ficheiro temporário não foi promovido.", file=sys.stderr)
        tmp_out.unlink(missing_ok=True)
        return 1

    # Substituição atómica: o ficheiro final só é actualizado após conclusão completa
    tmp_out.replace(final_out)
    elapsed_total = time.time() - t0
    print()
    print(
        f"Concluído em {elapsed_total:.1f}s — {final_out} "
        f"({final_out.stat().st_size // 1024 // 1024} MiB)"
    )
    print("Reinicie o TileServer para servir o novo pacote:")
    print("  docker compose -f infra/docker-compose.yml restart tileserver")
    return 0


if __name__ == "__main__":
    sys.exit(main())
