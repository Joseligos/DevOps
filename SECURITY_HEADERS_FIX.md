# 🛡️ Optional Security Headers Implementation Guide

## Overview

Este documento muestra cómo agregar security headers opcionales a tu backend para lograr **10/10 en el ZAP scan**.

**Tiempo estimado**: 5 minutos  
**Dificultad**: Fácil  
**Impacto**: Mejora defensa en profundidad (defense-in-depth)

---

## Step 1: Update backend/index.js

Añade este código después del middleware de CORS:

```javascript
// CORS
app.use(cors());

// ═══════════════════════════════════════════════════════════
// SECURITY HEADERS (Optional - Defense in Depth)
// ═══════════════════════════════════════════════════════════

app.use((req, res, next) => {
  // 1. HSTS - Force HTTPS connections
  // Tells browsers to always use HTTPS (max-age = 1 year)
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  
  // 2. Hide Express.js from exposure
  // Makes it harder for attackers to identify the framework
  app.disable('x-powered-by');
  
  // 3. CSP - Content Security Policy
  // Prevents inline scripts and restricts resource loading
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:"
  );
  
  // 4. X-Content-Type-Options - Prevent MIME sniffing
  // Forces browser to respect Content-Type header
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // 5. X-Frame-Options - Clickjacking protection
  // Prevents your site from being embedded in iframes
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  
  // 6. X-XSS-Protection - Browser XSS filter
  // Enables XSS filtering in older browsers
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  // 7. Permissions-Policy - Control browser features
  // Disables access to sensitive browser APIs
  res.setHeader(
    'Permissions-Policy',
    'geolocation=(), microphone=(), camera=(), payment=()'
  );
  
  // 8. Referrer-Policy - Control referrer information
  // Prevents leaking referrer data
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  next();
});
```

---

## Step 2: Verify Headers

After deploying, test the headers:

```bash
# Check if headers are present
curl -i https://devops-crud-app-backend.onrender.com/healthz | grep -i "Strict-Transport-Security\|X-Content-Type\|Content-Security-Policy"

# Should return:
# strict-transport-security: max-age=31536000; includeSubDomains
# x-content-type-options: nosniff
# content-security-policy: default-src 'self'; ...
```

---

## Step 3: Run ZAP Scan Again

After deploying:

```bash
git add backend/index.js
git commit -m "Add security headers for defense-in-depth"
git push origin main
```

ZAP will automatically scan (or trigger manually):
- Wait 2-3 minutes for deployment
- ZAP will run and should show **7 PASS** instead of 7 WARN

---

## Security Headers Explained

| Header | Purpose | Impact |
|--------|---------|--------|
| **Strict-Transport-Security** | Force HTTPS | Prevents man-in-the-middle attacks |
| **X-Content-Type-Options** | Prevent MIME sniffing | Stops browsers from guessing file types |
| **X-Frame-Options** | Clickjacking protection | Prevents embedding in malicious iframes |
| **Content-Security-Policy** | Script/resource restrictions | Blocks inline scripts and unauthorized resources |
| **Permissions-Policy** | API access control | Disables sensors, camera, microphone, payment APIs |
| **Referrer-Policy** | Referrer control | Prevents leaking sensitive URLs in referrer header |
| **X-XSS-Protection** | XSS filter | Enables browser XSS protection (legacy) |

---

## ZAP Scan Expected Results After Fix

```
BEFORE (Current):
├─ PASS: 132 ✅
├─ WARN: 7 ⚠️ (Headers missing)
└─ FAIL: 0 ✅

AFTER (With headers):
├─ PASS: 139 ✅ (132 + 7 header checks)
├─ WARN: 0 ✅
└─ FAIL: 0 ✅

Security Score: 9/10 → 10/10 ⭐
```

---

## Notes

1. **No downtime**: Headers can be added without restarting
2. **No performance impact**: Headers are tiny (< 1KB)
3. **Backward compatible**: Old browsers ignore unknown headers
4. **Zero config required**: Works on Render as-is
5. **Optional**: Your app is already secure without these

---

## Alternative: Helmet.js

If you want a simpler approach, use the `helmet` package:

```bash
npm install helmet
```

Then in `backend/index.js`:

```javascript
const helmet = require('helmet');

app.use(helmet());  // Sets ALL security headers automatically
app.use(cors());
```

This is equivalent to manually setting all 8 headers above.

---

## Deployment Steps

1. Update `backend/index.js`
2. Commit and push: `git push origin main`
3. Render auto-deploys (2-3 min)
4. Next ZAP scan runs and confirms all headers present
5. Security assessment: 10/10 ⭐

---

**Implementation Time**: 5 minutes  
**Effort Level**: Easy  
**Security Improvement**: +1 point (9/10 → 10/10)  
**Maintenance**: Zero (set it and forget it)
