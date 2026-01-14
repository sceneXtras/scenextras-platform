# PostHog Backend Error Tracking & User Journey Enhancement

## Overview

Enhanced the Python API backend to send comprehensive error tracking and performance metrics to PostHog, enabling better error analysis and user journey tracking.

## What Was Enhanced

### 1. ✅ **Automatic Error Tracking**

**Files Modified:**
- `sceneXtras/api/helper/exception_logger.py` - Added PostHog integration alongside Sentry
- `sceneXtras/api/main.py` - Enhanced exception handlers to include request context

**Features:**
- All exceptions automatically sent to PostHog with rich context
- Error categorization (connection_error, content_filter, quota_error, application_error)
- Includes traceback, endpoint, method, status code, and correlation ID
- Errors linked to user journeys via `request_id`

**Benefits:**
- See errors in user journey context
- Identify which endpoints/users are experiencing errors
- Track error frequency and patterns
- Correlate errors with user actions

### 2. ✅ **Automatic API Performance Tracking**

**Files Modified:**
- `sceneXtras/api/main.py` - Enhanced `unified_request_tracking` middleware

**Features:**
- Every API request automatically tracked in PostHog
- Performance metrics: response time, status code, endpoint, method
- Correlation ID (`request_id`) included for linking events
- Filters out health checks and static files

**Benefits:**
- Monitor API performance in real-time
- Identify slow endpoints affecting user experience
- Track performance degradation over time
- Link performance issues to user journeys

### 3. ✅ **Slow Request Tracking**

**Files Modified:**
- `sceneXtras/api/main.py` - Added slow request detection and tracking
- `sceneXtras/api/helper/posthog_telemetry.py` - Added `capture_slow_request` method

**Features:**
- Automatically tracks requests exceeding `SLOW_THRESHOLD` (default: 5 seconds)
- Captures duration, threshold, endpoint, and correlation ID
- Helps identify performance bottlenecks

**Benefits:**
- Proactively identify performance issues
- Monitor slow requests affecting user experience
- Track performance trends

### 4. ✅ **Correlation ID Support**

**Files Modified:**
- `sceneXtras/api/main.py` - Added `request_id` to all error contexts
- `sceneXtras/api/helper/posthog_telemetry.py` - Added `request_id` parameter to all tracking methods

**Features:**
- Every request gets a unique `request_id` (UUID)
- `request_id` included in all PostHog events
- Sent to frontend via `X-Request-ID` header
- Links frontend and backend events together

**Benefits:**
- **Link frontend and backend events** - See complete user journey from frontend click to backend API call
- **Debug errors faster** - Find all events related to a specific request
- **Trace user journeys** - Follow a user's path through frontend and backend

### 5. ✅ **Enhanced Error Context**

**Files Modified:**
- `sceneXtras/api/helper/posthog_telemetry.py` - Added `capture_error` method
- `sceneXtras/api/helper/exception_logger.py` - Enhanced to extract and send error context

**Features:**
- Error type categorization
- Endpoint, method, status code included
- Traceback (truncated to 5000 chars for PostHog limits)
- User ID and request ID for correlation

**Benefits:**
- Rich error context for debugging
- Better error categorization and filtering
- Understand error patterns

## New PostHog Events

### 1. `api_request`
**Triggered:** Every API request (except health checks, static files)
**Properties:**
- `endpoint` - API endpoint path
- `method` - HTTP method (GET, POST, etc.)
- `status_code` - HTTP status code
- `response_time_ms` - Request duration in milliseconds
- `request_id` - Correlation ID
- `success` - Boolean (200-299 = true)
- `user_id` - User ID (or "anonymous")
- `environment` - Environment name

### 2. `api_error`
**Triggered:** When an exception occurs
**Properties:**
- `error_type` - Error category (connection_error, content_filter, quota_error, application_error)
- `error_message` - Exception message
- `exception_type` - Python exception type
- `endpoint` - API endpoint path
- `method` - HTTP method
- `status_code` - HTTP status code
- `request_id` - Correlation ID
- `traceback` - Exception traceback (truncated)
- `error_context` - Human-readable context message
- `user_id` - User ID (or "anonymous")
- `environment` - Environment name

