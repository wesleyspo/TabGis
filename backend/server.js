const express = require('express');
const cors = require('cors');
const https = require('https');
const { randomUUID } = require('crypto');
const { Pool } = require('pg');
const { omsAggregateCellMetersFromZoom } = require('./lib/omsAggregate');
const { geocodeQueryTooShort } = require('./lib/geocodeQuery');
const { formatLocalStreetDisplayName } = require('./lib/localGeocodeFormat');
const { createDefaultEventBus } = require('./lib/events/createEventBus');

/** Obrigatório pela política de uso do Nominatim (https://operations.osmfoundation.org/policies/nominatim/). */
const NOMINATIM_USER_AGENT =
  process.env.NOMINATIM_USER_AGENT ||
  'TabGis/1.0 (utility mapping; https://github.com/wesleyspo/TabGis)';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use((req, _res, next) => {
  req.correlationId = req.get('x-correlation-id') || randomUUID();
  next();
});

const pool = new Pool({
  host: process.env.DB_HOST || 'db',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'tabgis_db',
  user: process.env.DB_USER || 'tabgis_admin',
  password: process.env.DB_PASSWORD || 'password123',
});

const eventBus = createDefaultEventBus(pool);

/** Emite evento no barramento plugável (sinks nunca rebentam a resposta HTTP). */
async function emitWithRequest(req, envelope) {
  const meta = {
    ...(envelope.metadata || {}),
    correlation_id: req.correlationId,
    http_method: req.method,
    http_path: req.originalUrl || req.url || '',
  };
  await eventBus.emit({
    ...envelope,
    correlationId: envelope.correlationId || req.correlationId,
    metadata: meta,
  });
}

/**
 * Geocodificação por texto (endereço / lugar) via Nominatim (OpenStreetMap).
 * GET /api/geocode?q=... — resultados limitados ao Brasil, com viewbox na RMSP.
 * Requer Internet no servidor API.
 */
app.get('/api/geocode', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (geocodeQueryTooShort(q)) {
    return res.status(400).json({ error: 'Query too short', results: [] });
  }

  const url = new URL('https://nominatim.openstreetmap.org/search');
  url.searchParams.set('format', 'json');
  url.searchParams.set('q', q);
  url.searchParams.set('limit', '10');
  url.searchParams.set('addressdetails', '1');
  url.searchParams.set('accept-language', 'pt-BR,pt,en');
  url.searchParams.set('countrycodes', 'br');
  url.searchParams.set('bounded', '1');
  url.searchParams.set('viewbox', '-47.2,-24.08,-45.45,-23.18');

  try {
    const body = await new Promise((resolve, reject) => {
      const reqN = https.get(
        url,
        {
          headers: {
            'User-Agent': NOMINATIM_USER_AGENT,
            Accept: 'application/json',
          },
        },
        (r) => {
          let d = '';
          r.on('data', (c) => {
            d += c;
          });
          r.on('end', () => resolve(d));
        }
      );
      reqN.on('error', reject);
      reqN.setTimeout(15000, () => {
        reqN.destroy();
        reject(new Error('Geocode request timeout'));
      });
    });

    const parsed = JSON.parse(body);
    if (!Array.isArray(parsed)) {
      return res.status(502).json({ error: 'Unexpected geocoder response', results: [] });
    }

    const results = parsed.map((item) => ({
      lat: parseFloat(item.lat),
      lon: parseFloat(item.lon),
      display_name: item.display_name,
      type: item.type,
      class: item.class,
    }));

    res.json({ results });
  } catch (error) {
    console.error('GET /api/geocode', error);
    res.status(502).json({ error: 'Geocoding failed', results: [] });
  }
});

/**
 * Geocodificação local: nomes de vias em landbase.vias_alvo_sp (recorte municípios-alvo).
 * Sem Internet; não resolve número de porta nem CEP — substring no nome OSM
 * com normalização sem acentos (extensão `unaccent`; ver infra/sql/12_unaccent_geocode_local.sql).
 * GET /api/geocode-local?q=...
 */
