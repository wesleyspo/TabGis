'use strict';

/**
 * Lado da célula da grelha métrica (UTM 23S), em metros — agregação OMS no mapa.
 * @param {unknown} zoom valor vindo de query string (Leaflet)
 * @returns {number}
 */
function omsAggregateCellMetersFromZoom(zoom) {
  if (zoom === null || zoom === undefined || zoom === '') return 5500;
  const z = Number(zoom);
  if (!Number.isFinite(z)) return 5500;
  if (z <= 8) return 12000;
  if (z <= 9) return 8000;
  if (z <= 10) return 5500;
  if (z <= 11) return 3500;
  if (z <= 12) return 1800;
  return 900;
}

module.exports = { omsAggregateCellMetersFromZoom };
