-- TabGis — lote extra de ordens fictícias para testes da grelha OMS / scroll / ordenação
-- Idempotente (ON CONFLICT order_code). Aplicar após 05_operational_demo_data.sql e migrações 06+.

INSERT INTO operations.work_order (order_code, category, summary, description, status, priority, assigned_team_id, owner_id)
SELECT v.order_code, v.category, v.summary, v.description, v.status, v.priority, t.id, u.id
FROM (VALUES
    ('2026-9001', 'repair', 'Aperto de conexões BT — quadro predial', 'Reincidência de aquecimento em bornes; torque conforme norma.', 'open', 'P2', 'EQ-ALPHA', 'operador1'),
    ('2026-9002', 'complaint', 'Interrupção intermitente — Jardim Anália Franco', 'Cliente reporta quedas de tensão em horário de pico.', 'in_progress', 'P1', 'EQ-BETA', 'marina.silva'),
    ('2026-9003', 'task', 'Cadastro fotográfico de poste BT', 'Linha urbana — inventário de acessórios e número de placa.', 'scheduled', 'P3', 'EQ-EPSILON', 'ana.miranda'),
    ('2026-9004', 'repair', 'Chave fusível MT disparada — AF-11', 'Inspeção visual e teste de isolamento antes de religar.', 'open', 'P1', 'EQ-DELTA', 'despacho.centro'),
    ('2026-9005', 'complaint', 'Ruído em transformador abrigado', 'Condomínio — medição de ruído e vibração.', 'open', 'P3', 'EQ-ZETA', 'marina.silva'),
    ('2026-9006', 'repair', 'Substituição de para-raios 15 kV', 'Subestação compacta — EPI e bloqueio de manobra.', 'in_progress', 'P2', 'EQ-GAMA', 'gilberto.nunes'),
    ('2026-9007', 'task', 'Verificação de aterramento em CM', 'Medição de resistência de terra e corrosão de hastes.', 'scheduled', 'P3', 'EQ-ALPHA', 'operador1'),
    ('2026-9008', 'repair', 'Cabos despontando em bandejamento', 'Corredor industrial — reforço de fixação e identificação.', 'open', 'P2', 'EQ-EPSILON', 'despacho.centro'),
    ('2026-9009', 'complaint', 'Conta de energia divergente pós religação', 'Conferência de leitura e histórico AMI.', 'open', 'P3', 'EQ-BETA', 'ana.miranda'),
    ('2026-9010', 'repair', 'Religador com falha de comunicação SCADA', 'Ping RTU e verificação de antena / alimentação.', 'in_progress', 'P1', 'EQ-DELTA', 'operador1'),
    ('2026-9011', 'task', 'Inspeção de câmara subterrânea', 'Umidade e drenagem — registro fotográfico.', 'scheduled', 'P3', 'EQ-ZETA', 'marina.silva'),
    ('2026-9012', 'repair', 'Desbalanceamento de fases em trafo de rua', 'Medição de tensões e correntes por fase.', 'open', 'P2', 'EQ-GAMA', 'gilberto.nunes'),
    ('2026-9013', 'complaint', 'Faísca em conector aéreo', 'Desligamento preventivo e troca de conector.', 'in_progress', 'P1', 'EQ-ALPHA', 'despacho.centro'),
    ('2026-9014', 'task', 'Atualização cadastral de cliente gerador', 'Microgeração — conferência de proteções e religação.', 'scheduled', 'P2', 'EQ-EPSILON', 'operador1'),
    ('2026-9015', 'repair', 'Manutenção em seccionadora motorizada', 'Teste de comando local/remoto e limites.', 'open', 'P2', 'EQ-BETA', 'marina.silva'),
    ('2026-9016', 'repair', 'Corrosão em estrutura metálica MT', 'Pintura e avaliação de vida útil.', 'scheduled', 'P3', 'EQ-DELTA', 'ana.miranda'),
    ('2026-9017', 'complaint', 'Queda total — condomínio horizontal', 'Checar chave geral e ramal de entrada.', 'in_progress', 'P1', 'EQ-ZETA', 'operador1'),
    ('2026-9018', 'task', 'Treinamento de equipe em EPI veicular', 'Checklist de deslocamento e barreira de segurança.', 'open', 'P3', 'EQ-GAMA', 'gilberto.nunes'),
    ('2026-9019', 'repair', 'Ajuste de proteção de sobrecorrente', 'Coordenação com subestação vizinha.', 'open', 'P2', 'EQ-ALPHA', 'despacho.centro'),
    ('2026-9020', 'complaint', 'Tensão alta em rede rural', 'Regulador ou trafo com tape incorreto — verificar.', 'in_progress', 'P2', 'EQ-EPSILON', 'marina.silva'),
    ('2026-9021', 'task', 'Inventário de religadores na região leste', 'Planilha de firmware e versão de protocolo.', 'scheduled', 'P3', 'EQ-BETA', 'ana.miranda'),
    ('2026-9022', 'repair', 'Substituição de cabo BT danificado por poda', 'Desligamento e religação com termografia.', 'open', 'P1', 'EQ-DELTA', 'operador1'),
    ('2026-9023', 'repair', 'Teste de disjuntor geral edifício comercial', 'Curva de disparo e manutenção preventiva.', 'scheduled', 'P2', 'EQ-ZETA', 'gilberto.nunes'),
    ('2026-9024', 'complaint', 'Cliente sensível — hospital menor', 'Prioridade máxima; plano de contingência.', 'in_progress', 'P1', 'EQ-GAMA', 'despacho.centro'),
    ('2026-9025', 'task', 'Calibração de medidor de campo (portátil)', 'Comparador laboratório móvel.', 'open', 'P3', 'EQ-ALPHA', 'marina.silva'),
    ('2026-9026', 'repair', 'Arco seco em isolador de pino', 'Troca de cadeia e limpeza.', 'open', 'P2', 'EQ-EPSILON', 'operador1'),
    ('2026-9027', 'complaint', 'Odor de queimado em trafo pad-mounted', 'Inspeção DGA amostra e ventilação.', 'in_progress', 'P1', 'EQ-BETA', 'despacho.centro'),
    ('2026-9028', 'task', 'Mapeamento térmico noturno linha MT', 'Drone / câmera — condições climáticas favoráveis.', 'scheduled', 'P3', 'EQ-DELTA', 'ana.miranda'),
    ('2026-9029', 'repair', 'Falha de bobina em TC', 'Substituição e ensaio de relação.', 'open', 'P1', 'EQ-ZETA', 'gilberto.nunes'),
    ('2026-9030', 'repair', 'Reforço de fundação de poste inclinado', 'Cunha e estai provisório.', 'scheduled', 'P2', 'EQ-GAMA', 'marina.silva')
) AS v(order_code, category, summary, description, status, priority, team_code, owner_username)
JOIN operations.team t ON t.team_code = v.team_code
JOIN security.users u ON u.username = v.owner_username
ON CONFLICT (order_code) DO UPDATE SET
    summary = EXCLUDED.summary,
    description = EXCLUDED.description,
    status = EXCLUDED.status,
    priority = EXCLUDED.priority,
    assigned_team_id = EXCLUDED.assigned_team_id,
    owner_id = EXCLUDED.owner_id,
    updated_at = CURRENT_TIMESTAMP;

