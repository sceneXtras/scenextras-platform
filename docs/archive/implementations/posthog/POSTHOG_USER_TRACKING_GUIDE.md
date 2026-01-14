# Complete User Journey Tracking Guide - PostHog

## 🎯 How to Track Users Across All Interactions

Now that everything is set up, here's how to track a user's complete journey from frontend to backend.

---

## 🔑 **Key Identifiers**

### **1. User ID (`user_id` / `distinct_id`)**
- **Frontend:** User's authenticated ID (from Supabase/Auth)
- **Backend:** Extracted from JWT/auth headers
- **Used for:** Linking all events to a specific user

### **2. Request ID (`request_id`)**
- **Frontend:** UUID generated for each API request
- **Backend:** Uses frontend's `request_id` or generates new one
- **Used for:** Correlating frontend actions with backend API calls

### **3. Session ID (`session_id`)**
- **Frontend:** PostHog session ID
- **Used for:** Grouping events within a session

---

## 📊 **How to Track a User's Complete Journey**

### **Method 1: By User ID (Complete User History)**

#### **In PostHog Dashboard:**

1. **Go to:** Activity → Persons
2. **Search for:** User ID or email
3. **Click on:** User profile
4. **View:** All events for this user

#### **PostHog Query:**

```
Event: Any
Property: distinct_id = "user_12345"
```

**What you'll see:**
- All frontend events (clicks, page views, etc.)
- All backend API calls (`api_request` events)
- All errors (`api_error` events)
- All slow requests (`slow_request` events)
- Complete timeline of user actions

---

### **Method 2: By Request ID (Single User Action → Backend Flow)**

#### **Use Case:** Track a specific user action end-to-end

#### **Example Scenario:**
1. User clicks "Start Chat" button → Frontend event
2. Frontend makes API call → Backend receives request
3. Backend processes request → Backend events
4. Backend returns response → Frontend receives data

#### **Steps:**

1. **Find Frontend Event:**
   ```
   Event: button_click
   Property: button_name = "Start Chat"
   Property: distinct_id = "user_12345"
   ```

2. **Extract Request ID:**
   - Look for `request_id` property in the frontend event
   - Example: `request_id = "82b0da6e-9c9b-422b-b748-9e16ea98f45b"`

3. **Find All Related Backend Events:**
   ```
   Event: api_request
   Property: request_id = "82b0da6e-9c9b-422b-b748-9e16ea98f45b"
   ```

4. **See Complete Flow:**
   - Frontend event (with `request_id`)
   - Backend `api_request` event (same `request_id`)
   - Backend `slow_request` event (if slow, same `request_id`)
   - Backend `api_error` event (if error, same `request_id`)

---

### **Method 3: By Session ID (User's Current Session)**

#### **Use Case:** Track everything a user does in one session

#### **PostHog Query:**

```
Event: Any
Property: session_id = "019a3b6b-634f-72e5-a430-d105b888fb87"
```

**What you'll see:**
- All events in this session
- Frontend interactions
- Backend API calls
- Errors and performance issues

---

## 🔍 **Practical Examples**

### **Example 1: Track User Signup Flow**

**Query:**
```
distinct_id = "user_12345"
AND
event IN ["signup_started", "signup_completed", "api_request"]
AND
(
  endpoint LIKE "%/auth/signup%" OR
  endpoint LIKE "%/auth/verify%"
)
```

**What you'll see:**
1. `signup_started` - Frontend event
2. `api_request` with `endpoint = "/api/auth/signup"` - Backend API call
3. `api_request` with `endpoint = "/api/auth/verify"` - Email verification
4. `signup_completed` - Frontend event

**Timeline:**
```
10:00:00 - signup_started (request_id: abc-123)
10:00:01 - api_request (request_id: abc-123, endpoint: /api/auth/signup)
10:00:02 - api_request (request_id: abc-123, status: 200)
10:00:05 - signup_completed (request_id: abc-123)
```

---

### **Example 2: Track User Chat Interaction**

**Query:**
```
distinct_id = "user_12345"
AND
event IN ["chat_started", "api_request", "chat_message_sent"]
AND
(
  endpoint LIKE "%/chat%" OR
  character_id IS NOT NULL
)
```

**What you'll see:**
1. `chat_started` - Frontend event (user clicked chat)
2. `api_request` with `endpoint = "/api/chat/messages"` - Fetch chat history
3. `api_request` with `endpoint = "/api/chat/send"` - Send message
4. `api_request` with `endpoint = "/api/chat/stream"` - Stream response
5. `slow_request` - If any request was slow

**Timeline:**
```
10:05:00 - chat_started (request_id: def-456)
10:05:01 - api_request (request_id: def-456, endpoint: /api/chat/messages)
10:05:02 - api_request (request_id: def-456, status: 200, response_time_ms: 45)
10:05:05 - chat_message_sent (request_id: ghi-789)
10:05:06 - api_request (request_id: ghi-789, endpoint: /api/chat/send)
10:05:07 - api_request (request_id: ghi-789, status: 200, response_time_ms: 1200)
10:05:07 - slow_request (request_id: ghi-789, duration_ms: 1200, threshold_ms: 1000)
```

