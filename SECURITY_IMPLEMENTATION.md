# 🔐 Security Implementation Guide

## Overview

Este proyecto implementa una **estrategia de seguridad en capas** con múltiples herramientas de escaneo automático integradas en el pipeline CI/CD de GitHub Actions.

## Security Layers

### 1. **CodeQL - Static Code Analysis**
**Propósito**: Análisis estático del código fuente para detectar vulnerabilidades, bugs, y problemas de seguridad.

**Localización**: `.github/workflows/codeql-analysis.yml`

**Características**:
- ✅ Análisis automático en `push` a main/develop
- ✅ Análisis en pull requests
- ✅ Análisis programado diariamente (2 AM UTC)
- ✅ Soporte para JavaScript (lenguaje del proyecto)
- ✅ Resultados cargados automáticamente a GitHub Security tab

**Qué detecta**:
- SQL Injection vulnerabilities
- Cross-site scripting (XSS)
- Command injection
- Path traversal
- Deserialization vulnerabilities
- Regular expression denial of service (ReDoS)
- Buffer overflows
- Logic errors

**Acceder a resultados**:
```
GitHub Repository → Security tab → Code scanning alerts
```

### 2. **OWASP ZAP - Dynamic Security Scanning**
**Propósito**: Pruebas de seguridad dinámicas contra la API en vivo para detectar vulnerabilidades en tiempo de ejecución.

**Localización**: `.github/workflows/zap-scan.yml`

**Características**:
- ✅ Escaneo automático en `push` a main
- ✅ Escaneo programado diariamente (3 AM UTC)
- ✅ Objetivo: https://devops-crud-app-backend.onrender.com
- ✅ Usa baseline scanning (rápido, recomendado para CI/CD)
- ✅ No bloquea el build (visible, no enforced)

**Qué detecta**:
- SQL Injection
- Cross-site Scripting (XSS)
- CORS configuration issues
- Authentication/Authorization bypass
- Insecure Direct Object References (IDOR)
- Security Misconfiguration
- Sensitive Data Exposure
- API vulnerabilities
- HTTPS/SSL configuration issues

**Cómo funciona**:
1. ZAP inicia un proxy local
2. Realiza pruebas pasivas y activas contra la API
3. Genera reporte SARIF
4. Sube resultados a GitHub Security tab

**Importante**: ZAP necesita que la aplicación sea accesible públicamente (ya está en Render)

### 3. **Trivy - Container Vulnerability Scanning**
**Propósito**: Escanea imágenes Docker para detectar vulnerabilidades conocidas en dependencias.

**Localización**: `.github/workflows/trivy-scan.yml`

**Características**:
- ✅ Escaneo automático en cambios de `Dockerfile` y `backend/**`
- ✅ Escaneo en pull requests
- ✅ Escaneo programado semanalmente (Lunes 2 AM UTC)
- ✅ Genera reporte SARIF y JSON
- ✅ Filtra CRITICAL y HIGH severities
- ✅ Reportes guardados como artifacts por 30 días

**Qué detecta**:
- OS package vulnerabilities (Debian, Alpine, Ubuntu)
- Application dependencies vulnerabilities
- Known CVEs en imágenes base
- Secrets en la imagen

**Proceso**:
1. Construye la imagen Docker localmente
2. Escanea con Trivy
3. Genera reporte en formato SARIF (para GitHub Security tab)
4. Genera reporte JSON (descargable como artifact)

**Acceder a resultados**:
```
GitHub Repository → Security tab → Container scanning
O
GitHub Repository → Actions → Latest run → Artifacts → trivy-vulnerability-report
```

### 4. **Secret Detection - Custom + Third-party**
**Propósito**: Detecta secretos, tokens, y credenciales hardcodeados en el repositorio.

**Localización**: `.github/workflows/secret-detection.yml`

**Características**:
- ✅ Detección automática en `push` y pull requests
- ✅ Detección programada diariamente (4 AM UTC)
- ✅ Tres capas de detección

#### Capa 1: Custom Script (`scripts/check-secrets.sh`)
Búsqueda de patrones comunes:
- AWS API Keys (AKIA...)
- AWS Secret Access Keys
- GitHub Tokens (ghp_, gho_, ghu_, ghs_, ghr_)
- SSH Private Keys
- API Keys genéricas
- Database URLs
- JWT Tokens
- Slack Tokens
- Contraseñas genéricas
- Grafana Tokens

Ejecución manual:
```bash
chmod +x scripts/check-secrets.sh
./scripts/check-secrets.sh
```

#### Capa 2: TruffleHog
Detección de patrones complejos y verificación de entropía:
- Busca en todo el historio de git
- Detecta secretos "reales" (no solo patrones)
- Valida contra APIs públicas

