# 🎨 Grafana Cloud Setup - Guía Paso a Paso Completa

## ⏱️ Tiempo Total: ~30 minutos

---

## 📋 Paso 1: Crear Cuenta Grafana Cloud (5 min)

### 1.1 Sign Up
1. Abre: **https://grafana.com/auth/sign-up/create-account**
2. Completa el formulario:
   ```
   Email:      tu-email@gmail.com
   Password:   contraseña-segura
   First Name: Tu Nombre
   Company:    (opcional)
   ```
3. Click **"Complete Signup"**

### 1.2 Verifica tu Email
- Abre tu email
- Haz click en el enlace de verificación
- Serás redirigido a Grafana Cloud

### 1.3 Crea Stack
1. En la página de bienvenida, verás una opción para crear "Stack"
2. Rellena:
   ```
   Organization Name: DevOps-CRUD
   Stack Name: metrics (se genera automáticamente)
   Region: (elige tu región más cercana)
   ```
3. Click **"Create Stack"**

**Espera 2-3 minutos a que se cree el stack...**

---

## 🔑 Paso 2: Obtener Credenciales Prometheus (3 min)

### 2.1 Acceder al Dashboard
Una vez que el stack esté listo, serás redirigido automáticamente.

Si no:
1. Login en: **https://grafana.com/login**
2. Usa tu email y password

### 2.2 Encontrar Prometheus Settings
1. En la barra lateral izquierda, click **"Connections"**

