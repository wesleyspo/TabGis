#!/usr/bin/env bash
# Gera: (1) docs/html/*.html a partir de docs/mds/*.md
#       (2) docs/pdfs/*.pdf  (Docker pandoc/extra, LaTeX)
#       (3) _site/ para GitHub Pages (hub + páginas na raiz + help)
# Requisitos: pandoc no PATH *ou* Docker pandoc/core para HTML;
#             PDF: Docker pandoc/extra (recomendado) ou pandoc + lualatex local.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SITE="${1:-$ROOT/_site}"
PANDOC_IMAGE="${PANDOC_IMAGE:-pandoc/core:3.1}"
PANDOC_PDF_IMAGE="${PANDOC_PDF_IMAGE:-pandoc/extra:3.1}"

MDS="$ROOT/docs/mds"
HTML="$ROOT/docs/html"
PDFS="$ROOT/docs/pdfs"

run_pandoc_html() {
  if command -v pandoc >/dev/null 2>&1; then
    pandoc "$@"
  elif command -v docker >/dev/null 2>&1; then
    local -a vols=(-v "$ROOT:$ROOT")
    local site_parent
    site_parent="$(cd "$(dirname "$SITE")" && pwd)"
    if [[ "$site_parent" != "$ROOT" && "$site_parent" != "$ROOT/"* ]]; then
      vols+=(-v "$site_parent:$site_parent")
    fi
    docker run --rm "${vols[@]}" -w "$ROOT" "$PANDOC_IMAGE" "$@"
  else
    echo "ERRO: instale pandoc (sudo apt install pandoc) ou disponibilize Docker (${PANDOC_IMAGE})." >&2
    exit 1
  fi
}

run_pandoc_pdf() {
  local -a args=("$@")
  if command -v docker >/dev/null 2>&1; then
    docker run --rm -v "$ROOT:$ROOT" -w "$ROOT" "$PANDOC_PDF_IMAGE" "${args[@]}" && return 0
  fi
  if command -v pandoc >/dev/null 2>&1; then
    pandoc "${args[@]}" && return 0
  fi
  echo "AVISO: sem Docker nem pandoc — PDF omitido para: ${args[*]}" >&2
  return 1
}

mkdir -p "$HTML/assets" "$PDFS" "$SITE/help" "$SITE/assets"

if [[ ! -f "$HTML/assets/site.css" ]]; then
  echo "ERRO: falta $HTML/assets/site.css (estilos do site)." >&2
  exit 1
fi

cp "$HTML/assets/site.css" "$SITE/assets/site.css"
cp "$HTML/index.html" "$SITE/index.html"

for md in "$MDS"/*.md; do
  [[ -f "$md" ]] || continue
  base="$(basename "$md" .md)"
  run_pandoc_html -s \
    --metadata "title=${base}" \
    -c "assets/site.css" \
    -o "$HTML/${base}.html" \
    "$md"
  cp "$HTML/${base}.html" "$SITE/${base}.html"

  if run_pandoc_pdf "$md" -o "$PDFS/${base}.pdf" --pdf-engine=lualatex -V geometry:margin=2cm; then
    :
  else
    echo "AVISO: PDF não gerado para ${base}.md (Docker ${PANDOC_PDF_IMAGE} ou pandoc + lualatex)." >&2
  fi
done

cp "$ROOT/frontend/help.html" "$SITE/help/index.html"
cp "$ROOT/frontend/styles.css" "$SITE/help/styles.css"

echo "docs/html e docs/pdfs actualizados; site em: $SITE"
