# Dokku Deployment Guide - Bug Report API

This guide covers deploying the Bug Report API service to Dokku for zero-downtime deployments.

## Prerequisites

- Dokku host: `dokku-scenextras.eastus.cloudapp.azure.com`
- SSH key: `~/.ssh/dokku_azure`
- GitHub repository: `git@github.com:sceneXtras/scenextras-platform.git`

## Files for Zero-Downtime Deployment

The following files ensure zero-downtime deployments:

1. **Dockerfile** - Multi-stage build with health checks
2. **CHECKS** - Dokku health check configuration
3. **app.json** - Application metadata and healthcheck definitions
4. **.github/workflows/deploy.yml** - Auto-deployment on push to main
5. **.github/workflows/deployment-notify.yml** - Discord notifications

## Manual Deployment Steps

### 1. Create Dokku App (One-time setup)

SSH into the Dokku host:

```bash
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com

# Create the app
dokku apps:create bug-report

# Set environment variables
dokku config:set bug-report \
  PORT=5000 \
  GIN_MODE=release \
  AZURE_STORAGE_CONNECTION_STRING="your-connection-string" \
  AZURE_CONTAINER_NAME="bug-reports" \
  LOGWARD_API_KEY="your-logward-key"

# Configure domains (optional)
dokku domains:set bug-report bug-report.dokku-scenextras.eastus.cloudapp.azure.com

# Enable zero-downtime deployment
dokku checks:enable bug-report

# Set resource limits (optional)
dokku resource:limit bug-report --memory 512m
dokku resource:reserve bug-report --memory 256m

# Configure persistent storage (if needed)
# dokku storage:ensure-directory bug-report-data
# dokku storage:mount bug-report /var/lib/dokku/data/storage/bug-report-data:/data

exit
```

### 2. Deploy from Local Machine

From the bug-report directory:

```bash
# Add Dokku remote (one-time)
git remote add dokku dokku@dokku-scenextras.eastus.cloudapp.azure.com:bug-report

# Deploy
git push dokku main:master

# Or force push if needed
git push dokku main:master --force
```

### 3. Verify Deployment

```bash
# Check app status
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku ps:report bug-report"

# View logs
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku logs bug-report -t"

# Test health endpoint
curl https://bug-report.dokku-scenextras.eastus.cloudapp.azure.com/health
```

## Automatic Deployment (GitHub Actions)

The service is configured to auto-deploy on push to `main` branch.

### Required GitHub Secrets

Set these in your GitHub repository settings (Settings → Secrets and variables → Actions):

- `DOKKU_TEST_SSH_KEY` - SSH private key for Dokku deployment
- `DISCORD_WEBHOOK_URL` - Discord webhook for deployment notifications (optional)

### Workflow Files

- `.github/workflows/deploy.yml` - Main deployment workflow
- `.github/workflows/deployment-notify.yml` - Discord notifications

### Triggering Manual Deployment

1. Go to Actions tab in GitHub
2. Select "Deploy to Dokku" workflow
3. Click "Run workflow" → Choose branch → Run

## Zero-Downtime Deployment Flow

1. **GitHub Actions push** triggers deployment
2. **Dokku builds** new Docker image
3. **Health checks start**:
   - Wait 10 seconds before first check
   - Check `/health` endpoint
   - Retry up to 10 times over 60 seconds
4. **If health checks pass**:
   - New container replaces old one
   - Zero downtime transition
5. **If health checks fail**:
   - Old container keeps running
   - Deployment rolls back automatically

## Health Check Endpoints

The service provides one health endpoint:

- **`GET /health`** - Returns `{"status":"healthy","service":"bug-report-api","version":"1.0.0"}`

## Environment Variables

Required variables (set via `dokku config:set`):

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `PORT` | Server port | No | 5000 |
| `AZURE_STORAGE_CONNECTION_STRING` | Azure Blob Storage connection | Yes | - |
| `AZURE_CONTAINER_NAME` | Azure container name | No | bug-reports |
| `LOGWARD_API_KEY` | LogWard API key | No | - |
| `GIN_MODE` | Gin mode (debug/release) | No | release |

## Troubleshooting

### Deployment Fails Health Checks

```bash
# View real-time logs during deployment
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku logs bug-report -t"

# Check current config
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku config bug-report"

# Verify health endpoint manually
dokku run bug-report wget -O- http://localhost:5000/health
```

### Rollback to Previous Version

```bash
# List releases
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku ps:releases bug-report"

# Rollback to previous release
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku ps:rollback bug-report"
```

### View App Metrics

```bash
# Resource usage
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku resource:report bug-report"

# Process status
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku ps:report bug-report"
```

### Clear Build Cache

```bash
# If builds are failing, clear cache
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku repo:purge-cache bug-report"
```

## Monitoring

### Health Check

```bash
# Manual health check
curl -f https://bug-report.dokku-scenextras.eastus.cloudapp.azure.com/health

# Automated monitoring (add to cron)
*/5 * * * * curl -f https://bug-report.dokku-scenextras.eastus.cloudapp.azure.com/health || echo "Bug Report API is down!"
```

### Logs

```bash
# Follow logs
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku logs bug-report -t"

# View last 100 lines
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku logs bug-report -n 100"
```

## Scaling

```bash
# Scale to multiple instances (if needed)
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku ps:scale bug-report web=2"

# View current scale
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku ps:scale bug-report"
```

## SSL/TLS Configuration

```bash
# Enable Let's Encrypt SSL (if domain is configured)
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku letsencrypt:enable bug-report"

# Auto-renew SSL
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku letsencrypt:cron-job --add"
```

## Related Documentation

- [API Reference](./API_REFERENCE.md) - API endpoint documentation
- [React Native Client](./REACT_NATIVE_CLIENT.md) - Mobile client integration
- [Dokku Documentation](https://dokku.com/docs/deployment/zero-downtime-deploys/) - Zero-downtime deployments

## Support

For deployment issues:
1. Check GitHub Actions logs
2. Check Discord notifications (if configured)
3. SSH to Dokku host and view application logs
4. Review health check configuration in `CHECKS` and `app.json`
