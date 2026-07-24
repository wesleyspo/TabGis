'use strict';

/**
 * Documento próximo de coleção Mongo (`event_report`): chave idempotente `_id` = event_uuid.
 * @param {Record<string, unknown>} row — linha de events.event (camelCase columns vindos do pg são lowercase keys)
 */
function eventRowToMongoShape(row) {
  return {
    _id: row.event_uuid,
    insertedAt: row.recorded_at,
    occurredAt: row.occurred_at,
    schemaVersion: row.schema_version,
    domain: row.domain,
    type: row.event_type,
    aggregateType: row.aggregate_type,
    aggregateId: row.aggregate_id,
    correlationId: row.correlation_id,
    causationId: row.causation_id,
    actorType: row.actor_type,
    actorId: row.actor_id,
    source: row.source,
    body: row.payload,
    metadata: row.metadata,
  };
}

module.exports = { eventRowToMongoShape };
