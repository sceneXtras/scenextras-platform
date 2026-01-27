# Security Audit Report - SceneXtras Deployed Applications

**Date:** 2026-01-27
**Auditor:** Claude Code Security Analysis
**Scope:** All 9 deployed Dokku applications

---

## Executive Summary

This security audit analyzed all deployed SceneXtras services from smallest to largest. The overall security posture is **MODERATE** with several well-implemented controls but some notable gaps requiring attention.

**Key Findings:**
- 1 Critical issue (credentials in repo)
- 2 High-priority issues (missing rate limiting)
- 3 Medium-priority issues
- 2 Low-priority issues

---

## Deployed Services Overview

| Service | Dokku App Name | Technology | Risk Level |
|---------|----------------|------------|------------|
| Huginn | `huginn` | Ruby (Docker) | 🟡 MEDIUM |
| Bug Report | `bug-report` | Go | 🟢 LOW |
| Linear Daily Digest | `linear-daily-digest` | Automation | 🟢 LOW |
| Search Engine | `scenextras-autocomplete` | Go/Fiber | 🟢 LOW-MEDIUM |
| Auth Gateway | `scenextras-gateway` | Go | 🟢 LOW |
| Test API | `scenextras-test` | Python/FastAPI | 🟡 MEDIUM |
| Transcription | `scenextras-transcription` | Unknown | 🟡 MEDIUM |
| Main API | `scenextras` | Python/FastAPI | 🟡 MEDIUM-HIGH |

---

## Detailed Findings

### 1. Huginn (Health Check Automation)

**Risk Level: 🟡 MEDIUM**

#### Critical Finding: Credentials Exposed in Repository

**Location:** `automations/huginn/README.md:59`

```markdown
2. Login: `admin` / `bpgYtSsZRPOplaUKsl7HYnQomj2qnD8T`
```

**Impact:** Anyone with repository access can authenticate to the Huginn instance at `https://huginn.scenextras.com`

**Recommendation:**
1. Immediately rotate the Huginn admin password
2. Remove credentials from the repository
3. Use environment variables or secret management (e.g., Dokku config vars)
4. Add `.env.example` with placeholder values instead

#### Other Concerns:
- Discord webhook URL potentially exposed in scenario config
- No audit logging visible for agent executions

---

### 2. Bug-Report Service (Go)

**Risk Level: 🟢 LOW**

#### Positive Controls:
- Token-based authentication middleware
- Uses `secrets.compare_digest` for timing-safe comparisons
- API key validation implemented
- Minimal attack surface

#### Recommendations:
- Ensure API keys are rotated periodically
- Add request logging for audit trails

---

### 3. Linear Daily Digest

**Risk Level: 🟢 LOW**

Simple automation service with minimal security surface.

---

### 4. scenextras-autocomplete (Go Search Engine)

**Risk Level: 🟢 LOW-MEDIUM**

#### Positive Security Features:

| Feature | Implementation |
|---------|----------------|
| Request Tracing | Request ID middleware with UUID generation |
| Structured Logging | Zap logger with request context |
| Observability | OpenTelemetry tracing enabled |
| Analytics | PostHog event tracking |

#### Code Reference - Request ID Middleware:
```go
// golang_search_engine/internal/middleware/logger.go
func RequestLogger(baseLogger *zap.SugaredLogger) fiber.Handler {
    return func(c *fiber.Ctx) error {
        requestID := GetRequestID(c)
        traceID := GetTraceID(c)
        reqLogger := baseLogger.With("request_id", requestID, "trace_id", traceID)
        // ...
    }
}
```

#### Security Concerns:

1. **No Rate Limiting on Search Endpoints**
   - `/api/search` and `/autocomplete` have no throttling
   - Potential for abuse/DoS

2. **Admin Endpoints Lack Visible Authentication**
   - `DELETE /api/entities/:id` - deletes entities
   - `POST /api/db/clear` - clears entire database
   - Located in `golang_search_engine/internal/handlers/handlers.go:745`

**Recommendations:**
- Add rate limiting (e.g., 100 requests/minute per IP)
- Protect admin endpoints with authentication
- Consider API key requirement for write operations

---

### 5. scenextras-gateway (Go Auth Gateway)

**Risk Level: 🟢 LOW** (Well-designed)

