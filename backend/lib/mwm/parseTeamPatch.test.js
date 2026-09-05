'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { parseTeamPatch } = require('./parseTeamPatch');

describe('parseTeamPatch', () => {
  it('aceita lat/lng e status', () => {
    const r = parseTeamPatch({
      last_known_lat: -23.55,
      last_known_lng: -46.63,
      status: 'active',
    });
    assert.equal(r.ok, true);
    assert.equal(r.updates.last_known_lat, -23.55);
    assert.equal(r.updates.status, 'active');
  });

  it('rejeita lat fora de range', () => {
    const r = parseTeamPatch({ last_known_lat: 100 });
    assert.equal(r.ok, false);
  });

  it('rejeita status inválido', () => {
    const r = parseTeamPatch({ status: 'dead' });
    assert.equal(r.ok, false);
  });
});
