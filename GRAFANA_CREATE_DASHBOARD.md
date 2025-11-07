# 📊 Crear Dashboard Profesional en Grafana Cloud

## Dashboard que Vamos a Crear

```
┌─────────────────────────────────────────────────────────┐
│           CRUD App - Monitoring Dashboard               │
├─────────────────────────────────────────────────────────┤
│  Requests/sec (Graph)  │  P95 Latency (Stat)           │
│                        │  Green: <200ms                 │
│  Shows all traffic     │  Yellow: 200-1000ms           │
│                        │  Red: >1000ms                  │
├─────────────────────────────────────────────────────────┤
│  Error Rate % (Gauge)  │  Active Requests (Gauge)      │
│  Green: 0-0.1%         │  Max threshold: 50            │
│  Yellow: 0.1-1%        │  Shows concurrent requests     │
│  Red: >1%              │                                │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Paso 1: Preparar Dashboard Vacío

1. En Grafana Cloud, **Dashboards** → **+ New** → **Dashboard**
2. Click **"+ Add Panel"** (o espera a que se abra automáticamente)

---

## 📈 Paso 2: Panel 1 - Requests per Second

### 2.1 Crear el Panel

Ya deberías estar en el editor. Si no:
- Click **"+ Add Panel"**

### 2.2 Configurar Query

En el área de "Queries" (abajo):

```
rate(http_requests_total[1m])
```

### 2.3 Configurar Visualización

En la parte derecha, busca "Visualization" y selecciona: **Time series**

### 2.4 Configurar Opciones del Panel

Haz click en el icono de **engranaje** (⚙️) arriba a la derecha o en la sección "Panel Options":

```
Title: Requests per Second
Description: HTTP requests per second
Unit: None
Decimals: 2
```

En **"Thresholds"**:
- Mode: Absolute
- Thresholds: Green 0-∞ (leave default)

En **"Legend"**:
- Show legend: ON
- Placement: Bottom
- Show legend values: ON
- Values: Min, Max, Mean

### 2.5 Guardar Panel

Haz click **"Save"** (arriba a la derecha) o presiona `Escape`

Deberías ver un gráfico con líneas mostrando las requests!

---

## ⏱️ Paso 3: Panel 2 - P95 Latency

### 3.1 Crear Nuevo Panel

En el dashboard, haz click **"+ Add Panel"** (o el icono `+`)

### 3.2 Query

```
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### 3.3 Visualización

Selecciona: **Stat** (número grande)

### 3.4 Opciones

```
Title: P95 Latency
Unit: Seconds
Decimals: 3
Reduce options:
  - Calculation: Last
  - Fields: All values
```

### 3.5 Thresholds (para colores)

En **"Thresholds"**:
- Mode: Absolute
- Thresholds:
  - Green: 0 - 0.2 (verde si < 200ms)
  - Yellow: 0.2 - 1 (amarillo si 200-1000ms)
  - Red: 1 - ∞ (rojo si > 1s)

### 3.6 Guardar

Click **"Save"**

---

## 🔴 Paso 4: Panel 3 - Error Rate %

### 4.1 Nuevo Panel

Click **"+ Add Panel"**

### 4.2 Query

```
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

**Explicación:**
- Cuenta requests con status 5xx (errores)
- Divide entre total de requests
- Multiplica por 100 para porcentaje

### 4.3 Visualización

Selecciona: **Gauge** (círculo con número)

### 4.4 Opciones

```
Title: Error Rate %
Unit: Percent (0-100)
Min: 0
Max: 100
Decimals: 2
Show threshold labels: ON
```

### 4.5 Thresholds

```
Mode: Absolute
Green: 0 - 0.1
Yellow: 0.1 - 1
Red: 1 - 100
```

### 4.6 Guardar

Click **"Save"**

---

## 🔄 Paso 5: Panel 4 - Active Requests

### 5.1 Nuevo Panel

Click **"+ Add Panel"**

### 5.2 Query

```
http_requests_active
```

### 5.3 Visualización

Selecciona: **Gauge** (igual que Panel 3)

### 5.4 Opciones

```
Title: Active Requests
Unit: None
Min: 0
Max: 50
Decimals: 0
```

### 5.5 Thresholds

```
Mode: Absolute
Green: 0 - 10
Yellow: 10 - 30
Red: 30 - 50
```

### 5.6 Guardar

Click **"Save"**

---

## 💾 Paso 6: Guardar Dashboard Completo

1. Cuando todos los 4 paneles estén listos, en la barra superior, haz click el **icono de disk** (💾)
2. Dale un nombre: `CRUD App - Metrics`
3. Agrega descripción (opcional): `Real-time monitoring for DevOps CRUD application`
4. Click **"Save"**

---

## 📺 Tu Dashboard Debería Verse Así

```
CRUD App - Metrics
═══════════════════════════════════════════════════════════

[Requests/sec          ]  [    P95: 0.023s          ]
[   📈 Graph trending   ]  [  🟢 GREEN (Good)         ]
[   showing all requests]  [  Latency is low          ]

[   Error Rate: 0.0%    ]  [  Active: 2 requests     ]
[   🟢 GREEN (0%)        ]  [  🟢 GREEN (<10)          ]
[   No errors detected  ]  [  Normal activity         ]

═══════════════════════════════════════════════════════════
Last updated: just now
```

---

## 🧪 Verificación: Generar Traffic para Probar

Para ver cómo cambian los paneles en tiempo real:

```bash
# En tu terminal
for i in {1..100}; do
  curl -s https://devops-crud-app-backend.onrender.com/users > /dev/null &
done
wait
```

Entonces en Grafana:
- **Requests/sec** → subirá (verás spike en el gráfico)
- **P95 Latency** → puede cambiar un poco
- **Error Rate** → debería seguir 0% (no hay errores)
- **Active Requests** → subirá mientras se ejecutan

Refresh la página para ver datos más frescos: `Ctrl+R` o `Cmd+R`

---

## 🎯 Lo Que Conseguiste

✅ Prometheus scrapeando backend en Render  
✅ Datos enviándose a Grafana Cloud  
✅ Dashboard profesional con 4 paneles  
✅ Alertas visuales (colores: verde/amarillo/rojo)  
✅ Monitoreo en tiempo real  

---

## 🚀 Siguiente Paso: Alertas

Una vez que tu dashboard esté listo, vamos a:
1. Crear Contact Point (email para alertas)
2. Crear Alert Rules (qué condiciones envían alertas)
3. Recibir notificaciones automáticas

---

## 💡 Tips

- **Refresh automático:** En el dashboard, arriba a la derecha, haz click el reloj ⏰ y selecciona "5s" para refresh cada 5 segundos
- **Zoom en gráfico:** Click y arrastra en el gráfico para hacer zoom en un período
- **Descargar panel:** Haz click los 3 puntitos ⋮ en un panel → Download
- **Exportar dashboard:** Dashboard settings → JSON export

---

Cuando termines de crear el dashboard, **cuéntame qué ves!** 😊

¿Ves los 4 paneles con datos? ¡Vamos!
