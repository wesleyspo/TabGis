'use strict';

/**
 * Valida PATCH de equipa (última posição / campos operacionais).
 * Campos: last_known_lat, last_known_lng, status, notes não aplicável —
 * só last_known_lat/lng e status.
 * @param {unknown} body
 * @returns {{ ok: true, updates: Record<string, unknown> } | { ok: false, error: string, status: number }}
 */
function parseTeamPatch(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, error: 'Expected JSON object', status: 400 };
  }

  const updates = {};
  if (Object.prototype.hasOwnProperty.call(body, 'last_known_lat')) {
    const lat = Number(body.last_known_lat);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      return { ok: false, error: 'last_known_lat must be a number in [-90, 90]', status: 400 };
    }
    updates.last_known_lat = lat;
  }
  if (Object.prototype.hasOwnProperty.call(body, 'last_known_lng')) {
    const lng = Number(body.last_known_lng);
    if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
      return {
        ok: false,
        error: 'last_known_lng must be a number in [-180, 180]',
        status: 400,
      };
    }
    updates.last_known_lng = lng;
  }
  if (Object.prototype.hasOwnProperty.call(body, 'status')) {
    const s = String(body.status || '').trim().toLowerCase();
    if (!['active', 'inactive', 'paused'].includes(s)) {
      return {
        ok: false,
        error: "status must be one of: active, inactive, paused",
        status: 400,
      };
    }
    updates.status = s;
  }
  if (Object.keys(updates).length === 0) {
    return {
      ok: false,
      error: 'No updatable fields: last_known_lat, last_known_lng, status',
      status: 400,
    };
  }
  return { ok: true, updates };
}

module.exports = { parseTeamPatch };
