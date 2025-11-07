# Manual Redeploy Instructions for Render

## Problem
The Terraform configuration was updated to use Docker builds, but the Render service needs to be redeployed to apply the changes.

## Solution Option 1: Manual Deploy via Render Dashboard (Easiest)

1. Go to https://dashboard.render.com
2. Find your backend service (`devops-crud-app-backend`)
3. Click on the service
4. Scroll down to the bottom and click **"Clear build cache & redeploy"** or **"Manual Deploy"**
5. Wait for the build to complete (should take 2-5 minutes)
6. Check the logs to verify:
   - Docker build succeeds
   - Backend starts with message: "Checking DB connection..." → "DB connection OK" → "Ensuring schema..." → "Backend running on port 3000"

## Solution Option 2: Apply Terraform Locally

If you have terraform already initialized locally:

```bash
cd /home/joseligo/DevOps/terraform
terraform apply
```

This will update the Render service configuration and trigger a redeploy.

## What Changed

The Terraform config was updated from:
- **Old**: Native Node.js runtime with `root_directory = "backend"` and `build_command = "npm ci"`
- **New**: Docker runtime that auto-detects and uses the Dockerfile at the repository root

## Verification Checklist

After redeploy completes:

1. ✅ Check Render backend logs show startup messages
2. ✅ Test `curl https://devops-crud-app-backend.onrender.com/healthz` → should return `{"status":"ok"}`
3. ✅ Test `curl https://devops-crud-app-backend.onrender.com/users` → should return `[]` (empty array)
4. ✅ Database should have `users` table created

## Troubleshooting

If backend still shows 502 after redeploy:
1. Check backend service logs in Render dashboard
2. Look for "Startup failed" or database connection errors
3. Verify DATABASE_URL environment variable is set correctly
4. Check if Dockerfile was detected and used (look for "Docker build" messages in logs)