-- Enriquecimento mínimo (espelha lógica do 06 para novas linhas)
UPDATE operations.work_order wo SET
    started_at = COALESCE(wo.started_at, wo.created_at),
    organization_label = COALESCE(wo.organization_label, 'UO RMSP — Operações'),
    municipality_name = COALESCE(wo.municipality_name, (ARRAY['São Paulo', 'Guarulhos', 'Osasco', 'Mauá', 'Santo André'])[((wo.id - 1) % 5) + 1]),
    neighborhood_name = COALESCE(wo.neighborhood_name, (ARRAY['Tatuapé', 'Vila Prudente', 'Pinheiros', 'Osasco Centro', 'Centro'])[((wo.id - 1) % 5) + 1]),
    equipment_code = COALESCE(wo.equipment_code, 'TR-' || (1000 + wo.id)::text),
    feeder_code = COALESCE(wo.feeder_code, 'AF-' || (7 + (wo.id % 5))::text),
    affected_customers_count = COALESCE(NULLIF(wo.affected_customers_count, 0), 15 + (wo.id % 95)),
    order_type = CASE
        WHEN wo.category = 'event' THEN 'event'
        ELSE CASE wo.category
            WHEN 'repair' THEN 'repair'
            WHEN 'task' THEN 'maintenance'
            WHEN 'complaint' THEN 'incident'
            ELSE COALESCE(NULLIF(btrim(COALESCE(wo.order_type, '')), ''), 'incident')
        END
    END,
    focus_lat = COALESCE(wo.focus_lat, -23.55 - (wo.id % 12) * 0.011),
    focus_lng = COALESCE(wo.focus_lng, -46.63 - (wo.id % 10) * 0.014),
    flag_safety_risk = COALESCE(wo.flag_safety_risk, (wo.id % 6) = 0),
    flag_critical_infra = COALESCE(wo.flag_critical_infra, (wo.id % 9) = 0),
    flag_customer_callback = COALESCE(wo.flag_customer_callback, wo.category = 'complaint'),
    priority_score = COALESCE(wo.priority_score, CASE wo.priority WHEN 'P1' THEN 1 WHEN 'P2' THEN 2 WHEN 'P3' THEN 3 ELSE 4 END),
    callback_auto = CASE WHEN wo.callback_auto IS NOT DISTINCT FROM FALSE THEN (wo.id % 5 = 0) ELSE wo.callback_auto END
WHERE wo.order_code ~ '^2026-90';

UPDATE operations.work_order wo SET complaints_linked_count = cnt FROM (
    SELECT work_order_id, COUNT(*)::int AS cnt FROM operations.work_order_complaint GROUP BY work_order_id
) s WHERE wo.id = s.work_order_id;
