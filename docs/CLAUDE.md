# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Interview-Driven Spec Workflow

**Trigger:** When user references a `SPEC.md` file or asks to "interview" about a spec/feature.

**Process:**

1. **Read the spec file first** - Understand the feature/requirement thoroughly before asking questions.

2. **Interview using AskUserQuestion** - Conduct an in-depth interview covering:
   - **Technical Implementation:** Architecture choices, data models, API design, state management, error handling strategies, caching approaches, database schema decisions
   - **UI & UX:** User flows, interaction patterns, loading states, empty states, error states, accessibility considerations, mobile vs desktop differences, animation/transition needs
   - **Edge Cases:** What happens when X fails? What if user does Y? Concurrent access scenarios, network failures, partial data states
   - **Tradeoffs:** Performance vs simplicity, build vs buy, sync vs async, optimistic vs pessimistic updates
   - **Concerns:** Security implications, scalability bottlenecks, maintenance burden, testing complexity, backwards compatibility
   - **Integration:** How it affects existing features, migration paths, feature flag strategy, rollback considerations

3. **Ask non-obvious questions** - Avoid questions with obvious answers. Focus on:
   - Decisions that could go multiple ways
   - Implicit assumptions that need validation
   - Conflicts between requirements
   - Second-order effects on other features
   - Operational concerns (monitoring, debugging, support)

4. **Continue until complete** - Keep interviewing across multiple rounds until:
   - All ambiguities are resolved
   - Technical approach is clear
   - Edge cases are addressed
   - User explicitly says "done" or "that's enough"

5. **Write the final spec** - Compile all decisions into a comprehensive spec file:
   - Location: `docs/specs/<feature-name>-spec.md` or same location as original
   - Include: Requirements, technical design, UI/UX details, edge cases, acceptance criteria
   - Format: Structured markdown with clear sections

**Example question categories:**
```
- "The spec mentions caching - should invalidation be time-based, event-based, or manual?"
- "For the error state, should we show inline errors or a toast notification?"
- "If the API call fails mid-flow, should we auto-retry or let the user decide?"
- "This feature touches the auth flow - should existing sessions be preserved or invalidated?"
- "What's the acceptable latency for this operation? Sub-100ms or is 500ms okay?"
```

---

## Project Overview

SceneXtras is a multi-service application ecosystem for interactive movie/TV character conversations and content discovery. The project consists of four main services in a monorepo structure:

1. **Python API Backend** (`sceneXtras/api/`) - FastAPI service with AI chat, authentication, and content APIs
2. **React Web Frontend** (`frontend_webapp/`) - React 18+ TypeScript SPA with MUI/Chakra UI
3. **Go Search Engine** (`golang_search_engine/`) - High-performance autocomplete service with TMDB integration
4. **React Native Mobile App** (`mobile_app_sx/`) - Expo-based cross-platform mobile application

## Recent Documentation Enhancements (October 2025)

This CLAUDE.md file has been significantly expanded with:
- **Comprehensive test commands** for all services (20+ Python API test targets, 15+ React Web tests, Go benchmarks)
- **Detailed environment configuration** with categorized variables for each service
- **Enhanced troubleshooting guide** with specific solutions for common issues
- **Expanded Go Search Engine commands** including TVDB integration tests
- **Complete documentation references** with links to specialized docs
- **Testing standards** with coverage requirements and available test types

## Quick Start Commands

### Python API Backend (FastAPI)
```bash
cd sceneXtras/api

# Setup environment (first time)
poetry install

# Start development server
./start_dev.sh
# OR
make dev

# Run tests
make test                    # All tests
make test-unit              # Unit tests only
make test-integration       # Integration tests
make test-api               # API endpoint tests
make test-smoke             # Quick verification (maxfail=1)
make test-all               # All tests with verbose output
make test-watch             # Watch mode (requires pytest-watch)
make test-failed            # Re-run only failed tests
make test-parallel          # Run tests in parallel (pytest-xdist)

# Coverage
make coverage               # Generate coverage report (HTML, JSON, term)
make coverage-unit          # Unit test coverage only

# Advanced testing
make test-security          # Security-focused tests
make test-report            # Generate HTML test report
make benchmark              # Run performance benchmarks
make test-mutation          # Mutation testing (requires mutmut)
make test-stats             # Show test statistics

# Code quality
make lint                   # Run Flake8 (ALWAYS run before finishing jobs)
make lint-fix              # Fix easily correctable issues
make lint-serious          # Show only serious issues
make type-check            # Run mypy
make quality               # Run all checks (lint, type-check, smoke, coverage)

# Database
make test-db-setup         # Setup test database

# Cleanup
make test-clean            # Remove test artifacts
```

