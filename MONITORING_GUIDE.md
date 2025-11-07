# 📊 Monitoring Completo - Guía Práctica

## 🎯 Objetivo

Monitorear tu app en Render con:
- ✅ **Prometheus** - Recolecta métricas
- ✅ **Grafana Cloud** - Visualiza datos (gratis)
- ✅ **Alertas** - Te notifica si algo falla
- ✅ **UptimeRobot** - Monitorea disponibilidad externa

**Ventaja:** Detectas problemas ANTES que tus usuarios

---

## 📋 Paso 1: Entender las Métricas

### Tipos de Métricas

```
Counter:   Nunca baja. Ej: total de requests (siempre sube)
Gauge:     Puede subir/bajar. Ej: memoria usada
Histogram: Distribuye valores. Ej: tiempo de respuesta
Summary:   Percentiles. Ej: p50, p95, p99 latencia
```

### Métricas Principales para tu App

```
http_requests_total        → Total requests (Counter)
http_request_duration_seconds → Tiempo de respuesta (Histogram)
http_requests_active       → Requests activos ahora (Gauge)
db_connections_used        → Conexiones DB activas (Gauge)
db_query_duration_seconds  → Tiempo queries DB (Histogram)
errors_total               → Errores totales (Counter)
```

---

## 🔧 Paso 2: Agregar Prometheus a tu Backend

### 2.1 Instalar paquete

```bash
cd /home/joseligo/DevOps/backend
npm install prom-client
```

### 2.2 Configurar Prometheus en backend/index.js

El código irá en tu `backend/index.js` (ver próxima sección)

---

## 📝 Paso 3: Código de Backend con Prometheus

Reemplaza tu `backend/index.js` con esto:

```javascript
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
```

---

## 📤 Paso 4: Deploy a Render

```bash
git add backend/index.js backend/package.json
git commit -m "Add Prometheus metrics to backend"
git push origin main
```

Render redeploya automáticamente (5 minutos).

---

## 🔗 Paso 5: Verificar Métricas en Render

Una vez deployado:

```bash
# Ver métricas raw
curl https://devops-crud-app-backend.onrender.com/metrics | head -50

# Deberías ver algo como:
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
# http_requests_total{method="GET",route="/users",status="200"} 5
```

---

## 🎨 Paso 6: Configurar Grafana Cloud

### 6.1 Crear cuenta

1. Ve a: https://grafana.com/auth/sign-up/create-account
2. Sign up gratis
3. Elige "Grafana Cloud"

### 6.2 Obtener credenciales Prometheus

1. En Grafana Cloud dashboard
2. Click "Connections" → "Prometheus"
3. Copia el "Remote Write URL"
4. Copia el "Username" y "Password"

### 6.3 Configurar Prometheus remoto en tu backend

Necesitamos un **Prometheus servidor** que lea tu app y envíe a Grafana.

Vamos a usar un contenedor Docker local o un agente simple.

**Opción Fácil - Usar Render environment variables:**

Crea un archivo `.env` (NO lo commits):

```
GRAFANA_PROMETHEUS_URL=https://prometheus-blocks-prod-xxxxx.grafana-blocks.grafana.io
GRAFANA_USERNAME=xxx@xxx
GRAFANA_PASSWORD=xxxxx
```

---

## 📊 Paso 7: Crear Dashboards en Grafana

### Panel 1: Requests por segundo

```
Query: rate(http_requests_total[1m])
Visualization: Graph
```

### Panel 2: P95 latencia

```
Query: histogram_quantile(0.95, http_request_duration_seconds)
Visualization: Gauge
```

### Panel 3: Error rate

```
Query: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100
Visualization: Percentage
```

### Panel 4: DB queries duration

```
Query: avg(rate(db_query_duration_seconds_sum[5m])) / avg(rate(db_query_duration_seconds_count[5m]))
Visualization: Graph
```

---

## 🚨 Paso 8: Configurar Alertas

### Alerta 1: Error rate > 5%

```
name: HighErrorRate
expr: (rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])) > 0.05
for: 5m
annotations:
  summary: "Error rate above 5%"
```

### Alerta 2: P95 latencia > 1s

```
name: HighLatency
expr: histogram_quantile(0.95, http_request_duration_seconds) > 1
for: 5m
annotations:
  summary: "P95 latency above 1 second"
```

