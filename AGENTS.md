# Workspace AGENTS Guide

## Scope
This workspace aggregates multiple git repositories for SceneXtras services and tools. Follow the closest repo-level AGENTS.md when making changes in a sub-repo.

## Core Services
- sceneXtras/api: Python FastAPI backend
- frontend_webapp: React web frontend
- golang_search_engine: Go autocomplete/search service
- golang_auth_gateway: Go auth gateway
- mobile_app_sx: React Native mobile app

## Common Commands (root Makefile)
- `make help` for the full command index
- `make dev-api`, `make dev-api-local`, `make dev-web`, `make dev-search`, `make dev-gateway`, `make dev-mobile`
- `make test-api`, `make test-web`, `make test-search`, `make test-gateway`, `make test-mobile`, `make test-all`
- `make lint-api`, `make lint-search`, `make lint-gateway`, `make quality-api`
- `make build-api`, `make build-web`, `make build-search`, `make build-gateway`
- `make deploy-api`, `make deploy-search`, `make deploy-gateway`

## Repo Index
- `automations/`: automation workflows and E2E helpers
- `bug-report/`: Go bug report API
- `eu_leapfrog_repo/`: Next.js app
- `golang_transcription_service/`: Go transcription service
- `health-monitor/`: Go health check notifier
- `MCPs/`: MCP tooling mirror
- `mobile_app_sx-expo-ota/`: Expo OTA mobile app
- `posthog_ops/`: PostHog analysis scripts
- `sceneXtras/`: Python backend root
- `website-backoffice/`: Vite React admin UI

## Notes
- Secrets live in `.env` files; never commit them.
- Prefer repo-local scripts and Makefiles for build/test. See each repo README for details.

## Notes from CLAUDE.md (extract)
- Code-only output for coding tasks unless the user explicitly asks for explanations.
- Use `dokku logs` for realtime streaming; use persistent log files for historical analysis.
- New containers must implement health checks; failed deployments should not replace healthy containers.
- Feature flags are mandatory and maintain 80%+ test coverage across services.
- Mobile prefer `./run.sh --web`; Python must run `make lint` before finishing; Go requires `TMDB_API_KEY`.
- Env notes: PostHog has fallback env var names; all `EXPO_PUBLIC_*` variables are client-exposed.
