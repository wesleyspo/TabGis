'use strict';

/**
 * @param {{ name: string; municipio_nome?: string | null; highway?: string | null }} r
 */
function formatLocalStreetDisplayName(r) {
  const mun = r.municipio_nome || '';
  const hw = r.highway || '';
  const display = mun
    ? `${r.name} — ${mun}${hw ? ` (${hw})` : ''}`
    : `${r.name}${hw ? ` (${hw})` : ''}`;
  return {
    lat: r.lat,
    lon: r.lon,
    display_name: display,
    type: 'way',
    class: 'highway',
    source: 'local',
  };
}

module.exports = { formatLocalStreetDisplayName };
