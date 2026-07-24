# Regionalização (i18n)

## Mecanismo

| Componente | Função |
|------------|--------|
| `config.language` | Registo dos idiomas suportados (códigos **en**, **pt**, **es**, **it**). |
| `config.translation` | Pares (`object_id`, `language_id`, `translated_text`) — chaves de UI e glossário. |
| `GET /api/translations/:lang` | API usada pelo `frontend/main.js` para carregar o mapa de chaves. |
| `infra/sql/02_populate_translations.sql` | Carga idempotente (`ON CONFLICT DO UPDATE`) de todas as cadeias. |

## Tabela de idiomas (cadastro)

| Código | Uso típico |
|--------|------------|
| **en** | Inglês (referência técnica). |
| **pt** | Português (interface padrão TabGis). |
| **es** | Espanhol. |
| **it** | Italiano. |

## Glossário técnico recente (exemplos de chaves)

| Chave | Propósito |
|-------|-----------|
| `UI_GLOSSARY_LINEAR_NETWORK_SEGMENT` | Definição de *segmento linear da rede* (SIG). |
| `UI_GLOSSARY_POSTGIS_TOPOLOGY` | Definição da extensão `postgis_topology`. |
| `UI_HELP_STACK_POSTGIS_TOPOLOGY` | Ajuda: stack PostGIS + `gis.network_span`. |
| `UI_HELP_API_TOPOLOGY` | Ajuda: endpoints `/api/topology/*`. |

Após alterar `02_populate_translations.sql`, reaplicar na PostGIS e **reiniciar** o contentor `api` para o cliente recarregar traduções.
