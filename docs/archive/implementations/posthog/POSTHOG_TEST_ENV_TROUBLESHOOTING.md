# PostHog Backend Verification - Test Environment Troubleshooting

## 🔍 Current Status

### ✅ Frontend PostHog
- **Status:** ✅ Loading
- PostHog scripts loading from `us-assets.i.posthog.com`
- Console shows: "PostHog initialized successfully"
- Session ID: `019a3b0b-3385-7c42-ab6f-4500940cfc6e`
- Session Recording: INACTIVE (manual start failed)

### ❌ Backend Request Tracking
- **Issue:** `X-Request-ID` header is **NULL** in API responses
- **Test Result:** API call to `/api/popular/movies` returned:
  - `status: 200` ✅
  - `requestId: null` ❌
  - `processTime: null` ❌
  - `processId: null` ❌

## 🚨 Critical Issue Found

**The backend middleware is NOT adding `X-Request-ID` headers!**

This means either:
1. The middleware isn't running on the test backend
2. The middleware code wasn't deployed
3. There's a CORS issue preventing headers from being visible

## ✅ What to Check

### 1. **Backend Code Deployment**

**Check if your changes are deployed:**
```bash
# SSH into test backend or check deployment logs
# Verify these files exist and have your changes:
- sceneXtras/api/main.py (lines 519-650)
- sceneXtras/api/helper/posthog_telemetry.py
- sceneXtras/api/helper/exception_logger.py
```

**Verify middleware is active:**
```bash
# Check backend logs for:
# "Request started: GET /api/popular/movies"
# Should see request_id in logs
```

### 2. **Backend Environment Variables**

**Check if PostHog vars are set:**
```bash
# On test backend server:
echo $POSTHOG_PUBLIC_KEY
echo $POSTHOG_SECRET_KEY
echo $POSTHOG_PROJECT_ID
echo $POSTHOG_HOST
```

**If missing, set them:**
```bash
export POSTHOG_PUBLIC_KEY="your-key"
export POSTHOG_SECRET_KEY="your-secret"
export POSTHOG_PROJECT_ID="your-project-id"
export POSTHOG_HOST="https://us.i.posthog.com"
```

### 3. **CORS Headers**

**Check if CORS is blocking headers:**
- Open Browser DevTools → Network
- Click on API request → Headers tab
- Check **Response Headers** section
- Look for `X-Request-ID` (might be hidden by CORS)

**If headers are blocked:**
- Check backend CORS configuration
- Ensure `X-Request-ID`, `X-Process-Time`, `X-Process-ID` are in exposed headers

### 4. **Backend Logs**

**Check backend logs for:**
```bash
# Should see logs like:
# "Request started: GET /api/popular/movies"
# "Request completed: GET /api/popular/movies"
# With request_id in the context
```

**If no logs:**
- Middleware might not be running
- Check middleware order in `main.py`
- Verify `unified_request_tracking` middleware is registered

### 5. **PostHog Events**

**Check PostHog dashboard:**
- Go to: https://us.i.posthog.com
- Navigate to: **Events**
- Filter: `event = "api_request"`
- Should see events for API calls

**If no events:**
- Backend PostHog client might be disabled
- Check `posthog.disabled` status
- Verify environment variables are set

## 🔧 Quick Fixes

### Fix 1: Verify Middleware Order

**Check `main.py` middleware order:**
```python
# Should be in this order:
1. identify_user_middleware (sets user_id)
2. unified_request_tracking (adds request_id)
```

### Fix 2: Check CORS Configuration

**Verify CORS exposes headers:**
```python
# In your FastAPI CORS middleware:
expose_headers=["X-Request-ID", "X-Process-Time", "X-Process-ID"]
```

### Fix 3: Test Backend Directly

**Test backend API directly:**
```bash
curl -I https://test.backend.scenextras.com/api/popular/movies?limit=1

# Should see:
# X-Request-ID: <uuid>
# X-Process-Time: <time>
# X-Process-ID: <pid>
```

## 📋 Verification Checklist

### Backend Checks:
- [ ] Code changes deployed to test backend
- [ ] Middleware is active (check logs)
- [ ] Environment variables set
- [ ] CORS exposes headers
- [ ] PostHog client not disabled

### Frontend Checks:
- [ ] PostHog loads (✅ confirmed)
- [ ] PostHog events sent (check network tab)
- [ ] API calls return `X-Request-ID` header (❌ currently null)

### PostHog Dashboard Checks:
- [ ] Frontend events appear
- [ ] Backend `api_request` events appear
- [ ] `request_id` present in events
- [ ] Events linked via correlation IDs

## 🎯 Next Steps

1. **Verify backend deployment:**
   - Check if code changes are on test backend
   - Verify middleware is running
   - Check backend logs

2. **Fix CORS (if needed):**
   - Add `X-Request-ID` to exposed headers
   - Restart backend

3. **Verify PostHog config:**
   - Check environment variables
   - Verify PostHog client is enabled
   - Test PostHog connection

4. **Test again:**
   - Make API calls
   - Check for `X-Request-ID` header
   - Verify events in PostHog dashboard

## 🔍 Debugging Commands

**On Backend Server:**
```bash
# Check if middleware is running
grep -r "unified_request_tracking" sceneXtras/api/main.py

# Check PostHog config
python -c "from helper.posthog_helper import posthog; print(f'Disabled: {posthog.disabled}')"

# Check logs
tail -f logs/app.log | grep "Request started"

# Test API endpoint
curl -I https://test.backend.scenextras.com/api/popular/movies?limit=1
```

**In Browser Console:**
```javascript
// Check for headers
fetch('https://test.backend.scenextras.com/api/popular/movies?limit=1')
  .then(r => {
    console.log('Headers:', [...r.headers.entries()]);
    console.log('X-Request-ID:', r.headers.get('X-Request-ID'));
  });
```

## Summary

**Main Issue:** Backend middleware not adding `X-Request-ID` headers

**Likely Causes:**
1. Code changes not deployed to test backend
2. Middleware not running
3. CORS blocking headers

**Priority Fixes:**
1. Verify backend code is deployed
2. Check backend logs for middleware activity
3. Verify CORS configuration exposes headers
4. Check PostHog environment variables

Once `X-Request-ID` appears in headers, backend tracking should work!

