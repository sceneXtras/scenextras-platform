# SceneXtras Dokku Deployment Instructions

This document describes the deployment architecture and procedures for all SceneXtras services deployed to Dokku.

## Infrastructure Overview

| Component | Host | Platform |
|-----------|------|----------|
| **Dokku Server** | `dokku-scenextras.eastus.cloudapp.azure.com` | Azure VM |
| **Frontend** | Vercel (automatic via GitHub webhook) | Vercel |

## Service Deployment Summary

| Service | GitHub Repo | Dokku App Name | Deployment Method |
|---------|-------------|----------------|-------------------|
| **Python API** | `Securiteru/sceneXtras` | `scenextras` / `scenextras-test` | GitHub Actions → git push |
| **Go Search Engine** | `sceneXtras/golang_search_engine` | `scenextras-autocomplete` | GitHub Actions → stop-rebuild |
| **Go Auth Gateway** | `sceneXtras/golang_auth_gateway` | `scenextras-gateway` | GitHub Actions → git push |
| **React Frontend** | `sceneXtras/frontend_webapp` | N/A | Vercel auto-deploy |

---

## Zero-Downtime Deployment Requirements

**IMPORTANT:** All Dokku-deployed services MUST implement health checks to ensure zero-downtime deployments. Failed deployments should NOT replace working containers.

### Required Files for Each Service

Every containerized service must include:

1. **`CHECKS`** - Dokku health check definitions
2. **`app.json`** - Dokku app config with healthchecks
3. **`Dockerfile`** - With `HEALTHCHECK` instruction
4. **Health endpoints** - `/ping`, `/health`, `/ready`

See the "Zero-Downtime Deployment (Dokku)" section in `CLAUDE.md` for detailed implementation instructions.

---

## 1. Python API (`sceneXtras/`)

### Deployment Flow

```
Push to main/test branch
    ↓
GitHub Actions triggers (.github/workflows/test.yml)
    ↓
SSH key loaded (DOKKU_TEST_SSH_KEY)
    ↓
git push dokku main:master --force
    ↓
Dokku builds container (uses CHECKS, app.json, Dockerfile)
    ↓
Health checks pass → containers swap (zero-downtime)
```

### Git Remotes

```bash
dokku      → dokku@dokku-scenextras.eastus.cloudapp.azure.com:scenextras
dokku-test → dokku@dokku-scenextras.eastus.cloudapp.azure.com:scenextras-test
origin     → https://github.com/Securiteru/sceneXtras.git
```

### Manual Deployment

```bash
cd sceneXtras

# Deploy to production
git push dokku main

# Deploy to test environment
git push dokku-test test

# Or use the deployment script
./deploy_dokku.sh
```

### Health Check Endpoints

| Endpoint | Response | Purpose |
|----------|----------|---------|
| `/ping` | `pong` | Liveness check |
| `/healthcheck/db` | `alive` | Database connectivity |
| `/healthcheck/ready` | `ready` (200) or 503 | Full readiness check |

### Viewing Logs

```bash
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com logs scenextras -t
```

---

## 2. Go Search Engine (`golang_search_engine/`)

### Special Deployment Requirements

**BadgerDB Constraint:** This service uses BadgerDB, a single-process file-based database. Standard Dokku zero-downtime deployment runs both old and new containers simultaneously, causing database lock conflicts.

**Solution:** Use the stop-rebuild strategy instead of standard git push.

### Deployment Flow

```
Push to main branch
    ↓
GitHub Actions triggers (.github/workflows/deploy.yml)
    ↓
SSH key loaded (DOKKU_TEST_SSH_KEY)
    ↓
Runs scripts/deploy_badgerdb.sh:
    Step 1: dokku ps:stop scenextras-autocomplete
    Step 2: Wait 5 seconds (release database lock)
    Step 3: dokku ps:rebuild scenextras-autocomplete
    ↓
Health check at http://52.149.141.25:5000/health
    ↓
Discord notification on success/failure
```

### Git Remotes

```bash
dokku  → dokku@dokku-scenextras.eastus.cloudapp.azure.com:scenextras-autocomplete
origin → https://github.com/sceneXtras/golang_search_engine.git
```

### Manual Deployment

```bash
cd golang_search_engine

# Recommended: Use the BadgerDB-compatible script
./scripts/deploy_badgerdb.sh

# Alternative: Standard git push (may cause issues with BadgerDB)
git push dokku main
```

### Health Check Endpoints

| Endpoint | Response | Purpose |
|----------|----------|---------|
| `/ping` | `pong` | Liveness check |
| `/health` | `{"status": "healthy", ...}` | Health status |
| `/ready` | `{"status": "ready"}` or 503 | Readiness check |

### Service URLs

