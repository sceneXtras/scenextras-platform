# Emergency Rollback Procedures

This document describes how to quickly rollback SceneXtras Dokku services when a deployment is successful but causes production issues.

## Quick Reference (Copy & Paste)

```bash
# Fastest rollback commands (run from repo root)
./scripts/rollback/rollback.sh api previous       # Python API (~30s)
./scripts/rollback/rollback.sh gateway previous   # Auth Gateway (~30s)
./scripts/rollback/rollback.sh search previous    # Search Engine (~45s, has downtime)
./scripts/rollback/rollback.sh transcription previous  # Transcription Service (~30s)
```

## Severity Levels

| Level | Criteria | Response Time | Action |
|-------|----------|---------------|--------|
| **P1** | Service down, all users affected | Immediate | Rollback NOW |
| **P2** | Major feature broken, >50% users affected | < 5 minutes | Evaluate then rollback |
| **P3** | Minor feature broken, <50% users affected | < 15 minutes | Evaluate fix vs rollback |
| **P4** | Cosmetic issue, no functional impact | Next business day | Fix forward |

## Step-by-Step Rollback

### 1. Confirm the Issue (30 seconds)

```bash
# Check service health
curl https://scenextras.com/healthcheck/ready       # API
curl http://52.149.141.25:8080/health               # Gateway
curl http://52.149.141.25:5000/health               # Search

# Quick log check
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku logs scenextras -n 50"
```

### 2. Execute Rollback (30-60 seconds)

**Option A: Rollback to Previous Release (Fastest)**
```bash
./scripts/rollback/rollback.sh <service> previous
```

**Option B: Rollback to Specific Release**
```bash
# List available releases
./scripts/rollback/rollback.sh <service> --list

# Rollback to specific release number
./scripts/rollback/rollback.sh <service> release:5
```

**Option C: Rollback to Specific Tag**
```bash
# Deploy specific tagged version (created during deployment)
./scripts/rollback/rollback.sh <service> tag:pre-deploy-20231201-120000
```

### 3. Verify Recovery (30 seconds)

```bash
# Health check
curl https://scenextras.com/healthcheck/ready

# Quick smoke test
curl https://scenextras.com/ping
```

### 4. Post-Incident

1. Post in #incidents Slack channel
2. Create incident ticket
3. Schedule post-mortem within 24 hours

## Service-Specific Notes

### Python API (scenextras)
- **Rollback Time:** ~30 seconds
- **Zero Downtime:** Yes (Dokku blue-green)
- **Health URL:** `http://52.149.141.25:5000/healthcheck/ready`
- **Command:**
  ```bash
  ./scripts/rollback/rollback.sh api previous
  ```

### Go Auth Gateway (scenextras-gateway)
- **Rollback Time:** ~30 seconds
- **Zero Downtime:** Yes
- **Health URL:** `http://52.149.141.25:8080/health`
- **Command:**
  ```bash
  ./scripts/rollback/rollback.sh gateway previous
  ```

### Go Search Engine (scenextras-autocomplete)
- **Rollback Time:** ~45 seconds
- **Zero Downtime:** NO (BadgerDB requires stop-rebuild)
- **Expected Downtime:** 10-30 seconds
- **Health URL:** `http://52.149.141.25:5000/health`
- **Command:**
  ```bash
  ./scripts/rollback/rollback.sh search previous
  ```

### Go Transcription Service
- **Rollback Time:** ~30 seconds
- **Zero Downtime:** Yes
- **Health URL:** `http://52.149.141.25:5001/health`
- **Command:**
  ```bash
  ./scripts/rollback/rollback.sh transcription previous
  ```

## Manual Rollback (If Scripts Fail)

If the rollback scripts are unavailable, use these direct commands:

```bash
# SSH to Dokku
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com

# Rollback to previous
dokku ps:rollback scenextras

# Or rollback to specific release
dokku ps:rollback scenextras 3

# Or deploy specific tag
dokku tags:deploy scenextras pre-deploy-20231201-120000

# Check status
dokku ps:report scenextras

# View logs
dokku logs scenextras -n 100
```

## Rollback All Services

**Use with extreme caution - only for catastrophic failures:**

```bash
./scripts/rollback/rollback.sh all previous
```

This will prompt for confirmation before rolling back all services.

## Version Tags

Every deployment automatically creates a rollback tag:
- Format: `pre-deploy-YYYYMMDD-HHMMSS`
- Example: `pre-deploy-20231201-120000`

List available tags:
```bash
./scripts/rollback/rollback.sh <service> --list
```

## Configure Release Retention

By default, Dokku keeps 5 releases. To keep more:

```bash
# Keep last 10 releases for faster rollback options
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku ps:set scenextras release-history 10"
```

## Monitoring After Rollback

After rollback, monitor for 15-30 minutes:

```bash
# Tail logs
ssh dokku@dokku-scenextras.eastus.cloudapp.azure.com "dokku logs scenextras -t"

# Check error rates in PostHog/Sentry
# Monitor response times
```

## Rollback Decision Tree

```
Deployment Completed Successfully
         │
         ▼
Is the service healthy? ──No──► ROLLBACK IMMEDIATELY
         │
        Yes
         │
         ▼
Are there user-facing errors? ──Yes──► Check error rate
         │                                    │
        No                                    ▼
         │                            >1% of requests? ──Yes──► ROLLBACK
         │                                    │
         ▼                                   No
Monitor for 10 minutes                        │
         │                                    ▼
         ▼                            Is it P1/P2? ──Yes──► ROLLBACK
No issues? Deployment complete               │
                                            No
                                             │
                                             ▼
                                      Can fix in <1 hour? ──Yes──► Fix forward
                                             │
                                            No
                                             │
                                             ▼
                                         ROLLBACK
```

## Contacts

- **On-Call:** Check PagerDuty schedule
- **Slack:** #incidents, #engineering
- **Email:** engineering@scenextras.com

## Post-Mortem Template

After any P1/P2 rollback, create a post-mortem:

```markdown
## Incident: [Brief Description]
**Date:** YYYY-MM-DD
**Duration:** X minutes
**Severity:** P1/P2

### Timeline
- HH:MM - Deployment started
- HH:MM - Issue detected
- HH:MM - Rollback initiated
- HH:MM - Service restored

### Root Cause
[Description of what caused the issue]

### Impact
- Users affected: X
- Error rate: X%
- Revenue impact: $X

### Resolution
[How was it fixed]

### Action Items
- [ ] Item 1
- [ ] Item 2

### Lessons Learned
[What we learned]
```
