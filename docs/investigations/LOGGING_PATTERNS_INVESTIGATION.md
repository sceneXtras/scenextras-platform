# Logging Patterns Investigation

**Date:** 2026-01-28  
**Investigated by:** @copilot  
**Scope:** Entire SceneXtras monorepo logging infrastructure

---

## Executive Summary

This document provides a comprehensive analysis of logging patterns across all services in the SceneXtras platform. The investigation covers logging libraries, configuration patterns, and identifies gaps in observability coverage.

### Key Findings

1. **All services use structured logging** with JSON output for machine parsing
2. **Python API has the most mature logging** with persistent file storage and multiple specialized logs
3. **Go Search Engine lacks Sentry integration** - identified as a gap in error tracking
4. **All services integrate PostHog** for analytics and user behavior tracking
5. **Request/Trace ID propagation** is implemented across all services for distributed tracing

---

## Service-by-Service Analysis

### 1. Python API Backend (`sceneXtras/api/`)

#### Logging Libraries

| Library | Purpose | Status |
|---------|---------|--------|
| **`logging`** (Standard Library) | Core application logging | ✅ Active |
| **Sentry** | Error tracking & performance monitoring | ✅ Implemented |
| **PostHog** | Analytics & event tracking | ✅ Implemented |

#### Configuration

**Location:** `sceneXtras/api/helper/exception_logger.py`

```python
# Custom exception logger integrates:
# - Python standard logging
# - Sentry error capture
# - PostHog event tracking
```

**Persistent Log Files** (Mounted at `/var/lib/dokku/data/storage/scenextras-logs/`):
- `app.log` - Main application logs (JSON format)
- `error.log` - Error logs only
- `security.log` - Security events (auth failures, suspicious activity)
- `payment_service.log` - Payment transaction logs
- `notification_service.log` - Push notification events
- `cronjobs.log` - Scheduled task execution logs

#### Logging Patterns

```python
# Standard pattern
import logging
logger = logging.getLogger(__name__)

logger.info("User authenticated", extra={"user_id": user_id})
logger.warning("Rate limit approaching", extra={"endpoint": endpoint})
logger.error("Database connection failed", exc_info=True)

# Exception logger pattern
from helper.exception_logger import log_exception
try:
    risky_operation()
except Exception as e:
    log_exception(e, context={"user_id": user_id})
```

#### Key Features

