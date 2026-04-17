/**
 * TabGis — frontend/main.js
 *
 * Lógica de mapa Leaflet: camadas WMS (GeoServer), satélite online/offline,
 * busca WFS (municípios e bairros), GetFeatureInfo ao clique e controlo de camadas.
 *
 * Convenção de mensagens de erro (setStatus):
 *   "Falha em [recurso]. [Instrução de remediação] (ver docs/[RUNBOOK].md)."
 * Todas as falhas seguem este padrão para que o operador saiba exactamente
 * qual serviço recuperar e onde encontrar o procedimento.
 */

// ── Referência ao elemento de status no rodapé da sidebar ─────────────────
const statusEl = document.getElementById("status");

/**
 * Menus da topbar (<details>): um só aberto de cada vez; clique fora fecha todos.
 */
function initTopbarMenuDetails() {
  const topbar = document.querySelector(".topbar");
  if (!topbar) return;
  const allDetails = () => Array.from(topbar.querySelectorAll("details"));
  allDetails().forEach((d) => {
    d.addEventListener("toggle", () => {
      if (!d.open) return;
      allDetails().forEach((o) => {
        if (o !== d) o.open = false;
      });
    });
  });
  document.addEventListener(
    "click",
    (ev) => {
      if (topbar.contains(ev.target)) return;
      allDetails().forEach((d) => {
        d.open = false;
      });
    },
    true
  );
}
initTopbarMenuDetails();

// ── Resolução de URLs base ────────────────────────────────────────────────

/**
 * Devolve a raiz dos tiles locais (TileServer GL).
 * Em produção (:8088) o nginx faz proxy de /tiles → TileServer :8081.
 * Em desenvolvimento (:5173 ou outra porta) aponta directamente para :8088/tiles
 * para evitar CORS e garantir acesso ao proxy.
 */
function getLocalTilesBase() {
  const port = window.location.port;
  if (port && port !== "80" && port !== "443" && port !== "8088") {
    return `${window.location.protocol}//${window.location.hostname}:8088/tiles`;
  }
  return `${window.location.origin}/tiles`;
}

/**
 * Devolve a URL base do GeoServer.
 * Suporta override via atributo data-geoserver-base num elemento HTML,
 * útil para testes em ambientes distintos sem editar o ficheiro.
 * Em produção (:8088) usa same-origin; fora disso aponta para :8080.
 */
function getGeoserverBase() {
  const override = document.querySelector("[data-geoserver-base]")
    ?.getAttribute("data-geoserver-base");
  if (override) return override.replace(/\/$/, "");
  const port = window.location.port;
  if (port && port !== "80" && port !== "443" && port !== "8088") {
    return `${window.location.protocol}//${window.location.hostname}:8080/geoserver`;
  }
  return `${window.location.origin}/geoserver`;
}

const geoserverBase = getGeoserverBase();

/** Último mapa de traduções carregado (i18n em painéis dinâmicos). */
let i18nCache = {};

/** Rótulo i18n com fallback (ex.: busca no mapa antes do fetch completar). */
function uiText(key, fallback) {
  const v = i18nCache[key];
  return v != null && v !== "" ? v : fallback;
}
/** Endpoint WMS do workspace base_sp */
const geoserverWms = `${geoserverBase}/base_sp/wms`;
/** Endpoint OWS genérico — usado para pedidos WFS */
const geoserverOws = `${geoserverBase}/ows`;

// ── Inicialização do mapa ─────────────────────────────────────────────────

// Restringe o zoom e área de exploração ao foco do satélite (São Paulo - RMSP ampliada)
// A área de maxBounds foi intencionalmente expandida para permitir o pan da tela e a abertura de popups
const homeBounds = L.latLngBounds([
  [-25.0, -49.0],
  [-22.0, -44.0]
]);

/**
 * preferCanvas melhora performance para muitas features vectoriais.
 * minZoom/maxZoom definem o envelope operacional: estado SP até rua.
 */
const map = L.map("map", {
  zoomControl: true,
  preferCanvas: true,
  minZoom: 9, // Impede um zoom out que mostra o mundo inteiro
  maxZoom: 20,
  zoomDelta: 0.2,
  zoomSnap: 0.2,
  wheelPxPerZoomLevel: 300,
  maxBounds: homeBounds, // Limita o arrasto e o zoom out para esta BBOX
  maxBoundsViscosity: 1.0 // Torna os limites "rígidos", o ecrã não foge
});

/** Mínimo absoluto (L.map); o indicador % e `setMinZoom` nunca ficam abaixo disto. */
const MAP_ORIG_MIN_ZOOM = map.getMinZoom();

/**
 * Pane dedicado para o satélite (raster de fundo).
 * zIndex 100 garante que fica abaixo das camadas vectoriais WMS
 * mas acima do fundo cinza padrão do Leaflet.
 */
map.createPane("satellite");
map.getPane("satellite").style.zIndex = "100";

/** Radar RainViewer acima do basemap, abaixo de marcadores WMS densos. */
map.createPane("weatherRadar");
map.getPane("weatherRadar").style.zIndex = "350";

// ── Definição das camadas ─────────────────────────────────────────────────

/**
 * Satélite online — tiles XYZ Esri World Imagery.
 * Requer acesso à Internet; qualidade até zoom 19.
 * Uso sujeito aos termos de serviço Esri.
 */
const satelliteLayer = L.tileLayer(
  "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
  {
    pane: "satellite",
    attribution:
      "Tiles &copy; Esri — Source: Esri, Maxar, Earthstar Geographics | Uso sujeito a termos Esri",
    maxZoom: 19,
    maxNativeZoom: 19,
    tileSize: 256,
  }
);

/**
 * Satélite local — raster MBTiles servido pelo TileServer GL.
 * Ficheiro: data/tiles/sp_satellite.mbtiles (gerado por build_sp_satellite_mbtiles.sh).
 *
 * minNativeZoom=10: o MBTiles começa no zoom 10; abaixo disso o Leaflet
 *   faria upscale de tiles inexistentes → 404. Com este parâmetro o Leaflet
 *   upscala os tiles de zoom 10 para qualquer zoom inferior ao invés de pedir
 *   tiles que não existem.
 * maxNativeZoom=17: alinhado ao ZMAX=17 do script de geração (resolução 1,2 m/px).
 *   Acima de 17 o Leaflet upscala os tiles mais próximos disponíveis.
 */
const satelliteLocalLayer = L.tileLayer(
  `${getLocalTilesBase()}/data/sp_sat/{z}/{x}/{y}.png`,
  {
    pane: "satellite",
    attribution: "Imagem local (MBTiles / POC — respeitar termos da fonte original)",
    maxZoom: 20,
    minNativeZoom: 10,
    maxNativeZoom: 17,
    tileSize: 256,
  }
);

/**
 * GeoSampa offline — ortofoto MBTiles servida pelo TileServer GL.
 * Dataset esperado: /tiles/data/geosampa_offline/{z}/{x}/{y}.png
 */
const geosampaOfflineLayer = L.tileLayer(
  `${getLocalTilesBase()}/data/geosampa_offline/{z}/{x}/{y}.png`,
  {
    pane: "satellite",
    attribution: "GeoSampa (PMSP) — camada offline local (MBTiles)",
    maxZoom: 22,
    minNativeZoom: 10,
    maxNativeZoom: 19,
    tileSize: 256,
  }
);

/**
 * Camadas WMS do GeoServer — workspace base_sp.
 * transparent:false na UF porque serve como fundo sólido quando sem satélite.
 * Os estilos SLD estão versionados em infra/geoserver/styles/.
 */
const ufLayer = L.tileLayer.wms(geoserverWms, {
  layers: "base_sp:uf_sp",
  format: "image/png",
  transparent: false,
  styles: "base_sp_uf_outline",
  version: "1.1.1",
});

const municipiosLayer = L.tileLayer.wms(geoserverWms, {
  layers: "base_sp:municipios_sp",
  format: "image/png",
  transparent: true,
  styles: "base_sp_municipios_outline",
  version: "1.1.1",
});

/** Municípios-alvo com destaque de cor — 24 municípios da RMSP ampliada */
const municipiosAlvoLayer = L.tileLayer.wms(geoserverWms, {
  layers: "base_sp:municipios_alvo_sp",
  format: "image/png",
  transparent: true,
  styles: "base_sp_municipios_alvo_highlight",
  version: "1.1.1",
  tileSize: 512,
});

/** Bairros dos municípios-alvo — desligado por defeito (muito denso em zoom baixo) */
const bairrosAlvoLayer = L.tileLayer.wms(geoserverWms, {
  layers: "base_sp:bairros_alvo_sp",
  format: "image/png",
  transparent: true,
  styles: "base_sp_bairros_alvo",
  version: "1.1.1",
  tileSize: 512,
});

/** Vias dos municípios-alvo — maior detalhe OSM dentro da RMSP ampliada */
const viasAlvoLayer = L.tileLayer.wms(geoserverWms, {
  layers: "base_sp:vias_alvo_sp",
  format: "image/png",
  transparent: true,
  styles: "base_sp_vias_zoom_scales",
  version: "1.1.1",
});

/** Rotas MWM demo (abaixo dos marcadores OMS) */
const mwmDemoCrewRoutesGroup = L.layerGroup();

/** Agregados por município / bairro (zoom afastado) */
const omsAggregateMarkersGroup = L.layerGroup().addTo(map);

/** Marcadores de ordens (cor = estado, raio ≈ tipo, traço ≈ equipe) */
const workOrderMarkersGroup = L.layerGroup().addTo(map);

/** Zoom: até 10 → município; 11–12 → bairro; ≥13 → ordens individuais */
const OMS_ZOOM_MUNICIPIO_MAX = 10;
const OMS_ZOOM_BAIRRO_MAX = 12;

/** Alinhado a `enforceZoomValidation` das vias (WMS denso abaixo disto). */
const VIAS_LAYER_MIN_ZOOM = 13;
const LAYER_ZOOM_CFG_STORAGE_KEY = "tabgis_layer_zoom_cfg_v1";
const DEFAULT_LAYER_ZOOM_CFG = {
  override: false,
  bairrosEnableMin: OMS_ZOOM_BAIRRO_MAX,
  bairrosDisableBelow: OMS_ZOOM_BAIRRO_MAX,
  viasEnableMin: VIAS_LAYER_MIN_ZOOM,
  viasDisableBelow: VIAS_LAYER_MIN_ZOOM,
};
/** Tecto ao focar por «Ir para» (próximo do objeto; alinhado ao satélite online Esri z19). */
const MAP_FOCUS_MAX_ZOOM = 19;
const MAP_FOCUS_ZOOM_ORDER = 18;
const MAP_FOCUS_ZOOM_TEAM = 18;
const MAP_FOCUS_ZOOM_ADDRESS = 19;

/** @type {'municipio' | 'bairro' | 'detail'} */
let omsMapDisplayMode = 'detail';
let omsAggregateFetchToken = 0;

function clampZoomLevel(v, fallback) {
  const n = Number(v);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(0, Math.min(22, Math.round(n)));
}

function readLayerZoomCfg() {
  try {
    const raw = localStorage.getItem(LAYER_ZOOM_CFG_STORAGE_KEY);
    if (!raw) return { ...DEFAULT_LAYER_ZOOM_CFG };
    const parsed = JSON.parse(raw);
    return {
      override: !!parsed.override,
      bairrosEnableMin: clampZoomLevel(parsed.bairrosEnableMin, DEFAULT_LAYER_ZOOM_CFG.bairrosEnableMin),
      bairrosDisableBelow: clampZoomLevel(parsed.bairrosDisableBelow, DEFAULT_LAYER_ZOOM_CFG.bairrosDisableBelow),
      viasEnableMin: clampZoomLevel(parsed.viasEnableMin, DEFAULT_LAYER_ZOOM_CFG.viasEnableMin),
      viasDisableBelow: clampZoomLevel(parsed.viasDisableBelow, DEFAULT_LAYER_ZOOM_CFG.viasDisableBelow),
    };
  } catch {
    return { ...DEFAULT_LAYER_ZOOM_CFG };
  }
}

function getEffectiveLayerZoomCfg() {
  const cfg = readLayerZoomCfg();
  return cfg.override ? cfg : { ...DEFAULT_LAYER_ZOOM_CFG };
}

// Camadas ativas por defeito ao iniciar (apenas limites municipais e municípios)
municipiosLayer.addTo(map);
municipiosAlvoLayer.addTo(map);

// ── Gestão de opacidade com satélite ─────────────────────────────────────

/**
 * Reduz a opacidade das camadas de limite quando o satélite está activo,
 * para não obstruir a imagem de fundo.
 * @param {boolean} on - true quando qualquer camada satélite está visível
 */
function setVectorOverSatOpacity(on) {
  const opacity = on ? 0.32 : 1;
  ufLayer.setOpacity(opacity);
  municipiosLayer.setOpacity(opacity);
}

/** Relê o estado das camadas satélite e ajusta opacidade dos vectores. */
function refreshSatelliteOpacity() {
  const satActive =
    map.hasLayer(satelliteLayer) ||
    map.hasLayer(satelliteLocalLayer) ||
    map.hasLayer(geosampaOfflineLayer);
  setVectorOverSatOpacity(satActive);
}

// ── Controlos de camadas satélite (exclusão mútua online/local) ───────────

/**
 * Os dois satélites são mutuamente exclusivos: activar um desliga o outro.
 * Isto evita tiles sobrepostos que causariam degradação visual.
 */
document.getElementById("satellite_online").addEventListener("change", (event) => {
  const localCb = document.getElementById("satellite_local");
  const geosampaCb = document.getElementById("geosampa_offline");
  if (event.target.checked) {
    localCb.checked = false;
    geosampaCb.checked = false;
    map.removeLayer(satelliteLocalLayer);
    map.removeLayer(geosampaOfflineLayer);
    geosampaOfflineConfirmed = false;
    satelliteLayer.addTo(map);
    refreshSatelliteOpacity();
    updateMapZoomPercentLabel();
    setStatus("Satélite online activo (UF/municípios mais transparentes).");
  } else {
    map.removeLayer(satelliteLayer);
    refreshSatelliteOpacity();
    updateMapZoomPercentLabel();
    setStatus("Satélite online desligado.");
  }
});

/**
 * Activação do satélite local com verificação de saúde prévia do TileServer.
 * Antes de adicionar a camada ao mapa, consulta o endpoint de metadados do
 * dataset para confirmar que o serviço está acessível e o ficheiro MBTiles
 * existe. Só mostra a mensagem de erro se o servidor estiver realmente
 * inacessível — 404s de cobertura parcial são silenciados quando confirmado=true.
 */
document.getElementById("satellite_local").addEventListener("change", async (event) => {
  const onlineCb = document.getElementById("satellite_online");
  const geosampaCb = document.getElementById("geosampa_offline");
  if (event.target.checked) {
    onlineCb.checked = false;
    geosampaCb.checked = false;
    map.removeLayer(satelliteLayer);
    map.removeLayer(geosampaOfflineLayer);
    setStatus("A verificar TileServer…");
    try {
      const meta = await checkLocalRasterHealth("sp_sat");
      satelliteLocalConfirmed = true;
      geosampaOfflineConfirmed = false;
      satelliteLocalLayer.addTo(map);
      refreshSatelliteOpacity();
      updateMapZoomPercentLabel();
      setStatus(
        `Satélite local activo — capital SP, zoom ${meta.minzoom}–${meta.maxzoom}.`
      );
    } catch {
      satelliteLocalConfirmed = false;
      geosampaOfflineConfirmed = false;
      spSatMbtilesBounds = null;
      event.target.checked = false;
      setStatus(
        "Falha tiles MBTiles. Gere sp_satellite.mbtiles e suba tileserver (ver docs/DEPLOY_POC.md)."
      );
    }
  } else {
    map.removeLayer(satelliteLocalLayer);
    satelliteLocalConfirmed = false;
    geosampaOfflineConfirmed = false;
    spSatMbtilesBounds = null;
    refreshSatelliteOpacity();
    updateMapZoomPercentLabel();
    setStatus("Satélite local desligado.");
  }
});

/**
 * Activação da ortofoto GeoSampa local com verificação de saúde prévia.
 * Exclusão mútua com os satélites para evitar sobreposição de rasters.
 */
document.getElementById("geosampa_offline").addEventListener("change", async (event) => {
  const onlineCb = document.getElementById("satellite_online");
  const localCb = document.getElementById("satellite_local");
  if (event.target.checked) {
    onlineCb.checked = false;
    localCb.checked = false;
    map.removeLayer(satelliteLayer);
    map.removeLayer(satelliteLocalLayer);
    satelliteLocalConfirmed = false;
    geosampaOfflineConfirmed = false;
    spSatMbtilesBounds = null;
    setStatus("A verificar TileServer (GeoSampa offline)…");
    try {
      const meta = await checkLocalRasterHealth("geosampa_offline");
      geosampaOfflineConfirmed = true;
      geosampaOfflineLayer.addTo(map);
      refreshSatelliteOpacity();
      updateMapZoomPercentLabel();
      setStatus(
        `GeoSampa - Offline activo — zoom ${meta.minzoom ?? "?"}–${meta.maxzoom ?? "?"}.`
      );
    } catch {
      geosampaOfflineConfirmed = false;
      event.target.checked = false;
      setStatus(
        "Falha na camada GeoSampa offline. Gere geosampa_offline.mbtiles e suba tileserver (ver docs/DEPLOY_POC.md)."
      );
    }
  } else {
    map.removeLayer(geosampaOfflineLayer);
    geosampaOfflineConfirmed = false;
    refreshSatelliteOpacity();
    updateMapZoomPercentLabel();
    setStatus("GeoSampa - Offline desligado.");
  }
});

