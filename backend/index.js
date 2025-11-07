// Backend API with automatic schema initialization
const express = require('express'); // Import Express for building the API
const cors = require('cors'); // Import CORS to allow frontend access
const { Pool } = require('pg'); // Import PostgreSQL client
const app = express(); // Create an Express app

// Enable CORS for all origins (adjust in production)
app.use(cors());
app.use(express.json()); // Parse JSON request bodies

console.log('[STARTUP] Initializing database connection pool...');
console.log('[STARTUP] DATABASE_URL:', process.env.DATABASE_URL ? 'SET' : 'NOT SET');

// Connect to PostgreSQL using DATABASE_URL from environment variables
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

console.log('[STARTUP] Pool created, ready to connect on first query');

// Ensure required schema exists (idempotent)
async function ensureSchema() {
  try {
    console.log('[SCHEMA] Attempting to create users table...');
    const createTableSQL = `CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL);`;
    console.log('[SCHEMA] SQL:', createTableSQL);
    const result = await pool.query(createTableSQL);
    console.log('[SCHEMA] CREATE TABLE succeeded. Result:', { command: result.command, rowCount: result.rowCount });
    
    // Verify table exists by querying information_schema
    const verifySQL = `SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users')`;
    const verifyResult = await pool.query(verifySQL);
    console.log('[SCHEMA] Table verification:', verifyResult.rows[0]);
    console.log('[SCHEMA] ✅ users table is ready');
  } catch (err) {
    console.error('[SCHEMA] ❌ CRITICAL: Failed to ensure DB schema:', err);
    console.error('[SCHEMA] Error details:', { code: err.code, message: err.message, severity: err.severity });
    throw err; // Stop startup if schema creation fails
  }
}

// Health check endpoint for Kubernetes probes and monitoring
app.get('/healthz', (req, res) => res.json({ status: 'ok' }));

// Get all users from the database (with error handling)
app.get('/users', async (req, res, next) => {
  try {
    const { rows } = await pool.query('SELECT * FROM users'); // Query the users table
    return res.json(rows); // Send users as JSON
  } catch (err) {
    // Forward to the error handler
    next(err);
  }
});

// Add a new user to the database (with error handling)
app.post('/users', async (req, res, next) => {
  try {
    const { name } = req.body; // Get name from request body
    // Validate input a bit
    if (!name || typeof name !== 'string') {
      return res.status(400).json({ error: 'name_required' });
    }

    // Insert user and return the new record
    const { rows } = await pool.query(
      'INSERT INTO users(name) VALUES($1) RETURNING *',
      [name]
    );
    return res.json(rows[0]); // Send the new user as JSON
  } catch (err) {
    // Forward to the error handler
    next(err);
  }
});

// Generic error handler (ensures CORS headers are included on errors)
app.use((err, req, res, next) => {
  // Log the full error to render logs
  console.error('Unhandled error:', err && (err.stack || err.message || err));

  // If headers already sent, delegate to default handler
  if (res.headersSent) return next(err);

  // Send a JSON error response. CORS middleware is global so Access-Control-* headers will be present.
  res.status(500).json({ error: 'internal_server_error' });
});

// Log unhandled promise rejections and uncaught exceptions so they appear in Render logs
process.on('unhandledRejection', (reason) => {
  console.error('unhandledRejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('uncaughtException:', err && (err.stack || err.message || err));
  // Allow logs to flush and then exit so the platform can restart the process.
  setTimeout(() => process.exit(1), 1000);
});

// Startup: ensure schema, then start server
(async () => {
  try {
    console.log('[STARTUP] IIFE started, beginning startup sequence...');
    console.log('[STARTUP] Checking DB connection...');
    await pool.query('SELECT 1');
    console.log('[STARTUP] DB connection OK');
    
    console.log('[STARTUP] Ensuring schema...');
    await ensureSchema();
    console.log('[STARTUP] Schema initialization complete');
    
    // Start the server ONLY after schema is ready
    const PORT = process.env.PORT || 3000;
    console.log('[STARTUP] Starting Express server on port', PORT);
    app.listen(PORT, () => console.log(`[STARTUP] ✅ Backend running on port ${PORT}`));
  } catch (err) {
    console.error('[STARTUP] ❌ FAILED:', err && (err.stack || err.message || err));
    process.exit(1);
  }
})();
