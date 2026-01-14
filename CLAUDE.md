# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Output Mode: Code-Only for Coding Tasks

**CRITICAL INSTRUCTION:** When fulfilling coding tasks, output ONLY:
1. **Code changes** (via Edit/Write tools)
2. **Brief summary at the end** (2-5 lines max)

**DO NOT output:** Explanatory text before/during code changes, step-by-step narration, verbose approach descriptions.

**EXCEPTION:** Provide full text responses ONLY when the user explicitly requests explanations, answers, or text.

---

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

## Quick Start Commands

### Python API Backend (FastAPI)
```bash
cd sceneXtras/api
poetry install

# Development servers (both support hot reload):
./start_local.sh              # Local SQLite mode (no tunnels, recommended for UI testing)
./start_local.sh --fresh      # Local mode with fresh database
./start_dev.sh                # Full stack with SSH tunnels to production DB

# Tests: make test | test-unit | test-integration | test-api | test-smoke | test-parallel
# Coverage: make coverage | coverage-unit
# Quality: make lint | lint-fix | type-check | quality
```
**URLs:** http://localhost:8080 | /docs | /debug/ssh-tunnels

### React Web Frontend
```bash
cd frontend_webapp
yarn install && yarn start
# Tests: yarn test:ci | test:e2e | vitest
# Quality: yarn lint:check | lint:fix | type-check
```
**URL:** http://localhost:3000

### Go Search Engine
```bash
cd golang_search_engine
make quickstart  # Docker Compose recommended
# Manual: make build && make run && make init-data
# Tests: make test | test-unit | test-coverage | test-bench
```
**URL:** http://localhost:8080 | **Requires TMDB_API_KEY**

### React Native Mobile App
```bash
cd mobile_app_sx
bun install
./run.sh --web      # Web development (RECOMMENDED)
./run.sh --ios      # iOS simulator
./run.sh --android  # Android emulator
# Logs: tail -f logs/server.log
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

**Testing:** pytest with fixtures/markers, 80%+ coverage requirement

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
- Sentry error tracking, PostHog analytics, Vercel Analytics
- Audio processing (Howler, Wavesurfer.js)

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
2. **Wrap new functionality behind a feature flag**
3. Implement handler logic in service layer (`services/`)
4. Add database operations if needed (`db/` or `model/`)
5. Write unit tests in `tests/unit/`, integration tests in `tests/integration/`
6. **ALWAYS run FLAKE8 before finishing:** `make lint`
7. Run quality checks: `make quality`

### Adding a New React Component (Web)
1. Create component in `frontend_webapp/src/components/`
2. **Wrap new component/feature behind a feature flag**
3. Use TypeScript with proper interfaces
4. Follow MUI/Chakra UI patterns
5. Add React Testing Library tests, ensure accessibility
6. Run: `yarn lint:check && yarn type-check && yarn test:ci`

### Adding a New Feature (Mobile)
1. Create screen in `mobile_app_sx/app/` (Expo Router convention)
2. **Wrap new feature behind a feature flag**
3. Use appropriate Zustand store or create new store in `mobile_app_sx/store/`
4. Leverage CachedImage component for images
5. Add proper TypeScript types in `mobile_app_sx/types/`
6. Test on both iOS and Android
7. Run: `bun run typecheck && bun run test`

### Modifying Search Logic (Go)
1. Update handlers in `golang_search_engine/internal/handlers/`
2. **Wrap significant changes behind a feature flag**
3. Modify search service in `golang_search_engine/internal/services/`
4. Add tests in `golang_search_engine/test/`
5. Run: `make test && make test-coverage`

## Zero-Downtime Deployment (Dokku)

**Required for each service:**
1. `CHECKS` file with health endpoints
2. `app.json` with healthchecks
3. `/healthcheck/ready` endpoint (return 503 when unhealthy)
4. Dockerfile `HEALTHCHECK` instruction

**CHECKS file format:**
```
WAIT=10  TIMEOUT=60  ATTEMPTS=10
/ping pong
/healthcheck/db alive
/healthcheck/ready ready
```

**Deployment Flow:** Push → Build → Health checks → Pass = replace old container, Fail = keep old running

## Emergency Rollback

```bash
./scripts/rollback/rollback.sh api previous       # ~30s, zero-downtime
./scripts/rollback/rollback.sh search previous    # ~45s, brief downtime
./scripts/rollback/rollback.sh <service> --list   # show releases
```

| Severity | Action |
|----------|--------|
| P1: Service down | Rollback immediately |
| P2: Major feature broken | Rollback within 5 min |
| P3/P4 | Evaluate fix vs rollback |

See `docs/EMERGENCY_ROLLBACK.md` for complete procedures.

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
const { data, error } = useQuery({
  queryKey: ['resource', id],
  queryFn: () => fetchResource(id),
  retry: 3,
});
```

### API Authentication

