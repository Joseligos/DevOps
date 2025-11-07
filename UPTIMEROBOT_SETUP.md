# 🤖 UptimeRobot Setup - Monitoreo Externo

## 1. ¿Qué es UptimeRobot?

**UptimeRobot** es un servicio que monitorea desde **afuera** si tu app está disponible.

- ✅ Verifica que tu app responde (HTTP 200)
- ✅ Te alerta por email si cae
- ✅ Gratis hasta 50 monitores
- ✅ Historial de uptime (últimos 3 meses visible gratis)

---

## 2. Crear Cuenta

1. Ve a: https://uptimerobot.com/
2. Click **"Sign Up For Free"**
3. Email y password
4. Click "Create account"
5. Verifica tu email

---

## 3. Agregar Primer Monitor

### 3.1 Dashboard UptimeRobot

1. Login en https://uptimerobot.com
2. Click **"Add New Monitor"** (botón azul)

### 3.2 Configurar Monitor 1: Backend Health Check

**Type:** HTTP(s)

**Friendly Name:** `Backend Health - PROD`

**URL:** `https://devops-crud-app-backend.onrender.com/healthz`

**Monitoring Interval:** `5 minutes` (enough for free tier)

**Timeout:** `30 seconds`

**Request Method:** `GET`

**Send Email Alert At:** `Downed` (cuando falla)

**Alert Contacts:** Tu email (ya está configurado)

Click **"Create Monitor"**

---

## 4. Agregar Más Monitores

### Monitor 2: GET /users Endpoint

**Friendly Name:** `Backend GET /users`

**URL:** `https://devops-crud-app-backend.onrender.com/users`

**Expected Response Code:** `200`

Click **"Create Monitor"**

### Monitor 3: Frontend Health

**Friendly Name:** `Frontend App - PROD`

**URL:** `https://devops-crud-app-frontend.onrender.com/`

**Expected Response Code:** `200`

Click **"Create Monitor"**

### Monitor 4: POST /users (Status Endpoint)

**Friendly Name:** `Backend POST /users`

**URL:** `https://devops-crud-app-backend.onrender.com/metrics`

**Expected Response Code:** `200` (verifica que métricas están disponibles)

Click **"Create Monitor"**

---

## 5. Configurar Email Alerts

### 5.1 Alert Contacts

1. En la izquierda, click **"Integrations"** → **"Alert Contacts"**
2. Click **"Add alert contact"**
3. **Type:** Email
4. **Email address:** tu email
5. Click **"Save"**

### 5.2 Usar en Monitor

Cuando crees un monitor, selecciona este email contact en "Alert Contacts".

---

## 6. Verificar Monitores

1. Click en cualquier monitor para ver detalles
2. Verás:
   - Status actual (Up/Down)
   - Last checked time
   - Average response time
   - Uptime % (últimos 30 días)
   - Gráfico de availability

---

## 7. Más Monitores Avanzados (Opcional)

### Monitor con Body Validation

Si quieres verificar que la respuesta JSON contiene datos:

**Friendly Name:** `Users endpoint returns data`

**URL:** `https://devops-crud-app-backend.onrender.com/users`

**Request Method:** `GET`

**HTTP Custom Headers:** (déjalo vacío por ahora)

**HTTP Custom Body:** (para POST, si lo necesitas)

**Alert Contacts:** tu email

Click **"Create Monitor"**

---

## 8. Maintenance Windows

Si necesitas actualizar tu app sin que UptimeRobot te alerte:

1. Click en el monitor
2. Click **"Maintenance Windows"**
3. **Start Date/Time:** cuando empieza el mantenimiento
4. **Duration:** cuánto tiempo va a durar
5. Click **"Save"**

UptimeRobot no enviará alertas durante ese período.

---

## 9. Webhook Alerts (Avanzado)

Para recibir alertas en Slack/Discord:

### 9.1 Crear Webhook en Slack

1. Ve a tu Slack workspace settings
2. Apps → Build → Create
3. Create App → From Scratch
4. Name: `UptimeRobot`
5. Copy el **Webhook URL**

### 9.2 Agregar a UptimeRobot

1. UptimeRobot → **Integrations** → **Alert Contacts**
2. Click **"Add Alert Contact"**
3. **Type:** Webhook
4. **Name:** `Slack Alerts`
5. **URL:** pega tu Slack Webhook URL
6. Click **"Save"**

### 9.3 Usar en Monitores

Selecciona "Slack Alerts" cuando crees monitores.

---

## 10. Dashboard Público (Opcional)

Puedes compartir un dashboard de uptime públicamente:

### 10.1 Crear Status Page

1. Click **"Uptime Monitor"** en el sidebar
2. Click **"Create Public Status Page"** (si no existe)
3. **Page Title:** `DevOps CRUD Status`
4. **Page Domain:** se genera automáticamente
5. Agrega tus monitores
6. Click **"Save"**

### 10.2 Compartir

Tu status page estará en: `https://your-domain.statuspage.io/`

Puedes compartirla con tus usuarios.

---

## 11. Integración con Grafana Alerts

Para un setup más robusto:

1. En Grafana, crea alertas (ver GRAFANA_SETUP.md)
2. En UptimeRobot, configura monitores básicos
3. **Resultado:** Doble monitoreo
   - Grafana: métricas internas (latencia, errores)
   - UptimeRobot: disponibilidad externa (¿responde?)

---

## 12. Estadísticas & Reporting

### 12.1 Ver Estadísticas

1. Click en un monitor
2. Scroll down para ver:
   - Uptime % (últimos 30 días)
   - Average response time
   - Response times graph
   - Downtime events (historial)

### 12.2 Export Reports

UptimeRobot ofrece reportes mensuales en la versión Pro, pero en gratis ves:
- Historial de eventos
- Gráficos de uptime
- Average response times

---

## ✅ Checklist

- [ ] Cuenta UptimeRobot creada
- [ ] Email verificado
- [ ] Monitor 1: Backend /healthz agregado
- [ ] Monitor 2: Backend /users agregado
- [ ] Monitor 3: Frontend agregado
- [ ] Monitor 4: Metrics endpoint agregado
- [ ] Recibiste email de verificación de monitor
- [ ] (Opcional) Alert contact de Slack agregado
- [ ] (Opcional) Public Status Page creada
- [ ] Todos los monitores muestran "Up" ✅

---

## 🆘 Troubleshooting

**UptimeRobot reporta "Down":**

```bash
# Verifica manualmente que el endpoint responde
curl -i https://devops-crud-app-backend.onrender.com/healthz

# Si no responde, verifica en Render dashboard
# Dashboard → backend service → Logs
```

**No recibo emails de UptimeRobot:**

- Revisa spam/promotions
- Verifica en UptimeRobot que tu email está confirmado
- En Alert Contacts, haz click "Send Test Alert"

**Demasiadas falsas alarmas:**

- Aumenta el **Monitoring Interval** a 10-15 minutos
- Agrega un segundo check para confirmar down

---

## 📊 Reporte Típico

Después de 30 días:

```
Backend Health Check:
- Uptime: 99.87%
- Downtime: 1.87 horas
- Average Response Time: 850ms
- Most Recent Downtime: 12 mins (Oct 15 3:00 AM)

Frontend:
- Uptime: 99.95%
- Downtime: 22 minutos
- Average Response Time: 320ms
```

---

¡Tu app ahora está monitoreada externamente 🎉
