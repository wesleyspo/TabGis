'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { parseTeamRoutesQuery, parseDisplacementsQuery } = require('./parseTeamRoutesQuery');

test('parseTeamRoutesQuery defaults hours=48 e teamId null', () => {
  const r = parseTeamRoutesQuery({});
  assert.equal(r.ok, true);
  assert.equal(r.hours, 48);
  assert.equal(r.teamId, null);
});

test('parseTeamRoutesQuery aceita hours e team_id válidos', () => {
  const r = parseTeamRoutesQuery({ hours: '24', team_id: '3' });
  assert.equal(r.ok, true);
  assert.equal(r.hours, 24);
  assert.equal(r.teamId, 3);
});

test('parseTeamRoutesQuery rejeita hours fora de 1..168', () => {
  assert.equal(parseTeamRoutesQuery({ hours: 0 }).ok, false);
  assert.equal(parseTeamRoutesQuery({ hours: 169 }).ok, false);
  assert.equal(parseTeamRoutesQuery({ hours: 12.5 }).ok, false);
});

test('parseTeamRoutesQuery rejeita team_id inválido', () => {
  assert.equal(parseTeamRoutesQuery({ team_id: 'abc' }).ok, false);
  assert.equal(parseTeamRoutesQuery({ team_id: 0 }).ok, false);
});

test('parseDisplacementsQuery limita e filtra', () => {
  const r = parseDisplacementsQuery({ team_id: 2, limit: '9999' });
  assert.equal(r.ok, true);
  assert.equal(r.teamId, 2);
  assert.equal(r.limit, 500);
});

test('parseDisplacementsQuery rejeita work_order_id inválido', () => {
  assert.equal(parseDisplacementsQuery({ work_order_id: -1 }).ok, false);
});
