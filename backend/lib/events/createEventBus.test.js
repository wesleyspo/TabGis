'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { createEventBus } = require('./createEventBus');

test('emit invoca todos os sinks', async () => {
  const seen = [];
  const bus = createEventBus({
    sinks: [
      async (e) => {
        seen.push(`a:${e.eventType}`);
      },
      async (e) => {
        seen.push(`b:${e.domain}`);
      },
    ],
  });
  await bus.emit({ domain: 'system', eventType: 'test.ping', payload: { x: 1 } });
  assert.deepStrictEqual(seen, ['a:test.ping', 'b:system']);
});

test('sink com erro não impede os seguintes', async () => {
  const seen = [];
  const bus = createEventBus({
    sinks: [
      async () => {
        throw new Error('boom');
      },
      async () => {
        seen.push('ok');
      },
    ],
  });
  await bus.emit({ domain: 'system', eventType: 'test.isolated' });
  assert.deepStrictEqual(seen, ['ok']);
});