#### Security Architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    Auth Gateway Flow                         │
├─────────────────────────────────────────────────────────────┤
│  1. Extract JWT from Authorization header                    │
│  2. Validate signature (ES256 via JWKS or HS256)            │
│  3. Check token expiration and claims                        │
│  4. Query Postgres for quota (chat routes only)             │
│  5. Inject trusted headers:                                  │
│     - X-User-Id                                              │
│     - X-User-Role                                            │
│     - X-Quota-Remaining                                      │
│     - X-Request-Id                                           │
│  6. Proxy to downstream service                              │
└─────────────────────────────────────────────────────────────┘
```

#### Positive Security Controls:

1. **Proper JWT Validation**
   ```go
   // golang_auth_gateway/middleware/supabase_auth.go:155-216
   switch alg {
   case "ES256":
       // Validates kid header, fetches from JWKS
       kid, ok := token.Header["kid"].(string)
       jwks, err := getJWKS(cfg.SupabaseURL)
       // ...
   case "HS256":
       return []byte(cfg.JWTSecret), nil
   default:
       return nil, fmt.Errorf("unsupported algorithm: %s", alg)
   }
   ```

2. **JWKS Caching with Proper Locking**
   - Double-check locking pattern prevents race conditions
   - 1-hour TTL with automatic refresh on key miss

3. **Algorithm Confusion Prevention**
   - Explicit algorithm validation prevents attacks where attacker switches to `none` or weaker algorithm

#### Recommendations:
- Consider adding rate limiting at gateway level
- Add circuit breaker for downstream service failures
- Log failed authentication attempts for security monitoring

---

### 6. scenextras-test (Test Environment)

**Risk Level: 🟡 MEDIUM**

Same codebase as production API. Ensure:
- Test environment doesn't contain production secrets
- Test database is isolated from production
- Access is restricted to development team

---

### 7. scenextras-transcription (Voice Service)

**Risk Level: 🟡 MEDIUM**

- Deployed and monitored by Huginn health checks
- Source code not found in main repository
- Health endpoint: `https://voice.backend.scenextras.com/health`

**Recommendation:** Audit this service separately once source is located.

---

### 8. scenextras (Main Python API)

**Risk Level: 🟡 MEDIUM-HIGH** (Due to complexity and sensitive operations)

#### Positive Security Controls

##### Authentication System

| Component | Implementation | Location |
|-----------|----------------|----------|
| Primary Auth | Supabase JWT validation | `auth/authentation_logic.py:590` |
| Fallback Auth | Admin-generated JWT with `admin_generated` claim | `auth/authentation_logic.py:651` |
| Password Hashing | Passlib with bcrypt | `auth/authentation_logic.py:47` |
| 2FA Support | TOTP/OTP via pyotp | `auth/authentation_logic.py:517` |

```python
# auth/authentation_logic.py:47
pwd_context = CryptContext(schemes=[PASSWORD_ALGO], deprecated="auto")
```

##### Webhook Security

**Stripe Webhooks:**
```python
# router/payment_router.py:3044-3045
event = stripe.Webhook.construct_event(payload, sig_header, endpoint_secret)
```

**Customer.io Webhooks:**
```python
# router/notification_router.py:271-275
expected_signature = hmac.new(
    CUSTOMERIO_WEBHOOK_SIGNING_KEY.encode(),
    signing_string.encode(),
    hashlib.sha256,
).hexdigest()

if not hmac.compare_digest(expected_signature, x_cio_signature):
    raise HTTPException(status_code=401, detail="Invalid webhook signature")
```

##### CORS Configuration

