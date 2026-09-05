'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { parseDisplacementPatch } = require('./parseDisplacementPatch');

describe('parseDisplacementPatch', () => {
  it('rejeita corpo vazio', () => {
    const r = parseDisplacementPatch(null);
    assert.equal(r.ok, false);
    assert.equal(r.status, 400);
  });

  it('aceita notes e horários ISO', () => {
    const r = parseDisplacementPatch({
      notes: 'Chegada à obra',
      planned_departure_at: '2026-09-05T10:00:00.000Z',
    });
    assert.equal(r.ok, true);
    assert.equal(r.updates.notes, 'Chegada à obra');
    assert.equal(r.updates.planned_departure_at, '2026-09-05T10:00:00.000Z');
  });

  it('aceita limpeza de campos para null', () => {
    const r = parseDisplacementPatch({ actual_arrival_at: null });
    assert.equal(r.ok, true);
    assert.equal(r.updates.actual_arrival_at, null);
  });

  it('rejeita notes não-string', () => {
    const r = parseDisplacementPatch({ notes: 1 });
    assert.equal(r.ok, false);
  });

  it('rejeita timestamp inválido', () => {
    const r = parseDisplacementPatch({ planned_departure_at: 'not-a-date' });
    assert.equal(r.ok, false);
    assert.match(r.error, /ISO-8601/);
  });
});
