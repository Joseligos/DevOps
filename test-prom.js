// Test script to verify prom-client works
const promClient = require('prom-client');

console.log('Testing prom-client...');

(async () => {
  try {
    const register = new promClient.Registry();
    console.log('✅ Registry created');
    
    promClient.collectDefaultMetrics({ register });
    console.log('✅ Default metrics collected');
    
    const metrics = await register.metrics();  // ← AWAIT!!!
    console.log('✅ Metrics retrieved');
    console.log('Type:', typeof metrics, 'instanceof Buffer:', Buffer.isBuffer(metrics));
    console.log('First 500 chars:');
    const str = metrics.toString();
    console.log(str.substring(0, 500));
  } catch (err) {
    console.error('❌ Error:', err);
    console.error('Stack:', err.stack);
  }
})();
