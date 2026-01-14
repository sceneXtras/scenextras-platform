# Backend Sentry Testing Results & Verification Checklist

## ✅ Backend Test Results

### Working Endpoints Verified:
- ✅ `/ping` - Returns 200 OK
- ✅ `/version` - Returns version 1.7.1
- ✅ `/healthcheck/db` - Database connection alive
- ✅ `/api/popular/movies` - Returns movie data
- ✅ `/api/tailored-characters` - Returns character data

### Backend Status:
- ✅ Backend is deployed and responding
- ✅ API endpoints are functional
- ✅ Database connections working

## 🔍 What to Check in Sentry Dashboard

### 1. Check Sentry Dashboard - Issues Tab

**Go to:** Sentry → Issues → Filter by environment: `test` or `development`

**Look for:**
- ✅ Errors from `test.backend.scenextras.com`
- ✅ Errors should have enhanced context:
  - Source code snippets
  - Local variables (sanitized)
  - Request context (path, method, user_id, duration_ms)
  - Error group tags (`error_group: http_error`, `database_error`, etc.)
  - Custom fingerprints for better grouping

**Test:** Trigger an error by hitting an invalid endpoint:
```bash
curl https://test.backend.scenextras.com/api/invalid-endpoint
```

### 2. Check Sentry Dashboard - Performance Tab

**Go to:** Sentry → Performance

**Look for:**
- ✅ Transactions for each API request:
  - `GET /ping`
  - `GET /version`
  - `GET /api/popular/movies`
  - `GET /api/tailored-characters`
- ✅ Each transaction should show:
  - Duration (ms)
  - Status code
  - Request path
  - Service tag: `service: python-api`

**Filter by:**
- Transaction: `http.server`
- Environment: `test` or `development`

### 3. Check Sentry Dashboard - Releases

**Go to:** Sentry → Releases

**Look for:**
- ✅ Release matching your deployment (e.g., `sceneXtras@{commit-sha}`)
- ✅ Release should have:
  - Backend errors associated with it
  - Performance transactions
  - Source code context visible

### 4. Verify Error Context Enhancement

**In any error, check for:**

**Enhanced Context:**
- ✅ `error_location` section with:
  - `filename`
  - `function`
  - `line`
- ✅ `local_variables` section (sanitized)
- ✅ `request` context with:
  - `path`
  - `method`
  - `client_ip`
  - `user_id`
  - `duration_ms`
- ✅ `query_params` context (sanitized)

**Tags:**
- ✅ `service: python-api`
- ✅ `error_group: {error_type}` (http_error, database_error, etc.)

**Fingerprints:**
- ✅ Custom fingerprints for better grouping (e.g., `["database-error", "connection"]`)

### 5. Check Slow Request Detection

**If requests take >1 second:**
- ✅ Should have tag: `slow_request: true`
- ✅ Should have tag: `request_duration_ms: {duration}`
- ✅ Should appear in Performance tab with slow indicators

### 6. Database Error Context

**If database errors occur:**
- ✅ Should have `database` context with:
  - `host`
  - `database`
  - `pool_stats`
  - `error_type`
- ✅ Should have tags:
  - `error_group: database_error`
  - `database_error_type: {type}`
- ✅ Should have custom fingerprint (e.g., `["database-error", "connection"]`)

## 🧪 How to Test Specific Features

### Test Error Context Enhancement:
1. **Trigger a test error** (if you have admin access):
   ```bash
   curl -u admin:password https://test.backend.scenextras.com/test-error-logging
   ```
2. **Check Sentry** → Issues → Latest error
3. **Verify** source code context and local variables are present

### Test Performance Transactions:
1. **Make several API requests**:
   ```bash
   curl https://test.backend.scenextras.com/api/popular/movies?limit=5
   curl https://test.backend.scenextras.com/api/tailored-characters
   ```
2. **Check Sentry** → Performance
3. **Verify** transactions appear with duration and status

### Test Error Grouping:
1. **Trigger different error types**:
   - Invalid endpoint (404) → Should group as `http_error`
   - Invalid request → Should group appropriately
2. **Check Sentry** → Issues
3. **Verify** errors are grouped by type

### Test Request Context:
1. **Make authenticated request** (if possible)
2. **Check Sentry** → Issues/Performance
3. **Verify** user_id appears in context

## 📊 Expected Behavior

### ✅ Working Correctly If:
- Errors appear in Sentry Issues tab
- Errors show source code context
- Performance transactions appear in Performance tab
- Errors are grouped by type (error_group tags)
- Request context is automatically added
- Database errors have enhanced context

### ❌ Issues to Watch For:
- No errors appearing → Check `SENTRY_DSN` environment variable
- No source code context → Check if sourcemaps are uploaded
- No performance data → Check `tracesSampleRate > 0`
- Errors not grouped → Check if error_group tags are set
- Missing request context → Check middleware is running

## 🎯 Quick Verification Commands

```bash
# Test backend health
curl https://test.backend.scenextras.com/ping

# Test version
curl https://test.backend.scenextras.com/version

# Test database connection
curl https://test.backend.scenextras.com/healthcheck/db

# Test API endpoint (should trigger Sentry tracking)
curl https://test.backend.scenextras.com/api/popular/movies?limit=5

# Test invalid endpoint (should trigger error tracking)
curl https://test.backend.scenextras.com/api/invalid-endpoint
```

## 📝 Summary

**Backend Status:** ✅ **WORKING**
- All endpoints responding correctly
- API is functional
- Database connections working

**Next Steps:**
1. ✅ Check Sentry Dashboard for errors and performance data
2. ✅ Verify error context enhancement is working
3. ✅ Check performance transactions are being tracked
4. ✅ Verify error grouping is working correctly

**If Sentry is configured correctly**, you should see:
- Errors with enhanced context in Sentry Issues
- Performance transactions in Sentry Performance
- Better error grouping with custom tags and fingerprints

