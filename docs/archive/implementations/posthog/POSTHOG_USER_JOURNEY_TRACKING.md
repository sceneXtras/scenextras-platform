# Complete User Journey Tracking - Current Status & Enhancement Plan

## 🎯 Your Question: Can you track a user across all repositories?

**Short Answer:** **Partially YES**, but with **enhancements needed** for full correlation.

## ✅ What's Working NOW

### 1. **Backend API Tracking** ✅

**Python API Backend:**
- ✅ Generates unique `request_id` (UUID) for every request
- ✅ Adds `X-Request-ID` header to all responses
- ✅ Tracks `user_id` from authentication
- ✅ Sends `api_request` events to PostHog with:
  - `request_id` - Correlation ID
  - `user_id` - User identifier
  - `endpoint` - API endpoint
  - `method` - HTTP method
  - `status_code` - Response status
  - `response_time_ms` - Performance metrics

**Go Search Engine:**
- ✅ Has PostHog integration
- ✅ Extracts `user_id` from headers
- ❓ Need to verify if it generates/sends `request_id`

### 2. **User Identification** ✅

**Frontend (React Web):**
- ✅ PostHog initialized
- ✅ User identification via `posthog.identify(userId)`
- ✅ Tracks user properties (email, subscription, etc.)

**Mobile App:**
- ✅ PostHog initialized
- ✅ User identification with properties
- ✅ Platform-specific tracking

**Backend:**
- ✅ Extracts `user_id` from auth headers
- ✅ Uses `user_id` as `distinct_id` in PostHog events

## ❌ What's Missing for Full Correlation

### 1. **Frontend → Backend Correlation** ❌

**Current Issue:**
- Frontend generates `requestId` but doesn't pass it to backend
- Backend generates its own `request_id` (different UUID)
- **Result:** Can't link frontend events to backend events

**What's Needed:**
```typescript
// Frontend should send X-Request-ID header to backend
config.headers['X-Request-ID'] = requestId; // UUID
```

### 2. **Frontend PostHog Events Missing `request_id`** ❌

**Current Issue:**
- Frontend PostHog events don't include `request_id`
- Can't correlate frontend clicks with backend API calls

**What's Needed:**
```typescript
// Include request_id in frontend PostHog events
trackEvent('button_click', {
  request_id: requestId, // From API response header
  // ... other properties
});
```

### 3. **Cross-Service Correlation** ❓

**Go Search Engine:**
- Need to verify if it generates/sends `request_id`
- Need to verify if it correlates with Python API

**Mobile App:**
- Need to verify if it passes `request_id` to backend
- Need to verify PostHog events include `request_id`

## 🔧 Enhancement Plan

### **Phase 1: Frontend → Backend Correlation** (HIGH PRIORITY)

**Step 1: Send Request ID to Backend**

Modify `frontend_webapp/src/api/apiClient.ts`:

```typescript
// In request interceptor
api.interceptors.request.use((config) => {
  // Generate or reuse request ID
  const requestId = uuidv4();
  (config as CustomRequestConfig).requestId = requestId;
  
  // Send to backend so it can correlate
  config.headers['X-Request-ID'] = requestId;
  
  return config;
});

// In response interceptor
api.interceptors.response.use((response) => {
  // Get request_id from response header (backend's correlation ID)
  const backendRequestId = response.headers['x-request-id'];
  
  // Store for PostHog tracking
  (response.config as CustomRequestConfig).requestId = backendRequestId;
  
  return response;
});
```

**Step 2: Include Request ID in Frontend PostHog Events**

Modify `frontend_webapp/src/utils/posthogUtils.ts`:

```typescript
export const trackEvent = (
  eventName: string,
  properties: Record<string, any> = {},
  requestId?: string, // Optional request_id from API response
) => {
  const userId = getCurrentUserId();
  const email = getUserEmail();
  
  if (isInternalUser(userId, email)) {
    return;
  }
  
  if (isPostHogAvailable()) {
    const enrichedProperties = {
      ...getStandardProperties(properties),
      ...properties,
      // Include request_id if available
      ...(requestId && { request_id: requestId }),
    };
    
    safePosthog.capture(eventName, enrichedProperties);
  }
};
```

