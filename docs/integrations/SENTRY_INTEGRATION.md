# Sentry Integration Guide

## Overview

Sentry is implemented across all services for error tracking, crash reporting, and performance monitoring. This guide provides configuration, implementation details, and troubleshooting.

---

## Configuration

### Environment Variables

**Python API** (`sceneXtras/api/.env`):
```
SENTRY_DSN=https://xxxxx@sentry.io/projectid
```

**React Web** (`frontend_webapp/.env`):
```
REACT_APP_SENTRY_DSN=https://xxxxx@sentry.io/projectid
GENERATE_SOURCEMAP=true  # Enable for proper error tracking
```

**React Native** (`mobile_app_sx/.env`):
```
EXPO_PUBLIC_SENTRY_DSN=https://xxxxx@sentry.io/projectid
```

**Go Search Engine** (currently optional):
```
SENTRY_DSN=https://xxxxx@sentry.io/projectid
```

---

## Service Coverage

### ✅ Python API Backend
- **Status:** Fully implemented
- **Errors Tracked:** All exceptions with context
- **Performance:** API request timing and slow endpoint detection
- **Sessions:** User session tracking
- **Location:** `sceneXtras/api/middleware/sentry_middleware.py`

### ✅ React Web Frontend
- **Status:** Fully implemented
- **Errors Tracked:** JavaScript errors, React component errors
- **Performance:** Page load performance, Core Web Vitals
- **Sessions:** User session tracking with authentication
- **Sourcemaps:** Enabled for production builds
- **Location:** `frontend_webapp/src/services/sentry.ts`

### ✅ React Native Mobile
- **Status:** Fully implemented
- **Errors Tracked:** App crashes, unhandled rejections
- **Performance:** App startup time, screen navigation
- **Sessions:** User session tracking with device info
- **Location:** `mobile_app_sx/services/sentry.ts`

### ⚠️ Go Search Engine
- **Status:** Optional/Not required
- **Note:** Can be implemented if needed for production monitoring

---

## Implementation Details

### Backend (Python API)

**Middleware Integration:**
```python
# Automatic error capture
# All unhandled exceptions are caught and sent to Sentry
# Request context is included for debugging
```

**Tracked Information:**
- Exception type and message
- Stack trace
- User ID (if authenticated)
- Request details (method, path, headers)
- Environment (dev/production)
- Performance metrics

### Frontend (React Web)

**Error Boundaries:**
- React error boundaries capture component failures
- User interactions are tracked
- Navigation events are logged

**Performance Monitoring:**
- Page load times
- Core Web Vitals (LCP, FID, CLS)
- API request performance
- JavaScript execution timing

**Sourcemaps:**
- Debug symbols uploaded to Sentry
- Maps minified code back to source
- Stack traces show original file/line numbers

### Mobile (React Native)

**Crash Detection:**
- Unhandled exceptions
- Native crashes (via Sentry SDK)
- Promise rejection handling

**Performance Tracking:**
- App startup time
- Screen navigation performance
- API request timing
- Memory usage patterns

---

## Session Tracking

### User Identification

**Backend:**
```python
# User context is automatically included
sentry_sdk.set_user({"id": user_id, "email": email})
```

**Frontend:**
```typescript
// User context set on login
Sentry.setUser({ id: userId, email: userEmail });
```

**Mobile:**
```typescript
// User context set in auth store
Sentry.setUser({ id: userId, email: userEmail });
```

### Session Properties

Each session includes:
- User ID and email
- Device/browser information
- Operating system
- Environment (development/production)
- App version
- Start and end times

---

## Sourcemap Setup

### Generating Sourcemaps

**Frontend (React):**
```bash
GENERATE_SOURCEMAP=true yarn build
# Creates .map files for each .js file
```

**Mobile (Expo):**
```bash
bun run build:ios
# Sourcemaps generated automatically
```

### Uploading Sourcemaps

Sourcemaps are automatically managed by Sentry:
1. Build creates sourcemap files
2. Release is tagged with git commit
3. Sentry receives upload with release information
4. Stack traces are automatically unminified

---

## Error Verification

### Testing Error Capture

**Backend:**
```bash
# Test endpoint
curl http://localhost:8080/debug/trigger-sentry-error

# Check Sentry dashboard for error
```

**Frontend:**
```typescript
// In console
Sentry.captureException(new Error('Test error'));

// Check Sentry dashboard
```

**Mobile:**
```typescript
// Trigger error in development
throw new Error('Test Sentry error');

// App will crash and report on restart
```

---

## Performance Monitoring

### Backend Metrics

- Request duration (P50, P95, P99)
- Error rates by endpoint
- Slow requests (>1000ms)
- Database query performance

### Frontend Metrics

- Page load time
- Time to first paint (FCP)
- Largest contentful paint (LCP)
- Cumulative layout shift (CLS)
- First input delay (FID)

### Mobile Metrics

- App startup time
- Screen navigation time
- API request duration
- Memory consumption

---

## Troubleshooting

### Events Not Appearing

1. **Verify DSN is correct** in environment variables
2. **Check Sentry project** is active and accepting events
3. **Review logs** for initialization errors
4. **Test manually** to confirm events are captured

### Missing Sourcemaps

1. **Verify `GENERATE_SOURCEMAP=true`** is set
2. **Check build output** contains .map files
3. **Upload to Sentry** (usually automatic)
4. **Clear browser cache** to fetch latest sourcemaps

### High Error Volume

1. **Review errors** in Sentry dashboard
2. **Group similar errors** to identify patterns
3. **Set alerts** for critical error rates
4. **Review recent deployments** for correlation

---

## Best Practices

1. **Include context** in errors for debugging
2. **Use breadcrumbs** to track user actions leading to error
3. **Set appropriate log levels** (error > warning > info)
4. **Monitor error rate trends** for regression detection
5. **Use sampling** in production to control costs
6. **Review grouped errors** regularly
7. **Test in development** before deploying

---

## References

- **Python Middleware:** `sceneXtras/api/middleware/sentry_middleware.py`
- **Backend Config:** Check `sceneXtras/api/main.py` for Sentry init
- **Frontend Service:** `frontend_webapp/src/services/sentry.ts`
- **Mobile Service:** `mobile_app_sx/services/sentry.ts`

---

## Historical Implementation Iterations

This document consolidates 8 previous iteration documents. Detailed implementation history is available in `/docs/archive/implementations/sentry/` if needed for reference.