app.get('/api/geocode-local', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (geocodeQueryTooShort(q)) {
    return res.status(400).json({ error: 'Query too short', results: [] });
  }

  try {
    const { rows } = await pool.query(
      `SELECT DISTINCT ON (unaccent(lower(btrim(v.name)))), COALESCE(v.municipio_nome, ''))
         v.name,
         v.highway,
         v.municipio_nome,
         ST_Y(ST_Transform(ST_LineInterpolatePoint(v.geom, 0.5), 4326))::double precision AS lat,
         ST_X(ST_Transform(ST_LineInterpolatePoint(v.geom, 0.5), 4326))::double precision AS lon
       FROM landbase.vias_alvo_sp v
       WHERE v.name IS NOT NULL
         AND btrim(v.name) <> ''
         AND strpos(unaccent(lower(v.name)), unaccent(lower($1::text))) > 0
       ORDER BY unaccent(lower(btrim(v.name))),
                COALESCE(v.municipio_nome, ''),
                ST_Length(v.geom::geography) DESC
       LIMIT 15`,
      [q]
    );

    const results = rows.map((r) =>
      formatLocalStreetDisplayName({
        name: r.name,
        municipio_nome: r.municipio_nome,
        highway: r.highway,
        lat: r.lat,
        lon: r.lon,
      })
    );

    res.json({ results });
  } catch (error) {
    console.error('GET /api/geocode-local', error);
    res.status(500).json({ error: 'Local geocoding failed', results: [] });
  }
});

