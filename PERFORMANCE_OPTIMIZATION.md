# ⚡ Performance Optimization and Scaling

## Overview

Tu pipeline CI/CD necesita ser **rápido**, **eficiente**, y **escalable**. Este documento cubre cómo optimizar tiempos de ejecución, paralelizar jobs, cachear dependencias, y prepararse para crecimiento.

## 1. 📊 Measure Pipeline Execution Times

### Current Pipeline Baseline

Implementa timing en tus workflows para establecer una línea base:

```yaml
name: Build with Performance Metrics

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # Record the start time
      - name: 📍 Start timer
        id: start_time
        run: |
          echo "start_time=$(date +%s)" >> $GITHUB_ENV
          echo "BUILD START: $(date '+%Y-%m-%d %H:%M:%S')"

      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: 📦 Install dependencies
        run: npm ci

      - name: 🧪 Run tests
        run: npm test

      - name: 🔍 Run linting
        run: npm run lint

      # Calculate and display elapsed time
      - name: ⏱️ End timer and report
        if: always()
        run: |
          end_time=$(date +%s)
          elapsed_time=$((end_time - ${{ env.start_time }}))
          minutes=$((elapsed_time / 60))
          seconds=$((elapsed_time % 60))
          echo "═══════════════════════════════════"
          echo "BUILD TIME: ${minutes}m ${seconds}s"
          echo "Build completed at: $(date '+%Y-%m-%d %H:%M:%S')"
          echo "═══════════════════════════════════"
```

### Performance Metrics to Track

Create a file `docs/performance-baseline.md` to track over time:

```markdown
# Pipeline Performance Baseline

| Date | Job | Duration | Status |
|------|-----|----------|--------|
| 2024-11-06 | Full Build | 5m 30s | ✅ |
| 2024-11-06 | Unit Tests | 2m 15s | ✅ |
| 2024-11-06 | Linting | 45s | ✅ |
| 2024-11-06 | Security Scan | 3m | ✅ |

Target: Reduce total time by 30% within 3 months
```

## 2. ⚙️ Implement Parallelization Strategies

### Current Sequential Flow

```
checkout → npm install → npm test → npm lint → build → deploy
          (5m 30s total - everything waits for everything)
```

### Optimized Parallel Flow

```
              ┌─ npm test (2m 15s) ─┐
checkout →  npm install  ┼─ npm lint (45s) ─┬→ build → deploy
              └─ CodeQL scan (2m) ─┘
          (Total: ~5m instead of 8m)
```

### Implementation - Parallel Jobs

Update `.github/workflows/ci.yml`:

```yaml
name: CI Pipeline - Optimized for Speed

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # Phase 1: Setup and install dependencies
  setup:
    name: Setup Dependencies
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'  # Enable npm caching

      - name: Install dependencies
        run: npm ci

  # Phase 2: Run tests in parallel
  test:
    name: Run Tests
    needs: setup  # Wait for setup to complete
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Run unit tests
        run: npm test

      - name: Generate coverage report
        run: npm run test:coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json

  # Phase 2 (Parallel): Run linting
  lint:
    name: Code Quality
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Run ESLint
        run: npm run lint

      - name: Check formatting
        run: npm run format:check

  # Phase 2 (Parallel): Build artifacts
  build:
    name: Build Application
    needs: setup
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Build application
        run: npm run build

      - name: Build Docker image
        run: docker build -t devops-crud-app:${{ github.sha }} .

  # Phase 3: Only deploy if all checks pass
  deploy:
    name: Deploy to Production
    needs: [test, lint, build]  # Wait for all parallel jobs
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Deploy to Render
        run: |
          curl -X POST https://api.render.com/deploy/srv-YOUR_SERVICE_ID \
            -H "Authorization: Bearer ${{ secrets.RENDER_API_KEY }}"

      - name: Verify deployment
        run: curl -f https://devops-crud-app-backend.onrender.com/healthz
```

### Benefits of Parallelization

| Before | After |
|--------|-------|
| Sequential: 8m 30s | Parallel: ~4m 30s |
| Single failure blocks everything | Visible which job failed |
| Resource underutilized | Runners fully utilized |
| Can't see logs side-by-side | Each job has own logs |

**Result: 47% faster CI/CD pipeline**

## 3. 💾 Set Up Distributed Caching

