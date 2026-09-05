const express = require('express');
const cors = require('cors');
const https = require('https');
const { randomUUID } = require('crypto');
const { Pool } = require('pg');
const { omsAggregateCellMetersFromZoom } = require('./lib/omsAggregate');
const { geocodeQueryTooShort } = require('./lib/geocodeQuery');
const { formatLocalStreetDisplayName } = require('./lib/localGeocodeFormat');
const { createDefaultEventBus } = require('./lib/events/createEventBus');
const { validateViewNodePatch } = require('./lib/schematic/validateViewNodePatch');
const { eventRowToMongoShape } = require('./lib/events/eventRowToMongoShape');
const {
  validateSpanCreate,
  validateSpanPatch,
  lineStringGeoJson,
} = require('./lib/topology/validateSpanWrite');
const { generateSpanCode } = require('./lib/topology/generateSpanCode');
const {
  parseTeamRoutesQuery,
  parseDisplacementsQuery,
} = require('./lib/mwm/parseTeamRoutesQuery');
const { parseDisplacementPatch } = require('./lib/mwm/parseDisplacementPatch');
const { parseTeamPatch } = require('./lib/mwm/parseTeamPatch');

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

async function listUsersWithGroup(poolLike) {
  const { rows } = await poolLike.query(
    `SELECT u.id, u.username, u.email, u.first_name, u.last_name, u.access_type, u.status,
            u.is_active, u.created_at,
            g.id AS group_id, g.code AS group_code, g.name AS group_name
     FROM security.users u
     LEFT JOIN LATERAL (
       SELECT gm.group_id
       FROM security.user_group_member gm
       WHERE gm.user_id = u.id
       ORDER BY gm.assigned_at DESC
       LIMIT 1
     ) m ON TRUE
     LEFT JOIN security.user_group g ON g.id = m.group_id
     ORDER BY u.username`
  );
  return rows;
}

function getRequestUserId(req) {
  const raw = req.get('x-tabgis-user-id');
  if (!raw) return null;
  const id = Number(raw);
  return Number.isFinite(id) && id > 0 ? id : null;
}

async function getEffectiveAccess(userId) {
  const id = Number(userId);
  if (!Number.isFinite(id) || id < 1) return null;
  const { rows } = await pool.query(
    `SELECT u.id AS user_id, u.username, u.is_active,
            g.id AS group_id, g.code AS group_code, g.name AS group_name, g.is_admin,
            COALESCE(array_agg(p.code ORDER BY p.code) FILTER (WHERE p.code IS NOT NULL), '{}') AS privilege_codes
     FROM security.users u
     LEFT JOIN LATERAL (
       SELECT gm.group_id
       FROM security.user_group_member gm
       WHERE gm.user_id = u.id
       ORDER BY gm.assigned_at DESC
       LIMIT 1
     ) m ON TRUE
     LEFT JOIN security.user_group g ON g.id = m.group_id
     LEFT JOIN security.group_privilege gp ON gp.group_id = g.id
     LEFT JOIN security.privilege p ON p.id = gp.privilege_id
     WHERE u.id = $1
     GROUP BY u.id, u.username, u.is_active, g.id, g.code, g.name, g.is_admin`,
    [id]
  );
  if (!rows.length) return null;
  const r = rows[0];
  const codes = Array.isArray(r.privilege_codes) ? r.privilege_codes : [];
  const privilegeSet = new Set(codes);
  return {
    user_id: Number(r.user_id),
    username: r.username,
    is_active: r.is_active !== false,
    group_id: r.group_id != null ? Number(r.group_id) : null,
    group_code: r.group_code || null,
    group_name: r.group_name || null,
    is_admin: r.is_admin === true,
    privilege_codes: codes,
    privileges: {
      dms: r.is_admin === true || privilegeSet.has('module.dms'),
      parameters: r.is_admin === true || privilegeSet.has('config.parameters'),
      ref_types: r.is_admin === true || privilegeSet.has('config.ref_types'),
      users: r.is_admin === true || privilegeSet.has('config.users'),
    },
  };
}

