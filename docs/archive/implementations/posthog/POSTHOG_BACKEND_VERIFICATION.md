# PostHog Backend Verification Guide

## Quick Verification Steps

### 1. Run the Verification Script

```bash
cd sceneXtras/api

# Basic verification (no API connection needed)
poetry run python verify_posthog_backend.py

# With API endpoint test (if API is running)
poetry run python verify_posthog_backend.py --api-url http://localhost:8080
```

### 2. Check PostHog Dashboard

**Go to PostHog:**
- URL: https://us.i.posthog.com (or your PostHog host)
- Navigate to: **Events** → **Live events**

**Look for these events:**
- `api_request` - Every API call
- `api_error` - When errors occur
- `slow_request` - Slow requests (>5s)

**Filter by:**
- `distinct_id` = `test_user_verification` (for test events)
- `request_id` = `test_request_verify_*` (for correlation IDs)

### 3. Test Real API Calls

**Test API Performance Tracking:**
```bash
# Make some API calls
curl http://localhost:8080/api/health
curl http://localhost:8080/api/characters

# Check PostHog dashboard for api_request events
```

**Test Error Tracking:**
```bash
# Trigger an error (if you have an endpoint that can error)
curl http://localhost:8080/api/test-endpoint-that-errors

# Check PostHog dashboard for api_error events
```

### 4. Verify Correlation IDs

**Check for `request_id` in events:**
1. Make an API call
2. Note the `X-Request-ID` header in response
3. Search PostHog for that `request_id`
4. Should find corresponding `api_request` event

### 5. Check Internal User Filtering

**Test with internal user:**
```bash
# Set internal domain
export POSTHOG_INTERNAL_DOMAINS="scenextras.com"

# Make API call with internal email
# Events should be filtered (not appear in PostHog)
```

**Test with external user:**
```bash
# Make API call with external email
# Events should appear in PostHog
```

## What to Look For

### ✅ Success Indicators

1. **Events Appearing:**
   - `api_request` events for every API call
   - `api_error` events when errors occur
   - `slow_request` events for slow requests

2. **Event Properties:**
   - `request_id` present in all events
   - `endpoint`, `method`, `status_code` in `api_request`
   - `error_type`, `error_message` in `api_error`
   - `duration_ms`, `threshold_ms` in `slow_request`

3. **Correlation:**
   - Multiple events share same `request_id`
   - Can trace user journey from frontend to backend

### ❌ Failure Indicators

1. **No Events:**
   - Check PostHog configuration
   - Verify `POSTHOG_PUBLIC_KEY` is set
   - Check PostHog client is not disabled

2. **Missing Properties:**
   - Check exception logger context
   - Verify middleware is running
   - Check request_id is being generated

3. **Internal Users Not Filtered:**
   - Check `POSTHOG_INTERNAL_DOMAINS` setting
   - Verify email extraction logic

## Common Issues

### Issue: No Events in PostHog

**Check:**
1. `POSTHOG_PUBLIC_KEY` is set
2. PostHog client is not disabled (`posthog.disabled != True`)
3. Network connectivity to PostHog host
4. Internal user filtering (may be filtering your test user)

**Solution:**
```bash
# Check PostHog configuration
python -c "from helper.posthog_helper import posthog; print(f'Disabled: {posthog.disabled}')"
```

### Issue: Events Missing request_id

**Check:**
1. Middleware is running (`unified_request_tracking`)
2. Request state has `request_id`
3. Exception logger context includes `request_id`

**Solution:**
- Check middleware order in `main.py`
- Verify exception handlers extract `request_id` from request state

### Issue: Slow Requests Not Tracked

**Check:**
1. Request duration exceeds `SLOW_THRESHOLD` (default: 5 seconds)
2. PostHog telemetry method is called
3. Check logs for PostHog errors

**Solution:**
```bash
# Check slow threshold
grep SLOW_THRESHOLD sceneXtras/api/main.py
```

## PostHog Dashboard Queries

### Find All API Requests
```
event = "api_request"
```

### Find Errors
```
event = "api_error"
```

### Find Slow Requests
```
event = "slow_request"
```

### Find Events by Request ID
```
properties.request_id = "your-request-id"
```

### Find Events by User
```
distinct_id = "user-id"
```

### Find Errors by Type
```
event = "api_error" AND properties.error_type = "application_error"
```

### Performance Analysis
```
event = "api_request"
GROUP BY properties.endpoint
AGGREGATE avg(properties.response_time_ms)
```

## Next Steps After Verification

1. **Set Up Dashboards:**
   - Error rates by endpoint
   - API performance metrics
   - User journey flows

2. **Create Alerts:**
   - High error rates
   - Slow requests increasing
   - Critical errors

3. **Monitor:**
   - Watch events in real-time
   - Check error patterns
   - Monitor performance trends

