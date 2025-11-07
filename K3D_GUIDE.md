# 🚀 Kubernetes Local con K3d - Guía Completa

## ⚠️ IMPORTANTE

**Este setup es COMPLETAMENTE LOCAL y NO afecta tu app en Render.**
- Render sigue funcionando exactamente igual ✅
- Esto es solo para aprender Kubernetes
- Tu máquina necesita Docker/Podman instalado

---

## 📋 Requisitos

- ✅ Linux (Ubuntu/Debian/Fedora) o macOS
- ✅ Docker o Podman instalado
- ✅ 4GB RAM disponible (mínimo)
- ✅ 10GB disco libre

### Verificar Docker

```bash
docker --version
docker ps
```

Si ves versión y lista de contenedores → Listo ✅

---

## 🔧 Paso 1: Instalar K3d

### En Linux:
```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

### En macOS:
```bash
brew install k3d
```

### Verificar instalación:
```bash
k3d version
```

Deberías ver: `k3d version vX.X.X`

---

## 🏗️ Paso 2: Crear un Cluster K3d

```bash
# Crear cluster llamado "dev-cluster" con setup ligero
k3d cluster create dev-cluster \
  --servers 1 \
  --agents 2 \
  --port 8080:80@loadbalancer \
  --port 8443:443@loadbalancer \
  --volume /tmp/k3dvol:/tmp/k3dvol@all
```

Esto crea:
- 1 servidor (control plane)
- 2 agentes (worker nodes)
- Puerto 8080 → HTTP
- Puerto 8443 → HTTPS

### Verificar cluster:
```bash
k3d cluster list
kubectl cluster-info
kubectl get nodes
```

---

## 📦 Paso 3: Crear Namespaces y Secrets

### 3.1 Namespace para tu app:
```bash
kubectl create namespace devops-app
```

### 3.2 Secret para DATABASE_URL

Primero, obtén tu DATABASE_URL de `terraform/terraform.tfvars`:

```bash
# Lee el valor desde el archivo
grep "database_url" terraform/terraform.tfvars
```

Luego crea el secret (REEMPLAZA con tu URL real):

```bash
kubectl create secret generic db-secret \
  --from-literal=database_url="postgresql://user:password@host:5432/db" \
  -n devops-app
```

### Verificar:
```bash
kubectl get secrets -n devops-app
```

---

## 🐳 Paso 4: Crear Manifiestos Kubernetes

### Estructura de carpetas:

```
kubernetes/
├── backend/
│   ├── deployment.yaml
│   └── service.yaml
├── frontend/
│   ├── deployment.yaml
│   └── service.yaml
└── postgres/
    └── configmap.yaml
```

Vamos a crear cada archivo...

### 4.1 Backend Deployment

**Archivo: `kubernetes/backend/deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: devops-app
  labels:
    app: backend
spec:
  replicas: 2  # 2 instancias para redundancia
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: node:18-alpine
        workingDir: /app
        command:
          - sh
          - -c
          - |
            npm install && node index.js
        volumeMounts:
        - name: backend-code
          mountPath: /app
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: database_url
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        ports:
        - containerPort: 3000
          name: http
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: backend-code
        hostPath:
          path: /home/joseligo/DevOps/backend
          type: Directory
```

### 4.2 Backend Service

**Archivo: `kubernetes/backend/service.yaml`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: devops-app
  labels:
    app: backend
spec:
  type: LoadBalancer
  selector:
    app: backend
  ports:
  - name: http
    port: 80
    targetPort: 3000
    protocol: TCP
```

### 4.3 Frontend Deployment

**Archivo: `kubernetes/frontend/deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: devops-app
  labels:
    app: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: node:18-alpine
        workingDir: /app
        command:
          - sh
          - -c
          - |
            npm ci && npm run build && npx serve -s build -l 3000
        volumeMounts:
        - name: frontend-code
          mountPath: /app
        env:
        - name: REACT_APP_API_URL
          value: "http://backend"
        ports:
        - containerPort: 3000
          name: http
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 15
          periodSeconds: 10
      volumes:
      - name: frontend-code
        hostPath:
          path: /home/joseligo/DevOps/frontend
          type: Directory
```

### 4.4 Frontend Service

**Archivo: `kubernetes/frontend/service.yaml`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: devops-app
  labels:
    app: frontend
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - name: http
    port: 8080
    targetPort: 3000
    protocol: TCP
```

---

## 🚀 Paso 5: Desplegar en K3d

### 5.1 Crear carpeta de manifiestos:

```bash
mkdir -p kubernetes/backend kubernetes/frontend
```

### 5.2 Copiar los archivos YAML

(Los archivos que creamos arriba)

### 5.3 Aplicar manifiestos:

```bash
# Aplicar todos los manifiestos
kubectl apply -f kubernetes/

# O por partes:
kubectl apply -f kubernetes/backend/deployment.yaml
kubectl apply -f kubernetes/backend/service.yaml
kubectl apply -f kubernetes/frontend/deployment.yaml
kubectl apply -f kubernetes/frontend/service.yaml
```

### 5.4 Verificar despliegue:

```bash
# Ver pods
kubectl get pods -n devops-app

# Ver servicios
kubectl get svc -n devops-app

# Ver logs del backend
kubectl logs -f deployment/backend -n devops-app

# Ver logs del frontend
kubectl logs -f deployment/frontend -n devops-app
```

---

## 🌐 Paso 6: Acceder a tu App Localmente

Una vez deployado:

```bash
# Frontend en local:
http://localhost:8080

# Backend en local:
http://localhost (o localhost:80 si lo ves)
```

### Pruebas:

```bash
# Health check del backend
curl http://localhost/healthz

# Listar usuarios
curl http://localhost/users

# Crear usuario
curl -X POST http://localhost/users \
  -H "Content-Type: application/json" \
  -d '{"name":"K8s User"}'
```

---

## 🛑 Paso 7: Limpiar (cuando quieras parar)

```bash
# Eliminar manifiestos
kubectl delete -f kubernetes/

# Parar cluster pero mantener
k3d cluster stop dev-cluster

# Eliminar cluster completamente
k3d cluster delete dev-cluster
```

---

## 📊 Comandos Útiles

```bash
# Ver cluster info
k3d cluster list
kubectl cluster-info

# Ver recursos
kubectl get all -n devops-app
kubectl describe pod <pod-name> -n devops-app

# Port-forward manual (si necesitas)
kubectl port-forward -n devops-app service/backend 3001:80

# Ejecutar comando en pod
kubectl exec -it <pod-name> -n devops-app -- sh

# Ver eventos
kubectl get events -n devops-app

# Ver logs de todos los pods
kubectl logs -l app=backend -n devops-app
```

---

## ⚠️ IMPORTANTE

- **Render sigue funcionando:** Tu app en `https://devops-crud-app-backend.onrender.com` NO se ve afectada
- **K3d es LOCAL:** Solo corre en tu máquina con Docker
- **Base de datos:** K3d usará LA MISMA base de datos que Render (la de Railway)
- **Puertos:** Locales son 8080/8443, no tocan nada global

---

## 🔗 Próximo Paso: GitOps con Flux

Una vez que K3d funcione, podemos configurar **Flux** para que:
- Vea cambios en GitHub
- Aplique automáticamente a K3d
- Sincronice código + manifiestos

¿Quieres que continúe con Flux después?
