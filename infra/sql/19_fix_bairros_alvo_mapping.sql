-- Correção segura para lista de bairros:
-- remove linhas em que `bairro_nome` coincide com nome de município-alvo
-- (ruído típico de boundaries administrativas no OSM), sem alterar restante cobertura.

DELETE FROM landbase.bairros_alvo_sp b
USING landbase.municipios_alvo_sp m
WHERE lower(unaccent(btrim(COALESCE(b.bairro_nome, ''))))
      = lower(unaccent(btrim(COALESCE(m.nm_mun, ''))));

ANALYZE landbase.bairros_alvo_sp;