```python
# main.py:940-956
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=(
        r"https?://(localhost|127\.0\.0\.1|192\.168\.\d+\.\d+|...)$"
        r"|https://frontend-webapp-git-.*\.vercel\.app$"
        r"|https://.*\.expo\.dev$"
    ),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

##### Database Security

- SQLAlchemy ORM with parameterized queries
- Race condition protection via PostgreSQL `ON CONFLICT`
- Connection pooling with limits

#### Security Concerns

##### 1. No Global Rate Limiting (HIGH PRIORITY)

**Evidence:**
```python
# router/realtime_router.py:41
**Authentication:** None (should add rate limiting)
```

Rate limiting only exists for:
- Internal TMDB/external API calls
- Email sending batches

**Missing rate limiting on:**
- Authentication endpoints (`/token`, `/login`)
- Chat endpoints
- Search endpoints

**Risk:** Brute force attacks, credential stuffing, API abuse

##### 2. Overly Permissive CORS Headers

```python
allow_methods=["*"],
allow_headers=["*"],
```

**Recommendation:** Restrict to required methods and headers:
```python
allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
```

##### 3. Hardcoded Test Credentials

**Locations:**
- `test_referral_code_user_auth.py:14`: `test_password = "testpassword123"`
- `auth/authentation_logic.py:384`: `password="universal_password"`

**Recommendation:** Use environment variables for test credentials.

##### 4. Sensitive Data in Logs

Email addresses are partially logged (which is good), but token previews appear in debug logs:
```python
# auth/authentation_logic.py:587-588
token_preview = f"{token[:20]}...{token[-10:]}" if token and len(token) > 30 else token
logger.info(f"[AUTH DEBUG] Starting Supabase auth validation, token_preview={token_preview}")
```

**Recommendation:** Remove token logging in production or ensure DEBUG level is disabled.

---

## Priority Matrix

| Priority | Issue | Service | Effort | Impact |
|----------|-------|---------|--------|--------|
| 🔴 **P1** | Hardcoded Huginn credentials in repo | Huginn | Low | Critical |
| 🟠 **P2** | No rate limiting on auth endpoints | Python API | Medium | High |
| 🟠 **P2** | Missing auth on admin endpoints | Search Engine | Low | High |
| 🟡 **P3** | Overly permissive CORS headers | Python API | Low | Medium |
| 🟡 **P3** | No rate limiting on search | Search Engine | Medium | Medium |
| 🟡 **P3** | Test env security isolation | Test API | Medium | Medium |
| 🟢 **P4** | Test credentials in codebase | Python API | Low | Low |
| 🟢 **P4** | Token logging in debug mode | Python API | Low | Low |

---

## Remediation Recommendations

### Immediate Actions (This Week)

1. **Rotate Huginn credentials** and remove from repository
2. **Add rate limiting** to authentication endpoints:
   ```python
   # Recommended: slowapi or fastapi-limiter
   from slowapi import Limiter
   limiter = Limiter(key_func=get_remote_address)

   @app.post("/token")
   @limiter.limit("5/minute")
   async def login():
       ...
   ```

3. **Protect admin endpoints** in search engine with API key or JWT

### Short-Term (Next Sprint)

4. Restrict CORS to specific methods/headers
5. Implement rate limiting on search endpoints
6. Add authentication to transcription service (verify)
7. Audit test environment for production secret leakage

### Long-Term (Backlog)

8. Implement centralized rate limiting at gateway level
9. Add security headers middleware (CSP, HSTS, X-Frame-Options)
10. Set up automated security scanning in CI/CD
11. Conduct penetration testing

---

## What's Working Well

| Area | Implementation | Notes |
|------|----------------|-------|
| JWT Validation | ES256/JWKS + HS256 fallback | Proper algorithm validation |
| Webhook Security | Signature verification | Timing-safe comparisons |
| Password Storage | bcrypt via Passlib | Industry standard |
| SQL Injection | SQLAlchemy ORM | Parameterized by default |
| Error Handling | Sentry with filtering | Prevents sensitive data leakage |
| Observability | OpenTelemetry + PostHog | Good audit trail |
| Gateway Architecture | High-trust model | Clean separation of concerns |

---

## Appendix: Files Reviewed

### Go Services
- `golang_search_engine/internal/handlers/handlers.go`
- `golang_search_engine/internal/middleware/logger.go`
- `golang_search_engine/cmd/server/main.go`
- `golang_auth_gateway/middleware/auth.go`
- `golang_auth_gateway/middleware/supabase_auth.go`
- `bug-report/middleware/auth.go`
- `bug-report/handlers/report.go`

### Python API
- `sceneXtras/api/main.py`
- `sceneXtras/api/auth/authentation_logic.py`
- `sceneXtras/api/auth/auth_req.py`
- `sceneXtras/api/router/payment_router.py`
- `sceneXtras/api/router/notification_router.py`
- `sceneXtras/api/db/database.py`

### Configuration
- `automations/huginn/README.md`
- `automations/huginn/health-check-scenario.json`

---

## Sign-Off

This audit represents a point-in-time assessment. Security is an ongoing process and regular audits are recommended.

**Next Audit Recommended:** 2026-04-27 (90 days)
