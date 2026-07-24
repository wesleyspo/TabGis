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

    ('UI_LAYER_GROUP_OMS_HEAT', en_id, 'OMS — heat map (aggregated orders)'),
    ('UI_LAYER_GROUP_OMS_HEAT', pt_id, 'OMS — mapa de calor (ordens agregadas)'),
    ('UI_LAYER_GROUP_OMS_HEAT', es_id, 'OMS — mapa de calor (pedidos agregados)'),
    ('UI_LAYER_GROUP_OMS_HEAT', it_id, 'OMS — mappa di calore (ordini aggregati)'),

    ('UI_LAYER_OMS_HEAT_NONE', en_id, 'Off (markers only)'),
    ('UI_LAYER_OMS_HEAT_NONE', pt_id, 'Desligado (só marcadores)'),
    ('UI_LAYER_OMS_HEAT_NONE', es_id, 'Desactivado (solo marcadores)'),
    ('UI_LAYER_OMS_HEAT_NONE', it_id, 'Spento (solo marcatori)'),

    ('UI_LAYER_OMS_HEAT_ORDERS', en_id, 'By order count'),
    ('UI_LAYER_OMS_HEAT_ORDERS', pt_id, 'Por quantidade de ordens'),
    ('UI_LAYER_OMS_HEAT_ORDERS', es_id, 'Por número de órdenes'),
    ('UI_LAYER_OMS_HEAT_ORDERS', it_id, 'Per numero ordini'),

    ('UI_LAYER_OMS_HEAT_CLIENTS', en_id, 'By affected customers'),
    ('UI_LAYER_OMS_HEAT_CLIENTS', pt_id, 'Por clientes afectados'),
    ('UI_LAYER_OMS_HEAT_CLIENTS', es_id, 'Por clientes afectados'),
    ('UI_LAYER_OMS_HEAT_CLIENTS', it_id, 'Per clienti coinvolti'),

    ('UI_LAYER_OMS_HEAT_DURATION', en_id, 'By open duration (hours)'),
    ('UI_LAYER_OMS_HEAT_DURATION', pt_id, 'Por duração aberta (horas)'),
    ('UI_LAYER_OMS_HEAT_DURATION', es_id, 'Por duración abierta (horas)'),
    ('UI_LAYER_OMS_HEAT_DURATION', it_id, 'Per ore aperte'),

    ('UI_LAYER_OMS_HEAT_PRIORITY', en_id, 'By priority score (sum)'),
    ('UI_LAYER_OMS_HEAT_PRIORITY', pt_id, 'Por prioridade (soma dos scores)'),
    ('UI_LAYER_OMS_HEAT_PRIORITY', es_id, 'Por prioridad (suma de scores)'),
    ('UI_LAYER_OMS_HEAT_PRIORITY', it_id, 'Per priorità (somma score)'),

    ('UI_LAYER_OMS_HEAT_HINT', en_id, 'Visible when zoomed out (aggregated grid). Requires OMS privilege.'),
    ('UI_LAYER_OMS_HEAT_HINT', pt_id, 'Visível com zoom afastado (grelha agregada). Requer privilégio OMS.'),
    ('UI_LAYER_OMS_HEAT_HINT', es_id, 'Visible con zoom alejado. Requiere privilegio OMS.'),
    ('UI_LAYER_OMS_HEAT_HINT', it_id, 'Visibile con zoom lontano. Richiede privilegio OMS.'),

    ('UI_LAYER_OMS_HEAT_METRIC', en_id, 'Metric'),
    ('UI_LAYER_OMS_HEAT_METRIC', pt_id, 'Métrica'),
    ('UI_LAYER_OMS_HEAT_METRIC', es_id, 'Métrica'),
    ('UI_LAYER_OMS_HEAT_METRIC', it_id, 'Metrica'),

    ('UI_OP_AGG_POPUP_CLIENTS', en_id, 'Affected customers'),
    ('UI_OP_AGG_POPUP_CLIENTS', pt_id, 'Clientes afectados'),
    ('UI_OP_AGG_POPUP_CLIENTS', es_id, 'Clientes afectados'),
    ('UI_OP_AGG_POPUP_CLIENTS', it_id, 'Clienti coinvolti'),

    ('UI_OP_AGG_POPUP_HOURS', en_id, 'Open hours (sum)'),
    ('UI_OP_AGG_POPUP_HOURS', pt_id, 'Horas abertas (soma)'),
    ('UI_OP_AGG_POPUP_HOURS', es_id, 'Horas abiertas (suma)'),
    ('UI_OP_AGG_POPUP_HOURS', it_id, 'Ore aperte (somma)'),

    ('UI_OP_AGG_POPUP_PRIORITY', en_id, 'Priority score (sum)'),
    ('UI_OP_AGG_POPUP_PRIORITY', pt_id, 'Score prioridade (soma)'),
    ('UI_OP_AGG_POPUP_PRIORITY', es_id, 'Score prioridad (suma)'),
    ('UI_OP_AGG_POPUP_PRIORITY', it_id, 'Score priorità (somma)'),

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

    ('UI_LAYER_GROUP_NETWORK', en_id, 'Utility network'),
    ('UI_LAYER_GROUP_NETWORK', pt_id, 'Rede técnica'),
    ('UI_LAYER_GROUP_NETWORK', es_id, 'Red técnica'),
    ('UI_LAYER_GROUP_NETWORK', it_id, 'Rete tecnica'),

    ('UI_LAYER_NETWORK_SPANS', en_id, 'Linear network segments'),
    ('UI_LAYER_NETWORK_SPANS', pt_id, 'Segmentos lineares da rede'),
    ('UI_LAYER_NETWORK_SPANS', es_id, 'Tramos lineales de red'),
    ('UI_LAYER_NETWORK_SPANS', it_id, 'Segmenti lineari di rete'),

    ('UI_LAYER_NETWORK_SPANS_HINT', en_id, 'Native PostGIS topology (gis.network_span) — shared topological nodes.'),
    ('UI_LAYER_NETWORK_SPANS_HINT', pt_id, 'Topologia nativa PostGIS (gis.network_span) — nós topológicos partilhados.'),
    ('UI_LAYER_NETWORK_SPANS_HINT', es_id, 'Topología nativa PostGIS (gis.network_span) — nodos topológicos compartidos.'),
    ('UI_LAYER_NETWORK_SPANS_HINT', it_id, 'Topologia nativa PostGIS (gis.network_span) — nodi topologici condivisi.'),

    ('UI_NETWORK_SPAN_DRAW_BTN', en_id, 'Draw segment'),
    ('UI_NETWORK_SPAN_DRAW_BTN', pt_id, 'Desenhar segmento'),
    ('UI_NETWORK_SPAN_DRAW_BTN', es_id, 'Dibujar tramo'),
    ('UI_NETWORK_SPAN_DRAW_BTN', it_id, 'Disegna segmento'),

    ('UI_NETWORK_SPAN_DRAW_TITLE', en_id, 'Click the map to add vertices; double-click or Enter finishes; Esc cancels.'),
    ('UI_NETWORK_SPAN_DRAW_TITLE', pt_id, 'Clique no mapa para adicionar vértices; duplo clique ou Enter conclui; Esc cancela.'),
    ('UI_NETWORK_SPAN_DRAW_TITLE', es_id, 'Haga clic en el mapa para añadir vértices; doble clic o Enter termina; Esc cancela.'),
    ('UI_NETWORK_SPAN_DRAW_TITLE', it_id, 'Clicca sulla mappa per aggiungere vertici; doppio clic o Invio conclude; Esc annulla.'),

    ('UI_NETWORK_SPAN_DRAW_HINT', en_id, 'Segment drawing: click adds a vertex; double-click or Enter finishes; Esc cancels.'),
    ('UI_NETWORK_SPAN_DRAW_HINT', pt_id, 'Desenho de segmento: clique adiciona vértice; duplo clique ou Enter conclui; Esc cancela.'),
    ('UI_NETWORK_SPAN_DRAW_HINT', es_id, 'Dibujo de tramo: clic añade vértice; doble clic o Enter termina; Esc cancela.'),
    ('UI_NETWORK_SPAN_DRAW_HINT', it_id, 'Disegno segmento: clic aggiunge un vertice; doppio clic o Invio conclude; Esc annulla.'),

    ('UI_NETWORK_SPAN_DRAW_CANCEL', en_id, 'Cancel drawing (Esc)'),
    ('UI_NETWORK_SPAN_DRAW_CANCEL', pt_id, 'Cancelar desenho (Esc)'),
    ('UI_NETWORK_SPAN_DRAW_CANCEL', es_id, 'Cancelar dibujo (Esc)'),
    ('UI_NETWORK_SPAN_DRAW_CANCEL', it_id, 'Annulla disegno (Esc)'),

    ('UI_NETWORK_SPAN_DRAW_CANCELLED', en_id, 'Segment drawing cancelled.'),
    ('UI_NETWORK_SPAN_DRAW_CANCELLED', pt_id, 'Desenho de segmento cancelado.'),
    ('UI_NETWORK_SPAN_DRAW_CANCELLED', es_id, 'Dibujo de tramo cancelado.'),
    ('UI_NETWORK_SPAN_DRAW_CANCELLED', it_id, 'Disegno segmento annullato.'),

    ('UI_NETWORK_SPAN_DRAW_SAVED', en_id, 'Segment saved:'),
    ('UI_NETWORK_SPAN_DRAW_SAVED', pt_id, 'Segmento gravado:'),
    ('UI_NETWORK_SPAN_DRAW_SAVED', es_id, 'Tramo guardado:'),
    ('UI_NETWORK_SPAN_DRAW_SAVED', it_id, 'Segmento salvato:'),

    ('UI_NETWORK_SPAN_DRAW_NEED2', en_id, 'At least 2 vertices are required to save the segment.'),
    ('UI_NETWORK_SPAN_DRAW_NEED2', pt_id, 'São precisos pelo menos 2 vértices para gravar o segmento.'),
    ('UI_NETWORK_SPAN_DRAW_NEED2', es_id, 'Se necesitan al menos 2 vértices para guardar el tramo.'),
    ('UI_NETWORK_SPAN_DRAW_NEED2', it_id, 'Servono almeno 2 vertici per salvare il segmento.'),

    ('UI_NETWORK_SPAN_DRAW_DESC', en_id, 'Segment created by drawing on the map.'),
    ('UI_NETWORK_SPAN_DRAW_DESC', pt_id, 'Segmento criado por desenho no mapa.'),
    ('UI_NETWORK_SPAN_DRAW_DESC', es_id, 'Tramo creado dibujando en el mapa.'),
    ('UI_NETWORK_SPAN_DRAW_DESC', it_id, 'Segmento creato disegnando sulla mappa.'),

    ('UI_OP_MWM_ROUTES_48H_LOADING', en_id, 'Loading operational routes (48 h)…'),
    ('UI_OP_MWM_ROUTES_48H_LOADING', pt_id, 'A carregar rotas operacionais (48 h)…'),
    ('UI_OP_MWM_ROUTES_48H_LOADING', es_id, 'Cargando rutas operativas (48 h)…'),
    ('UI_OP_MWM_ROUTES_48H_LOADING', it_id, 'Caricamento percorsi operativi (48 h)…'),

    ('UI_OP_MWM_ROUTES_48H_SUMMARY', en_id, 'Operational routes (last {hours} h): {count} track(s), ~{km} km.'),
    ('UI_OP_MWM_ROUTES_48H_SUMMARY', pt_id, 'Rotas operacionais (últimas {hours} h): {count} traçado(s), ~{km} km.'),
    ('UI_OP_MWM_ROUTES_48H_SUMMARY', es_id, 'Rutas operativas (últimas {hours} h): {count} trazado(s), ~{km} km.'),
    ('UI_OP_MWM_ROUTES_48H_SUMMARY', it_id, 'Percorsi operativi (ultime {hours} h): {count} tracciato/i, ~{km} km.'),

    ('UI_OP_MWM_ROUTES_48H_FAIL', en_id, 'Failed to load 48 h routes. Check the API and docs/mds/OPERATIONS_MWM.md.'),
    ('UI_OP_MWM_ROUTES_48H_FAIL', pt_id, 'Falha ao carregar rotas 48 h. Verifique a API e docs/mds/OPERATIONS_MWM.md.'),
    ('UI_OP_MWM_ROUTES_48H_FAIL', es_id, 'Error al cargar rutas 48 h. Verifique la API y docs/mds/OPERATIONS_MWM.md.'),
    ('UI_OP_MWM_ROUTES_48H_FAIL', it_id, 'Errore nel caricamento percorsi 48 h. Verificare API e docs/mds/OPERATIONS_MWM.md.'),

    ('UI_OP_MWM_ROUTES_48H_FORBIDDEN', en_id, 'Missing privilege to query operational routes (module.mwm).'),
    ('UI_OP_MWM_ROUTES_48H_FORBIDDEN', pt_id, 'Sem privilégio para consultar rotas operacionais (module.mwm).'),
    ('UI_OP_MWM_ROUTES_48H_FORBIDDEN', es_id, 'Sin privilegio para consultar rutas operativas (module.mwm).'),
    ('UI_OP_MWM_ROUTES_48H_FORBIDDEN', it_id, 'Privilegio mancante per consultare percorsi operativi (module.mwm).'),

    ('UI_OP_MWM_ROUTE_OP_POPUP', en_id, 'Operational route (48 h)'),
    ('UI_OP_MWM_ROUTE_OP_POPUP', pt_id, 'Rota operacional (48 h)'),
    ('UI_OP_MWM_ROUTE_OP_POPUP', es_id, 'Ruta operativa (48 h)'),
    ('UI_OP_MWM_ROUTE_OP_POPUP', it_id, 'Percorso operativo (48 h)'),

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

    ('UI_OP_TAB_USR', en_id, 'Users'),
    ('UI_OP_TAB_USR', pt_id, 'Utilizadores'),
    ('UI_OP_TAB_USR', es_id, 'Usuarios'),
    ('UI_OP_TAB_USR', it_id, 'Utenti'),

    ('UI_OP_API_LIVE_BANNER', en_id, 'Data: API → operations.work_order'),
    ('UI_OP_API_LIVE_BANNER', pt_id, 'Dados: API → operations.work_order'),
    ('UI_OP_API_LIVE_BANNER', es_id, 'Datos: API → operations.work_order'),
    ('UI_OP_API_LIVE_BANNER', it_id, 'Dati: API → operations.work_order'),

    ('UI_OP_API_USERS_BANNER', en_id, 'Data: API → security.users'),
    ('UI_OP_API_USERS_BANNER', pt_id, 'Dados: API → security.users'),
    ('UI_OP_API_USERS_BANNER', es_id, 'Datos: API → security.users'),
    ('UI_OP_API_USERS_BANNER', it_id, 'Dati: API → security.users'),

    ('UI_OP_USERS_TITLE', en_id, 'Users'),
    ('UI_OP_USERS_TITLE', pt_id, 'Utilizadores'),
    ('UI_OP_USERS_TITLE', es_id, 'Usuarios'),
    ('UI_OP_USERS_TITLE', it_id, 'Utenti'),

    ('UI_OP_USERS_HINT', en_id, 'Minimal directory for owner_id and locked_by_id on orders (POC, no auth).'),
    ('UI_OP_USERS_HINT', pt_id, 'Cadastro mínimo para owner_id e locked_by_id nas ordens (POC sem autenticação).'),
    ('UI_OP_USERS_HINT', es_id, 'Registro mínimo para owner_id y locked_by_id en órdenes (POC sin autenticación).'),
    ('UI_OP_USERS_HINT', it_id, 'Anagrafica minima per owner_id e locked_by_id sugli ordini (POC senza auth).'),

    ('UI_OP_COL_ORDER_OWNER', en_id, 'Owner (user)'),
    ('UI_OP_COL_ORDER_OWNER', pt_id, 'Responsável'),
    ('UI_OP_COL_ORDER_OWNER', es_id, 'Responsable'),
    ('UI_OP_COL_ORDER_OWNER', it_id, 'Responsabile'),

    ('UI_OP_COL_USERNAME', en_id, 'Username'),
    ('UI_OP_COL_USERNAME', pt_id, 'Utilizador'),
    ('UI_OP_COL_USERNAME', es_id, 'Usuario'),
    ('UI_OP_COL_USERNAME', it_id, 'Utente'),

    ('UI_OP_COL_EMAIL', en_id, 'Email'),
    ('UI_OP_COL_EMAIL', pt_id, 'E-mail'),
    ('UI_OP_COL_EMAIL', es_id, 'Correo'),
    ('UI_OP_COL_EMAIL', it_id, 'E-mail'),

    ('UI_OP_COL_ACCESS', en_id, 'Role'),
    ('UI_OP_COL_ACCESS', pt_id, 'Perfil'),
    ('UI_OP_COL_ACCESS', es_id, 'Perfil'),
    ('UI_OP_COL_ACCESS', it_id, 'Profilo'),

    ('UI_OP_COL_USER_STATUS', en_id, 'Status'),
    ('UI_OP_COL_USER_STATUS', pt_id, 'Estado'),
    ('UI_OP_COL_USER_STATUS', es_id, 'Estado'),
    ('UI_OP_COL_USER_STATUS', it_id, 'Stato'),

    ('UI_OP_DETAIL_OWNER', en_id, 'Owner (owner_id)'),
    ('UI_OP_DETAIL_OWNER', pt_id, 'Responsável (owner)'),
    ('UI_OP_DETAIL_OWNER', es_id, 'Responsable (owner)'),
    ('UI_OP_DETAIL_OWNER', it_id, 'Responsabile (owner)'),

    ('UI_OP_DETAIL_LOCKED_BY', en_id, 'Edit lock'),
    ('UI_OP_DETAIL_LOCKED_BY', pt_id, 'Bloqueio de edição'),
    ('UI_OP_DETAIL_LOCKED_BY', es_id, 'Bloqueo de edición'),
    ('UI_OP_DETAIL_LOCKED_BY', it_id, 'Blocco modifica'),

    ('UI_OP_BTN_ASSUME_LOCK', en_id, 'Reserve for editing'),
    ('UI_OP_BTN_ASSUME_LOCK', pt_id, 'Reservar edição'),
    ('UI_OP_BTN_ASSUME_LOCK', es_id, 'Reservar edición'),
    ('UI_OP_BTN_ASSUME_LOCK', it_id, 'Riserva modifica'),

    ('UI_OP_BTN_RELEASE_LOCK', en_id, 'Release edit reservation'),
    ('UI_OP_BTN_RELEASE_LOCK', pt_id, 'Libertar edição'),
    ('UI_OP_BTN_RELEASE_LOCK', es_id, 'Liberar edición'),
    ('UI_OP_BTN_RELEASE_LOCK', it_id, 'Rilascia modifica'),

    ('UI_OP_BTN_ADD_USER', en_id, 'Add'),
    ('UI_OP_BTN_ADD_USER', pt_id, 'Adicionar'),
    ('UI_OP_BTN_ADD_USER', es_id, 'Añadir'),
    ('UI_OP_BTN_ADD_USER', it_id, 'Aggiungi'),

    ('UI_OP_PLACEHOLDER_USERNAME', en_id, 'username'),
    ('UI_OP_PLACEHOLDER_USERNAME', pt_id, 'utilizador'),
    ('UI_OP_PLACEHOLDER_USERNAME', es_id, 'usuario'),
    ('UI_OP_PLACEHOLDER_USERNAME', it_id, 'utente'),

    ('UI_OP_PLACEHOLDER_EMAIL', en_id, 'email'),
    ('UI_OP_PLACEHOLDER_EMAIL', pt_id, 'e-mail'),
    ('UI_OP_PLACEHOLDER_EMAIL', es_id, 'correo'),
    ('UI_OP_PLACEHOLDER_EMAIL', it_id, 'e-mail'),

    ('UI_OP_PLACEHOLDER_FIRST', en_id, 'first name'),
    ('UI_OP_PLACEHOLDER_FIRST', pt_id, 'nome'),
    ('UI_OP_PLACEHOLDER_FIRST', es_id, 'nombre'),
    ('UI_OP_PLACEHOLDER_FIRST', it_id, 'nome'),

    ('UI_OP_PLACEHOLDER_LAST', en_id, 'last name'),
    ('UI_OP_PLACEHOLDER_LAST', pt_id, 'apelido'),
    ('UI_OP_PLACEHOLDER_LAST', es_id, 'apellido'),
    ('UI_OP_PLACEHOLDER_LAST', it_id, 'cognome'),

    ('UI_OP_STATUS_LOADING_ORDERS', en_id, 'Loading work orders…'),
    ('UI_OP_STATUS_LOADING_ORDERS', pt_id, 'A carregar ordens…'),
    ('UI_OP_STATUS_LOADING_ORDERS', es_id, 'Cargando órdenes…'),
    ('UI_OP_STATUS_LOADING_ORDERS', it_id, 'Caricamento ordini…'),

    ('UI_OP_STATUS_LOADING_USERS', en_id, 'Loading users…'),
    ('UI_OP_STATUS_LOADING_USERS', pt_id, 'A carregar utilizadores…'),
    ('UI_OP_STATUS_LOADING_USERS', es_id, 'Cargando usuarios…'),
    ('UI_OP_STATUS_LOADING_USERS', it_id, 'Caricamento utenti…'),

    ('UI_OP_NO_ORDERS', en_id, 'No work orders in database.'),
    ('UI_OP_NO_ORDERS', pt_id, 'Sem ordens na base.'),
    ('UI_OP_NO_ORDERS', es_id, 'Sin órdenes en la base.'),
    ('UI_OP_NO_ORDERS', it_id, 'Nessun ordine nel database.'),

    ('UI_OP_LOCK_OK', en_id, 'Edit reservation active.'),
    ('UI_OP_LOCK_OK', pt_id, 'Edição reservada.'),
    ('UI_OP_LOCK_OK', es_id, 'Edición reservada.'),
    ('UI_OP_LOCK_OK', it_id, 'Modifica riservata.'),

    ('UI_OP_LOCK_RELEASED', en_id, 'Edit reservation released.'),
    ('UI_OP_LOCK_RELEASED', pt_id, 'Reserva de edição libertada.'),
    ('UI_OP_LOCK_RELEASED', es_id, 'Reserva de edición liberada.'),
    ('UI_OP_LOCK_RELEASED', it_id, 'Prenotazione modifica rilasciata.'),

    ('UI_OP_STATUS_LOADING_TEAMS', en_id, 'Loading field teams…'),
    ('UI_OP_STATUS_LOADING_TEAMS', pt_id, 'A carregar equipas…'),
    ('UI_OP_STATUS_LOADING_TEAMS', es_id, 'Cargando equipos…'),
    ('UI_OP_STATUS_LOADING_TEAMS', it_id, 'Caricamento squadre…'),

    ('UI_OP_NO_TEAMS', en_id, 'No teams registered.'),
    ('UI_OP_NO_TEAMS', pt_id, 'Sem equipas registadas.'),
    ('UI_OP_NO_TEAMS', es_id, 'Sin equipos registrados.'),
    ('UI_OP_NO_TEAMS', it_id, 'Nessuna squadra registrata.'),

    ('UI_OP_STATUS_LOADING_AUDIT', en_id, 'Loading audit archive…'),
    ('UI_OP_STATUS_LOADING_AUDIT', pt_id, 'A carregar arquivo…'),
    ('UI_OP_STATUS_LOADING_AUDIT', es_id, 'Cargando archivo…'),
    ('UI_OP_STATUS_LOADING_AUDIT', it_id, 'Caricamento archivio…'),

    ('UI_OP_AUD_EMPTY', en_id, 'No pre-delete archive rows yet.'),
    ('UI_OP_AUD_EMPTY', pt_id, 'Nenhum registo de arquivo pré-delete.'),
    ('UI_OP_AUD_EMPTY', es_id, 'Sin filas de archivo previas al borrado.'),
    ('UI_OP_AUD_EMPTY', it_id, 'Nessuna riga in archivio pre-cancellazione.'),

    ('UI_OP_USER_CREATED', en_id, 'User created.'),
    ('UI_OP_USER_CREATED', pt_id, 'Utilizador criado.'),
    ('UI_OP_USER_CREATED', es_id, 'Usuario creado.'),
    ('UI_OP_USER_CREATED', it_id, 'Utente creato.'),

    ('UI_OP_USER_CREATE_FAIL', en_id, 'Could not create user (duplicate username?).'),
    ('UI_OP_USER_CREATE_FAIL', pt_id, 'Não foi possível criar (username duplicado?).'),
    ('UI_OP_USER_CREATE_FAIL', es_id, 'No se pudo crear (¿usuario duplicado?).'),
    ('UI_OP_USER_CREATE_FAIL', it_id, 'Impossibile creare (username duplicato?).'),

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

    ('UI_OP_TAB_ESQ', en_id, 'Schematic, one-line & power flow'),
    ('UI_OP_TAB_ESQ', pt_id, 'Esquemático, unifilar e fluxo'),
    ('UI_OP_TAB_ESQ', es_id, 'Esquemático, unifilar y flujo'),
    ('UI_OP_TAB_ESQ', it_id, 'Schema, unifilare e flusso'),

    ('UI_OP_ESQ_TITLE', en_id, 'Network schematic'),
    ('UI_OP_ESQ_TITLE', pt_id, 'Esquemático de rede'),
    ('UI_OP_ESQ_TITLE', es_id, 'Esquemático de red'),
    ('UI_OP_ESQ_TITLE', it_id, 'Schematico di rete'),

    ('UI_OP_ESQ_HINT', en_id, 'Static, sequential one-line and qualitative power-flow labels. Each object has a geographic focus for «Go to map».'),
    ('UI_OP_ESQ_HINT', pt_id, 'Unifilar estático e sequencial com indicação qualitativa de potência. Cada elemento dispõe de coordenadas de foco para «Ir para o mapa».'),
    ('UI_OP_ESQ_HINT', es_id, 'Unifilar estático y secuencial. Cada elemento tiene enfoque geográfico para «Ir al mapa».'),
    ('UI_OP_ESQ_HINT', it_id, 'Unifilare statico; ogni elemento ha un punto per «Vai alla mappa».'),

    ('UI_OP_ESQ_SELECT_VIEW', en_id, 'Schematic view'),
    ('UI_OP_ESQ_SELECT_VIEW', pt_id, 'Vista esquemática'),
    ('UI_OP_ESQ_SELECT_VIEW', es_id, 'Vista esquemática'),
    ('UI_OP_ESQ_SELECT_VIEW', it_id, 'Vista schematica'),

    ('UI_OP_ESQ_P_KW', en_id, 'P (kW)'),
    ('UI_OP_ESQ_P_KW', pt_id, 'P (kW)'),
    ('UI_OP_ESQ_P_KW', es_id, 'P (kW)'),
    ('UI_OP_ESQ_P_KW', it_id, 'P (kW)'),

    ('UI_OP_ESQ_Q_KVAR', en_id, 'Q (kVAr)'),
    ('UI_OP_ESQ_Q_KVAR', pt_id, 'Q (kVAr)'),
    ('UI_OP_ESQ_Q_KVAR', es_id, 'Q (kVAr)'),
    ('UI_OP_ESQ_Q_KVAR', it_id, 'Q (kVAr)'),

    ('UI_OP_ESQ_NO_VIEWS', en_id, 'No schematic views (apply SQL migration 16 and seed).'),
    ('UI_OP_ESQ_NO_VIEWS', pt_id, 'Sem vistas esquemáticas (aplique infra/sql/16_schematic_schema.sql e os dados de demonstração).'),
    ('UI_OP_ESQ_NO_VIEWS', es_id, 'Sin vistas (aplique la migración SQL 16).'),
    ('UI_OP_ESQ_NO_VIEWS', it_id, 'Nessuna vista (migrazione SQL 16).'),

    ('UI_OP_ESQ_LOAD_FAIL', en_id, 'Failed to load schematic from API'),
    ('UI_OP_ESQ_LOAD_FAIL', pt_id, 'Falha ao carregar o esquemático'),
    ('UI_OP_ESQ_LOAD_FAIL', es_id, 'Error al cargar el esquemático'),
    ('UI_OP_ESQ_LOAD_FAIL', it_id, 'Caricamento schematico fallito'),

    ('UI_OP_STATUS_LOADING_SCHEMATIC', en_id, 'Loading schematic…'),
    ('UI_OP_STATUS_LOADING_SCHEMATIC', pt_id, 'A carregar o esquemático…'),
    ('UI_OP_STATUS_LOADING_SCHEMATIC', es_id, 'Cargando esquemático…'),
    ('UI_OP_STATUS_LOADING_SCHEMATIC', it_id, 'Caricamento schematico…'),

    ('UI_OP_STATUS_SCHEMATIC_NO_COORD', en_id, 'This object has no map focus coordinates.'),
    ('UI_OP_STATUS_SCHEMATIC_NO_COORD', pt_id, 'Este elemento não tem coordenadas de foco para o mapa.'),
    ('UI_OP_STATUS_SCHEMATIC_NO_COORD', es_id, 'Sin coordenadas de mapa para este elemento.'),
    ('UI_OP_STATUS_SCHEMATIC_NO_COORD', it_id, 'Nessun punto di mappa per questo elemento.'),

    ('UI_OP_STATUS_SCHEMATIC_MAP', en_id, 'Operational view: focus from the schematic (neighbourhoods and streets on).'),
    ('UI_OP_STATUS_SCHEMATIC_MAP', pt_id, 'Vista operacional: foco a partir do esquemático (bairros e vias activos).'),
    ('UI_OP_STATUS_SCHEMATIC_MAP', es_id, 'Vista operativa: enfoque desde el esquemático (barrios y vías).'),
    ('UI_OP_STATUS_SCHEMATIC_MAP', it_id, 'Vista operativa: foco dallo sch. unif. (quartieri e strade).'),

    ('UI_OP_STATUS_SCHEMATIC_MAP_GIS', en_id, 'Operational view: focus from gis.equipment geometry (neighbourhoods and streets on).'),
    ('UI_OP_STATUS_SCHEMATIC_MAP_GIS', pt_id, 'Vista operacional: foco a partir da geometria em gis.equipment (bairros e vias activos).'),
    ('UI_OP_STATUS_SCHEMATIC_MAP_GIS', es_id, 'Vista operativa: enfoque desde la geometría en gis.equipment (barrios y vías).'),
    ('UI_OP_STATUS_SCHEMATIC_MAP_GIS', it_id, 'Vista operativa: fuoco dalla geometria gis.equipment (quartieri e strade).'),

    ('UI_OP_ESQ_MAP_TOOLTIP', en_id, 'Focus: schematic node coordinates.'),
    ('UI_OP_ESQ_MAP_TOOLTIP', pt_id, 'Foco: coordenadas do nó do esquemático.'),
    ('UI_OP_ESQ_MAP_TOOLTIP', es_id, 'Enfoque: coordenadas del nodo del esquema.'),
    ('UI_OP_ESQ_MAP_TOOLTIP', it_id, 'Focus: coordinate del nodo schematico.'),

    ('UI_OP_ESQ_MAP_TOOLTIP_GIS', en_id, 'Focus: gis.equipment inventory geometry.'),
    ('UI_OP_ESQ_MAP_TOOLTIP_GIS', pt_id, 'Foco: geometria do equipamento em gis.equipment (inventário).'),
    ('UI_OP_ESQ_MAP_TOOLTIP_GIS', es_id, 'Enfoque: geometría del equipo en gis.equipment.'),
    ('UI_OP_ESQ_MAP_TOOLTIP_GIS', it_id, 'Focus: geometria equipaggio in gis.equipment.'),

    ('UI_OP_TAB_TMP', en_id, 'Weather & field operations'),
    ('UI_OP_TAB_TMP', pt_id, 'Clima e operações de campo'),
    ('UI_OP_TAB_TMP', es_id, 'Clima y operaciones de campo'),
    ('UI_OP_TAB_TMP', it_id, 'Clima e operazioni sul campo'),

    ('UI_OP_TAB_AUD', en_id, 'Audit & compliance'),
    ('UI_OP_TAB_AUD', pt_id, 'Auditoria e conformidade'),
    ('UI_OP_TAB_AUD', es_id, 'Auditoría y conformidad'),
    ('UI_OP_TAB_AUD', it_id, 'Audit e conformità'),

    ('UI_OP_TEAMS_TITLE', en_id, 'Field teams'),
    ('UI_OP_TEAMS_TITLE', pt_id, 'Equipas em campo'),
    ('UI_OP_TEAMS_TITLE', es_id, 'Equipos de campo'),
    ('UI_OP_TEAMS_TITLE', it_id, 'Squadre sul campo'),

    ('UI_OP_TEAMS_HINT', en_id, 'Latest reported position per team. Use «Go to map» to centre the operational view on the last known coordinates.'),
    ('UI_OP_TEAMS_HINT', pt_id, 'Posição mais recente reportada por equipa. Utilize «Ir para o mapa» para centrar a vista operacional na última coordenada conhecida.'),
    ('UI_OP_TEAMS_HINT', es_id, 'Última posición reportada por equipo. Use «Ir al mapa» para centrar la vista operativa.'),
    ('UI_OP_TEAMS_HINT', it_id, 'Ultima posizione riportata per squadra. Usa «Vai alla mappa» per centrare la vista.'),

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

    ('UI_OP_STATUS_MAP_CENTERED', en_id, 'Map centred on the team last known position.'),
    ('UI_OP_STATUS_MAP_CENTERED', pt_id, 'Mapa centrado na última posição conhecida da equipa.'),
    ('UI_OP_STATUS_MAP_CENTERED', es_id, 'Mapa centrado en la última posición conocida del equipo.'),
    ('UI_OP_STATUS_MAP_CENTERED', it_id, 'Mappa centrata sull’ultima posizione nota della squadra.'),

    ('UI_OP_BTN_NEW_TEAM', en_id, '+ New team'),
    ('UI_OP_BTN_NEW_TEAM', pt_id, '+ Nova equipa'),
    ('UI_OP_BTN_NEW_TEAM', es_id, '+ Nuevo equipo'),
    ('UI_OP_BTN_NEW_TEAM', it_id, '+ Nuova squadra'),

    ('UI_OP_BTN_IMPORT', en_id, 'Import CSV'),
    ('UI_OP_BTN_IMPORT', pt_id, 'Importar CSV'),
    ('UI_OP_BTN_IMPORT', es_id, 'Importar CSV'),
    ('UI_OP_BTN_IMPORT', it_id, 'Importa CSV'),

    ('UI_OP_ORDERS_TITLE', en_id, 'Work orders'),
    ('UI_OP_ORDERS_TITLE', pt_id, 'Ordens de serviço'),
    ('UI_OP_ORDERS_TITLE', es_id, 'Órdenes de servicio'),
    ('UI_OP_ORDERS_TITLE', it_id, 'Ordini di lavoro'),

    ('UI_OP_ORDERS_HINT', en_id, 'Active work orders (events excluded). Single click: detail in the panel; double-click or Ctrl+Enter: order sheet (tasks and complaints). The toolbar next to Operation sets map layout (ops focus / 50-50). Markers reflect type, team and status.'),
    ('UI_OP_ORDERS_HINT', pt_id, 'Ordens ativas (sem eventos). Clique simples: detalhe no painel; duplo clique ou Ctrl+Enter: folha da ordem (tarefas e reclamações). A barra ao lado de \"Operação\" define o layout do mapa (CC dominante / 50/50). Marcadores: tipo, equipe e estado.'),
    ('UI_OP_ORDERS_HINT', es_id, 'Órdenes activas (sin eventos). Clic: detalle en el panel; doble clic o Ctrl+Enter: hoja del pedido (tareas y reclamaciones). La barra junto a «Operación» ajusta el mapa (énfasis operaciones / 50/50). Marcadores: tipo, equipo y estado.'),
    ('UI_OP_ORDERS_HINT', it_id, 'Ordini attivi (eventi esclusi). Click: dettaglio nel pannello; doppio click o Ctrl+Invio: foglio ordine (attività e reclami). La barra accanto a «Operazioni» imposta il layout mappa (focus operazioni / 50-50). Marcatori: tipo, squadra e stato.'),

    ('UI_OP_COL_ORDER_CODE', en_id, 'Order no.'),
    ('UI_OP_COL_ORDER_CODE', pt_id, 'Nº Ordem'),
    ('UI_OP_COL_ORDER_CODE', es_id, 'N.º orden'),
    ('UI_OP_COL_ORDER_CODE', it_id, 'N. ordine'),

    ('UI_OP_COL_ORDER_CATEGORY', en_id, 'Category'),
    ('UI_OP_COL_ORDER_CATEGORY', pt_id, 'Categoria'),
    ('UI_OP_COL_ORDER_CATEGORY', es_id, 'Categoría'),
    ('UI_OP_COL_ORDER_CATEGORY', it_id, 'Categoria'),

    ('UI_OP_COL_ORDER_SUMMARY', en_id, 'Summary'),
    ('UI_OP_COL_ORDER_SUMMARY', pt_id, 'Resumo'),
    ('UI_OP_COL_ORDER_SUMMARY', es_id, 'Resumen'),
    ('UI_OP_COL_ORDER_SUMMARY', it_id, 'Riassunto'),

    ('UI_OP_COL_CAT', en_id, 'Cat.'),
    ('UI_OP_COL_CAT', pt_id, 'Cat.'),
    ('UI_OP_COL_CAT', es_id, 'Cat.'),
    ('UI_OP_COL_CAT', it_id, 'Cat.'),

    ('UI_OP_COL_ACT', en_id, 'Updated'),
    ('UI_OP_COL_ACT', pt_id, 'Act.'),
    ('UI_OP_COL_ACT', es_id, 'Act.'),
    ('UI_OP_COL_ACT', it_id, 'Agg.'),

    ('UI_OP_COL_BLOQ', en_id, 'Lock'),
    ('UI_OP_COL_BLOQ', pt_id, 'Blq.'),
    ('UI_OP_COL_BLOQ', es_id, 'Bloq.'),
    ('UI_OP_COL_BLOQ', it_id, 'Blocco'),

    ('UI_OP_COL_DET', en_id, 'Detail'),
    ('UI_OP_COL_DET', pt_id, 'Det.'),
    ('UI_OP_COL_DET', es_id, 'Det.'),
    ('UI_OP_COL_DET', it_id, 'Det.'),

    ('UI_TT_CATEGORY_GRID', en_id, 'Operational category (complaint, repair, …)'),
    ('UI_TT_CATEGORY_GRID', pt_id, 'Categoria operacional (reclamação, reparo, …)'),
    ('UI_TT_CATEGORY_GRID', es_id, 'Categoría operativa (reclamo, reparación, …)'),
    ('UI_TT_CATEGORY_GRID', it_id, 'Categoria operativa (reclamo, riparazione, …)'),

    ('UI_TT_FEEDER_GRID', en_id, 'Feeder / upstream segment'),
    ('UI_TT_FEEDER_GRID', pt_id, 'Alimentador / segmento a montante'),
    ('UI_TT_FEEDER_GRID', es_id, 'Alimentador / tramo aguas arriba'),
    ('UI_TT_FEEDER_GRID', it_id, 'Alimentatore / segmento a monte'),

    ('UI_TT_GRID_UPDATED', en_id, 'Last record update'),
    ('UI_TT_GRID_UPDATED', pt_id, 'Última actualização do registo'),
    ('UI_TT_GRID_UPDATED', es_id, 'Última actualización del registro'),
    ('UI_TT_GRID_UPDATED', it_id, 'Ultimo aggiornamento del record'),

    ('UI_TT_GRID_LOCK', en_id, 'Edit lock (another user)'),
    ('UI_TT_GRID_LOCK', pt_id, 'Bloqueio de edição (outro utilizador)'),
    ('UI_TT_GRID_LOCK', es_id, 'Bloqueo de edición (otro usuario)'),
    ('UI_TT_GRID_LOCK', it_id, 'Blocco modifica (altro utente)'),

    ('UI_TT_GRID_DESC', en_id, 'Technical description (first line)'),
    ('UI_TT_GRID_DESC', pt_id, 'Descrição técnica (primeira linha)'),
    ('UI_TT_GRID_DESC', es_id, 'Descripción técnica (primera línea)'),
    ('UI_TT_GRID_DESC', it_id, 'Descrizione tecnica (prima riga)'),

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

    ('UI_OP_OPEN_DETAIL', en_id, 'Sheet'),
    ('UI_OP_OPEN_DETAIL', pt_id, 'Folha'),
    ('UI_OP_OPEN_DETAIL', es_id, 'Hoja'),
    ('UI_OP_OPEN_DETAIL', it_id, 'Foglio'),

    ('UI_OP_COL_ORDER_TYPE', en_id, 'Type'),
    ('UI_OP_COL_ORDER_TYPE', pt_id, 'Tipo'),
    ('UI_OP_COL_ORDER_TYPE', es_id, 'Tipo'),
    ('UI_OP_COL_ORDER_TYPE', it_id, 'Tipo'),

    ('UI_OP_COL_ORG', en_id, 'Organization'),
    ('UI_OP_COL_ORG', pt_id, 'Organização'),
    ('UI_OP_COL_ORG', es_id, 'Organización'),
    ('UI_OP_COL_ORG', it_id, 'Organizzazione'),

    ('UI_OP_COL_MUNICIPALITY', en_id, 'Municipality'),
    ('UI_OP_COL_MUNICIPALITY', pt_id, 'Município'),
    ('UI_OP_COL_MUNICIPALITY', es_id, 'Municipio'),
    ('UI_OP_COL_MUNICIPALITY', it_id, 'Comune'),

    ('UI_OP_COL_NEIGHBORHOOD', en_id, 'Neighborhood'),
    ('UI_OP_COL_NEIGHBORHOOD', pt_id, 'Bairro'),
    ('UI_OP_COL_NEIGHBORHOOD', es_id, 'Barrio'),
    ('UI_OP_COL_NEIGHBORHOOD', it_id, 'Quartiere'),

    ('UI_OP_COL_EQUIPMENT', en_id, 'Equipment'),
    ('UI_OP_COL_EQUIPMENT', pt_id, 'Equipamento'),
    ('UI_OP_COL_EQUIPMENT', es_id, 'Equipo'),
    ('UI_OP_COL_EQUIPMENT', it_id, 'Apparato'),

    ('UI_OP_COL_FEEDER', en_id, 'Feeder'),
    ('UI_OP_COL_FEEDER', pt_id, 'Alimentador'),
    ('UI_OP_COL_FEEDER', es_id, 'Alimentador'),
    ('UI_OP_COL_FEEDER', it_id, 'Alimentatore'),

    ('UI_OP_COL_AFFECTED', en_id, 'Cust.'),
    ('UI_OP_COL_AFFECTED', pt_id, 'Clientes'),
    ('UI_OP_COL_AFFECTED', es_id, 'Clientes'),
    ('UI_OP_COL_AFFECTED', it_id, 'Clienti'),

    ('UI_OP_COL_COMPLAINTS', en_id, 'Compl.'),
    ('UI_OP_COL_COMPLAINTS', pt_id, 'Recl.'),
    ('UI_OP_COL_COMPLAINTS', es_id, 'Recl.'),
    ('UI_OP_COL_COMPLAINTS', it_id, 'Recl.'),

    ('UI_OP_COL_FLAGS_SHORT', en_id, 'Flags'),
    ('UI_OP_COL_FLAGS_SHORT', pt_id, 'Sinais'),
    ('UI_OP_COL_FLAGS_SHORT', es_id, 'Señales'),
    ('UI_OP_COL_FLAGS_SHORT', it_id, 'Segnali'),

    ('UI_OP_COL_START_TIME', en_id, 'Start'),
    ('UI_OP_COL_START_TIME', pt_id, 'Início'),
    ('UI_OP_COL_START_TIME', es_id, 'Inicio'),
    ('UI_OP_COL_START_TIME', it_id, 'Inizio'),

    ('UI_OP_COL_HOURS', en_id, 'Δh'),
    ('UI_OP_COL_HOURS', pt_id, 'Δh'),
    ('UI_OP_COL_HOURS', es_id, 'Δh'),
    ('UI_OP_COL_HOURS', it_id, 'Δh'),

    ('UI_OP_COL_TYPE_ABBR', en_id, 'T'),
    ('UI_OP_COL_TYPE_ABBR', pt_id, 'T'),
    ('UI_OP_COL_TYPE_ABBR', es_id, 'T'),
    ('UI_OP_COL_TYPE_ABBR', it_id, 'T'),

    ('UI_OP_COL_ORG_SHORT', en_id, 'Org.'),
    ('UI_OP_COL_ORG_SHORT', pt_id, 'Org.'),
    ('UI_OP_COL_ORG_SHORT', es_id, 'Org.'),
    ('UI_OP_COL_ORG_SHORT', it_id, 'Org.'),

    ('UI_OP_COL_LOC_SHORT', en_id, 'Loc.'),
    ('UI_OP_COL_LOC_SHORT', pt_id, 'Loc.'),
    ('UI_OP_COL_LOC_SHORT', es_id, 'Ubic.'),
    ('UI_OP_COL_LOC_SHORT', it_id, 'Loc.'),

    ('UI_OP_COL_EQUIP_SHORT', en_id, 'Eq.'),
    ('UI_OP_COL_EQUIP_SHORT', pt_id, 'Eq.'),
    ('UI_OP_COL_EQUIP_SHORT', es_id, 'Eq.'),
    ('UI_OP_COL_EQUIP_SHORT', it_id, 'Eq.'),

    ('UI_OP_COL_PRI_POS', en_id, 'Pri·POS'),
    ('UI_OP_COL_PRI_POS', pt_id, 'Pri.·POS'),
    ('UI_OP_COL_PRI_POS', es_id, 'Pri.·POS'),
    ('UI_OP_COL_PRI_POS', it_id, 'Pri·POS'),

    ('UI_OP_COL_CALLBACK', en_id, 'CB'),
    ('UI_OP_COL_CALLBACK', pt_id, 'CB'),
    ('UI_OP_COL_CALLBACK', es_id, 'CB'),
    ('UI_OP_COL_CALLBACK', it_id, 'CB'),

    ('UI_OP_LAYOUT_CCC', en_id, '75%'),
    ('UI_OP_LAYOUT_CCC', pt_id, '75%'),
    ('UI_OP_LAYOUT_CCC', es_id, '75%'),
    ('UI_OP_LAYOUT_CCC', it_id, '75%'),

    ('UI_OP_LAYOUT_SPLIT', en_id, '50%'),
    ('UI_OP_LAYOUT_SPLIT', pt_id, '50%'),
    ('UI_OP_LAYOUT_SPLIT', es_id, '50%'),
    ('UI_OP_LAYOUT_SPLIT', it_id, '50%'),

    ('UI_OP_LAYOUT_GROUP_ARIA', en_id, 'Toggle: control-center focus (~75% map) versus map and panel split 50/50'),
    ('UI_OP_LAYOUT_GROUP_ARIA', pt_id, 'Interruptor: foco no centro de controlo (~75% mapa) ou mapa e painel 50/50'),
    ('UI_OP_LAYOUT_GROUP_ARIA', es_id, 'Interruptor: foco en centro de control (~75% mapa) o mapa y panel 50/50'),
    ('UI_OP_LAYOUT_GROUP_ARIA', it_id, 'Interruttore: focus centro controllo (~75% mappa) oppure mappa e pannello 50/50'),

    ('UI_OP_LAYOUT_CCC_FOCUS', en_id, 'Control center focus (~75%)'),
    ('UI_OP_LAYOUT_CCC_FOCUS', pt_id, 'Foco no centro de controle (~75%)'),
    ('UI_OP_LAYOUT_CCC_FOCUS', es_id, 'Foco en centro de control (~75%)'),
    ('UI_OP_LAYOUT_CCC_FOCUS', it_id, 'Focus centro controllo (~75%)'),

    ('UI_OP_DETAIL_TITLE', en_id, 'Order: identifier'),
    ('UI_OP_DETAIL_TITLE', pt_id, 'Ordem: identificador'),
    ('UI_OP_DETAIL_TITLE', es_id, 'Orden: identificador'),
    ('UI_OP_DETAIL_TITLE', it_id, 'Ordine: identificatore'),

    ('UI_OP_DETAIL_EMPTY', en_id, 'Select an order, a team row, or a map feature.'),
    ('UI_OP_DETAIL_EMPTY', pt_id, 'Seleccione uma ordem, uma linha de equipa ou uma feição no mapa.'),
    ('UI_OP_DETAIL_EMPTY', es_id, 'Seleccione un pedido, una fila de equipo o una entidad en el mapa.'),
    ('UI_OP_DETAIL_EMPTY', it_id, 'Selezionare un ordine, una riga squadra o una feature sulla mappa.'),

    ('UI_OP_DETAIL_MAP_QUERY', en_id, 'Map query (GetFeatureInfo)'),
    ('UI_OP_DETAIL_MAP_QUERY', pt_id, 'Consulta ao mapa (GetFeatureInfo)'),
    ('UI_OP_DETAIL_MAP_QUERY', es_id, 'Consulta al mapa (GetFeatureInfo)'),
    ('UI_OP_DETAIL_MAP_QUERY', it_id, 'Interrogazione mappa (GetFeatureInfo)'),

    ('UI_OP_DETAIL_ORDER', en_id, 'Work order'),
    ('UI_OP_DETAIL_ORDER', pt_id, 'Ordem de serviço'),
    ('UI_OP_DETAIL_ORDER', es_id, 'Orden de servicio'),
    ('UI_OP_DETAIL_ORDER', it_id, 'Ordine di lavoro'),

    ('UI_OP_DETAIL_TEAM', en_id, 'Field team'),
    ('UI_OP_DETAIL_TEAM', pt_id, 'Equipa em campo'),
    ('UI_OP_DETAIL_TEAM', es_id, 'Equipo de campo'),
    ('UI_OP_DETAIL_TEAM', it_id, 'Squadra sul campo'),

    ('UI_OP_COL_PRIORITY_SCORE', en_id, 'Score'),
    ('UI_OP_COL_PRIORITY_SCORE', pt_id, 'Peso'),
    ('UI_OP_COL_PRIORITY_SCORE', es_id, 'Peso'),
    ('UI_OP_COL_PRIORITY_SCORE', it_id, 'Peso'),

    ('UI_OP_COL_FOCUS_LAT', en_id, 'Focus lat'),
    ('UI_OP_COL_FOCUS_LAT', pt_id, 'Latitude foco'),
    ('UI_OP_COL_FOCUS_LAT', es_id, 'Latitud foco'),
    ('UI_OP_COL_FOCUS_LAT', it_id, 'Lat foco'),

    ('UI_OP_COL_FOCUS_LNG', en_id, 'Focus lng'),
    ('UI_OP_COL_FOCUS_LNG', pt_id, 'Longitude foco'),
    ('UI_OP_COL_FOCUS_LNG', es_id, 'Longitud foco'),
    ('UI_OP_COL_FOCUS_LNG', it_id, 'Lng foco'),

    ('UI_OP_FLAG_SAFETY', en_id, 'Safety risk'),
    ('UI_OP_FLAG_SAFETY', pt_id, 'Risco segurança'),
    ('UI_OP_FLAG_SAFETY', es_id, 'Riesgo seguridad'),
    ('UI_OP_FLAG_SAFETY', it_id, 'Rischio sicurezza'),

    ('UI_OP_FLAG_CRITICAL', en_id, 'Critical infra'),
    ('UI_OP_FLAG_CRITICAL', pt_id, 'Infra crítica'),
    ('UI_OP_FLAG_CRITICAL', es_id, 'Infra crítica'),
    ('UI_OP_FLAG_CRITICAL', it_id, 'Infra critica'),

    ('UI_OP_FLAG_CALLBACK', en_id, 'Customer callback'),
    ('UI_OP_FLAG_CALLBACK', pt_id, 'Callback cliente'),
    ('UI_OP_FLAG_CALLBACK', es_id, 'Callback cliente'),
    ('UI_OP_FLAG_CALLBACK', it_id, 'Callback cliente'),

    ('UI_OP_ORDER_SHEET_TITLE', en_id, 'Work order sheet'),
    ('UI_OP_ORDER_SHEET_TITLE', pt_id, 'Folha da ordem'),
    ('UI_OP_ORDER_SHEET_TITLE', es_id, 'Hoja de la orden'),
    ('UI_OP_ORDER_SHEET_TITLE', it_id, 'Foglio ordine'),

    ('UI_OP_ORDER_SHEET_HINT', en_id, 'Create tasks and change their status here; complaints remain read-only in this version.'),
    ('UI_OP_ORDER_SHEET_HINT', pt_id, 'Pode criar tarefas e alterar o estado (em curso, concluída) a partir desta folha; reclamações permanecem em leitura nesta versão.'),
    ('UI_OP_ORDER_SHEET_HINT', es_id, 'Cree tareas y cambie su estado aquí; las reclamaciones siguen siendo solo lectura.'),
    ('UI_OP_ORDER_SHEET_HINT', it_id, 'Crea attività e modifica lo stato qui; i reclami restano in sola lettura.'),

    ('UI_OP_BTN_TASK_ADD', en_id, 'Add task'),
    ('UI_OP_BTN_TASK_ADD', pt_id, 'Adicionar tarefa'),
    ('UI_OP_BTN_TASK_ADD', es_id, 'Añadir tarea'),
    ('UI_OP_BTN_TASK_ADD', it_id, 'Aggiungi attività'),

    ('UI_OP_PLACEHOLDER_TASK_SUMMARY', en_id, 'New task summary'),
    ('UI_OP_PLACEHOLDER_TASK_SUMMARY', pt_id, 'Resumo da nova tarefa'),
    ('UI_OP_PLACEHOLDER_TASK_SUMMARY', es_id, 'Resumen de la nueva tarea'),
    ('UI_OP_PLACEHOLDER_TASK_SUMMARY', it_id, 'Riassunto nuova attività'),

    ('UI_OP_PLACEHOLDER_TASK_NOTES', en_id, 'Notes (optional)'),
    ('UI_OP_PLACEHOLDER_TASK_NOTES', pt_id, 'Notas (opcional)'),
    ('UI_OP_PLACEHOLDER_TASK_NOTES', es_id, 'Notas (opcional)'),
    ('UI_OP_PLACEHOLDER_TASK_NOTES', it_id, 'Note (opzionale)'),

    ('UI_OP_COL_TASK_ACTIONS', en_id, 'Actions'),
    ('UI_OP_COL_TASK_ACTIONS', pt_id, 'Acções'),
    ('UI_OP_COL_TASK_ACTIONS', es_id, 'Acciones'),
    ('UI_OP_COL_TASK_ACTIONS', it_id, 'Azioni'),

    ('UI_OP_TASK_START', en_id, 'In progress'),
    ('UI_OP_TASK_START', pt_id, 'Em curso'),
    ('UI_OP_TASK_START', es_id, 'En curso'),
    ('UI_OP_TASK_START', it_id, 'In corso'),

    ('UI_OP_TASK_DONE', en_id, 'Complete'),
    ('UI_OP_TASK_DONE', pt_id, 'Concluir'),
    ('UI_OP_TASK_DONE', es_id, 'Completar'),
    ('UI_OP_TASK_DONE', it_id, 'Completa'),

    ('UI_OP_TASK_REOPEN', en_id, 'Reopen'),
    ('UI_OP_TASK_REOPEN', pt_id, 'Reabrir'),
    ('UI_OP_TASK_REOPEN', es_id, 'Reabrir'),
    ('UI_OP_TASK_REOPEN', it_id, 'Riapri'),

    ('UI_OP_TASK_STATUS_OK', en_id, 'Task updated.'),
    ('UI_OP_TASK_STATUS_OK', pt_id, 'Tarefa actualizada.'),
    ('UI_OP_TASK_STATUS_OK', es_id, 'Tarea actualizada.'),
    ('UI_OP_TASK_STATUS_OK', it_id, 'Attività aggiornata.'),

    ('UI_OP_TASK_ADDED', en_id, 'Task created.'),
    ('UI_OP_TASK_ADDED', pt_id, 'Tarefa criada.'),
    ('UI_OP_TASK_ADDED', es_id, 'Tarea creada.'),
    ('UI_OP_TASK_ADDED', it_id, 'Attività creata.'),

    ('UI_OP_TASK_SUMMARY_REQUIRED', en_id, 'Enter a task summary.'),
    ('UI_OP_TASK_SUMMARY_REQUIRED', pt_id, 'Indique o resumo da tarefa.'),
    ('UI_OP_TASK_SUMMARY_REQUIRED', es_id, 'Indique el resumen de la tarea.'),
    ('UI_OP_TASK_SUMMARY_REQUIRED', it_id, 'Inserire il riassunto dell’attività.'),

    ('UI_OP_BTN_SAVE_SHEET', en_id, 'Save sheet'),
    ('UI_OP_BTN_SAVE_SHEET', pt_id, 'Guardar folha'),
    ('UI_OP_BTN_SAVE_SHEET', es_id, 'Guardar hoja'),
    ('UI_OP_BTN_SAVE_SHEET', it_id, 'Salva foglio'),

    ('UI_OP_TASKS_TITLE', en_id, 'Tasks'),
    ('UI_OP_TASKS_TITLE', pt_id, 'Tarefas'),
    ('UI_OP_TASKS_TITLE', es_id, 'Tareas'),
    ('UI_OP_TASKS_TITLE', it_id, 'Attività'),

    ('UI_OP_COMPLAINTS_TITLE', en_id, 'Complaints'),
    ('UI_OP_COMPLAINTS_TITLE', pt_id, 'Reclamações'),
    ('UI_OP_COMPLAINTS_TITLE', es_id, 'Reclamaciones'),
    ('UI_OP_COMPLAINTS_TITLE', it_id, 'Reclami'),

    ('UI_OP_COL_TASK_SEQ', en_id, 'Seq.'),
    ('UI_OP_COL_TASK_SEQ', pt_id, 'Seq.'),
    ('UI_OP_COL_TASK_SEQ', es_id, 'Seq.'),
    ('UI_OP_COL_TASK_SEQ', it_id, 'Seq.'),

    ('UI_OP_COL_TASK_SUMMARY', en_id, 'Task'),
    ('UI_OP_COL_TASK_SUMMARY', pt_id, 'Tarefa'),
    ('UI_OP_COL_TASK_SUMMARY', es_id, 'Tarea'),
    ('UI_OP_COL_TASK_SUMMARY', it_id, 'Attività'),

    ('UI_OP_COL_TASK_NOTES', en_id, 'Notes'),
    ('UI_OP_COL_TASK_NOTES', pt_id, 'Notas'),
    ('UI_OP_COL_TASK_NOTES', es_id, 'Notas'),
    ('UI_OP_COL_TASK_NOTES', it_id, 'Note'),

    ('UI_OP_COL_COMPLAINT_REF', en_id, 'Ref.'),
    ('UI_OP_COL_COMPLAINT_REF', pt_id, 'Ref.'),
    ('UI_OP_COL_COMPLAINT_REF', es_id, 'Ref.'),
    ('UI_OP_COL_COMPLAINT_REF', it_id, 'Ref.'),

    ('UI_OP_COL_CHANNEL', en_id, 'Channel'),
    ('UI_OP_COL_CHANNEL', pt_id, 'Canal'),
    ('UI_OP_COL_CHANNEL', es_id, 'Canal'),
    ('UI_OP_COL_CHANNEL', it_id, 'Canale'),

    ('UI_OP_COL_CALLER', en_id, 'Caller'),
    ('UI_OP_COL_CALLER', pt_id, 'Interlocutor'),
    ('UI_OP_COL_CALLER', es_id, 'Interlocutor'),
    ('UI_OP_COL_CALLER', it_id, 'Interlocutore'),

    ('UI_OP_COL_RECEIVED', en_id, 'Received'),
    ('UI_OP_COL_RECEIVED', pt_id, 'Recebida'),
    ('UI_OP_COL_RECEIVED', es_id, 'Recibida'),
    ('UI_OP_COL_RECEIVED', it_id, 'Ricevuta'),

    ('UI_OP_TASKS_EMPTY', en_id, 'No tasks recorded.'),
    ('UI_OP_TASKS_EMPTY', pt_id, 'Sem tarefas registadas.'),
    ('UI_OP_TASKS_EMPTY', es_id, 'Sin tareas registradas.'),
    ('UI_OP_TASKS_EMPTY', it_id, 'Nessuna attività registrata.'),

    ('UI_OP_COMPLAINTS_EMPTY', en_id, 'No linked complaints.'),
    ('UI_OP_COMPLAINTS_EMPTY', pt_id, 'Sem reclamações ligadas.'),
    ('UI_OP_COMPLAINTS_EMPTY', es_id, 'Sin reclamaciones vinculadas.'),
    ('UI_OP_COMPLAINTS_EMPTY', it_id, 'Nessun reclamo collegato.'),

    ('UI_OP_STATUS_LOADING_SHEET', en_id, 'Loading sheet…'),
    ('UI_OP_STATUS_LOADING_SHEET', pt_id, 'A carregar folha…'),
    ('UI_OP_STATUS_LOADING_SHEET', es_id, 'Cargando hoja…'),
    ('UI_OP_STATUS_LOADING_SHEET', it_id, 'Caricamento foglio…'),

    ('UI_OP_SHEET_LOAD_FAIL', en_id, 'Failed to load sheet. Apply infra/sql/06_work_order_sheet_model.sql if not yet applied.'),
    ('UI_OP_SHEET_LOAD_FAIL', pt_id, 'Falha ao carregar folha. Aplique infra/sql/06_work_order_sheet_model.sql se ainda não aplicou.'),
    ('UI_OP_SHEET_LOAD_FAIL', es_id, 'Error al cargar la hoja. Aplique infra/sql/06_work_order_sheet_model.sql si aún no lo hizo.'),
    ('UI_OP_SHEET_LOAD_FAIL', it_id, 'Caricamento foglio fallito. Eseguire infra/sql/06_work_order_sheet_model.sql se non ancora applicato.'),

    ('UI_OP_SHEET_SAVED', en_id, 'Sheet saved.'),
    ('UI_OP_SHEET_SAVED', pt_id, 'Folha guardada.'),
    ('UI_OP_SHEET_SAVED', es_id, 'Hoja guardada.'),
    ('UI_OP_SHEET_SAVED', it_id, 'Foglio salvato.'),

    ('UI_OP_SHEET_META_TEAM', en_id, 'Team'),
    ('UI_OP_SHEET_META_TEAM', pt_id, 'Equipa'),
    ('UI_OP_SHEET_META_TEAM', es_id, 'Equipo'),
    ('UI_OP_SHEET_META_TEAM', it_id, 'Squadra'),

    ('UI_OP_STATUS_ORDER_MAP_FOCUS', en_id, 'Operational view: neighborhoods and roads on; target municipalities layer off.'),
    ('UI_OP_STATUS_ORDER_MAP_FOCUS', pt_id, 'Vista operacional: bairros e vias activos; municípios-alvo desligados.'),
    ('UI_OP_STATUS_ORDER_MAP_FOCUS', es_id, 'Vista operativa: barrios y vías activos; capa municipios-alvo apagada.'),
    ('UI_OP_STATUS_ORDER_MAP_FOCUS', it_id, 'Vista operativa: quartieri e strade attivi; municipi obiettivo spenti.'),

    ('UI_OP_STATUS_ORDER_MAP_NO_COORD', en_id, 'This work order has no focus coordinates.'),
    ('UI_OP_STATUS_ORDER_MAP_NO_COORD', pt_id, 'Esta ordem não tem coordenadas de foco.'),
    ('UI_OP_STATUS_ORDER_MAP_NO_COORD', es_id, 'Esta orden no tiene coordenadas de foco.'),
    ('UI_OP_STATUS_ORDER_MAP_NO_COORD', it_id, 'Questo ordine non ha coordinate di foco.'),

    ('UI_OP_GO_MAP_ORDER', en_id, 'Go to map (neighborhoods & roads)'),
    ('UI_OP_GO_MAP_ORDER', pt_id, 'Ir para o mapa (bairros e vias)'),
    ('UI_OP_GO_MAP_ORDER', es_id, 'Ir al mapa (barrios y vías)'),
    ('UI_OP_GO_MAP_ORDER', it_id, 'Vai alla mappa (quartieri e strade)'),

    ('UI_TT_AFFECTED', en_id, 'Affected customers (decision metric)'),
    ('UI_TT_AFFECTED', pt_id, 'Clientes afectados (métrica decisória)'),
    ('UI_TT_AFFECTED', es_id, 'Clientes afectados (métrica decisoria)'),
    ('UI_TT_AFFECTED', it_id, 'Clienti coinvolti (metrica decisoria)'),

    ('UI_TT_COMPLAINTS', en_id, 'Complaints linked to this work order'),
    ('UI_TT_COMPLAINTS', pt_id, 'Reclamações ligadas a esta ordem'),
    ('UI_TT_COMPLAINTS', es_id, 'Reclamaciones vinculadas a esta orden'),
    ('UI_TT_COMPLAINTS', it_id, 'Reclami collegati a questo ordine'),

    ('UI_TT_PRIORITY_SCORE', en_id, 'Numeric priority weight for triage'),
    ('UI_TT_PRIORITY_SCORE', pt_id, 'Peso numérico para triagem'),
    ('UI_TT_PRIORITY_SCORE', es_id, 'Peso numérico para triage'),
    ('UI_TT_PRIORITY_SCORE', it_id, 'Peso numerico per triage'),

    ('UI_TT_FLAG_SAFETY', en_id, 'Safety risk flagged'),
    ('UI_TT_FLAG_SAFETY', pt_id, 'Risco de segurança assinalado'),
    ('UI_TT_FLAG_SAFETY', es_id, 'Riesgo de seguridad marcado'),
    ('UI_TT_FLAG_SAFETY', it_id, 'Rischio sicurezza segnalato'),

    ('UI_TT_FLAG_SAFETY_OFF', en_id, 'No safety risk flag'),
    ('UI_TT_FLAG_SAFETY_OFF', pt_id, 'Sem flag de risco de segurança'),
    ('UI_TT_FLAG_SAFETY_OFF', es_id, 'Sin marca de riesgo de seguridad'),
    ('UI_TT_FLAG_SAFETY_OFF', it_id, 'Nessun rischio sicurezza'),

    ('UI_TT_FLAG_CRITICAL', en_id, 'Critical infrastructure'),
    ('UI_TT_FLAG_CRITICAL', pt_id, 'Infra-estrutura crítica'),
    ('UI_TT_FLAG_CRITICAL', es_id, 'Infraestructura crítica'),
    ('UI_TT_FLAG_CRITICAL', it_id, 'Infrastruttura critica'),

    ('UI_TT_FLAG_CRITICAL_OFF', en_id, 'Not marked as critical infra'),
    ('UI_TT_FLAG_CRITICAL_OFF', pt_id, 'Fora de perfil de infra crítica'),
    ('UI_TT_FLAG_CRITICAL_OFF', es_id, 'No marcada como infra crítica'),
    ('UI_TT_FLAG_CRITICAL_OFF', it_id, 'Non marcata come infra critica'),

    ('UI_TT_FLAG_CALLBACK', en_id, 'Customer callback required'),
    ('UI_TT_FLAG_CALLBACK', pt_id, 'Callback ao cliente necessário'),
    ('UI_TT_FLAG_CALLBACK', es_id, 'Callback al cliente requerido'),
    ('UI_TT_FLAG_CALLBACK', it_id, 'Callback cliente richiesto'),

    ('UI_TT_FLAG_CALLBACK_OFF', en_id, 'No pending customer callback'),
    ('UI_TT_FLAG_CALLBACK_OFF', pt_id, 'Sem callback pendente'),
    ('UI_TT_FLAG_CALLBACK_OFF', es_id, 'Sin callback pendiente'),
    ('UI_TT_FLAG_CALLBACK_OFF', it_id, 'Nessun callback pendente'),

    ('UI_TT_HOURS_OPEN', en_id, 'Elapsed time (hours since start)'),
    ('UI_TT_HOURS_OPEN', pt_id, 'Tempo em curso (horas desde o início)'),
    ('UI_TT_HOURS_OPEN', es_id, 'Tiempo transcurrido (horas desde el inicio)'),
    ('UI_TT_HOURS_OPEN', it_id, 'Tempo trascorso (ore dall’inizio)'),

    ('UI_TT_PRIORITY_LETTER', en_id, 'Operational priority (P1…)'),
    ('UI_TT_PRIORITY_LETTER', pt_id, 'Prioridade operacional (P1…)'),
    ('UI_TT_PRIORITY_LETTER', es_id, 'Prioridad operativa (P1…)'),
    ('UI_TT_PRIORITY_LETTER', it_id, 'Priorità operativa (P1…)'),

    ('UI_TT_POS_SCORE', en_id, 'POS / numeric weight for triage'),
    ('UI_TT_POS_SCORE', pt_id, 'POS / peso numérico para triagem'),
    ('UI_TT_POS_SCORE', es_id, 'POS / peso numérico para triage'),
    ('UI_TT_POS_SCORE', it_id, 'POS / peso numerico per triage'),

    ('UI_TT_CALLBACK_HUM', en_id, 'Human callback (operator / direct contact)'),
    ('UI_TT_CALLBACK_HUM', pt_id, 'Callback humano (operador / contacto directo)'),
    ('UI_TT_CALLBACK_HUM', es_id, 'Callback humano (operador / contacto directo)'),
    ('UI_TT_CALLBACK_HUM', it_id, 'Callback umano (operatore / contatto diretto)'),

    ('UI_TT_CALLBACK_AUTO', en_id, 'Automatic callback (IVR, SMS, BOT)'),
    ('UI_TT_CALLBACK_AUTO', pt_id, 'Callback automático (IVR, SMS, BOT)'),
    ('UI_TT_CALLBACK_AUTO', es_id, 'Callback automático (IVR, SMS, BOT)'),
    ('UI_TT_CALLBACK_AUTO', it_id, 'Callback automatico (IVR, SMS, BOT)'),

    ('UI_OT_TYPE_REPAIR', en_id, 'Repair'),
    ('UI_OT_TYPE_REPAIR', pt_id, 'Reparo'),
    ('UI_OT_TYPE_REPAIR', es_id, 'Reparación'),
    ('UI_OT_TYPE_REPAIR', it_id, 'Riparazione'),

    ('UI_OT_TYPE_MAINTENANCE', en_id, 'Maintenance'),
    ('UI_OT_TYPE_MAINTENANCE', pt_id, 'Manutenção'),
    ('UI_OT_TYPE_MAINTENANCE', es_id, 'Mantenimiento'),
    ('UI_OT_TYPE_MAINTENANCE', it_id, 'Manutenzione'),

    ('UI_OT_TYPE_INSPECTION', en_id, 'Inspection'),
    ('UI_OT_TYPE_INSPECTION', pt_id, 'Inspecção'),
    ('UI_OT_TYPE_INSPECTION', es_id, 'Inspección'),
    ('UI_OT_TYPE_INSPECTION', it_id, 'Ispezione'),

    ('UI_OT_TYPE_EMERGENCY', en_id, 'Emergency'),
    ('UI_OT_TYPE_EMERGENCY', pt_id, 'Emergência'),
    ('UI_OT_TYPE_EMERGENCY', es_id, 'Emergencia'),
    ('UI_OT_TYPE_EMERGENCY', it_id, 'Emergenza'),

    ('UI_OT_TYPE_RESTORATION', en_id, 'Restoration'),
    ('UI_OT_TYPE_RESTORATION', pt_id, 'Restabelecimento'),
    ('UI_OT_TYPE_RESTORATION', es_id, 'Restablecimiento'),
    ('UI_OT_TYPE_RESTORATION', it_id, 'Ristabilimento'),

    ('UI_OT_TYPE_INCIDENT', en_id, 'Incident'),
    ('UI_OT_TYPE_INCIDENT', pt_id, 'Incidente'),
    ('UI_OT_TYPE_INCIDENT', es_id, 'Incidente'),
    ('UI_OT_TYPE_INCIDENT', it_id, 'Incidente'),

    ('UI_OP_ORDER_DETAIL_TITLE', en_id, 'Work order detail'),
    ('UI_OP_ORDER_DETAIL_TITLE', pt_id, 'Detalhe da ordem'),
    ('UI_OP_ORDER_DETAIL_TITLE', es_id, 'Detalle de la orden'),
    ('UI_OP_ORDER_DETAIL_TITLE', it_id, 'Dettaglio ordine'),

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

    ('UI_OP_ORDER_DETAIL_HINT', en_id, 'Data reflects the current operational record; future forms will follow the full OMS model.'),
    ('UI_OP_ORDER_DETAIL_HINT', pt_id, 'Os dados reflectem o registo operacional actual na base de dados; alterações futuras seguirão o modelo OMS completo.'),
    ('UI_OP_ORDER_DETAIL_HINT', es_id, 'Los datos reflejan el registro operativo actual; los formularios seguirán el modelo OMS completo.'),
    ('UI_OP_ORDER_DETAIL_HINT', it_id, 'I dati riflettono il record operativo attuale; i form seguiranno il modello OMS completo.'),

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
    ('UI_OP_AUD_TIMELINE_HINT', it_id, 'La timeline completa sarà integrata via API.'),

    -- Glossary / topology — termos técnicos sem ambiguidade regional (EN, PT-BR, ES, IT)
    ('UI_GLOSSARY_LINEAR_NETWORK_SEGMENT', en_id, 'Linear network segment (GIS): contiguous length of a utility asset between two endpoints, stored as a LineString and optionally as a TopoGeometry for shared-node topology.'),
    ('UI_GLOSSARY_LINEAR_NETWORK_SEGMENT', pt_id, 'Segmento linear da rede (SIG): extensão contínua de um activo de utilities entre dois extremos, representada como LineString e, opcionalmente, como TopoGeometry para partilha de nós topológicos.'),
    ('UI_GLOSSARY_LINEAR_NETWORK_SEGMENT', es_id, 'Tramo lineal de red (SIG): tramo continuo de un activo de utilities entre dos extremos, almacenado como LineString y, opcionalmente, como TopoGeometry para topología de nodos compartidos.'),
    ('UI_GLOSSARY_LINEAR_NETWORK_SEGMENT', it_id, 'Segmento lineare di rete (GIS): tratto continuo di un asset di utilities tra due estremi, memorizzato come LineString e, opzionalmente, come TopoGeometry per nodi topologici condivisi.'),

    ('UI_GLOSSARY_POSTGIS_TOPOLOGY', en_id, 'PostGIS Topology (extension postgis_topology): native topological model with shared primitives (nodes, edges, faces) managed by the database engine.'),
    ('UI_GLOSSARY_POSTGIS_TOPOLOGY', pt_id, 'Topologia PostGIS (extensão postgis_topology): modelo topológico nativo com primitivas partilhadas (nós, arestas, faces) geridas pelo motor da base de dados.'),
    ('UI_GLOSSARY_POSTGIS_TOPOLOGY', es_id, 'Topología PostGIS (extensión postgis_topology): modelo topológico nativo con primitivas compartidas (nodos, aristas, caras) gestionadas por el motor.'),
    ('UI_GLOSSARY_POSTGIS_TOPOLOGY', it_id, 'Topologia PostGIS (estensione postgis_topology): modello topologico nativo con primitive condivise (nodi, archi, facce) gestite dal motore.'),

    ('UI_HELP_STACK_POSTGIS_TOPOLOGY', en_id, 'Native PostGIS Topology (tabgis_utilities_topo) and linear segments in gis.network_span — see TOPOLOGY_NATIVE_POSTGIS.md.'),
    ('UI_HELP_STACK_POSTGIS_TOPOLOGY', pt_id, 'Topologia nativa PostGIS (tabgis_utilities_topo) e segmentos lineares da rede em gis.network_span — ver TOPOLOGY_NATIVE_POSTGIS.md.'),
    ('UI_HELP_STACK_POSTGIS_TOPOLOGY', es_id, 'Topología nativa PostGIS (tabgis_utilities_topo) y tramos lineales en gis.network_span — ver TOPOLOGY_NATIVE_POSTGIS.md.'),
    ('UI_HELP_STACK_POSTGIS_TOPOLOGY', it_id, 'Topologia nativa PostGIS (tabgis_utilities_topo) e segmenti lineari in gis.network_span — vedi TOPOLOGY_NATIVE_POSTGIS.md.'),

    ('UI_HELP_API_TOPOLOGY', en_id, 'Topology API (/api/topology/*): metadata and linear network segments (JSON + approximate length in metres).'),
    ('UI_HELP_API_TOPOLOGY', pt_id, 'API de topologia (/api/topology/*): metadados e segmentos lineares da rede (JSON + comprimento aproximado em metros).'),
    ('UI_HELP_API_TOPOLOGY', es_id, 'API de topología (/api/topology/*): metadatos y tramos lineales (JSON + longitud aproximada en metros).'),
    ('UI_HELP_API_TOPOLOGY', it_id, 'API topologia (/api/topology/*): metadati e segmenti lineari (JSON + lunghezza approssimativa in metri).')

    ON CONFLICT (object_id, language_id) DO UPDATE SET translated_text = EXCLUDED.translated_text;
END $$;