/**
 * Zoom da última vista «Home» (0% no indicador). `null` até o primeiro encaixe de bounds.
 * @type {number | null}
 */
let mapZoomPctBaselineZ = null;

/**
 * Extremos do indicador %: 100% = detalhe nativo do satélite activo (ou maxZoom).
 */
function getZoomPercentExtents() {
  let zMax = map.getMaxZoom();
  if (map.hasLayer(satelliteLayer)) {
    zMax = satelliteLayer.options.maxNativeZoom ?? satelliteLayer.options.maxZoom ?? 19;
  } else if (map.hasLayer(satelliteLocalLayer)) {
    zMax = satelliteLocalLayer.options.maxNativeZoom ?? 17;
  } else if (map.hasLayer(geosampaOfflineLayer)) {
    zMax = geosampaOfflineLayer.options.maxNativeZoom ?? 19;
  }
  return { zMax };
}

/**
 * Define 0% = zoom actual após vista Home; impede afastar mais que esse nível (`setMinZoom`).
 */
function applyZoomPctBaselineFromCurrentView() {
  const z = map.getZoom();
  mapZoomPctBaselineZ = z;
  map.setMinZoom(Math.max(MAP_ORIG_MIN_ZOOM, z));
  updateMapZoomPercentLabel();
}

function updateMapZoomPercentLabel() {
  const el = document.getElementById("map-zoom-pct-value");
  if (!el) return;
  if (mapZoomPctBaselineZ == null) {
    el.textContent = "—";
    return;
  }
  const { zMax } = getZoomPercentExtents();
  const z0 = mapZoomPctBaselineZ;
  const span = Math.max(1e-6, zMax - z0);
  const z = map.getZoom();
  const pct = ((z - z0) / span) * 100;
  el.textContent = `${Math.round(Math.max(0, Math.min(100, pct)))}%`;
}

/** Percentagem 0–100 igual ao indicador %; `null` se ainda não há baseline da vista Home. */
function getCurrentMapZoomPercent() {
  if (mapZoomPctBaselineZ == null) return null;
  const { zMax } = getZoomPercentExtents();
  const z0 = mapZoomPctBaselineZ;
  const span = Math.max(1e-6, zMax - z0);
  const z = map.getZoom();
  return ((z - z0) / span) * 100;
}

/** Acima deste valor no indicador %, bairros e vias passam a ser mostrados automaticamente (se o zoom Leaflet permitir). */
const MAP_ZOOM_PCT_AUTO_BAIRROS_VIAS = 50;

/**
 * Indicador de zoom ≥ 50%: activa checkboxes e camadas de bairros (z≥12) e vias (z≥13).
 * Não desliga camadas quando o % baixa — só reforça o comportamento «aproximar para ver detalhe».
 */
function maybeAutoShowBairrosEViasByZoomPercent() {
  const pct = getCurrentMapZoomPercent();
  if (pct == null || pct < MAP_ZOOM_PCT_AUTO_BAIRROS_VIAS) return;
  const cfg = getEffectiveLayerZoomCfg();
  const z = map.getZoom();
  const cbBairros = document.getElementById("bairros_alvo_sp");
  const cbVias = document.getElementById("vias_alvo_sp");
  if (z >= cfg.bairrosEnableMin) {
    if (cbBairros && !cbBairros.checked) cbBairros.checked = true;
    if (cbBairros?.checked && !map.hasLayer(bairrosAlvoLayer)) bairrosAlvoLayer.addTo(map);
  }
  if (z >= cfg.viasEnableMin) {
    if (cbVias && !cbVias.checked) cbVias.checked = true;
    if (cbVias?.checked && !map.hasLayer(viasAlvoLayer)) viasAlvoLayer.addTo(map);
  }
}

function initMapZoomPercentIndicator() {
  const topLeft = map.getContainer().querySelector(".leaflet-top.leaflet-left");
  if (!topLeft || document.getElementById("map-zoom-pct-value")) return;
  const zoomCtrl = topLeft.querySelector(".leaflet-control-zoom");
  if (!zoomCtrl) return;

  const strip = L.DomUtil.create("div", "leaflet-control map-zoom-strip");
  topLeft.insertBefore(strip, zoomCtrl);
  strip.appendChild(zoomCtrl);

  const bar = L.DomUtil.create("div", "leaflet-bar leaflet-control map-zoom-pct");
  const inner = L.DomUtil.create("span", "map-zoom-pct__value", bar);
  inner.id = "map-zoom-pct-value";
  inner.textContent = "—";
  inner.setAttribute(
    "title",
    "Zoom: 0% = vista Home actual (não é possível afastar mais); 100% = detalhe máximo nativo do satélite activo (ou máximo do mapa sem satélite)."
  );
  strip.appendChild(bar);

  L.DomEvent.disableClickPropagation(strip);
  L.DomEvent.disableScrollPropagation(strip);
  map.on("zoom zoomend", updateMapZoomPercentLabel);
  updateMapZoomPercentLabel();
}

// ── Utilitários ───────────────────────────────────────────────────────────

/**
 * Exibe mensagem de estado no rodapé da sidebar.
 * Convenção: sucessos são frases simples; erros seguem o padrão
 * "Falha em [recurso]. [Instrução de remediação] (ver docs/[RUNBOOK].md)."
 * @param {string} message
 */
function setStatus(message) {
  statusEl.textContent = message;
}

function initLayerZoomConfigUI() {
  const overrideEl = document.getElementById("cfg-zoom-override");
  const bEnEl = document.getElementById("cfg-zoom-bairros-enable");
  const bDisEl = document.getElementById("cfg-zoom-bairros-disable");
  const vEnEl = document.getElementById("cfg-zoom-vias-enable");
  const vDisEl = document.getElementById("cfg-zoom-vias-disable");
  const btnSave = document.getElementById("cfg-zoom-save");
  const btnReset = document.getElementById("cfg-zoom-reset");
  if (!overrideEl || !bEnEl || !bDisEl || !vEnEl || !vDisEl || !btnSave || !btnReset) return;

  function fillForm() {
    const cfg = readLayerZoomCfg();
    overrideEl.checked = !!cfg.override;
    bEnEl.value = String(cfg.bairrosEnableMin);
    bDisEl.value = String(cfg.bairrosDisableBelow);
    vEnEl.value = String(cfg.viasEnableMin);
    vDisEl.value = String(cfg.viasDisableBelow);
  }

  btnSave.addEventListener("click", () => {
    const nextCfg = {
      override: overrideEl.checked,
      bairrosEnableMin: clampZoomLevel(bEnEl.value, DEFAULT_LAYER_ZOOM_CFG.bairrosEnableMin),
      bairrosDisableBelow: clampZoomLevel(bDisEl.value, DEFAULT_LAYER_ZOOM_CFG.bairrosDisableBelow),
      viasEnableMin: clampZoomLevel(vEnEl.value, DEFAULT_LAYER_ZOOM_CFG.viasEnableMin),
      viasDisableBelow: clampZoomLevel(vDisEl.value, DEFAULT_LAYER_ZOOM_CFG.viasDisableBelow),
    };
    localStorage.setItem(LAYER_ZOOM_CFG_STORAGE_KEY, JSON.stringify(nextCfg));
    fillForm();
    map.fire("zoomend");
    setStatus(
      nextCfg.override
        ? "Configuração de zoom aplicada (sobreposição ativa)."
        : "Configuração de zoom salva (regras atuais preservadas)."
    );
  });

  btnReset.addEventListener("click", () => {
    localStorage.removeItem(LAYER_ZOOM_CFG_STORAGE_KEY);
    fillForm();
    map.fire("zoomend");
    setStatus("Configuração de zoom resetada para o padrão.");
  });

  fillForm();
}

/**
 * Enquadra o mapa num bbox WGS84.
 * @param {number} minLon @param {number} minLat
 * @param {number} maxLon @param {number} maxLat
 */
function fitBounds(minLon, minLat, maxLon, maxLat) {
  map.fitBounds([
    [minLat, minLon],
    [maxLat, maxLon],
  ]);
}

/**
 * Vista inicial: inset = metade da extensão em proporção ao bbox (menor inset ⇒ mais zoom).
 * @param {number} [lonInsetFactor=1] — só longitude; valor menor que 1 aperta o enquadramento horizontal
 *   (útil com satélite local + ecrã largo, para reduzir letterbox lateral).
 */
function fitBoundsHomeInset(minLon, minLat, maxLon, maxLat, inset, lonInsetFactor = 1) {
  const cLat = (minLat + maxLat) / 2;
  const cLon = (minLon + maxLon) / 2;
  const hLat = ((maxLat - minLat) / 2) * inset;
  const hLon = ((maxLon - minLon) / 2) * inset * lonInsetFactor;
  map.fitBounds([
    [cLat - hLat, cLon - hLon],
    [cLat + hLat, cLon + hLon],
  ]);
}

/** Mapa em tela cheia: ~4% menos zoom que inset 0,9 (área visível um pouco maior). */
const HOME_INSET_FULL = 0.9 * 1.04;

/** Com painel 50%: ~8% mais zoom que a mesma cena em tela cheia (compensa metade da largura). */
const HOME_INSET_SPLIT = HOME_INSET_FULL / 1.08;

/** Mapa no quadrante inferior direito (layout CC): enquadramento ligeiramente distinto do 50/50. */
const HOME_INSET_CCC = HOME_INSET_SPLIT * 0.94;

/**
 * Com satélite local MBTiles: ligeira compressão só em longitude no Home (ecrãs muito largos
 * mostram mais lon que o rect vertical «cabe»; isto aproxima a moldura da cobertura raster).
 */
const HOME_LOCAL_SAT_LON_INSET_FACTOR = 0.88;

const OPER_LAYOUT_STORAGE_KEY = "tabgis_oper_layout";

/** @type {Map<string, object>} última listagem OMS por id (detalhe + marcadores). */
let workOrderRowsById = new Map();

/** Última resposta bruta da API (ordenação client-side). */
let workOrdersListCache = [];

/** Estado da ordenação na grelha OMS. */
const omsSortState = { key: null, dir: /** @type {'asc' | 'desc'} */ ("asc") };

/**
 * Constrói a string BBOX em EPSG:3857 para os pedidos WMS GetFeatureInfo.
 * O GeoServer 1.1.1 espera BBOX no SRS da camada (3857 quando publicado em WebMercator).
 * @returns {string} "minX,minY,maxX,maxY"
 */
function bbox3857String() {
  const b = map.getBounds();
  const crs = map.options.crs;
  const corners = [b.getNorthWest(), b.getNorthEast(), b.getSouthEast(), b.getSouthWest()]
    .map((ll) => crs.project(ll));
  const xs = corners.map((p) => p.x);
  const ys = corners.map((p) => p.y);
  return [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)].join(",");
}

/**
 * Enquadra o mapa em torno de uma FeatureCollection GeoJSON.
 * maxZoom:16 impede zoom excessivo em polígonos muito pequenos.
 * @param {object} data - GeoJSON FeatureCollection
 */
function fitMapToGeoJSONFeatureCollection(data) {
  if (!data || !data.features || !data.features.length) {
    setStatus("Nenhuma geometria encontrada.");
    return;
  }
  const gj = L.geoJSON(data);
  const bounds = gj.getBounds();
  if (bounds.isValid()) map.fitBounds(bounds, { maxZoom: 16 });
}

// ── Estado de saúde do TileServer local ──────────────────────────────────────

/**
 * Confirmado como true após fetch bem-sucedido ao endpoint de metadados do TileServer.
 * Enquanto false, qualquer tileerror é reportado como falha de infraestrutura.
 * Quando true, 404s de tiles fora da cobertura são silenciados — comportamento
 * normal para MBTiles de área parcial (bbox capital SP não cobre o estado inteiro).
 */
let satelliteLocalConfirmed = false;
let geosampaOfflineConfirmed = false;

/**
 * Bounds WGS84 do MBTiles (west,south,east,north) vindos do TileJSON, se disponíveis.
 * @type {null | { west: number, south: number, east: number, north: number }}
 */
let spSatMbtilesBounds = null;

/**
 * Cruza o intervalo de longitude do Home com a extensão declarada do MBTiles,
 * para não enquadrar área fora dos tiles (faixas laterais vazias).
 * @returns {{ minLon: number, maxLon: number }}
 */
function clipHomeLonToSpSatMbtiles(minLon, maxLon) {
  const t = spSatMbtilesBounds;
  if (!t) return { minLon, maxLon };
  const { west, east } = t;
  if (!Number.isFinite(west) || !Number.isFinite(east) || east <= west) {
    return { minLon, maxLon };
  }
  let a = Math.max(minLon, west);
  let b = Math.min(maxLon, east);
  if (b <= a) {
    return { minLon: west, maxLon: east };
  }
  return { minLon: a, maxLon: b };
}

/**
 * Verifica a disponibilidade do TileServer consultando o endpoint de metadados
 * do dataset (não depende de coordenadas específicas de tile).
 * Devolve os metadados em caso de sucesso, ou lança excepção se inacessível.
 * @returns {Promise<object>}
 */
async function checkLocalRasterHealth(datasetId) {
  const res = await fetch(`${getLocalTilesBase()}/data/${datasetId}.json`, {
    signal: AbortSignal.timeout(5000),
  });
  if (!res.ok) throw new Error(`TileServer respondeu HTTP ${res.status}`);
  const meta = await res.json();
  const b = meta.bounds;
  if (Array.isArray(b) && b.length >= 4) {
    const west = Number(b[0]);
    const south = Number(b[1]);
    const east = Number(b[2]);
    const north = Number(b[3]);
    if (
      [west, south, east, north].every(Number.isFinite) &&
      east > west &&
      north > south
    ) {
      spSatMbtilesBounds = { west, south, east, north };
    } else {
      spSatMbtilesBounds = null;
    }
  } else {
    spSatMbtilesBounds = null;
  }
  return meta;
}

// ── Busca no mapa (WFS — municípios e bairros). Filtros ficam para a parte tabular. ──

let municipiosGeoJSON = null;

function municipioNameFromFeature(f) {
  const p = f.properties || {};
  return p.nm_mun || p.NM_MUN || "";
}

/**
 * Carrega a lista de municípios via WFS e preenche a listbox.
 */
async function loadMunicipiosAlvoWfs() {
  const url = new URL(geoserverOws);
  url.searchParams.set("service", "WFS");
  url.searchParams.set("version", "1.0.0");
  url.searchParams.set("request", "GetFeature");
  url.searchParams.set("typeName", "base_sp:municipios_alvo_sp");
  url.searchParams.set("outputFormat", "application/json");
  url.searchParams.set("srsName", "EPSG:4326");

  const res = await fetch(url.toString());
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  municipiosGeoJSON = await res.json();

  const sel = document.getElementById("search-municipio");
  if (!sel) return;

  const names = (municipiosGeoJSON.features || [])
    .map(municipioNameFromFeature)
    .filter(Boolean)
    .sort();

  sel.innerHTML = `<option value="">${uiText("UI_SEARCH_SELECT_MUNI", "Selecione um município…")}</option>`;
  names.forEach((n) => {
    const opt = document.createElement("option");
    opt.value = n;
    opt.textContent = n;
    sel.appendChild(opt);
  });
}

async function onMunicipioSelected(name) {
  if (!name) {
    document.getElementById("search-bairro").innerHTML = `<option value="">${uiText("UI_SEARCH_NEED_MUNI_FIRST", "Selecione um município primeiro…")}</option>`;
    return;
  }
  const f = municipiosGeoJSON.features.find((x) => municipioNameFromFeature(x) === name);
  if (f) fitMapToGeoJSONFeatureCollection({ type: "FeatureCollection", features: [f] });
  await loadBairrosWfs(name);
}

/**
 * Carrega os bairros do município selecionado via WFS e preenche a listbox.
 */
