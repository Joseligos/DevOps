# 🚀 Empezar con K3d - Guía Rápida

## ⚠️ RECUERDA

✅ **Tu app en Render sigue funcionando igual**
✅ **Esto es totalmente local en tu máquina**
✅ **No afecta nada en producción**

---

## 📋 Pasos Rápidos

### 1️⃣ Verificar requisitos

```bash
# Verificar que Docker está instalado
docker --version

# Debería mostrar: Docker version X.X.X
```

### 2️⃣ Ejecutar el script de setup

```bash
# Dale permisos y ejecuta
chmod +x k3d-setup.sh
./k3d-setup.sh
```

### 3️⃣ Seguir el menú

El script te preguntará qué hacer:

```
1) Install K3d          ← Primero esto
2) Create K3d cluster   ← Luego esto
3) Create secrets       ← Luego esto (necesita tu DATABASE_URL)
4) Deploy app          ← Luego esto
5) Show access info    ← Para ver URLs
```

---

## 🔧 O Hacerlo Manualmente

Si prefieres entender cada paso:

### Paso 1: Instalar K3d

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d version
```

### Paso 2: Crear cluster

```bash
k3d cluster create dev-cluster \
  --servers 1 \
  --agents 2 \
  --port 8080:80@loadbalancer \
  --port 8443:443@loadbalancer \
  --wait
```

### Paso 3: Crear namespace

```bash
kubectl create namespace devops-app
```

### Paso 4: Crear secret con tu DATABASE_URL

Primero, obtén tu DATABASE_URL:

```bash
grep "database_url" terraform/terraform.tfvars
```

Luego:

```bash
kubectl create secret generic db-secret \
  --from-literal=database_url="postgresql://user:password@host:5432/db" \
  -n devops-app
```

### Paso 5: Desplegar

```bash
kubectl apply -f kubernetes/
```

### Paso 6: Verificar

```bash
kubectl get pods -n devops-app
kubectl get svc -n devops-app
```

---

## 🌐 Acceder a tu App

Una vez deployada:

```
Frontend: http://localhost:8080
Backend:  http://localhost (puerto 80)
```

### Probar el backend:

```bash
# Health check
curl http://localhost/healthz

# Listar usuarios
curl http://localhost/users

# Crear usuario
curl -X POST http://localhost/users \
  -H "Content-Type: application/json" \
  -d '{"name":"K8s User"}'
```

---

## 📊 Útiles

```bash
# Ver pods
kubectl get pods -n devops-app

# Ver logs del backend
kubectl logs -f deployment/backend -n devops-app

# Ver logs del frontend
kubectl logs -f deployment/frontend -n devops-app

# Port-forward manual
kubectl port-forward svc/backend 3001:80 -n devops-app

# Ejecutar comando en pod
kubectl exec -it <pod-name> -n devops-app -- sh
```

---

## 🛑 Limpiar Cuando Termines

```bash
# Parar cluster pero mantener
k3d cluster stop dev-cluster

# Eliminar cluster
k3d cluster delete dev-cluster
```

---

## ⚠️ Notas Importantes

1. **Base de datos compartida**: K3d usa la MISMA base de datos que Render (Railway)
   - Los usuarios creados en K3d aparecen en Render
   - Los usuarios creados en Render aparecen en K3d

2. **Volúmenes**: Los archivos están en tu máquina con mount de carpetas

3. **Recursos**: Necesitas:
   - 4GB RAM disponible
   - 10GB disco libre
   - Docker corriendo

4. **Puertos**: Solo usa puertos 8080/8443 locales

---

## 🆘 Si Algo Falla

```bash
# Ver estado del cluster
k3d cluster list
kubectl cluster-info

# Ver eventos
kubectl get events -n devops-app

# Limpiar todo y empezar de nuevo
k3d cluster delete dev-cluster
# Luego ejecuta el setup script de nuevo
```

---

## 🎯 Próximo Paso

Una vez que K3d funcione, puedes:

1. **Continuar con Flux** - GitOps automático desde GitHub
2. **Experimentar** - Cambiar manifiestos, probar diferentes configs
3. **Comparar** - Notar diferencias entre Render y Kubernetes

**¿Necesitas ayuda?** Pregunta en el próximo mensaje 👇
