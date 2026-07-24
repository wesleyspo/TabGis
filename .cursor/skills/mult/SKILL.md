---
name: mult
description: Maintains TabGis documentation under docs/ (mds + html + pdfs mirrors), GitHub Pages build (Pandoc), architecture BPMN, regionalization, and maps sources when the product changes. Use when the user invokes /mult or asks to refresh documentation parity between Markdown, HTML, PDF, or the static Pages site.
disable-model-invocation: true
---

# mult — documentação TabGis (MD + HTML + PDF)

## Verbatim (pedido do utilizador)

> Baseado no conteúdo desenvolvido até o momento preciso que atualize a documentação:
> /home/wesley/projects/TabGis/docs
> Ela deve conter um home que direciona para os MDs relacionados.
> Deve dividir em dois repositórios Mds e HTML que devem ter a mesma estrutura e comportamento.
>
> Avaliar a necessidade de atualizar a página que criamos para o github.
>
> Criar um diagrama de arquitetura BPMN com todos os modulos que utilizamos.
>
> geoserver
> postgresql
> github
> geosampa
> Tabela de regionalização
> Vamos adicionar o Mongo para a recepção de dados já adicione-o como componente pendente
> Liguagens utilizadas
> Deploy
> mapas offline de XXX data XXX
> origem dos mapas

## Interpretação (árvores paralelas)

No repositório **TabGis** único:

| Árvore | Caminho | Papel |
|--------|---------|--------|
| **Markdown (fonte)** | `docs/mds/` | Única origem canónica dos `.md` autoriais. |
| **HTML (espelho)** | `docs/html/` | Mesmos nomes-base que `mds/` (`CONTEXT_STATE.html`, …) + `index.html` + `assets/site.css`; gerado por Pandoc a partir de `mds/`. |
| **PDF (espelho)** | `docs/pdfs/` | Um `.pdf` por cada `.md` em `mds/` (Docker `pandoc/extra` ou LaTeX local). |
| **Home índice MD** | `docs/README.md` | Aponta para `mds/`, `html/`, `pdfs/` e para o script de build. |

Não são dois repositórios Git separados, a menos que o projecto decida extrair documentação para um repo dedicado no futuro.

## Checklist ao aplicar /mult

1. Ler `docs/mds/CONTEXT_STATE.md` e código tocado na sessão.
2. Actualizar `docs/README.md` (home) se existirem novos `.md` em `mds/` ou secções relevantes.
3. Actualizar `docs/html/index.html` com os **mesmos destinos** (links `./<Nome>.html` ao lado do hub).
4. Actualizar `docs/mds/ARCHITECTURE_BPMN.md` se mudarem módulos externos (PostGIS, GeoServer, GitHub, GeoSampa, Mongo pendente, etc.).
5. Actualizar `docs/mds/REGIONALIZATION.md` e `infra/sql/02_populate_translations.sql` quando houver novas chaves i18n.
6. Actualizar `docs/mds/MAPS_AND_SOURCES.md` e números em `CONTEXT_STATE` quando mudarem pacotes MBTiles ou origens.
7. Verificar `.github/workflows/pages.yml` e `scripts/docs/build-pages-site.sh` se o fluxo de Pages mudar.
8. Correr localmente: `scripts/docs/build-pages-site.sh` (HTML em `docs/html/`, PDF em `docs/pdfs/`, artefacto em `_site/`).

## GitHub Pages

O workflow `.github/workflows/pages.yml` instala **Pandoc**, gera `_site/` com o script acima e publica **índice de documentação** na raiz do site (ficheiros `*.html` planos) e **ajuda** em `/help/`. Se o Pages estiver desactivado no GitHub, activar em **Settings → Pages → GitHub Actions**.

## Ficheiros-chave

- `docs/README.md` — home Markdown.
- `docs/html/index.html` — home HTML (espelho de navegação).
- `docs/mds/ARCHITECTURE_BPMN.md` — diagrama Mermaid (estilo colaboração BPMN).
- `docs/mds/REGIONALIZATION.md`, `docs/mds/MAPS_AND_SOURCES.md`.
