DO $$
DECLARE
    en_id INTEGER;
    pt_id INTEGER;
    es_id INTEGER;
    it_id INTEGER;
BEGIN
    SELECT id INTO en_id FROM config.language WHERE code = 'en';
    SELECT id INTO pt_id FROM config.language WHERE code = 'pt';
    SELECT id INTO es_id FROM config.language WHERE code = 'es';
    SELECT id INTO it_id FROM config.language WHERE code = 'it';

    INSERT INTO config.translation (object_id, language_id, translated_text) VALUES
    ('UI_BTN_HOME_TITLE', en_id, 'Initial View (Capital)'),
    ('UI_BTN_HOME_TITLE', pt_id, 'Visão inicial (Capital)'),
    ('UI_BTN_HOME_TITLE', es_id, 'Vista inicial (Capital)'),
    ('UI_BTN_HOME_TITLE', it_id, 'Vista iniziale (Capitale)'),

    ('UI_MENU_SEARCH', en_id, 'Search'),
    ('UI_MENU_SEARCH', pt_id, 'Busca'),
    ('UI_MENU_SEARCH', es_id, 'Búsqueda'),
    ('UI_MENU_SEARCH', it_id, 'Ricerca'),

    ('UI_MENU_LAYERS', en_id, 'Layers'),
    ('UI_MENU_LAYERS', pt_id, 'Camadas'),
    ('UI_MENU_LAYERS', es_id, 'Capas'),
    ('UI_MENU_LAYERS', it_id, 'Livelli'),

    ('UI_BTN_OPERATION', en_id, 'Operation'),
    ('UI_BTN_OPERATION', pt_id, 'Operação'),
    ('UI_BTN_OPERATION', es_id, 'Operación'),
    ('UI_BTN_OPERATION', it_id, 'Operazione'),

    ('UI_SPLIT_CONTROL_CENTER', en_id, 'Control center'),
    ('UI_SPLIT_CONTROL_CENTER', pt_id, 'Centro de Controle'),
    ('UI_SPLIT_CONTROL_CENTER', es_id, 'Centro de control'),
    ('UI_SPLIT_CONTROL_CENTER', it_id, 'Centro di controllo'),

    ('UI_SPLIT_MAP', en_id, 'Map'),
    ('UI_SPLIT_MAP', pt_id, 'Mapa'),
    ('UI_SPLIT_MAP', es_id, 'Mapa'),
    ('UI_SPLIT_MAP', it_id, 'Mappa'),

    ('UI_SEARCH_MUNI_LABEL', en_id, 'Municipalities'),
    ('UI_SEARCH_MUNI_LABEL', pt_id, 'Municípios'),
    ('UI_SEARCH_MUNI_LABEL', es_id, 'Municipios'),
    ('UI_SEARCH_MUNI_LABEL', it_id, 'Comuni'),

    ('UI_SEARCH_NEIGHBORHOOD_LABEL', en_id, 'Neighborhoods'),
    ('UI_SEARCH_NEIGHBORHOOD_LABEL', pt_id, 'Bairros'),
    ('UI_SEARCH_NEIGHBORHOOD_LABEL', es_id, 'Barrios'),
    ('UI_SEARCH_NEIGHBORHOOD_LABEL', it_id, 'Quartieri'),

    ('UI_SEARCH_LOADING_MUNI', en_id, 'Loading municipalities…'),
    ('UI_SEARCH_LOADING_MUNI', pt_id, 'Carregando municípios…'),
    ('UI_SEARCH_LOADING_MUNI', es_id, 'Cargando municipios…'),
    ('UI_SEARCH_LOADING_MUNI', it_id, 'Caricamento comuni…'),

    ('UI_SEARCH_SELECT_MUNI', en_id, 'Select a municipality…'),
    ('UI_SEARCH_SELECT_MUNI', pt_id, 'Selecione um município…'),
    ('UI_SEARCH_SELECT_MUNI', es_id, 'Seleccione un municipio…'),
    ('UI_SEARCH_SELECT_MUNI', it_id, 'Seleziona un comune…'),

    ('UI_SEARCH_NEED_MUNI_FIRST', en_id, 'Select a municipality first…'),
    ('UI_SEARCH_NEED_MUNI_FIRST', pt_id, 'Selecione um município primeiro…'),
    ('UI_SEARCH_NEED_MUNI_FIRST', es_id, 'Seleccione primero un municipio…'),
    ('UI_SEARCH_NEED_MUNI_FIRST', it_id, 'Seleziona prima un comune…'),

    ('UI_SEARCH_LOADING_BAIRROS', en_id, 'Loading neighborhoods…'),
    ('UI_SEARCH_LOADING_BAIRROS', pt_id, 'Carregando bairros…'),
    ('UI_SEARCH_LOADING_BAIRROS', es_id, 'Cargando barrios…'),
    ('UI_SEARCH_LOADING_BAIRROS', it_id, 'Caricamento quartieri…'),

    ('UI_SEARCH_SELECT_BAIRRO', en_id, 'Select a neighborhood…'),
    ('UI_SEARCH_SELECT_BAIRRO', pt_id, 'Selecione um bairro…'),
    ('UI_SEARCH_SELECT_BAIRRO', es_id, 'Seleccione un barrio…'),
    ('UI_SEARCH_SELECT_BAIRRO', it_id, 'Seleziona un quartiere…'),

    ('UI_LAYER_GROUP_BACKGROUND', en_id, 'Background Image'),
    ('UI_LAYER_GROUP_BACKGROUND', pt_id, 'Imagem de fundo'),
    ('UI_LAYER_GROUP_BACKGROUND', es_id, 'Imagen de fondo'),
    ('UI_LAYER_GROUP_BACKGROUND', it_id, 'Immagine di sfondo'),

    ('UI_LAYER_SAT_ONLINE', en_id, 'Online Satellite'),
    ('UI_LAYER_SAT_ONLINE', pt_id, 'Satélite online'),
    ('UI_LAYER_SAT_ONLINE', es_id, 'Satélite en línea'),
    ('UI_LAYER_SAT_ONLINE', it_id, 'Satellite online'),

    ('UI_LAYER_SAT_LOCAL', en_id, 'Local Satellite'),
    ('UI_LAYER_SAT_LOCAL', pt_id, 'Satélite local'),
    ('UI_LAYER_SAT_LOCAL', es_id, 'Satélite local'),
    ('UI_LAYER_SAT_LOCAL', it_id, 'Satellite locale'),

    ('UI_LAYER_GROUP_ADMIN', en_id, 'Administrative Boundaries'),
    ('UI_LAYER_GROUP_ADMIN', pt_id, 'Limites administrativos'),
    ('UI_LAYER_GROUP_ADMIN', es_id, 'Límites administrativos'),
    ('UI_LAYER_GROUP_ADMIN', it_id, 'Confini amministrativi'),

    ('UI_LAYER_ADMIN_LIMITS', en_id, 'Municipal Boundaries'),
    ('UI_LAYER_ADMIN_LIMITS', pt_id, 'Limites Municipais'),
    ('UI_LAYER_ADMIN_LIMITS', es_id, 'Límites Municipales'),
    ('UI_LAYER_ADMIN_LIMITS', it_id, 'Confini Comunali'),

    ('UI_LAYER_ADMIN_MUNI', en_id, 'Municipalities'),
    ('UI_LAYER_ADMIN_MUNI', pt_id, 'Municípios'),
    ('UI_LAYER_ADMIN_MUNI', es_id, 'Municipios'),
    ('UI_LAYER_ADMIN_MUNI', it_id, 'Comuni'),

    ('UI_LAYER_ADMIN_NEIGHBORHOOD', en_id, 'Neighborhoods'),
    ('UI_LAYER_ADMIN_NEIGHBORHOOD', pt_id, 'Bairros'),
    ('UI_LAYER_ADMIN_NEIGHBORHOOD', es_id, 'Barrios'),
    ('UI_LAYER_ADMIN_NEIGHBORHOOD', it_id, 'Quartieri'),

    ('UI_LAYER_GROUP_OSM', en_id, 'OSM Roads'),
    ('UI_LAYER_GROUP_OSM', pt_id, 'Vias OSM'),
    ('UI_LAYER_GROUP_OSM', es_id, 'Vías OSM'),
    ('UI_LAYER_GROUP_OSM', it_id, 'Strade OSM'),

    ('UI_LAYER_OSM_ROADS', en_id, 'Roads'),
    ('UI_LAYER_OSM_ROADS', pt_id, 'Vias'),
    ('UI_LAYER_OSM_ROADS', es_id, 'Vías'),
    ('UI_LAYER_OSM_ROADS', it_id, 'Strade'),

    ('UI_STATUS_LANG_PREFIX', en_id, 'Session language changed to:'),
    ('UI_STATUS_LANG_PREFIX', pt_id, 'Idioma da sessão alterado para:'),
    ('UI_STATUS_LANG_PREFIX', es_id, 'Idioma de la sesión cambiado a:'),
    ('UI_STATUS_LANG_PREFIX', it_id, 'Lingua della sessione impostata su:'),

    ('UI_STATUS_LOADING', en_id, 'Loading map...'),
    ('UI_STATUS_LOADING', pt_id, 'Carregando mapa…'),
    ('UI_STATUS_LOADING', es_id, 'Cargando mapa…'),
    ('UI_STATUS_LOADING', it_id, 'Caricamento mappa…'),

    ('UI_PANEL_OP_TITLE', en_id, 'Operation Panel'),
    ('UI_PANEL_OP_TITLE', pt_id, 'Painel de Operação'),
    ('UI_PANEL_OP_TITLE', es_id, 'Panel de Operación'),
    ('UI_PANEL_OP_TITLE', it_id, 'Pannello Operativo'),

    ('UI_PANEL_OP_EMPTY', en_id, 'Network tools will appear here.'),
    ('UI_PANEL_OP_EMPTY', pt_id, 'Ferramentas de rede aparecerão aqui.'),
    ('UI_PANEL_OP_EMPTY', es_id, 'Herramientas de red aparecerán aquí.'),
    ('UI_PANEL_OP_EMPTY', it_id, 'Gli strumenti di rete appariranno qui.'),

    ('UI_OP_MOCK_BANNER', en_id, 'Mock panel — sample data'),
    ('UI_OP_MOCK_BANNER', pt_id, 'Painel mock — dados de exemplo'),
    ('UI_OP_MOCK_BANNER', es_id, 'Panel mock — datos de ejemplo'),
    ('UI_OP_MOCK_BANNER', it_id, 'Pannello mock — dati di esempio'),

    ('UI_OP_TAB_MWM', en_id, 'Field teams, routes & displacement'),
    ('UI_OP_TAB_MWM', pt_id, 'Equipas, rotas e deslocamentos'),
    ('UI_OP_TAB_MWM', es_id, 'Equipos, rutas y desplazamientos'),
    ('UI_OP_TAB_MWM', it_id, 'Squadre, percorsi e spostamenti'),

    ('UI_OP_TAB_OMS', en_id, 'Work orders'),
    ('UI_OP_TAB_OMS', pt_id, 'Ordens de serviço'),
    ('UI_OP_TAB_OMS', es_id, 'Órdenes de servicio'),
    ('UI_OP_TAB_OMS', it_id, 'Ordini di lavoro'),

    ('UI_OP_TAB_IND', en_id, 'Operational indicators'),
    ('UI_OP_TAB_IND', pt_id, 'Indicadores operacionais'),
    ('UI_OP_TAB_IND', es_id, 'Indicadores operativos'),
    ('UI_OP_TAB_IND', it_id, 'Indicatori operativi'),

    ('UI_OP_TAB_DMS', en_id, 'Remote telecontrol'),
    ('UI_OP_TAB_DMS', pt_id, 'Telecomando remoto'),
    ('UI_OP_TAB_DMS', es_id, 'Telecontrol remoto'),
    ('UI_OP_TAB_DMS', it_id, 'Telecomando remoto'),

    ('UI_OP_TAB_SMT', en_id, 'Installations & telemetry'),
    ('UI_OP_TAB_SMT', pt_id, 'Instalações e telemetria'),
    ('UI_OP_TAB_SMT', es_id, 'Instalaciones y telemetría'),
    ('UI_OP_TAB_SMT', it_id, 'Impianti e telemetria'),

    ('UI_OP_TAB_TMP', en_id, 'Weather & field operations'),
    ('UI_OP_TAB_TMP', pt_id, 'Clima e operações de campo'),
    ('UI_OP_TAB_TMP', es_id, 'Clima y operaciones de campo'),
    ('UI_OP_TAB_TMP', it_id, 'Clima e operazioni sul campo'),

    ('UI_OP_TAB_AUD', en_id, 'Audit & compliance'),
    ('UI_OP_TAB_AUD', pt_id, 'Auditoria e conformidade'),
    ('UI_OP_TAB_AUD', es_id, 'Auditoría y conformidad'),
    ('UI_OP_TAB_AUD', it_id, 'Audit e conformità'),

    ('UI_OP_TEAMS_TITLE', en_id, 'Team structure'),
    ('UI_OP_TEAMS_TITLE', pt_id, 'Estrutura de equipas'),
    ('UI_OP_TEAMS_TITLE', es_id, 'Estructura de equipos'),
    ('UI_OP_TEAMS_TITLE', it_id, 'Struttura squadre'),

    ('UI_OP_TEAMS_HINT', en_id, 'Teams, skills and location. Links to work orders and displacement times in the DB; full routes for the last 48h per team.'),
    ('UI_OP_TEAMS_HINT', pt_id, 'Equipas, competências e localização. Relacionamento com ordens e horários de deslocamento na BD; rotas completas das últimas 48h por equipa.'),
    ('UI_OP_TEAMS_HINT', es_id, 'Equipos, competencias y ubicación. Relación con órdenes y horarios de desplazamiento en la BD; rutas completas de las últimas 48h por equipo.'),
    ('UI_OP_TEAMS_HINT', it_id, 'Squadre, competenze e posizione. Collegamento a ordini e orari di spostamento nel DB; percorsi completi delle ultime 48h per squadra.'),

    ('UI_OP_COL_TEAM', en_id, 'Team'),
    ('UI_OP_COL_TEAM', pt_id, 'Equipa'),
    ('UI_OP_COL_TEAM', es_id, 'Equipo'),
    ('UI_OP_COL_TEAM', it_id, 'Squadra'),

    ('UI_OP_COL_LEADER', en_id, 'Lead'),
    ('UI_OP_COL_LEADER', pt_id, 'Líder'),
    ('UI_OP_COL_LEADER', es_id, 'Líder'),
    ('UI_OP_COL_LEADER', it_id, 'Capo'),

    ('UI_OP_COL_SKILL', en_id, 'Skill'),
    ('UI_OP_COL_SKILL', pt_id, 'Skill'),
    ('UI_OP_COL_SKILL', es_id, 'Skill'),
    ('UI_OP_COL_SKILL', it_id, 'Skill'),

    ('UI_OP_COL_TYPE', en_id, 'Type'),
    ('UI_OP_COL_TYPE', pt_id, 'Tipo'),
    ('UI_OP_COL_TYPE', es_id, 'Tipo'),
    ('UI_OP_COL_TYPE', it_id, 'Tipo'),

    ('UI_OP_COL_OWNER', en_id, 'Owner'),
    ('UI_OP_COL_OWNER', pt_id, 'Proprietário'),
    ('UI_OP_COL_OWNER', es_id, 'Propietario'),
    ('UI_OP_COL_OWNER', it_id, 'Proprietario'),

    ('UI_OP_COL_LAST_COORD', en_id, 'Last coordinate'),
    ('UI_OP_COL_LAST_COORD', pt_id, 'Últ. coordenada'),
    ('UI_OP_COL_LAST_COORD', es_id, 'Últ. coordenada'),
    ('UI_OP_COL_LAST_COORD', it_id, 'Ult. coordinata'),

    ('UI_OP_COL_LAST_UPDATE', en_id, 'Last update'),
    ('UI_OP_COL_LAST_UPDATE', pt_id, 'Últ. atualização'),
    ('UI_OP_COL_LAST_UPDATE', es_id, 'Últ. actualización'),
    ('UI_OP_COL_LAST_UPDATE', it_id, 'Ult. aggiornamento'),

    ('UI_OP_COL_ZONE', en_id, 'Zone'),
    ('UI_OP_COL_ZONE', pt_id, 'Zona'),
    ('UI_OP_COL_ZONE', es_id, 'Zona'),
    ('UI_OP_COL_ZONE', it_id, 'Zona'),

    ('UI_OP_COL_MEMBERS', en_id, 'Memb.'),
    ('UI_OP_COL_MEMBERS', pt_id, 'Memb.'),
    ('UI_OP_COL_MEMBERS', es_id, 'Miembr.'),
    ('UI_OP_COL_MEMBERS', it_id, 'Memb.'),

    ('UI_OP_COL_STATUS', en_id, 'Status'),
    ('UI_OP_COL_STATUS', pt_id, 'Estado'),
    ('UI_OP_COL_STATUS', es_id, 'Estado'),
    ('UI_OP_COL_STATUS', it_id, 'Stato'),

    ('UI_OP_STATUS_ACTIVE', en_id, 'Active'),
    ('UI_OP_STATUS_ACTIVE', pt_id, 'Activa'),
    ('UI_OP_STATUS_ACTIVE', es_id, 'Activa'),
    ('UI_OP_STATUS_ACTIVE', it_id, 'Attiva'),

    ('UI_OP_STATUS_STANDBY', en_id, 'Stand-by'),
    ('UI_OP_STATUS_STANDBY', pt_id, 'Stand-by'),
    ('UI_OP_STATUS_STANDBY', es_id, 'Stand-by'),
    ('UI_OP_STATUS_STANDBY', it_id, 'Stand-by'),

    ('UI_OP_GO_MAP', en_id, 'Go to map'),
    ('UI_OP_GO_MAP', pt_id, 'Ir para'),
    ('UI_OP_GO_MAP', es_id, 'Ir al mapa'),
    ('UI_OP_GO_MAP', it_id, 'Vai alla mappa'),

    ('UI_OP_STATUS_MAP_CENTERED', en_id, 'Map centred on team last known position (mock).'),
    ('UI_OP_STATUS_MAP_CENTERED', pt_id, 'Mapa centralizado na última posição conhecida da equipa (mock).'),
    ('UI_OP_STATUS_MAP_CENTERED', es_id, 'Mapa centrado en la última posición conocida del equipo (mock).'),
    ('UI_OP_STATUS_MAP_CENTERED', it_id, 'Mappa centrata sull’ultima posizione nota della squadra (mock).'),

    ('UI_OP_BTN_NEW_TEAM', en_id, '+ New team'),
    ('UI_OP_BTN_NEW_TEAM', pt_id, '+ Nova equipa'),
    ('UI_OP_BTN_NEW_TEAM', es_id, '+ Nuevo equipo'),
    ('UI_OP_BTN_NEW_TEAM', it_id, '+ Nuova squadra'),

    ('UI_OP_BTN_IMPORT', en_id, 'Import CSV'),
    ('UI_OP_BTN_IMPORT', pt_id, 'Importar CSV'),
    ('UI_OP_BTN_IMPORT', es_id, 'Importar CSV'),
    ('UI_OP_BTN_IMPORT', it_id, 'Importa CSV'),

    ('UI_OP_ORDERS_TITLE', en_id, 'Work orders'),
    ('UI_OP_ORDERS_TITLE', pt_id, 'Ordens'),
    ('UI_OP_ORDERS_TITLE', es_id, 'Órdenes'),
    ('UI_OP_ORDERS_TITLE', it_id, 'Ordini'),

    ('UI_OP_ORDERS_HINT', en_id, 'Tasks, repairs, complaints and events. Select a row to open detail — field structure to be defined.'),
    ('UI_OP_ORDERS_HINT', pt_id, 'Tarefas, reparos, reclamações e eventos. Ao seleccionar uma ordem abre-se o detalhe — estrutura de campos a definir.'),
    ('UI_OP_ORDERS_HINT', es_id, 'Tareas, reparaciones, reclamaciones y eventos. Al seleccionar una orden se abre el detalle.'),
    ('UI_OP_ORDERS_HINT', it_id, 'Compiti, riparazioni, reclami ed eventi. Selezionando un ordine si apre il dettaglio.'),

    ('UI_OP_COL_ORDER_CODE', en_id, 'Code'),
    ('UI_OP_COL_ORDER_CODE', pt_id, 'Código'),
    ('UI_OP_COL_ORDER_CODE', es_id, 'Código'),
    ('UI_OP_COL_ORDER_CODE', it_id, 'Codice'),

    ('UI_OP_COL_ORDER_CATEGORY', en_id, 'Category'),
    ('UI_OP_COL_ORDER_CATEGORY', pt_id, 'Categoria'),
    ('UI_OP_COL_ORDER_CATEGORY', es_id, 'Categoría'),
    ('UI_OP_COL_ORDER_CATEGORY', it_id, 'Categoria'),

    ('UI_OP_COL_ORDER_SUMMARY', en_id, 'Summary'),
    ('UI_OP_COL_ORDER_SUMMARY', pt_id, 'Resumo'),
    ('UI_OP_COL_ORDER_SUMMARY', es_id, 'Resumen'),
    ('UI_OP_COL_ORDER_SUMMARY', it_id, 'Riassunto'),

    ('UI_OP_COL_ORDER_STATUS', en_id, 'Status'),
    ('UI_OP_COL_ORDER_STATUS', pt_id, 'Estado'),
    ('UI_OP_COL_ORDER_STATUS', es_id, 'Estado'),
    ('UI_OP_COL_ORDER_STATUS', it_id, 'Stato'),

    ('UI_OP_CAT_REPAIR', en_id, 'Repair'),
    ('UI_OP_CAT_REPAIR', pt_id, 'Reparo'),
    ('UI_OP_CAT_REPAIR', es_id, 'Reparación'),
    ('UI_OP_CAT_REPAIR', it_id, 'Riparazione'),

    ('UI_OP_CAT_COMPLAINT', en_id, 'Complaint'),
    ('UI_OP_CAT_COMPLAINT', pt_id, 'Reclamação'),
    ('UI_OP_CAT_COMPLAINT', es_id, 'Reclamación'),
    ('UI_OP_CAT_COMPLAINT', it_id, 'Reclamo'),

    ('UI_OP_CAT_TASK', en_id, 'Task'),
    ('UI_OP_CAT_TASK', pt_id, 'Tarefa'),
    ('UI_OP_CAT_TASK', es_id, 'Tarea'),
    ('UI_OP_CAT_TASK', it_id, 'Attività'),

    ('UI_OP_CAT_EVENT', en_id, 'Event'),
    ('UI_OP_CAT_EVENT', pt_id, 'Evento'),
    ('UI_OP_CAT_EVENT', es_id, 'Evento'),
    ('UI_OP_CAT_EVENT', it_id, 'Evento'),

    ('UI_OP_ORDER_OPEN', en_id, 'Open'),
    ('UI_OP_ORDER_OPEN', pt_id, 'Aberta'),
    ('UI_OP_ORDER_OPEN', es_id, 'Abierta'),
    ('UI_OP_ORDER_OPEN', it_id, 'Aperta'),

    ('UI_OP_ORDER_PROGRESS', en_id, 'In progress'),
    ('UI_OP_ORDER_PROGRESS', pt_id, 'Em curso'),
    ('UI_OP_ORDER_PROGRESS', es_id, 'En curso'),
    ('UI_OP_ORDER_PROGRESS', it_id, 'In corso'),

    ('UI_OP_ORDER_SCHEDULED', en_id, 'Scheduled'),
    ('UI_OP_ORDER_SCHEDULED', pt_id, 'Agendada'),
    ('UI_OP_ORDER_SCHEDULED', es_id, 'Programada'),
    ('UI_OP_ORDER_SCHEDULED', it_id, 'Programmata'),

    ('UI_OP_ORDER_PLANNED', en_id, 'Planned'),
    ('UI_OP_ORDER_PLANNED', pt_id, 'Planeado'),
    ('UI_OP_ORDER_PLANNED', es_id, 'Planificado'),
    ('UI_OP_ORDER_PLANNED', it_id, 'Pianificato'),

    ('UI_OP_OPEN_DETAIL', en_id, 'Open'),
    ('UI_OP_OPEN_DETAIL', pt_id, 'Abrir'),
    ('UI_OP_OPEN_DETAIL', es_id, 'Abrir'),
    ('UI_OP_OPEN_DETAIL', it_id, 'Apri'),

    ('UI_OP_ORDER_DETAIL_TITLE', en_id, 'Order detail (mock)'),
    ('UI_OP_ORDER_DETAIL_TITLE', pt_id, 'Detalhe da ordem (mock)'),
    ('UI_OP_ORDER_DETAIL_TITLE', es_id, 'Detalle de la orden (mock)'),
    ('UI_OP_ORDER_DETAIL_TITLE', it_id, 'Dettaglio ordine (mock)'),

    ('UI_OP_DETAIL_DESCRIPTION', en_id, 'Description'),
    ('UI_OP_DETAIL_DESCRIPTION', pt_id, 'Descrição'),
    ('UI_OP_DETAIL_DESCRIPTION', es_id, 'Descripción'),
    ('UI_OP_DETAIL_DESCRIPTION', it_id, 'Descrizione'),

    ('UI_OP_DETAIL_PRIORITY', en_id, 'Priority'),
    ('UI_OP_DETAIL_PRIORITY', pt_id, 'Prioridade'),
    ('UI_OP_DETAIL_PRIORITY', es_id, 'Prioridad'),
    ('UI_OP_DETAIL_PRIORITY', it_id, 'Priorità'),

    ('UI_OP_DETAIL_CREATED', en_id, 'Created at'),
    ('UI_OP_DETAIL_CREATED', pt_id, 'Criada em'),
    ('UI_OP_DETAIL_CREATED', es_id, 'Creada el'),
    ('UI_OP_DETAIL_CREATED', it_id, 'Creata il'),

    ('UI_OP_DETAIL_ASSIGNED_TEAM', en_id, 'Assigned team'),
    ('UI_OP_DETAIL_ASSIGNED_TEAM', pt_id, 'Equipa atribuída'),
    ('UI_OP_DETAIL_ASSIGNED_TEAM', es_id, 'Equipo asignado'),
    ('UI_OP_DETAIL_ASSIGNED_TEAM', it_id, 'Squadra assegnata'),

    ('UI_OP_ORDER_DETAIL_HINT', en_id, 'Final fields will align with operations.work_order.'),
    ('UI_OP_ORDER_DETAIL_HINT', pt_id, 'Campos definitivos serão alinhados ao modelo operations.work_order.'),
    ('UI_OP_ORDER_DETAIL_HINT', es_id, 'Los campos finales se alinearán con operations.work_order.'),
    ('UI_OP_ORDER_DETAIL_HINT', it_id, 'I campi finali saranno allineati a operations.work_order.'),

    ('UI_OP_IND_TITLE', en_id, 'Indicators'),
    ('UI_OP_IND_TITLE', pt_id, 'Indicadores'),
    ('UI_OP_IND_TITLE', es_id, 'Indicadores'),
    ('UI_OP_IND_TITLE', it_id, 'Indicatori'),

    ('UI_OP_MODULE_AUDIT_NOTE', en_id, 'Module under construction. Changes and deletions in operational data are always recorded in Audit before removing rows from main tables.'),
    ('UI_OP_MODULE_AUDIT_NOTE', pt_id, 'Módulo em construção. Alterações e remoções em dados operacionais são sempre registadas em Auditoria antes de eliminar registos nas tabelas principais.'),
    ('UI_OP_MODULE_AUDIT_NOTE', es_id, 'Módulo en construcción. Los cambios y eliminaciones se registran en Auditoría antes de borrar filas principales.'),
    ('UI_OP_MODULE_AUDIT_NOTE', it_id, 'Modulo in costruzione. Modifiche ed eliminazioni sono registrate in Audit prima di rimuovere le righe principali.'),

    ('UI_OP_IND_PLACEHOLDER', en_id, 'KPIs and dashboards (mock) — see AUD tab for trails.'),
    ('UI_OP_IND_PLACEHOLDER', pt_id, 'KPIs e painéis (mock) — ver guia AUD para trilhas.'),
    ('UI_OP_IND_PLACEHOLDER', es_id, 'KPIs y paneles (mock) — ver AUD.'),
    ('UI_OP_IND_PLACEHOLDER', it_id, 'KPI e cruscotti (mock) — vedi AUD.'),

    ('UI_OP_DMS_TITLE', en_id, 'Telecontrol'),
    ('UI_OP_DMS_TITLE', pt_id, 'Telecomando'),
    ('UI_OP_DMS_TITLE', es_id, 'Telemando'),
    ('UI_OP_DMS_TITLE', it_id, 'Telecomando'),

    ('UI_OP_DMS_PLACEHOLDER', en_id, 'Devices and commands (mock).'),
    ('UI_OP_DMS_PLACEHOLDER', pt_id, 'Dispositivos e comandos (mock).'),
    ('UI_OP_DMS_PLACEHOLDER', es_id, 'Dispositivos y comandos (mock).'),
    ('UI_OP_DMS_PLACEHOLDER', it_id, 'Dispositivi e comandi (mock).'),

    ('UI_OP_SMT_TITLE', en_id, 'Installations & telemetry'),
    ('UI_OP_SMT_TITLE', pt_id, 'Instalações e telemetria'),
    ('UI_OP_SMT_TITLE', es_id, 'Instalaciones y telemetría'),
    ('UI_OP_SMT_TITLE', it_id, 'Impianti e telemetria'),

    ('UI_OP_SMT_PLACEHOLDER', en_id, 'Readings and alarms (mock).'),
    ('UI_OP_SMT_PLACEHOLDER', pt_id, 'Leituras e alarmes (mock).'),
    ('UI_OP_SMT_PLACEHOLDER', es_id, 'Lecturas y alarmas (mock).'),
    ('UI_OP_SMT_PLACEHOLDER', it_id, 'Letture e allarmi (mock).'),

    ('UI_OP_TMP_TITLE', en_id, 'Weather'),
    ('UI_OP_TMP_TITLE', pt_id, 'Clima'),
    ('UI_OP_TMP_TITLE', es_id, 'Clima'),
    ('UI_OP_TMP_TITLE', it_id, 'Meteo'),

    ('UI_OP_TMP_PLACEHOLDER', en_id, 'Weather constraints (mock).'),
    ('UI_OP_TMP_PLACEHOLDER', pt_id, 'Condicionantes meteorológicas (mock).'),
    ('UI_OP_TMP_PLACEHOLDER', es_id, 'Condicionantes meteorológicos (mock).'),
    ('UI_OP_TMP_PLACEHOLDER', it_id, 'Vincoli meteorologici (mock).'),

    ('UI_OP_AUD_TITLE', en_id, 'Audit'),
    ('UI_OP_AUD_TITLE', pt_id, 'Auditoria'),
    ('UI_OP_AUD_TITLE', es_id, 'Auditoría'),
    ('UI_OP_AUD_TITLE', it_id, 'Audit'),

    ('UI_OP_AUD_POLICY', en_id, 'Nothing is deleted from main operations tables without a prior copy to audit.operations_row_archive. Includes relevant trails from IND, DMS, SMT and TMP when applicable.'),
    ('UI_OP_AUD_POLICY', pt_id, 'Nada é apagado das tabelas principais do schema operations sem cópia prévia para audit.operations_row_archive. Inclui trilhas relevantes dos módulos IND, DMS, SMT e TMP quando aplicável.'),
    ('UI_OP_AUD_POLICY', es_id, 'No se borran filas principales del schema operations sin copia previa en audit.operations_row_archive.'),
    ('UI_OP_AUD_POLICY', it_id, 'Nulla viene eliminato dalle tabelle operations senza copia in audit.operations_row_archive.'),

    ('UI_OP_AUD_ARCHIVE_TITLE', en_id, 'Archived deleted rows (mock)'),
    ('UI_OP_AUD_ARCHIVE_TITLE', pt_id, 'Arquivo de linhas removidas (mock)'),
    ('UI_OP_AUD_ARCHIVE_TITLE', es_id, 'Archivo de filas eliminadas (mock)'),
    ('UI_OP_AUD_ARCHIVE_TITLE', it_id, 'Archivio righe rimosse (mock)'),

    ('UI_OP_AUD_COL_TABLE', en_id, 'Table'),
    ('UI_OP_AUD_COL_TABLE', pt_id, 'Tabela'),
    ('UI_OP_AUD_COL_TABLE', es_id, 'Tabla'),
    ('UI_OP_AUD_COL_TABLE', it_id, 'Tabella'),

    ('UI_OP_AUD_COL_ID', en_id, 'Source ID'),
    ('UI_OP_AUD_COL_ID', pt_id, 'ID origem'),
    ('UI_OP_AUD_COL_ID', es_id, 'ID origen'),
    ('UI_OP_AUD_COL_ID', it_id, 'ID origine'),

    ('UI_OP_AUD_COL_WHEN', en_id, 'Archived at'),
    ('UI_OP_AUD_COL_WHEN', pt_id, 'Arquivado em'),
    ('UI_OP_AUD_COL_WHEN', es_id, 'Archivado el'),
    ('UI_OP_AUD_COL_WHEN', it_id, 'Archiviato il'),

    ('UI_OP_AUD_COL_REASON', en_id, 'Reason'),
    ('UI_OP_AUD_COL_REASON', pt_id, 'Motivo'),
    ('UI_OP_AUD_COL_REASON', es_id, 'Motivo'),
    ('UI_OP_AUD_COL_REASON', it_id, 'Motivo'),

    ('UI_OP_AUD_REASON_MERGE', en_id, 'Team merge'),
    ('UI_OP_AUD_REASON_MERGE', pt_id, 'Fusão de equipas'),
    ('UI_OP_AUD_REASON_MERGE', es_id, 'Fusión de equipos'),
    ('UI_OP_AUD_REASON_MERGE', it_id, 'Fusione squadre'),

    ('UI_OP_REASON_CANCEL', en_id, 'Duplicate cancellation'),
    ('UI_OP_REASON_CANCEL', pt_id, 'Cancelamento duplicado'),
    ('UI_OP_REASON_CANCEL', es_id, 'Cancelación duplicada'),
    ('UI_OP_REASON_CANCEL', it_id, 'Annullamento duplicato'),

    ('UI_OP_AUD_TIMELINE_HINT', en_id, 'Full timeline from audit.parameter_history, audit.login_history and operations archive will be integrated via API.'),
    ('UI_OP_AUD_TIMELINE_HINT', pt_id, 'Linha temporal completa de audit.parameter_history, audit.login_history e arquivo operacional será integrada na API.'),
    ('UI_OP_AUD_TIMELINE_HINT', es_id, 'La línea temporal completa se integrará vía API.'),
    ('UI_OP_AUD_TIMELINE_HINT', it_id, 'La timeline completa sarà integrata via API.')

    ON CONFLICT (object_id, language_id) DO UPDATE SET translated_text = EXCLUDED.translated_text;
END $$;