---

### **Example 3: Track User Error**

**Query:**
```
distinct_id = "user_12345"
AND
event = "api_error"
```

**What you'll see:**
- Error type
- Error message
- Endpoint where error occurred
- Request ID for correlation
- Traceback (truncated)

**Then correlate with frontend:**
```
request_id = "<from api_error>"
```

**See:**
- What frontend action triggered the error
- Complete error context
- User's actions before error

---

## 📈 **PostHog Dashboards**

### **Dashboard 1: User Journey Timeline**

**Create Dashboard with:**
1. **Events Table:**
   - Columns: Timestamp, Event, User ID, Request ID, Endpoint
   - Filter: `distinct_id = "{user_id}"`
   - Sort: Timestamp ascending

2. **Funnel:**
   - Step 1: Page View
   - Step 2: API Request (any)
   - Step 3: Successful API Response (status < 400)

3. **Timeline Visualization:**
   - X-axis: Time
   - Y-axis: Events
   - Color by: Event type

---

### **Dashboard 2: API Performance by User**

**Create Dashboard with:**
1. **Table:**
   - Filter: `event = "api_request" AND distinct_id = "{user_id}"`
   - Columns: Timestamp, Endpoint, Response Time, Status Code, Request ID

2. **Chart:**
   - Line chart: Response time over time
   - Filter: `event = "api_request" AND distinct_id = "{user_id}"`

3. **Slow Requests:**
   - Filter: `event = "slow_request" AND distinct_id = "{user_id}"`
   - Group by: Endpoint

---

### **Dashboard 3: Error Tracking by User**

**Create Dashboard with:**
1. **Errors Table:**
   - Filter: `event = "api_error" AND distinct_id = "{user_id}"`
   - Columns: Timestamp, Error Type, Endpoint, Request ID, Error Message

2. **Error Trends:**
   - Bar chart: Error count by endpoint
   - Filter: `event = "api_error" AND distinct_id = "{user_id}"`

3. **Correlated Events:**
   - Filter: `request_id IN (SELECT request_id FROM api_error WHERE distinct_id = "{user_id}")`

---

## 🔗 **Correlation Queries**

### **Find All Events for a Request:**

```
request_id = "82b0da6e-9c9b-422b-b748-9e16ea98f45b"
```

**Returns:**
- Frontend event (if tracked with `request_id`)
- Backend `api_request` event
- Backend `slow_request` event (if applicable)
- Backend `api_error` event (if error occurred)

---

### **Find User's Complete Journey:**

```
distinct_id = "user_12345"
ORDER BY timestamp ASC
```

**Returns:**
- All events for this user
- Chronological order
- Complete interaction history

---

### **Find Slow Requests for a User:**

```
distinct_id = "user_12345"
AND
event = "slow_request"
ORDER BY duration_ms DESC
```

**Returns:**
- All slow requests for this user
- Sorted by duration (slowest first)
- Includes `request_id` for correlation

---

## 🎯 **Best Practices**

### **1. Always Include Request ID in Frontend Events**

When tracking frontend events, include the `request_id` from the API response:

```typescript
// After API call
const response = await api.get('/api/popular/movies');
const requestId = response.headers['x-request-id'];

// Track event with correlation
trackEvent('movies_loaded', {
  request_id: requestId,  // ← Important!
  movie_count: response.data.length
});
```

---

### **2. Use Consistent User Identification**

Make sure `user_id` is consistent across:
- Frontend PostHog `identify()` calls
- Backend API requests (via JWT/auth)
- PostHog events

---

### **3. Query by Multiple Properties**

For best results, combine filters:

```
distinct_id = "user_12345"
AND
event IN ["api_request", "api_error", "slow_request"]
AND
timestamp >= "2025-10-31T00:00:00Z"
```

---

## 📋 **Quick Reference**

### **PostHog Event Properties:**

| Property | Source | Purpose |
|----------|--------|---------|
| `distinct_id` | Frontend/Backend | User identifier |
| `request_id` | Frontend/Backend | Request correlation |
| `session_id` | Frontend | Session grouping |
| `endpoint` | Backend | API endpoint |
| `method` | Backend | HTTP method |
| `status_code` | Backend | Response status |
| `response_time_ms` | Backend | Performance |
| `error_type` | Backend | Error category |
| `environment` | Both | Environment name |

---

## 🚀 **Next Steps**

1. **Create PostHog Dashboards:**
   - User Journey Timeline
   - API Performance by User
   - Error Tracking by User

2. **Set Up Alerts:**
   - Alert on `slow_request` events
   - Alert on `api_error` events for specific users
   - Alert on multiple errors for same `request_id`

3. **Create Cohorts:**
   - Users with slow requests
   - Users with errors
   - Users with successful journeys

4. **Build Funnels:**
   - Signup → First Chat → Engagement
   - Using `request_id` correlation

---

**You now have complete visibility into user journeys across your entire platform!** 🎉

