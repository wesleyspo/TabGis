const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST || 'db',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'tabgis_db',
  user: process.env.DB_USER || 'tabgis_admin',
  password: process.env.DB_PASSWORD || 'password123',
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
    res.status(201).json(rows[0]);
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
    res.json(rows[0]);
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
    res.status(201).json(rows[0]);
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
    res.json(rows[0]);
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

app.listen(port, () => {
  console.log(`API server running on port ${port}`);
});