**API will be available at:**
- Server: http://localhost:8080
- Docs: http://localhost:8080/docs
- SSH Tunnel Debug: http://localhost:8080/debug/ssh-tunnels

**Note:** The Python API has a comprehensive Makefile with 20+ test and quality commands. See full list above or run `make help` for all available targets.

### React Web Frontend
```bash
cd frontend_webapp

# Install dependencies
yarn install

# Development server
yarn start

# Testing
yarn test:ci               # CI mode
yarn test                  # Interactive mode

# Code quality
yarn lint:check            # Check linting
yarn lint:fix              # Fix linting issues
yarn type-check            # TypeScript checks

# Build
yarn build                 # Production build
```

**Web app will be available at:** http://localhost:3000

### Go Search Engine
```bash
cd golang_search_engine

# Quick start (Docker Compose - recommended)
make quickstart            # Build, run, and initialize with sample data

# Manual development
make build                 # Build binary
make run                   # Run locally
make init-db              # Initialize database directory
make init-data            # Initialize with sample data (after service is running)

# Testing
make test                  # Run all tests
make test-unit            # Run unit tests only (no integration)
make test-coverage        # Generate coverage report (HTML)
make test-bench           # Run performance benchmarks
make test-tvdb            # Run TVDB-specific integration tests

# Docker commands
make docker-build         # Build Docker image
make docker-run           # Run Docker container
make docker-up            # Start with docker-compose
make docker-down          # Stop services
make logs                 # View logs
make restart              # Restart service

# Development tools
make deps                 # Download dependencies
make fmt                  # Format code
make lint                 # Lint code (requires golangci-lint)
make clean                # Clean build artifacts

# Quick commands
make help                 # Show all available targets
```

**API will be available at:** http://localhost:8080
**Required:** TMDB API key in `.env` file
**Endpoints:**
- Health: http://localhost:8080/health
- Search: http://localhost:8080/api/search?q=batman
- Init cache: http://localhost:8080/api/search/init

### React Native Mobile App
```bash
cd mobile_app_sx

# Install dependencies
bun install

# Development (ALWAYS use run.sh)
./run.sh --web             # Web development (RECOMMENDED)
./run.sh                   # Mobile with tunnel
./run.sh --ios             # iOS simulator
./run.sh --android         # Android emulator

# Build
bun run build:ios          # iOS production build
bun run build:android      # Android production build

# Testing
bun run test               # All tests
bun run test:unit          # Unit tests
bun run test:e2e           # E2E tests
```

## Architecture Overview

### Python API Backend Architecture

**Framework:** FastAPI with uvicorn, Poetry for dependency management

**Key Modules:**
- `auth/` - Authentication, JWT tokens, user management
- `chat/` - AI chat service with multiple LLM providers (Anthropic, OpenAI, Groq)
- `router/` - API route handlers
- `model/` - Database models (SQLAlchemy)
- `db/` - Database operations and Supabase integration
- `services/` - Business logic services
- `middleware/` - Request/response middleware
- `external_api/` - Third-party API integrations (TMDB, TVDB)

**Database:** PostgreSQL via Supabase with Alembic migrations

**Key Features:**
- Multi-provider AI chat (Claude, GPT, Groq)
- WebSocket support for real-time chat
- Redis caching layer
- Firebase Admin integration
- SendGrid email service
- Stripe payment integration
- Sentry error tracking
- PostHog analytics

**Testing Strategy:**
- Unit tests with pytest
- Integration tests for API endpoints
- Performance benchmarks
- Security tests
- 80%+ coverage requirement

### React Web Frontend Architecture

**Framework:** React 18+ with TypeScript, Create React App + Craco

**State Management:**
- TanStack Query (React Query) - Server state
- Zustand - Global application state
- React Context API - Component-level state
- React Router v6 - URL-based state