![Connections Menu](https://i.imgur.com/xxx.png)

2. Busca **"Prometheus"** en la lista (o usa el search)

3. Click en **"Prometheus"** (el data source)

### 2.3 Copiar Credenciales

Verás una pantalla como esta:

```
═══════════════════════════════════════════════════════════
  GRAFANA CLOUD PROMETHEUS
═══════════════════════════════════════════════════════════

Remote Write URL:
  https://prometheus-blocks-prod-us-central1.grafana-blocks.grafana.io/api/prom/push

Username:
  123456  (tu Grafana User ID)

Password:
  glc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  (token muy largo)
```

**COPIA ESTOS VALORES Y GUÁRDALOS EN UN LUGAR SEGURO** (no en git!)

---

## 🚀 Paso 3: Iniciar Prometheus Localmente (5 min)

Prometheus correrá en tu máquina local, scrapeará las métricas de tu backend en Render, y las enviará a Grafana Cloud.

### 3.1 Editar prometheus.yml

1. Abre el archivo: `/home/joseligo/DevOps/prometheus.yml`

2. Busca esta sección (alrededor de línea 14):

```yaml
# remote_write:
#   - url: https://prometheus-blocks-prod-us-central1...
#     basic_auth:
#       username: YOUR_GRAFANA_USERNAME_HERE
#       password: YOUR_GRAFANA_PASSWORD_HERE
```

3. Reemplázalo con tus credenciales (descomenta y completa):

```yaml
remote_write:
  - url: https://prometheus-blocks-prod-us-central1.grafana-blocks.grafana.io/api/prom/push
    basic_auth:
      username: 123456
      password: glc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**⚠️ IMPORTANTE: NO COMMITEES ESTE ARCHIVO A GIT** (tiene credenciales!)

Agregalo a `.gitignore` si lo necesitas:
```bash
echo "prometheus.yml" >> .gitignore
```

### 3.2 Iniciar Docker Compose

```bash
cd /home/joseligo/DevOps
docker-compose -f prometheus-monitoring.yml up -d
```

Deberías ver:

```
Creating devops_prometheus ... done
Creating devops_grafana    ... done
Creating devops_alertmanager ... done
```

### 3.3 Verificar que Prometheus Está Corriendo

```bash
# Opción 1: Ver logs
docker-compose -f prometheus-monitoring.yml logs prometheus | tail -20

# Esperado: líneas con "scraping" y "remote_write"
```

O abre en browser:
- **http://localhost:9090** - Prometheus UI

Verifica:
1. Click **"Status"** → **"Targets"**
2. Deberías ver:
   - `prometheus-self` → UP ✅
   - `backend-render` → UP ✅

Si `backend-render` está DOWN:
```bash
# Verifica que el backend URL es accesible
curl https://devops-crud-app-backend.onrender.com/metrics | head -5

# Si funciona, espera 30 segundos a que Prometheus intente conectar
```

### 3.4 Verificar que Datos Llegan a Grafana Cloud

En Prometheus UI:
1. Click **"Graph"** en la parte superior
2. En "Expression", escribe: `http_requests_total`
3. Click **"Execute"**
4. Deberías ver un gráfico con datos! 📈

**Si todo está bien, tus métricas se están enviando a Grafana Cloud en este momento.**

---

## 📊 Paso 4: Crear Primer Dashboard (10 min)

### 4.1 Acceder a Grafana Cloud Dashboard

1. Login en Grafana Cloud: **https://grafana.com/login**
2. O abre directamente desde el link que recibiste por email

### 4.2 Crear Nuevo Dashboard

1. En la barra lateral izquierda, click **"Dashboards"** (icono de gráfico)
2. Click **"New"** (botón azul)
3. Click **"New Dashboard"**

### 4.3 Agregar Panel 1: Requests per Second

1. Click **"Add a new panel"** (o "Add new panel" si es primera vez)

2. En el área de query (abajo), cambia de "Time series" a tu preferencia:

3. En **"Metrics"**, escribe esta query:

```
rate(http_requests_total[1m])
```

4. En **"Legend"**, configura para mostrar etiquetas:

```
{{ method }} {{ route }} {{ status }}
```

5. Configuración del Panel:
   - **Title:** `Requests per Second`
   - **Visualization:** `Time series`
   - **Unit:** (dejar default)
   - **Refresh:** `10s`

6. Click **"Save"** (arriba a la derecha)

---

### 4.4 Agregar Panel 2: Latency (P95)

1. Click **"Add"** en la toolbar (o icono `+`)
2. Click **"Visualization"** → **"Stat"** (para un número grande)

3. Query:

```
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

4. Configuración:
   - **Title:** `P95 Latency`
   - **Unit:** `Seconds`
   - **Decimals:** `3`
   - **Thresholds:** Green 0-0.2, Yellow 0.2-1, Red 1+

5. Click **"Save"**

---

### 4.5 Agregar Panel 3: Error Rate %

1. Crear nuevo panel
2. Visualization: **"Gauge"**

3. Query:

```
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

4. Configuración:
   - **Title:** `Error Rate %`
   - **Unit:** `Percent (0-100)`
   - **Max value:** `100`
   - **Thresholds:** Green 0-0.1, Yellow 0.1-1, Red 1+

5. Click **"Save"**

---

### 4.6 Agregar Panel 4: Active Requests

1. Nuevo panel
2. Visualization: **"Gauge"**

3. Query:

```
http_requests_active
```

4. Configuración:
   - **Title:** `Active Requests`
   - **Unit:** (none)
   - **Max value:** `50`

5. Click **"Save"**

---

### 4.7 Guardar Dashboard

1. En la barra superior, click el **icono de disk** (guardar)
2. Dale un nombre: `CRUD App - Metrics`
3. Click **"Save"**

**¡Listo! Tu primer dashboard está creado!** 🎉

---

## 🚨 Paso 5: Configurar Alertas (7 min)

### 5.1 Crear Contact Point (donde enviar alertas)

1. En Grafana Cloud, sidebar izquierda
2. Click **"Alerting"** → **"Contact points"**
3. Click **"New contact point"**

4. Configuración:
   ```
   Name: email-alerts
   Type: Email
   Email addresses: tu-email@gmail.com
   ```

5. Click **"Save contact point"**

### 5.2 Crear Alerta 1: Error Rate > 5%

1. **Alerting** → **"Alert rules"**
2. Click **"Create alert rule"** (botón azul)

3. Configuración:

   **Sección: Define query and condition**
   - Metric: 
   ```
   (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) > 0.05
   ```

   **Sección: Set alert evaluation behavior**
   - For: `5 minutes`
   - Evaluation group: `default`

4. Click **"Next"** (o continúa en la misma pantalla)

5. **Configuración de Alerta:**
   - Alert rule name: `HighErrorRate`
   - Annotations:
     - Summary: `Error rate above 5% - immediate action needed`
     - Description: `Current error rate: {{ $value | humanizePercentage }}`

6. **Contact Point:** Selecciona `email-alerts`

7. Click **"Save rule"**

---

### 5.3 Crear Alerta 2: P95 Latency > 1 segundo

1. **Create alert rule** (nuevo)

2. Query:
```
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
```

3. For: `5 minutes`

4. Alert rule name: `HighLatency`
5. Summary: `P95 latency above 1 second`
6. Contact Point: `email-alerts`

7. Click **"Save rule"**

---

### 5.4 Crear Alerta 3: Muchas Requests Activos

1. **Create alert rule**

2. Query:
```
http_requests_active > 50
```

3. For: `3 minutes`

4. Alert rule name: `TooManyActive`
5. Summary: `More than 50 active requests`
6. Contact Point: `email-alerts`

7. Click **"Save rule"**

---

## ✅ Verificación Final

### Paso 1: Dashboard Visible
- [ ] Abre tu dashboard: **Dashboards** → **CRUD App - Metrics**
- [ ] Deberías ver 4 paneles con datos
- [ ] Gráficos muestran data en tiempo real

### Paso 2: Prometheus Scrapeando
- [ ] Abre http://localhost:9090
- [ ] **Status** → **Targets**
- [ ] `backend-render` debe estar **UP** ✅

### Paso 3: Generar Traffic para Probar

```bash
# Genera 100 requests
for i in {1..100}; do
  curl -s https://devops-crud-app-backend.onrender.com/users > /dev/null &
done
wait

# Espera 10 segundos
sleep 10

# Abre tu dashboard y deberías ver:
# - Requests/sec subiendo
# - P95 latency actualizándose
# - Error rate visible
```

Abre tu dashboard en Grafana Cloud y verás los datos actualizándose en vivo! 📈

### Paso 4: Probar Alertas (opcional)

Para probar que las alertas funcionan:

1. Genera mucho traffic para que error rate suba:
```bash
for i in {1..500}; do
  curl -X POST https://devops-crud-app-backend.onrender.com/users \
    -H "Content-Type: application/json" \
    -d '{}' > /dev/null &
done
```

2. Espera 5 minutos
3. Deberías recibir email de alerta

---

## 🆘 Troubleshooting

### "Backend-render está DOWN en Prometheus"
```
Causa: Prometheus no puede alcanzar tu Render backend
Solución:
1. Verifica que el backend está up: curl https://devops-crud-app-backend.onrender.com/healthz
2. En prometheus.yml, verifica la URL está correcta
3. Reinicia Prometheus: docker-compose -f prometheus-monitoring.yml restart prometheus
```

### "No veo datos en Grafana Cloud"
```
Causa: Los datos aún no han llegado o Prometheus no está enviando
Solución:
1. En Prometheus local (http://localhost:9090), ejecuta la query
2. Si ves datos localmente, espera 2-3 minutos a que lleguen a Grafana Cloud
3. Verifica credenciales en prometheus.yml son correctas
4. Revisa logs: docker-compose logs prometheus | grep remote_write
```

### "Query en Grafana devuelve 'no data'"
```
Causa: La query es incorrecta o los datos aún no existen
Solución:
1. En Prometheus local, prueba la query primero
2. Verifica que la métrica existe: curl https://backend.../metrics | grep http_requests_total
3. Asegúrate que hay data (haz algunos requests primero)
```

### "Alertas no se envían"
```
Causa: Contact point no está guardado o threshold no se alcanza
Solución:
1. Verifica que contact point está configurado: Alerting → Contact points
2. Haz que el threshold se alcance (generar mucho traffic)
3. En "Alert rules", verifica que la regla está ENABLED (toggle verde)
```

---

## 🎓 Lo Que Has Logrado

✅ Grafana Cloud account creada  
✅ Prometheus localmente scrapeando tu backend  
✅ Métricas enviándose a Grafana Cloud  
✅ Dashboard profesional con 4 paneles  
✅ 3 alertas configuradas para problemas comunes  

**Ahora tienes monitoring profesional, lista** 🎉

---

## 📈 Próximas Mejoras (Opcional)

1. **Agregar más paneles:**
   - Memory usage
   - CPU usage
   - Database query performance
   - Custom business metrics

2. **Integrar Slack:**
   - Alertas en Slack en lugar de email
   - Notificaciones en tiempo real

3. **Crear SLO dashboard:**
   - Track 99.9% uptime
   - Track P99 latency targets
   - Track error rate targets

4. **Agregar logs:**
   - Usar Grafana Loki para agregar logs
   - Ver logs y métricas juntas

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs: `docker-compose logs prometheus`
2. Verifica URLs y credenciales
3. Abre una issue en GitHub

**¡Felicitaciones! 🎉 Monitoring profesional en vivo!**
