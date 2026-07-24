'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  validateSpanCreate,
  validateSpanPatch,
  validateCoordinates,
  lineStringGeoJson,
} = require('./validateSpanWrite');

const VALID_COORDS = [
  [-46.6333, -23.5505],
  [-46.636, -23.5512],
];

test('validateSpanCreate aceita corpo mínimo válido', () => {
  const r = validateSpanCreate({ code: 'SEG_A1', coordinates: VALID_COORDS });
  assert.equal(r.ok, true);
  assert.equal(r.span.code, 'SEG_A1');
  assert.deepEqual(r.span.coordinates, VALID_COORDS);
});

test('validateSpanCreate normaliza opcionais e aceita metadata objeto', () => {
  const r = validateSpanCreate({
    code: 'SEG-B.2',
    coordinates: VALID_COORDS,
    description: '  Alimentador norte  ',
    utility_domain: 'electric',
    equipment_from_id: '7',
    equipment_to_id: null,
    metadata: { phase: 'ABC' },
  });
  assert.equal(r.ok, true);
  assert.equal(r.span.description, 'Alimentador norte');
  assert.equal(r.span.utility_domain, 'electric');
  assert.equal(r.span.equipment_from_id, 7);
  assert.equal(r.span.equipment_to_id, null);
  assert.deepEqual(r.span.metadata, { phase: 'ABC' });
});

test('validateSpanCreate permite omitir code (codeAuto) e rejeita code inválido', () => {
  const auto = validateSpanCreate({ coordinates: VALID_COORDS });
  assert.equal(auto.ok, true);
  assert.equal(auto.span.code, null);
  assert.equal(auto.span.codeAuto, true);
  assert.equal(
    validateSpanCreate({ code: 'x'.repeat(97), coordinates: VALID_COORDS }).ok,
    false
  );
  assert.equal(validateSpanCreate({ code: 'SEG A1', coordinates: VALID_COORDS }).ok, false);
  assert.equal(validateSpanCreate({ code: '-SEG', coordinates: VALID_COORDS }).ok, false);
});

test('validateSpanCreate rejeita coordenadas inválidas', () => {
  assert.equal(validateSpanCreate({ code: 'S1', coordinates: [[-46.6, -23.5]] }).ok, false);
  assert.equal(
    validateSpanCreate({ code: 'S1', coordinates: [[-46.6, -23.5], [-200, -23.5]] }).ok,
    false
  );
  assert.equal(
    validateSpanCreate({ code: 'S1', coordinates: [[-46.6, -23.5], [-46.6, -95]] }).ok,
    false
  );
  const dup = validateSpanCreate({
    code: 'S1',
    coordinates: [[-46.6, -23.5], [-46.6, -23.5]],
  });
  assert.equal(dup.ok, false);
  assert.match(dup.error, /repeats/);
});

test('validateSpanCreate rejeita metadata não-objeto e corpo não-objeto', () => {
  assert.equal(
    validateSpanCreate({ code: 'S1', coordinates: VALID_COORDS, metadata: [1] }).ok,
    false
  );
  assert.equal(validateSpanCreate(null).ok, false);
  assert.equal(validateSpanCreate([]).ok, false);
});

test('validateSpanPatch exige pelo menos um campo e recusa code', () => {
  const empty = validateSpanPatch({});
  assert.equal(empty.ok, false);
  assert.equal(empty.status, 400);
  const withCode = validateSpanPatch({ code: 'NOVO' });
  assert.equal(withCode.ok, false);
  assert.match(withCode.error, /immutable/);
});

test('validateSpanPatch aceita limpeza com null e retraçado de geometria', () => {
  const r = validateSpanPatch({
    description: null,
    equipment_from_id: '',
    coordinates: VALID_COORDS,
  });
  assert.equal(r.ok, true);
  assert.equal(r.updates.description, null);
  assert.equal(r.updates.equipment_from_id, null);
  assert.deepEqual(r.updates.coordinates, VALID_COORDS);
});

test('validateSpanPatch rejeita equipment id não inteiro positivo', () => {
  assert.equal(validateSpanPatch({ equipment_from_id: 0 }).ok, false);
  assert.equal(validateSpanPatch({ equipment_to_id: 1.5 }).ok, false);
  assert.equal(validateSpanPatch({ equipment_to_id: 'abc' }).ok, false);
});

test('validateCoordinates devolve pares numéricos normalizados', () => {
  const r = validateCoordinates([
    ['-46.6333', '-23.5505'],
    [-46.636, -23.5512],
  ]);
  assert.equal(r.ok, true);
  assert.deepEqual(r.coordinates[0], [-46.6333, -23.5505]);
});

test('lineStringGeoJson produz GeoJSON válido', () => {
  const parsed = JSON.parse(lineStringGeoJson(VALID_COORDS));
  assert.equal(parsed.type, 'LineString');
  assert.deepEqual(parsed.coordinates, VALID_COORDS);
});
