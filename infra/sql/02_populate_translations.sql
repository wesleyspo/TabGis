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

    ('UI_MENU_FILTERS', en_id, 'Filters'),
    ('UI_MENU_FILTERS', pt_id, 'Filtros'),
    ('UI_MENU_FILTERS', es_id, 'Filtros'),
    ('UI_MENU_FILTERS', it_id, 'Filtri'),

    ('UI_MENU_LAYERS', en_id, 'Layers'),
    ('UI_MENU_LAYERS', pt_id, 'Camadas'),
    ('UI_MENU_LAYERS', es_id, 'Capas'),
    ('UI_MENU_LAYERS', it_id, 'Livelli'),

    ('UI_BTN_OPERATION', en_id, 'Operation'),
    ('UI_BTN_OPERATION', pt_id, 'Operação'),
    ('UI_BTN_OPERATION', es_id, 'Operación'),
    ('UI_BTN_OPERATION', it_id, 'Operazione'),

    ('UI_FILTER_MUNI_LABEL', en_id, 'Municipalities'),
    ('UI_FILTER_MUNI_LABEL', pt_id, 'Municípios'),
    ('UI_FILTER_MUNI_LABEL', es_id, 'Municipios'),
    ('UI_FILTER_MUNI_LABEL', it_id, 'Comuni'),

    ('UI_FILTER_MUNI_PLACEHOLDER', en_id, 'Filter municipalities...'),
    ('UI_FILTER_MUNI_PLACEHOLDER', pt_id, 'Filtrar municípios…'),
    ('UI_FILTER_MUNI_PLACEHOLDER', es_id, 'Filtrar municipios…'),
    ('UI_FILTER_MUNI_PLACEHOLDER', it_id, 'Filtra comuni…'),

    ('UI_FILTER_NEIGHBORHOOD_LABEL', en_id, 'Neighborhoods'),
    ('UI_FILTER_NEIGHBORHOOD_LABEL', pt_id, 'Bairros'),
    ('UI_FILTER_NEIGHBORHOOD_LABEL', es_id, 'Barrios'),
    ('UI_FILTER_NEIGHBORHOOD_LABEL', it_id, 'Quartieri'),

    ('UI_FILTER_NEIGHBORHOOD_PLACEHOLDER', en_id, 'Filter neighborhoods...'),
    ('UI_FILTER_NEIGHBORHOOD_PLACEHOLDER', pt_id, 'Filtrar bairros…'),
    ('UI_FILTER_NEIGHBORHOOD_PLACEHOLDER', es_id, 'Filtrar barrios…'),
    ('UI_FILTER_NEIGHBORHOOD_PLACEHOLDER', it_id, 'Filtra quartieri…'),

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
    ('UI_PANEL_OP_EMPTY', it_id, 'Gli strumenti di rete appariranno qui.')

    ON CONFLICT (object_id, language_id) DO UPDATE SET translated_text = EXCLUDED.translated_text;
END $$;