**UI Framework:**
- Material UI + Chakra UI hybrid approach
- Emotion for CSS-in-JS styling
- Framer Motion & GSAP for animations

**Key Features:**
- React Hook Form + Zod for form validation
- Supabase authentication with OAuth
- Sentry error tracking
- PostHog analytics
- Vercel Analytics
- Audio processing (Howler, Wavesurfer.js)

**Testing:**
- Jest + React Testing Library for unit tests
- Playwright for E2E tests
- 80%+ coverage target

**Performance Requirements:**
- Core Web Vitals compliance
- <3s load time on 3G
- <500KB initial bundle
- WCAG 2.1 AA accessibility

### Go Search Engine Architecture

**Framework:** Pure Go with minimal dependencies

**Core Components:**
- Trie-based autocomplete engine
- BadgerDB for persistent storage
- Multi-dimensional search (exact, prefix, substring, fuzzy)
- Levenshtein distance for typo tolerance
- Multi-tier caching architecture

**Performance Targets:**
- Sub-30ms response times
- 10x faster than SQLite
- In-memory + disk persistence

**Data Sources:**
- TMDB API integration (REQUIRED)
- Real-time production data sync
- No mock data fallback

**Key Endpoints:**
- `/api/search?q={query}` - Main search
- `/health` - Health check
- `/api/search/init` - Initialize cache

### React Native Mobile App Architecture

**Framework:** React Native with Expo, TypeScript

**Routing:** Expo Router (file-based)

**State Management:**
- Modular Zustand stores:
  - `userStore.ts` - User profile, credits, subscriptions
  - `characterStore.ts` - Character data, favorites
  - `messageStore.ts` - Chat messages, persistence
  - `scenarioStore.ts` - Scenario management
  - `uiStore.ts` - UI state, modals, themes
- Legacy store compatibility layer
- Custom hooks (useChat, useFavorites, useProfile)

**Styling:** NativeWind (Tailwind CSS for React Native)

**Key Features:**
- Local image caching system (MMKV + FileSystem)
- Mixpanel analytics (platform-specific)
- Sentry error tracking
- TMDB image integration
- Screen-based navigation (not modals)

**Performance:**
- 87% cache hit rate
- 70% data savings from image caching
- <50ms cached image loading

## Development Workflows

### Adding a New API Endpoint (Python)

1. Define route in appropriate router file (`router/`)
2. Implement handler logic in service layer (`services/`)
3. Add database operations if needed (`db/` or `model/`)
4. Write unit tests in `tests/unit/`
5. Write integration tests in `tests/integration/`
6. Update API documentation (FastAPI auto-generates)
7. **ALWAYS run FLAKE8 before finishing:** `make lint` (or `make lint-fix` to auto-fix issues)
8. Run quality checks: `make quality`

### Adding a New React Component (Web)

1. Create component in `frontend_webapp/components/` or `frontend_webapp/src/components/`
2. Use TypeScript with proper interfaces
3. Follow MUI/Chakra UI patterns
4. Add React Testing Library tests
5. Ensure accessibility (ARIA, semantic HTML)
6. Run: `yarn lint:check && yarn type-check && yarn test:ci`

### Adding a New Feature (Mobile)

1. Create screen in `mobile_app_sx/app/` (Expo Router convention)
2. Use appropriate Zustand store or create new store in `mobile_app_sx/store/`
3. Leverage CachedImage component for images
4. Add proper TypeScript types in `mobile_app_sx/types/`
5. Test on both iOS and Android
6. Run: `bun run typecheck && bun run test`

### Modifying Search Logic (Go)

1. Update handlers in `golang_search_engine/internal/handlers/`
2. Modify search service in `golang_search_engine/internal/services/`
3. Update cache logic if needed
4. Add tests in `golang_search_engine/test/`
5. Run: `make test && make test-coverage`

## Zero-Downtime Deployment (Dokku)

**IMPORTANT:** All newly deployed containers MUST implement health checks to ensure zero-downtime deployments. Failed deployments should NOT replace working containers.

### Required Files for Each Service

Every containerized service must include these files:

#### 1. CHECKS File (Repository Root)

Create a `CHECKS` file in the service root:

