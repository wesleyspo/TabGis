'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { eventRowToMongoShape } = require('./eventRowToMongoShape');

test('eventRowToMongoShape maps pg row to mongo-like document', () => {
  const row = {
    id: 1,
    event_uuid: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    occurred_at: new Date('2026-01-01T12:00:00.000Z'),
    recorded_at: new Date('2026-01-01T12:00:01.000Z'),
    schema_version: 1,
    domain: 'oms',
    event_type: 'oms.work_order.updated',
    aggregate_type: 'operations.work_order',
    aggregate_id: '42',
    correlation_id: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
    causation_id: null,
    actor_type: 'api',
    actor_id: null,
    source: 'tabgis-api',
    payload: { x: 1 },
    metadata: { http_method: 'PATCH' },
  };
  const doc = eventRowToMongoShape(row);
  assert.equal(doc._id, row.event_uuid);
  assert.equal(doc.type, 'oms.work_order.updated');
  assert.deepEqual(doc.body, { x: 1 });
  assert.equal(doc.insertedAt, row.recorded_at);
});