async function loadBairrosWfs(municipioNome) {
  const sel = document.getElementById("search-bairro");
  sel.innerHTML = `<option value="">${uiText("UI_SEARCH_LOADING_BAIRROS", "Carregando bairros…")}</option>`;

  const cql = `municipio_nome = '${municipioNome.replace(/'/g, "''")}'`;

  const url = new URL(geoserverOws);
  url.searchParams.set("service", "WFS");
  url.searchParams.set("version", "1.0.0");
  url.searchParams.set("request", "GetFeature");
  url.searchParams.set("typeName", "base_sp:bairros_alvo_sp");
  url.searchParams.set("outputFormat", "application/json");
  url.searchParams.set("srsName", "EPSG:4326");
  url.searchParams.set("CQL_FILTER", cql);

  try {
    const res = await fetch(url.toString());
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const gj = await res.json();

    const bairros = (gj.features || [])
      .map(f => f.properties?.bairro_nome || "")
      .filter(Boolean)
      .sort();

    sel.innerHTML = `<option value="">${uiText("UI_SEARCH_SELECT_BAIRRO", "Selecione um bairro…")}</option>`;
    bairros.forEach((b) => {
      const opt = document.createElement("option");
      opt.value = b;
      opt.textContent = b;
      sel.appendChild(opt);
    });
    
    // Armazena o GeoJSON no elemento para uso posterior no zoom
    sel._bairrosGeoJSON = gj;
  } catch (e) {
    setStatus(
      `Falha na busca de bairros. Verifique GeoServer em ${geoserverBase} (ver docs/DEPLOY_POC.md).`
    );
  }
}

function onBairroSelected(bairroNome) {
  if (!bairroNome) return;
  const sel = document.getElementById("search-bairro");
  const gj = sel._bairrosGeoJSON;
  if (!gj) return;

  const f = gj.features.find((x) => (x.properties?.bairro_nome || "") === bairroNome);
  if (!f) return;
  fitMapToGeoJSONFeatureCollection({ type: "FeatureCollection", features: [f] });
  map.once("moveend", () => {
    const cfg = getEffectiveLayerZoomCfg();
    enableBairrosEViasNoMapa();
    if (map.getZoom() < cfg.viasEnableMin) {
      map.setZoom(cfg.viasEnableMin);
    }
    setStatus(`Bairro focado: ${bairroNome} — bairros e vias activos.`);
  });
}

/** Preferência: geocodificação em PostGIS vs Nominatim (localStorage). */
const ADDRESS_SEARCH_LOCAL_KEY = "tabgis_geocode_local";

/** Marcador temporário após geocodificação. */
let addressSearchPulseMarker = null;

function initAddressSearch() {
  const input = document.getElementById("search-address");
  const btn = document.getElementById("search-address-btn");
  const ul = document.getElementById("search-address-results");
  const localCb = document.getElementById("search-address-local");
  const hintEl = document.querySelector(".search-address-hint");
  if (!input || !btn || !ul) return;

  function updateAddressSearchHint() {
    if (!hintEl) return;
    const local = localCb instanceof HTMLInputElement && localCb.checked;
    hintEl.textContent = local
      ? uiText(
          "UI_SEARCH_ADDRESS_HINT_LOCAL",
          "Busca só nomes de vias nos municípios-alvo (PostGIS). Sem número de porta. Não usa Internet."
        )
      : uiText(
          "UI_SEARCH_ADDRESS_HINT",
          "Busca em linha (Nominatim / OSM), com prioridade na região de São Paulo. Requer Internet."
        );
  }

  if (localCb instanceof HTMLInputElement) {
    localCb.checked = localStorage.getItem(ADDRESS_SEARCH_LOCAL_KEY) === "1";
    localCb.addEventListener("change", () => {
      localStorage.setItem(ADDRESS_SEARCH_LOCAL_KEY, localCb.checked ? "1" : "0");
      updateAddressSearchHint();
    });
  }
  updateAddressSearchHint();

  async function runSearch() {
    const q = input.value.trim();
    if (q.length < 3) {
      setStatus(uiText("UI_SEARCH_ADDRESS_SHORT", "Digite pelo menos 3 caracteres."));
      return;
    }
    ul.innerHTML = "";
    ul.hidden = true;
    const useLocal = localCb instanceof HTMLInputElement && localCb.checked;
    const url = useLocal
      ? `/api/geocode-local?q=${encodeURIComponent(q)}`
      : `/api/geocode?q=${encodeURIComponent(q)}`;
    try {
      const res = await fetch(url);
      const data = await res.json();
      const results = Array.isArray(data.results) ? data.results : [];
      if (!results.length) {
        setStatus(uiText("UI_SEARCH_ADDRESS_NONE", "Nenhum resultado encontrado."));
        return;
      }
      results.forEach((item) => {
        const li = document.createElement("li");
        const hit = document.createElement("button");
        hit.type = "button";
        hit.className = "search-address-hit";
        hit.textContent = item.display_name || "—";
        hit.addEventListener("click", () => focusAddressSearchResult(item));
        li.appendChild(hit);
        ul.appendChild(li);
      });
      ul.hidden = false;
    } catch (e) {
      console.error(e);
      setStatus(
        useLocal
          ? uiText("UI_SEARCH_ADDRESS_FAIL_LOCAL", "Falha na busca local (base de dados).")
          : uiText("UI_SEARCH_ADDRESS_FAIL", "Falha na busca de endereço (rede ou serviço indisponível).")
      );
    }
  }

  function focusAddressSearchResult(item) {
    const lat = item.lat;
    const lon = item.lon;
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) return;
    focusMapWithVias(lat, lon, MAP_FOCUS_ZOOM_ADDRESS);
    if (addressSearchPulseMarker && map.hasLayer(addressSearchPulseMarker)) {
      map.removeLayer(addressSearchPulseMarker);
    }
    addressSearchPulseMarker = L.circleMarker([lat, lon], {
      radius: 9,
      color: "#0284c7",
      weight: 2,
      fillColor: "#38bdf8",
      fillOpacity: 0.88,
    });
    addressSearchPulseMarker.addTo(map);
    window.setTimeout(() => {
      if (addressSearchPulseMarker && map.hasLayer(addressSearchPulseMarker)) {
        map.removeLayer(addressSearchPulseMarker);
      }
      addressSearchPulseMarker = null;
    }, 14000);
    ul.hidden = true;
    setStatus(uiText("UI_SEARCH_ADDRESS_OK", "Endereço localizado no mapa."));
  }

  btn.addEventListener("click", runSearch);
  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") runSearch();
  });
}

// ── GetFeatureInfo (clique no mapa) ───────────────────────────────────────

/**
 * Devolve as camadas WMS visíveis para o pedido GFI, ordenadas do mais
 * específico (bairro/via alvo) para o mais genérico (UF).
 * A ordem importa porque o GeoServer devolve resultados pela mesma ordem.
 * Agora respeita os "pills" de seleção LAND.
 * @returns {string} lista separada por vírgulas
 */
function visibleQueryLayers() {
  const layers = [];
  
  const selBairrosLand = document.getElementById("sel_bairros_land");
  if (map.hasLayer(bairrosAlvoLayer) && (!selBairrosLand || selBairrosLand.checked)) {
    layers.push("base_sp:bairros_alvo_sp");
  }
  
  if (map.hasLayer(viasAlvoLayer)) {
    layers.push("base_sp:vias_alvo_sp");
  }
  
  const selMuniLand = document.getElementById("sel_muni_land");
  const muniLandActive = (!selMuniLand || selMuniLand.checked);

  if (map.hasLayer(municipiosAlvoLayer) && muniLandActive) {
    layers.push("base_sp:municipios_alvo_sp");
  }
  
  // Condiciona o popup do municipio de fundo (municipios_sp) à mesma flag LAND
  if (map.hasLayer(municipiosLayer) && muniLandActive) {
    layers.push("base_sp:municipios_sp");
  }
  
  // UF (Estado) fica sem popup ou desativado se não houver camadas para consultar
  // Se for o único, não gera popup poluente
  
  return layers.length ? layers.join(",") : "";
}

