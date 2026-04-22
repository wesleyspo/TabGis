'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { isValidDomain, normalizeDomain, assertDomainOrThrow } = require('./constants');

test('domínios normalizados', () => {
  assert.strictEqual(normalizeDomain(' OMS '), 'oms');
  assert.strictEqual(isValidDomain('oms'), true);
  assert.strictEqual(isValidDomain('desconhecido'), false);
});

test('assertDomainOrThrow', () => {
  assert.strictEqual(assertDomainOrThrow('SYSTEM'), 'system');
  assert.throws(() => assertDomainOrThrow('zzz'), /inválido/);
});
