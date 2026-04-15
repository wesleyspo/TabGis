-- Configuração de visibilidade das vias por escala (denominador de escala OGC, ~mapa 1:N).
-- Em Web Mercator, ao afastar o zoom o denominador AUMENTA; ao aproximar, DIMINUI.
-- Regra GeoServer (SLD): cada regra aplica-se quando min_scale_denominator <= escala_atual <= max_scale_denominator
-- (valores NULL significam sem limite nesse extremo).

CREATE SCHEMA IF NOT EXISTS landbase;

DROP TABLE IF EXISTS landbase.via_zoom_config CASCADE;

CREATE TABLE landbase.via_zoom_config (
  id                serial PRIMARY KEY,
  highway_group     text NOT NULL,
  highway_values    text NOT NULL,
  min_scale_denominator double precision DEFAULT 0,
  max_scale_denominator double precision,
  leaflet_zoom_ref_min smallint,
  leaflet_zoom_ref_max smallint,
  notas             text
);

COMMENT ON TABLE landbase.via_zoom_config IS
  'Define intervalos de escala em que cada grupo de valores highway OSM é desenhado no WMS. Valores alinhados ao SLD base_sp_vias_zoom_scales.sld; após alterar a tabela, regerar/atualizar o SLD ou executar infra/scripts/apply_vias_zoom_style.sh';

-- Referência aproximada Leaflet (EPSG:3857, SP): z8 ~1:300k, z10 ~1:75k, z12 ~1:19k, z14 ~1:5k, z16 ~1:1.2k
-- max_scale_denominator: regra SLD aplica quando escala_atual <= este valor (mais detalhe ao aproximar zoom).
INSERT INTO landbase.via_zoom_config (highway_group, highway_values, min_scale_denominator, max_scale_denominator, leaflet_zoom_ref_min, leaflet_zoom_ref_max, notas) VALUES
('motorway_trunk', 'motorway,trunk', 0, 500000000, 4, 22, 'Alinhado ao SLD base_sp_vias_zoom_scales.sld'),
('primary', 'primary', 0, 8000000, 7, 22, NULL),
('secondary', 'secondary', 0, 2500000, 9, 22, NULL),
('tertiary', 'tertiary', 0, 600000, 11, 22, NULL),
('residential_living', 'residential,living_street', 0, 150000, 12, 22, NULL),
('service_unclassified', 'service,unclassified,road', 0, 100000, 13, 22, NULL),
('outros', '_ELSE_', 0, 40000, 14, 22, 'ElseFilter no SLD');