/** Escapa caracteres HTML para exibição segura em innerHTML/popup */
function escapeHtml(s) {
  const t = s == null ? "" : String(s);
  return t
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Converte a resposta GeoJSON do GFI em tabela HTML.
 * Filtra colunas de geometria que não têm utilidade para o utilizador.
 * @param {object} json - resposta GeoJSON do GeoServer
 * @returns {string} HTML da(s) tabela(s) de atributos
 */
function gfiJsonToHtml(json) {
  if (!json.features || !json.features.length) return "";
  return json.features
    .map((feat) => {
      const p = feat.properties || {};
      const rows = Object.entries(p)
        .filter(([k]) => k !== "geometry" && k !== "boundedBy")
        .map(
          ([k, v]) =>
            `<tr><th>${escapeHtml(k)}</th><td>${escapeHtml(String(v ?? ""))}</td></tr>`
        )
        .join("");
      return `<table class="gfi-table">${rows}</table>`;
    })
    .join("<hr/>");
}

function operDetailBodyEl() {
  return document.getElementById("oper-detail-body");
}

function setOperDetailMapQuery(html, latlng) {
  const body = operDetailBodyEl();
  if (!body) return;
  const title = uiText("UI_OP_DETAIL_MAP_QUERY", "Consulta ao mapa (GetFeatureInfo)");
  const sub =
    latlng != null
      ? `<p class="oper-detail-meta">${escapeHtml(`${latlng.lat.toFixed(5)}, ${latlng.lng.toFixed(5)}`)}</p>`
      : "";
  body.innerHTML = `<h4 class="oper-detail-heading">${escapeHtml(title)}</h4>${sub}<div class="oper-detail-scroll oper-detail-scroll--html">${html}</div>`;
}

function renderOperDetailPlaceholder() {
  const body = operDetailBodyEl();
  if (!body) return;
  body.innerHTML = `<p class="mock-hint oper-detail-empty">${escapeHtml(
    uiText("UI_OP_DETAIL_EMPTY", "Selecione uma ordem, uma equipe no painel ou uma feição no mapa.")
  )}</p>`;
}

function renderOperDetailWorkOrder(r) {
  const body = operDetailBodyEl();
  if (!body || !r) return;
  const title = uiText("UI_OP_DETAIL_ORDER", "Ordem de serviço");
  const loc = [r.municipality_name, r.neighborhood_name].filter(Boolean).join(" · ") || "—";
  const lines = [
    ["Código", r.order_code || `#${r.id}`],
    ["Resumo", r.summary || "—"],
    ["Estado", orderStatusLabel(r.status)],
    ["Categoria", orderCategoryLabel(r.category)],
    ["Tipo", orderTypeLabel(r.order_type)],
    ["Alimentador", r.feeder_code || "—"],
    ["Equipa", r.team_code || "—"],
    ["Responsável", r.owner_username || "—"],
    ["Bloqueio", r.locked_by_username || "—"],
    ["Actualização", formatUpdatedCompact(r.updated_at)],
    ["Local", loc],
    ["Equipamento", r.equipment_code || "—"],
    ["Descrição", r.description ? String(r.description).slice(0, 400) : "—"],
  ];
  const rows = lines
    .map(
      ([k, v]) =>
        `<tr><th>${escapeHtml(k)}</th><td>${escapeHtml(String(v))}</td></tr>`
    )
    .join("");
  body.innerHTML = `<h4 class="oper-detail-heading">${escapeHtml(title)}</h4><table class="oper-detail-table"><tbody>${rows}</tbody></table>`;
}

function renderOperDetailTeam(t) {
  const body = operDetailBodyEl();
  if (!body || !t) return;
  const title = uiText("UI_OP_DETAIL_TEAM", "Equipa em campo");
  const lines = [
    ["Equipa", t.team_code || "—"],
    ["Líder", t.leader_name || "—"],
    ["Skill", t.skill || "—"],
    ["Tipo", t.team_type || "—"],
    ["Unidade", t.owner_org || "—"],
    ["Zona", t.zone || "—"],
    ["Membros", t.member_count != null ? String(t.member_count) : "—"],
    ["Estado", teamStatusLabel(t.status)],
  ];
  const rows = lines
    .map(
      ([k, v]) =>
        `<tr><th>${escapeHtml(k)}</th><td>${escapeHtml(String(v))}</td></tr>`
    )
    .join("");
  body.innerHTML = `<h4 class="oper-detail-heading">${escapeHtml(title)}</h4><table class="oper-detail-table"><tbody>${rows}</tbody></table>`;
}

/**
 * Executa GetFeatureInfo WMS no ponto clicado.
 * Estratégia de fallback:
 *   1. Tenta JSON (mais rico e estruturado).
 *   2. Se JSON vazio ou não parsável, tenta text/html (resposta legível do GeoServer).
 * O popup abre na posição geográfica do clique, não no píxel do ecrã.
 * @param {L.LeafletMouseEvent} ev
 */
async function getFeatureInfoAtEvent(ev) {
  const queryLayers = visibleQueryLayers();
  if (!queryLayers) return; // Se não há nenhuma camada selecionável ativada, cancela o clique

  const size = map.getSize();
  const pt = map.mouseEventToContainerPoint(ev.originalEvent);
  const x = Math.floor(pt.x);
  const y = Math.floor(pt.y);
  const bbox = bbox3857String();

  function buildUrl(infoFormat) {
    const url = new URL(geoserverWms);
    url.searchParams.set("SERVICE", "WMS");
    url.searchParams.set("VERSION", "1.1.1");
    url.searchParams.set("REQUEST", "GetFeatureInfo");
    url.searchParams.set("LAYERS", queryLayers);
    url.searchParams.set("QUERY_LAYERS", queryLayers);
    url.searchParams.set("BBOX", bbox);
    url.searchParams.set("WIDTH", String(size.x));
    url.searchParams.set("HEIGHT", String(size.y));
    url.searchParams.set("X", String(x));
    url.searchParams.set("Y", String(y));
    url.searchParams.set("SRS", "EPSG:3857");
    url.searchParams.set("INFO_FORMAT", infoFormat);
    url.searchParams.set("FEATURE_COUNT", "20");
    return url.toString();
  }

  let html = "";
  try {
    // Tentativa 1: JSON estruturado
    let res = await fetch(buildUrl("application/json"));
    let text = await res.text();
    let jsonParsedOk = false;
    try {
      const json = JSON.parse(text);
      jsonParsedOk = true;
      html = gfiJsonToHtml(json);
    } catch {
      html = "";
    }
    // Só mostrar corpo bruto se *não* for JSON válido (evita FeatureCollection vazio cru no ecrã)
    if (!html && !jsonParsedOk && text.length && text.length < 4000) {
      html = `<pre>${escapeHtml(text)}</pre>`;
    }
    // Tentativa 2: text/html nativo do GeoServer
    if (!html) {
      res = await fetch(buildUrl("text/html"));
      text = await res.text();
      if (text && !text.includes("ServiceException")) html = text;
    }
  } catch (e) {
    html = `<p>${escapeHtml(
      `Falha ao consultar feição. Verifique GeoServer em ${geoserverBase} (ver docs/DEPLOY_POC.md).`
    )}</p>`;
  }
  if (!html) {
    html = `<p>${escapeHtml(uiText("UI_GFI_EMPTY_POINT", "Nenhuma feição identificada neste ponto."))}</p>`;
  }
  L.popup({ autoPanPaddingTopLeft: [0, 80] }).setLatLng(ev.latlng).setContent(html).openOn(map);
  const appEl = document.querySelector(".app");
  if (
    appEl?.classList.contains("has-left-panel") &&
    appEl.classList.contains("app--oper-layout-ccc")
  ) {
    setOperDetailMapQuery(html, ev.latlng);
  }
}

// ── Inicialização ─────────────────────────────────────────────────────────

// Função Home: visão dependente do estado do painel lateral (mesmos parâmetros que ao abrir a URL)
function setHomeView() {
  // `applyZoomPctBaselineFromCurrentView` fixa minZoom ao zoom actual; sem repor aqui, um Home
  // subsequente pode precisar de mais zoom-out do que o minZoom permite e o fit falha em silêncio.
  map.setMinZoom(MAP_ORIG_MIN_ZOOM);
  map.invalidateSize();
  const appEl = document.querySelector(".app");
  const split = appEl?.classList.contains("has-left-panel");
  const ccc = split && appEl?.classList.contains("app--oper-layout-ccc");
  requestAnimationFrame(() => {
    map.invalidateSize();
    const useLocalSat = map.hasLayer(satelliteLocalLayer) && spSatMbtilesBounds != null;
    const lonFac = useLocalSat ? HOME_LOCAL_SAT_LON_INSET_FACTOR : 1;
    if (ccc) {
      let minLon = -47.2496;
      let maxLon = -46.2513;
      if (useLocalSat) {
        const cl = clipHomeLonToSpSatMbtiles(minLon, maxLon);
        minLon = cl.minLon;
        maxLon = cl.maxLon;
      }
      fitBoundsHomeInset(
        minLon,
        -24.1088,
        maxLon,
        -23.1966,
        HOME_INSET_CCC,
        lonFac
      );
    } else if (split) {
      let minLon = -47.2496;
      let maxLon = -46.2513;
      if (useLocalSat) {
        const cl = clipHomeLonToSpSatMbtiles(minLon, maxLon);
        minLon = cl.minLon;
        maxLon = cl.maxLon;
      }
      fitBoundsHomeInset(
        minLon,
        -24.1088,
        maxLon,
        -23.1966,
        HOME_INSET_SPLIT,
        lonFac
      );
    } else {
      let minLon = -47.648;
      let maxLon = -45.918;
      if (useLocalSat) {
        const cl = clipHomeLonToSpSatMbtiles(minLon, maxLon);
        minLon = cl.minLon;
        maxLon = cl.maxLon;
      }
      fitBoundsHomeInset(
        minLon,
        -24.0674,
        maxLon,
        -23.2733,
        HOME_INSET_FULL,
        lonFac
      );
    }
    window.setTimeout(() => {
      applyZoomPctBaselineFromCurrentView();
    }, 400);
  });
}

/** Mensagem inicial só uma vez; setHomeView pode repetir-se após o contentor ganhar altura. */
let mapInitialStatusDone = false;
function runInitialMapLayout() {
  try {
    setHomeView();
  } catch (e) {
    console.error(e);
  }
  if (!mapInitialStatusDone) {
    mapInitialStatusDone = true;
    setStatus("Mapa carregado.");
  }
  setTimeout(() => {
    refreshOmsMarkersForZoom();
  }, 450);
}

map.whenReady(() => {
  requestAnimationFrame(runInitialMapLayout);
  initMapZoomPercentIndicator();
});

// Respaldo: contentor flex às vezes só tem altura definitiva após pintura
setTimeout(runInitialMapLayout, 400);

document.getElementById("search-municipio").addEventListener("change", (e) => onMunicipioSelected(e.target.value));
document.getElementById("search-bairro").addEventListener("change", (e) => onBairroSelected(e.target.value));
initAddressSearch();
initLayerZoomConfigUI();
document.getElementById("btn-home").addEventListener("click", setHomeView);

// Lógica do Painel Esquerdo (Operação)
const btnOperacao = document.getElementById("btn-operacao");
const btnCloseOperacao = document.getElementById("btn-close-operacao");
const appContainer = document.querySelector(".app");

function readOperLayoutMode() {
  const v = localStorage.getItem(OPER_LAYOUT_STORAGE_KEY);
  return v === "split" ? "split" : "ccc";
}

function writeOperLayoutMode(mode) {
  localStorage.setItem(OPER_LAYOUT_STORAGE_KEY, mode === "split" ? "split" : "ccc");
}

function applyOperLayoutClasses() {
  if (!appContainer.classList.contains("has-left-panel")) {
    appContainer.classList.remove("app--oper-layout-ccc", "app--oper-layout-split");
    return;
  }
  const mode = readOperLayoutMode();
  appContainer.classList.toggle("app--oper-layout-ccc", mode === "ccc");
  appContainer.classList.toggle("app--oper-layout-split", mode === "split");
  const operCccCb = document.getElementById("oper-layout-ccc-focus");
  if (operCccCb instanceof HTMLInputElement) operCccCb.checked = mode === "ccc";
  if (mode === "ccc") renderOperDetailPlaceholder();
  else {
    const body = operDetailBodyEl();
    if (body) body.innerHTML = "";
  }
}

function toggleLeftPanel() {
  const isOpening = !appContainer.classList.contains("has-left-panel");
  appContainer.classList.toggle("has-left-panel");
  if (appContainer.classList.contains("has-left-panel")) {
    applyOperLayoutClasses();
  } else {
    appContainer.classList.remove("app--oper-layout-ccc", "app--oper-layout-split");
  }

  // Aguardar a transição CSS (300ms) para invalidar o tamanho do mapa
  setTimeout(() => {
    map.invalidateSize();
    if (isOpening) {
      setHomeView();
      loadWorkOrdersFromApi();
      loadTeamsFromApi();
    }
  }, 300);
}

btnOperacao.addEventListener("click", toggleLeftPanel);
btnCloseOperacao.addEventListener("click", toggleLeftPanel);

(function initOperLayoutPicker() {
  const operCccCb = document.getElementById("oper-layout-ccc-focus");
  if (!(operCccCb instanceof HTMLInputElement)) return;
  operCccCb.checked = readOperLayoutMode() === "ccc";
  operCccCb.addEventListener("change", () => {
    writeOperLayoutMode(operCccCb.checked ? "ccc" : "split");
    applyOperLayoutClasses();
    setTimeout(() => {
      map.invalidateSize();
      setHomeView();
      refreshOmsMarkersForZoom();
    }, 320);
  });
})();

(function initToggleMwmRoutesButton() {
  const btn = document.getElementById("btn-toggle-mwm-routes");
  if (!btn) return;
  const labelSpan = btn.querySelector("span");
  btn.addEventListener("click", () => {
    const visible = map.hasLayer(mwmDemoCrewRoutesGroup);
    if (visible) {
      map.removeLayer(mwmDemoCrewRoutesGroup);
      btn.classList.add("mock-btn-ir--secondary");
      btn.setAttribute("aria-pressed", "false");
      if (labelSpan) labelSpan.textContent = "Exibir equipes em rota";
    } else {
      loadMwmDemoFieldRoutes().then(() => {
        mwmDemoCrewRoutesGroup.addTo(map);
      });
      btn.classList.remove("mock-btn-ir--secondary");
      btn.setAttribute("aria-pressed", "true");
      if (labelSpan) labelSpan.textContent = "Ocultar equipes em rota";
    }
  });
})();

(function initOmsOrdersTableSort() {
  const thead = document.querySelector("#oms-orders-table thead");
  if (!thead) return;
  thead.addEventListener("click", (e) => {
    const th = e.target.closest("th[data-wo-sort]");
    if (!th || workOrdersListCache.length === 0) return;
    const key = th.getAttribute("data-wo-sort");
    if (!key) return;
    if (omsSortState.key === key) {
      omsSortState.dir = omsSortState.dir === "asc" ? "desc" : "asc";
    } else {
      omsSortState.key = key;
      omsSortState.dir = "asc";
    }
    renderOmsOrderRowsToTbody(getOmsSortedRows());
    updateOmsSortHeaderUI();
    refreshOmsMarkersForZoom();
    const lang = document.getElementById("select-language")?.value || "pt";
    loadTranslations(lang);
  });
  thead.addEventListener("keydown", (e) => {
    if (e.key !== "Enter" && e.key !== " ") return;
    const th = e.target.closest("th[data-wo-sort]");
    if (!th) return;
    e.preventDefault();
    th.click();
  });
})();

/** Centro da previsão Open-Meteo (capital SP). */
const WEATHER_REF_LAT = -23.55052;
const WEATHER_REF_LNG = -46.633308;

let tabgisWeatherPopupHtml =
  "<p>Carregue a previsão com «Atualizar previsão» para ver o resumo no mapa.</p>";

const weatherOverlayGroup = L.layerGroup();
let rainRadarCache = { urlTemplate: null, fetchedAt: 0 };

async function getRainViewerTileUrlTemplate() {
  const now = Date.now();
  if (rainRadarCache.urlTemplate && now - rainRadarCache.fetchedAt < 300000) {
    return rainRadarCache.urlTemplate;
  }
  const r = await fetch("https://api.rainviewer.com/public/weather-maps.json");
  if (!r.ok) throw new Error("RainViewer API");
  const j = await r.json();
  const past = j.radar && j.radar.past;
  if (!past || !past.length) throw new Error("RainViewer sem frames");
  const last = past[past.length - 1];
  const host = String(j.host || "https://tilecache.rainviewer.com").replace(/\/$/, "");
  const urlTemplate = `${host}${last.path}/256/{z}/{x}/{y}/2/1_1.png`;
  rainRadarCache = { urlTemplate, fetchedAt: now };
  return urlTemplate;
}

function setWeatherMapStatus(msg, show) {
  const el = document.getElementById("weather-map-map-status");
  if (!el) return;
  el.textContent = msg || "";
  el.hidden = !show;
  el.style.color = show ? "var(--danger, #f87171)" : "";
}

async function syncWeatherMapOverlays() {
  const radarCb = document.getElementById("weather-map-show-radar");
  const refCb = document.getElementById("weather-map-show-ref");
  const opacityEl = document.getElementById("weather-map-opacity");
  const wantRadar = !!(radarCb && radarCb.checked);
  const wantRef = !!(refCb && refCb.checked);
  const op = Math.min(
    0.9,
    Math.max(0.12, parseFloat(opacityEl && opacityEl.value !== "" ? opacityEl.value : "0.5"))
  );

  if (!wantRadar && !wantRef) {
    if (map.hasLayer(weatherOverlayGroup)) map.removeLayer(weatherOverlayGroup);
    weatherOverlayGroup.clearLayers();
    setWeatherMapStatus("", false);
    return;
  }

  setWeatherMapStatus("", false);
  weatherOverlayGroup.clearLayers();

  if (wantRef) {
    const circ = L.circle([WEATHER_REF_LAT, WEATHER_REF_LNG], {
      radius: 22000,
      color: "#38bdf8",
      weight: 1,
      fillColor: "#0ea5e9",
      fillOpacity: 0.07,
      pane: "overlayPane",
    });
    circ.bindPopup(
      `<div class="weather-map-popup" style="max-width:280px">${tabgisWeatherPopupHtml}</div>`,
      { maxWidth: 300 }
    );
    weatherOverlayGroup.addLayer(circ);
  }

  if (wantRadar) {
    try {
      const urlTemplate = await getRainViewerTileUrlTemplate();
      const tl = L.tileLayer(urlTemplate, {
        pane: "weatherRadar",
        opacity: op,
        maxZoom: 20,
        maxNativeZoom: 10,
        attribution:
          'Radar <a href="https://www.rainviewer.com/api.html" target="_blank" rel="noopener noreferrer">RainViewer</a>',
      });
      weatherOverlayGroup.addLayer(tl);
    } catch {
      setWeatherMapStatus("Radar RainViewer indisponível (rede ou API).", true);
    }
  }

  if (!map.hasLayer(weatherOverlayGroup)) weatherOverlayGroup.addTo(map);
}

function applyWeatherRadarOpacityOnly() {
  const opacityEl = document.getElementById("weather-map-opacity");
  const op = Math.min(
    0.9,
    Math.max(0.12, parseFloat(opacityEl && opacityEl.value !== "" ? opacityEl.value : "0.5"))
  );
  weatherOverlayGroup.eachLayer((layer) => {
    if (layer instanceof L.TileLayer) layer.setOpacity(op);
  });
}

/**
 * Clima indicativo (São Paulo centro) — Open-Meteo, sem chave API.
 * @see https://open-meteo.com/en/terms
 */
async function loadWeatherOpenMeteo() {
  const statusEl = document.getElementById("weather-panel-status");
  const body = document.getElementById("weather-panel-body");
  if (!body) return;
  const setErr = (msg) => {
    if (statusEl) {
      statusEl.textContent = msg;
      statusEl.hidden = false;
      statusEl.style.color = "var(--danger, #f87171)";
    }
  };
  const clearErr = () => {
    if (statusEl) {
      statusEl.hidden = true;
      statusEl.textContent = "";
      statusEl.style.color = "";
    }
  };
  clearErr();
  body.innerHTML = '<p class="mock-hint">A carregar dados meteorológicos…</p>';
  const url =
    "https://api.open-meteo.com/v1/forecast?latitude=-23.55052&longitude=-46.633308" +
    "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,apparent_temperature" +
    "&timezone=America%2FSao_Paulo&wind_speed_unit=kmh";
  const wmoLabel = (code) => {
    const m = {
      0: "Céu limpo",
      1: "Principalmente limpo",
      2: "Parcialmente nublado",
      3: "Nublado",
      45: "Nevoeiro",
      48: "Nevoeiro com geada",
      51: "Chuvisco leve",
      61: "Chuva fraca",
      63: "Chuva moderada",
      65: "Chuva forte",
      80: "Aguaceiros",
      95: "Trovoada",
      96: "Trovoada com granizo",
    };
    return m[code] != null ? m[code] : `Condição (código WMO ${code})`;
  };
  try {
    const r = await fetch(url);
    if (!r.ok) throw new Error(String(r.status));
    const j = await r.json();
    const c = j.current;
    if (!c) throw new Error("no current");
    const t = c.temperature_2m;
    const ap = c.apparent_temperature;
    const rh = c.relative_humidity_2m;
    const w = c.wind_speed_10m;
    const wd = c.wind_direction_10m;
    const wc = c.weather_code;
    const time = c.time || "";
    body.innerHTML = `
      <div class="weather-card weather-card--wide">
        <div class="weather-card__label">Resumo</div>
        <div class="weather-card__value" style="font-size:1rem;font-weight:500;">${escapeHtml(wmoLabel(wc))}</div>
        <div class="mock-hint" style="margin-top:6px;font-size:11px;">Observação: ${escapeHtml(time)} (America/Sao_Paulo)</div>
      </div>
      <div class="weather-card">
        <div class="weather-card__label">Temperatura</div>
        <div class="weather-card__value">${t != null ? `${Number(t).toFixed(1)} °C` : "—"}</div>
      </div>
      <div class="weather-card">
        <div class="weather-card__label">Sensação</div>
        <div class="weather-card__value">${ap != null ? `${Number(ap).toFixed(1)} °C` : "—"}</div>
      </div>
      <div class="weather-card">
        <div class="weather-card__label">Humidade</div>
        <div class="weather-card__value">${rh != null ? `${rh} %` : "—"}</div>
      </div>
      <div class="weather-card">
        <div class="weather-card__label">Vento</div>
        <div class="weather-card__value">${w != null ? `${Number(w).toFixed(0)} km/h` : "—"}</div>
        <div class="mock-hint" style="margin-top:4px;font-size:11px;">${wd != null ? `Direcção ${wd}°` : ""}</div>
      </div>`;
    tabgisWeatherPopupHtml = `<strong>Referência SP (Open-Meteo)</strong><br/>${escapeHtml(
      wmoLabel(wc)
    )}<br/><small>${escapeHtml(time)}</small><br/>Temp.: ${
      t != null ? `${Number(t).toFixed(1)} °C` : "—"
    } · Hum.: ${rh != null ? `${rh} %` : "—"}<br/>Vento: ${
      w != null ? `${Number(w).toFixed(0)} km/h` : "—"
    }${wd != null ? ` · Dir. ${wd}°` : ""}`;
    void syncWeatherMapOverlays();
  } catch {
    setErr("Falha ao obter previsão (Open-Meteo). Verifique ligação à Internet.");
    body.innerHTML =
      '<p class="mock-hint">Sem dados. Utilize «Atualizar previsão» ou confirme acesso a api.open-meteo.com a partir do browser.</p>';
  }
}

document.getElementById("btn-weather-refresh")?.addEventListener("click", () => {
  loadWeatherOpenMeteo();
});

document.getElementById("weather-map-show-radar")?.addEventListener("change", () => {
  void syncWeatherMapOverlays();
});
document.getElementById("weather-map-show-ref")?.addEventListener("change", () => {
  void syncWeatherMapOverlays();
});
document.getElementById("weather-map-opacity")?.addEventListener("input", () => {
  applyWeatherRadarOpacityOnly();
});

// Guias do painel Operação (OMS, MWM, IND, …)
(function initOperacaoTabs() {
  const bar = document.querySelector(".operacao-tab-bar");
  if (!bar) return;

  bar.addEventListener("click", (e) => {
    const tab = e.target.closest(".operacao-tab");
    if (!tab || !bar.contains(tab)) return;

    const id = tab.getAttribute("data-tab");
    if (!id) return;

    bar.querySelectorAll(".operacao-tab").forEach((btn) => {
      const on = btn === tab;
      btn.classList.toggle("active", on);
      btn.setAttribute("aria-selected", on ? "true" : "false");
    });

    document.querySelectorAll(".operacao-panel").forEach((panel) => {
      const on = panel.getAttribute("data-panel") === id;
      panel.classList.toggle("active", on);
    });

    if (id === "oms") loadWorkOrdersFromApi();
    if (id === "mwm") {
      loadTeamsFromApi();
      loadMwmDemoFieldRoutes().then(() => {
        if (!map.hasLayer(mwmDemoCrewRoutesGroup)) mwmDemoCrewRoutesGroup.addTo(map);
      });
    }
    if (id === "tmp") loadWeatherOpenMeteo();
    if (id === "aud") loadAuditArchiveFromApi();
  });
})();

const ORDER_CATEGORY_I18N = {
  repair: "UI_OP_CAT_REPAIR",
  complaint: "UI_OP_CAT_COMPLAINT",
  task: "UI_OP_CAT_TASK",
  event: "UI_OP_CAT_EVENT",
};

const ORDER_STATUS_I18N = {
  open: "UI_OP_ORDER_OPEN",
  in_progress: "UI_OP_ORDER_PROGRESS",
  scheduled: "UI_OP_ORDER_SCHEDULED",
  planned: "UI_OP_ORDER_PLANNED",
};

const ORDER_TYPE_I18N = {
  repair: "UI_OT_TYPE_REPAIR",
  maintenance: "UI_OT_TYPE_MAINTENANCE",
  inspection: "UI_OT_TYPE_INSPECTION",
  emergency: "UI_OT_TYPE_EMERGENCY",
  restoration: "UI_OT_TYPE_RESTORATION",
  incident: "UI_OT_TYPE_INCIDENT",
};

let selectedWorkOrderId = null;
let pocLockUserId = null;

function orderCategoryLabel(category) {
  const key = ORDER_CATEGORY_I18N[category];
  return (key && i18nCache[key]) || category || "—";
}

function orderStatusLabel(status) {
  const key = ORDER_STATUS_I18N[status];
  return (key && i18nCache[key]) || status || "—";
}

function orderTypeLabel(orderType) {
  const t = orderType || "";
  const key = ORDER_TYPE_I18N[t];
  return (key && i18nCache[key]) || t || "—";
}

function orderStatusBadgeClass(status) {
  if (status === "open") return "mock-badge mock-badge--warn";
  if (status === "planned") return "mock-badge mock-badge--muted";
  return "mock-badge mock-badge--ok";
}

function workOrderMarkerFillColor(status) {
  const s = (status || "").toLowerCase();
  if (s === "open") return "#f59e0b";
  if (s === "in_progress") return "#22c55e";
  if (s === "planned") return "#94a3b8";
  if (s === "scheduled") return "#3b82f6";
  return "#64748b";
}

function workOrderMarkerRadius(orderType) {
  const t = (orderType || "").toLowerCase();
  if (t === "emergency") return 11;
  if (t === "repair") return 9;
  if (t === "incident") return 8;
  if (t === "maintenance") return 7;
  if (t === "inspection") return 6;
  if (t === "restoration") return 8;
  return 7;
}

function workOrderTeamStrokeColor(teamId) {
  if (teamId == null) return "#e2e8f0";
  const hues = [12, 48, 175, 265, 320];
  const h = hues[Math.abs(Number(teamId)) % hues.length];
  return `hsl(${h} 72% 52%)`;
}

function rebuildWorkOrderMarkers(rows) {
  workOrderMarkersGroup.clearLayers();
  rows.forEach((r) => {
    const lat = r.focus_lat != null ? parseFloat(r.focus_lat) : NaN;
    const lng = r.focus_lng != null ? parseFloat(r.focus_lng) : NaN;
    if (Number.isNaN(lat) || Number.isNaN(lng)) return;
    const fill = workOrderMarkerFillColor(r.status);
    const rad = workOrderMarkerRadius(r.order_type || r.category);
    const stroke = workOrderTeamStrokeColor(r.assigned_team_id);
    const m = L.circleMarker([lat, lng], {
      radius: rad,
      color: stroke,
      weight: 2,
      fillColor: fill,
      fillOpacity: 0.82,
    });
    const code = r.order_code || `#${r.id}`;
    m.bindPopup(
      `<strong>${escapeHtml(code)}</strong><br/>${escapeHtml(r.summary || "")}<br/><span class="mock-hint">${escapeHtml(
        r.team_code || ""
      )}</span>`
    );
    m.on("click", () => {
      const full = workOrderRowsById.get(String(r.id));
      if (full) renderOperDetailWorkOrder(full);
    });
    m.addTo(workOrderMarkersGroup);
  });
}

function mwmDemoRouteColor(vehicleType) {
  const v = String(vehicleType || "").toUpperCase();
  if (v === "MOTO") return "#f97316";
  if (v === "CARRINHO") return "#0ea5e9";
  return "#22c55e";
}

function mwmDemoVehicleDivIcon(vehicleType) {
  const v = String(vehicleType || "").toUpperCase();
  const sym = v === "MOTO" ? "\u{1F3CD}" : v === "CARRINHO" ? "\u{1F6D2}" : "\u{1F697}";
  return L.divIcon({
    className: "mwm-crew-vehicle-marker",
    html: `<span class="mwm-crew-vehicle-marker__ic" title="">${sym}</span>`,
    iconSize: [30, 30],
    iconAnchor: [15, 15],
  });
}

/**
 * Recarrega marcadores OMS: zoom alto = ordens; intermédio = por bairro; baixo = por município.
 */
async function refreshOmsMarkersForZoom() {
  const z = map.getZoom();
  /** @type {'municipio' | 'bairro' | 'detail'} */
  let mode = "detail";
  if (z <= OMS_ZOOM_MUNICIPIO_MAX) mode = "municipio";
  else if (z <= OMS_ZOOM_BAIRRO_MAX) mode = "bairro";

  if (mode === "detail") {
    omsAggregateMarkersGroup.clearLayers();
    omsMapDisplayMode = "detail";
    rebuildWorkOrderMarkers(getOmsSortedRows());
    return;
  }

  omsMapDisplayMode = mode;
  workOrderMarkersGroup.clearLayers();
  omsAggregateMarkersGroup.clearLayers();

  const token = ++omsAggregateFetchToken;
  try {
    const res = await fetch(`/api/oms/work-orders/aggregate?zoom=${encodeURIComponent(String(z))}`);
    if (!res.ok) throw new Error("aggregate bad response");
    const rows = await res.json();
    if (token !== omsAggregateFetchToken) return;

    rows.forEach((g) => {
      const lat = g.center_lat != null ? parseFloat(g.center_lat) : NaN;
      const lng = g.center_lng != null ? parseFloat(g.center_lng) : NaN;
      if (Number.isNaN(lat) || Number.isNaN(lng)) return;
      const n = parseInt(String(g.orders_count), 10) || 0;
      const rad = Math.min(10 + Math.sqrt(n) * 1.1, 22);
      const hint = g.area_hint != null && String(g.area_hint).trim() !== "" ? String(g.area_hint).trim() : "";
      const muni = g.municipality_name || "";
      const bai = g.neighborhood_name || "";
      const adminTitle = bai && muni ? `${bai} · ${muni}` : muni || bai;
      const title = hint || adminTitle || uiText("UI_OP_AGG_CLUSTER_FALLBACK", "Agrupamento");
      const cm = L.circleMarker([lat, lng], {
        radius: rad,
        color: "#38bdf8",
        weight: 2,
        fillColor: "#0284c7",
        fillOpacity: 0.78,
      });
      cm.bindPopup(
        `<strong>${escapeHtml(title)}</strong><br/>` +
          `${n} ${escapeHtml(uiText("UI_OP_AGG_ORDERS_COUNT", "ordens"))}`
      );
      cm.bindTooltip(`${n} — ${escapeHtml(title)}`, { direction: "top" });
      cm.addTo(omsAggregateMarkersGroup);
    });
  } catch (e) {
    if (token === omsAggregateFetchToken) {
      console.error("refreshOmsMarkersForZoom", e);
    }
  }
}

async function loadMwmDemoFieldRoutes() {
  try {
    const res = await fetch("/api/mwm/demo-routes");
    if (!res.ok) throw new Error("demo-routes bad response");
    const routes = await res.json();
    mwmDemoCrewRoutesGroup.clearLayers();
    routes.forEach((r) => {
      const pts = Array.isArray(r.points) ? r.points : [];
      const latlngs = pts
        .map((p) => [parseFloat(p.lat), parseFloat(p.lng)])
        .filter((ll) => ll.every((v) => Number.isFinite(v)));
      if (latlngs.length < 2) return;
      const color = mwmDemoRouteColor(r.vehicle_type);
      const lineOpts = { color, weight: 3, opacity: 0.88 };
      const todayStr = new Date().toISOString().slice(0, 10);
      if (r.route_date && String(r.route_date).slice(0, 10) !== todayStr) lineOpts.dashArray = "6 4";
      const poly = L.polyline(latlngs, lineOpts);
      poly.bindPopup(
        `<strong>${escapeHtml(r.crew_code || "")}</strong> ${escapeHtml(r.vehicle_type || "")}<br/>` +
          `${escapeHtml(r.label || "")}<br/><span class="mock-hint">${escapeHtml(String(r.route_date || "").
            slice(0, 10))}</span>`
      );
      poly.addTo(mwmDemoCrewRoutesGroup);
      const last = latlngs[latlngs.length - 1];
      const mk = L.marker(last, { icon: mwmDemoVehicleDivIcon(r.vehicle_type) });
      mk.bindTooltip(`${escapeHtml(r.crew_code || "")} — ${escapeHtml(r.crew_name || "")}`, {
        direction: "top",
      });
      mk.addTo(mwmDemoCrewRoutesGroup);
    });
  } catch (e) {
    console.error("loadMwmDemoFieldRoutes", e);
  }
}

map.on("zoomend", () => {
  refreshOmsMarkersForZoom();
});

/**
 * Activa checkboxes e camadas de bairros + vias (sem validar zoom — usar após `setView` com z adequado).
 */
function enableBairrosEViasNoMapa() {
  const cbBairros = document.getElementById("bairros_alvo_sp");
  const cbVias = document.getElementById("vias_alvo_sp");
  if (cbBairros) cbBairros.checked = true;
  if (cbVias) cbVias.checked = true;
  if (!map.hasLayer(bairrosAlvoLayer)) bairrosAlvoLayer.addTo(map);
  if (!map.hasLayer(viasAlvoLayer)) viasAlvoLayer.addTo(map);
}

/**
 * Centra o mapa com zoom útil para vias (13–MAP_FOCUS_MAX_ZOOM) e garante bairros + vias visíveis.
 * @param {number} lat
 * @param {number} lng
 * @param {number} targetZoom - desejado; será clampeado e alinhado a zoomSnap
 */
function focusMapWithVias(lat, lng, targetZoom) {
  const cfg = getEffectiveLayerZoomCfg();
  const raw = Math.min(
    MAP_FOCUS_MAX_ZOOM,
    Math.max(cfg.viasEnableMin, Number(targetZoom))
  );
  const snap = map.options.zoomSnap > 0 ? map.options.zoomSnap : 1;
  const z = Math.round(raw / snap) * snap;
  map.setView([lat, lng], z);
  enableBairrosEViasNoMapa();
}

/**
 * «Ir para» a partir da ordem: centra o mapa, desliga municípios-alvo e activa bairros + vias.
 */
function focusOperationalMapOnWorkOrder(lat, lng) {
  const latNum = parseFloat(lat);
  const lngNum = parseFloat(lng);
  if (Number.isNaN(latNum) || Number.isNaN(lngNum)) {
    setStatus(uiText("UI_OP_STATUS_ORDER_MAP_NO_COORD", "Esta ordem não tem coordenadas de foco."));
    return;
  }
  focusMapWithVias(latNum, lngNum, MAP_FOCUS_ZOOM_ORDER);
  const cbMuni = document.getElementById("municipios_alvo_sp");
  if (cbMuni) cbMuni.checked = false;
  if (map.hasLayer(municipiosAlvoLayer)) map.removeLayer(municipiosAlvoLayer);
  setStatus(
    uiText(
      "UI_OP_STATUS_ORDER_MAP_FOCUS",
      "Vista operacional: bairros e vias activos; municípios-alvo desligados."
    )
  );
}

function woIconBool(titleTrue, titleFalse, value) {
  const on = !!value;
  const sym = on ? "●" : "○";
  const title = on ? titleTrue : titleFalse;
  const cls = on ? "wo-ico wo-ico--on" : "wo-ico wo-ico--off";
  return `<span class="${cls}" title="${escapeHtml(title)}">${sym}</span>`;
}

function woFlagsCell(r) {
  const tS = uiText("UI_TT_FLAG_SAFETY", "Risco de segurança");
  const tSf = uiText("UI_TT_FLAG_SAFETY_OFF", "Sem indicação de risco de segurança");
  const tC = uiText("UI_TT_FLAG_CRITICAL", "Infra-estrutura crítica");
  const tCf = uiText("UI_TT_FLAG_CRITICAL_OFF", "Fora de perfil de infra crítica");
  return `<span class="wo-flag-group">${woIconBool(tS, tSf, r.flag_safety_risk)}${woIconBool(
    tC,
    tCf,
    r.flag_critical_infra
  )}</span>`;
}

/** Valor numérico na célula (ícone fica no cabeçalho da coluna). */
function woNumericCell(value) {
  if (value == null || value === "" || Number.isNaN(Number(value))) return "—";
  return escapeHtml(String(value));
}

/** Horas desde início (API `hours_open` ou cálculo a partir de start_time / started_at / created_at). */
function workOrderHoursOpen(r) {
  const fromApi = r.hours_open;
  if (fromApi != null && fromApi !== "" && !Number.isNaN(Number(fromApi))) {
    return Math.round(Number(fromApi) * 10) / 10;
  }
  const startIso = r.start_time || r.started_at || r.created_at;
  if (startIso == null || startIso === "") return null;
  const t = Date.parse(String(startIso));
  if (!Number.isFinite(t)) return null;
  return Math.round(((Date.now() - t) / 3600000) * 10) / 10;
}

/** Prioridade tipo P1…P3 → dígito; caso contrário tenta número. */
function parsePriorityNumeric(priority) {
  if (priority == null || priority === "") return null;
  const s = String(priority).trim();
  const m = s.match(/^P\s*(\d+)$/i);
  if (m) return parseInt(m[1], 10);
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

function formatStartCompact(iso) {
  if (iso == null) return "—";
  const s = String(iso).replace("T", " ").replace(/\.\d{3}Z?$/, "");
  return s.slice(5, 16).replace(" ", "\u00a0");
}

function orderTypeAbbr(orderType) {
  const t = (orderType || "").toLowerCase();
  if (!t) return "—";
  return t.slice(0, 3).toUpperCase();
}

function orderCategoryAbbr(category) {
  const t = (category || "").toLowerCase();
  if (!t) return "—";
  return t.slice(0, 3).toUpperCase();
}

/** Última actualização (grelha): dd/mm HH:mm */
function formatUpdatedCompact(iso) {
  if (iso == null) return "—";
  const s = String(iso).replace("T", " ").replace(/\.\d{3}Z?$/, "");
  if (s.length < 16) return s.slice(0, 16);
  return `${s.slice(8, 10)}/${s.slice(5, 7)} ${s.slice(11, 16)}`;
}

/** Uma linha de descrição técnica para a grelha. */
function formatDescriptionGridLine(desc, maxLen) {
  const n = maxLen != null ? maxLen : 52;
  if (desc == null || String(desc).trim() === "") return "—";
  const s = String(desc).replace(/\s+/g, " ").trim();
  return s.length > n ? `${s.slice(0, n - 1)}…` : s;
}

function woLockCell(r) {
  const lu = r.locked_by_username;
  if (!lu) return "—";
  const short = lu.length > 9 ? `${lu.slice(0, 8)}…` : lu;
  return `<span class="wo-lock" title="${escapeHtml(lu)}"><span class="wo-lock-ic" aria-hidden="true">🔒</span>${escapeHtml(short)}</span>`;
}

async function resolvePocLockUserId() {
  if (pocLockUserId != null) return pocLockUserId;
  try {
    const res = await fetch("/api/users");
    if (!res.ok) return null;
    const users = await res.json();
    const op = users.find((u) => u.username === "operador1");
    pocLockUserId = op ? op.id : users[0]?.id ?? null;
    return pocLockUserId;
  } catch {
    return null;
  }
}

function setOmsStatusMessage(msg, isError) {
  const el = document.getElementById("oms-orders-status");
  if (!el) return;
  el.textContent = msg;
  el.hidden = !msg;
  el.style.color = isError ? "var(--danger, #f87171)" : "";
}

function setUsrStatusMessage(msg, isError) {
  const el = document.getElementById("usr-panel-status");
  if (!el) return;
  el.textContent = msg;
  el.hidden = !msg;
  el.style.color = isError ? "var(--danger, #f87171)" : "";
}

function omsSortScalar(r, key) {
  switch (key) {
    case "code":
      return (r.order_code || "").toLowerCase();
    case "start":
      return Date.parse(String(r.start_time || r.created_at || "")) || 0;
    case "hours":
      return workOrderHoursOpen(r) ?? 0;
    case "type":
      return (r.order_type || "").toLowerCase();
    case "category":
      return (r.category || "").toLowerCase();
    case "feeder":
      return (r.feeder_code || "").toLowerCase();
    case "updated":
      return Date.parse(String(r.updated_at || "")) || 0;
    case "lock":
      return (r.locked_by_username || "").toLowerCase();
    case "descr":
      return (r.description || "").toLowerCase();
    case "org":
      return (r.organization_label || "").toLowerCase();
    case "loc":
      return [r.municipality_name, r.neighborhood_name].filter(Boolean).join(" ").toLowerCase();
    case "equip":
      return (r.equipment_code || "").toLowerCase();
    case "affected":
      return Number(r.affected_customers_count) || 0;
    case "complaints":
      return Number(r.complaints_linked_count) || 0;
    case "flags":
      return (!!r.flag_safety_risk ? 4 : 0) + (!!r.flag_critical_infra ? 2 : 0);
    case "priority": {
      const n = parsePriorityNumeric(r.priority);
      return n == null ? -1e9 : n;
    }
    case "pos": {
      const n = Number(r.priority_score);
      return Number.isFinite(n) ? n : -1e9;
    }
    case "cb_hum":
      return r.flag_customer_callback ? 1 : 0;
    case "cb_auto":
      return r.callback_auto ? 1 : 0;
    case "team":
      return (r.team_code || "").toLowerCase();
    case "owner":
      return (r.owner_username || "").toLowerCase();
    case "status":
      return (r.status || "").toLowerCase();
    case "summary":
      return (r.summary || "").toLowerCase();
    default:
      return "";
  }
}

function compareOmsRows(a, b, key, dir) {
  const mul = dir === "desc" ? -1 : 1;
  const va = omsSortScalar(a, key);
  const vb = omsSortScalar(b, key);
  if (typeof va === "number" && typeof vb === "number") {
    if (va !== vb) return mul * (va < vb ? -1 : 1);
  } else {
    const c = String(va).localeCompare(String(vb), "pt", { numeric: true, sensitivity: "base" });
    if (c !== 0) return mul * c;
  }
  return Number(a.id) - Number(b.id);
}

function sortWorkOrdersForDisplay(rows, key, dir) {
  if (!key || !rows.length) return rows;
  return [...rows].sort((a, b) => compareOmsRows(a, b, key, dir));
}

function getOmsSortedRows() {
  return sortWorkOrdersForDisplay(workOrdersListCache, omsSortState.key, omsSortState.dir);
}

function updateOmsSortHeaderUI() {
  const thead = document.querySelector("#oms-orders-table thead");
  if (!thead) return;
  thead.querySelectorAll("th[data-wo-sort]").forEach((th) => {
    th.classList.remove("wo-sortable--asc", "wo-sortable--desc");
    th.removeAttribute("aria-sort");
  });
  if (!omsSortState.key) return;
  const th = thead.querySelector(`th[data-wo-sort="${omsSortState.key}"]`);
  if (!th) return;
  const asc = omsSortState.dir === "asc";
  th.classList.add(asc ? "wo-sortable--asc" : "wo-sortable--desc");
  th.setAttribute("aria-sort", asc ? "ascending" : "descending");
}

function buildWorkOrderTr(r) {
  const tr = document.createElement("tr");
  tr.className = "order-row-api";
  tr.setAttribute("data-order-id", String(r.id));
  tr.setAttribute("data-priority", r.priority != null ? String(r.priority) : "—");
  tr.setAttribute(
    "data-created",
    r.created_at ? String(r.created_at).replace("T", " ").slice(0, 16) : "—"
  );
  tr.setAttribute("data-team", r.team_code ? `${r.team_code} — ${r.team_name || ""}`.trim() : "—");
  tr.setAttribute("data-owner", r.owner_username || "—");
  tr.setAttribute("data-locked", r.locked_by_username || "—");
  tr.setAttribute("role", "button");
  tr.tabIndex = 0;
  const statusSpan = document.createElement("span");
  statusSpan.className = orderStatusBadgeClass(r.status);
  statusSpan.textContent = orderStatusLabel(r.status);
  const lat = r.focus_lat != null ? parseFloat(r.focus_lat) : NaN;
  const lng = r.focus_lng != null ? parseFloat(r.focus_lng) : NaN;
  const hasPos = !Number.isNaN(lat) && !Number.isNaN(lng);
  const mapBtn = hasPos
    ? `<button type="button" class="mock-btn-ir mock-btn-wo-map" data-lat="${lat}" data-lng="${lng}" title="${escapeHtml(
        uiText("UI_OP_GO_MAP_ORDER", "Ir para o mapa (bairros e vias)")
      )}">${i18nCache.UI_OP_GO_MAP || "Ir para"}</button>`
    : `<span class="mock-hint">—</span>`;
  const affTitle = uiText("UI_TT_AFFECTED", "Número de clientes afectados (decisório)");
  const compTitle = uiText("UI_TT_COMPLAINTS", "Reclamações ligadas a esta ordem");
  const hoursTitle = uiText("UI_TT_HOURS_OPEN", "Tempo em curso (horas desde o início)");
  const catTitle = uiText("UI_TT_CATEGORY_GRID", "Categoria operacional (reclamação, reparo, …)");
  const updTitle = uiText("UI_TT_GRID_UPDATED", "Última actualização do registo");
  const lockTitle = uiText("UI_TT_GRID_LOCK", "Bloqueio de edição (outro utilizador)");
  const descTitle = uiText("UI_TT_GRID_DESC", "Descrição técnica (primeira linha)");
  const mun = r.municipality_name || "—";
  const bai = r.neighborhood_name || "—";
  const loc = mun === "—" && bai === "—" ? "—" : `${mun} · ${bai}`;
  const priNum = parsePriorityNumeric(r.priority);
  const priDisp = priNum != null ? String(priNum) : "—";
  const posRaw =
    r.priority_score != null && !Number.isNaN(Number(r.priority_score))
      ? String(r.priority_score)
      : "—";
  const cbHum = r.flag_customer_callback ? "1" : "0";
  const cbAuto = r.callback_auto ? "1" : "0";
  const descLine = formatDescriptionGridLine(r.description, 48);
  const teamTitle = [r.team_code, r.team_name].filter(Boolean).join(" — ") || "";
  tr.innerHTML = `
    <td class="wo-sticky-code">${escapeHtml(r.order_code)}</td>
    <td class="wo-start">${escapeHtml(formatStartCompact(r.start_time || r.created_at))}</td>
    <td class="wo-num-cell" title="${escapeHtml(hoursTitle)}">${woNumericCell(workOrderHoursOpen(r))}</td>
    <td data-col="status"></td>
    <td><abbr title="${escapeHtml(catTitle)}: ${escapeHtml(orderCategoryLabel(r.category))}">${escapeHtml(orderCategoryAbbr(r.category))}</abbr></td>
    <td><abbr title="${escapeHtml(orderTypeLabel(r.order_type))}">${escapeHtml(orderTypeAbbr(r.order_type))}</abbr></td>
    <td class="wo-ellipsis" title="${escapeHtml(r.organization_label || "")}">${escapeHtml(r.organization_label || "—")}</td>
    <td class="wo-ellipsis" title="${escapeHtml(loc)}">${escapeHtml(loc)}</td>
    <td class="wo-ellipsis">${escapeHtml(r.equipment_code || "—")}</td>
    <td class="wo-ellipsis" title="${escapeHtml(r.feeder_code || "")}">${escapeHtml(r.feeder_code || "—")}</td>
    <td class="wo-num-cell" title="${escapeHtml(affTitle)}">${woNumericCell(r.affected_customers_count)}</td>
    <td class="wo-num-cell" title="${escapeHtml(compTitle)}">${woNumericCell(r.complaints_linked_count)}</td>
    <td class="wo-icon-cell">${woFlagsCell(r)}</td>
    <td class="wo-num-cell" title="${escapeHtml(uiText("UI_TT_PRIORITY_LETTER", "Prioridade operacional (P1…)"))}">${escapeHtml(priDisp)}</td>
    <td class="wo-num-cell" title="${escapeHtml(uiText("UI_TT_POS_SCORE", "POS / peso numérico para triagem"))}">${escapeHtml(posRaw)}</td>
    <td class="wo-num-cell" title="${escapeHtml(uiText("UI_TT_CALLBACK_HUM", "Callback humano (operador / contacto directo)"))}">${cbHum}</td>
    <td class="wo-num-cell" title="${escapeHtml(uiText("UI_TT_CALLBACK_AUTO", "Callback automático (IVR, SMS, BOT)"))}">${cbAuto}</td>
    <td class="wo-ellipsis" title="${escapeHtml(teamTitle)}">${escapeHtml(r.team_code || "—")}</td>
    <td class="wo-ellipsis">${escapeHtml(r.owner_username || "—")}</td>
    <td class="wo-start wo-muted" title="${escapeHtml(updTitle)}">${escapeHtml(formatUpdatedCompact(r.updated_at))}</td>
    <td class="wo-lock-cell wo-ellipsis" title="${escapeHtml(lockTitle)}">${woLockCell(r)}</td>
    <td class="wo-desc-cell wo-ellipsis" title="${escapeHtml(descTitle)}">${escapeHtml(descLine)}</td>
    <td class="wo-summary-cell">${escapeHtml(r.summary || "—")}</td>
    <td><button type="button" class="mock-btn-open-order" data-i18n="UI_OP_OPEN_DETAIL">${i18nCache.UI_OP_OPEN_DETAIL || "Folha"}</button></td>
    <td>${mapBtn}</td>
  `;
  const statusTd = tr.querySelector('td[data-col="status"]');
  if (statusTd) statusTd.appendChild(statusSpan);
  return tr;
}

function renderOmsOrderRowsToTbody(rows) {
  const tbody = document.getElementById("oms-orders-tbody");
  if (!tbody) return;
  tbody.innerHTML = "";
  rows.forEach((r) => tbody.appendChild(buildWorkOrderTr(r)));
}

async function loadWorkOrdersFromApi() {
  const tbody = document.getElementById("oms-orders-tbody");
  if (!tbody) return;
  setOmsStatusMessage(i18nCache.UI_OP_STATUS_LOADING_ORDERS || "A carregar ordens…", false);
  try {
    const res = await fetch("/api/work-orders");
    if (!res.ok) throw new Error("bad response");
    const rows = await res.json();
    workOrdersListCache = rows;
    workOrderRowsById = new Map(rows.map((r) => [String(r.id), r]));
    renderOmsOrderRowsToTbody(getOmsSortedRows());
    updateOmsSortHeaderUI();
    refreshOmsMarkersForZoom();
    setOmsStatusMessage(
      rows.length ? "" : i18nCache.UI_OP_NO_ORDERS || "Sem ordens na base.",
      false
    );
    const lang = document.getElementById("select-language")?.value || "pt";
    loadTranslations(lang);
  } catch {
    workOrdersListCache = [];
    workOrderRowsById = new Map();
    tbody.innerHTML = "";
    updateOmsSortHeaderUI();
    refreshOmsMarkersForZoom();
    setOmsStatusMessage(
      "Falha ao carregar ordens. Verifique o serviço API e a base de dados (ver docs/DEPLOY_POC.md).",
      true
    );
  }
}

function formatTs(iso) {
  if (iso == null) return "—";
  return String(iso).replace("T", " ").replace(/\.\d{3}Z?$/, "").slice(0, 16);
}

function teamStatusBadgeClass(status) {
  const s = (status || "").toLowerCase();
  if (s === "active") return "mock-badge mock-badge--ok";
  if (s === "standby") return "mock-badge mock-badge--warn";
  return "mock-badge mock-badge--muted";
}

function teamStatusLabel(status) {
  const s = (status || "").toLowerCase();
  if (s === "active") return i18nCache.UI_OP_STATUS_ACTIVE || "Activa";
  if (s === "standby") return i18nCache.UI_OP_STATUS_STANDBY || "Stand-by";
  return status || "—";
}

function setTeamsStatusMessage(msg, isError) {
  const el = document.getElementById("teams-panel-status");
  if (!el) return;
  el.textContent = msg;
  el.hidden = !msg;
  el.style.color = isError ? "var(--danger, #f87171)" : "";
}

function setAuditStatusMessage(msg, isError) {
  const el = document.getElementById("audit-panel-status");
  if (!el) return;
  el.textContent = msg;
  el.hidden = !msg;
  el.style.color = isError ? "var(--danger, #f87171)" : "";
}

async function loadTeamsFromApi() {
  const tbody = document.getElementById("teams-tbody");
  if (!tbody) return;
  setTeamsStatusMessage(i18nCache.UI_OP_STATUS_LOADING_TEAMS || "Carregando equipes…", false);
  try {
    const res = await fetch("/api/teams");
    if (!res.ok) throw new Error("bad response");
    const rows = await res.json();
    tbody.innerHTML = "";
    rows.forEach((r) => {
      const tr = document.createElement("tr");
      const lat = r.lat != null ? parseFloat(r.lat) : NaN;
      const lng = r.lng != null ? parseFloat(r.lng) : NaN;
      const hasPos = !Number.isNaN(lat) && !Number.isNaN(lng);
      const statusSpan = document.createElement("span");
      statusSpan.className = teamStatusBadgeClass(r.status);
      statusSpan.textContent = teamStatusLabel(r.status);
      const mapBtn = hasPos
        ? `<button type="button" class="mock-btn-ir" data-i18n="UI_OP_GO_MAP" data-lat="${lat}" data-lng="${lng}">${i18nCache.UI_OP_GO_MAP || "Ir para"}</button>`
        : `<span class="mock-hint">—</span>`;
      tr.innerHTML = `
        <td>${escapeHtml(r.team_code)}</td>
        <td>${escapeHtml(r.leader_name || "—")}</td>
        <td>${escapeHtml(r.skill || "—")}</td>
        <td>${escapeHtml(r.team_type || "—")}</td>
        <td>${escapeHtml(r.owner_org || "—")}</td>
        <td>${escapeHtml(formatTs(r.last_coordinate_at))}</td>
        <td>${escapeHtml(formatTs(r.last_updated_at))}</td>
        <td>${escapeHtml(r.zone || "—")}</td>
        <td>${escapeHtml(r.member_count != null ? String(r.member_count) : "—")}</td>
        <td></td>
        <td>${mapBtn}</td>
      `;
      tr.querySelector("td:nth-child(10)").appendChild(statusSpan);
      tr.classList.add("team-row-api");
      tr.dataset.teamCode = r.team_code ?? "";
      tr.dataset.leaderName = r.leader_name ?? "";
      tr.dataset.skill = r.skill ?? "";
      tr.dataset.teamType = r.team_type ?? "";
      tr.dataset.ownerOrg = r.owner_org ?? "";
      tr.dataset.zone = r.zone ?? "";
      tr.dataset.memberCount =
        r.member_count != null && r.member_count !== "" ? String(r.member_count) : "";
      tr.dataset.status = r.status ?? "";
      tr.setAttribute("role", "button");
      tr.tabIndex = 0;
      tbody.appendChild(tr);
    });
    setTeamsStatusMessage(rows.length ? "" : i18nCache.UI_OP_NO_TEAMS || "Sem equipes registradas.", false);
    const lang = document.getElementById("select-language")?.value || "pt";
    loadTranslations(lang);
  } catch {
    setTeamsStatusMessage(
      "Falha ao carregar equipes. Verifique o serviço API (ver docs/DEPLOY_POC.md).",
      true
    );
  }
}

async function loadAuditArchiveFromApi() {
  const tbody = document.getElementById("audit-archive-tbody");
  if (!tbody) return;
  setAuditStatusMessage(i18nCache.UI_OP_STATUS_LOADING_AUDIT || "A carregar arquivo…", false);
  try {
    const res = await fetch("/api/audit/operations-archive?limit=50");
    if (!res.ok) throw new Error("bad response");
    const rows = await res.json();
    tbody.innerHTML = "";
    if (rows.length === 0) {
      const tr = document.createElement("tr");
      tr.innerHTML = `<td colspan="4" class="mock-hint">${escapeHtml(i18nCache.UI_OP_AUD_EMPTY || "Nenhum registo de arquivo pré-delete.")}</td>`;
      tbody.appendChild(tr);
    } else {
      rows.forEach((r) => {
        const tr = document.createElement("tr");
        const tbl = r.source_schema && r.source_table ? `${r.source_schema}.${r.source_table}` : "—";
        tr.innerHTML = `
          <td><code>${escapeHtml(tbl)}</code></td>
          <td>${escapeHtml(r.source_id)}</td>
          <td>${escapeHtml(formatTs(r.archived_at))}</td>
          <td>${escapeHtml(r.archive_reason || "—")}</td>
        `;
        tbody.appendChild(tr);
      });
    }
    setAuditStatusMessage("", false);
  } catch {
    setAuditStatusMessage(
      "Falha ao carregar arquivo de auditoria. Verifique a API (ver docs/DEPLOY_POC.md).",
      true
    );
  }
}

async function loadUsersFromApi() {
  const tbody = document.getElementById("users-tbody");
  if (!tbody) return;
  setUsrStatusMessage(i18nCache.UI_OP_STATUS_LOADING_USERS || "A carregar utilizadores…", false);
  try {
    const res = await fetch("/api/users");
    if (!res.ok) throw new Error("bad response");
    const rows = await res.json();
    tbody.innerHTML = "";
    rows.forEach((u) => {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${escapeHtml(u.username)}</td>
        <td>${escapeHtml(u.email || "—")}</td>
        <td>${escapeHtml(u.access_type || "—")}</td>
        <td>${escapeHtml(u.status || "—")}</td>
      `;
      tbody.appendChild(tr);
    });
    setUsrStatusMessage("", false);
  } catch {
    setUsrStatusMessage(
      'Falha ao carregar utilizadores. Verifique API (ver docs/DEPLOY_POC.md).',
      true
    );
  }
}

function setOrderSheetFetchStatus(msg, isError) {
  const el = document.getElementById("wo-sheet-fetch-status");
  if (!el) return;
  el.textContent = msg;
  el.hidden = !msg;
  el.style.color = isError ? "var(--danger, #f87171)" : "";
}

function closeOrderSheetModal() {
  const modal = document.getElementById("modal-order-sheet");
  if (!modal) return;
  modal.style.display = "none";
  modal.setAttribute("aria-hidden", "true");
}

async function openOrderSheetModal(orderId) {
  const modal = document.getElementById("modal-order-sheet");
  if (!modal) return;
  selectedWorkOrderId = String(orderId);
  modal.style.display = "flex";
  modal.setAttribute("aria-hidden", "false");
  setOrderSheetFetchStatus(i18nCache.UI_OP_STATUS_LOADING_SHEET || "A carregar folha…", false);
  const sub = document.getElementById("wo-sheet-code-sub");
  if (sub) sub.textContent = "";
  try {
    const res = await fetch(`/api/work-orders/${orderId}`);
    if (!res.ok) throw new Error("fetch fail");
    const data = await res.json();
    const o = data.order;
    if (sub) sub.textContent = o.order_code || `#${o.id}`;
    document.getElementById("wo-sheet-summary").value = o.summary || "";
    document.getElementById("wo-sheet-description").value = o.description || "";
    document.getElementById("wo-sheet-status").value = o.status || "open";
    document.getElementById("wo-sheet-priority").value = o.priority || "";
    document.getElementById("wo-sheet-order-type").value = o.order_type || "incident";
    document.getElementById("wo-sheet-org").value = o.organization_label || "";
    document.getElementById("wo-sheet-municipality").value = o.municipality_name || "";
    document.getElementById("wo-sheet-neighborhood").value = o.neighborhood_name || "";
    document.getElementById("wo-sheet-equipment").value = o.equipment_code || "";
    document.getElementById("wo-sheet-feeder").value = o.feeder_code || "";
    document.getElementById("wo-sheet-affected").value =
      o.affected_customers_count != null ? String(o.affected_customers_count) : "0";
    document.getElementById("wo-sheet-prio-score").value =
      o.priority_score != null ? String(o.priority_score) : "";
    document.getElementById("wo-sheet-lat").value = o.focus_lat != null ? String(o.focus_lat) : "";
    document.getElementById("wo-sheet-lng").value = o.focus_lng != null ? String(o.focus_lng) : "";
    document.getElementById("wo-sheet-flag-safety").checked = !!o.flag_safety_risk;
    document.getElementById("wo-sheet-flag-crit").checked = !!o.flag_critical_infra;
    document.getElementById("wo-sheet-flag-cb").checked = !!o.flag_customer_callback;
    const meta = document.getElementById("wo-sheet-readonly-meta");
    if (meta) {
      meta.textContent = `${uiText("UI_OP_SHEET_META_TEAM", "Equipa")}: ${o.team_code || "—"} · ${uiText(
        "UI_OP_DETAIL_OWNER",
        "Responsável"
      )}: ${o.owner_username || "—"} · ${uiText("UI_OP_DETAIL_LOCKED_BY", "Bloqueio")}: ${
        o.locked_by_username || "—"
      } · ${uiText("UI_OP_DETAIL_CREATED", "Criada")}: ${formatTs(o.created_at)} · ${uiText(
        "UI_OP_COL_COMPLAINTS",
        "Recl."
      )}: ${o.complaints_linked_count ?? "—"}`;
    }
    const ttbody = document.getElementById("wo-sheet-tasks-tbody");
    if (ttbody) {
      ttbody.innerHTML = "";
      (data.tasks || []).forEach((t) => {
        const tr = document.createElement("tr");
        const st = (t.status || "").toLowerCase();
        const canStart = st !== "in_progress" && st !== "completed";
        const canComplete = st === "in_progress" || st === "open" || st === "scheduled";
        const canReopen = st === "completed";
        tr.innerHTML = `
          <td>${escapeHtml(String(t.sequence_no))}</td>
          <td>${escapeHtml(t.summary || "—")}</td>
          <td>${escapeHtml(t.status || "—")}</td>
          <td>${escapeHtml(t.notes || "—")}</td>
          <td class="wo-task-actions">
            <button type="button" class="mock-btn mock-btn--xs wo-task-patch" data-task-id="${t.id}" data-new-status="in_progress" ${canStart ? "" : "disabled"}>${escapeHtml(
          i18nCache.UI_OP_TASK_START || "Em curso"
        )}</button>
            <button type="button" class="mock-btn mock-btn--xs wo-task-patch" data-task-id="${t.id}" data-new-status="completed" ${canComplete ? "" : "disabled"}>${escapeHtml(
          i18nCache.UI_OP_TASK_DONE || "Concluir"
        )}</button>
            <button type="button" class="mock-btn mock-btn--xs wo-task-patch" data-task-id="${t.id}" data-new-status="open" ${canReopen ? "" : "disabled"}>${escapeHtml(
          i18nCache.UI_OP_TASK_REOPEN || "Reabrir"
        )}</button>
          </td>`;
        ttbody.appendChild(tr);
      });
      if (!data.tasks?.length) {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td colspan="5" class="mock-hint">${escapeHtml(
          i18nCache.UI_OP_TASKS_EMPTY || "Sem tarefas registadas."
        )}</td>`;
        ttbody.appendChild(tr);
      }
    }
    const ctbody = document.getElementById("wo-sheet-complaints-tbody");
    if (ctbody) {
      ctbody.innerHTML = "";
      (data.complaints || []).forEach((c) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${escapeHtml(c.complaint_ref || "—")}</td>
          <td>${escapeHtml(c.channel || "—")}</td>
          <td>${escapeHtml(c.caller_name || "—")}</td>
          <td>${escapeHtml(c.status || "—")}</td>
          <td>${escapeHtml(c.summary || "—")}</td>
          <td>${escapeHtml(formatTs(c.received_at))}</td>`;
        ctbody.appendChild(tr);
      });
      if (!data.complaints?.length) {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td colspan="6" class="mock-hint">${escapeHtml(
          i18nCache.UI_OP_COMPLAINTS_EMPTY || "Sem reclamações ligadas."
        )}</td>`;
        ctbody.appendChild(tr);
      }
    }
    setOrderSheetFetchStatus("", false);
    const lang = document.getElementById("select-language")?.value || "pt";
    loadTranslations(lang);
  } catch {
    setOrderSheetFetchStatus(
      i18nCache.UI_OP_SHEET_LOAD_FAIL ||
        "Falha ao carregar a folha. Aplique infra/sql/06_work_order_sheet_model.sql se ainda não aplicou.",
      true
    );
  }
}

function teamRowToDetailObject(tr) {
  return {
    team_code: tr.dataset.teamCode || "",
    leader_name: tr.dataset.leaderName || "",
    skill: tr.dataset.skill || "",
    team_type: tr.dataset.teamType || "",
    owner_org: tr.dataset.ownerOrg || "",
    zone: tr.dataset.zone || "",
    member_count:
      tr.dataset.memberCount != null && tr.dataset.memberCount !== ""
        ? Number(tr.dataset.memberCount)
        : null,
    status: tr.dataset.status || "",
  };
}

(function initOperacaoPanelActions() {
  const panels = document.querySelector(".operacao-panels");
  if (!panels) return;

  panels.addEventListener("click", (e) => {
    const woMapBtn = e.target.closest(".mock-btn-wo-map");
    if (woMapBtn) {
      e.stopPropagation();
      const lat = parseFloat(woMapBtn.getAttribute("data-lat") || "");
      const lng = parseFloat(woMapBtn.getAttribute("data-lng") || "");
      focusOperationalMapOnWorkOrder(lat, lng);
      return;
    }

    const irBtn = e.target.closest(".mock-btn-ir");
    if (irBtn && !irBtn.classList.contains("mock-btn-wo-map")) {
      const lat = parseFloat(irBtn.getAttribute("data-lat") || "");
      const lng = parseFloat(irBtn.getAttribute("data-lng") || "");
      if (!Number.isNaN(lat) && !Number.isNaN(lng)) {
        focusMapWithVias(lat, lng, MAP_FOCUS_ZOOM_TEAM);
        setStatus(
          i18nCache.UI_OP_STATUS_MAP_CENTERED ||
            "Mapa centrado na última posição conhecida da equipe."
        );
      }
      return;
    }

    const openBtn = e.target.closest(".mock-btn-open-order");
    if (openBtn) {
      e.stopPropagation();
      const row = openBtn.closest(".order-row-api");
      const id = row?.getAttribute("data-order-id");
      const full = id ? workOrderRowsById.get(String(id)) : null;
      if (full) renderOperDetailWorkOrder(full);
      if (id) openOrderSheetModal(id);
      return;
    }

    const teamRow = e.target.closest(".team-row-api");
    if (teamRow && !e.target.closest("button")) {
      renderOperDetailTeam(teamRowToDetailObject(teamRow));
      return;
    }

    const row = e.target.closest(".order-row-api");
    if (row && !e.target.closest("button")) {
      const id = row.getAttribute("data-order-id");
      const full = id ? workOrderRowsById.get(String(id)) : null;
      if (full) renderOperDetailWorkOrder(full);
    }
  });

  panels.addEventListener("dblclick", (e) => {
    const row = e.target.closest(".order-row-api");
    if (!row || e.target.closest("button")) return;
    const id = row.getAttribute("data-order-id");
    if (!id) return;
    const full = workOrderRowsById.get(String(id));
    if (full) renderOperDetailWorkOrder(full);
    openOrderSheetModal(id);
  });

  panels.addEventListener("keydown", (e) => {
    const teamRow = e.target.closest?.(".team-row-api");
    if (teamRow && !e.target.closest("button")) {
      if (e.key !== "Enter" && e.key !== " ") return;
      e.preventDefault();
      renderOperDetailTeam(teamRowToDetailObject(teamRow));
      return;
    }
    const row = e.target.closest?.(".order-row-api");
    if (!row || e.target.closest("button")) return;
    if (e.key === "Enter" && e.ctrlKey) {
      e.preventDefault();
      const id = row.getAttribute("data-order-id");
      const full = id ? workOrderRowsById.get(String(id)) : null;
      if (full) renderOperDetailWorkOrder(full);
      if (id) openOrderSheetModal(id);
      return;
    }
    if (e.key !== "Enter" && e.key !== " ") return;
    e.preventDefault();
    const id = row.getAttribute("data-order-id");
    const full = id ? workOrderRowsById.get(String(id)) : null;
    if (full) renderOperDetailWorkOrder(full);
  });
})();

document.getElementById("btn-close-order-sheet")?.addEventListener("click", closeOrderSheetModal);

document.getElementById("modal-order-sheet")?.addEventListener("click", (ev) => {
  if (ev.target.id === "modal-order-sheet") closeOrderSheetModal();
});

document.getElementById("modal-order-sheet")?.addEventListener("click", async (ev) => {
  const patchBtn = ev.target.closest(".wo-task-patch");
  if (patchBtn && !patchBtn.disabled) {
    const taskId = patchBtn.getAttribute("data-task-id");
    const newStatus = patchBtn.getAttribute("data-new-status");
    if (!selectedWorkOrderId || !taskId || !newStatus) return;
    try {
      const res = await fetch(`/api/work-orders/${selectedWorkOrderId}/tasks/${taskId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      if (!res.ok) throw new Error("patch task");
      setStatus(i18nCache.UI_OP_TASK_STATUS_OK || "Tarefa actualizada.");
      await openOrderSheetModal(selectedWorkOrderId);
    } catch {
      setStatus("Falha ao actualizar tarefa. Verifique a API (ver docs/DEPLOY_POC.md).");
    }
    return;
  }

  if (ev.target.closest("#btn-wo-add-task")) {
    ev.preventDefault();
    const summary = document.getElementById("wo-new-task-summary")?.value?.trim() || "";
    if (!summary) {
      setStatus(i18nCache.UI_OP_TASK_SUMMARY_REQUIRED || "Indique o resumo da tarefa.");
      return;
    }
    const notes = document.getElementById("wo-new-task-notes")?.value?.trim() || null;
    const status = document.getElementById("wo-new-task-status")?.value || "open";
    if (!selectedWorkOrderId) return;
    try {
      const res = await fetch(`/api/work-orders/${selectedWorkOrderId}/tasks`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ summary, notes, status }),
      });
      if (!res.ok) throw new Error("post task");
      document.getElementById("wo-new-task-summary").value = "";
      document.getElementById("wo-new-task-notes").value = "";
      setStatus(i18nCache.UI_OP_TASK_ADDED || "Tarefa criada.");
      await openOrderSheetModal(selectedWorkOrderId);
      await loadWorkOrdersFromApi();
    } catch {
      setStatus("Falha ao criar tarefa. Verifique a API (ver docs/DEPLOY_POC.md).");
    }
  }
});

document.getElementById("btn-order-sheet-save")?.addEventListener("click", async () => {
  if (!selectedWorkOrderId) return;
  const body = {
    summary: document.getElementById("wo-sheet-summary")?.value ?? "",
    description: document.getElementById("wo-sheet-description")?.value ?? "",
    status: document.getElementById("wo-sheet-status")?.value,
    priority: document.getElementById("wo-sheet-priority")?.value || null,
    order_type: document.getElementById("wo-sheet-order-type")?.value,
    organization_label: document.getElementById("wo-sheet-org")?.value || null,
    municipality_name: document.getElementById("wo-sheet-municipality")?.value || null,
    neighborhood_name: document.getElementById("wo-sheet-neighborhood")?.value || null,
    equipment_code: document.getElementById("wo-sheet-equipment")?.value || null,
    feeder_code: document.getElementById("wo-sheet-feeder")?.value || null,
    affected_customers_count: parseInt(document.getElementById("wo-sheet-affected")?.value || "0", 10),
    priority_score: document.getElementById("wo-sheet-prio-score")?.value
      ? parseInt(document.getElementById("wo-sheet-prio-score").value, 10)
      : null,
    flag_safety_risk: document.getElementById("wo-sheet-flag-safety")?.checked ?? false,
    flag_critical_infra: document.getElementById("wo-sheet-flag-crit")?.checked ?? false,
    flag_customer_callback: document.getElementById("wo-sheet-flag-cb")?.checked ?? false,
  };
  const latStr = document.getElementById("wo-sheet-lat")?.value?.trim();
  const lngStr = document.getElementById("wo-sheet-lng")?.value?.trim();
  if (latStr !== "") {
    const x = parseFloat(latStr);
    if (!Number.isNaN(x)) body.focus_lat = x;
  }
  if (lngStr !== "") {
    const y = parseFloat(lngStr);
    if (!Number.isNaN(y)) body.focus_lng = y;
  }
  if (body.priority_score !== null && Number.isNaN(body.priority_score)) delete body.priority_score;
  try {
    const res = await fetch(`/api/work-orders/${selectedWorkOrderId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error("patch fail");
    setStatus(i18nCache.UI_OP_SHEET_SAVED || "Folha guardada.");
    await loadWorkOrdersFromApi();
    await openOrderSheetModal(selectedWorkOrderId);
  } catch {
    setStatus("Falha ao guardar folha. Verifique a API (ver docs/DEPLOY_POC.md).");
  }
});

document.getElementById("btn-order-sheet-assume-lock")?.addEventListener("click", async () => {
  if (!selectedWorkOrderId) return;
  const uid = await resolvePocLockUserId();
  if (uid == null) {
    setStatus(
      "Não foi possível reservar edição: crie o utilizador «operador1» ou outro perfil OPERACAO em Utilizadores."
    );
    return;
  }
  try {
    const res = await fetch(`/api/work-orders/${selectedWorkOrderId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ locked_by_id: uid }),
    });
    if (!res.ok) throw new Error("patch fail");
    setStatus(i18nCache.UI_OP_LOCK_OK || "Edição reservada.");
    loadWorkOrdersFromApi();
    openOrderSheetModal(selectedWorkOrderId);
  } catch {
    setStatus("Falha ao reservar edição. Verifique a API (ver docs/DEPLOY_POC.md).");
  }
});