- **Health:** http://52.149.141.25:5000/health
- **Search:** http://52.149.141.25:5000/api/search?q=batman
- **Init Cache:** http://52.149.141.25:5000/api/search/init

### Cache Rebuild After Deployment

After deployment, you may need to rebuild the search cache:

```bash
# Clear old cache
curl -X DELETE http://52.149.141.25:5000/api/search/cache

# Build new cache (takes ~30-60 minutes)
curl -X POST http://52.149.141.25:5000/api/cache/enterprise/build \
  -H 'Content-Type: application/json' \
  -d '{
    "movies_limit": 5000,
    "series_limit": 5000,
    "animes_limit": 5000,
    "cartoons_limit": 5000,
    "cast_limit": 10,
    "include_actors": true
  }'

# Monitor progress
curl http://52.149.141.25:5000/api/cache/enterprise/progress
```

---

## 3. Go Auth Gateway (`golang_auth_gateway/`)

### Initial Setup (One-Time)

```bash
# Create the Dokku app on the server
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com apps:create scenextras-gateway

# Add the git remote locally
cd golang_auth_gateway
git remote add dokku dokku@dokku-scenextras.eastus.cloudapp.azure.com:scenextras-gateway

# Set required environment variables
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com config:set scenextras-gateway \
  PORT=8080 \
  SUPABASE_URL=your_supabase_url \
  SUPABASE_JWT_SECRET=your_jwt_secret \
  CHAT_SERVICE_URL=http://scenextras.web.1:5000 \
  CORE_SERVICE_URL=http://scenextras.web.1:5000 \
  DATABASE_URL=your_database_url
```

### Deployment Flow

```
Push to main branch
    ↓
GitHub Actions triggers (workflow to be created)
    ↓
SSH key loaded (DOKKU_TEST_SSH_KEY)
    ↓
git push dokku main
    ↓
Dokku builds container (uses CHECKS, app.json, Dockerfile)
    ↓
Health checks pass → containers swap (zero-downtime)
```

### Git Remotes

```bash
dokku  → dokku@dokku-scenextras.eastus.cloudapp.azure.com:scenextras-gateway
origin → git@github.com:sceneXtras/golang_auth_gateway.git
```

### Manual Deployment

```bash
cd golang_auth_gateway
git push dokku main
```

### Health Check Endpoints

| Endpoint | Response | Purpose |
|----------|----------|---------|
| `/ping` | `pong` | Liveness check |
| `/health` | `{"status": "ok", ...}` | Health status |
| `/ready` | `{"status": "ready"}` or 503 | Readiness check |

---

## 4. React Frontend (`frontend_webapp/`)

### Deployment Flow

The frontend is deployed to **Vercel**, not Dokku. Vercel automatically deploys on push to main via GitHub webhook integration.

```
Push to main branch
    ↓
GitHub Actions triggers (.github/workflows/deploy-with-sourcemaps.yml)
    ↓
Build with sourcemaps
    ↓
Upload sourcemaps to PostHog and Sentry
    ↓
Remove .map files from build
    ↓
Vercel auto-deploys via GitHub webhook
```

### Git Remotes

```bash
origin → https://github.com/sceneXtras/frontend_webapp.git
```

---

## GitHub Actions Workflows

### Python API (`sceneXtras/.github/workflows/test.yml`)

- **Triggers:** Push to `main` or `test` branches
- **Action:** Git push to Dokku remote
- **Environment:** `scenextras`

### Go Search Engine (`golang_search_engine/.github/workflows/deploy.yml`)

- **Triggers:** Push to `main` branch, manual dispatch
- **Action:** SSH + stop-rebuild script (BadgerDB compatible)
- **Environment:** `scenextras`
- **Notifications:** Discord webhook

### React Frontend (`frontend_webapp/.github/workflows/deploy-with-sourcemaps.yml`)

- **Triggers:** Push to `main` branch, manual dispatch
- **Action:** Build + sourcemap upload (Vercel deploys automatically)
- **Environment:** `Production`

---

## GitHub Secrets Required

| Secret | Used By | Purpose |
|--------|---------|---------|
| `DOKKU_TEST_SSH_KEY` | All Dokku deployments | SSH private key for Dokku access |
| `DISCORD_WEBHOOK_URL` | Go Search Engine | Deployment notifications |
| `SENTRY_AUTH_TOKEN` | Frontend | Sourcemap uploads |
| `SENTRY_ORG` | Frontend | Sentry organization |
| `SENTRY_PROJECT` | Frontend | Sentry project name |
| `POSTHOG_API_KEY` | Frontend | Sourcemap uploads |
| `SLACK_WEBHOOK` | Frontend | Build notifications |
| `REACT_APP_SENTRY_DSN` | Frontend | Sentry DSN for builds |

