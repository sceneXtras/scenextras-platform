# PostHog Event Verification Checklist

## ✅ Confirmed Working

### 1. Slow Request Tracking ✅
- Event: `slow_request` ✅
- Distinct ID: `test_user_verification` ✅
- Library: `posthog-python` ✅
- Timestamp: Matches test execution ✅

## Next Steps: Verify Other Events

### 2. Check Event Properties

Click on the `slow_request` event in PostHog and verify these properties are present:

**Expected Properties:**
- ✅ `endpoint` - API endpoint path
- ✅ `method` - HTTP method (GET, POST, etc.)
- ✅ `duration_ms` - Request duration in milliseconds
- ✅ `threshold_ms` - Slow request threshold
- ✅ `request_id` - Correlation ID (important!)
- ✅ `environment` - Environment name
- ✅ `timestamp` - ISO timestamp

### 3. Verify Other Event Types

**Check for these events:**

#### A. API Request Events
```
Filter: event = "api_request"
```
- Should see events for every API call
- Properties should include: `endpoint`, `method`, `status_code`, `response_time_ms`, `request_id`

#### B. API Error Events
```
Filter: event = "api_error"
```
- Should see events when errors occur
- Properties should include: `error_type`, `error_message`, `endpoint`, `request_id`, `traceback`

### 4. Test Real API Calls

**Make some API calls to your test environment:**

```bash
# Health check (should create api_request event)
curl https://your-test-api.com/api/health

# Any other endpoint (should create api_request event)
curl https://your-test-api.com/api/characters

# Check PostHog dashboard immediately after
```

### 5. Verify Correlation IDs

**Check if `request_id` is present:**

1. Look at the `slow_request` event properties
2. Note the `request_id` value
3. Search for other events with the same `request_id`:
   ```
   properties.request_id = "<your-request-id>"
   ```
4. Should see multiple events linked together

### 6. Verify Real-Time Tracking

**Test with your actual API:**

1. Make some API calls to your test environment
2. Watch PostHog Live Events: **Activity → Live events**
3. You should see `api_request` events appearing in real-time

## What to Look For

### ✅ Success Indicators

1. **Events Appearing:**
   - ✅ `slow_request` - Confirmed working!
   - ⏳ `api_request` - Should appear for every API call
   - ⏳ `api_error` - Should appear when errors occur

2. **Event Properties:**
   - ⏳ `request_id` present in all events
   - ⏳ `endpoint`, `method`, `status_code` in `api_request`
   - ⏳ `error_type`, `error_message` in `api_error`
   - ✅ `duration_ms`, `threshold_ms` in `slow_request` (check properties)

3. **Correlation:**
   - Multiple events share same `request_id`
   - Can trace user journey from frontend to backend

### ⚠️ Things to Check

1. **Properties Missing?**
   - Click on the event → Expand "Properties" section
   - Check if all expected properties are there

2. **No `api_request` Events?**
   - Make sure your API is actually running
   - Check that endpoints are being called
   - Verify not all requests are being filtered (health checks are filtered)

3. **Internal User Filtering?**
   - If your test user email ends with `@scenextras.com`, events might be filtered
   - Check `POSTHOG_INTERNAL_DOMAINS` setting

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

### Performance Analysis
```
event = "api_request"
GROUP BY properties.endpoint
AGGREGATE avg(properties.response_time_ms)
```

## Summary

✅ **Working:**
- PostHog integration is active
- Events are being sent successfully
- `slow_request` tracking confirmed

⏳ **Next Steps:**
1. Check `slow_request` event properties (especially `request_id`)
2. Verify `api_request` events appear for real API calls
3. Test error tracking (`api_error` events)
4. Verify correlation IDs link events together

🎉 **Great progress!** Your PostHog backend enhancements are working!

