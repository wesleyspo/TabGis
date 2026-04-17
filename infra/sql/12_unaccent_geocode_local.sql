-- Geocode local: comparação sem acentos (ex.: "Mario" ↔ "Mário").
-- Aplicar na BD existente: psql ... -f infra/sql/12_unaccent_geocode_local.sql
CREATE EXTENSION IF NOT EXISTS unaccent;
