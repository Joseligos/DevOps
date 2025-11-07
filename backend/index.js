// Backend API with Prometheus metrics
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const promClient = require('prom-client');

const app = express();

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// ========== PROMETHEUS METRICS SETUP ==========

// Create a Registry (collects all metrics)
const register = new promClient.Registry();

// Default metrics (CPU, memory, etc)
promClient.collectDefaultMetrics({ register });

// Custom Counter: Total HTTP requests
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

// Custom Histogram: HTTP request duration
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.5, 1, 2, 5],
  registers: [register]
});

// Custom Gauge: Active requests
const httpRequestsActive = new promClient.Gauge({
  name: 'http_requests_active',
  help: 'Number of active HTTP requests',
  registers: [register]
});

// Custom Counter: Database queries
const dbQueriesTotal = new promClient.Counter({
  name: 'db_queries_total',
  help: 'Total database queries',
  labelNames: ['query_type', 'status'],
  registers: [register]
});

// Custom Histogram: Database query duration
const dbQueryDuration = new promClient.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Database query duration in seconds',
  labelNames: ['query_type'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1],
  registers: [register]
});

// Custom Counter: Errors
const errorsTotal = new promClient.Counter({
  name: 'errors_total',
  help: 'Total errors',
  labelNames: ['type', 'endpoint'],
  registers: [register]
});

// ========== MIDDLEWARE ==========

// Middleware to track request metrics
app.use((req, res, next) => {
  const startTime = Date.now();
  httpRequestsActive.inc();
  
  // Track when response is sent
  res.on('finish', () => {
    const duration = (Date.now() - startTime) / 1000;
    httpRequestsActive.dec();
    httpRequestsTotal.labels(req.method, req.route?.path || req.path, res.statusCode).inc();
    httpRequestDuration.labels(req.method, req.route?.path || req.path, res.statusCode).observe(duration);
  });
  
  next();
});

// ========== DATABASE CONNECTION ==========

console.log('[STARTUP] Initializing database connection pool...');
console.log('[STARTUP] DATABASE_URL:', process.env.DATABASE_URL ? 'SET' : 'NOT SET');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

console.log('[STARTUP] Pool created, ready to connect on first query');

// ========== SCHEMA INITIALIZATION ==========

async function ensureSchema() {
  try {
    console.log('[SCHEMA] Attempting to create users table...');
    const createTableSQL = `CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL);`;
    console.log('[SCHEMA] SQL:', createTableSQL);
    
    const startTime = Date.now();
    const result = await pool.query(createTableSQL);
    const duration = (Date.now() - startTime) / 1000;
    
    dbQueryDuration.labels('create_table').observe(duration);
    dbQueriesTotal.labels('create_table', 'success').inc();
    
    console.log('[SCHEMA] CREATE TABLE succeeded. Result:', { command: result.command, rowCount: result.rowCount });
    
    // Verify table exists
    const verifySQL = `SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users')`;
    const verifyResult = await pool.query(verifySQL);
    console.log('[SCHEMA] Table verification:', verifyResult.rows[0]);
    console.log('[SCHEMA] ✅ users table is ready');
  } catch (err) {
    console.error('[SCHEMA] ❌ CRITICAL: Failed to ensure DB schema:', err);
    console.error('[SCHEMA] Error details:', { code: err.code, message: err.message, severity: err.severity });
    errorsTotal.labels('schema_initialization', '/schema').inc();
    throw err;
  }
}

// ========== ENDPOINTS ==========

// Prometheus metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(register.metrics());
});

// Health check endpoint
app.get('/healthz', (req, res) => res.json({ status: 'ok' }));

// Get all users
app.get('/users', async (req, res, next) => {
  try {
    const startTime = Date.now();
    const { rows } = await pool.query('SELECT * FROM users');
    const duration = (Date.now() - startTime) / 1000;
    
    dbQueryDuration.labels('select').observe(duration);
    dbQueriesTotal.labels('select', 'success').inc();
    
    return res.json(rows);
  } catch (err) {
    dbQueriesTotal.labels('select', 'error').inc();
    errorsTotal.labels('database', '/users').inc();
    next(err);
  }
});

// Create new user
app.post('/users', async (req, res, next) => {
  try {
    const { name } = req.body;
    if (!name || typeof name !== 'string') {
      return res.status(400).json({ error: 'name_required' });
    }

    const startTime = Date.now();
    const { rows } = await pool.query(
      'INSERT INTO users(name) VALUES($1) RETURNING *',
      [name]
    );
    const duration = (Date.now() - startTime) / 1000;
    
    dbQueryDuration.labels('insert').observe(duration);
    dbQueriesTotal.labels('insert', 'success').inc();
    
    return res.json(rows[0]);
  } catch (err) {
    dbQueriesTotal.labels('insert', 'error').inc();
    errorsTotal.labels('database', '/users').inc();
    next(err);
  }
});

// Generic error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err && (err.stack || err.message || err));
  
  if (res.headersSent) return next(err);
  
  errorsTotal.labels('unhandled', req.path).inc();
  res.status(500).json({ error: 'internal_server_error' });
});

// ========== ERROR HANDLERS ==========

process.on('unhandledRejection', (reason) => {
  console.error('unhandledRejection:', reason);
  errorsTotal.labels('unhandledRejection', 'process').inc();
});

process.on('uncaughtException', (err) => {
  console.error('uncaughtException:', err && (err.stack || err.message || err));
  errorsTotal.labels('uncaughtException', 'process').inc();
  setTimeout(() => process.exit(1), 1000);
});

// ========== STARTUP ==========

(async () => {
  try {
    console.log('[STARTUP] IIFE started, beginning startup sequence...');
    console.log('[STARTUP] Checking DB connection...');
    await pool.query('SELECT 1');
    console.log('[STARTUP] DB connection OK');
    
    console.log('[STARTUP] Ensuring schema...');
    await ensureSchema();
    console.log('[STARTUP] Schema initialization complete');
    
    const PORT = process.env.PORT || 3000;
    console.log('[STARTUP] Starting Express server on port', PORT);
    app.listen(PORT, () => console.log(`[STARTUP] ✅ Backend running on port ${PORT}`));
  } catch (err) {
    console.error('[STARTUP] ❌ FAILED:', err && (err.stack || err.message || err));
    errorsTotal.labels('startup_failed', 'main').inc();
    process.exit(1);
  }
})();
