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

// Get all users from the database
app.get('/users', async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM users'); // Query the users table
  res.json(rows); // Send users as JSON
});

// Add a new user to the database
app.post('/users', async (req, res) => {
  const { name } = req.body; // Get name from request body
  // Insert user and return the new record
  const { rows } = await pool.query('INSERT INTO users(name) VALUES($1) RETURNING *', [name]);
  res.json(rows[0]); // Send the new user as JSON
});

// Start the server on the port specified by Render or default to 3000
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
