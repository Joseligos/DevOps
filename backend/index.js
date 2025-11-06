const express = require('express'); // Import Express for building the API
const cors = require('cors'); // Import CORS to allow frontend access
const { Pool } = require('pg'); // Import PostgreSQL client
const app = express(); // Create an Express app

// Enable CORS for all origins (adjust in production)
app.use(cors());
app.use(express.json()); // Parse JSON request bodies

// Connect to PostgreSQL using DATABASE_URL from environment variables
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

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

// Start the server on the port specified by Render or default to 3000
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));

// Log unhandled promise rejections and uncaught exceptions so they appear in Render logs
process.on('unhandledRejection', (reason) => {
  console.error('unhandledRejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('uncaughtException:', err && (err.stack || err.message || err));
  // Allow logs to flush and then exit so the platform can restart the process.
  setTimeout(() => process.exit(1), 1000);
});

// Optional quick DB connectivity check at startup (logged, non-fatal)
pool.query('SELECT 1').then(() => {
  console.log('DB connection OK');
}).catch((err) => {
  console.error('DB connectivity check failed:', err && (err.stack || err.message || err));
});
