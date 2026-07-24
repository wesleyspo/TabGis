'use strict';

/**
 * Validação pura dos corpos de escrita de segmentos lineares da rede
 * (`gis.network_span`) — POST / PATCH em /api/topology/spans.
 * Sem dependências de BD: testável com node:test.
 */

const CODE_MAX = 96;
const DESCRIPTION_MAX = 2000;
const UTILITY_DOMAIN_MAX = 16;
const MIN_VERTICES = 2;
const MAX_VERTICES = 500;

/** Código: identificador estável (letras, dígitos, hífen, sublinhado, ponto). */
const CODE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

function isPlainObject(v) {
  return v != null && typeof v === 'object' && !Array.isArray(v);
}

/**
 * Valida lista de vértices [[lng, lat], ...] de uma LineString.
 * @returns {{ ok: true, coordinates: number[][] } | { ok: false, error: string }}
 */
function validateCoordinates(raw) {
  if (!Array.isArray(raw)) {
    return { ok: false, error: 'coordinates must be an array of [lng, lat] pairs' };
  }
  if (raw.length < MIN_VERTICES) {
    return { ok: false, error: `coordinates must have at least ${MIN_VERTICES} vertices` };
  }
  if (raw.length > MAX_VERTICES) {
    return { ok: false, error: `coordinates must have at most ${MAX_VERTICES} vertices` };
  }
  const coordinates = [];
  for (let i = 0; i < raw.length; i++) {
    const pair = raw[i];
    if (!Array.isArray(pair) || pair.length !== 2) {
      return { ok: false, error: `coordinates[${i}] must be a [lng, lat] pair` };
    }
    const lng = Number(pair[0]);
    const lat = Number(pair[1]);
    if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
      return { ok: false, error: `coordinates[${i}][0] (lng) must be between -180 and 180` };
    }
    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      return { ok: false, error: `coordinates[${i}][1] (lat) must be between -90 and 90` };
    }
    coordinates.push([lng, lat]);
  }
  for (let i = 1; i < coordinates.length; i++) {
    if (coordinates[i][0] === coordinates[i - 1][0] && coordinates[i][1] === coordinates[i - 1][1]) {
      return { ok: false, error: `coordinates[${i}] repeats the previous vertex` };
    }
  }
  return { ok: true, coordinates };
}

function validateOptionalText(body, field, max, updates) {
  if (!Object.prototype.hasOwnProperty.call(body, field)) return null;
  if (body[field] == null || body[field] === '') {
    updates[field] = null;
    return null;
  }
  const s = String(body[field]).trim();
  if (s.length > max) {
    return `${field} must be at most ${max} characters`;
  }
  updates[field] = s || null;
  return null;
}

function validateOptionalEquipmentId(body, field, updates) {
  if (!Object.prototype.hasOwnProperty.call(body, field)) return null;
  if (body[field] == null || body[field] === '') {
    updates[field] = null;
    return null;
  }
  const id = Number(body[field]);
  if (!Number.isInteger(id) || id < 1) {
    return `${field} must be a positive integer or null`;
  }
  updates[field] = id;
  return null;
}

/**
 * Valida corpo de criação (POST /api/topology/spans).
 * Obrigatórios: code, coordinates. Opcionais: description, utility_domain,
 * equipment_from_id, equipment_to_id, metadata (objeto).
 * @returns {{ ok: true, span: Record<string, unknown> } | { ok: false, error: string, status: number }}
 */
function validateSpanCreate(body) {
  if (!isPlainObject(body)) {
    return { ok: false, error: 'Expected JSON object', status: 400 };
  }
  const code = body.code == null ? '' : String(body.code).trim();
  if (!code) {
    return { ok: false, error: 'code is required', status: 400 };
  }
  if (code.length > CODE_MAX) {
    return { ok: false, error: `code must be at most ${CODE_MAX} characters`, status: 400 };
  }
  if (!CODE_PATTERN.test(code)) {
    return {
      ok: false,
      error: 'code must start with a letter or digit and use only letters, digits, ".", "_" or "-"',
      status: 400,
    };
  }
  const coords = validateCoordinates(body.coordinates);
  if (!coords.ok) {
    return { ok: false, error: coords.error, status: 400 };
  }
  const span = { code, coordinates: coords.coordinates };
  for (const [field, max] of [
    ['description', DESCRIPTION_MAX],
    ['utility_domain', UTILITY_DOMAIN_MAX],
  ]) {
    const err = validateOptionalText(body, field, max, span);
    if (err) return { ok: false, error: err, status: 400 };
  }
  for (const field of ['equipment_from_id', 'equipment_to_id']) {
    const err = validateOptionalEquipmentId(body, field, span);
    if (err) return { ok: false, error: err, status: 400 };
  }
  if (Object.prototype.hasOwnProperty.call(body, 'metadata')) {
    if (!isPlainObject(body.metadata)) {
      return { ok: false, error: 'metadata must be a JSON object', status: 400 };
    }
    span.metadata = body.metadata;
  }
  return { ok: true, span };
}

/**
 * Valida corpo de atualização parcial (PATCH /api/topology/spans/:id).
 * Campos permitidos: description, utility_domain, equipment_from_id,
 * equipment_to_id, coordinates (retraça a geometria), metadata.
 * `code` é imutável (identidade externa do segmento).
 * @returns {{ ok: true, updates: Record<string, unknown> } | { ok: false, error: string, status: number }}
 */
function validateSpanPatch(body) {
  if (!isPlainObject(body)) {
    return { ok: false, error: 'Expected JSON object', status: 400 };
  }
  if (Object.prototype.hasOwnProperty.call(body, 'code')) {
    return { ok: false, error: 'code is immutable; create a new span instead', status: 400 };
  }
  const updates = {};
  for (const [field, max] of [
    ['description', DESCRIPTION_MAX],
    ['utility_domain', UTILITY_DOMAIN_MAX],
  ]) {
    const err = validateOptionalText(body, field, max, updates);
    if (err) return { ok: false, error: err, status: 400 };
  }
  for (const field of ['equipment_from_id', 'equipment_to_id']) {
    const err = validateOptionalEquipmentId(body, field, updates);
    if (err) return { ok: false, error: err, status: 400 };
  }
  if (Object.prototype.hasOwnProperty.call(body, 'coordinates')) {
    const coords = validateCoordinates(body.coordinates);
    if (!coords.ok) {
      return { ok: false, error: coords.error, status: 400 };
    }
    updates.coordinates = coords.coordinates;
  }
  if (Object.prototype.hasOwnProperty.call(body, 'metadata')) {
    if (!isPlainObject(body.metadata)) {
      return { ok: false, error: 'metadata must be a JSON object', status: 400 };
    }
    updates.metadata = body.metadata;
  }
  if (Object.keys(updates).length === 0) {
    return {
      ok: false,
      error:
        'No updatable fields: description, utility_domain, equipment_from_id, equipment_to_id, coordinates, metadata',
      status: 400,
    };
  }
  return { ok: true, updates };
}

/** Constrói o GeoJSON LineString (string) a partir de vértices já validados. */
function lineStringGeoJson(coordinates) {
  return JSON.stringify({ type: 'LineString', coordinates });
}

module.exports = {
  validateSpanCreate,
  validateSpanPatch,
  validateCoordinates,
  lineStringGeoJson,
  CODE_MAX,
  MIN_VERTICES,
  MAX_VERTICES,
};
