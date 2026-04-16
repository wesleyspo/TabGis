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

/**
 * Pane dedicado para o satélite (raster de fundo).
 * zIndex 100 garante que fica abaixo das camadas vectoriais WMS
 * mas acima do fundo cinza padrão do Leaflet.
 */
map.createPane("satellite");
map.getPane("satellite").style.zIndex = "100";

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

/** Marcadores de ordens (cor = estado, raio ≈ tipo, traço ≈ equipa) */
const workOrderMarkersGroup = L.layerGroup().addTo(map);

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
  const satActive = map.hasLayer(satelliteLayer) || map.hasLayer(satelliteLocalLayer);
  setVectorOverSatOpacity(satActive);
}

// ── Controlos de camadas satélite (exclusão mútua online/local) ───────────

/**
 * Os dois satélites são mutuamente exclusivos: activar um desliga o outro.
 * Isto evita tiles sobrepostos que causariam degradação visual.
 */
document.getElementById("satellite_online").addEventListener("change", (event) => {
  const localCb = document.getElementById("satellite_local");
  if (event.target.checked) {
    localCb.checked = false;
    map.removeLayer(satelliteLocalLayer);
    satelliteLayer.addTo(map);
    refreshSatelliteOpacity();
    setStatus("Satélite online activo (UF/municípios mais transparentes).");
  } else {
    map.removeLayer(satelliteLayer);
    refreshSatelliteOpacity();
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
  if (event.target.checked) {
    onlineCb.checked = false;
    map.removeLayer(satelliteLayer);
    setStatus("A verificar TileServer…");
    try {
      const meta = await checkTileServerHealth();
      satelliteLocalConfirmed = true;
      satelliteLocalLayer.addTo(map);
      refreshSatelliteOpacity();
      setStatus(
        `Satélite local activo — capital SP, zoom ${meta.minzoom}–${meta.maxzoom}.`
      );
    } catch {
      satelliteLocalConfirmed = false;
      event.target.checked = false;
      setStatus(
        "Falha tiles MBTiles. Gere sp_satellite.mbtiles e suba tileserver (ver docs/DEPLOY_POC.md)."
      );
    }
  } else {
    map.removeLayer(satelliteLocalLayer);
    satelliteLocalConfirmed = false;
    refreshSatelliteOpacity();
    setStatus("Satélite local desligado.");
  }
});

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
 */
function fitBoundsHomeInset(minLon, minLat, maxLon, maxLat, inset) {
  const cLat = (minLat + maxLat) / 2;
  const cLon = (minLon + maxLon) / 2;
  const hLat = ((maxLat - minLat) / 2) * inset;
  const hLon = ((maxLon - minLon) / 2) * inset;
  map.fitBounds([
    [cLat - hLat, cLon - hLon],
    [cLat + hLat, cLon + hLon],
  ]);
}

/** Mapa em tela cheia: ~4% menos zoom que inset 0,9 (área visível um pouco maior). */
const HOME_INSET_FULL = 0.9 * 1.04;

/** Com painel 50%: ~8% mais zoom que a mesma cena em tela cheia (compensa metade da largura). */
const HOME_INSET_SPLIT = HOME_INSET_FULL / 1.08;

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

/**
 * Verifica a disponibilidade do TileServer consultando o endpoint de metadados
 * do dataset (não depende de coordenadas específicas de tile).
 * Devolve os metadados em caso de sucesso, ou lança excepção se inacessível.
 * @returns {Promise<{minzoom: number, maxzoom: number}>}
 */
async function checkTileServerHealth() {
  const res = await fetch(`${getLocalTilesBase()}/data/sp_sat.json`, {
    signal: AbortSignal.timeout(5000),
  });
  if (!res.ok) throw new Error(`TileServer respondeu HTTP ${res.status}`);
  return res.json();
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
  if (f) {
    fitMapToGeoJSONFeatureCollection({ type: "FeatureCollection", features: [f] });
    setStatus(`Bairro focado: ${bairroNome}`);
  }
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
    try {
      const json = JSON.parse(text);
      html = gfiJsonToHtml(json);
    } catch {
      html = "";
    }
    // Fallback: texto bruto (útil para respostas de erro do GeoServer < 4 KB)
    if (!html && text.length && text.length < 4000) {
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
  if (!html) html = "<p>Sem dados neste ponto.</p>";
  L.popup({ autoPanPaddingTopLeft: [0, 80] }).setLatLng(ev.latlng).setContent(html).openOn(map);
}

// ── Inicialização ─────────────────────────────────────────────────────────

// Função Home: visão dependente do estado do painel lateral (mesmos parâmetros que ao abrir a URL)
function setHomeView() {
  map.invalidateSize();
  const split = document.querySelector(".app").classList.contains("has-left-panel");
  requestAnimationFrame(() => {
    if (split) {
      fitBoundsHomeInset(
        -47.2496,
        -24.1088,
        -46.2513,
        -23.1966,
        HOME_INSET_SPLIT
      );
    } else {
      fitBoundsHomeInset(
        -47.6480,
        -24.0674,
        -45.9180,
        -23.2733,
        HOME_INSET_FULL
      );
    }
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
}

map.whenReady(() => {
  requestAnimationFrame(runInitialMapLayout);
});

// Respaldo: contentor flex às vezes só tem altura definitiva após pintura
setTimeout(runInitialMapLayout, 400);

document.getElementById("search-municipio").addEventListener("change", (e) => onMunicipioSelected(e.target.value));
document.getElementById("search-bairro").addEventListener("change", (e) => onBairroSelected(e.target.value));
document.getElementById("btn-home").addEventListener("click", setHomeView);

// Lógica do Painel Esquerdo (Operação)
const btnOperacao = document.getElementById("btn-operacao");
const btnCloseOperacao = document.getElementById("btn-close-operacao");
const appContainer = document.querySelector(".app");

function toggleLeftPanel() {
  const isOpening = !appContainer.classList.contains("has-left-panel");
  appContainer.classList.toggle("has-left-panel");
  
  // Aguardar a transição CSS (300ms) para invalidar o tamanho do mapa
  setTimeout(() => {
    map.invalidateSize();
    // Se o painel está sendo aberto, foca na capital de modo que fique bem enquadrada nos 50%
    if (isOpening) {
      setHomeView();
      loadWorkOrdersFromApi();
      loadTeamsFromApi();
    }
  }, 300);
}

btnOperacao.addEventListener("click", toggleLeftPanel);
btnCloseOperacao.addEventListener("click", toggleLeftPanel);

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

    if (id === "usr") loadUsersFromApi();
    if (id === "oms") loadWorkOrdersFromApi();
    if (id === "mwm") loadTeamsFromApi();
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
    m.addTo(workOrderMarkersGroup);
  });
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
  map.setView([latNum, lngNum], 14);
  const cbMuni = document.getElementById("municipios_alvo_sp");
  const cbBairros = document.getElementById("bairros_alvo_sp");
  const cbVias = document.getElementById("vias_alvo_sp");
  if (cbMuni) cbMuni.checked = false;
  if (map.hasLayer(municipiosAlvoLayer)) map.removeLayer(municipiosAlvoLayer);
  if (cbBairros) cbBairros.checked = true;
  if (cbVias) cbVias.checked = true;
  if (!map.hasLayer(bairrosAlvoLayer)) bairrosAlvoLayer.addTo(map);
  if (!map.hasLayer(viasAlvoLayer)) viasAlvoLayer.addTo(map);
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

/** Contador compacto: símbolo + valor (tooltip no contentor). */
function woCounter(sym, title, value) {
  const v = value != null && value !== "" && !Number.isNaN(Number(value)) ? String(value) : "—";
  return `<span class="wo-ctr" title="${escapeHtml(title)}"><span class="wo-ctr-sym" aria-hidden="true">${sym}</span><span class="wo-ctr-val">${escapeHtml(v)}</span></span>`;
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

function woPriPosCell(r) {
  const pri = r.priority != null && String(r.priority).trim() !== "" ? String(r.priority).trim() : "—";
  const priTitle = uiText("UI_TT_PRIORITY_LETTER", "Prioridade operacional (P1…)");
  const posTitle = uiText("UI_TT_POS_SCORE", "POS / peso numérico para triagem");
  const posVal = r.priority_score != null ? String(r.priority_score) : "—";
  return `<span class="wo-pripos"><abbr class="wo-pri-abbr" title="${escapeHtml(priTitle)}">${escapeHtml(pri)}</abbr><span class="wo-pos-wrap" title="${escapeHtml(posTitle)}"><span class="wo-pos-ic" aria-hidden="true">⌖</span><span class="wo-pos-val">${escapeHtml(posVal)}</span></span></span>`;
}

function woCallbackPhonesCell(r) {
  const humOn = !!r.flag_customer_callback;
  const autoOn = !!r.callback_auto;
  const th = uiText("UI_TT_CALLBACK_HUM", "Callback humano (operador / contacto directo)");
  const ta = uiText("UI_TT_CALLBACK_AUTO", "Callback automático (IVR, SMS, BOT)");
  return `<span class="wo-cb-row"><span class="wo-cb wo-cb--hum ${humOn ? "wo-cb--on" : ""}" title="${escapeHtml(th)}">☎</span><span class="wo-cb wo-cb--auto ${autoOn ? "wo-cb--on" : ""}" title="${escapeHtml(ta)}">⚙</span></span>`;
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

async function loadWorkOrdersFromApi() {
  const tbody = document.getElementById("oms-orders-tbody");
  if (!tbody) return;
  setOmsStatusMessage(i18nCache.UI_OP_STATUS_LOADING_ORDERS || "A carregar ordens…", false);
  try {
    const res = await fetch("/api/work-orders");
    if (!res.ok) throw new Error("bad response");
    const rows = await res.json();
    tbody.innerHTML = "";
    rows.forEach((r) => {
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
      const mun = r.municipality_name || "—";
      const bai = r.neighborhood_name || "—";
      const loc = mun === "—" && bai === "—" ? "—" : `${mun} · ${bai}`;
      tr.innerHTML = `
        <td>${escapeHtml(r.order_code)}</td>
        <td class="wo-start">${escapeHtml(formatStartCompact(r.start_time || r.created_at))}</td>
        <td class="wo-icon-cell">${woCounter("⏱", hoursTitle, r.hours_open)}</td>
        <td><abbr title="${escapeHtml(orderTypeLabel(r.order_type))}">${escapeHtml(orderTypeAbbr(r.order_type))}</abbr></td>
        <td class="wo-ellipsis" title="${escapeHtml(r.organization_label || "")}">${escapeHtml(r.organization_label || "—")}</td>
        <td class="wo-ellipsis" title="${escapeHtml(loc)}">${escapeHtml(loc)}</td>
        <td class="wo-ellipsis">${escapeHtml(r.equipment_code || "—")}</td>
        <td class="wo-icon-cell">${woCounter("⌂", affTitle, r.affected_customers_count)}</td>
        <td class="wo-icon-cell">${woCounter("◆", compTitle, r.complaints_linked_count)}</td>
        <td class="wo-icon-cell">${woFlagsCell(r)}</td>
        <td class="wo-pripos-cell">${woPriPosCell(r)}</td>
        <td class="wo-icon-cell">${woCallbackPhonesCell(r)}</td>
        <td>${escapeHtml(r.team_code || "—")}</td>
        <td>${escapeHtml(r.owner_username || "—")}</td>
        <td data-col="status"></td>
        <td class="wo-summary-cell">${escapeHtml(r.summary || "—")}</td>
        <td><button type="button" class="mock-btn-open-order" data-i18n="UI_OP_OPEN_DETAIL">${i18nCache.UI_OP_OPEN_DETAIL || "Folha"}</button></td>
        <td>${mapBtn}</td>
      `;
      const statusTd = tr.querySelector('td[data-col="status"]');
      if (statusTd) statusTd.appendChild(statusSpan);
      tbody.appendChild(tr);
    });
    rebuildWorkOrderMarkers(rows);
    setOmsStatusMessage(
      rows.length ? "" : i18nCache.UI_OP_NO_ORDERS || "Sem ordens na base.",
      false
    );
    const lang = document.getElementById("select-language")?.value || "pt";
    loadTranslations(lang);
  } catch {
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
  setTeamsStatusMessage(i18nCache.UI_OP_STATUS_LOADING_TEAMS || "A carregar equipas…", false);
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
      tbody.appendChild(tr);
    });
    setTeamsStatusMessage(rows.length ? "" : i18nCache.UI_OP_NO_TEAMS || "Sem equipas registadas.", false);
    const lang = document.getElementById("select-language")?.value || "pt";
    loadTranslations(lang);
  } catch {
    setTeamsStatusMessage(
      "Falha ao carregar equipas. Verifique o serviço API (ver docs/DEPLOY_POC.md).",
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
        map.setView([lat, lng], 15);
        setStatus(
          i18nCache.UI_OP_STATUS_MAP_CENTERED ||
            "Mapa centrado na última posição conhecida da equipa."
        );
      }
      return;
    }

    const openBtn = e.target.closest(".mock-btn-open-order");
    if (openBtn) {
      e.stopPropagation();
      const row = openBtn.closest(".order-row-api");
      const id = row?.getAttribute("data-order-id");
      if (id) openOrderSheetModal(id);
      return;
    }

    const row = e.target.closest(".order-row-api");
    if (row && !e.target.closest("button")) {
      const id = row.getAttribute("data-order-id");
      if (id) openOrderSheetModal(id);
    }
  });

  panels.addEventListener("keydown", (e) => {
    if (e.key !== "Enter" && e.key !== " ") return;
    const row = e.target.closest?.(".order-row-api");
    if (!row || e.target.closest("button")) return;
    e.preventDefault();
    const id = row.getAttribute("data-order-id");
    if (id) openOrderSheetModal(id);
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


// Lógica do Modal de Traduções (Configurações)
const modalTranslations = document.getElementById("modal-translations");
const btnOpenTranslations = document.getElementById("btn-open-translations");
const btnCloseTranslations = document.getElementById("btn-close-translations");
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
});

// Auto exibir Limite do Estado (UF) em zooms muito distantes
// Auto habilitar Bairros (e desabilitar Municípios) em zooms muito próximos
map.on("zoomend", () => {
  const zoom = map.getZoom();
  
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

  if (zoom >= 12) {
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
    if (temBairros) {
      map.removeLayer(bairrosAlvoLayer);
      if (checkboxBairros) checkboxBairros.checked = false;
    }
    if (!temMunicipios) {
      municipiosAlvoLayer.addTo(map);
      if (checkboxMunicipios) checkboxMunicipios.checked = true;
    }
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
 * 1. TileServer inacessível / MBTiles não gerado → satelliteLocalConfirmed=false
 *    → mostrar mensagem de remediação completa.
 *
 * 2. Tile fora da cobertura do MBTiles (bbox capital SP) → TileServer responde
 *    404 normalmente; quando satelliteLocalConfirmed=true este erro é silenciado
 *    pois é comportamento esperado de um pacote de área parcial.
 */
satelliteLocalLayer.on("tileerror", () => {
  if (!satelliteLocalConfirmed) {
    setStatus(
      "Falha tiles MBTiles. Gere sp_satellite.mbtiles e suba tileserver (ver docs/DEPLOY_POC.md)."
    );
  }
});

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
  enforceZoomValidation(event, bairrosAlvoLayer, "Bairros", 12, 20);
});

document.getElementById("vias_alvo_sp").addEventListener("change", (event) => {
  enforceZoomValidation(event, viasAlvoLayer, "Vias", 13, 20);
});

// ── Botões de navegação rápida ────────────────────────────────────────────

// Os antigos botões zoom-state, zoom-capital e zoom-campinas foram removidos.