### Cache npm Dependencies

```yaml
# In any GitHub Actions workflow job:
steps:
  - name: Checkout code
    uses: actions/checkout@v3

  - name: Setup Node.js
    uses: actions/setup-node@v3
    with:
      node-version: '18'
      cache: 'npm'  # ← Automatic npm cache (fastest)

  - name: Install dependencies
    run: npm ci  # Use 'ci' instead of 'install' for CI/CD
```

### Advanced Caching Strategy

```yaml
# Cache multiple locations
- name: 🗂️ Cache Dependencies and Build
  uses: actions/cache@v3
  with:
    path: |
      ~/.npm                    # Global npm cache
      node_modules             # Local dependencies
      dist                      # Build artifacts
      .next                     # Next.js cache
      .eslintcache            # ESLint cache
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
      ${{ runner.os }}-

# Cache Docker layers
- name: 🐳 Cache Docker Layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-
```

### Cache Key Strategy

```yaml
# Good: Specific key based on dependencies
key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
# Invalidates when package-lock.json changes ✅

# Better: Multiple fallback layers
restore-keys: |
  ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
  ${{ runner.os }}-node-
# Tries exact match first, falls back to partial match ✅

# Avoid: Time-based keys (always cache miss)
key: ${{ runner.os }}-node-${{ github.run_id }}
# Defeats purpose - creates new cache every run ❌
```

### Caching Performance Impact

```
First Run:
  npm install: 2m 15s (no cache)
  Total: 5m 30s

Subsequent Runs:
  npm install: 15s (from cache) ✅
  Total: 3m 15s

Savings per push: ~2m 15s (40% faster)
Annual savings: ~18 hours/month (assuming 400 commits/month)
```

## 4. 📈 Create Performance Benchmarks

### Automated Benchmark Workflow

Create `.github/workflows/performance-benchmark.yml`:

```yaml
name: Performance Benchmark

on:
  push:
    branches: [main]
  schedule:
    # Run every Monday at 2 AM UTC
    - cron: '0 2 * * 1'

jobs:
  benchmark:
    name: Run Performance Benchmarks
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: 📊 Benchmark: Cold Start (no cache)
        id: cold_start
        run: |
          rm -rf node_modules
          START=$(date +%s%N | cut -b1-13)
          npm ci > /dev/null 2>&1
          END=$(date +%s%N | cut -b1-13)
          DURATION=$((($END - $START) / 1000))
          echo "duration_ms=$DURATION" >> $GITHUB_OUTPUT
          echo "Cold Start: ${DURATION}ms"

      - name: 📊 Benchmark: Warm Start (with cache)
        id: warm_start
        run: |
          rm -rf node_modules
          START=$(date +%s%N | cut -b1-13)
          npm ci > /dev/null 2>&1
          END=$(date +%s%N | cut -b1-13)
          DURATION=$((($END - $START) / 1000))
          echo "duration_ms=$DURATION" >> $GITHUB_OUTPUT
          echo "Warm Start: ${DURATION}ms"

      - name: 📊 Benchmark: Tests
        id: tests
        run: |
          START=$(date +%s%N | cut -b1-13)
          npm test > /dev/null 2>&1
          END=$(date +%s%N | cut -b1-13)
          DURATION=$((($END - $START) / 1000))
          echo "duration_ms=$DURATION" >> $GITHUB_OUTPUT
          echo "Test Suite: ${DURATION}ms"

      - name: 📊 Benchmark: Build
        id: build
        run: |
          START=$(date +%s%N | cut -b1-13)
          npm run build > /dev/null 2>&1
          END=$(date +%s%N | cut -b1-13)
          DURATION=$((($END - $START) / 1000))
          echo "duration_ms=$DURATION" >> $GITHUB_OUTPUT
          echo "Build: ${DURATION}ms"

      - name: 📝 Update Benchmark Report
        run: |
          cat >> performance-report.md << EOF
          ## Benchmark Run - $(date '+%Y-%m-%d %H:%M:%S')
          
          | Metric | Duration | Status |
          |--------|----------|--------|
          | Cold Start | ${{ steps.cold_start.outputs.duration_ms }}ms | ${{ steps.cold_start.outcome }} |
          | Warm Start | ${{ steps.warm_start.outputs.duration_ms }}ms | ${{ steps.warm_start.outcome }} |
          | Tests | ${{ steps.tests.outputs.duration_ms }}ms | ${{ steps.tests.outcome }} |
          | Build | ${{ steps.build.outputs.duration_ms }}ms | ${{ steps.build.outcome }} |
          
          EOF

      - name: 📤 Commit Report
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add performance-report.md
          git commit -m "Update performance benchmark report"
          git push

      - name: ⚠️ Alert on Regression
        run: |
          COLD_START=${{ steps.cold_start.outputs.duration_ms }}
          THRESHOLD=60000  # 60 seconds threshold
          if [ $COLD_START -gt $THRESHOLD ]; then
            echo "⚠️ WARNING: Cold start time exceeds threshold!"
            echo "Current: ${COLD_START}ms, Threshold: ${THRESHOLD}ms"
            exit 1
          fi
```