**Step 3: Track Frontend Actions with Request ID**

```typescript
// After API call, track frontend event with request_id
const response = await api.get('/api/popular/movies');
const requestId = response.headers['x-request-id'];

trackEvent('movies_viewed', {
  movie_count: response.data.length,
  request_id: requestId, // Link to backend api_request event
});
```

### **Phase 2: Backend Accept Request ID** (MEDIUM PRIORITY)

**Modify Backend Middleware:**

```python
# In unified_request_tracking middleware
@app.middleware("http")
async def unified_request_tracking(request: Request, call_next):
    # Use frontend's request_id if provided, otherwise generate new one
    frontend_request_id = request.headers.get("X-Request-ID")
    request_id = frontend_request_id or str(uuid.uuid4())
    
    request.state.request_id = request_id
    # ... rest of middleware
```

### **Phase 3: Cross-Service Correlation** (LOW PRIORITY)

**Go Search Engine:**
- Generate `request_id` if not provided
- Include `request_id` in PostHog events
- Accept `X-Request-ID` from Python API calls

**Mobile App:**
- Generate `request_id` for API calls
- Send `X-Request-ID` to backend
- Include `request_id` in PostHog events

## 📊 What You CAN Track NOW

### ✅ **Backend-Only Tracking**

**You can currently track:**
1. ✅ All API requests by user (`user_id`)
2. ✅ API performance metrics (`response_time_ms`)
3. ✅ Error tracking (`api_error` events)
4. ✅ Slow requests (`slow_request` events)
5. ✅ User journey through API endpoints

**PostHog Query:**
```
distinct_id = "user_123"
event = "api_request"
```

**Shows:**
- All API calls made by user
- Endpoints accessed
- Performance metrics
- Error rates

### ❌ **What You CANNOT Track (Yet)**

1. ❌ Frontend clicks → Backend API calls correlation
2. ❌ User journey from page load → API call → response
3. ❌ Frontend errors → Backend errors correlation
4. ❌ Cross-service request flow (Python → Go → Python)

## 🎯 Recommended Next Steps

### **Immediate (High Impact, Low Effort):**

1. **Add `X-Request-ID` header to frontend API calls**
   - Time: 30 minutes
   - Impact: Enables frontend → backend correlation

2. **Include `request_id` in frontend PostHog events**
   - Time: 1 hour
   - Impact: Links frontend actions to backend events

### **Short Term (Medium Impact, Medium Effort):**

3. **Backend accepts frontend's `request_id`**
   - Time: 30 minutes
   - Impact: Single correlation ID across frontend/backend

4. **Verify Go Search Engine PostHog integration**
   - Time: 1 hour
   - Impact: Complete cross-service tracking

### **Long Term (High Impact, High Effort):**

5. **Implement request ID propagation**
   - Time: 2-3 hours
   - Impact: Full user journey tracking across all services

## 📋 Implementation Checklist

### Frontend Enhancements:
- [ ] Generate `request_id` (UUID) for each API call
- [ ] Send `X-Request-ID` header to backend
- [ ] Extract `request_id` from response headers
- [ ] Include `request_id` in PostHog events
- [ ] Track frontend actions with `request_id`

### Backend Enhancements:
- [ ] Accept `X-Request-ID` from frontend
- [ ] Use frontend's `request_id` if provided
- [ ] Verify `request_id` propagation in all services

### Cross-Service:
- [ ] Verify Go Search Engine PostHog integration
- [ ] Verify Mobile App PostHog integration
- [ ] Test end-to-end correlation

## 🎉 Summary

**Current State:**
- ✅ Backend tracks all API requests with `user_id` and `request_id`
- ✅ Can see all backend API calls per user
- ❌ Cannot correlate frontend actions with backend calls
- ❌ Cannot track full user journey across services

**After Enhancements:**
- ✅ Full user journey tracking from frontend → backend
- ✅ Correlate frontend clicks with API calls
- ✅ Track user across all repositories/services
- ✅ See complete user interaction flow

**Next Step:** Implement Phase 1 (Frontend → Backend Correlation) for immediate impact!

