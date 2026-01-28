# Huginn on Dokku

Automation platform deployment for SceneXtras infrastructure.

## Quick Start

```bash
# 1. Configure
cp .env.example .env
# Edit .env with your values

# 2. Source environment
source .env

# 3. Setup infrastructure (first time only)
./deploy.sh setup

# 4. Deploy
./deploy.sh deploy
```

## Commands

| Command | Description |
|---------|-------------|
| `./deploy.sh setup` | Create app, database, SSL |
| `./deploy.sh deploy` | Deploy/redeploy Huginn |
| `./deploy.sh logs` | Tail application logs |
| `./deploy.sh status` | Check app health |
| `./deploy.sh rollback` | Rollback to previous version |
| `./deploy.sh console` | Rails console access |
| `./deploy.sh run-script <file>` | Run Ruby script in container |

## Deploy Automation Scenarios

Pre-built scenarios in `scripts/`:

```bash
# Revenue monitoring (RevenueCat + Stripe -> Discord)
DISCORD_WEBHOOK_URL=https://... ./deploy.sh run-script scripts/deploy_discord_monitor.rb

# Service health monitoring
DISCORD_WEBHOOK_URL=https://... ./deploy.sh run-script scripts/deploy_health_monitor.rb

# Bug report pipeline (Bug Report Service -> Linear + Discord)
LINEAR_API_KEY=xxx ./deploy.sh run-script scripts/deploy_bug_report_pipeline.rb

# Linear -> Customer.io support status pipeline
CUSTOMERIO_SITE_ID=xxx CUSTOMERIO_API_KEY=xxx ./deploy.sh run-script scripts/deploy_linear_customerio_pipeline.rb
```

### Linear -> Customer.io Support Status Pipeline

This pipeline monitors Linear issue status changes and updates Customer.io user profiles for support notifications.

**Workflow:**
1. User submits bug report → Bug Report Pipeline creates Linear issue with user email in description
2. Support team moves issue to "In Progress" → User marked `SUPPORT_REQUIRED` in Customer.io
3. Support team moves issue to "Done" → User marked `SUPPORT_FINISHED` in Customer.io
4. Customer.io campaigns can trigger notifications based on these attributes

**Setup:**

1. Deploy the pipeline:
   ```bash
   CUSTOMERIO_SITE_ID=xxx CUSTOMERIO_API_KEY=xxx ./deploy.sh run-script scripts/deploy_linear_customerio_pipeline.rb
   ```

2. Configure Linear webhook:
   - Go to Linear → Settings → Team Settings → Webhooks
   - Add the webhook URL from deployment output
   - Select "Issues" as resource type
   - Enable "Updated" events

**Customer.io Attributes Set:**
- `support_status`: `SUPPORT_REQUIRED` or `SUPPORT_FINISHED`
- `support_status_label`: Human-readable label
- `support_issue_id`: Linear issue ID (e.g., SX-123)
- `support_issue_url`: Link to the Linear issue
- `support_status_updated_at`: ISO timestamp

**Customer.io Segments:** Create segments like:
- "Users Awaiting Support": `support_status = SUPPORT_REQUIRED`
- "Users with Resolved Issues": `support_status = SUPPORT_FINISHED`

## Architecture

```
                    ┌─────────────────────────────────────┐
                    │           Dokku Host                │
                    │                                     │
  RevenueCat ──────►│  ┌─────────────────────────────┐   │
                    │  │         Huginn              │   │
  Stripe ──────────►│  │                             │   │
                    │  │  Webhook ─► Formatter ─►    │───┼──► Discord
  Custom ──────────►│  │                             │   │
                    │  │  Monitor ─► Trigger ─►      │   │
                    │  └─────────────────────────────┘   │
                    │              │                     │
                    │              ▼                     │
                    │        PostgreSQL                  │
                    └─────────────────────────────────────┘
```

## Webhook URLs

After deployment, webhook URLs follow this pattern:

```
https://huginn.scenextras.com/users/1/web_requests/{agent_id}/{secret}
```

Get exact URLs by running the deployment scripts - they output the full URLs.

## Custom Agents

Create new automation by:

1. Writing a Ruby script (see `scripts/` for examples)
2. Running via `./deploy.sh run-script your_script.rb`

### Agent Types Available

| Type | Use For |
|------|---------|
| `WebhookAgent` | Receive HTTP webhooks |
| `HttpStatusAgent` | Monitor HTTP endpoints |
| `JavaScriptAgent` | Transform/process data |
| `TriggerAgent` | Conditional routing |
| `PostAgent` | HTTP POST to external services |
| `SchedulerAgent` | Cron-like scheduling |
| `RssAgent` | Monitor RSS feeds |
| `EmailAgent` | Send emails |

## Troubleshooting

```bash
# Check logs
./deploy.sh logs

# Check container status
./deploy.sh status

# Enter container for debugging
./deploy.sh enter

# Access Rails console
./deploy.sh console
```
