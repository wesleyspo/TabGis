'use strict';

/**
 * Valida PATCH de deslocamento (planned/actual times + notes).
 * @param {unknown} body
 * @returns {{ ok: true, updates: Record<string, unknown> } | { ok: false, error: string, status: number }}
 */
function parseDisplacementPatch(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, error: 'Expected JSON object', status: 400 };
  }

  const allowed = [
    'planned_departure_at',
    'planned_arrival_at',
    'actual_departure_at',
    'actual_arrival_at',
    'notes',
  ];
  const updates = {};
  for (const field of allowed) {
    if (!Object.prototype.hasOwnProperty.call(body, field)) continue;
    const v = body[field];
    if (v === null) {
      updates[field] = null;
      continue;
    }
    if (field === 'notes') {
      if (typeof v !== 'string') {
        return { ok: false, error: 'notes must be a string or null', status: 400 };
      }
      updates[field] = v.slice(0, 500);
      continue;
    }
    if (typeof v !== 'string') {
      return {
        ok: false,
        error: `${field} must be an ISO-8601 timestamp string or null`,
        status: 400,
      };
    }
    const t = Date.parse(v);
    if (Number.isNaN(t)) {
      return {
        ok: false,
        error: `${field} must be a valid ISO-8601 timestamp`,
        status: 400,
      };
    }
    updates[field] = new Date(t).toISOString();
  }

  if (Object.keys(updates).length === 0) {
    return {
      ok: false,
      error:
        'No updatable fields: planned_departure_at, planned_arrival_at, actual_departure_at, actual_arrival_at, notes',
      status: 400,
    };
  }
  return { ok: true, updates };
}

module.exports = { parseDisplacementPatch };
