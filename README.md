# DevOps CRUD Application

Full-stack CRUD application with CI/CD pipeline, Docker containerization, and Infrastructure as Code (Terraform).

## 🏗️ Arquitectura

- **Backend:** Node.js + Express + PostgreSQL
- **Frontend:** React + Axios
- **Database:** PostgreSQL
- **CI/CD:** GitHub Actions
- **Containerization:** Docker (multi-stage builds)
- **Infrastructure:** Terraform (Render deployment)

## 📁 Estructura del Proyecto

```
DevOps/
├── backend/              # API Node.js/Express
│   ├── index.js
│   └── package.json
├── frontend/            # Aplicación React
│   ├── src/
│   └── package.json
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # Provider configuration
│   ├── variables.tf    # Variable definitions
│   ├── render.tf       # Render resources
│   ├── outputs.tf      # Output values
│   └── README.md       # Terraform guide
├── .github/
│   └── workflows/
│       └── ci.yml      # CI/CD pipeline
├── Dockerfile          # Backend Dockerfile
└── deploy.sh          # Deployment helper script
```

## 🚀 Quick Start

### Desarrollo Local

```bash
# Instalar dependencias
npm install

# Backend
cd backend
npm start

# Frontend (otra terminal)
cd frontend
npm start
```

## 🔧 Despliegue en Producción

### Opción 1: Script Automático

```bash
./deploy.sh
```

### Opción 2: Manual con Terraform

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus credenciales
terraform init
terraform plan -out=infra.tfplan
terraform apply infra.tfplan
```

📖 **Guía completa:** Ver `terraform/README.md` y `DEPLOYMENT_CHECKLIST.md`

## � Security & Monitoring

### Seguridad Automática
- **CodeQL**: Análisis estático de código (búsqueda de vulnerabilidades)
- **OWASP ZAP**: Pruebas dinámicas de seguridad contra la API
- **Trivy**: Escaneo de vulnerabilidades en imagen Docker
- **Secret Detection**: Detección de credenciales hardcodeadas

📖 **Guía completa:** Ver `SECURITY_IMPLEMENTATION.md`

### Monitoreo con Prometheus + Grafana
- **Prometheus**: Colección de métricas en local
- **Grafana Cloud**: Dashboard y visualización en la nube
- **Alertas**: Reglas configuradas para eventos críticos

📖 **Guía completa:** Ver `MONITORING_GUIDE.md` y `GRAFANA_CLOUD_SETUP_VISUAL.md`

## �📚 Documentación

- 📘 [Terraform Setup](terraform/README.md)
- ✅ [Deployment Checklist](DEPLOYMENT_CHECKLIST.md)
- 🏛️ [Architecture](ARCHITECTURE.md)
- 🔐 [Security Implementation](SECURITY_IMPLEMENTATION.md)
- 📊 [Monitoring Guide](MONITORING_GUIDE.md)
- 📈 [Grafana Setup](GRAFANA_CLOUD_SETUP_VISUAL.md)

## 🔄 CI/CD Pipeline

1. ✅ Tests (`npm test`)
2. ✅ Linting (`npm run lint`)
3. ✅ Docker build
4. 🚀 Auto-deploy a Render

## 🛠️ Tecnologías

- Node.js 18, Express, PostgreSQL
- React 17, Axios
- Docker, Terraform, GitHub Actions
- Render (hosting)

## 📊 Scripts

```bash
npm test              # Tests
npm run lint          # Linting
./deploy.sh          # Deploy interactivo
```

## 👥 Autor

Joseligos - [GitHub](https://github.com/Joseligos)