### Alerta 3: Database queries lentas

```
name: SlowDatabaseQueries
expr: avg(rate(db_query_duration_seconds_sum[5m])) > 0.5
for: 5m
annotations:
  summary: "Database queries averaging > 500ms"
```

---

## 🤖 Paso 9: UptimeRobot - Monitoreo Externo

UptimeRobot verifica que tu app esté **siempre disponible** desde afuera.

### 9.1 Crear cuenta

1. Ve a: https://uptimerobot.com
2. Sign up gratis
3. Máximo 50 monitores (suficiente)

### 9.2 Agregar monitoreo

1. Click "Add New Monitor"
2. **Type:** HTTP(S)
3. **URL:** https://devops-crud-app-backend.onrender.com/healthz
4. **Check interval:** 5 minutos

### 9.3 Agregar alertas

1. Click "Alert Contacts"
2. Agrega tu email o Slack
3. Recibirás notificación si cae

### 9.4 Múltiples endpoints

Agrega monitores para:
- Backend health: `https://...backend.../healthz`
- Frontend: `https://...frontend...`
- GET users: `https://...backend.../users`
- POST users: Crea un monitor para verificar que POST funciona

---

## 📈 Paso 10: SLOs (Service Level Objectives)

Define objetivos de disponibilidad y performance:

### SLO 1: 99.9% disponibilidad

```
Objetivo: 99.9% requests < 5s
Ventana: 30 días
Alertar si: < 99% en ventana actual
```

### SLO 2: P95 latencia < 200ms

```
Objetivo: 95% de requests < 200ms
Ventana: 24 horas
Alertar si: > 300ms
```

### SLO 3: Error rate < 0.1%

```
Objetivo: < 0.1% errores
Ventana: 24 horas
Alertar si: > 0.5%
```

---

## 📋 Comandos Útiles

```bash
# Ver métricas localmente (después de deploy)
curl https://devops-crud-app-backend.onrender.com/metrics | grep -E "http_requests_total|db_query"

# Simular traffic para probar métricas
for i in {1..100}; do
  curl https://devops-crud-app-backend.onrender.com/users > /dev/null
done

# Ver error rate
curl https://devops-crud-app-backend.onrender.com/metrics | grep errors_total
```

---

## 🎯 Dashboard Recomendado

Crea un dashboard en Grafana con:

1. **Status Panel** - ¿Está la app en línea? (color verde/rojo)
2. **Request Rate** - Requests por segundo (línea)
3. **Latency** - P50, P95, P99 (línea)
4. **Error Rate** - % de errores (gauge)
5. **Database** - Queries/sec, duración (línea)
6. **Memory** - Uso de RAM (gauge)
7. **CPU** - Uso de CPU (gauge)
8. **UptimeRobot Status** - % de uptime mes (número)

---

## ✅ Checklist

- [ ] Agregaste `prom-client` a backend
- [ ] Actualizaste `backend/index.js` con métricas
- [ ] Deployaste a Render
- [ ] Verificaste `/metrics` endpoint
- [ ] Creaste cuenta Grafana Cloud
- [ ] Configuraste conexión Prometheus
- [ ] Creaste dashboard
- [ ] Creaste alertas
- [ ] Configuraste UptimeRobot
- [ ] Definiste SLOs

---

## 🆘 Troubleshooting

**No veo métricas en /metrics:**
```bash
# Verifica que el endpoint existe
curl https://devops-crud-app-backend.onrender.com/metrics

# Verifica los logs en Render
# Dashboard → backend service → Logs
```

**Grafana no ve datos:**
```
- Verifica que Render redeploy completó
- Verifica que URL de Prometheus es correcta
- Espera 2-3 minutos a que Grafana sincronice
```

**UptimeRobot reporta down:**
```
- Verifica que tu backend está activo en Render
- Verifica CORS: curl -i https://backend.../healthz
- Revisa logs en Render para ver qué falla
```

---

## 🚀 Próximos Pasos

1. **Integrar Slack** - Alertas en Slack en lugar de email
2. **Grafana Loki** - Logs agregados (gratuito)
3. **Tracing** - Con Jaeger (ver cómo fluyen requests)
4. **Custom Alerts** - Basadas en business metrics

¡Felicitaciones! Ya tienes **monitoring profesional** 🎉
