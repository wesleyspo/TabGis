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

// Endpoint to fetch translations for a specific language
app.get('/api/translations/:lang', async (req, res) => {
  try {
    const { lang } = req.params;
    
    // Join with config.language to verify the code and get matching translations
    const query = `
      SELECT t.object_id, t.translated_text
      FROM config.translation t
      JOIN config.language l ON t.language_id = l.id
      WHERE l.code = $1
    `;
    
    const result = await pool.query(query, [lang]);
    
    // Convert array of objects to a single dictionary
    const translations = {};
    result.rows.forEach(row => {
      translations[row.object_id] = row.translated_text;
    });
    
    res.json(translations);
  } catch (error) {
    console.error('Error fetching translations:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(port, () => {
  console.log(`API server running on port ${port}`);
});