document.getElementById("btn-order-sheet-release-lock")?.addEventListener("click", async () => {
  if (!selectedWorkOrderId) return;
  try {
    const res = await fetch(`/api/work-orders/${selectedWorkOrderId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ locked_by_id: null }),
    });
    if (!res.ok) throw new Error("patch fail");
    setStatus(i18nCache.UI_OP_LOCK_RELEASED || "Reserva de edição libertada.");
    loadWorkOrdersFromApi();
    openOrderSheetModal(selectedWorkOrderId);
  } catch {
    setStatus("Falha ao libertar edição. Verifique a API (ver docs/DEPLOY_POC.md).");
  }
});

document.getElementById("form-new-user")?.addEventListener("submit", async (ev) => {
  ev.preventDefault();
  const form = ev.target;
  const fd = new FormData(form);
  const body = {
    username: fd.get("username"),
    email: fd.get("email") || null,
    first_name: fd.get("first_name") || null,
    last_name: fd.get("last_name") || null,
    access_type: fd.get("access_type") || "CONSULTA",
  };
  try {
    const res = await fetch("/api/users", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error("post fail");
    form.reset();
    setUsrStatusMessage(i18nCache.UI_OP_USER_CREATED || "Utilizador criado.", false);
    loadUsersFromApi();
  } catch {
    setUsrStatusMessage(
      i18nCache.UI_OP_USER_CREATE_FAIL || "Não foi possível criar (username duplicado?).",
      true
    );
  }
});


const REF_TYPE_SECTION_LABELS = {
  equipment_type: "Tipo de equipamento",
  network_type: "Tipo de rede",
  network_level: "Nível / instalação",
  connection_state: "Estado de ligação",
  work_order_type: "Tipo de ordem de serviço",
  task_type: "Tipo de tarefa",
  call_type: "Tipo de chamada / incidente",
};

function setRefTypesStatus(msg, isError) {
  const el = document.getElementById("ref-types-status");
  if (!el) return;
  el.textContent = msg || "";
  el.hidden = !msg;
  el.style.color = isError ? "var(--danger, #f87171)" : "";
}

function renderRefTypesToRoot(data) {
  const root = document.getElementById("ref-types-tables-root");
  if (!root) return;
  root.innerHTML = "";
  const tables = Object.keys(data).sort();
  tables.forEach((table) => {
    const rows = data[table];
    if (!Array.isArray(rows)) return;
    const sec = document.createElement("section");
    sec.className = "ref-type-block";
    const h = document.createElement("h4");
    h.textContent = REF_TYPE_SECTION_LABELS[table] || table;
    const tbl = document.createElement("table");
    tbl.className = "mock-table";
    tbl.innerHTML =
      "<thead><tr><th>code</th><th>label_en</th><th>label_pt</th></tr></thead>";
    const tb = document.createElement("tbody");
    rows.forEach((row) => {
      const tr = document.createElement("tr");
      tr.dataset.refTable = table;
      tr.dataset.refId = String(row.id);
      tr.innerHTML = `<td><code>${escapeHtml(row.code || "")}</code></td>
        <td><input type="text" class="table-input ref-lbl-en" value="${escapeHtml(row.label_en || "")}" /></td>
        <td><input type="text" class="table-input ref-lbl-pt" value="${escapeHtml(row.label_pt || "")}" /></td>`;
      tb.appendChild(tr);
    });
    tbl.appendChild(tb);
    sec.appendChild(h);
    sec.appendChild(tbl);
    root.appendChild(sec);
  });
}

function readRefTypesPayloadFromDom() {
  const root = document.getElementById("ref-types-tables-root");
  if (!root) return {};
  const out = {};
  root.querySelectorAll("tbody tr[data-ref-table]").forEach((tr) => {
    const table = tr.getAttribute("data-ref-table");
    const id = Number(tr.getAttribute("data-ref-id"));
    if (!table || !Number.isFinite(id)) return;
    const label_en = tr.querySelector(".ref-lbl-en")?.value ?? "";
    const label_pt = tr.querySelector(".ref-lbl-pt")?.value ?? "";
    if (!out[table]) out[table] = [];
    out[table].push({ id, label_en, label_pt });
  });
  return out;
}

async function loadRefTypesFromApi() {
  setRefTypesStatus("A carregar tipos de domínio (ref.*)…", false);
  try {
    const res = await fetch("/api/ref/types");
    if (!res.ok) throw new Error("bad");
    const data = await res.json();
    renderRefTypesToRoot(data);
    setRefTypesStatus("", false);
  } catch {
    setRefTypesStatus("Falha ao carregar ref.* (ver API e schema 04).", true);
  }
}

async function saveRefTypesFromApi() {
  const body = readRefTypesPayloadFromDom();
  setRefTypesStatus("A guardar…", false);
  try {
    const res = await fetch("/api/ref/types", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || res.statusText);
    }
    setRefTypesStatus("Guardado.", false);
    await loadRefTypesFromApi();
  } catch (e) {
    setRefTypesStatus(e.message || "Falha ao guardar.", true);
  }
}

// Lógica do Modal de Traduções (Configurações)
const modalTranslations = document.getElementById("modal-translations");
const modalVisualization = document.getElementById("modal-visualization");
const modalUsers = document.getElementById("modal-users");
const modalRefTypes = document.getElementById("modal-ref-types");
const btnOpenTranslations = document.getElementById("btn-open-translations");
const btnCloseTranslations = document.getElementById("btn-close-translations");
const btnOpenVisualization = document.getElementById("btn-open-visualization");
const btnCloseVisualization = document.getElementById("btn-close-visualization");
const btnOpenUsers = document.getElementById("btn-open-users");
const btnCloseUsers = document.getElementById("btn-close-users");
const btnOpenRefTypes = document.getElementById("btn-open-ref-types");
const btnCloseRefTypes = document.getElementById("btn-close-ref-types");
const btnRefTypesReload = document.getElementById("btn-ref-types-reload");
const btnRefTypesSave = document.getElementById("btn-ref-types-save");
const configDropdown = document.querySelector(".config-dropdown");
const selectLanguage = document.getElementById("select-language");

btnOpenTranslations.addEventListener("click", () => {
  modalTranslations.style.display = "flex";
  // Fecha o dropdown quando abre a modal
  if (configDropdown) configDropdown.removeAttribute("open");
});

btnCloseTranslations.addEventListener("click", () => {
  modalTranslations.style.display = "none";
});

if (btnOpenVisualization && modalVisualization) {
  btnOpenVisualization.addEventListener("click", () => {
    modalVisualization.style.display = "flex";
    if (configDropdown) configDropdown.removeAttribute("open");
  });
}

if (btnCloseVisualization && modalVisualization) {
  btnCloseVisualization.addEventListener("click", () => {
    modalVisualization.style.display = "none";
  });
}

if (btnOpenUsers && modalUsers) {
  btnOpenUsers.addEventListener("click", () => {
    modalUsers.style.display = "flex";
    modalUsers.setAttribute("aria-hidden", "false");
    if (configDropdown) configDropdown.removeAttribute("open");
    loadUsersFromApi();
  });
}
if (btnCloseUsers && modalUsers) {
  btnCloseUsers.addEventListener("click", () => {
    modalUsers.style.display = "none";
    modalUsers.setAttribute("aria-hidden", "true");
  });
}

if (btnOpenRefTypes && modalRefTypes) {
  btnOpenRefTypes.addEventListener("click", () => {
    modalRefTypes.style.display = "flex";
    modalRefTypes.setAttribute("aria-hidden", "false");
    if (configDropdown) configDropdown.removeAttribute("open");
    loadRefTypesFromApi();
  });
}
if (btnCloseRefTypes && modalRefTypes) {
  btnCloseRefTypes.addEventListener("click", () => {
    modalRefTypes.style.display = "none";
    modalRefTypes.setAttribute("aria-hidden", "true");
  });
}
btnRefTypesReload?.addEventListener("click", () => loadRefTypesFromApi());
btnRefTypesSave?.addEventListener("click", () => saveRefTypesFromApi());

const btnOpenHelp = document.getElementById("btn-open-help");
if (btnOpenHelp) {
  btnOpenHelp.addEventListener("click", () => {
    if (configDropdown) configDropdown.removeAttribute("open");
    const base = window.location.origin + (window.location.pathname.replace(/\/[^/]*$/, "") || "");
    window.open(`${base}/help.html`, "_blank", "noopener,noreferrer");
  });
}

selectLanguage.addEventListener("change", async (e) => {
  const lang = e.target.value;
  const label = e.target.options[e.target.selectedIndex].text;
  if (configDropdown) configDropdown.removeAttribute("open");

  // Mensagem só depois do fetch: evita que operações assíncronas posteriores
  // (ex.: WFS de municípios) sobrescrevam o log antes de concluir as traduções.
  const translations = await loadTranslations(lang);
  if (translations) {
    const prefix =
      translations.UI_STATUS_LANG_PREFIX || "Idioma da sessão alterado para:";
    setStatus(`${prefix} ${label}`);
  }
});

/**
 * Carrega traduções da API e aplica a elementos [data-i18n].
 * @param {string} lang código ISO (en, pt, es, it)
 * @returns {Promise<Record<string, string>|null>} mapa de chaves ou null em erro
 */
async function loadTranslations(lang) {
  try {
    const res = await fetch(`/api/translations/${lang}`);
    if (!res.ok) throw new Error("Failed to fetch translations");
    const translations = await res.json();
    i18nCache = translations;

    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (translations[key]) {
        el.textContent = translations[key];
      }
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => {
      const key = el.getAttribute("data-i18n-placeholder");
      if (translations[key]) {
        el.setAttribute("placeholder", translations[key]);
      }
    });
    document.querySelectorAll("[data-i18n-title]").forEach((el) => {
      const key = el.getAttribute("data-i18n-title");
      if (translations[key]) {
        el.setAttribute("title", translations[key]);
      }
    });
    return translations;
  } catch (error) {
    console.error("Error loading translations:", error);
    setStatus("Falha ao carregar traduções da API.");
    return null;
  }
}

// Load initial translations based on selected language
loadTranslations(selectLanguage.value);

// Fechar os painéis e modais ao clicar fora
document.addEventListener("click", (event) => {
  const details = document.querySelectorAll("details.panel-section, details.config-dropdown");
  details.forEach((detail) => {
    if (detail.open && !detail.contains(event.target)) {
      // Ignorar cliques no próprio botão (summary) que já são tratados nativamente
      if (!event.target.closest("summary")) {
        detail.removeAttribute("open");
      }
    }
  });

  // Fechar modal ao clicar na overlay escura (fora do modal-content)
  if (event.target === modalTranslations) {
    modalTranslations.style.display = "none";
  }
  if (event.target === modalVisualization) {
    modalVisualization.style.display = "none";
  }
  if (modalUsers && event.target === modalUsers) {
    modalUsers.style.display = "none";
    modalUsers.setAttribute("aria-hidden", "true");
  }
  if (modalRefTypes && event.target === modalRefTypes) {
    modalRefTypes.style.display = "none";
    modalRefTypes.setAttribute("aria-hidden", "true");
  }
});

// Auto exibir Limite do Estado (UF) em zooms muito distantes
// Auto habilitar Bairros (e desabilitar Municípios) em zooms muito próximos
map.on("zoomend", () => {
  const zoom = map.getZoom();
  const cfg = getEffectiveLayerZoomCfg();

  maybeAutoShowBairrosEViasByZoomPercent();

  // Lógica UF (Estado)
  const temUF = map.hasLayer(ufLayer);
  if (zoom < 9 && !temUF) {
    ufLayer.addTo(map);
  } else if (zoom >= 9 && temUF) {
    map.removeLayer(ufLayer);
  }

  // Lógica Bairros vs Municípios (respeita o toggle de Bairros em zoom ≥ 12)
  const temBairros = map.hasLayer(bairrosAlvoLayer);
  const temMunicipios = map.hasLayer(municipiosAlvoLayer);
  const checkboxBairros = document.getElementById("bairros_alvo_sp");
  const checkboxMunicipios = document.getElementById("municipios_alvo_sp");
  const bairrosPretendidos = checkboxBairros && checkboxBairros.checked;

  if (zoom >= cfg.bairrosEnableMin) {
    if (bairrosPretendidos) {
      if (!temBairros) bairrosAlvoLayer.addTo(map);
      if (temMunicipios) {
        map.removeLayer(municipiosAlvoLayer);
        if (checkboxMunicipios) checkboxMunicipios.checked = false;
      }
    } else {
      if (temBairros) map.removeLayer(bairrosAlvoLayer);
      if (!temMunicipios) {
        municipiosAlvoLayer.addTo(map);
        if (checkboxMunicipios) checkboxMunicipios.checked = true;
      }
    }
  } else {
    if (zoom < cfg.bairrosDisableBelow && temBairros) {
      map.removeLayer(bairrosAlvoLayer);
      if (checkboxBairros) checkboxBairros.checked = false;
    }
    if (!temMunicipios) {
      municipiosAlvoLayer.addTo(map);
      if (checkboxMunicipios) checkboxMunicipios.checked = true;
    }
  }

  const checkboxVias = document.getElementById("vias_alvo_sp");
  const temVias = map.hasLayer(viasAlvoLayer);
  if (zoom < cfg.viasDisableBelow && temVias) {
    map.removeLayer(viasAlvoLayer);
    if (checkboxVias) checkboxVias.checked = false;
  }
});

// Carrega municípios-alvo no arranque; CORS pode bloquear em dev :5173 — preferir :8088
loadMunicipiosAlvoWfs().catch(() => {
  setStatus(
    `Falha ao carregar municípios (WFS). Prefira http://HOST:8088 e verifique GeoServer (ver docs/DEPLOY_POC.md).`
  );
});

// Consulta de atributos ao clicar no mapa
map.on("click", (ev) => {
  // Fechar os dropdowns abertos ao clicar no mapa (pois o Leaflet pode não propagar o evento para o document)
  document.querySelectorAll("details[open]").forEach(d => d.removeAttribute("open"));

  getFeatureInfoAtEvent(ev).catch(() =>
    setStatus(
      `Falha ao consultar feição. Verifique GeoServer em ${geoserverBase} (ver docs/DEPLOY_POC.md).`
    )
  );
});

// ── Monitorização de erros de tiles ──────────────────────────────────────

// Utilitário para desenvolvedor: Copiar a BBOX atual para a clipboard (útil no DevTools)
window.copyBboxToClipboard = function() {
  const b = map.getBounds();
  const cmd = `fitBounds(${b.getWest().toFixed(4)}, ${b.getSouth().toFixed(4)}, ${b.getEast().toFixed(4)}, ${b.getNorth().toFixed(4)});`;
  
  // Em HTTP local fora de localhost o clipboard API é bloqueado, usamos prompt() de fallback
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(cmd).then(() => {
      console.log("BBOX copiada para a área de transferência: " + cmd);
      setStatus("BBOX copiada para a área de transferência!");
    }).catch(err => {
      console.error("Falha ao copiar:", err);
      console.log("A tua BBOX é:", cmd);
      prompt("Copia a BBOX abaixo (Ctrl+C):", cmd);
    });
  } else {
    console.log("A tua BBOX é:", cmd);
    prompt("Copia a BBOX abaixo (Ctrl+C):", cmd);
  }
};
console.log("Dica Dev: Usa a função copyBboxToClipboard() na consola para obteres a BBOX exata da vista atual.");

