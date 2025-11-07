# 🎨 Grafana Cloud Setup - Paso a Paso

## 1. Crear Cuenta Grafana Cloud

### 1.1 Sign Up

1. Ve a: https://grafana.com/auth/sign-up/create-account
2. Llena el formulario:
   - Email: tu email
   - Password: contraseña segura
   - First Name: tu nombre
   - Company: tu empresa (opcional)
3. Click "Complete Signup"
4. Verifica tu email (click en enlace)

### 1.2 Selecciona "Grafana Cloud"

Después de verificar email:
1. Click "Grafana Cloud" (selecciona la opción Free)
2. Enter Organization Name: `DevOps-CRUD`
3. Click "Create Stack"

**Espera 2-3 minutos a que se cree el stack**

---

## 2. Obtener Credenciales Prometheus Remote Write

### 2.1 Acceder al Dashboard

1. Cuando esté listo, irás automáticamente al dashboard
2. En la barra lateral izquierda, click **"Connections"**
3. Busca **"Prometheus"** en la lista
4. Click en "Prometheus"

### 2.2 Copiar URL y Credenciales

Verás una pantalla con:

```
Remote Write URL: https://prometheus-blocks-prod-us-central1.grafana-blocks.grafana.io/api/prom/push
Username: Your-Grafana-ID (como: 123456)
Password: xxxxxxxxx (token largo)
```

**Copia estos valores, los necesitaremos después.**

---

## 3. Configurar Prometheus Remote Write en Render

Como tu backend en Render necesita enviar métricas a Grafana, vamos a usar un **sidecar Prometheus** con Docker Compose.

### 3.1 Crear archivo `prometheus-docker-compose.yml`

Este archivo es para ejecutar **en tu máquina local** para probar antes de ponerlo en producción.

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring

  # Grafana (opcional, para ver dashboards localmente)
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
```

### 3.2 Crear archivo `prometheus.yml`

Este archivo le dice a Prometheus dónde traer las métricas:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Remote write to Grafana Cloud
remote_write:
  - url: https://prometheus-blocks-prod-us-central1.grafana-blocks.grafana.io/api/prom/push
    basic_auth:
      username: YOUR_GRAFANA_USERNAME
      password: YOUR_GRAFANA_PASSWORD

scrape_configs:
  - job_name: 'render-backend'
    # Scrape from tu backend en Render
    static_configs:
      - targets: ['devops-crud-app-backend.onrender.com:443']
    scheme: https
    scrape_interval: 30s
    # Para desarrollo local:
    # - targets: ['localhost:3000']
    # scheme: http

  - job_name: 'prometheus-self'
    # Prometheus se monitorea a sí mismo
    static_configs:
      - targets: ['localhost:9090']
```

### 3.3 Reemplaza credenciales

En `prometheus.yml`, reemplaza:
- `YOUR_GRAFANA_USERNAME`: tu Grafana Username (número)
- `YOUR_GRAFANA_PASSWORD`: tu token (la contraseña larga)

**NO commits esto a git (tiene credenciales).**

---

## 4. Probar Localmente (Opcional)

```bash
# En la carpeta /home/joseligo/DevOps
docker-compose -f prometheus-docker-compose.yml up -d

# Ver logs
docker-compose -f prometheus-docker-compose.yml logs prometheus

# Acceder a Prometheus UI
open http://localhost:9090

# Acceder a Grafana (si incluiste el servicio)
open http://localhost:3000
# Login: admin / admin
```

---

## 5. Verificar Que Métricas Llegan a Grafana

### 5.1 Dashboard Grafana Cloud

1. Ve a tu Grafana Cloud dashboard: https://grafana-blocks-prod.grafana.net/
2. Login con tu email y password
3. En la izquierda, click **"Dashboards"** → **"Browse"**
4. Si ves datos llegando, verás gráficos con:
   - `http_requests_total`
   - `http_request_duration_seconds`
   - `db_queries_total`
   - etc.

---

## 6. Crear tu Primer Dashboard

### 6.1 Crear nuevo Dashboard

1. Click el icono **"+"** en la izquierda
2. Click **"Dashboard"**
3. Click **"Add a new panel"**

### 6.2 Panel 1: Requests por Segundo

1. En "Metrics", escribe:
```
rate(http_requests_total[1m])
```

2. En "Legend", selecciona:
   - `{{ method }}` - `{{ route }}` - `{{ status }}`

3. Visualization: "Time series"

4. Title: "Requests/sec"

5. Click "Save"

### 6.3 Panel 2: Error Rate (%)

1. New Panel
2. Metrics:
```
(sum(rate(http_requests_total{status=~"5.."}[5m])) by (route)) 
/ 
(sum(rate(http_requests_total[5m])) by (route)) 
* 100
```

3. Visualization: "Gauge"
4. Title: "Error Rate (%)"
5. Unit: "Percent (0-100)"
6. Thresholds: Green 0-0.1, Yellow 0.1-1, Red 1-100