async function ensurePrivilege(req, res, privilegeCode) {
  if (process.env.SECURITY_ENFORCE !== '1') return true;
  const uid = getRequestUserId(req);
  if (!uid) {
    res.status(401).json({ error: 'Missing X-TabGis-User-Id for this operation' });
    return false;
  }
  const access = await getEffectiveAccess(uid);
  if (!access || access.is_active === false) {
    res.status(403).json({ error: 'User is inactive or unknown' });
    return false;
  }
  if (access.is_admin || access.privilege_codes.includes(privilegeCode)) return true;
  res.status(403).json({ error: `Missing privilege: ${privilegeCode}` });
  return false;
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

const OPEN_METEO_FORECAST_BASE =
  process.env.OPEN_METEO_FORECAST_BASE || 'https://api.open-meteo.com/v1/forecast';

/**
 * Proxy de leitura para Open-Meteo (sem chave). O browser chama a API TabGis;
 * o contentor contacta o serviço externo — útil quando o posto de trabalho não tem saída directa.
 * @see https://open-meteo.com/en/terms
 */
app.get('/api/weather/open-meteo', async (req, res) => {
  const latRaw = req.query.latitude ?? req.query.lat;
  const lngRaw = req.query.longitude ?? req.query.lon;
  const lat = latRaw !== undefined && String(latRaw).trim() !== '' ? Number(latRaw) : -23.55052;
  const lng = lngRaw !== undefined && String(lngRaw).trim() !== '' ? Number(lngRaw) : -46.633308;
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return res.status(400).json({ error: 'Invalid latitude or longitude' });
  }
  const upstream = new URL(OPEN_METEO_FORECAST_BASE);
  upstream.searchParams.set('latitude', String(lat));
  upstream.searchParams.set('longitude', String(lng));
  upstream.searchParams.set(
    'current',
    'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,apparent_temperature'
  );
  upstream.searchParams.set('timezone', 'America/Sao_Paulo');
  upstream.searchParams.set('wind_speed_unit', 'kmh');

  const ac = new AbortController();
  const to = setTimeout(() => ac.abort(), 15000);
  try {
    const r = await fetch(upstream.toString(), {
      signal: ac.signal,
      headers: { Accept: 'application/json' },
    });
    clearTimeout(to);
    if (!r.ok) {
      console.error('GET /api/weather/open-meteo upstream', r.status, upstream.hostname);
      return res.status(502).json({ error: 'Open-Meteo returned an error status' });
    }
    const j = await r.json();
    res.json(j);
  } catch (error) {
    clearTimeout(to);
    console.error('GET /api/weather/open-meteo', error);
    res.status(502).json({ error: 'Failed to reach Open-Meteo' });
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

/** Utilizadores (security.users) + grupo activo (security.user_group_member) */
app.get('/api/users', async (_req, res) => {
  try {
    const rows = await listUsersWithGroup(pool);
    res.json(rows);
  } catch (error) {
    console.error('GET /api/users', error);
    res.status(500).json({ error: 'Failed to list users' });
  }
});

app.post('/api/users', async (req, res) => {
  const client = await pool.connect();
  try {
    const { username, email, first_name, last_name, access_type, group_id } = req.body || {};
    if (!username || String(username).trim() === '') {
      return res.status(400).json({ error: 'username is required' });
    }
    await client.query('BEGIN');
    const { rows } = await client.query(
      `INSERT INTO security.users (username, email, first_name, last_name, access_type)
       VALUES ($1, $2, $3, $4, COALESCE($5, 'CONSULTA'))
       RETURNING id, username, email, first_name, last_name, access_type, status, is_active, created_at`,
      [String(username).trim(), email || null, first_name || null, last_name || null, access_type || null]
    );
    const created = rows[0];
    const gid = Number(group_id);
    if (Number.isFinite(gid) && gid > 0) {
      const gExists = await client.query(`SELECT id FROM security.user_group WHERE id = $1`, [gid]);
      if (!gExists.rows.length) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Invalid group_id' });
      }
      await client.query(
        `INSERT INTO security.user_group_member (user_id, group_id)
         VALUES ($1, $2)
         ON CONFLICT (user_id, group_id) DO NOTHING`,
        [created.id, gid]
      );
    }
    await client.query('COMMIT');
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
    const list = await listUsersWithGroup(pool);
    const full = list.find((u) => Number(u.id) === Number(created.id)) || created;
    res.status(201).json(full);
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {
      /* ignore */
    }
    if (error.code === '23505') {
      return res.status(409).json({ error: 'Username already exists' });
    }
    console.error('POST /api/users', error);
    res.status(500).json({ error: 'Failed to create user' });
  } finally {
    client.release();
  }
});

app.patch('/api/users/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  const body = req.body || {};
  const sets = [];
  const vals = [];
  if (Object.prototype.hasOwnProperty.call(body, 'is_active')) {
    const isActive = !!body.is_active;
    sets.push(`is_active = $${vals.length + 1}`);
    vals.push(isActive);
    sets.push(`status = $${vals.length + 1}`);
    vals.push(isActive ? 'active' : 'inactive');
  }
  if (Object.prototype.hasOwnProperty.call(body, 'access_type')) {
    const at = String(body.access_type || '').trim().toUpperCase();
    if (!at) return res.status(400).json({ error: 'access_type cannot be empty' });
    sets.push(`access_type = $${vals.length + 1}`);
    vals.push(at);
  }
  if (sets.length === 0) {
    return res.status(400).json({ error: 'No fields to update' });
  }
  vals.push(id);
  try {
    const { rows } = await pool.query(
      `UPDATE security.users
       SET ${sets.join(', ')}
       WHERE id = $${vals.length}
       RETURNING id`,
      vals
    );
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    await emitWithRequest(req, {
      domain: 'security',
      eventType: 'security.user.updated',
      aggregateType: 'security.user',
      aggregateId: String(id),
      payload: {
        is_active: body.is_active,
        access_type: body.access_type,
      },
      actorType: 'api',
    });
    const list = await listUsersWithGroup(pool);
    const full = list.find((u) => Number(u.id) === id);
    res.json(full || { id });
  } catch (error) {
    console.error('PATCH /api/users/:id', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

app.patch('/api/users/:id/group', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  const groupIdRaw = req.body ? req.body.group_id : null;
  const groupId = groupIdRaw == null || groupIdRaw === '' ? null : Number(groupIdRaw);
  if (groupId !== null && (!Number.isFinite(groupId) || groupId < 1)) {
    return res.status(400).json({ error: 'Invalid group_id' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const u = await client.query(`SELECT id FROM security.users WHERE id = $1`, [id]);
    if (!u.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found' });
    }
    if (groupId !== null) {
      const g = await client.query(`SELECT id FROM security.user_group WHERE id = $1`, [groupId]);
      if (!g.rows.length) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Group not found' });
      }
    }
    await client.query(`DELETE FROM security.user_group_member WHERE user_id = $1`, [id]);
    if (groupId !== null) {
      await client.query(
        `INSERT INTO security.user_group_member (user_id, group_id) VALUES ($1, $2)`,
        [id, groupId]
      );
    }
    await client.query('COMMIT');
    await emitWithRequest(req, {
      domain: 'security',
      eventType: 'security.user.group.updated',
      aggregateType: 'security.user',
      aggregateId: String(id),
      payload: {
        group_id: groupId,
      },
      actorType: 'api',
    });
    const list = await listUsersWithGroup(pool);
    const full = list.find((u2) => Number(u2.id) === id);
    res.json(full || { id, group_id: groupId });
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {
      /* ignore */
    }
    console.error('PATCH /api/users/:id/group', error);
    res.status(500).json({ error: 'Failed to update user group' });
  } finally {
    client.release();
  }
});

app.get('/api/security/privileges', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, code, label_pt, label_en, description
       FROM security.privilege
       ORDER BY code`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/security/privileges', error);
    res.status(500).json({ error: 'Failed to list privileges' });
  }
});

app.get('/api/security/groups', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT g.id, g.code, g.name, g.is_admin, g.is_system,
              COALESCE(
                jsonb_agg(
                  jsonb_build_object(
                    'id', p.id,
                    'code', p.code,
                    'label_pt', p.label_pt,
                    'label_en', p.label_en
                  )
                  ORDER BY p.code
                ) FILTER (WHERE p.id IS NOT NULL),
                '[]'::jsonb
              ) AS privileges
       FROM security.user_group g
       LEFT JOIN security.group_privilege gp ON gp.group_id = g.id
       LEFT JOIN security.privilege p ON p.id = gp.privilege_id
       GROUP BY g.id, g.code, g.name, g.is_admin, g.is_system
       ORDER BY g.name`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/security/groups', error);
    res.status(500).json({ error: 'Failed to list groups' });
  }
});

app.get('/api/security/users/:id/effective-access', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid user id' });
  }
  try {
    const access = await getEffectiveAccess(id);
    if (!access) return res.status(404).json({ error: 'User not found' });
    res.json(access);
  } catch (error) {
    console.error('GET /api/security/users/:id/effective-access', error);
    res.status(500).json({ error: 'Failed to compute effective access' });
  }
});

app.put('/api/security/groups/:id/privileges', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'config.users'))) return;
  const id = Number(req.params.id);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid group id' });
  }
  const codes = Array.isArray(req.body?.privilege_codes)
    ? req.body.privilege_codes.map((c) => String(c || '').trim()).filter(Boolean)
    : null;
  if (!codes) {
    return res.status(400).json({ error: 'Expected privilege_codes[]' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const g = await client.query(`SELECT id, code, is_admin FROM security.user_group WHERE id = $1`, [id]);
    if (!g.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Group not found' });
    }
    if (g.rows[0].is_admin) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Administrator group always has all privileges' });
    }
    const pRows = await client.query(
      `SELECT id, code FROM security.privilege WHERE code = ANY($1::text[])`,
      [codes]
    );
    if (pRows.rows.length !== codes.length) {
      const found = new Set(pRows.rows.map((r) => r.code));
      const missing = codes.filter((c) => !found.has(c));
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `Unknown privilege codes: ${missing.join(', ')}` });
    }
    await client.query(`DELETE FROM security.group_privilege WHERE group_id = $1`, [id]);
    for (const r of pRows.rows) {
      await client.query(
        `INSERT INTO security.group_privilege (group_id, privilege_id) VALUES ($1, $2)`,
        [id, r.id]
      );
    }
    await client.query('COMMIT');
    await emitWithRequest(req, {
      domain: 'security',
      eventType: 'security.group.privileges.updated',
      aggregateType: 'security.group',
      aggregateId: String(id),
      payload: { privilege_codes: codes },
      actorType: 'api',
    });
    res.json({ ok: true });
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {
      /* ignore */
    }
    console.error('PUT /api/security/groups/:id/privileges', error);
    res.status(500).json({ error: 'Failed to update group privileges' });
  } finally {
    client.release();
  }
});

