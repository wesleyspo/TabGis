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
  if (z <= 13) return 1100;
  if (z <= 14) return 700;
  if (z <= 15) return 450;
  return 350;
}

module.exports = { omsAggregateCellMetersFromZoom };
