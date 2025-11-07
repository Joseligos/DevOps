# 🚀 Monitoring Deployment Checklist

## Status Actual (6 Nov 2025)

✅ **Backend funcionando:**
- GET /healthz → HTTP 200 ✓
- GET /users → HTTP 200 ✓  
- POST /users → HTTP 200 ✓
- Data persiste en Railway ✓

⏳ **Métricas (en progreso):**
- GET /metrics → Aún no disponible
- Esperando que Render termine el build...

---

## Fase 1: Esperar Build de Render ⏳

1. **Tiempo estimado:** 5-10 minutos desde push
2. **Status page:** https://render.com/status
3. **Tu backend:** https://dashboard.render.com → tu app backend

Si ya pasaron 10 minutos sin éxito:
- [ ] Ver logs en Render dashboard (Logs tab)
- [ ] Buscar errores de `prom-client` o módulos faltantes

---

## Fase 2: Verificar Métricas (cuando esté listo)

```bash
# Paso 1: Verifica que /metrics existe
curl -i https://devops-crud-app-backend.onrender.com/metrics

# Esperado: HTTP 200 + métrica data

# Paso 2: Verifica que tiene contenido
curl https://devops-crud-app-backend.onrender.com/metrics | head -50

# Esperado: HELP lines, TYPE lines, métrica values

# Paso 3: Filtra una métrica específica
curl https://devops-crud-app-backend.onrender.com/metrics | grep http_requests_total

# Esperado: 
# http_requests_total{method="GET",route="/healthz",status="200"} 5
# http_requests_total{method="GET",route="/users",status="200"} 10
```

---

## Fase 3: Configurar Grafana Cloud

### 3.1 Crear Cuenta (5 min)
1. Ve a https://grafana.com/auth/sign-up/create-account
2. Sign up
3. Verifica email
4. Selecciona "Grafana Cloud"

### 3.2 Obtener Credenciales (2 min)
1. Dashboard → Connections → Prometheus
2. Copia:
   - Remote Write URL
   - Username
   - Password

### 3.3 Crear Prometheus Local (5 min)
```bash
cd /home/joseligo/DevOps

# Edita prometheus.yml y descomenta remote_write
# (reemplaza USERNAME y PASSWORD con tus datos)
nano prometheus.yml

# Inicia Prometheus en Docker
docker-compose -f prometheus-monitoring.yml up -d

# Verifica que está corriendo
curl http://localhost:9090/api/v1/query?query=up

# Esperado: JSON response con data
```

### 3.4 Verifica que scrapeando (2 min)
1. Abre http://localhost:9090 en browser
2. Status → Targets
3. Verifica que `backend-render` está `UP`

---

## Fase 4: Dashboard Grafana Cloud (10 min)

### 4.1 Crear Dashboard
1. Grafana Cloud → Dashboards → New → Dashboard
2. Add Panel

### 4.2 Panel 1: Requests/sec
```
Query: rate(http_requests_total[1m])
Legend: {{ method }} {{ route }}
```

### 4.3 Panel 2: Error Rate
```
Query: (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
Type: Gauge
Thresholds: Green 0-0.1, Yellow 0.1-1, Red 1+
```

### 4.4 Panel 3: P95 Latency
```
Query: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
Type: Stat
Unit: Seconds
```

### 4.5 Panel 4: Active Requests
```
Query: http_requests_active
Type: Gauge
```

---

## Fase 5: Alertas en Grafana (5 min)

### 5.1 Contact Point
1. Alerting → Contact Points → New
2. Type: Email
3. Agrega tu email

### 5.2 Regla 1: Error Rate > 5%
```
Condition: (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) > 0.05
For: 5m
Contact: tu email
```

### 5.3 Regla 2: P95 Latency > 1s
```
Condition: histogram_quantile(0.95, http_request_duration_seconds) > 1
For: 5m
Contact: tu email
```

---

## Fase 6: UptimeRobot (5 min)

### 6.1 Crear Cuenta
1. https://uptimerobot.com → Sign Up
2. Verifica email

### 6.2 Monitor 1: Health Check
- Name: Backend Health
- URL: https://devops-crud-app-backend.onrender.com/healthz
- Interval: 5 min
- Email Alert: ON

### 6.3 Monitor 2: GET /users
- Name: Backend Users Endpoint
- URL: https://devops-crud-app-backend.onrender.com/users
- Interval: 5 min

### 6.4 Monitor 3: Frontend
- Name: Frontend App
- URL: https://devops-crud-app-frontend.onrender.com
- Interval: 5 min

### 6.5 Monitor 4: Metrics Endpoint
- Name: Prometheus Metrics
- URL: https://devops-crud-app-backend.onrender.com/metrics
- Interval: 10 min

---

## Troubleshooting

**¿/metrics aún no funciona después de 15 min?**

Chequea el código:
```javascript
// En backend/index.js línea 1-5:
const promClient = require('prom-client');  // ← Si esta línea falla, eso es

// Solución:
npm install prom-client
git add package-lock.json
git commit -m "Update prom-client"
git push origin main
```

**Prometheus no ve métricas:**
```bash
# Verifica prometheus.yml
cat prometheus.yml | grep -A5 "backend-render"

# Si está comentado, descomenta:
# - job_name: 'backend-render'

# Reinicia Prometheus:
docker-compose -f prometheus-monitoring.yml restart prometheus
```

**Grafana no conecta:**
- Verifica credenciales en prometheus.yml
- Remote write URL debe ser exacto
- Username/Password sin espacios

---

## Next Steps

| Orden | Acción | Tiempo | Status |
|-------|--------|--------|--------|
| 1 | Esperar Render redeploy | 10 min | ⏳ En progreso |
| 2 | Verificar /metrics | 2 min | ⏳ Pendiente |
| 3 | Crear Grafana Cloud | 5 min | ⏳ Pendiente |
| 4 | Docker Prometheus local | 5 min | ⏳ Pendiente |
| 5 | Dashboard básico | 10 min | ⏳ Pendiente |
| 6 | Alertas | 5 min | ⏳ Pendiente |
| 7 | UptimeRobot | 5 min | ⏳ Pendiente |

**Total:** ~42 minutos para monitoring completo

---

## Verificación Final

Cuando todo esté listo:

```bash
# 1. Backend con métricas
curl https://devops-crud-app-backend.onrender.com/metrics | head -5
✅ Expectedoutput: HELP y TYPE lines

# 2. Grafana recibe datos
# Dashboard → Panel → ejecuta query
# ✅ Expected: gráficos con datos

# 3. UptimeRobot monitorea
# https://uptimerobot.com → Dashboard
# ✅ Expected: todos los monitores "UP"

# 4. Alertas funcionan
# Grafana → Alerting → Alert rules
# ✅ Expected: reglas en estado "Normal"
```

---

📊 **Resultado:** Monitoring profesional, alertas automáticas, uptime tracking 🎉
