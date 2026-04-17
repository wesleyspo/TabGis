-- TabGis — massa de teste: subestação → alimentadores → consumidores (gis.*)
-- Idempotente: remove apenas registos com prefixo POC_DEMO_ / contas POC-DEMO-*
-- Ordem: após 04_gis_oms_mwm_domain.sql (ref + gis)

BEGIN;

DELETE FROM gis.consumer WHERE account_number LIKE 'POC-DEMO-%';
DELETE FROM gis.equipment WHERE location_desc LIKE 'POC_DEMO_%';

DO $$
DECLARE
  pid_sub BIGINT;
  pid_fd1 BIGINT;
  pid_fd2 BIGINT;
BEGIN
  INSERT INTO gis.equipment (
    type_id, network_type_id, network_level_id,
    status_0, status_1, status_2, status_3,
    normal_status_0, normal_status_1, normal_status_2, normal_status_3,
    parent_equipment_id, location_desc, geom
  ) VALUES (
    1, 1, 1,
    1, 1, 1, 1,
    1, 1, 1, 1,
    NULL,
    'POC_DEMO_Subestação Sé',
    ST_SetSRID(ST_MakePoint(-46.633308, -23.550510), 4326)
  )
  RETURNING id INTO pid_sub;

  INSERT INTO gis.equipment (
    type_id, network_type_id, network_level_id,
    status_0, status_1, status_2, status_3,
    normal_status_0, normal_status_1, normal_status_2, normal_status_3,
    parent_equipment_id, location_desc, geom
  ) VALUES (
    2, 2, 2,
    1, 1, 1, 1,
    1, 1, 1, 1,
    pid_sub,
    'POC_DEMO_Alimentador Leste-01',
    ST_SetSRID(ST_MakePoint(-46.628900, -23.548200), 4326)
  )
  RETURNING id INTO pid_fd1;

  INSERT INTO gis.equipment (
    type_id, network_type_id, network_level_id,
    status_0, status_1, status_2, status_3,
    normal_status_0, normal_status_1, normal_status_2, normal_status_3,
    parent_equipment_id, location_desc, geom
  ) VALUES (
    2, 2, 1,
    1, 1, 1, 1,
    1, 1, 1, 1,
    pid_sub,
    'POC_DEMO_Alimentador Oeste-02',
    ST_SetSRID(ST_MakePoint(-46.638200, -23.553100), 4326)
  )
  RETURNING id INTO pid_fd2;

  INSERT INTO gis.consumer (
    account_number, status_id, type_id, equipment_id, contract_type_id,
    last_name, city, state, geom, location_desc, utility_domain
  ) VALUES
    (
      'POC-DEMO-0001', 1, 1, pid_fd1, 1,
      'Unidade A', 'São Paulo', 'SP',
      ST_SetSRID(ST_MakePoint(-46.629500, -23.548800), 4326),
      'POC_DEMO_CONSUMER_A',
      'energy'
    ),
    (
      'POC-DEMO-0002', 1, 2, pid_fd2, 1,
      'Comércio B', 'São Paulo', 'SP',
      ST_SetSRID(ST_MakePoint(-46.637800, -23.552600), 4326),
      'POC_DEMO_CONSUMER_B',
      'energy'
    );
END $$;

COMMIT;