```
WAIT=10
TIMEOUT=60
ATTEMPTS=10

# Format: <path> <expected_content>
/ping pong
/healthcheck/db alive
/healthcheck/ready ready
```

**Parameters:**
- `WAIT=10` - Wait 10 seconds before first check
- `TIMEOUT=60` - Each check can take up to 60 seconds
- `ATTEMPTS=10` - Retry up to 10 times before failing deployment

#### 2. app.json Healthchecks

Add healthchecks to `app.json`:

```json
{
    "healthchecks": {
        "web": [
            {
                "type": "startup",
                "name": "app-ready",
                "description": "Verify application startup and dependencies",
                "path": "/healthcheck/ready",
                "attempts": 10,
                "wait": 5,
                "timeout": 60,
                "content": "ready"
            }
        ]
    }
}
```

**Note:** Dokku is deprecating CHECKS file in favor of app.json healthchecks. Having both provides redundancy during the transition.

#### 3. Comprehensive Readiness Endpoint

**Python (FastAPI):**
```python
@app.get("/healthcheck/ready")
async def healthcheck_ready():
    """
    Comprehensive readiness check for zero-downtime deployment.
    Returns 503 if any critical service is unavailable.
    """
    checks = {
        "database": {"status": "unknown", "message": ""},
        "redis": {"status": "unknown", "message": ""},
    }
    all_healthy = True

    # Check 1: Database connectivity
    try:
        connection_status = await db.is_alive()
        if connection_status:
            checks["database"]["status"] = "healthy"
            checks["database"]["message"] = "Database connection is alive"
        else:
            checks["database"]["status"] = "unhealthy"
            checks["database"]["message"] = "Database connection failed"
            all_healthy = False
    except Exception as e:
        checks["database"]["status"] = "unhealthy"
        checks["database"]["message"] = f"Database check failed: {str(e)}"
        all_healthy = False

    # Check 2: Redis connectivity
    try:
        redis_client.ping()
        checks["redis"]["status"] = "healthy"
        checks["redis"]["message"] = "Redis connection is alive"
    except Exception as e:
        checks["redis"]["status"] = "unhealthy"
        checks["redis"]["message"] = f"Redis check failed: {str(e)}"
        all_healthy = False

    # Return appropriate response
    if all_healthy:
        return {
            "status": "ready",
            "message": "All services are operational",
            "checks": checks
        }
    else:
        from fastapi.responses import JSONResponse
        return JSONResponse(
            status_code=503,
            content={
                "status": "not_ready",
                "message": "One or more services are not operational",
                "checks": checks
            }
        )
```

**Go:**
```go
func healthcheckReady(w http.ResponseWriter, r *http.Request) {
    checks := map[string]interface{}{
        "database": map[string]string{"status": "unknown"},
        "cache":    map[string]string{"status": "unknown"},
    }
    allHealthy := true

    // Check database
    if err := db.Ping(); err != nil {
        checks["database"] = map[string]string{
            "status":  "unhealthy",
            "message": err.Error(),
        }
        allHealthy = false
    } else {
        checks["database"] = map[string]string{
            "status":  "healthy",
            "message": "Database connection is alive",
        }
    }

    // Return response
    w.Header().Set("Content-Type", "application/json")
    if allHealthy {
        w.WriteHeader(http.StatusOK)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  "ready",
            "checks":  checks,
        })
    } else {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  "not_ready",
            "checks":  checks,
        })
    }
}
```

**Key Point:** Return HTTP 503 when unhealthy - this tells Dokku the container isn't ready.

#### 4. Dockerfile HEALTHCHECK

Add to Dockerfile:

```dockerfile
# Add healthcheck - uses comprehensive readiness check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl --fail http://localhost:${PORT:-5000}/healthcheck/ready || exit 1
```

**Parameters:**
- `--start-period=60s` - Grace period for app initialization
- `--interval=30s` - Check every 30 seconds
- `--timeout=10s` - Fail if check takes longer than 10 seconds
- `--retries=3` - Mark unhealthy after 3 consecutive failures

#### 5. Graceful Shutdown (Recommended)

Handle graceful shutdown for in-flight requests:

**Python (FastAPI):**
```python
graceful_shutdown_timeout = int(os.getenv("GRACEFUL_SHUTDOWN_TIMEOUT", "30"))

if active_requests:
    logger.info(f"Waiting for {len(active_requests)} active requests...")
    start_time = time.time()
    while active_requests and (time.time() - start_time) < graceful_shutdown_timeout:
        await asyncio.sleep(0.5)

    if active_requests:
        logger.warning(f"Timeout: {len(active_requests)} requests still in progress")
```

### Deployment Flow

1. **Push to Dokku** → Docker image builds
2. **Container starts** → Dokku waits for CHECKS to pass
3. **Health checks run** → `/ping`, `/healthcheck/db`, `/healthcheck/ready`
4. **If all pass** → New container replaces old one (60s graceful transition)
5. **If any fail** → Deployment rejected, old container keeps running

### Required Endpoints Summary

| Endpoint | Response | Purpose |
|----------|----------|---------|
| `/ping` | `pong` | Basic liveness check |
| `/healthcheck/db` | `alive` | Database connectivity |
| `/healthcheck/ready` | `ready` (200) or `not_ready` (503) | Full readiness check |

### Testing Health Checks

To verify health checks work correctly:

```python
# Temporarily make /healthcheck/ready return 503:
return JSONResponse(status_code=503, content={"status": "not_ready"})
```

Push and watch the deployment fail, then verify the old container is still serving traffic.

### File Structure

```
your-service/
├── CHECKS                 # Dokku health check definitions
├── app.json               # Dokku app config with healthchecks
├── Dockerfile             # With HEALTHCHECK instruction
└── api/
    └── main.py            # With /healthcheck/ready endpoint
```

## Testing Standards

### Python API
- Use pytest with fixtures and markers (unit, integration, api, smoke, security, performance)
- Mock external services (TMDB, OpenAI, Stripe, Supabase)
- Test error conditions and edge cases
- Aim for 80%+ coverage (enforced with `--cov-fail-under=80`)
- **Available test commands:**
  - `make test` - All tests with verbose output
  - `make test-unit` - Unit tests only (fast)
  - `make test-integration` - Integration tests
  - `make test-api` - API endpoint tests
  - `make test-smoke` - Quick smoke tests (fail-fast)
  - `make test-parallel` - Run tests in parallel (pytest-xdist)
  - `make test-watch` - Watch mode for TDD
  - `make test-failed` - Re-run only failed tests
  - `make coverage` - Full coverage report (HTML, JSON, term-missing)
  - `make test-security` - Security-focused tests
  - `make benchmark` - Performance benchmarks
  - `make test-mutation` - Mutation testing with mutmut
  - `make test-report` - HTML test report
  - `make test-stats` - Test statistics summary

### React Web
- Use React Testing Library for components
- Use Playwright for E2E flows
- Use Vitest for modern test runner (alongside Jest)
- Test user interactions and accessibility (WCAG 2.1 AA)
- Mock API calls with MSW
- **Available test commands:**
  - `yarn test:ci` - CI mode with coverage
  - `yarn test:unit` - Unit tests only
  - `yarn test:integration` - Integration tests
  - `yarn test:functional` - All functional tests
  - `yarn test:functional:webapp` - Web app functionality
  - `yarn test:functional:auth` - Authentication flows
  - `yarn test:functional:media` - Media handling
  - `yarn test:functional:story` - Story features
  - `yarn test:functional:payments` - Payment flows
  - `yarn test:functional:chat` - Chat functionality
  - `yarn test:e2e` - Playwright E2E tests
  - `yarn test:e2e:ui` - Playwright UI mode
  - `yarn test:e2e:debug` - Debug Playwright tests
  - `yarn vitest` - Vitest watch mode
  - `yarn vitest:run` - Vitest CI mode
  - `yarn test:coverage` - Coverage report

### Go Search Engine
- Table-driven tests for search logic
- Benchmark critical paths with memory profiling
- Test concurrent access patterns
- Integration tests with real TMDB data
- **Available test commands:**
  - `make test` - Run all tests
  - `make test-unit` - Unit tests only (no integration)
  - `make test-coverage` - Coverage report with HTML output
  - `make test-bench` - Performance benchmarks with memory stats
  - `make test-tvdb` - TVDB-specific integration tests
  - Performance target: Sub-30ms response times

