'use strict';

/**
 * Valida o corpo de PATCH para `schematic.view_node` (rótulo e foco geográfico).
 * Foco: `focus_lat` e `focus_lng` devem vir juntos (ou ambos `null` para limpar o par).
 * @param {unknown} body
 * @returns {{ ok: true, updates: Record<string, unknown> } | { ok: false, error: string, status: number }}
 */
function validateViewNodePatch(body) {
  if (body == null || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, error: 'Expected JSON object', status: 400 };
  }
  const hasLat = Object.prototype.hasOwnProperty.call(body, 'focus_lat');
  const hasLng = Object.prototype.hasOwnProperty.call(body, 'focus_lng');
  if (hasLat !== hasLng) {
    return {
      ok: false,
      error: 'Use focus_lat and focus_lng together (or neither)',
      status: 400,
    };
  }
  const updates = {};
  if (Object.prototype.hasOwnProperty.call(body, 'label')) {
    const s = body.label == null ? '' : String(body.label).trim();
    if (s.length > 200) {
      return { ok: false, error: 'label must be at most 200 characters', status: 400 };
    }
    updates.label = s;
  }
  if (hasLat && hasLng) {
    if (
      (body.focus_lat === null || body.focus_lat === '') &&
      (body.focus_lng === null || body.focus_lng === '')
    ) {
      updates.focus_lat = null;
      updates.focus_lng = null;
    } else {
      const la = Number(body.focus_lat);
      const lo = Number(body.focus_lng);
      if (Number.isNaN(la) || la < -90 || la > 90) {
        return { ok: false, error: 'focus_lat must be between -90 and 90', status: 400 };
      }
      if (Number.isNaN(lo) || lo < -180 || lo > 180) {
        return { ok: false, error: 'focus_lng must be between -180 and 180', status: 400 };
      }
      updates.focus_lat = la;
      updates.focus_lng = lo;
    }
  }
  if (Object.keys(updates).length === 0) {
    return {
      ok: false,
      error: 'No updatable fields: label, or pair (focus_lat, focus_lng)',
      status: 400,
    };
  }
  return { ok: true, updates };
}

module.exports = { validateViewNodePatch };
