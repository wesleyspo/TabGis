'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { formatLocalStreetDisplayName } = require('./localGeocodeFormat');

test('rótulo com município e highway', () => {
  const o = formatLocalStreetDisplayName({
    name: 'Rua X',
    municipio_nome: 'São Paulo',
    highway: 'residential',
    lat: -23,
    lon: -46,
  });
  assert.strictEqual(o.display_name, 'Rua X — São Paulo (residential)');
  assert.strictEqual(o.source, 'local');
});

test('rótulo só com nome', () => {
  const o = formatLocalStreetDisplayName({
    name: 'Rua Y',
    municipio_nome: null,
    highway: null,
    lat: 1,
    lon: 2,
  });
  assert.strictEqual(o.display_name, 'Rua Y');
});