### 6.4 Panel 3: P95 Latencia

1. New Panel
2. Metrics:
```
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

3. Visualization: "Stat"
4. Title: "P95 Latency (s)"
5. Unit: "Seconds"

### 6.5 Panel 4: DB Query Duration

1. New Panel
2. Metrics:
```
avg(rate(db_query_duration_seconds_sum[5m])) / avg(rate(db_query_duration_seconds_count[5m]))
```

3. Visualization: "Time series"
4. Title: "Avg Query Duration (s)"

---

## 7. Crear Alertas

### 7.1 Configurar Contact Point

1. En la izquierda, click **"Alerting"** → **"Contact points"**
2. Click **"New contact point"**
3. Name: `email-alert`
4. Type: `Email`
5. Email addresses: tu email
6. Click "Save"

### 7.2 Crear Regla de Alerta 1: Error Rate Alto

1. Click **"Alerting"** → **"Alert rules"**
2. Click **"Create new alert rule"**
3. **Rule name:** `HighErrorRate`
4. **Condition:**
```
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05
```
5. **For:** `5m`
6. **Annotations:**
   - Summary: "Error rate above 5%"
   - Description: "Check backend logs immediately"
7. **Contact point:** `email-alert`
8. Click "Save rule"

### 7.3 Crear Regla 2: P95 Latencia Alta

1. **Rule name:** `HighLatency`
2. **Condition:**
```
histogram_quantile(0.95, http_request_duration_seconds) > 1
```
3. **For:** `5m`
4. **Annotations:**
   - Summary: "P95 latency above 1 second"
5. Click "Save rule"

### 7.4 Crear Regla 3: DB Queries Lentas

1. **Rule name:** `SlowDatabaseQueries`
2. **Condition:**
```
avg(rate(db_query_duration_seconds_sum[5m])) / avg(rate(db_query_duration_seconds_count[5m])) > 0.5
```
3. **For:** `5m`
4. **Annotations:**
   - Summary: "Database queries averaging > 500ms"
5. Click "Save rule"

---

## 8. Variables del Dashboard

Para hacer dashboards más interactivos:

### 8.1 Agregar variable

1. Click el engranaje (⚙️) arriba a la derecha
2. Click **"Variables"**
3. Click **"New variable"**
4. **Name:** `route`
5. **Type:** `Query`
6. **Data source:** `Prometheus`
7. **Query:**
```
label_values(http_requests_total, route)
```
8. Click "Save"

Ahora puedes filtrar paneles por ruta.

---

## 9. Notificaciones en Slack (Avanzado)

### 9.1 Crear Webhook en Slack

1. Ve a tu Slack workspace
2. Settings → Manage Apps → Build
3. Create an App → From Scratch
4. Name: `Grafana Alerts`
5. En "Incoming Webhooks", crea uno nuevo
6. Copia la URL

### 9.2 Agregar Slack a Grafana

1. En Grafana, **Alerting** → **Contact points**
2. **New contact point**
3. Name: `slack-alert`
4. Type: `Slack`
5. Webhook URL: [pega la URL de Slack]
6. Click "Save"

### 9.3 Usar Slack en alertas

En cualquier alert rule, selecciona `slack-alert` como contact point.

---

## 10. SLO Dashboard

Crea un dashboard separado para SLOs:

### Panel 1: Uptime 30 días

```
(1 - (sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d])))) * 100
```

Target: 99.9%

### Panel 2: P99 latencia

```
histogram_quantile(0.99, http_request_duration_seconds)
```

Target: < 200ms

### Panel 3: Error rate 30d

```
sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d])) * 100
```

Target: < 0.1%

---

## ✅ Checklist

- [ ] Cuenta Grafana Cloud creada
- [ ] Prometheus Remote Write URL obtenida
- [ ] prometheus.yml creado (credenciales reemplazadas)
- [ ] Primer dashboard creado
- [ ] 3 paneles básicos agregados (requests, latency, error rate)
- [ ] Email contact point configurado
- [ ] 3 alert rules creadas
- [ ] Recibiste email de alerta de prueba
- [ ] (Opcional) Slack integrado
- [ ] (Opcional) SLO dashboard creado

---

## 🆘 Troubleshooting

**No veo métricas en Grafana:**
- Verifica que el backend redeploy completó en Render
- Espera 2-3 minutos a que Prometheus sincronice
- Verifica que `prometheus.yml` tiene credenciales correctas

**Alertas no se envían:**
- Verifica email spam
- En Alert rules, haz click "Test" para enviar alerta manual
- Verifica que Contact point está guardado

**Prometheus local no conecta a Render:**
- Verifica que Render no está en maintenance
- Intenta: `curl https://devops-crud-app-backend.onrender.com/metrics`
- Verifica firewall/VPN

---

Ahora tienes monitoring profesional 🎉
