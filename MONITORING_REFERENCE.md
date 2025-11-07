# 📊 Monitoring Quick Reference

## Arquitectura Monitoring

```
┌─────────────────────┐
│   Your Backend      │ ← Running in Render
│   (with Prometheus) │
└──────────┬──────────┘
           │ exports /metrics
           ↓
┌─────────────────────┐
│   Prometheus        │ ← Runs locally (scrapes /metrics)
│   (collects data)   │
└──────────┬──────────┘
           │ sends metrics
           ↓
┌─────────────────────────┐
│  Grafana Cloud          │ ← Visualizes + Alerts
│  (Remote Write URL)     │
└─────────────────────────┘

PLUS:

┌─────────────────────┐
│   UptimeRobot       │ ← External availability check (every 5 min)
│   (external check)  │
└─────────────────────┘
```

---

## Métricas Clave

| Métrica | Tipo | Query | Qué Mide |
|---------|------|-------|----------|
| `http_requests_total` | Counter | `rate(...[1m])` | Requests/sec |
| `http_request_duration_seconds` | Histogram | `histogram_quantile(0.95, ...)` | P95 latency |
| `http_requests_active` | Gauge | `http_requests_active` | Requests en progreso |
| `db_queries_total` | Counter | `rate(...[5m])` | DB queries/sec |
| `db_query_duration_seconds` | Histogram | `avg(rate(..._sum) / ...count)` | Promedio duración query |
| `errors_total` | Counter | `rate(...[5m])` | Errores/sec |

---

## Alertas Críticas

| Nombre | Condition | For | Action |
|--------|-----------|-----|--------|
| **HighErrorRate** | Error% > 5% | 5m | Email + Slack |
| **HighLatency** | P95 > 1s | 5m | Email |
| **SlowDB** | Avg query > 500ms | 10m | Email |
| **DowntimeCheck** | UptimeRobot Down | 1m | Email alert |

---

## Comandos Útiles

### Ver Métricas Raw

```bash
# Get all metrics from production
curl https://devops-crud-app-backend.onrender.com/metrics

# Filter specific metric
curl https://devops-crud-app-backend.onrender.com/metrics | grep http_requests_total

# Pretty print (jq required)
curl https://devops-crud-app-backend.onrender.com/metrics | grep http_requests_total | head -20
```

### Simular Traffic (para probar métricas)

```bash
# Generar 1000 requests en 10 segundos
for i in {1..1000}; do
  curl -s https://devops-crud-app-backend.onrender.com/users > /dev/null &
done
wait

# Luego ver métricas
curl https://devops-crud-app-backend.onrender.com/metrics | grep http_requests_total
```

### Probar Error Rate

```bash
# Enviar requests inválidos (para trigger error rate alert)
for i in {1..50}; do
  curl -X POST https://devops-crud-app-backend.onrender.com/users \
    -H "Content-Type: application/json" \
    -d '{}' > /dev/null &  # Empty body = 400 error
done
wait
```

---

## URLs de Acceso

| Servicio | URL | Login |
|----------|-----|-------|
| Grafana Cloud | https://grafana.com/login | tu email |
| Prometheus Local | http://localhost:9090 | (ninguno) |
| UptimeRobot | https://uptimerobot.com/login | tu email |
| Backend Metrics | https://devops-crud-app-backend.onrender.com/metrics | (público) |
| Backend Health | https://devops-crud-app-backend.onrender.com/healthz | (público) |

---

## Prometheus PromQL Cheatsheet

```
# Rate (cambio por segundo en 5 minutos)
rate(http_requests_total[5m])

# Percentile (P95 = 95th percentile)
histogram_quantile(0.95, http_request_duration_seconds)

# Sum (total)
sum(http_requests_total)

# By label (agrupar)
sum by (route) (http_requests_total)

# Filter (solo 5xx errors)
http_requests_total{status=~"5.."}

# Error rate (% de errores)
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100

# Average
avg(http_request_duration_seconds)

# Combined query (DB query time avg)
avg(rate(db_query_duration_seconds_sum[5m])) / avg(rate(db_query_duration_seconds_count[5m]))
```

---

## Grafana Dashboard Panels

### Panel: Requests per Second

```
Query: rate(http_requests_total[1m])
Visualization: Time series
Legend: {{ method }} {{ route }} {{ status }}
Refresh: 10s
```

### Panel: Error Rate Gauge

```
Query: (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
Visualization: Gauge
Unit: Percent
Thresholds: Green 0-0.5, Yellow 0.5-2, Red 2-100
```

### Panel: P95 Latency

```
Query: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
Visualization: Stat
Unit: Seconds
Decimals: 2
```

### Panel: Database Queries

```
Query: avg(rate(db_query_duration_seconds_sum[5m])) / avg(rate(db_query_duration_seconds_count[5m]))
Visualization: Time series
Legend: {{ query_type }}
```

---

## SLO Queries

### 99.9% Uptime (30 días)

```
(1 - (sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d])))) * 100
```

Should return > 99.9

### P99 Latency < 200ms

```
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[30d]))
```

Should return < 0.2 seconds

### Error Rate < 0.1%

```
(sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d]))) * 100
```

Should return < 0.1

---

## Checklist Verification

```bash
# Step 1: Backend está running?
curl -i https://devops-crud-app-backend.onrender.com/healthz
# Expected: HTTP 200

# Step 2: Prometheus endpoint existe?
curl -i https://devops-crud-app-backend.onrender.com/metrics | head -20
# Expected: HTTP 200, HELP lines visible

# Step 3: Métricas tienen datos?
curl https://devops-crud-app-backend.onrender.com/metrics | grep -E "http_requests_total|db_queries"
# Expected: counter values > 0

# Step 4: Grafana Cloud conecta?
# Dashboard → Data Sources → Prometheus
# Expected: "Connected" badge

# Step 5: UptimeRobot monitorea?
# https://uptimerobot.com → Dashboard
# Expected: All monitors "UP"
```

---

## Troubleshooting Matrix

| Síntoma | Causa Probable | Fix |
|---------|---|---|
| No veo métricas en /metrics | Backend no redeploy | git push & espera 5 min |
| Métricas pero sin datos | Prometheus no scrapeando | Verifica prometheus.yml |
| Grafana shows no data | Remote write URL inválida | Copia credenciales de nuevo |
| Alertas no disparan | Threshold muy alto | Baja threshold 50% y prueba |
| UptimeRobot says DOWN | Render en maintenance | Verifica logs en Render |

---

## Performance Targets

| Metric | Target | Alert If |
|--------|--------|----------|
| Request Rate | 10-100 req/s | Consistently > 500 req/s |
| P50 Latency | < 100ms | > 500ms |
| P95 Latency | < 200ms | > 1s |
| P99 Latency | < 500ms | > 2s |
| Error Rate | < 0.1% | > 1% |
| Availability | 99.9% | < 99% monthly |
| DB Query Avg | < 50ms | > 500ms |

---

## Next Steps

1. **Immediate:** Deploy metrics to Render ✅ (in progress)
2. **Next:** Verify /metrics endpoint returns data
3. **After:** Create Grafana Cloud account
4. **Then:** Create first dashboard (5 panels)
5. **Finally:** Set up UptimeRobot (4 monitors)

---

📊 Monitoring Professional = Peace of Mind 🎉
