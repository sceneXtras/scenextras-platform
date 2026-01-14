# SceneXtras Discord Monitoring & Notifications Setup

## Overview

This document describes the unified monitoring and notification system for all SceneXtras services using Discord webhooks.

## Services Monitored

### 1. **Go Autocomplete Service**
- **Health Monitoring**: Hourly checks via GitHub Actions
- **Deployment Notifications**: Automated on every push to `main`
- **Location**: `golang_search_engine/`
- **Workflows**:
  - `.github/workflows/uptime-monitor.yml`
  - `.github/workflows/deploy.yml`

### 2. **Python API Backend**
- **Health Monitoring**: Hourly checks for both Production and Test environments
- **Deployment Notifications**: Automated on push to `main`, `dokku`, or `test` branches
- **Location**: `sceneXtras/api/`
- **Workflows**:
  - `.github/workflows/health-monitor.yml`
  - `.github/workflows/deploy-notify.yml`
- **Endpoints**:
  - Production: `https://backend.scenextras.com/health`
  - Test: `https://test.backend.scenextras.com/health`

### 3. **React Web Frontend**
- **Health Monitoring**: Every 2 hours with performance metrics
- **Deployment Notifications**: Automated via Vercel webhooks
- **Location**: `frontend_webapp/`
- **Workflows**:
  - `.github/workflows/health-monitor.yml`
  - `.github/workflows/deploy-notify.yml`
- **Endpoint**: `https://scenextras.com`

### 4. **React Native Mobile App**
- **Build Notifications**: Automated on push to `main` or `develop`
- **Location**: `mobile_app_sx/`
- **Workflows**:
  - `.github/workflows/build-notify.yml`

## Discord Webhook Configuration

### Secret Setup

All repositories use **environment-scoped secrets** for better security and isolation:

1. **Python API** (Securiteru/sceneXtras):
   - Navigate to: Repository → Settings → Environments → `scenextras`
   - Secret: `DISCORD_WEBHOOK_URL` ✅ **Already configured**

2. **Go Autocomplete** (sceneXtras/golang_search_engine):
   - Navigate to: Repository → Settings → Environments → `scenextras`
   - Secret: `DISCORD_WEBHOOK_URL` ✅ **Already configured**

3. **React Web Frontend** (sceneXtras/frontend_webapp):
   - Navigate to: Repository → Settings → Environments → `Production`
   - Secret: `DISCORD_WEBHOOK_URL` ✅ **Already configured**

4. **Mobile App** (sceneXtras/mobile_app_sx):
   - Navigate to: Repository → Settings → Environments → `Production`
   - Secret: `DISCORD_WEBHOOK_URL` ✅ **Already configured**

**Note**: All secrets are already configured. The workflows now correctly reference their respective environments.

### Webhook URL

The Discord webhook URL format:
```
https://discord.com/api/webhooks/{webhook_id}/{webhook_token}
```

**Current webhook**: `https://discord.com/api/webhooks/1426132484629856358/trfkiTqm69HkLy1tr5gc3D0z_-k_pZgzg6cID5xbhwTrWbP11DrKM1OG36k70BZzXK8E`

## Notification Types

### 🚀 Deployment Started (Blue - 3447003)
- Triggered when a deployment begins
- Includes: Environment, Branch, Commit info, Actor

### ✅ Deployment/Build Successful (Green - 65280)
- Triggered when deployment/build completes successfully
- Includes: Environment, URL, Status, Commit info

### 🚨 Deployment/Build Failed (Red - 16711680)
- Triggered when deployment/build fails
- Includes: Error details, Logs link, Commit info

### ⚠️ Health Check Warning (Yellow - 16776960)
- Triggered when service is degraded but not down
- Examples: Slow response time, test environment issues

### 📊 Daily Health Report (Green - 65280)
- Sent once per day at 12:00 UTC
- Includes: Status of all services, Response times

## Monitoring Features

### Health Checks

#### Go Autocomplete Service
- **Frequency**: Every hour
- **Checks**:
  - Container status (via SSH to Dokku)
  - Health endpoint response (`http://52.149.141.25:5000/health`)
  - Recent deployment failures
  - Database corruption detection
  - Cache statistics