app.get('/api/translations/:lang', async (req, res) => {
  try {
    const { lang } = req.params;

    const query = `
      SELECT t.object_id, t.translated_text
      FROM config.translation t
      JOIN config.language l ON t.language_id = l.id
      WHERE l.code = $1
    `;

    const result = await pool.query(query, [lang]);

    const translations = {};
    result.rows.forEach((row) => {
      translations[row.object_id] = row.translated_text;
    });

    res.json(translations);
  } catch (error) {
    console.error('Error fetching translations:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** Utilizadores (security.users) */
app.get('/api/users', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, username, email, first_name, last_name, access_type, status, created_at
       FROM security.users
       ORDER BY username`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/users', error);
    res.status(500).json({ error: 'Failed to list users' });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { username, email, first_name, last_name, access_type } = req.body || {};
    if (!username || String(username).trim() === '') {
      return res.status(400).json({ error: 'username is required' });
    }
    const { rows } = await pool.query(
      `INSERT INTO security.users (username, email, first_name, last_name, access_type)
       VALUES ($1, $2, $3, $4, COALESCE($5, 'CONSULTA'))
       RETURNING id, username, email, first_name, last_name, access_type, status, created_at`,
      [String(username).trim(), email || null, first_name || null, last_name || null, access_type || null]
    );
    const created = rows[0];
    await emitWithRequest(req, {
      domain: 'security',
      eventType: 'security.user.created',
      aggregateType: 'security.user',
      aggregateId: String(created.id),
      payload: {
        username: created.username,
        access_type: created.access_type,
      },
      actorType: 'api',
    });
    res.status(201).json(created);
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({ error: 'Username already exists' });
    }
    console.error('POST /api/users', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

/** Ordens — operations.work_order + equipa, responsável e bloqueio (eventos excluídos da lista OMS) */
app.get('/api/work-orders', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT wo.id, wo.order_code, wo.category, wo.order_type, wo.summary, wo.description, wo.status, wo.priority,
              wo.organization_label, wo.municipality_name, wo.neighborhood_name,
              wo.equipment_code, wo.feeder_code, wo.affected_customers_count, wo.complaints_linked_count,
              wo.flag_safety_risk, wo.flag_critical_infra, wo.flag_customer_callback, wo.callback_auto,
              wo.priority_score, wo.focus_lat, wo.focus_lng,
              wo.started_at, wo.created_at,
              COALESCE(wo.started_at, wo.created_at) AS start_time,
              ROUND((EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - COALESCE(wo.started_at, wo.created_at))) / 3600.0)::numeric, 1) AS hours_open,
              wo.owner_id, wo.locked_by_id, wo.updated_at,
              wo.assigned_team_id, t.team_code, t.name AS team_name,
              ou.username AS owner_username,
              lu.username AS locked_by_username
       FROM operations.work_order wo
       LEFT JOIN operations.team t ON t.id = wo.assigned_team_id
       LEFT JOIN security.users ou ON ou.id = wo.owner_id
       LEFT JOIN security.users lu ON lu.id = wo.locked_by_id
       WHERE COALESCE(wo.order_type, '') <> 'event'
         AND COALESCE(wo.category, '') <> 'event'
       ORDER BY wo.updated_at DESC NULLS LAST, wo.id DESC`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/work-orders', error);
    res.status(500).json({ error: 'Failed to list work orders' });
  }
});

/**
 * Agregação de ordens OMS para o mapa.
 * - Com zoom= (Leaflet): agrupamento espacial por grelha métrica (PostGIS ST_SnapToGrid), ordens próximas no mesmo marcador.
 * - Legado: group=municipio | bairro (vistas por nome administrativo).
 */
app.get('/api/oms/work-orders/aggregate', async (req, res) => {
  try {
    const zoomRaw = req.query.zoom;
    if (zoomRaw !== undefined && String(zoomRaw).trim() !== '') {
      const cellM = omsAggregateCellMetersFromZoom(zoomRaw);
      const { rows } = await pool.query(
        `SELECT cluster_id, orders_count, center_lat, center_lng,
                first_started_at, last_updated_at, area_hint
         FROM operations.fn_oms_orders_spatial_clusters($1::double precision, 1)
         ORDER BY orders_count DESC, cluster_id`,
        [cellM]
      );
      return res.json(rows);
    }

    const group = String(req.query.group || 'municipio').toLowerCase();
    let sql;
    if (group === 'bairro') {
      sql = `SELECT municipality_name, neighborhood_name, orders_count,
                    first_started_at, last_updated_at, center_lat, center_lng
             FROM operations.v_oms_orders_agg_bairro
             ORDER BY municipality_name, neighborhood_name`;
    } else {
      sql = `SELECT municipality_name, orders_count,
                    first_started_at, last_updated_at, center_lat, center_lng
             FROM operations.v_oms_orders_agg_municipio
             ORDER BY municipality_name`;
    }
    const { rows } = await pool.query(sql);
    res.json(rows);
  } catch (error) {
    console.error('GET /api/oms/work-orders/aggregate', error);
    res.status(500).json({ error: 'Failed to aggregate work orders' });
  }
});

/**
 * Rotas de campo de demonstração (mwm.demo_field_*) — equipas com CARRINHO / CARRO / MOTO.
 */
app.get('/api/mwm/demo-routes', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT r.id AS route_id, r.route_date::text AS route_date, r.label,
              c.id AS crew_id, c.crew_code, c.name AS crew_name, c.vehicle_type,
              COALESCE(
                (SELECT json_agg(
                   json_build_object(
                     'seq', p.seq_no,
                     'lat', ST_Y(p.geom),
                     'lng', ST_X(p.geom),
                     't', p.recorded_at
                   )
                   ORDER BY p.seq_no
                 )
                 FROM mwm.demo_field_route_point p
                 WHERE p.route_id = r.id),
                '[]'::json
              ) AS points
       FROM mwm.demo_field_route r
       JOIN mwm.demo_field_crew c ON c.id = r.crew_id
       WHERE r.route_date >= (CURRENT_DATE - INTERVAL '1 day')
       ORDER BY c.crew_code, r.route_date DESC, r.id`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/mwm/demo-routes', error);
    res.status(500).json({ error: 'Failed to load demo field routes' });
  }
});

/** Folha da ordem: cabeçalho + tarefas + reclamações (evento não exposto neste módulo) */
app.get('/api/work-orders/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const orderRes = await pool.query(
      `SELECT wo.*, t.team_code, t.name AS team_name,
              ou.username AS owner_username, lu.username AS locked_by_username
       FROM operations.work_order wo
       LEFT JOIN operations.team t ON t.id = wo.assigned_team_id
       LEFT JOIN security.users ou ON ou.id = wo.owner_id
       LEFT JOIN security.users lu ON lu.id = wo.locked_by_id
       WHERE wo.id = $1`,
      [id]
    );
    if (orderRes.rows.length === 0) {
      return res.status(404).json({ error: 'Work order not found' });
    }
    const order = orderRes.rows[0];
    if (order.order_type === 'event' || order.category === 'event') {
      return res.status(404).json({ error: 'Work order not available in OMS' });
    }
    const tasks = await pool.query(
      `SELECT id, work_order_id, sequence_no, summary, status, notes, created_at, updated_at
       FROM operations.work_order_task WHERE work_order_id = $1 ORDER BY sequence_no ASC, id ASC`,
      [id]
    );
    const complaints = await pool.query(
      `SELECT id, work_order_id, complaint_ref, channel, caller_name, contact_phone, status, summary, received_at
       FROM operations.work_order_complaint WHERE work_order_id = $1 ORDER BY received_at DESC NULLS LAST, id DESC`,
      [id]
    );
    res.json({
      order,
      tasks: tasks.rows,
      complaints: complaints.rows,
    });
  } catch (error) {
    console.error('GET /api/work-orders/:id', error);
    res.status(500).json({ error: 'Failed to load work order' });
  }
});

app.patch('/api/work-orders/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const b = req.body || {};
    const {
      owner_id,
      locked_by_id,
      status,
      priority,
      summary,
      description,
      assigned_team_id,
      order_type,
      organization_label,
      municipality_name,
      neighborhood_name,
      equipment_code,
      feeder_code,
      affected_customers_count,
      flag_safety_risk,
      flag_critical_infra,
      flag_customer_callback,
      priority_score,
      focus_lat,
      focus_lng,
    } = b;

    const fields = [];
    const values = [];
    let n = 1;

    const push = (col, val) => {
      fields.push(`${col} = $${n++}`);
      values.push(val);
    };

    if (owner_id !== undefined) push('owner_id', owner_id);
    if (locked_by_id !== undefined) push('locked_by_id', locked_by_id);
    if (status !== undefined) push('status', status);
    if (priority !== undefined) push('priority', priority);
    if (summary !== undefined) push('summary', summary);
    if (description !== undefined) push('description', description);
    if (assigned_team_id !== undefined) push('assigned_team_id', assigned_team_id);
    if (order_type !== undefined) {
      const ot = String(order_type).toLowerCase();
      if (ot === 'event') {
        return res.status(400).json({ error: 'order_type event is not editable via OMS' });
      }
      push('order_type', order_type);
    }
    if (organization_label !== undefined) push('organization_label', organization_label);
    if (municipality_name !== undefined) push('municipality_name', municipality_name);
    if (neighborhood_name !== undefined) push('neighborhood_name', neighborhood_name);
    if (equipment_code !== undefined) push('equipment_code', equipment_code);
    if (feeder_code !== undefined) push('feeder_code', feeder_code);
    if (affected_customers_count !== undefined) push('affected_customers_count', affected_customers_count);
    if (flag_safety_risk !== undefined) push('flag_safety_risk', !!flag_safety_risk);
    if (flag_critical_infra !== undefined) push('flag_critical_infra', !!flag_critical_infra);
    if (flag_customer_callback !== undefined) push('flag_customer_callback', !!flag_customer_callback);
    if (priority_score !== undefined) push('priority_score', priority_score);
    if (focus_lat !== undefined) push('focus_lat', focus_lat);
    if (focus_lng !== undefined) push('focus_lng', focus_lng);
    if (b.started_at !== undefined) push('started_at', b.started_at);
    if (b.callback_auto !== undefined) push('callback_auto', !!b.callback_auto);

    if (fields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const sql = `UPDATE operations.work_order SET ${fields.join(', ')} WHERE id = $${n} RETURNING *`;
    const { rows } = await pool.query(sql, values);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Work order not found' });
    }
    const updated = rows[0];
    const changedKeys = fields
      .filter((f) => !/^updated_at\s*=/i.test(f))
      .map((f) => String(f).split('=')[0].trim());
    await emitWithRequest(req, {
      domain: 'oms',
      eventType: 'oms.work_order.updated',
      aggregateType: 'operations.work_order',
      aggregateId: String(id),
      payload: {
        order_code: updated.order_code,
        changed: changedKeys,
      },
      actorType: 'api',
    });
    res.json(updated);
  } catch (error) {
    console.error('PATCH /api/work-orders/:id', error);
    res.status(500).json({ error: 'Failed to update work order' });
  }
});

/** Adicionar nova tarefa a uma ordem de trabalho */
app.post('/api/work-orders/:id/tasks', async (req, res) => {
  try {
    const workOrderId = parseInt(req.params.id, 10);
    if (Number.isNaN(workOrderId)) {
      return res.status(400).json({ error: 'Invalid work order ID' });
    }
    const { summary, notes, status } = req.body || {};
    if (!summary) {
      return res.status(400).json({ error: 'Task summary is required' });
    }

    const orderRes = await pool.query(
      `SELECT 1 FROM operations.work_order WHERE id = $1 AND COALESCE(order_type, '') <> 'event' AND COALESCE(category, '') <> 'event'`,
      [workOrderId]
    );
    if (orderRes.rows.length === 0) {
      return res.status(404).json({ error: 'Work order not found or is an event' });
    }

    const { rows } = await pool.query(
      `INSERT INTO operations.work_order_task (work_order_id, sequence_no, summary, notes, status)
       VALUES ($1, (SELECT COALESCE(MAX(sequence_no), 0) + 1 FROM operations.work_order_task WHERE work_order_id = $1), $2, $3, COALESCE($4, 'open'))
       RETURNING id, sequence_no, summary, status, notes, created_at, updated_at`,
      [workOrderId, summary, notes, status]
    );
    const task = rows[0];
    await emitWithRequest(req, {
      domain: 'oms',
      eventType: 'oms.work_order_task.created',
      aggregateType: 'operations.work_order_task',
      aggregateId: String(task.id),
      payload: {
        work_order_id: workOrderId,
        sequence_no: task.sequence_no,
        status: task.status,
      },
      actorType: 'api',
    });
    res.status(201).json(task);
  } catch (error) {
    console.error('POST /api/work-orders/:id/tasks', error);
    res.status(500).json({ error: 'Failed to add task' });
  }
});

/** Atualizar tarefa existente */
app.patch('/api/work-orders/:id/tasks/:task_id', async (req, res) => {
  try {
    const workOrderId = parseInt(req.params.id, 10);
    const taskId = parseInt(req.params.task_id, 10);
    if (Number.isNaN(workOrderId) || Number.isNaN(taskId)) {
      return res.status(400).json({ error: 'Invalid work order or task ID' });
    }

    const { summary, notes, status } = req.body || {};
    const fields = [];
    const values = [];
    let n = 1;

    const push = (col, val) => {
      fields.push(`${col} = $${n++}`);
      values.push(val);
    };

    if (summary !== undefined) push('summary', summary);
    if (notes !== undefined) push('notes', notes);
    if (status !== undefined) push('status', status);

    if (fields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(taskId);
    values.push(workOrderId);

    const sql = `UPDATE operations.work_order_task SET ${fields.join(', ')} WHERE id = $${n} AND work_order_id = $${n + 1} RETURNING *`;
    const { rows } = await pool.query(sql, values);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Task not found or does not belong to work order' });
    }
    const taskRow = rows[0];
    const taskChanged = fields.map((f) => String(f).split('=')[0].trim());
    await emitWithRequest(req, {
      domain: 'oms',
      eventType: 'oms.work_order_task.updated',
      aggregateType: 'operations.work_order_task',
      aggregateId: String(taskId),
      payload: {
        work_order_id: workOrderId,
        changed: taskChanged,
      },
      actorType: 'api',
    });
    res.json(taskRow);
  } catch (error) {
    console.error('PATCH /api/work-orders/:id/tasks/:task_id', error);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

/** Ordens canónicas OMS (leitura) — alinhado a docs/Database_Structure_Context.md */
app.get('/api/oms/work-orders', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT wo.id, wo.order_number, wo.status, wo.type_id, wo.priority, wo.owner_id, wo.locked_by_id,
              wo.order_created_at, wo.location_desc,
              ou.username AS owner_username, lu.username AS locked_by_username
       FROM oms.work_order wo
       LEFT JOIN security.users ou ON ou.id = wo.owner_id
       LEFT JOIN security.users lu ON lu.id = wo.locked_by_id
       ORDER BY wo.id DESC
       LIMIT 200`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/oms/work-orders', error);
    res.status(500).json({ error: 'Failed to list OMS work orders' });
  }
});

