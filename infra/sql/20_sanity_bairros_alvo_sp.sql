-- Sanidade pós-`setup_municipios_alvo_sp.sh` (e após `19_fix_bairros_alvo_mapping.sql` se aplicável):
-- A coluna `bairro_nome` não deve coincidir com o nome de um município-alvo (vazamento típico
-- de `admin_level` / boundaries OSM: uma cidade vizinha entra na intersecção e polui a lista
-- de bairros no cliente).
--
-- Critério: idêntico a `19_fix_bairros_alvo_mapping.sql` (normalização lower/unaccent/trim).
--
-- Execução (espera 0 violações; com falha, `psql` termina com código ≠ 0):
--   PGPASSWORD=... psql -h localhost -p 5433 -U tabgis_admin -d tabgis_db -v ON_ERROR_STOP=1 -f infra/sql/20_sanity_bairros_alvo_sp.sql

\set ON_ERROR_STOP on

\echo '--- landbase.bairros_alvo_sp: linhas com bairro_nome = nome de município-alvo (esperar 0) ---'
SELECT
  b.ctid::text AS row_id,
  b.bairro_nome,
  b.municipio_nome,
  b.tipo
FROM landbase.bairros_alvo_sp b
INNER JOIN landbase.municipios_alvo_sp m
  ON lower(unaccent(btrim(COALESCE(b.bairro_nome, ''))))
   = lower(unaccent(btrim(COALESCE(m.nm_mun, ''))))
ORDER BY b.municipio_nome, b.bairro_nome;

\echo '--- Resumo ---'
SELECT count(*)::bigint AS violacoes_bairro_igual_mun
FROM landbase.bairros_alvo_sp b
INNER JOIN landbase.municipios_alvo_sp m
  ON lower(unaccent(btrim(COALESCE(b.bairro_nome, ''))))
   = lower(unaccent(btrim(COALESCE(m.nm_mun, ''))));

DO $san$
DECLARE
  n bigint;
BEGIN
  SELECT count(*)
  INTO n
  FROM landbase.bairros_alvo_sp b
  INNER JOIN landbase.municipios_alvo_sp m
    ON lower(unaccent(btrim(COALESCE(b.bairro_nome, ''))))
     = lower(unaccent(btrim(COALESCE(m.nm_mun, ''))));

  IF n > 0 THEN
    RAISE EXCEPTION 'bairros_alvo_sp: % linha(s) com bairro_nome = município-alvo. Corrige com: psql -f infra/sql/19_fix_bairros_alvo_mapping.sql (e rever origem OSM se necessário).', n
      USING HINT = 'Reexecuta a listagem no topo deste ficheiro para ver ctid, municipio_nome e bairro_nome.';
  END IF;

  RAISE NOTICE 'bairros_alvo_sp: sanidade OK (0 coincidências bairro_nome vs município-alvo).';
END
$san$;