/**
 * tileerror dispara quando um tile WMS não pode ser carregado.
 * A mensagem inclui a URL base do GeoServer para diagnóstico rápido.
 * Causa mais comum: serviço GeoServer não iniciado ou camada não publicada.
 */
[ufLayer, municipiosLayer, municipiosAlvoLayer, bairrosAlvoLayer, viasAlvoLayer]
  .forEach((layer) => {
    layer.on("tileerror", () => {
      setStatus(
        `Falha ao carregar tiles WMS. Verifique GeoServer em ${geoserverBase} (ver docs/DEPLOY_POC.md).`
      );
    });
  });

/**
 * tileerror no satélite local pode ter duas causas distintas:
 *
 * 1. TileServer inacessível / MBTiles não gerado → *Confirmed=false
 *    → mostrar mensagem de remediação completa.
 *
 * 2. Tile fora da cobertura do MBTiles (bbox capital SP) → TileServer responde
 *    404 normalmente; quando *Confirmed=true este erro é silenciado
 *    pois é comportamento esperado de um pacote de área parcial.
 */
[satelliteLocalLayer, geosampaOfflineLayer].forEach((layer) => layer.on("tileerror", () => {
  const confirmed = layer === geosampaOfflineLayer
    ? geosampaOfflineConfirmed
    : satelliteLocalConfirmed;
  if (!confirmed) {
    setStatus(
      "Falha tiles MBTiles. Gere o pacote local e suba tileserver (ver docs/DEPLOY_POC.md)."
    );
  }
}));