### React Native Mobile
- Jest for unit tests with expo-jest preset
- Detox for E2E tests on iOS/Android
- Test both iOS and Android platforms
- Mock Expo modules appropriately
- **Available test commands:**
  - `bun run test` - All tests (20s timeout)
  - `bun run test:unit` - Unit tests only
  - `bun run test:api` - API integration tests
  - `bun run test:e2e` - Detox E2E tests
  - `bun run test:e2e:ios` - iOS E2E tests
  - `bun run test:e2e:android` - Android E2E tests
  - `bun run test:e2e:build` - Build Detox tests
  - Coverage target: 80%+

## Common Patterns

### Error Handling

**Python:**
```python
from fastapi import HTTPException

try:
    result = await service.operation()
except ServiceError as e:
    logger.error(f"Operation failed: {e}")
    raise HTTPException(status_code=400, detail=str(e))
```

**React:**
```typescript
import { useQuery } from '@tanstack/react-query';

const { data, error, isLoading } = useQuery({
  queryKey: ['resource', id],
  queryFn: () => fetchResource(id),
  retry: 3,
  onError: (err) => {
    logger.error('Failed to fetch', err);
    showNotification('Error loading data');
  }
});
```

**Go:**
```go
if err := service.Operation(); err != nil {
    logger.Error("Operation failed", zap.Error(err))
    return fmt.Errorf("operation failed: %w", err)
}
```

### API Authentication

**Python:**
```python
from fastapi import Depends
from auth.dependencies import get_current_user

@router.get("/protected")
async def protected_endpoint(user = Depends(get_current_user)):
    return {"user_id": user.id}
```

**React:**
```typescript
import { useAuth } from '@/hooks/useAuth';

const { user, isAuthenticated } = useAuth();
```

**Mobile:**
```typescript
import { useUserStore } from '@/store';

const user = useUserStore(state => state.user);
const isAuthenticated = useUserStore(state => state.isAuthenticated);
```

## Environment Configuration

All services require `.env` files for configuration. See `.env.example` files in each directory for templates.

### Python API (.env in sceneXtras/api/)
**AI Providers:**
- `OPENAI_API_KEY` - OpenAI API key for GPT models
- `ANTHROPIC_API_KEY` - Anthropic API key for Claude models
- `GROQ_API_KEY` - Groq API key for fast inference
- `GOOGLE_GENAI_API_KEY` - Google Generative AI key

**Data APIs:**
- `TMDB_API_KEY` - The Movie Database API key (REQUIRED)
- `TVDB_API_KEY` - TVDB API key for TV show data
- `SERPAPI_KEY` - SerpAPI key for web search

