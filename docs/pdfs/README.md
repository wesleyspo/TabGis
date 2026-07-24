# PDFs (gerados)

Cada ficheiro **`.pdf`** homólogo a um **`.md`** em [`../mds/`](../mds/) é produzido pelo script [`../../scripts/docs/build-pages-site.sh`](../../scripts/docs/build-pages-site.sh) com **Pandoc** e a imagem Docker **`pandoc/extra`** (motor **LuaLaTeX** por omissão, melhor suporte a Unicode em PT; alguns símbolos ou emoji podem faltar na fonte e gerar avisos).

Sem Docker, a etapa PDF tenta `pandoc` local com `--pdf-engine=lualatex` se existir; caso contrário omite-se o PDF. O HTML continua a ser gerado com `pandoc` do sistema ou `pandoc/core`.
