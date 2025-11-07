#!/bin/bash
# Test backend locally before Render deploy

echo "🧪 Testing backend schema initialization..."
echo ""

# Check if DATABASE_URL is set in terraform.tfvars
if [ -f /home/joseligo/DevOps/terraform/terraform.tfvars ]; then
    DB_URL=$(grep "database_url" /home/joseligo/DevOps/terraform/terraform.tfvars | cut -d'"' -f2)
    echo "📍 Using DATABASE_URL from terraform.tfvars"
    echo "   URL: ${DB_URL:0:50}..."
else
    echo "⚠️  terraform.tfvars not found"
    exit 1
fi

echo ""
echo "Running backend with schema initialization..."
echo "=============================================="
echo ""

# Export DATABASE_URL and run backend
export DATABASE_URL="$DB_URL"
cd /home/joseligo/DevOps/backend
node index.js &
BG_PID=$!

# Wait for startup messages
sleep 3

# Test endpoints
echo ""
echo "Testing endpoints..."
echo "==================="
echo ""

echo "1. Testing /healthz endpoint:"
curl -s http://localhost:3000/healthz | jq . || echo "Failed"

echo ""
echo "2. Testing /users endpoint (should list users or be empty):"
curl -s http://localhost:3000/users | jq . || echo "Failed"

echo ""
echo "3. Testing POST /users endpoint:"
curl -s -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User"}' | jq . || echo "Failed"

echo ""
echo "4. Testing GET /users again (should show new user):"
curl -s http://localhost:3000/users | jq . || echo "Failed"

# Cleanup
echo ""
echo "Stopping backend..."
kill $BG_PID
wait $BG_PID 2>/dev/null

echo ""
echo "✅ Test complete"
