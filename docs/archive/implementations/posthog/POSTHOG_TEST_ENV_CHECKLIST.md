# PostHog Backend Verification Checklist - Test Environment

## ✅ What to Check

### 1. **Frontend PostHog Integration** ✅

**Status:** ✅ PostHog is loading
- PostHog config loaded from: `https://us-assets.i.posthog.com/array/phc_QU5MN8O26rTR0MEmXiEwGqtj7EQLmdQ3QRqTtil64Sy/config.js`
- PostHog scripts loading correctly
- Session ID: `019a3b0b-3385-7c42-ab6f-4500940cfc6e`
- Session Recording: INACTIVE (manual start failed)

**Check in Browser Console:**
```javascript
// Check if PostHog is loaded
console.log(window.posthog);
console.log(window.posthog?.get_distinct_id());
```

**Check Network Tab:**
- Look for requests to `us.i.posthog.com` (event tracking)
- Should see `/decide/` endpoint called
- Should see `/batch/` endpoint for events

### 2. **Backend API Request Tracking** ⏳

**Check for `X-Request-ID` Header:**
1. Open Browser DevTools → Network tab
2. Filter: `test.backend.scenextras.com`
3. Click on any API request
4. Check Response Headers for:
   - ✅ `X-Request-ID` - Should be present (UUID format)
   - ✅ `X-Process-Time` - Should show response time
   - ✅ `X-Process-ID` - Should show process ID

**Test API Calls:**
```bash
# Test backend API call
curl -I https://test.backend.scenextras.com/api/popular/movies?limit=1

# Look for headers:
# X-Request-ID: <some-uuid>
# X-Process-Time: <time>
```

### 3. **PostHog Dashboard Verification** ⏳

**Check for Backend Events:**

1. **API Request Events:**
   ```
   Filter: event = "api_request"
   Properties should include:
   - endpoint: "/api/popular/movies"
   - method: "GET"
   - status_code: 200
   - response_time_ms: <number>
   - request_id: <uuid>
   ```

2. **Error Events (if any errors occur):**
   ```
   Filter: event = "api_error"
   Properties should include:
   - error_type: "application_error" | "connection_error" | etc.
   - error_message: <error message>
   - endpoint: <endpoint>
   - request_id: <uuid>
   ```

3. **Slow Request Events:**
   ```
   Filter: event = "slow_request"
   Properties should include:
   - endpoint: <endpoint>
   - duration_ms: <milliseconds>
   - threshold_ms: 5000
   - request_id: <uuid>
   ```

### 4. **Correlation ID Verification** ⏳

**Test Flow:**
1. Make an API call from frontend
2. Note the `X-Request-ID` from response header
3. Search PostHog for that `request_id`
4. Should see:
   - Frontend events (if frontend includes request_id)
   - Backend `api_request` event
   - Any error events for that request

**Example:**
```
Frontend: User clicks button → trackEvent('button_click', { request_id: 'abc123' })
Backend: API call → api_request event with request_id: 'abc123'
PostHog: Search for request_id = 'abc123' → See both events linked
```

### 5. **Common Issues to Check**

#### Issue: No `X-Request-ID` Header
**Check:**
- Backend middleware is running
- Request tracking middleware is active
- Check backend logs for errors

**Solution:**
```bash
# Check backend logs
# Look for "Request started" and "Request completed" logs
# Should see request_id in logs
```

#### Issue: No Backend Events in PostHog
**Check:**
- Backend environment variables set:
  - `POSTHOG_PUBLIC_KEY`
  - `POSTHOG_SECRET_KEY`
  - `POSTHOG_PROJECT_ID`
  - `POSTHOG_HOST` (default: https://us.i.posthog.com)
- PostHog client not disabled
- Internal user filtering not blocking events

**Solution:**
```python
# Check backend PostHog config
from helper.posthog_helper import posthog
print(f"PostHog disabled: {posthog.disabled}")
print(f"PostHog host: {POSTHOG_HOST}")
```

#### Issue: PostHog Not Loading on Frontend
**Check:**
- Console for PostHog initialization errors
- Network tab for failed PostHog requests
- Environment variables:
  - `REACT_APP_POSTHOG_TOKEN`
  - `REACT_APP_POSTHOG_HOST`

**Solution:**
- Check browser console for errors
- Verify PostHog token is correct
- Check network tab for blocked requests

### 6. **Quick Test Script**

**In Browser Console:**
```javascript
// 1. Check PostHog
console.log('PostHog:', window.posthog);
console.log('Distinct ID:', window.posthog?.get_distinct_id());

// 2. Make API call and check headers
fetch('https://test.backend.scenextras.com/api/popular/movies?limit=1')
  .then(response => {
    console.log('Request ID:', response.headers.get('X-Request-ID'));
    console.log('Process Time:', response.headers.get('X-Process-Time'));
    return response.json();
  })
  .then(data => console.log('Data:', data));

// 3. Track a test event
window.posthog?.capture('test_event', {
  test_property: 'test_value',
  timestamp: new Date().toISOString()
});
```

### 7. **Expected Network Requests**

**Frontend to PostHog:**
- `https://us.i.posthog.com/decide/` - Feature flags and config
- `https://us.i.posthog.com/batch/` - Event tracking

**Frontend to Backend:**
- `https://test.backend.scenextras.com/api/*` - API calls
- Should include `X-Request-ID` in response headers

**Backend to PostHog:**
- `https://us.i.posthog.com/capture/` - Backend events
- Check backend logs for PostHog requests

## Summary Checklist

- [ ] PostHog loads on frontend (check console logs)
- [ ] PostHog events appear in network tab
- [ ] Backend API calls return `X-Request-ID` header
- [ ] `api_request` events appear in PostHog dashboard
- [ ] `request_id` present in all backend events
- [ ] Correlation IDs link frontend/backend events
- [ ] Error tracking works (`api_error` events)
- [ ] Slow request tracking works (`slow_request` events)

## Next Steps

1. **Make some API calls** from the frontend
2. **Check PostHog dashboard** for `api_request` events
3. **Verify correlation IDs** by checking `request_id` in events
4. **Test error tracking** by triggering an error
5. **Monitor Live Events** in PostHog to see real-time tracking

