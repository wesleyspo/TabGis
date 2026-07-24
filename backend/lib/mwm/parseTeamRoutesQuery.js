'use strict';

/**
 * Valida query de GET /api/mwm/team-routes.
 * @param {Record<string, unknown>} query
 * @returns {{ ok: true, hours: number, teamId: number|null } | { ok: false, error: string, status: number }}
 */
function parseTeamRoutesQuery(query) {
  const q = query && typeof query === 'object' ? query : {};
  let hours = 48;
  if (Object.prototype.hasOwnProperty.call(q, 'hours') && q.hours !== '' && q.hours != null) {
    hours = Number(q.hours);
    if (!Number.isInteger(hours) || hours < 1 || hours > 168) {
      return {
        ok: false,
        error: 'hours must be an integer between 1 and 168 (default 48)',
        status: 400,
      };
    }
  }
  let teamId = null;
  if (Object.prototype.hasOwnProperty.call(q, 'team_id') && q.team_id !== '' && q.team_id != null) {
    teamId = Number(q.team_id);
    if (!Number.isInteger(teamId) || teamId < 1) {
      return { ok: false, error: 'team_id must be a positive integer', status: 400 };
    }
  }
  return { ok: true, hours, teamId };
}

/**
 * Valida query de GET /api/mwm/displacements.
 * @param {Record<string, unknown>} query
 */
function parseDisplacementsQuery(query) {
  const q = query && typeof query === 'object' ? query : {};
  let teamId = null;
  let workOrderId = null;
  if (Object.prototype.hasOwnProperty.call(q, 'team_id') && q.team_id !== '' && q.team_id != null) {
    teamId = Number(q.team_id);
    if (!Number.isInteger(teamId) || teamId < 1) {
      return { ok: false, error: 'team_id must be a positive integer', status: 400 };
    }
  }
  if (
    Object.prototype.hasOwnProperty.call(q, 'work_order_id') &&
    q.work_order_id !== '' &&
    q.work_order_id != null
  ) {
    workOrderId = Number(q.work_order_id);
    if (!Number.isInteger(workOrderId) || workOrderId < 1) {
      return { ok: false, error: 'work_order_id must be a positive integer', status: 400 };
    }
  }
  const limit = Math.min(Math.max(1, parseInt(String(q.limit || '100'), 10) || 100), 500);
  return { ok: true, teamId, workOrderId, limit };
}

module.exports = {
  parseTeamRoutesQuery,
  parseDisplacementsQuery,
};
