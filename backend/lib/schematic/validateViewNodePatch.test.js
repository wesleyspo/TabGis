'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { validateViewNodePatch } = require('./validateViewNodePatch');

test('rejeita corpo inválido', () => {
  const r1 = validateViewNodePatch(null);
  assert.equal(r1.ok, false);
  const r2 = validateViewNodePatch({ focus_lat: 1 });
  assert.equal(r2.ok, false);
  assert.match(String(r2.error), /focus_lat and focus_lng/);
});

test('aceita label só', () => {
  const r = validateViewNodePatch({ label: '  X  ' });
  assert.equal(r.ok, true);
  assert.equal(r.updates.label, 'X');
});

test('aceita par de foco', () => {
  const r = validateViewNodePatch({ focus_lat: -23.5, focus_lng: -46.6 });
  assert.equal(r.ok, true);
  assert.equal(r.updates.focus_lat, -23.5);
  assert.equal(r.updates.focus_lng, -46.6);
});

test('limpa foco com null em ambos', () => {
  const r = validateViewNodePatch({ focus_lat: null, focus_lng: null });
  assert.equal(r.ok, true);
  assert.equal(r.updates.focus_lat, null);
  assert.equal(r.updates.focus_lng, null);
});

test('rejeita label longa', () => {
  const r = validateViewNodePatch({ label: 'x'.repeat(201) });
  assert.equal(r.ok, false);
});