**Python:**
```python
from auth.dependencies import get_current_user
@router.get("/protected")
async def protected_endpoint(user = Depends(get_current_user)):
    return {"user_id": user.id}
```

**React/Mobile:**
```typescript
const { user, isAuthenticated } = useAuth();  // Web
const user = useUserStore(state => state.user);  // Mobile
```

## Environment Configuration

### Python API (`sceneXtras/api/.env`)
- **AI:** `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GROQ_API_KEY`, `GOOGLE_GENAI_API_KEY`
- **Data:** `TMDB_API_KEY` (required), `TVDB_API_KEY`, `SERPAPI_KEY`
- **DB/Cache:** `SUPABASE_URL`, `SUPABASE_KEY`, `REDIS_URL`
- **Auth/Payments:** `FIREBASE_ADMIN_SDK`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- **Monitoring:** `SENTRY_DSN`, `POSTHOG_PUBLIC_KEY`, `POSTHOG_SECRET_KEY`, `POSTHOG_PROJECT_ID`
- **Email:** `SENDGRID_API_KEY`
- **Storage:** `AZURE_STORAGE_CONNECTION_STRING`

### Go Search (`golang_search_engine/.env`)
- `TMDB_API_KEY` - **REQUIRED** (no mock fallback)
- `TVDB_API_KEY`, `PORT`, `DATABASE_PATH`, `CACHE_SIZE_MB`, `LOG_LEVEL`

### React Web (`frontend_webapp/.env`)
- `REACT_APP_API_URL`, `REACT_APP_SUPABASE_URL`, `REACT_APP_SUPABASE_ANON_KEY`
- `REACT_APP_SENTRY_DSN`, `REACT_APP_POSTHOG_TOKEN`, `REACT_APP_STRIPE_PUBLISHABLE_KEY`

### Mobile (`mobile_app_sx/.env`)
- `EXPO_PUBLIC_API_URL`, `EXPO_PUBLIC_MIXPANEL_TOKEN`, `EXPO_PUBLIC_SENTRY_DSN`
- `EXPO_PUBLIC_POSTHOG_API_KEY`, `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY`

## Feature Flags (MANDATORY)

**All new features MUST use PostHog feature flags.**

```typescript
// React/Mobile
import { useFeatureFlagEnabled } from 'posthog-js/react';
const enabled = useFeatureFlagEnabled('feature_new_chat_ui');
if (!enabled) return <LegacyComponent />;
return <NewFeatureComponent />;
```

```python
# Python
from services.feature_flags import is_feature_enabled
if is_feature_enabled("feature_new_endpoint", user_id=user.id):
    return new_implementation()
return legacy_implementation()
```

**Naming:** `feature_*` (new), `experiment_*` (A/B), `kill_switch_*` (emergency)
**Cleanup:** Remove flags 2-4 weeks after 100% rollout.

## Code Quality Standards

| Language | Formatter | Linter | Coverage |
|----------|-----------|--------|----------|
| Python | Black (88) | **Flake8 (MUST run)** | 80%+ |
| TypeScript | Prettier | ESLint | 80%+ |
| Go | gofmt | golangci-lint | Benchmark |

## Troubleshooting

| Service | Issue | Solution |
|---------|-------|----------|
| Python | SSH tunnel fail | Check `~/.ssh/dokku_azure` perms (600) |
| Python | Slow tests | `make test-parallel` or `test-smoke` |
| Python | Import errors | `make type-check`, review module structure |
| Web | Bundle size | Lazy loading, `yarn analyze` |
| Web | E2E failing | `yarn test:e2e:debug` |
| Go | Cache not init | `make init-data` after service starts |
| Go | BadgerDB corrupt | Delete `./data`, restart, `make init-data` |
| Mobile | Images not loading | Use `CachedImage` with TMDB URLs |
| Mobile | Module errors | `./run.sh --web` to clear cache |
| Mobile | iOS build fail | `cd ios && pod install` |

## Documentation References

- **Python Makefile:** `sceneXtras/api/Makefile`
- **Go API Docs:** `golang_search_engine/API_DOCUMENTATION.md`
- **Mobile Logs:** `mobile_app_sx/logs/server.log` (PRIMARY DEBUG FILE)
- **Image Caching:** `mobile_app_sx/docs/IMAGE_CACHING_SYSTEM.md`
- **Chat Audit:** `mobile_app_sx/docs/CHAT_SYSTEM_AUDIT.md`
- **Rollback:** `docs/EMERGENCY_ROLLBACK.md`, `scripts/rollback/`

## Critical Reminders

- **Mobile:** ALWAYS use `./run.sh --web`, use `CachedImage` for images, screen-based nav (not modals)
- **Python:** ALWAYS run `make lint` before finishing any job
- **Go:** Requires TMDB_API_KEY (no mock fallback), sub-30ms response requirement
- **All:** Feature flags mandatory, 80%+ test coverage, wrap new features behind flags
