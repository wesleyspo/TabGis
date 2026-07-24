'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { generateSpanCode, SPAN_CODE_AUTO_PATTERN } = require('./generateSpanCode');

test('generateSpanCode produz formato SEG_YYYYMMDD_HHMMSSmmm', () => {
  const d = new Date(2026, 6, 24, 16, 30, 45, 12); // Julho = mês 6 (0-based)
  const code = generateSpanCode(d);
  assert.equal(code, 'SEG_20260724_163045012');
  assert.match(code, SPAN_CODE_AUTO_PATTERN);
});

test('generateSpanCode com Date actual passa no padrão E2E', () => {
  assert.match(generateSpanCode(), SPAN_CODE_AUTO_PATTERN);
});

test('generateSpanCode padrea milissegundos a 3 dígitos', () => {
  const d = new Date(2026, 0, 1, 0, 0, 0, 7);
  assert.equal(generateSpanCode(d), 'SEG_20260101_000000007');
});