### 3. `slow_request`
**Triggered:** When request duration exceeds threshold
**Properties:**
- `endpoint` - API endpoint path
- `method` - HTTP method
- `duration_ms` - Request duration in milliseconds
- `threshold_ms` - Slow request threshold
- `request_id` - Correlation ID
- `user_id` - User ID (or "anonymous")
- `environment` - Environment name

## Frontend Integration

### Using Correlation IDs

The backend now sends `X-Request-ID` header with every response. The frontend can use this to link events:

```typescript
// In your API client
const response = await fetch('/api/endpoint', {
  headers: {
    'Authorization': `Bearer ${token}`,
  }
});

const requestId = response.headers.get('X-Request-ID');

// Track frontend event with same request_id
posthog.capture('frontend_action', {
  request_id: requestId,
  // ... other properties
});
```

### Querying Linked Events

In PostHog, you can now query events linked by `request_id`:

```sql
-- Find all events for a specific request
SELECT * FROM events 
WHERE properties->>'request_id' = 'your-request-id'
ORDER BY timestamp;
```

## Error Categories

Errors are automatically categorized for better filtering:

1. **connection_error** - HTTP connection issues (client disconnections)
2. **content_filter** - LLM content filter violations
3. **quota_error** - Provider balance/quota issues
4. **application_error** - General application errors

## Example Use Cases

### 1. User Journey Analysis
```
User clicks button → Frontend event (request_id: abc123)
  ↓
Backend API call → api_request event (request_id: abc123)
  ↓
If error occurs → api_error event (request_id: abc123)
```

All events linked by `request_id` show complete user journey.

### 2. Error Pattern Analysis
```
Filter: api_error events
Group by: error_type
Time range: Last 7 days
→ See which error types are most common
```

### 3. Performance Monitoring
```
Filter: slow_request events
Group by: endpoint
Time range: Last 24 hours
→ Identify slowest endpoints
```

### 4. User Experience Impact
```
User Journey:
1. User opens chat → frontend event
2. Backend API call → api_request (slow_request if slow)
3. If error → api_error
4. User sees error → frontend error event

All linked by request_id for complete picture
```

## Configuration

No additional configuration needed! The enhancements work automatically:

- **Error tracking** - Enabled by default (can disable per exception)
- **Performance tracking** - Enabled automatically for all API requests
- **Slow request tracking** - Uses existing `SLOW_THRESHOLD` setting
- **Internal user filtering** - Uses existing `POSTHOG_INTERNAL_DOMAINS` setting

## Testing

Run the test script to verify everything works:

```bash
cd sceneXtras/api
poetry run python test_posthog_backend_enhancements.py
```

## Benefits Summary

✅ **Better Error Analysis**
- See errors in user journey context
- Identify error patterns and trends
- Link errors to specific users/endpoints

✅ **Performance Monitoring**
- Track API performance automatically
- Identify slow endpoints
- Monitor performance degradation

✅ **User Journey Tracking**
- Link frontend and backend events
- See complete user flow
- Debug issues faster

✅ **No Code Changes Required**
- Automatic tracking for all requests
- No need to manually add tracking code
- Works with existing error handling

## Next Steps

1. **Monitor PostHog Dashboard** - Check that events are appearing
2. **Set Up Dashboards** - Create PostHog dashboards for:
   - Error rates by endpoint
   - Performance metrics
   - User journey flows
3. **Create Alerts** - Set up alerts for:
   - High error rates
   - Slow requests increasing
   - Critical errors

## Files Modified

- `sceneXtras/api/helper/posthog_telemetry.py` - Added `capture_error` and `capture_slow_request` methods
- `sceneXtras/api/helper/exception_logger.py` - Added PostHog integration
- `sceneXtras/api/main.py` - Enhanced middleware and exception handlers
- `sceneXtras/api/test_posthog_backend_enhancements.py` - Test suite (new file)

## Summary

Your backend now automatically tracks:
- ✅ All errors with rich context
- ✅ API performance metrics
- ✅ Slow requests
- ✅ Correlation IDs for linking events

This enables PostHog to provide comprehensive error analysis and user journey tracking without requiring manual code changes.