#### Capa 3: GitGuardian (Opcional)
Escaneo profesional con base de datos de secretos expuestos:
- Requiere API key (gratuita en https://www.gitguardian.com)
- Escanea commits en tiempo real
- Integración con GitHub Security

**Configurar GitGuardian**:
1. Crear cuenta en https://www.gitguardian.com (gratis)
2. Generar API key
3. Añadir secret a GitHub: Settings → Secrets and variables → Actions → New repository secret
   - Name: `GITGUARDIAN_API_KEY`
   - Value: Tu API key

### 5. **Dependency Scanning - npm audit**
Aunque no está en un workflow separado, npm audit se ejecuta automáticamente:

```bash
npm audit           # Ver vulnerabilidades
npm audit fix       # Intentar corregir automáticamente
npm audit fix --force  # Corregir incluso con breaking changes
```

## Security Workflow Timeline

```
Cada vez que haces push a main:

T=0     → GitHub Actions detecta push
T=0-2m  → CodeQL escanea el código fuente (paralelo)
T=0-3m  → OWASP ZAP escanea la API en vivo (paralelo)
T=0-5m  → Trivy escanea la imagen Docker (paralelo)
T=0-2m  → Secret Detection ejecuta 3 herramientas (paralelo)

T=5m    → Todos los reportes están disponibles en GitHub Security tab
T=5m+   → Puedes ver:
           - Code scanning alerts (CodeQL)
           - Container scanning (Trivy)
           - Secret detection results
```

## GitHub Security Tab

**Para ver todos los resultados**:
1. Ve a tu repositorio
2. Haz clic en "Security" tab (arriba)
3. En la izquierda, verás:
   - Code scanning alerts
   - Dependabot alerts
   - Secret scanning

## CI/CD Integration

Todos los workflows están configurados con:

```yaml
permissions:
  contents: read              # Leer código
  security-events: write      # Escribir resultados de seguridad
```

Esto permite que los workflows:
- ✅ Accedan al código del repositorio
- ✅ Carguen resultados al Security tab
- ✅ Creen issues automáticamente (opcional)

## Best Practices

### 1. **Never Commit Secrets**
```bash
# ❌ MALO
const API_KEY = "sk_live_51234567890abcdef";

# ✅ BIEN
const API_KEY = process.env.API_KEY;
```

### 2. **Use Environment Variables**
```bash
# .env.local (NO commitear)
DATABASE_URL=postgresql://user:pass@host:5432/db
API_KEY=sk_live_51234567890abcdef
JWT_SECRET=your-secret-key

# .env.example (SÍ commitear - sin valores)
DATABASE_URL=
API_KEY=
JWT_SECRET=
```

### 3. **Rotate Compromised Credentials**
Si un secret es expuesto:
1. ⏸️ Desactívalo inmediatamente
2. 🔄 Genera uno nuevo
3. 🔍 Revisa logs de acceso
4. 📝 Documenta el incidente
5. 🚀 Despliega el nuevo secret

### 4. **Keep Dependencies Updated**
```bash
# Ver vulnerabilidades
npm audit

# Actualizar automáticamente (minor/patch)
npm update

# Actualizar a última versión (puede romper)
npm upgrade
```

### 5. **Code Review Before Merge**
GitHub requiere al menos:
- ✅ 1 Code Review
- ✅ CodeQL pasen sin alertas
- ✅ Workflow checks pasen

## Responding to Security Alerts

### Si CodeQL encuentra algo:
1. Ve a Security → Code scanning alerts
2. Lee la descripción de la alerta
3. Entiende por qué se disparó
4. Soluciona o marca como false positive
5. Cierra la alerta

### Si Trivy encuentra vulnerabilidades:
1. Identifica el paquete vulnerable
2. En `backend/package.json`, actualiza el paquete
3. Ejecuta `npm update`
4. Verifica que funcione
5. Haz push - Trivy volverá a escanear

### Si Secret Detection encuentra algo:
1. **Inmediatamente** rota el secret
2. Elimina de git history (git filter-branch)
3. Fuerza push a GitHub
4. Revisa logs de acceso

## Monitoring Security

**GitHub Security Overview**:
```
Security tab → Overview
```

Muestra:
- 🔴 Critical issues
- 🟠 High severity issues  
- 🟡 Medium severity issues
- 🔵 Low severity issues

## Advanced: Custom Policies

Para enforcer seguridad:

**Opción 1: Branch Protection Rules**
```
Settings → Branches → Branch protection rules
- Require status checks to pass
- Require code reviews
- Require security scanning to pass
```

**Opción 2: Enforce on Render**
En Render, rechaza deploys si GitHub reports falla.

## Integrated Security Checklist

- ✅ CodeQL escanea en cada push
- ✅ OWASP ZAP escanea la API en vivo
- ✅ Trivy escanea la imagen Docker
- ✅ Secret Detection busca credenciales
- ✅ npm audit detecta dependencias vulnerables
- ✅ GitHub Security tab centraliza todo
- ✅ Alertas automáticas en PR/push
- ✅ Reportes descargables
- ✅ CI/CD integrado

## Troubleshooting

### ZAP no encuentra tu API
**Problema**: El workflow falla porque ZAP no puede conectar a https://devops-crud-app-backend.onrender.com

**Solución**:
1. Verifica que el backend esté corriendo
2. Haz request manual: `curl https://devops-crud-app-backend.onrender.com/healthz`
3. Si no responde, espera a que Render lo despierta (cold start)

### Trivy encuentra vulnerabilidades "antiguas"
**Problema**: Trivy reporta CVEs que ya corregiste

**Solución**:
1. Borra caché: `docker system prune -a`
2. Reconstruye: `docker build --no-cache .`
3. Actualiza paquetes: `npm update`

### Secret Detection con falsos positivos
**Problema**: El script reporta secretos que no son reales

**Solución**:
1. Revisa manualmente
2. Si es falso positivo, editá `scripts/check-secrets.sh`
3. Añade el patrón a la lista de exclusión

## Next Steps

1. **Verificar resultados**: Ve a Security tab después del próximo push
2. **Configurar alertas**: Settings → Notifications → Security alerts
3. **Opcional: GitGuardian**: Configurá la API key para detección profesional
4. **Integrar con Slack**: Notificaciones en tiempo real en tu canal de seguridad

---

**Última actualización**: 2024
**Workflows**: 4 (CodeQL, ZAP, Trivy, Secret Detection)
**Scripts**: 1 (check-secrets.sh)