// ── Toggles de camadas ────────────────────────────────────────────────────

/**
 * Valida o nível de zoom antes de ativar camadas densas para evitar pedidos
 * pesados e poluição visual. Reverte o toggle e avisa o utilizador se inválido.
 */
function enforceZoomValidation(event, layer, layerName, minZoom, maxZoom = 20) {
  if (event.target.checked) {
    const z = map.getZoom();
    if (z < minZoom || z > maxZoom) {
      event.target.checked = false; // reverte
      setStatus(`Zoom atual (${z}) inválido para ${layerName}. Escala permitida: ${minZoom} a ${maxZoom}.`);
      return;
    }
    layer.addTo(map);
    setStatus(`Camada ${layerName} ativada.`);
  } else {
    map.removeLayer(layer);
    setStatus(`Camada ${layerName} desativada.`);
  }
}

/**
 * Cada toggle controla uma camada WMS independente.
 * A camada é adicionada/removida do mapa mas o objecto Leaflet é reutilizado,
 * preservando o cache de tiles já descarregados.
 */
document.getElementById("municipios_sp").addEventListener("change", (event) => {
  if (event.target.checked) municipiosLayer.addTo(map);
  else map.removeLayer(municipiosLayer);
});

document.getElementById("municipios_alvo_sp").addEventListener("change", (event) => {
  if (event.target.checked) municipiosAlvoLayer.addTo(map);
  else map.removeLayer(municipiosAlvoLayer);
});

// Camadas com restrição de zoom
document.getElementById("bairros_alvo_sp").addEventListener("change", (event) => {
  const cfg = getEffectiveLayerZoomCfg();
  enforceZoomValidation(event, bairrosAlvoLayer, "Bairros", cfg.bairrosEnableMin, 20);
});

document.getElementById("vias_alvo_sp").addEventListener("change", (event) => {
  const cfg = getEffectiveLayerZoomCfg();
  enforceZoomValidation(event, viasAlvoLayer, "Vias", cfg.viasEnableMin, 20);
});

// ── Botões de navegação rápida ────────────────────────────────────────────

// Os antigos botões zoom-state, zoom-capital e zoom-campinas foram removidos.