**Database & Cache:**
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_KEY` - Supabase anon/service key
- `REDIS_URL` - Redis connection string for caching

**Authentication & Payments:**
- `FIREBASE_ADMIN_SDK` - Firebase Admin SDK credentials (JSON)
- `STRIPE_SECRET_KEY` - Stripe API key for payments
- `STRIPE_WEBHOOK_SECRET` - Stripe webhook secret

**Monitoring & Analytics:**
- `SENTRY_DSN` - Sentry error tracking DSN
- `POSTHOG_PUBLIC_KEY` - PostHog public key for event tracking
- `POSTHOG_SECRET_KEY` - PostHog secret key for API access (session replay downloads)
- `POSTHOG_PROJECT_ID` - PostHog project ID for API calls
- `POSTHOG_HOST` - PostHog host URL (default: https://us.i.posthog.com)
- `POSTHOG_INTERNAL_DOMAINS` - Comma-separated list of internal email domains to filter (default: scenextras.com)
- `POSTHOG_INTERNAL_USER_IDS` - Comma-separated list of internal user IDs to filter

**Email & Communications:**
- `SENDGRID_API_KEY` - SendGrid email service key

**Storage:**
- `AZURE_STORAGE_CONNECTION_STRING` - Azure Blob Storage

**Server Configuration:**
- `PORT` - Server port (default: 8080)
- `ENV` - Environment (development/production/test)

### Go Search Engine (.env in golang_search_engine/)
- `TMDB_API_KEY` - **REQUIRED** for production data (no mock fallback)
- `TVDB_API_KEY` - TVDB API key for TV show search
- `PORT` - Server port (default: 8080)
- `DATABASE_PATH` - BadgerDB path (default: ./data)
- `CACHE_SIZE_MB` - Cache size limit (default: 100MB)
- `LOG_LEVEL` - Logging level (debug/info/warn/error)

### React Web (.env in frontend_webapp/)
- `REACT_APP_API_URL` - Backend API URL
- `REACT_APP_SUPABASE_URL` - Supabase project URL
- `REACT_APP_SUPABASE_ANON_KEY` - Supabase public/anon key
- `REACT_APP_SENTRY_DSN` - Sentry DSN for error tracking
- `REACT_APP_POSTHOG_TOKEN` - PostHog public key for event tracking (primary)
- `REACT_APP_POSTHOG_HOST` - PostHog host URL (default: https://us.i.posthog.com)
- `REACT_APP_POSTHOG_INTERNAL_DOMAINS` - Comma-separated list of internal email domains to filter (default: scenextras.com)
- `REACT_APP_POSTHOG_INTERNAL_USER_IDS` - Comma-separated list of internal user IDs to filter
- `REACT_APP_STRIPE_PUBLISHABLE_KEY` - Stripe public key
- `REACT_APP_REVENUECAT_WEB_KEY` - RevenueCat Web publishable key for subscription management
- `REACT_APP_VERSION` - App version for tracking (default: from package.json)
- `GENERATE_SOURCEMAP` - Generate sourcemaps (true/false)

**Note:** PostHog also supports fallback variable names `REACT_APP_PUBLIC_POSTHOG_KEY` and `REACT_APP_PUBLIC_POSTHOG_HOST` for backward compatibility, but `REACT_APP_POSTHOG_TOKEN` is preferred.

### React Native Mobile (.env in mobile_app_sx/)
- `EXPO_PUBLIC_API_URL` - Backend API URL
- `EXPO_PUBLIC_MIXPANEL_TOKEN` - Mixpanel project token for analytics
- `EXPO_PUBLIC_SENTRY_DSN` - Sentry DSN for error tracking
- `EXPO_PUBLIC_POSTHOG_API_KEY` - PostHog public key for event tracking
- `EXPO_PUBLIC_POSTHOG_HOST` - PostHog host URL (default: https://us.i.posthog.com)
- `EXPO_PUBLIC_SUPABASE_URL` - Supabase project URL
- `EXPO_PUBLIC_SUPABASE_ANON_KEY` - Supabase public key
- `EXPO_PUBLIC_ENV` - Environment (development/staging/production)

**Note:** All `EXPO_PUBLIC_*` variables are exposed to the client side.

## Important Notes

### Mobile App Development
- **ALWAYS use `./run.sh --web`** after making code changes
- Use `CachedImage` component for all TMDB images
- Navigation: Use screen-based routing, not modals
- Test on both iOS and Android platforms
- Enable image caching on mobile (auto-disabled on web)

### Python API Development
- Use Poetry for dependency management
- **ALWAYS run FLAKE8 before finishing any job:** `make lint` or `cd sceneXtras/api && make lint`
- Run `make quality` before committing (includes lint, type-check, smoke, coverage)
- SSH tunnels auto-establish on startup
- Check `.env.example` for required variables

### React Web Development
- Use yarn as package manager
- Maintain 80%+ test coverage
- Follow semantic commit messages (feat:, fix:, refactor:)
- Run validation suite before PR creation

### Go Search Engine
- Requires TMDB API key (no mock fallback)
- Use Docker Compose for easiest setup
- Monitor cache performance with `/health` endpoint
- Sub-30ms response time requirement

## Known Issues & Troubleshooting

### Python API
- **Issue:** SSH tunnel failures
  - **Solution:** Verify `~/.ssh/dokku_azure` exists and has correct permissions (chmod 600)
- **Issue:** Tests failing intermittently
  - **Solution:** Use `make test-parallel` for faster execution or `make test-failed` to re-run failures
- **Issue:** Low test coverage warnings
  - **Solution:** Check coverage report with `make coverage` (HTML report in `htmlcov/index.html`)
- **Issue:** Slow test execution
  - **Solution:** Use `make test-smoke` for quick verification or `make test-unit` for fast unit tests only
- **Issue:** Import errors or circular dependencies
  - **Solution:** Check with `make type-check` and review module structure

### React Web
- **Issue:** Bundle size warnings
  - **Solution:** Use lazy loading and code splitting, check with `yarn analyze`
- **Issue:** TypeScript errors in tests
  - **Solution:** Run `yarn type-check` to identify type issues
- **Issue:** E2E tests failing
  - **Solution:** Use `yarn test:e2e:debug` for debugging or `yarn test:e2e:ui` for interactive mode
- **Issue:** Slow test execution
  - **Solution:** Use `yarn test:unit` for faster unit-only tests

### Go Search Engine
- **Issue:** Cache not initializing
  - **Solution:** Run `make init-data` after service starts, check logs with `make logs`
- **Issue:** TMDB API rate limiting
  - **Solution:** Verify TMDB API key is valid and check rate limit headers
- **Issue:** Slow search performance
  - **Solution:** Run `make test-bench` to identify bottlenecks, ensure cache is warmed up
- **Issue:** BadgerDB corruption
  - **Solution:** Stop service, delete `./data` directory, restart and run `make init-data`

### React Native Mobile
- **Issue:** Images not loading
  - **Solution:** Use `CachedImage` component with proper TMDB URLs
- **Issue:** Module resolution errors
  - **Solution:** Clear Metro cache with `./run.sh --web`, or manually with `rm -rf node_modules/.cache`
- **Issue:** Android build failures
  - **Solution:** Set `JAVA_HOME` to Java 17, verify Android SDK path in `android/local.properties`
- **Issue:** iOS build failures
  - **Solution:** Run `cd ios && pod install`, ensure Xcode is properly installed
- **Issue:** Expo module errors
  - **Solution:** Run `bun update` to sync package versions, then `bun run postinstall`
- **Issue:** Cache hit rate low
  - **Solution:** Check image URLs are using TMDB format, verify cache is enabled on mobile (auto-disabled on web)

## Code Quality Standards

### Python
- Black formatter (line length: 88)
- **Flake8 linting (select: E9, F, B, C4) - MUST be run before finishing any job**
  - Run with: `make lint` (or `make lint-fix` to auto-fix issues)
  - Command: `cd sceneXtras/api && make lint`
- mypy type checking
- 80%+ test coverage

### TypeScript (Web & Mobile)
- ESLint with React rules
- Prettier formatting
- Strict TypeScript mode
- 80%+ test coverage

### Go
- gofmt formatting
- golangci-lint
- Table-driven tests
- Benchmarking for critical paths

## Documentation References

### Core Documentation
- **Python API Makefile:** `sceneXtras/api/Makefile` - Comprehensive test and development commands
- **Go Search Engine API:** `golang_search_engine/API_DOCUMENTATION.md` - Complete API reference
- **Go API Examples:** `golang_search_engine/API_EXAMPLES.md` - Usage examples and patterns

### Mobile App Documentation
- **Mobile App Session Changes:** `mobile_app_sx/docs/SESSION_CHANGES_2025_09_01.md` - Navigation and auth changes
- **Chat System Audit:** `mobile_app_sx/docs/CHAT_SYSTEM_AUDIT.md` - Chat system architecture audit
- **Chat Implementation Roadmap:** `mobile_app_sx/docs/CHAT_IMPLEMENTATION_ROADMAP.md` - Implementation progress
- **Image Caching System:** `mobile_app_sx/docs/IMAGE_CACHING_SYSTEM.md` - Local caching implementation
- **Image Caching Quick Reference:** `mobile_app_sx/docs/IMAGE_CACHING_QUICK_REFERENCE.md` - Quick usage guide

### Environment Files
- **Python API:** `sceneXtras/api/.env.example` - Environment variable template
- **Go Search:** `golang_search_engine/.env.example` - Configuration template
- **React Web:** `frontend_webapp/.env.example` - Frontend environment template
- **Mobile App:** `mobile_app_sx/.env` - Mobile environment configuration

### Deployment
- **Zero-Downtime Deployment:** See "Zero-Downtime Deployment (Dokku)" section in this file for required health check implementation
- **Required Files:** `CHECKS`, `app.json` with healthchecks, Dockerfile `HEALTHCHECK`, `/healthcheck/ready` endpoint
