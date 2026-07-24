-- Liga a vista de demonstração `demo_feeder_central` a `gis.equipment` da massa POC (14).
-- Idempotente. Ordem: após `16_schematic_schema.sql` e, de preferência, `14_gis_equipment_network_demo.sql`.
-- Se `14` não estiver aplicado, os UPDATEs não afectam linhas (equipment_id fica inalterado).

UPDATE schematic.view_node n
SET equipment_id = e.id
FROM schematic.network_view v, gis.equipment e
WHERE v.code = 'demo_feeder_central'
  AND n.view_id = v.id
  AND n.seq_no = 1
  AND e.location_desc = 'POC_DEMO_Subestação Sé';

UPDATE schematic.view_node n
SET equipment_id = e.id
FROM schematic.network_view v, gis.equipment e
WHERE v.code = 'demo_feeder_central'
  AND n.view_id = v.id
  AND n.seq_no = 2
  AND e.location_desc = 'POC_DEMO_Alimentador Leste-01';

COMMENT ON TABLE schematic.view_node IS
  'Nó ordenado; equipment_id → gis.equipment. API GET /api/schematic/views/:id inclui rótulo de tipo e coordenadas do equipamento (fallback «Ir para o mapa»).';
