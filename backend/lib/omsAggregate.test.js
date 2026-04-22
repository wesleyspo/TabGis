'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { omsAggregateCellMetersFromZoom } = require('./omsAggregate');

test('zoom inválido devolve grelha por defeito', () => {
  assert.strictEqual(omsAggregateCellMetersFromZoom(''), 5500);
  assert.strictEqual(omsAggregateCellMetersFromZoom(null), 5500);
  assert.strictEqual(omsAggregateCellMetersFromZoom(undefined), 5500);
  assert.strictEqual(omsAggregateCellMetersFromZoom('x'), 5500);
});

test('escadas de zoom monótonas', () => {
  assert.strictEqual(omsAggregateCellMetersFromZoom(8), 12000);
  assert.strictEqual(omsAggregateCellMetersFromZoom(9), 8000);
  assert.strictEqual(omsAggregateCellMetersFromZoom(10), 5500);
  assert.strictEqual(omsAggregateCellMetersFromZoom(11), 3500);
  assert.strictEqual(omsAggregateCellMetersFromZoom(12), 1800);
  assert.strictEqual(omsAggregateCellMetersFromZoom(13), 900);
  assert.strictEqual(omsAggregateCellMetersFromZoom(22), 900);
});