/** Equipas em campo — operations.team */
app.get('/api/teams', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT t.id, t.team_code, t.name, t.leader_name, t.skill, t.team_type, t.owner_org, t.zone,
              t.member_count, t.status, t.last_coordinate_at, t.last_updated_at,
              ST_Y(t.last_known_geom) AS lat, ST_X(t.last_known_geom) AS lng
       FROM operations.team t
       ORDER BY t.team_code`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/teams', error);
    res.status(500).json({ error: 'Failed to list teams' });
  }
});

/** Tabelas ref.* de tipos / estados usados pelo domínio GIS/OMS (leitura + edição de rótulos POC). */
const REF_DOMAIN_TYPE_TABLES = [
  'equipment_type',
  'network_type',
  'network_level',
  'connection_state',
  'work_order_type',
  'task_type',
  'call_type',
];

app.get('/api/ref/types', async (_req, res) => {
  try {
    const out = {};
    for (const t of REF_DOMAIN_TYPE_TABLES) {
      const { rows } = await pool.query(
        `SELECT id, code, label_en, label_pt FROM ref.${t} ORDER BY id`
      );
      out[t] = rows;
    }
    res.json(out);
  } catch (error) {
    console.error('GET /api/ref/types', error);
    res.status(500).json({ error: 'Failed to load reference types' });
  }
});

/**
 * Actualização em lote de label_en / label_pt (código `code` imutável nesta POC).
 * Corpo: { "equipment_type": [{ "id": 1, "label_en": "…", "label_pt": "…" }], ... }
 */
app.put('/api/ref/types', async (req, res) => {
  const body = req.body;
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return res.status(400).json({ error: 'Expected JSON object keyed by table name' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const [table, rows] of Object.entries(body)) {
      if (!REF_DOMAIN_TYPE_TABLES.includes(table)) {
        throw new Error(`Unknown table: ${table}`);
      }
      if (!Array.isArray(rows)) {
        throw new Error(`Value for ${table} must be an array`);
      }
      for (const row of rows) {
        const id = Number(row.id);
        if (!Number.isFinite(id)) {
          throw new Error(`Invalid id in ${table}`);
        }
        const label_en = row.label_en != null ? String(row.label_en) : '';
        const label_pt = row.label_pt != null ? String(row.label_pt) : '';
        await client.query(
          `UPDATE ref.${table} SET label_en = $1, label_pt = $2 WHERE id = $3`,
          [label_en, label_pt, id]
        );
      }
    }
    await client.query('COMMIT');
    const tables = Object.keys(body);
    await emitWithRequest(req, {
      domain: 'ref',
      eventType: 'ref.types_batch.updated',
      aggregateType: 'ref.multitable',
      aggregateId: tables.sort().join(','),
      payload: {
        tables,
        row_counts: Object.fromEntries(
          tables.map((t) => [t, Array.isArray(body[t]) ? body[t].length : 0])
        ),
      },
      actorType: 'api',
    });
    res.json({ ok: true });
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {
      /* ignore */
    }
    console.error('PUT /api/ref/types', error);
    res.status(400).json({ error: error.message || 'Update failed' });
  } finally {
    client.release();
  }
});

/** Últimos registos de arquivo antes de DELETE (operations) */
app.get('/api/audit/operations-archive', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 40, 200);
    const { rows } = await pool.query(
      `SELECT id, source_schema, source_table, source_id, archived_at, archive_reason
       FROM audit.operations_row_archive
       ORDER BY archived_at DESC
       LIMIT $1`,
      [limit]
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/audit/operations-archive', error);
    res.status(500).json({ error: 'Failed to list archive rows' });
  }
});

/** Leitura do diário events (append-only). Filtros opcionais: domain, event_type, aggregate_type, aggregate_id, since (ISO). */
app.get('/api/events', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 80, 500);
    const cond = [];
    const vals = [];
    let n = 1;

    if (req.query.domain) {
      cond.push(`domain = $${n++}`);
      vals.push(String(req.query.domain).trim().toLowerCase());
    }
    if (req.query.event_type) {
      cond.push(`event_type = $${n++}`);
      vals.push(String(req.query.event_type).trim());
    }
    if (req.query.aggregate_type) {
      cond.push(`aggregate_type = $${n++}`);
      vals.push(String(req.query.aggregate_type).trim());
    }
    if (req.query.aggregate_id) {
      cond.push(`aggregate_id = $${n++}`);
      vals.push(String(req.query.aggregate_id).trim());
    }
    if (req.query.since) {
      cond.push(`occurred_at >= $${n++}::timestamptz`);
      vals.push(String(req.query.since));
    }
    if (req.query.correlation_id) {
      cond.push(`correlation_id = $${n++}::uuid`);
      vals.push(String(req.query.correlation_id).trim());
    }

    vals.push(limit);
    const where = cond.length ? `WHERE ${cond.join(' AND ')}` : '';
    const sql = `
      SELECT id, event_uuid, occurred_at, recorded_at, schema_version, domain, event_type,
             aggregate_type, aggregate_id, correlation_id, causation_id,
             actor_type, actor_id, source, payload, metadata
      FROM events.event
      ${where}
      ORDER BY occurred_at DESC, id DESC
      LIMIT $${n}
    `;
    const { rows } = await pool.query(sql, vals);
    res.json(rows);
  } catch (error) {
    console.error('GET /api/events', error);
    res.status(500).json({ error: 'Failed to list events (verifique se infra/sql/15_events_schema.sql foi aplicado)' });
  }
});

app.listen(port, () => {
  console.log(`API server running on port ${port}`);
});
