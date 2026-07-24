'use strict';

/**
 * Gera um código estável e legível para segmentos criados por desenho no mapa
 * ou quando o cliente omite `code` no POST /api/topology/spans.
 * Formato: SEG_YYYYMMDD_HHMMSSmmm (ex.: SEG_20260724_163045012)
 * @param {Date} [now]
 * @returns {string}
 */
function generateSpanCode(now = new Date()) {
  const pad = (n, w = 2) => String(n).padStart(w, '0');
  return (
    `SEG_${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_` +
    `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}${pad(now.getMilliseconds(), 3)}`
  );
}

/** Regex alinhado ao formato de generateSpanCode (também usado em E2E). */
const SPAN_CODE_AUTO_PATTERN = /^SEG_\d{8}_\d{9}$/;

module.exports = {
  generateSpanCode,
  SPAN_CODE_AUTO_PATTERN,
};