/** Ordens — operations.work_order + equipa, responsável e bloqueio (eventos excluídos da lista OMS) */
app.get('/api/work-orders', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
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
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  try {
    const zoomRaw = req.query.zoom;
    if (zoomRaw !== undefined && String(zoomRaw).trim() !== '') {
      const cellM = omsAggregateCellMetersFromZoom(zoomRaw);
      const { rows } = await pool.query(
        `SELECT cluster_id, orders_count, center_lat, center_lng,
                first_started_at, last_updated_at, area_hint,
                customers_sum, duration_hours_sum, priority_score_sum
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
app.get('/api/mwm/demo-routes', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.mwm'))) return;
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

/**
 * Rotas operacionais por janela temporal (`operations.team_route`).
 * Query: hours (1–168, default 48), team_id (opcional).
 * Devolve GeoJSON da rota + metadados da equipa. Ver docs/mds/OPERATIONS_MWM.md.
 */
app.get('/api/mwm/team-routes', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.mwm'))) return;
  const parsed = parseTeamRoutesQuery(req.query);
  if (!parsed.ok) {
    return res.status(parsed.status).json({ error: parsed.error });
  }
  try {
    const vals = [parsed.hours];
    let teamClause = '';
    if (parsed.teamId != null) {
      vals.push(parsed.teamId);
      teamClause = ` AND tr.team_id = $${vals.length}`;
    }
    const { rows } = await pool.query(
      `SELECT tr.id AS route_id, tr.team_id, t.team_code, t.name AS team_name, t.status AS team_status,
              tr.window_start, tr.window_end, tr.source, tr.recorded_at,
              ST_AsGeoJSON(tr.route_geom)::json AS route_geojson,
              round((ST_Length(tr.route_geom::geography))::numeric, 2) AS length_m_approx
       FROM operations.team_route tr
       JOIN operations.team t ON t.id = tr.team_id
       WHERE tr.window_end >= (now() - ($1::int * INTERVAL '1 hour'))
         AND tr.window_start <= now()
         ${teamClause}
       ORDER BY t.team_code, tr.window_end DESC, tr.id DESC`,
      vals
    );
    res.json({ hours: parsed.hours, count: rows.length, routes: rows });
  } catch (error) {
    console.error('GET /api/mwm/team-routes', error);
    res.status(500).json({
      error: 'Failed to list team routes (verifique operations.team_route e infra/sql/24_mwm_team_routes_48h_demo.sql)',
    });
  }
});

/**
 * Deslocamentos equipa ↔ ordem (`operations.team_order_displacement`).
 * Query: team_id, work_order_id, limit (default 100, max 500).
 */
app.get('/api/mwm/displacements', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.mwm'))) return;
  const parsed = parseDisplacementsQuery(req.query);
  if (!parsed.ok) {
    return res.status(parsed.status).json({ error: parsed.error });
  }
  try {
    const cond = [];
    const vals = [];
    if (parsed.teamId != null) {
      vals.push(parsed.teamId);
      cond.push(`d.team_id = $${vals.length}`);
    }
    if (parsed.workOrderId != null) {
      vals.push(parsed.workOrderId);
      cond.push(`d.work_order_id = $${vals.length}`);
    }
    vals.push(parsed.limit);
    const where = cond.length ? `WHERE ${cond.join(' AND ')}` : '';
    const { rows } = await pool.query(
      `SELECT d.id, d.team_id, t.team_code, d.work_order_id, wo.order_code, wo.summary AS order_summary,
              wo.status AS order_status,
              d.planned_departure_at, d.planned_arrival_at,
              d.actual_departure_at, d.actual_arrival_at, d.notes, d.created_at
       FROM operations.team_order_displacement d
       JOIN operations.team t ON t.id = d.team_id
       JOIN operations.work_order wo ON wo.id = d.work_order_id
       ${where}
       ORDER BY d.planned_departure_at DESC NULLS LAST, d.id DESC
       LIMIT $${vals.length}`,
      vals
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/mwm/displacements', error);
    res.status(500).json({ error: 'Failed to list displacements' });
  }
});

/**
 * Actualização parcial de deslocamento (horários planeados/real + notes).
 * PATCH /api/mwm/displacements/:id
 */
app.patch('/api/mwm/displacements/:id', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.mwm'))) return;
  const id = parseInt(req.params.id, 10);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid displacement id' });
  }
  const parsed = parseDisplacementPatch(req.body);
  if (!parsed.ok) {
    return res.status(parsed.status).json({ error: parsed.error });
  }
  const u = parsed.updates;
  try {
    const { rows } = await pool.query(
      `UPDATE operations.team_order_displacement
       SET planned_departure_at = CASE WHEN $2::boolean THEN $3::timestamptz ELSE planned_departure_at END,
           planned_arrival_at = CASE WHEN $4::boolean THEN $5::timestamptz ELSE planned_arrival_at END,
           actual_departure_at = CASE WHEN $6::boolean THEN $7::timestamptz ELSE actual_departure_at END,
           actual_arrival_at = CASE WHEN $8::boolean THEN $9::timestamptz ELSE actual_arrival_at END,
           notes = CASE WHEN $10::boolean THEN $11::text ELSE notes END
       WHERE id = $1
       RETURNING id, team_id, work_order_id, planned_departure_at, planned_arrival_at,
                 actual_departure_at, actual_arrival_at, notes, created_at`,
      [
        id,
        Object.prototype.hasOwnProperty.call(u, 'planned_departure_at'),
        u.planned_departure_at ?? null,
        Object.prototype.hasOwnProperty.call(u, 'planned_arrival_at'),
        u.planned_arrival_at ?? null,
        Object.prototype.hasOwnProperty.call(u, 'actual_departure_at'),
        u.actual_departure_at ?? null,
        Object.prototype.hasOwnProperty.call(u, 'actual_arrival_at'),
        u.actual_arrival_at ?? null,
        Object.prototype.hasOwnProperty.call(u, 'notes'),
        u.notes ?? null,
      ]
    );
    if (!rows.length) {
      return res.status(404).json({ error: 'Displacement not found' });
    }
    res.json(rows[0]);
  } catch (error) {
    console.error('PATCH /api/mwm/displacements/:id', error);
    res.status(500).json({ error: 'Failed to update displacement' });
  }
});

/**
 * Actualização de última posição de equipa (L4) e status.
 * PATCH /api/teams/:id
 * Campos: last_known_lat, last_known_lng, status.
 */
app.patch('/api/teams/:id', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.mwm'))) return;
  const id = parseInt(req.params.id, 10);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid team id' });
  }
  const parsed = parseTeamPatch(req.body);
  if (!parsed.ok) {
    return res.status(parsed.status).json({ error: parsed.error });
  }
  const u = parsed.updates;
  try {
    const { rows: existing } = await pool.query(
      `SELECT id, last_known_geom FROM operations.team WHERE id = $1 FOR UPDATE`,
      [id]
    );
    if (!existing.length) {
      return res.status(404).json({ error: 'Team not found' });
    }
    let lat = null;
    let lng = null;
    if (Object.prototype.hasOwnProperty.call(u, 'last_known_lat') || Object.prototype.hasOwnProperty.call(u, 'last_known_lng')) {
      const { rows: geomRows } = await pool.query(
        `SELECT ST_X(last_known_geom) AS lng, ST_Y(last_known_geom) AS lat
         FROM operations.team WHERE id = $1`,
        [id]
      );
      const oldLat = geomRows[0] && geomRows[0].lat != null ? Number(geomRows[0].lat) : NaN;
      const oldLng = geomRows[0] && geomRows[0].lng != null ? Number(geomRows[0].lng) : NaN;
      lat = Object.prototype.hasOwnProperty.call(u, 'last_known_lat')
        ? u.last_known_lat
        : oldLat;
      lng = Object.prototype.hasOwnProperty.call(u, 'last_known_lng')
        ? u.last_known_lng
        : oldLng;
    }
    const sets = [];
    const vals = [];
    if (Number.isFinite(lat) && Number.isFinite(lng)) {
      vals.push(lat, lng);
      sets.push(`last_known_geom = ST_SetSRID(ST_MakePoint($${vals.length - 1}, $${vals.length}), 4326)`);
    }
    if (Object.prototype.hasOwnProperty.call(u, 'status')) {
      vals.push(u.status);
      sets.push(`status = $${vals.length}`);
    }
    if (!sets.length) {
      return res.status(400).json({ error: 'No updatable fields' });
    }
    sets.push('last_updated_at = now()');
    vals.push(id);
    const { rows } = await pool.query(
      `UPDATE operations.team SET ${sets.join(', ')} WHERE id = $${vals.length} RETURNING id, team_code, name, last_coordinate_at, last_updated_at, status`,
      vals
    );
    res.json(rows[0]);
  } catch (error) {
    console.error('PATCH /api/teams/:id', error);
    res.status(500).json({ error: 'Failed to update team' });
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

/** Ordens canónicas OMS (leitura) — alinhado a docs/mds/Database_Structure_Context.md */
app.get('/api/oms/work-orders', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
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
app.get('/api/teams', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.mwm'))) return;
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

app.get('/api/ref/types', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'config.ref_types'))) return;
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
  if (!(await ensurePrivilege(req, res, 'config.ref_types'))) return;
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
  if (!(await ensurePrivilege(req, res, 'module.aud'))) return;
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

/** Filtros HTTP partilhados por GET /api/events e GET /api/events/export. */
function eventsHttpFilterClause(query) {
  const cond = [];
  const vals = [];
  let n = 1;
  if (query.domain) {
    cond.push(`domain = $${n++}`);
    vals.push(String(query.domain).trim().toLowerCase());
  }
  if (query.event_type) {
    cond.push(`event_type = $${n++}`);
    vals.push(String(query.event_type).trim());
  }
  if (query.aggregate_type) {
    cond.push(`aggregate_type = $${n++}`);
    vals.push(String(query.aggregate_type).trim());
  }
  if (query.aggregate_id) {
    cond.push(`aggregate_id = $${n++}`);
    vals.push(String(query.aggregate_id).trim());
  }
  if (query.since) {
    cond.push(`occurred_at >= $${n++}::timestamptz`);
    vals.push(String(query.since));
  }
  if (query.correlation_id) {
    cond.push(`correlation_id = $${n++}::uuid`);
    vals.push(String(query.correlation_id).trim());
  }
  return { cond, vals, nextParam: n };
}

/** Leitura do diário events (append-only). Filtros opcionais: domain, event_type, aggregate_type, aggregate_id, since (ISO). */
app.get('/api/events', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.aud'))) return;
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 80, 500);
    const { cond, vals, nextParam } = eventsHttpFilterClause(req.query);
    vals.push(limit);
    const where = cond.length ? `WHERE ${cond.join(' AND ')}` : '';
    const sql = `
      SELECT id, event_uuid, occurred_at, recorded_at, schema_version, domain, event_type,
             aggregate_type, aggregate_id, correlation_id, causation_id,
             actor_type, actor_id, source, payload, metadata
      FROM events.event
      ${where}
      ORDER BY occurred_at DESC, id DESC
      LIMIT $${nextParam}
    `;
    const { rows } = await pool.query(sql, vals);
    res.json(rows);
  } catch (error) {
    console.error('GET /api/events', error);
    res.status(500).json({ error: 'Failed to list events (verifique se infra/sql/15_events_schema.sql foi aplicado)' });
  }
});

/**
 * Exportação cursada para ETL / replicação externa: ordenação estável por `id` ascendente.
 * Query: after_id (opcional, default 0), limit (default 500, max 2000), mesmos filtros que GET /api/events,
 * shape=mongo → cada evento como documento com _id = event_uuid (dedupe idempotente).
 */
app.get('/api/events/export', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.aud'))) return;
  try {
    const afterId = Math.max(0, parseInt(req.query.after_id, 10) || 0);
    const limit = Math.min(Math.max(1, parseInt(req.query.limit, 10) || 500), 2000);
    const mongoShape = String(req.query.shape || '').toLowerCase() === 'mongo';
    const { cond, vals, nextParam } = eventsHttpFilterClause(req.query);
    cond.push(`id > $${nextParam++}`);
    vals.push(afterId);
    vals.push(limit);
    const where = `WHERE ${cond.join(' AND ')}`;
    const sql = `
      SELECT id, event_uuid, occurred_at, recorded_at, schema_version, domain, event_type,
             aggregate_type, aggregate_id, correlation_id, causation_id,
             actor_type, actor_id, source, payload, metadata
      FROM events.event
      ${where}
      ORDER BY id ASC
      LIMIT $${nextParam}
    `;
    const { rows } = await pool.query(sql, vals);
    const lastId = rows.length ? rows[rows.length - 1].id : afterId;
    const events = mongoShape ? rows.map(eventRowToMongoShape) : rows;
    res.json({
      after_id: afterId,
      next_after_id: lastId,
      count: rows.length,
      events,
    });
  } catch (error) {
    console.error('GET /api/events/export', error);
    res.status(500).json({
      error: 'Failed to export events (verifique se infra/sql/15_events_schema.sql foi aplicado)',
    });
  }
});

/**
 * Topologia PostGIS nativa (`postgis_topology`) — segmentos lineares da rede em `gis.network_span`.
 * Documentação: docs/mds/TOPOLOGY_NATIVE_POSTGIS.md
 */
app.get('/api/topology/meta', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  try {
    const { rows: topologies } = await pool.query(
      `SELECT id, name, srid, precision
       FROM topology.topology
       WHERE name = 'tabgis_utilities_topo'`
    );
    if (!topologies.length) {
      return res.json({
        ok: true,
        installed: false,
        hint: 'Aplicar infra/sql/21_postgis_topology_utilities.sql na base PostGIS.',
      });
    }
    const topo = topologies[0];
    const { rows: layers } = await pool.query(
      `SELECT layer_id, schema_name, table_name, feature_column, feature_type, level, child_id
       FROM topology.layer
       WHERE topology_id = $1
       ORDER BY layer_id`,
      [topo.id]
    );
    const { rows: primRows } = await pool.query(`
      SELECT
        (SELECT COUNT(*)::bigint FROM tabgis_utilities_topo.edge_data) AS edges,
        (SELECT COUNT(*)::bigint FROM tabgis_utilities_topo.node) AS nodes,
        (SELECT COUNT(*)::bigint FROM tabgis_utilities_topo.face) AS faces
    `);
    res.json({
      ok: true,
      installed: true,
      topology: topo,
      layers,
      primitives: primRows[0] || null,
    });
  } catch (error) {
    console.error('GET /api/topology/meta', error);
    const code = error && error.code;
    const hint =
      code === '42P01'
        ? 'CREATE EXTENSION postgis_topology; aplicar infra/sql/21_postgis_topology_utilities.sql.'
        : 'Verificar extensão postgis_topology e logs da API.';
    res.status(503).json({
      ok: false,
      error: 'Topology metadata unavailable',
      hint,
      detail: error.message,
    });
  }
});

app.get('/api/topology/spans', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 200, 500);
    const { rows } = await pool.query(
      `SELECT id, code, description, utility_domain,
              equipment_from_id, equipment_to_id,
              ST_AsGeoJSON(span_geom)::json AS span_geojson,
              (topo_geom IS NOT NULL) AS has_topo_geom,
              round((ST_Length(span_geom::geography))::numeric, 2) AS length_m_approx,
              created_at
       FROM gis.network_span
       ORDER BY id
       LIMIT $1`,
      [limit]
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/topology/spans', error);
    res.status(503).json({
      error:
        'Failed to list network spans (crie extensão postgis_topology e aplique infra/sql/21_postgis_topology_utilities.sql)',
      detail: error.message,
    });
  }
});

/** Camada TopoGeometry de gis.network_span (layer_id + tolerância da topologia). */
async function getNetworkSpanTopoLayer(clientLike) {
  const { rows } = await clientLike.query(
    `SELECT l.layer_id, t.precision, t.name AS topology_name
     FROM topology.layer l
     INNER JOIN topology.topology t ON t.id = l.topology_id
     WHERE t.name = 'tabgis_utilities_topo'
       AND l.schema_name = 'gis'
       AND l.table_name = 'network_span'
       AND l.feature_column = 'topo_geom'`
  );
  return rows[0] || null;
}

const SPAN_RETURNING = `
  id, code, description, utility_domain,
  equipment_from_id, equipment_to_id,
  ST_AsGeoJSON(span_geom)::json AS span_geojson,
  (topo_geom IS NOT NULL) AS has_topo_geom,
  round((ST_Length(span_geom::geography))::numeric, 2) AS length_m_approx,
  metadata, created_at, updated_at`;

app.get('/api/topology/spans/:id', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  const id = parseInt(req.params.id, 10);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid span id' });
  }
  try {
    const { rows } = await pool.query(
      `SELECT ${SPAN_RETURNING} FROM gis.network_span WHERE id = $1`,
      [id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Span not found' });
    res.json(rows[0]);
  } catch (error) {
    console.error('GET /api/topology/spans/:id', error);
    res.status(503).json({ error: 'Failed to load network span', detail: error.message });
  }
});

/**
 * Cria segmento linear da rede: INSERT + materialização de TopoGeometry
 * (nós coincidentes fundidos pela tolerância da topologia). Emite
 * `gis.topology.network_span.created`.
 */
app.post('/api/topology/spans', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  const parsed = validateSpanCreate(req.body);
  if (!parsed.ok) {
    return res.status(parsed.status).json({ error: parsed.error });
  }
  const s = parsed.span;
  const spanCode = s.codeAuto || !s.code ? generateSpanCode() : s.code;
  const client = await pool.connect();
  try {
    const layer = await getNetworkSpanTopoLayer(client);
    if (!layer) {
      return res.status(503).json({
        error: 'Topology layer not installed',
        hint: 'Aplicar infra/sql/21_postgis_topology_utilities.sql na base PostGIS.',
      });
    }
    await client.query('BEGIN');
    const { rows } = await client.query(
      `INSERT INTO gis.network_span
         (code, description, utility_domain, equipment_from_id, equipment_to_id, span_geom, metadata)
       VALUES ($1, $2, $3, $4, $5,
               ST_SetSRID(ST_GeomFromGeoJSON($6), 4326),
               COALESCE($7::jsonb, '{}'::jsonb))
       RETURNING ${SPAN_RETURNING}`,
      [
        spanCode,
        s.description ?? null,
        s.utility_domain ?? null,
        s.equipment_from_id ?? null,
        s.equipment_to_id ?? null,
        lineStringGeoJson(s.coordinates),
        s.metadata ? JSON.stringify(s.metadata) : null,
      ]
    );
    const span = rows[0];
    await client.query(
      `UPDATE gis.network_span
       SET topo_geom = topology.toTopoGeom(span_geom, 'tabgis_utilities_topo', $2, $3)
       WHERE id = $1`,
      [span.id, layer.layer_id, layer.precision]
    );
    await client.query('COMMIT');
    span.has_topo_geom = true;
    await emitWithRequest(req, {
      domain: 'gis',
      eventType: 'topology.network_span.created',
      aggregateType: 'gis.network_span',
      aggregateId: String(span.id),
      payload: { span_id: Number(span.id), code: span.code, vertices: s.coordinates.length },
      actorType: 'api',
    });
    res.status(201).json({ ok: true, span });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    if (error && error.code === '23505') {
      return res.status(409).json({ error: `Span code already exists: ${spanCode}` });
    }
    if (error && error.code === '23503') {
      return res.status(400).json({ error: 'equipment_from_id / equipment_to_id must reference gis.equipment' });
    }
    console.error('POST /api/topology/spans', error);
    res.status(500).json({ error: 'Failed to create network span', detail: error.message });
  } finally {
    client.release();
  }
});

/**
 * Atualização parcial de segmento. `coordinates` retraça a geometria e
 * re-materializa a TopoGeometry (limpa a anterior com clearTopoGeom).
 * Emite `gis.topology.network_span.updated`.
 */
app.patch('/api/topology/spans/:id', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  const id = parseInt(req.params.id, 10);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid span id' });
  }
  const parsed = validateSpanPatch(req.body);
  if (!parsed.ok) {
    return res.status(parsed.status).json({ error: parsed.error });
  }
  const u = parsed.updates;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: existing } = await client.query(
      `SELECT id, (topo_geom IS NOT NULL) AS has_topo_geom
       FROM gis.network_span WHERE id = $1 FOR UPDATE`,
      [id]
    );
    if (!existing.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Span not found' });
    }
    const sets = [];
    const vals = [];
    for (const field of ['description', 'utility_domain', 'equipment_from_id', 'equipment_to_id']) {
      if (u[field] !== undefined) {
        vals.push(u[field]);
        sets.push(`${field} = $${vals.length}`);
      }
    }
    if (u.metadata !== undefined) {
      vals.push(JSON.stringify(u.metadata));
      sets.push(`metadata = $${vals.length}::jsonb`);
    }
    if (u.coordinates !== undefined) {
      vals.push(lineStringGeoJson(u.coordinates));
      sets.push(`span_geom = ST_SetSRID(ST_GeomFromGeoJSON($${vals.length}), 4326)`);
    }
    sets.push('updated_at = now()');
    vals.push(id);
    const { rows } = await client.query(
      `UPDATE gis.network_span SET ${sets.join(', ')}
       WHERE id = $${vals.length}
       RETURNING ${SPAN_RETURNING}`,
      vals
    );
    if (u.coordinates !== undefined) {
      const layer = await getNetworkSpanTopoLayer(client);
      if (layer) {
        // Retraçado: limpa relações da TopoGeometry anterior e re-materializa sobre a nova geometria.
        await client.query(
          `UPDATE gis.network_span
           SET topo_geom = topology.toTopoGeom(span_geom, topology.clearTopoGeom(topo_geom), $2)
           WHERE id = $1 AND topo_geom IS NOT NULL`,
          [id, layer.precision]
        );
        await client.query(
          `UPDATE gis.network_span
           SET topo_geom = topology.toTopoGeom(span_geom, 'tabgis_utilities_topo', $2, $3)
           WHERE id = $1 AND topo_geom IS NULL`,
          [id, layer.layer_id, layer.precision]
        );
      }
    }
    await client.query('COMMIT');
    await emitWithRequest(req, {
      domain: 'gis',
      eventType: 'topology.network_span.updated',
      aggregateType: 'gis.network_span',
      aggregateId: String(id),
      payload: { span_id: id, updates: u },
      actorType: 'api',
    });
    const { rows: fresh } = await pool.query(
      `SELECT ${SPAN_RETURNING} FROM gis.network_span WHERE id = $1`,
      [id]
    );
    res.json({ ok: true, span: fresh[0] || rows[0] });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    if (error && error.code === '23503') {
      return res.status(400).json({ error: 'equipment_from_id / equipment_to_id must reference gis.equipment' });
    }
    console.error('PATCH /api/topology/spans/:id', error);
    res.status(500).json({ error: 'Failed to update network span', detail: error.message });
  } finally {
    client.release();
  }
});

/**
 * Remove segmento: limpa a TopoGeometry (liberta relações nas primitivas) e
 * apaga a linha — o trigger BEFORE DELETE (infra/sql/22) arquiva o snapshot em
 * audit.operations_row_archive antes da remoção. Emite
 * `gis.topology.network_span.deleted`.
 */
app.delete('/api/topology/spans/:id', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  const id = parseInt(req.params.id, 10);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid span id' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: existing } = await client.query(
      `SELECT id, code FROM gis.network_span WHERE id = $1 FOR UPDATE`,
      [id]
    );
    if (!existing.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Span not found' });
    }
    await client.query(
      `UPDATE gis.network_span
       SET topo_geom = topology.clearTopoGeom(topo_geom)
       WHERE id = $1 AND topo_geom IS NOT NULL`,
      [id]
    );
    await client.query(`DELETE FROM gis.network_span WHERE id = $1`, [id]);
    await client.query('COMMIT');
    await emitWithRequest(req, {
      domain: 'gis',
      eventType: 'topology.network_span.deleted',
      aggregateType: 'gis.network_span',
      aggregateId: String(id),
      payload: { span_id: id, code: existing[0].code },
      actorType: 'api',
    });
    res.json({ ok: true, deleted_id: id, code: existing[0].code });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('DELETE /api/topology/spans/:id', error);
    res.status(500).json({ error: 'Failed to delete network span', detail: error.message });
  } finally {
    client.release();
  }
});

/**
 * Manutenção da topologia: remove primitivas órfãs (arestas/nós sem referência
 * de TopoGeometry, tipicamente após DELETE de segmentos). Corpo opcional
 * `{ "dry_run": true }` apenas conta, sem remover. No dry-run a contagem de nós
 * isolados tende a subestimar (nós só ficam isolados após remover as arestas).
 * Função SQL: gis.prune_orphan_topology_primitives (infra/sql/23).
 * Emite `gis.topology.maintenance.pruned` quando remove de facto.
 */
app.post('/api/topology/maintenance/prune', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.oms'))) return;
  const dryRun = req.body != null && req.body.dry_run === true;
  try {
    const { rows } = await pool.query(
      `SELECT * FROM gis.prune_orphan_topology_primitives($1)`,
      [dryRun]
    );
    const result = rows[0] || {};
    if (!dryRun && (result.edges_removed > 0 || result.nodes_removed > 0)) {
      await emitWithRequest(req, {
        domain: 'gis',
        eventType: 'topology.maintenance.pruned',
        aggregateType: 'gis.topology',
        aggregateId: 'tabgis_utilities_topo',
        payload: { ...result },
        actorType: 'api',
      });
    }
    res.json({ ok: true, dry_run: dryRun, ...result });
  } catch (error) {
    console.error('POST /api/topology/maintenance/prune', error);
    res.status(503).json({
      error:
        'Failed to prune topology primitives (aplique infra/sql/23_topology_prune_orphan_primitives.sql)',
      detail: error.message,
    });
  }
});

/**
 * Vistas esquemáticas (unifilar / anotação de fluxo) — ver infra/sql/16_schematic_schema.sql
 */
app.get('/api/schematic/views', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.esq'))) return;
  try {
    const { rows } = await pool.query(
      `SELECT id, code, name, view_kind, description, metadata
       FROM schematic.network_view
       ORDER BY name, id`
    );
    res.json(rows);
  } catch (error) {
    console.error('GET /api/schematic/views', error);
    res.status(500).json({
      error:
        'Failed to list schematic views (verifique se infra/sql/16_schematic_schema.sql foi aplicado)',
    });
  }
});

app.get('/api/schematic/views/:id', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.esq'))) return;
  const id = parseInt(req.params.id, 10);
  if (!Number.isFinite(id) || id < 1) {
    return res.status(400).json({ error: 'Invalid view id' });
  }
  try {
    const { rows: vrows } = await pool.query(
      `SELECT id, code, name, view_kind, description, metadata
       FROM schematic.network_view
       WHERE id = $1`,
      [id]
    );
    if (!vrows.length) {
      return res.status(404).json({ error: 'View not found' });
    }
    const { rows: nodes } = await pool.query(
      `SELECT n.id, n.view_id, n.seq_no, n.label, n.symbol_code, n.equipment_id, n.focus_lat, n.focus_lng, n.props,
              e.location_desc AS equipment_location_desc,
              COALESCE(et.label_pt, et.label_en) AS equipment_type_label,
              et.code AS equipment_type_code,
              CASE WHEN e.geom IS NOT NULL THEN ST_Y(e.geom) END AS equipment_lat,
              CASE WHEN e.geom IS NOT NULL THEN ST_X(e.geom) END AS equipment_lng
       FROM schematic.view_node n
       LEFT JOIN gis.equipment e ON e.id = n.equipment_id
       LEFT JOIN ref.equipment_type et ON et.id = e.type_id
       WHERE n.view_id = $1
       ORDER BY n.seq_no, n.id`,
      [id]
    );
    const { rows: edges } = await pool.query(
      `SELECT id, view_id, from_node_id, to_node_id, edge_kind, label, active_power_kw, reactive_power_kvar, props
       FROM schematic.view_edge
       WHERE view_id = $1
       ORDER BY id`,
      [id]
    );
    res.json({ view: vrows[0], nodes, edges });
  } catch (error) {
    console.error('GET /api/schematic/views/:id', error);
    res.status(500).json({
      error: 'Failed to load schematic (verifique se infra/sql/16_schematic_schema.sql foi aplicado)',
    });
  }
});

/**
 * Actualiza nó de esquemático (rótulo e/ou par de coordenadas de foco). Emite `gis.schematic.view_node.updated`.
 */
app.patch('/api/schematic/views/:viewId/nodes/:nodeId', async (req, res) => {
  if (!(await ensurePrivilege(req, res, 'module.esq'))) return;
  const viewId = parseInt(req.params.viewId, 10);
  const nodeId = parseInt(req.params.nodeId, 10);
  if (!Number.isFinite(viewId) || !Number.isFinite(nodeId) || viewId < 1 || nodeId < 1) {
    return res.status(400).json({ error: 'Invalid view or node id' });
  }
  const parsed = validateViewNodePatch(req.body);
  if (!parsed.ok) {
    return res.status(parsed.status).json({ error: parsed.error });
  }
  const u = parsed.updates;
  const sets = [];
  const vals = [];
  if (u.label !== undefined) {
    sets.push(`label = $${vals.length + 1}`);
    vals.push(u.label);
  }
  if (u.focus_lat !== undefined) {
    sets.push(`focus_lat = $${vals.length + 1}`);
    vals.push(u.focus_lat);
    sets.push(`focus_lng = $${vals.length + 1}`);
    vals.push(u.focus_lng);
  }
  const phId = vals.length + 1;
  const phView = vals.length + 2;
  vals.push(nodeId, viewId);
  const sql = `UPDATE schematic.view_node
    SET ${sets.join(', ')}
    WHERE id = $${phId}::bigint AND view_id = $${phView}::bigint
    RETURNING id, view_id, seq_no, label, symbol_code, equipment_id, focus_lat, focus_lng, props`;
  const client = await pool.connect();
  try {
    const { rows } = await client.query(sql, vals);
    if (!rows.length) {
      return res.status(404).json({ error: 'Node not found in this view' });
    }
    await emitWithRequest(req, {
      domain: 'gis',
      eventType: 'schematic.view_node.updated',
      aggregateType: 'schematic.view_node',
      aggregateId: String(nodeId),
      payload: {
        view_id: viewId,
        node_id: nodeId,
        updates: u,
      },
      actorType: 'api',
    });
    res.json({ ok: true, node: rows[0] });
  } catch (error) {
    console.error('PATCH /api/schematic/views/:viewId/nodes/:nodeId', error);
    res.status(500).json({ error: 'Failed to update schematic node' });
  } finally {
    client.release();
  }
});

app.listen(port, () => {
  console.log(`API server running on port ${port}`);
});
