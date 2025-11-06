# 🚀 Guía Paso a Paso: Despliegue con Terraform

## Prerrequisitos

Antes de comenzar, necesitas:

1. **Terraform instalado** (versión >= 1.0)
   ```bash
   # Linux/macOS
   brew install terraform
   
   # O descarga desde: https://www.terraform.io/downloads
   ```

2. **Cuenta en Render** (gratis)
   - Regístrate en: https://render.com

3. **Base de datos PostgreSQL** (gratis)
   - Railway: https://railway.app
   - O Render PostgreSQL: https://render.com

---

## 📝 Paso 1: Obtener las Credenciales

### 1.1 Obtener API Key de Render

1. Ve a: https://dashboard.render.com/account/settings
2. Busca la sección "API Keys"
3. Click en "Create API Key"
4. Copia la key (empieza con `rnd_`)

### 1.2 Crear Base de Datos PostgreSQL

**Opción A - Railway (Recomendado):**
1. Ve a: https://railway.app
2. Sign up con GitHub
3. Click "New Project"
4. Selecciona "Provision PostgreSQL"
5. Espera que se cree
6. Click en PostgreSQL > Connect > Copia el "Postgres Connection URL"

**Opción B - Render:**
1. En Render Dashboard
2. Click "New" > "PostgreSQL"
3. Nombre: `devops-crud-db`
4. Plan: Free
5. Copia la "Internal Database URL"

---

## 📂 Paso 2: Configurar Terraform

### 2.1 Navegar al directorio de Terraform

```bash
cd /home/joseligo/DevOps/terraform
```

### 2.2 Crear archivo de variables

```bash
# Copia el ejemplo
cp terraform.tfvars.example terraform.tfvars

# Edita el archivo con tus credenciales
nano terraform.tfvars
```

### 2.3 Completar terraform.tfvars

Edita `terraform.tfvars` y reemplaza con tus valores reales:

```hcl
render_api_key = "rnd_TU_API_KEY_AQUI"
github_repo_url = "https://github.com/Joseligos/DevOps"
database_url = "postgresql://usuario:password@host.railway.app:5432/railway"
```

⚠️ **IMPORTANTE:** Este archivo NO debe subirse a git (ya está en .gitignore)

---

## 🏗️ Paso 3: Inicializar Terraform

```bash
# Inicializa Terraform (descarga providers)
terraform init
```

Deberías ver:
```
Initializing the backend...
Initializing provider plugins...
- Installing renderinc/render...

Terraform has been successfully initialized!
```

---

## 🔍 Paso 4: Verificar el Plan

Antes de crear recursos, revisa qué va a hacer Terraform:

```bash
# Crea un plan de ejecución
terraform plan -out=infra.tfplan
```

Esto mostrará:
- ✅ Recursos que se van a crear (backend, frontend)
- ✅ Variables que se van a usar
- ✅ URLs de salida

**Revisa cuidadosamente** que todo se vea bien antes de continuar.

---

## 🚀 Paso 5: Aplicar la Infraestructura

```bash
# Aplica el plan guardado
terraform apply infra.tfplan
```

Terraform comenzará a:
1. Crear el servicio backend en Render
2. Crear el sitio frontend en Render
3. Configurar las variables de entorno
4. Conectar el repositorio de GitHub
5. Iniciar el despliegue automático

⏱️ **Esto puede tomar 5-10 minutos** en el primer despliegue.

---

## ✅ Paso 6: Verificar el Despliegue

Una vez completado, verás los outputs:

```
Outputs:

backend_url = "https://devops-crud-app-backend.onrender.com"
frontend_url = "https://devops-crud-app-frontend.onrender.com"
backend_id = "srv-xxxxx"
frontend_id = "srv-yyyyy"
```

### Probar los servicios:

```bash
# Verificar backend health check
curl https://TU-BACKEND-URL/healthz

# Verificar frontend
curl https://TU-FRONTEND-URL
```

---

## 🔄 Paso 7: Actualizaciones Automáticas

Una vez configurado:

1. Haz cambios en tu código
2. Commit y push a GitHub:
   ```bash
   git add .
   git commit -m "Update feature"
   git push origin main
   ```
3. Render **automáticamente** desplegará los cambios (auto_deploy = true)

---

## 🛠️ Comandos Útiles

### Ver estado actual
```bash
terraform show
```

### Ver outputs de nuevo
```bash
terraform output
```

### Actualizar infraestructura (si cambias terraform files)
```bash
terraform plan -out=infra.tfplan
terraform apply infra.tfplan
```

### Destruir toda la infraestructura
```bash
terraform destroy
```

---

## 🐛 Solución de Problemas

### Error: "Provider not found"
```bash
terraform init
```

### Error: "API key invalid"
Verifica que tu API key en `terraform.tfvars` sea correcta.

### Error: "Repository not found"
Asegúrate que tu repo sea público o que Render tenga acceso.

### Backend no se conecta a la DB
Verifica el `DATABASE_URL` en Render Dashboard > tu servicio > Environment

### Ver logs en Render
1. Ve a Render Dashboard
2. Click en tu servicio
3. Tab "Logs"

---

## 📊 Costos

Todo lo configurado aquí es **GRATUITO**:
- ✅ Render Free Tier: 750 horas/mes
- ✅ Railway PostgreSQL: 500MB storage
- ✅ Terraform: Open source, gratis

---

## 🔐 Seguridad

✅ API keys en variables (no hardcodeadas)  
✅ terraform.tfvars en .gitignore  
✅ DATABASE_URL como variable sensible  
✅ HTTPS automático en Render  

---

## 📚 Próximos Pasos

1. Configurar dominios custom (opcional)
2. Agregar monitoreo y alertas
3. Configurar backups de la base de datos
4. Implementar CI/CD con GitHub Actions + Terraform
