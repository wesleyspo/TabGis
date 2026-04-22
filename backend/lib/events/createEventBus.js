'use strict';

const { createPgSink } = require('./createPgSink');

/**
 * Barramento plugável: vários sinks (Postgres, stdout, fila, Mongo futuro).
 * Nenhum sink deve rebentar o fluxo HTTP — erros são isolados por sink.
 */
function createEventBus({ sinks = [] } = {}) {
  if (!Array.isArray(sinks)) {
    throw new Error('events: sinks deve ser array');
  }

  async function emit(envelope) {
    if (!envelope || typeof envelope !== 'object') {
      return;
    }
    for (let i = 0; i < sinks.length; i += 1) {
      try {
        await sinks[i](envelope);
      } catch (err) {
        console.error(`[events] sink #${i} falhou:`, err && err.message ? err.message : err);
      }
    }
  }

  return { emit, sinks };
}

/** Fábrica por ambiente: EVENTS_DISABLED=1 → no-op; caso contrário sink Postgres. */
function createDefaultEventBus(pool) {
  if (process.env.EVENTS_DISABLED === '1' || process.env.EVENTS_DISABLED === 'true') {
    return createEventBus({ sinks: [] });
  }
  return createEventBus({ sinks: [createPgSink(pool)] });
}

module.exports = {
  createEventBus,
  createDefaultEventBus,
  createPgSink,
};
