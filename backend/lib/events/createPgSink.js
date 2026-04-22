'use strict';

const { assertDomainOrThrow } = require('./constants');

/**
 * Sink que persiste em events.event via events.append_event (Postgres).
 * Compatível com replicação futura: cada linha mapeia 1:1 para documento { event_uuid, ... }.
 */
function createPgSink(pool) {
  if (!pool || typeof pool.query !== 'function') {
    throw new Error('events: createPgSink requer pool pg');
  }

  return async function pgSink(envelope) {
    const domain = assertDomainOrThrow(envelope.domain);
    const eventType = String(envelope.eventType || '').trim();
    if (!eventType) {
      throw new Error('events: eventType obrigatório');
    }
    const payload = envelope.payload != null ? envelope.payload : {};
    const metadata = envelope.metadata != null ? envelope.metadata : {};
    await pool.query(
      `SELECT events.append_event(
        $1::text,
        $2::text,
        $3::jsonb,
        $4::text,
        $5::text,
        $6::uuid,
        $7::uuid,
        $8::text,
        $9::text,
        $10::text,
        $11::jsonb
      )`,
      [
        domain,
        eventType,
        payload,
        envelope.aggregateType != null ? String(envelope.aggregateType) : null,
        envelope.aggregateId != null ? String(envelope.aggregateId) : null,
        envelope.correlationId || null,
        envelope.causationId || null,
        envelope.actorType != null ? String(envelope.actorType) : 'api',
        envelope.actorId != null ? String(envelope.actorId) : null,
        envelope.source != null ? String(envelope.source) : 'tabgis-api',
        metadata,
      ]
    );
  };
}

module.exports = { createPgSink };
