'use strict';

/**
 * Domínios canónicos (prefixo mental para event_type e para exportação Mongo).
 * @readonly
 */
const DOMAINS = Object.freeze([
  'oms',
  'mwm',
  'dms',
  'ind',
  'smt',
  'tmp',
  'aud',
  'security',
  'ref',
  'gis',
  'config',
  'landbase',
  'system',
]);

function normalizeDomain(d) {
  return String(d || '')
    .trim()
    .toLowerCase();
}

function isValidDomain(d) {
  return DOMAINS.includes(normalizeDomain(d));
}

/** Convenção: domínio.entidade.acção (ex.: oms.work_order.updated). */
function assertDomainOrThrow(domain) {
  const n = normalizeDomain(domain);
  if (!isValidDomain(n)) {
    throw new Error(`events: domínio inválido "${domain}"`);
  }
  return n;
}

module.exports = {
  DOMAINS,
  normalizeDomain,
  isValidDomain,
  assertDomainOrThrow,
};
