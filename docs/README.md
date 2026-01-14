# SceneXtras Documentation Index

Welcome to the SceneXtras project documentation. This guide helps you navigate all available resources.

---

## 📖 Core Documentation

### Development & Architecture
- **[CLAUDE.md](./CLAUDE.md)** - Master development guide with all instructions and standards
- **[MICROSERVICES_ARCHITECTURE.md](./MICROSERVICES_ARCHITECTURE.md)** - Complete system architecture overview
- **[COMPLETE_IMPLEMENTATION_SUMMARY.md](./COMPLETE_IMPLEMENTATION_SUMMARY.md)** - Project implementation summary

---

## 🔧 Integration Guides

All integration documentation is consolidated here. Each guide covers configuration, implementation, troubleshooting, and best practices.

### Analytics & Monitoring
- **[integrations/POSTHOG_INTEGRATION.md](./integrations/POSTHOG_INTEGRATION.md)** - Event tracking and user analytics
- **[integrations/SENTRY_INTEGRATION.md](./integrations/SENTRY_INTEGRATION.md)** - Error tracking and crash reporting

### Payments & Subscriptions
- **[integrations/REVENUECAT_INTEGRATION.md](./integrations/REVENUECAT_INTEGRATION.md)** - Subscription and in-app purchase management

---

## 🚀 Guides & Setup

Step-by-step guides for common tasks and setup procedures.

### Deployment & Infrastructure
- **[guides/DEPLOYMENT.md](./guides/DEPLOYMENT.md)** - Zero-downtime deployment with Dokku, health checks, and graceful shutdown

### Configuration & Development
- **[guides/SESSION_TOKEN_LOGGING.md](./guides/SESSION_TOKEN_LOGGING.md)** - Session token logging configuration
- **[guides/DISCORD_MONITORING_SETUP.md](./guides/DISCORD_MONITORING_SETUP.md)** - Discord monitoring setup
- **[guides/PRE_MOBILE_LAUNCH_CHECKLIST_PROMPTS.md](./guides/PRE_MOBILE_LAUNCH_CHECKLIST_PROMPTS.md)** - Pre-launch checklist for mobile

---

## 🎯 Features & Functionality

Documentation about specific features and capabilities.

- **[features/CHAT.md](./features/CHAT.md)** - Chat system documentation
- **[features/ROLEPLAY.md](./features/ROLEPLAY.md)** - Roleplay scenario flows
- **[features/FEATURE_PARITY_COMPARISON.md](./features/FEATURE_PARITY_COMPARISON.md)** - Feature parity across platforms

### MCP Integration
- **[features/mcp/](./features/mcp/)** - Model Context Protocol implementation documentation

---

## 📊 Analysis & Reference

Analysis documents and session data for reference.

- **[analysis/PREMIUM_FLAG_ANALYSIS.md](./analysis/PREMIUM_FLAG_ANALYSIS.md)** - Premium feature flag analysis
- **[analysis/HANNAH_BOSBORNE_SESSION_ANALYSIS.md](./analysis/HANNAH_BOSBORNE_SESSION_ANALYSIS.md)** - User session case study
- **[analysis/SCENEXTRAS_BOT_ANALYSIS.md](./analysis/SCENEXTRAS_BOT_ANALYSIS.md)** - SceneXtras bot analysis

---

## 📚 Historical Documentation

### Implementation History
Detailed iteration histories of major implementations, archived for reference:

- **[archive/implementations/posthog/](./archive/implementations/posthog/)** - PostHog implementation iterations (22 files)
- **[archive/implementations/sentry/](./archive/implementations/sentry/)** - Sentry implementation iterations (8 files)
- **[archive/implementations/payments/](./archive/implementations/payments/)** - RevenueCat implementation iterations (4 files)

### Bug Fixes & Issues
Historical bug fixes and issue resolutions:

- **[archive/fixes/admin/](./archive/fixes/admin/)** - Admin panel and endpoint fixes
- **[archive/fixes/api/](./archive/fixes/api/)** - API and configuration fixes
- **[archive/fixes/chat/](./archive/fixes/chat/)** - Chat system fixes
- **[archive/fixes/images/](./archive/fixes/images/)** - Image caching and display fixes
- **[archive/fixes/payments/](./archive/fixes/payments/)** - Payment and subscription fixes
- **[archive/fixes/series/](./archive/fixes/series/)** - Series parameter and data fixes
- **[archive/fixes/sourcemaps/](./archive/fixes/sourcemaps/)** - Sourcemap and debugging fixes

---

## 🗂️ Directory Structure

```
/docs/
├── README.md (this file)
├── CLAUDE.md (development guide)
├── MICROSERVICES_ARCHITECTURE.md
├── COMPLETE_IMPLEMENTATION_SUMMARY.md
│
├── integrations/
│   ├── POSTHOG_INTEGRATION.md
│   ├── SENTRY_INTEGRATION.md
│   └── REVENUECAT_INTEGRATION.md
│
├── features/
│   ├── CHAT.md
│   ├── ROLEPLAY.md
│   ├── FEATURE_PARITY_COMPARISON.md
│   └── mcp/
│       ├── MCP_CODE_EXECUTION_IMPLEMENTATION.md
│       └── MCP_LLM_PROMPT.md
│
├── guides/
│   ├── DEPLOYMENT.md
│   ├── SESSION_TOKEN_LOGGING.md
│   ├── DISCORD_MONITORING_SETUP.md
│   └── PRE_MOBILE_LAUNCH_CHECKLIST_PROMPTS.md
│
├── analysis/
│   ├── PREMIUM_FLAG_ANALYSIS.md
│   ├── HANNAH_BOSBORNE_SESSION_ANALYSIS.md
│   └── SCENEXTRAS_BOT_ANALYSIS.md
│
└── archive/
    ├── implementations/
    │   ├── posthog/ (22 iteration files)
    │   ├── sentry/ (8 iteration files)
    │   └── payments/ (4 iteration files)
    └── fixes/
        ├── admin/
        ├── api/
        ├── chat/
        ├── images/
        ├── payments/
        ├── series/
        └── sourcemaps/
```

---

## 🔍 Quick Links by Topic

### Getting Started
1. Read [CLAUDE.md](./CLAUDE.md) for development instructions
2. Check [MICROSERVICES_ARCHITECTURE.md](./MICROSERVICES_ARCHITECTURE.md) for system overview
3. Review [guides/DEPLOYMENT.md](./guides/DEPLOYMENT.md) for deployment procedures

### Integration Setup
1. **PostHog:** See [integrations/POSTHOG_INTEGRATION.md](./integrations/POSTHOG_INTEGRATION.md)
2. **Sentry:** See [integrations/SENTRY_INTEGRATION.md](./integrations/SENTRY_INTEGRATION.md)
3. **RevenueCat:** See [integrations/REVENUECAT_INTEGRATION.md](./integrations/REVENUECAT_INTEGRATION.md)

### Feature Implementation
1. **Chat:** See [features/CHAT.md](./features/CHAT.md)
2. **Roleplay:** See [features/ROLEPLAY.md](./features/ROLEPLAY.md)
3. **MCP:** See [features/mcp/](./features/mcp/)

### Troubleshooting
1. Check relevant integration guide for your issue
2. Review [archive/fixes/](./archive/fixes/) for similar past issues
3. Reference [archive/implementations/](./archive/implementations/) for implementation details

---

## 📝 Documentation Standards

- **Active Documentation:** Kept in main `/docs/` directories
- **Historical Reference:** Moved to `/archive/` for reference
- **Consolidation:** Multiple iterations consolidated into single authoritative guides
- **Organization:** Grouped by function (integrations, features, guides, analysis)

---

## 🔄 Documentation Maintenance

This documentation is maintained as part of the codebase. When updating:

1. Edit relevant files in `/docs/`
2. Update this README if adding new sections
3. Move historical iterations to `/archive/` when consolidating
4. Keep integration guides current with implementation changes

---

**Last Updated:** November 2025

For the most current development instructions, always refer to [CLAUDE.md](./CLAUDE.md).
