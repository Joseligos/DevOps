# ✅ Checklist de Despliegue con Terraform

## 📋 Antes de Empezar

- [ ] Terraform instalado (`terraform --version`)
- [ ] Cuenta en Render creada (https://render.com)
- [ ] Cuenta en Railway creada (https://railway.app) O Base de datos PostgreSQL
- [ ] Repositorio en GitHub público o conectado a Render

---

## 🔑 Paso 1: Obtener Credenciales (15 min)

### Render API Key
- [ ] Ir a https://dashboard.render.com/account/settings
- [ ] Crear API Key
- [ ] Copiar key (empieza con `rnd_`)

### PostgreSQL Database
- [ ] **Railway**: Crear proyecto → Provision PostgreSQL → Copiar Connection URL
- [ ] **O Render**: New → PostgreSQL (Free) → Copiar Internal Database URL
- [ ] Guardar URL (empieza con `postgresql://`)

---

## 🛠️ Paso 2: Configurar Terraform (10 min)

- [ ] Navegar a carpeta terraform: `cd terraform/`
- [ ] Copiar ejemplo: `cp terraform.tfvars.example terraform.tfvars`
- [ ] Editar `terraform.tfvars` con tus credenciales:
  - [ ] `render_api_key = "rnd_..."`
  - [ ] `database_url = "postgresql://..."`
  - [ ] `github_repo_url = "https://github.com/Joseligos/DevOps"`
- [ ] Verificar que terraform.tfvars NO está en git: `git status`

---

## 🚀 Paso 3: Desplegar (20 min)

### Opción A: Script Automático (Recomendado)
```bash
cd /home/joseligo/DevOps
./deploy.sh
```
- [ ] Seleccionar opción 1: Inicializar
- [ ] Seleccionar opción 2: Ver plan
- [ ] Revisar el plan cuidadosamente
- [ ] Seleccionar opción 3: Aplicar
- [ ] Esperar 5-10 minutos
- [ ] Copiar URLs de output

### Opción B: Manual
```bash
cd terraform/
terraform init
terraform plan -out=infra.tfplan
# Revisar el plan
terraform apply infra.tfplan
```

---

## ✅ Paso 4: Verificar Despliegue (5 min)

- [ ] Copiar backend_url del output
- [ ] Probar health check: `curl BACKEND_URL/healthz`
- [ ] Debería responder: `{"status":"ok"}`
- [ ] Abrir frontend_url en navegador
- [ ] Verificar que carga la aplicación React

---

## 🔄 Paso 5: Configurar Auto-Deploy (5 min)

En Render Dashboard:
- [ ] Ir a tu servicio backend
- [ ] Settings → Build & Deploy
- [ ] Verificar que "Auto-Deploy" está en "Yes"
- [ ] Repetir para frontend

Probar:
```bash
# Hacer un cambio pequeño
echo "// Test deploy" >> backend/index.js
git add .
git commit -m "Test auto-deploy"
git push origin main
```
- [ ] Ir a Render Dashboard
- [ ] Ver que se inicia un nuevo deploy automáticamente
- [ ] Esperar que complete
- [ ] Verificar que el cambio se aplicó

---

## 🐛 Troubleshooting

### ❌ Error: "Provider not found"
```bash
cd terraform/
terraform init
```

### ❌ Error: "Invalid API key"
- [ ] Verificar que copiaste la API key completa
- [ ] Verificar que no tiene espacios al inicio/final
- [ ] Regenerar API key en Render

### ❌ Error: "Repository not found"
- [ ] Verificar que el repo es público
- [ ] O conectar GitHub a Render: Settings → Connect Repository

### ❌ Backend no inicia
- [ ] Ir a Render Dashboard → Backend → Logs
- [ ] Buscar errores
- [ ] Verificar DATABASE_URL en Environment variables
- [ ] Verificar que la DB está funcionando

### ❌ Frontend muestra error
- [ ] Verificar REACT_APP_API_URL apunta al backend correcto
- [ ] Abrir DevTools → Console para ver errores
- [ ] Verificar que el backend está respondiendo

---

## 📊 Monitoreo Post-Despliegue

### Render Dashboard
- [ ] Backend: https://dashboard.render.com/web/srv-XXXXX
- [ ] Frontend: https://dashboard.render.com/static/srv-YYYYY
- [ ] Verificar Metrics (CPU, Memory, Requests)

### Logs en Tiempo Real
```bash
# En Render Dashboard
Backend → Logs tab
Frontend → Logs tab
```

### Health Checks
```bash
# Backend
curl https://TU-BACKEND-URL/healthz

# Frontend
curl https://TU-FRONTEND-URL
```

---

## 🎯 Próximos Pasos

- [ ] Configurar dominio custom (opcional)
- [ ] Configurar alertas de uptime
- [ ] Configurar backups de DB
- [ ] Implementar monitoring (Sentry, LogRocket)
- [ ] Configurar CI/CD con GitHub Actions
- [ ] Agregar tests de integración

---

## 📝 Notas Importantes

⚠️ **NUNCA commits:**
- `terraform.tfvars`
- API keys
- Database passwords

✅ **SIEMPRE commits:**
- `terraform.tfvars.example`
- Archivos `.tf`
- Configuración de infraestructura

🔐 **Seguridad:**
- Rotar API keys regularmente
- Usar variables de entorno
- No hardcodear secretos
- Revisar logs por información sensible

---

## 🆘 Ayuda

- Terraform Docs: https://registry.terraform.io/providers/renderinc/render/latest/docs
- Render Docs: https://render.com/docs
- Railway Docs: https://docs.railway.app
- Community: https://community.render.com

---

## ✅ Checklist Final

- [ ] Infraestructura desplegada
- [ ] Backend respondiendo en /healthz
- [ ] Frontend accesible
- [ ] Base de datos conectada
- [ ] Auto-deploy configurado
- [ ] URLs guardadas
- [ ] Credentials seguras (no en git)
- [ ] Documentación actualizada

🎉 **¡Felicidades! Tu aplicación está en producción!**