- **Structured logging** with JSON output for log aggregation tools
- **Context enrichment** with user IDs, request IDs, and operation metadata
- **Persistent storage** outside Docker container for historical analysis
- **Log rotation** via system logrotate
- **Multiple severity levels** (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- **Exception stack traces** automatically captured

---

### 2. React Web Frontend (`frontend_webapp/`)

#### Logging Libraries

| Library | Purpose | Status |
|---------|---------|--------|
| **Console API** | Browser-based logging | ✅ Active |
| **Sentry** | Error tracking & session replay | ✅ Implemented |
| **PostHog** | Product analytics | ✅ Implemented |

#### Configuration

**Location:** `frontend_webapp/src/index.tsx`

```typescript
// Sentry initialization at application root
Sentry.init({
  dsn: process.env.REACT_APP_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  integrations: [
    new BrowserTracing(),
    new Replay()
  ]
});
```

#### Logging Patterns

**Custom Logger Utility:**
```typescript
// Common pattern across components
const logger = {
  info: (message: string, context?: object) => {
    console.log(`[INFO] ${message}`, context);
  },
  error: (message: string, error?: Error, context?: object) => {
    console.error(`[ERROR] ${message}`, error, context);
    Sentry.captureException(error, { extra: context });
  },
  warn: (message: string, context?: object) => {
    console.warn(`[WARN] ${message}`, context);
  }
};

// Usage examples
logger.info('Message liked', { messageId: message.id });
logger.error('API request failed', error, { endpoint: '/chat' });
```

#### Key Features

- **Browser DevTools integration** for development debugging
- **Source maps** for production error debugging
- **Request ID tracking** for correlating frontend/backend logs
- **User context** automatically attached to Sentry events
- **Performance monitoring** via Sentry's BrowserTracing
- **Session replay** for debugging user issues

---

### 3. Go Search Engine (`golang_search_engine/`)

#### Logging Libraries

| Library | Purpose | Status |
|---------|---------|--------|
| **Zap** (Uber's structured logger) | Application logging | ✅ Implemented |
| **OpenTelemetry** | Distributed tracing | ✅ Implemented |
| **PostHog** | Event tracking | ✅ Implemented |
| **Sentry** | Error tracking | ❌ **NOT IMPLEMENTED** |

#### Configuration

**Location:** `golang_search_engine/internal/middleware/logger.go`

```go
// Zap structured logger with request context
func RequestLogger(baseLogger *zap.SugaredLogger) fiber.Handler {
    return func(c *fiber.Ctx) error {
        requestID := c.Locals("request_id").(string)
        traceID := c.Locals("trace_id").(string)
        
        reqLogger := baseLogger.With(
            "request_id", requestID,
            "trace_id", traceID,
            "method", c.Method(),
            "path", c.Path(),
        )
        
        c.Locals("logger", reqLogger)
        return c.Next()
    }
}
```

#### Logging Patterns

```go
// Structured logging with Zap
logger.Info("Search query executed",
    zap.String("query", query),
    zap.Int("results", len(results)),
    zap.Duration("latency", duration),
)

logger.Error("Cache initialization failed",
    zap.Error(err),
    zap.String("cache_type", "badger"),
)
```

#### Key Features

- **High-performance structured logging** (Zap is optimized for low latency)
- **Request ID middleware** with UUID generation
- **Trace ID propagation** for distributed tracing
- **JSON output** for log aggregation
- **Context-aware logging** with request metadata
- **OpenTelemetry integration** for tracing

#### Identified Gap

**⚠️ Missing Sentry Integration**

The Go Search Engine lacks Sentry error tracking, which means:
- No automatic error capture and alerting
- Missing distributed tracing between Go and Python services
- Reduced visibility into production issues
- No performance monitoring for Go service

**Recommendation:** Add Sentry Go SDK ([`sentry-go`](https://github.com/getsentry/sentry-go)) for complete observability coverage.

---

### 4. React Native Mobile App (`mobile_app_sx/`)

#### Logging Libraries

| Library | Purpose | Status |
|---------|---------|--------|
| **Console API** | React Native logging | ✅ Active |
| **Sentry** | Error tracking | ✅ Implemented |
| **PostHog** | Product analytics | ✅ Implemented |
| **Mixpanel** | Platform-specific analytics | ✅ Implemented |

#### Configuration

**Location:** `mobile_app_sx/app/_layout.tsx`

```typescript
// Sentry initialization in root layout
Sentry.init({
  dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  enableInExpoDevelopment: false,
  debug: __DEV__,
});
```

**Development Logs:** `mobile_app_sx/logs/server.log`

#### Logging Patterns

```typescript
// Custom logger with level support
const logger = {
  info: (message: string, data?: any) => {
    console.log(`[${new Date().toISOString()}] INFO: ${message}`, data);
  },
  warn: (message: string, data?: any) => {
    console.warn(`[${new Date().toISOString()}] WARN: ${message}`, data);
  },
  error: (message: string, error?: Error, data?: any) => {
    console.error(`[${new Date().toISOString()}] ERROR: ${message}`, error, data);
    Sentry.captureException(error, {
      extra: { message, ...data },
      contexts: {
        user: { id: userStore.getState().user?.id }
      }
    });
  }
};

// Usage
logger.info('Chat message sent', { characterId, messageId });
logger.error('Image cache failed', error, { imageUrl });
```

#### Key Features

- **File-based development logs** for debugging
- **Native crash reporting** via Sentry
- **User context tracking** (user ID, device info)
- **Screen tracking** for navigation analytics
- **Platform-specific analytics** via Mixpanel
- **Offline error queuing** - errors sent when connection restored

---

## Common Patterns Across All Services

### 1. Structured Logging

All services use structured logging with key-value pairs for machine parsing:

```python
# Python
logger.info("User action", extra={"user_id": 123, "action": "login"})

# TypeScript
logger.info('User action', { userId: 123, action: 'login' });

# Go
logger.Info("User action", zap.Int("user_id", 123), zap.String("action", "login"))
```

### 2. Request/Trace ID Propagation

All services implement request ID tracking for distributed tracing:

- **Python API:** Generates `X-Request-ID` header
- **React Web:** Includes request ID in API calls
- **Go Search:** Propagates trace IDs via OpenTelemetry
- **Mobile App:** Tracks session IDs and event IDs

### 3. Error Tracking with Sentry

**Implemented in:** Python API ✅ | Web ✅ | Mobile ✅  
**Missing in:** Go Search ❌

### 4. Analytics with PostHog

All services send events to PostHog for product analytics:
- User behavior tracking
- Feature usage metrics
- Funnel analysis
- A/B test results

### 5. Environment-Aware Logging

All services adjust logging verbosity based on environment:
- **Development:** Verbose console logs, DEBUG level
- **Staging:** INFO level, all integrations enabled
- **Production:** WARNING+ level, persistent storage enabled

---

## Log Aggregation and Access

### Production Log Access

**Script:** `scripts/ops/logs.sh`

```bash
# Recent/Live logs
./scripts/ops/logs.sh dokku scenextras 200          # Last 200 lines
./scripts/ops/logs.sh dokku scenextras -f           # Follow live
./scripts/ops/logs.sh search scenextras "error" 100 # Search recent

# Historical logs (past containers, rotated files)
./scripts/ops/logs.sh history scenextras "1 day ago"
./scripts/ops/logs.sh history scenextras "2024-01-15" "2024-01-16" "error"
./scripts/ops/logs.sh history-nginx error "502" 200
```

### Persistent Storage (Python API)

Logs stored outside Docker container at:
```
/var/lib/dokku/data/storage/scenextras-logs/
├── app.log (JSON format)
├── error.log
├── security.log
├── payment_service.log
├── notification_service.log
└── cronjobs.log
```

**Access via SSH:**
```bash
ssh -i ~/.ssh/dokku_azure dokku@dokku-scenextras.eastus.cloudapp.azure.com \
  "grep '2026-01-20T17' /var/lib/dokku/data/storage/scenextras-logs/app.log | head -50"
```

---

## Recommendations

### 1. Add Sentry to Go Search Engine (High Priority)

**Impact:** Complete observability coverage across all services

**Implementation:**
```go
import "github.com/getsentry/sentry-go"

// Initialize in main.go
err := sentry.Init(sentry.ClientOptions{
    Dsn: os.Getenv("SENTRY_DSN"),
    Environment: os.Getenv("ENVIRONMENT"),
    BeforeSend: func(event *sentry.Event, hint *sentry.EventHint) *sentry.Event {
        // Add custom context
        return event
    },
})

// Middleware for automatic error capture
app.Use(func(c *fiber.Ctx) error {
    hub := sentry.CurrentHub().Clone()
    hub.Scope().SetRequest(c.Request())
    c.Locals("sentry", hub)
    
    defer func() {
        if r := recover(); r != nil {
            hub.Recover(r)
            hub.Flush(time.Second * 2)
        }
    }()
    
    return c.Next()
})
```

### 2. Standardize Log Levels (Medium Priority)

Create consistent log level usage across services:
- **DEBUG:** Detailed diagnostic info (dev only)
- **INFO:** Normal operational events
- **WARNING:** Unusual but recoverable conditions
- **ERROR:** Error conditions that need attention
- **CRITICAL:** System-threatening conditions

### 3. Implement Log Sampling (Low Priority)

For high-traffic endpoints, consider log sampling to reduce volume:
- Sample 10% of successful requests
- Always log errors and slow requests
- Include sampling rate in log metadata

### 4. Add Performance Monitoring (Medium Priority)

Expand Sentry's performance monitoring:
- **Python API:** Already has APM
- **Web Frontend:** Already has BrowserTracing
- **Go Search:** Add performance transactions
- **Mobile App:** Add screen load tracking

---

## Security Considerations

### Sensitive Data Handling

All services follow these patterns to avoid logging sensitive data:

```python
# ❌ DON'T LOG:
logger.info(f"User login: {email} {password}")

# ✅ DO LOG:
logger.info(f"User login", extra={"user_id": user.id, "ip": request.ip})
```

**Never log:**
- Passwords or password hashes
- API keys or tokens (except masked versions)
- Credit card numbers
- Personal identifiable information (PII) without consent
- Session tokens or JWTs

### Log Retention Policies

- **Development logs:** 7 days
- **Production logs (Dokku):** 30 days via logrotate
- **Persistent logs (Python API):** 90 days
- **Sentry events:** 90 days (configurable)
- **PostHog events:** 1 year

---

## Testing Logging Patterns

### Python API
```bash
cd sceneXtras/api
make test  # Includes logging tests
make lint  # Flake8 checks for print() statements
```

### React Web
```bash
cd frontend_webapp
yarn test:ci  # Tests custom logger utility
yarn lint:check  # ESLint checks for console.log in production
```

### Go Search Engine
```bash
cd golang_search_engine
make test  # Tests logger middleware
make test-coverage  # Includes logging coverage
```

### React Native Mobile
```bash
cd mobile_app_sx
bun run test  # Tests logger patterns
bun run typecheck  # Type-checks logging calls
```

---

## Conclusion

The SceneXtras platform has **mature logging infrastructure** with:
- ✅ Structured logging across all services
- ✅ Error tracking with Sentry (3/4 services)
- ✅ Analytics with PostHog (all services)
- ✅ Distributed tracing capabilities
- ✅ Persistent log storage for historical analysis

**Primary Gap:** Go Search Engine lacks Sentry integration, which should be prioritized to complete observability coverage.

**Overall Assessment:** The logging patterns are well-designed and follow industry best practices. The main recommendation is to add Sentry to the Go service for comprehensive error tracking across the entire platform.

---

## References

- **CLAUDE.md:** Production log viewer documentation
- **SESSION_TOKEN_LOGGING.md:** Guide for session token logging patterns
- **SECURITY_AUDIT_2026-01-27.md:** Identified Sentry gap in Go service
- **Python Exception Logger:** `sceneXtras/api/helper/exception_logger.py`
- **Go Logger Middleware:** `golang_search_engine/internal/middleware/logger.go`
- **Log Access Script:** `scripts/ops/logs.sh`

---

**Last Updated:** 2026-01-28  
**Next Review:** Q2 2026 (or when major logging changes are needed)