### GitHub Actions Performance Insights

View automatic performance data:

```
GitHub Repository → Actions → Select Workflow Run

Shows:
- Duration of each job
- Duration of each step
- Queue time
- Total wall-clock time
```

## 5. 💰 Plan for Growth Beyond Free Tiers

### GitHub Actions Free Tier Limits

```
Free Plan:
  ├─ 2,000 minutes/month (GitHub-hosted runners)
  ├─ 500 MB storage
  ├─ Unlimited public repos
  └─ Unlimited workflows

Pro Plan:
  ├─ 3,000 minutes/month
  ├─ 1 GB storage
  └─ $4/month per additional 1,000 minutes
```

### Cost Estimation

```
Current Usage:
  ├─ 1 push per day = 30 pushes/month
  ├─ Each push: ~5 min (CI) + 3 min (security) = 8 min
  ├─ Monthly: 30 × 8 = 240 minutes/month
  └─ Cost: FREE (under 2,000 min limit)

Growth Scenario (10x):
  ├─ 300 pushes/month
  ├─ Each: 8 min
  ├─ Monthly: 2,400 minutes/month
  └─ Cost: 400 min × $0.25/min = $100/month
```

### Optimization Strategies

**Strategy 1: Reduce Pipeline Duration**
```yaml
# Current: 8 min per push
# Optimized: 4 min per push (parallelization + caching)
# Result: 1,200 min/month at 10x growth = under limit

- Use parallelization (job optimization)
- Implement caching (npm, Docker)
- Skip unnecessary jobs on certain paths
```

**Strategy 2: Conditional Workflows**
```yaml
name: CI

on: [push]

jobs:
  test:
    if: contains(github.event.head_commit.modified, 'src/')
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  security:
    if: contains(github.event.head_commit.modified, 'backend/')
    runs-on: ubuntu-latest
    steps:
      - run: npm audit
```

**Strategy 3: Self-Hosted Runners**
```yaml
jobs:
  build:
    runs-on: self-hosted  # 0 cost, own hardware
    steps:
      - uses: actions/checkout@v3
      - run: npm ci && npm run build
```

### Migration Path: GitHub Actions → Advanced Tools

```
Stage 1 (Now): GitHub Actions
  ├─ Free tier sufficient
  ├─ Easy to use
  └─ Good for learning

Stage 2 (Small Team): GitHub Actions Pro + Self-Hosted
  ├─ 1-2 self-hosted runners
  ├─ Parallelized workflows
  └─ Cost: ~$100-200/month

Stage 3 (Scale): Jenkins/CircleCI/GitLab
  ├─ Better performance
  ├─ Advanced caching
  ├─ Custom docker images
  └─ Cost: $500-2000+/month

Stage 4 (Enterprise): Self-Hosted Jenkins
  ├─ Full control
  ├─ Advanced optimization
  ├─ Custom infrastructure
  └─ Cost: Infrastructure + maintenance
```

## 6. 🚀 Auto-Scale Infrastructure with IaC

### Terraform: Dynamic Scaling

Create `terraform/performance.tf`:

```hcl
# Auto-scaling group for self-hosted runners
resource "aws_autoscaling_group" "ci_runners" {
  name                = "devops-ci-runners"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 1
  max_size            = 10
  desired_capacity    = 3

  launch_template {
    id      = aws_launch_template.ci_runner.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "GitHub-CI-Runner"
    propagate_launch_template = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch template for CI runners
resource "aws_launch_template" "ci_runner" {
  name_prefix = "ci-runner-"
  image_id    = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"  # 2 vCPU, 4 GB RAM

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "GitHub-CI-Runner"
    }
  }

  user_data = base64encode(templatefile("${path.module}/runner-setup.sh", {
    github_token = var.github_runner_token
    repository   = var.github_repository
  }))
}

# Scale based on CPU usage
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "ci-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ci_runners.name
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "ci-runners-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}
```

### Docker Compose: Local Multi-Runner Setup

Create `docker-compose.ci.yml`:

```yaml
version: '3.8'

services:
  runner-1:
    image: myoung34/github-runner:ubuntu-jammy
    environment:
      REPO_URL: https://github.com/Joseligos/DevOps
      RUNNER_TOKEN: ${{ secrets.RUNNER_TOKEN }}
      RUNNER_NAME: ci-runner-1
      RUNNER_WORKDIR: /tmp/runner-work
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped

  runner-2:
    image: myoung34/github-runner:ubuntu-jammy
    environment:
      REPO_URL: https://github.com/Joseligos/DevOps
      RUNNER_TOKEN: ${{ secrets.RUNNER_TOKEN }}
      RUNNER_NAME: ci-runner-2
      RUNNER_WORKDIR: /tmp/runner-work
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped

  runner-3:
    image: myoung34/github-runner:ubuntu-jammy
    environment:
      REPO_URL: https://github.com/Joseligos/DevOps
      RUNNER_TOKEN: ${{ secrets.RUNNER_TOKEN }}
      RUNNER_NAME: ci-runner-3
      RUNNER_WORKDIR: /tmp/runner-work
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

## 7. 🎯 Performance Optimization Checklist

### Immediate (This Week)

- [ ] Implement npm caching in all workflows
- [ ] Add parallel jobs (test + lint + build)
- [ ] Add timing metrics to workflows
- [ ] Create performance baseline document

### Short-term (This Month)

- [ ] Set up automated benchmarks
- [ ] Reduce cold start time by 30%
- [ ] Implement conditional job execution
- [ ] Document scaling strategy

### Medium-term (This Quarter)

- [ ] Evaluate self-hosted runners
- [ ] Set up auto-scaling infrastructure
- [ ] Reduce total pipeline time by 50%
- [ ] Implement cost tracking

### Long-term (This Year)

- [ ] Migrate to advanced CI/CD tool if needed
- [ ] Implement full IaC with Terraform
- [ ] Support 100+ concurrent deployments
- [ ] Achieve <5min end-to-end pipeline

## 8. 📊 Performance Dashboard

Create `PERFORMANCE_METRICS.md`:

```markdown
# Performance Metrics Dashboard

## Current Pipeline Performance

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Avg Build Time | 4m 30s | <5m | ✅ |
| Avg Cache Hit Rate | 85% | >80% | ✅ |
| Parallelization | 3 jobs | 5 jobs | 🟡 |
| Deploy Frequency | 30/month | 100/month | 🟡 |
| Failure Rate | 2% | <5% | ✅ |

## Time Breakdown

```
Total: 4m 30s
├─ Setup: 30s (11%)
├─ Tests: 1m 30s (33%)
├─ Lint: 45s (17%)
├─ Build: 1m 15s (28%)
└─ Deploy: 30s (11%)
```

## Growth Projection

```
Month | Commits | Minutes Used | Cost | Utilization |
-------|---------|--------------|------|-------------|
Nov | 30 | 240 | $0 | 12% |
Dec | 45 | 360 | $0 | 18% |
Jan | 60 | 480 | $0 | 24% |
Feb | 100 | 800 | $0 | 40% |
Mar | 150 | 1200 | $0 | 60% |
Apr | 300 | 2400 | $100 | 120% ⚠️ |
```

---

## Next Steps

1. **Implement Parallelization** (5 min setup)
2. **Enable Caching** (2 min setup)
3. **Add Benchmarks** (10 min setup)
4. **Track Metrics** (ongoing)
5. **Plan for Scale** (quarterly review)

---

**Project**: DevOps CRUD App  
**Last Updated**: 2024-11-06  
**Performance Goal**: <5min end-to-end pipeline  
**Scaling Strategy**: Parallel + Cache + Auto-scale