#### Python API
- **Frequency**: Every hour
- **Checks**:
  - Production health endpoint
  - Test environment health endpoint
  - HTTP status codes
  - Response availability

#### React Web Frontend
- **Frequency**: Every 2 hours
- **Checks**:
  - HTTP status code
  - Content loading verification
  - Response time (threshold: 3000ms)
  - Performance metrics

### Deployment Tracking

#### Go Autocomplete
- **Strategy**: Stop-Rebuild (BadgerDB compatible)
- **Steps**:
  1. Stop old container
  2. Rebuild with latest code
  3. Health check verification (30 attempts)
  4. Discord notifications at each step

#### Python API
- **Strategy**: Git push to Dokku
- **Notifications**:
  1. Deployment started
  2. 60-second wait period
  3. Health check (10 attempts, 10s intervals)
  4. Success or failure notification

#### React Web
- **Strategy**: Vercel automatic deployment
- **Triggered by**: Vercel `deployment_status` events
- **Notifications**: Success/Failure based on Vercel status

#### Mobile App
- **Strategy**: GitHub Actions build validation
- **Steps**:
  1. Type checking
  2. Test execution
  3. Build status notification

## Alert Thresholds

| Service | Metric | Threshold | Action |
|---------|--------|-----------|--------|
| Go Autocomplete | Response Time | > 30ms | Warning (future) |
| Go Autocomplete | Container Down | Any | Critical Alert |
| Python API | HTTP Status | != 200 | Critical Alert |
| React Web | Response Time | > 3000ms | Performance Warning |
| React Web | HTTP Status | != 200 | Critical Alert |
| Mobile App | Build | Failed | Critical Alert |

## Manual Testing

### Trigger Health Check Manually

```bash
# Go Autocomplete
cd golang_search_engine
gh workflow run uptime-monitor.yml

# Python API
cd sceneXtras/api
gh workflow run health-monitor.yml

# React Web
cd frontend_webapp
gh workflow run health-monitor.yml
```

### Test Webhook Directly

```bash
# Success notification
curl -H "Content-Type: application/json" -X POST -d '{
  "embeds": [{
    "title": "✅ Test Notification",
    "description": "Testing webhook integration",
    "color": 65280
  }]
}' "YOUR_WEBHOOK_URL"

# Failure notification
curl -H "Content-Type: application/json" -X POST -d '{
  "embeds": [{
    "title": "🚨 Test Alert",
    "description": "Testing critical alert",
    "color": 16711680
  }]
}' "YOUR_WEBHOOK_URL"
```

## Troubleshooting

### Webhook not working

1. **Check secret is set**:
   - Go to repository Settings → Secrets
   - Verify `DISCORD_WEBHOOK_URL` exists

2. **Check webhook URL is valid**:
   - Test with curl command above
   - Verify webhook hasn't been deleted in Discord

3. **Check workflow permissions**:
   - Settings → Actions → General
   - Ensure "Read and write permissions" are enabled

### False alerts

1. **Check service health manually**:
   ```bash
   curl https://backend.scenextras.com/health
   curl https://scenextras.com
   curl http://52.149.141.25:5000/health
   ```

2. **Review workflow logs**:
   - Actions → Select failed workflow
   - Check each step's output

3. **Verify SSH access** (Go Autocomplete only):
   - Ensure `scenextras` environment has `DOKKU_TEST_SSH_KEY`
   - Verify key is valid and has correct permissions

## Future Enhancements

- [ ] Add Slack integration alongside Discord
- [ ] Implement PagerDuty for critical alerts
- [ ] Add response time trends and analytics
- [ ] Create dashboard for all services status
- [ ] Add automatic recovery mechanisms
- [ ] Implement rate limiting for notifications
- [ ] Add custom alert rules per service
- [ ] Create weekly/monthly reports

## Related Documentation

- Go Autocomplete: `golang_search_engine/docs/BADGERDB_DEPLOYMENT_GUIDE.md`
- Python API: `sceneXtras/api/AGENTS.md`
- React Web: `frontend_webapp/docs/`
- Mobile App: `mobile_app_sx/docs/`