---

## Common Dokku Commands

### App Management

```bash
# SSH into Dokku server
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com

# List all apps
dokku apps:list

# Check app status
dokku ps:report scenextras
dokku ps:report scenextras-autocomplete
dokku ps:report scenextras-gateway

# View app configuration
dokku config:show scenextras
```

### Logs

```bash
# View logs (follow mode)
dokku logs scenextras -t
dokku logs scenextras-autocomplete -t

# View last N lines
dokku logs scenextras -n 100
```

### Container Management

```bash
# Restart app
dokku ps:restart scenextras

# Stop app
dokku ps:stop scenextras

# Start app
dokku ps:start scenextras

# Rebuild app (triggers new deployment)
dokku ps:rebuild scenextras
```

### Environment Variables

```bash
# Set environment variable
dokku config:set scenextras KEY=value

# Unset environment variable
dokku config:unset scenextras KEY

# View all environment variables
dokku config:show scenextras
```

### Domains and SSL

```bash
# Add domain
dokku domains:add scenextras example.com

# Enable SSL (Let's Encrypt)
dokku letsencrypt:enable scenextras

# View domains
dokku domains:report scenextras
```

### Storage and Volumes

```bash
# Mount persistent storage
dokku storage:mount scenextras /var/lib/dokku/data/storage/scenextras:/data

# List mounts
dokku storage:list scenextras
```

---

## Troubleshooting

### Deployment Fails Health Checks

1. Check the CHECKS file exists and endpoints are correct
2. Verify health endpoints return expected content
3. Check app logs for startup errors:
   ```bash
   dokku logs scenextras -n 200
   ```

### BadgerDB Lock Error (Go Search Engine)

If you see "database locked" errors:

1. Stop the current container first:
   ```bash
   ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com ps:stop scenextras-autocomplete
   ```
2. Wait 5-10 seconds
3. Rebuild:
   ```bash
   ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com ps:rebuild scenextras-autocomplete
   ```

### SSH Connection Issues

1. Verify SSH key is loaded:
   ```bash
   ssh-add -l
   ```
2. Test connection:
   ```bash
   ssh -o BatchMode=yes dokku@dokku-scenextras.eastus.cloudapp.azure.com "echo OK"
   ```
3. Check known_hosts:
   ```bash
   ssh-keyscan dokku-scenextras.eastus.cloudapp.azure.com >> ~/.ssh/known_hosts
   ```

### Container Won't Start

1. Check for build errors:
   ```bash
   dokku ps:rebuild scenextras 2>&1 | tail -50
   ```
2. Verify environment variables are set:
   ```bash
   dokku config:show scenextras
   ```
3. Check Dockerfile syntax and dependencies

### Rolling Back a Deployment

Dokku doesn't have built-in rollback, but you can:

1. Revert the git commit locally
2. Force push to Dokku:
   ```bash
   git revert HEAD
   git push dokku main --force
   ```

Or redeploy a specific commit:
```bash
git checkout <commit-hash>
git push dokku HEAD:main --force
```

---

## Creating GitHub Actions Workflow for New Service

Use this template for new Dokku-deployed services:

```yaml
name: Deploy to Dokku

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: scenextras

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up SSH
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.DOKKU_TEST_SSH_KEY }}

      - name: Add Dokku host to known_hosts
        run: ssh-keyscan -H dokku-scenextras.eastus.cloudapp.azure.com >> ~/.ssh/known_hosts

      - name: Set Git identity
        run: |
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"

      - name: Deploy to Dokku
        env:
          DOKKU_REMOTE: dokku@dokku-scenextras.eastus.cloudapp.azure.com:your-app-name
        run: |
          git remote add dokku $DOKKU_REMOTE || true
          git push dokku main --force

      - name: Notify on failure
        if: failure()
        run: |
          echo "Deployment failed - check logs"
```

---

## Security Considerations

1. **SSH Keys:** Store `DOKKU_TEST_SSH_KEY` as a GitHub secret, never commit to repo
2. **Environment Variables:** Use `dokku config:set` for secrets, not Dockerfile
3. **Health Endpoints:** Don't expose sensitive data in health check responses
4. **Network:** Dokku apps run on internal network, use nginx proxy for external access
5. **SSL:** Always enable Let's Encrypt for production domains

---

## Related Documentation

- **Zero-Downtime Deployment Details:** See `CLAUDE.md` → "Zero-Downtime Deployment (Dokku)"
- **Python API Makefile:** `sceneXtras/api/Makefile`
- **Go Search Engine API:** `golang_search_engine/API_DOCUMENTATION.md`
- **Dokku Official Docs:** https://dokku.com/docs/getting-started/installation/
