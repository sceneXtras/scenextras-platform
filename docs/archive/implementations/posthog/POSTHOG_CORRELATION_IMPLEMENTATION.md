# Frontend Correlation Implementation Complete ✅

## ✅ Changes Implemented

### 1. **Frontend API Client** (`frontend_webapp/src/api/apiClient.ts`)

**Request Interceptor:**
- ✅ Generates UUID for each API request
- ✅ Sends `X-Request-ID` header to backend
- ✅ Stores `requestId` in config for correlation

**Response Interceptor:**
- ✅ Extracts `X-Request-ID` from backend response headers
- ✅ Updates config with backend's `request_id` for correlation
- ✅ Adds `request_id` to Sentry breadcrumbs

### 2. **PostHog Utils** (`frontend_webapp/src/utils/posthogUtils.ts`)

**Enhanced `trackEvent` Function:**
- ✅ Accepts optional `requestId` parameter
- ✅ Includes `request_id` in PostHog events when provided
- ✅ Enables correlation between frontend and backend events

### 3. **Backend Middleware** (`sceneXtras/api/main.py`)

**Enhanced Request Tracking:**
- ✅ Accepts `X-Request-ID` from frontend if provided
- ✅ Uses frontend's `request_id` for correlation
- ✅ Falls back to generating new UUID if not provided

## 🎯 How It Works Now

### **Complete User Journey Flow:**

1. **User clicks button on frontend**
   ```typescript
   // Frontend generates request_id
   const requestId = uuidv4(); // e.g., "abc-123-xyz"
   ```

2. **Frontend makes API call**
   ```typescript
   // Request sent with X-Request-ID header
   headers: { 'X-Request-ID': 'abc-123-xyz' }
   ```

3. **Backend receives request**
   ```python
   # Backend uses frontend's request_id
   request_id = "abc-123-xyz"  # Same ID!
   ```

4. **Backend sends response**
   ```python
   # Response includes X-Request-ID header
   headers: { 'X-Request-ID': 'abc-123-xyz' }
   ```

5. **Frontend tracks event with request_id**
   ```typescript
   trackEvent('button_click', {
     button_name: 'search',
     request_id: 'abc-123-xyz'  // Correlates with backend!
   });
   ```

6. **Backend tracks API call**
   ```python
   telemetry.capture_api_performance(
     request_id='abc-123-xyz',  # Same ID!
     endpoint='/api/popular/movies',
     ...
   )
   ```

## 📊 PostHog Correlation

**Now you can:**

1. **Search for a request_id in PostHog:**
   ```
   properties.request_id = "abc-123-xyz"
   ```

2. **See both events:**
   - ✅ Frontend: `button_click` event
   - ✅ Backend: `api_request` event

3. **Track complete user journey:**
   - Frontend action → Backend API call → Response
   - All linked via same `request_id`

## 🔧 Usage Examples

### **Example 1: Track Button Click with API Call**

```typescript
const handleSearch = async () => {
  try {
    // Make API call
    const response = await api.get('/api/popular/movies');
    
    // Get request_id from response
    const requestId = response.headers['x-request-id'];
    
    // Track frontend event with request_id
    trackEvent('search_performed', {
      search_term: searchTerm,
      results_count: response.data.length,
      request_id: requestId, // Links to backend api_request event
    });
  } catch (error) {
    // Error handling
  }
};
```

### **Example 2: Track Form Submission**

```typescript
const handleSubmit = async (formData) => {
  try {
    const response = await api.post('/api/submit', formData);
    const requestId = response.headers['x-request-id'];
    
    trackEvent('form_submitted', {
      form_type: 'contact',
      request_id: requestId,
    });
  } catch (error) {
    const requestId = error.response?.headers?.['x-request-id'];
    trackEvent('form_error', {
      form_type: 'contact',
      error: error.message,
      request_id: requestId,
    });
  }
};
```

### **Example 3: Automatic Correlation (Recommended)**

Create a helper function for automatic correlation:

```typescript
// In a utility file
export const trackEventWithRequestId = async (
  eventName: string,
  properties: Record<string, any>,
  apiCall: () => Promise<any>
) => {
  try {
    const response = await apiCall();
    const requestId = response.headers['x-request-id'];
    
    trackEvent(eventName, {
      ...properties,
      request_id: requestId,
      success: true,
    });
    
    return response;
  } catch (error) {
    const requestId = error.response?.headers?.['x-request-id'];
    trackEvent(`${eventName}_error`, {
      ...properties,
      request_id: requestId,
      error: error.message,
      success: false,
    });
    throw error;
  }
};

// Usage:
await trackEventWithRequestId(
  'movies_loaded',
  { source: 'homepage' },
  () => api.get('/api/popular/movies')
);
```

## ✅ Verification Checklist

### **Frontend:**
- [x] ✅ Generates UUID for each request
- [x] ✅ Sends `X-Request-ID` header to backend
- [x] ✅ Extracts `request_id` from response headers
- [x] ✅ `trackEvent` accepts optional `request_id`
- [x] ✅ Includes `request_id` in PostHog events

### **Backend:**
- [x] ✅ Accepts `X-Request-ID` from frontend
- [x] ✅ Uses frontend's `request_id` for correlation
- [x] ✅ Sends `X-Request-ID` in response headers
- [x] ✅ Includes `request_id` in PostHog events

### **Next Steps:**
- [ ] Update components to use `request_id` in `trackEvent` calls
- [ ] Test correlation in PostHog dashboard
- [ ] Verify end-to-end user journey tracking

## 🎉 Summary

**You can now:**
1. ✅ Track users from frontend to backend
2. ✅ Correlate frontend actions with API calls
3. ✅ See complete user journey in PostHog
4. ✅ Link events across all services via `request_id`

**Next:** Update your components to include `request_id` in `trackEvent` calls for full correlation!

