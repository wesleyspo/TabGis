'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { normalizeGeocodeQuery, geocodeQueryTooShort, DEFAULT_MIN } = require('./geocodeQuery');

test('normalização de entrada', () => {
  assert.strictEqual(normalizeGeocodeQuery('  abc  '), 'abc');
  assert.strictEqual(normalizeGeocodeQuery(null), '');
});

test('comprimento mínimo', () => {
  assert.strictEqual(DEFAULT_MIN, 3);
  assert.strictEqual(geocodeQueryTooShort('ab'), true);
  assert.strictEqual(geocodeQueryTooShort('abc'), false);
});
