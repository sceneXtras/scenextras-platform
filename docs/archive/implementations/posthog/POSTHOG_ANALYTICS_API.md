# PostHog Analytics API - Complete User Journey Tracking

## 🎯 Overview

This API provides endpoints to query PostHog for complete user activity, errors, performance metrics, and user journeys. All endpoints require authentication and can be used to track users across your entire platform.

---

## 📋 **API Endpoints**

### **Base URL:** `/api/analytics`

All endpoints require authentication via JWT token in the `Authorization` header.

---

### **1. Get User Activity Summary**

**Endpoint:** `GET /api/analytics/user/activity`

**Description:** Get comprehensive activity summary for a user including API requests, errors, slow requests, and most used endpoints.

**Query Parameters:**
- `user_id` (optional): User's distinct_id from PostHog
- `email` (optional): User's email address
- `days` (optional): Number of days to look back (default: 30, max: 365)

**If neither `user_id` nor `email` provided:** Returns data for the authenticated user.

**Response:**
```json
{
  "user_id": "user_12345",
  "period_days": 30,
  "total_events": 1234,
  "api_requests": {
    "total": 850,
    "successful": 820,
    "failed": 30,
    "average_response_time_ms": 125.5
  },
  "errors": {
    "total": 25,
    "by_type": {
      "application_error": 15,
      "connection_error": 5,
      "validation_error": 5
    }
  },
  "slow_requests": {
    "total": 12,
    "by_endpoint": {
      "/api/chat/send": {
        "count": 8,
        "average_duration_ms": 1250.5
      }
    }
  },
  "most_used_endpoints": {
    "/api/popular/movies": 150,
    "/api/chat/messages": 120,
    "/api/tailored-characters": 100
  },
  "timeline": [
    {
      "timestamp": "2025-10-31T17:00:00Z",
      "event": "api_request",
      "properties": {
        "endpoint": "/api/popular/movies",
        "status_code": 200,
        "response_time_ms": 45
      }
    }
  ]
}
```

**Example Request:**
```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/activity?email=user@example.com&days=7" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### **2. Get User Journey**

**Endpoint:** `GET /api/analytics/user/journey`

**Description:** Get complete user journey with correlated events grouped by `request_id`. This shows the full flow from frontend actions to backend API calls.

**Query Parameters:**
- `user_id` (optional): User's distinct_id from PostHog
- `email` (optional): User's email address
- `days` (optional): Number of days to look back (default: 7, max: 90)
- `include_correlation` (optional): Include request_id correlation (default: true)

**Response:**
```json
{
  "user_id": "user_12345",
  "period_days": 7,
  "total_events": 450,
  "correlated_requests": 120,
  "events": [
    {
      "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b",
      "events": [
        {
          "timestamp": "2025-10-31T17:00:00Z",
          "event": "button_click",
          "properties": {
            "button_name": "Start Chat",
            "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b"
          }
        },
        {
          "timestamp": "2025-10-31T17:00:01Z",
          "event": "api_request",
          "properties": {
            "endpoint": "/api/chat/start",
            "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b",
            "status_code": 200,
            "response_time_ms": 45
          }
        }
      ],
      "event_count": 2,
      "start_time": "2025-10-31T17:00:00Z",
      "end_time": "2025-10-31T17:00:01Z"
    }
  ]
}
```

**Example Request:**
```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/journey?user_id=user_12345&days=7" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### **3. Get User Events**

**Endpoint:** `GET /api/analytics/user/events`

**Description:** Get all events for a user, optionally filtered by event type.

**Query Parameters:**
- `user_id` (optional): User's distinct_id from PostHog
- `email` (optional): User's email address
- `event_type` (optional): Filter by event type (e.g., 'api_request', 'api_error', 'slow_request')
- `limit` (optional): Maximum number of events (default: 100, max: 1000)
- `days` (optional): Number of days to look back (default: 30, max: 365)

**Response:**
```json
{
  "events": [
    {
      "timestamp": "2025-10-31T17:00:00Z",
      "event": "api_request",
      "properties": {
        "endpoint": "/api/popular/movies",
        "method": "GET",
        "status_code": 200,
        "response_time_ms": 45,
        "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b"
      }
    }
  ],
  "total": 1,
  "user_id": "user_12345"
}
```

**Example Request:**
```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/events?email=user@example.com&event_type=api_request&limit=50" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### **4. Get User Errors**

**Endpoint:** `GET /api/analytics/user/errors`

**Description:** Get all errors encountered by a user with detailed error information.

**Query Parameters:**
- `user_id` (optional): User's distinct_id from PostHog
- `email` (optional): User's email address
- `limit` (optional): Maximum number of errors (default: 50, max: 500)
- `days` (optional): Number of days to look back (default: 30, max: 365)

**Response:**
```json
{
  "user_id": "user_12345",
  "total_errors": 5,
  "errors": [
    {
      "timestamp": "2025-10-31T17:00:00Z",
      "error_type": "application_error",
      "error_message": "Database connection failed",
      "exception_type": "OperationalError",
      "endpoint": "/api/chat/send",
      "method": "POST",
      "status_code": 500,
      "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b",
      "traceback": "..."
    }
  ]
}
```

**Example Request:**
```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/errors?email=user@example.com&days=7" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### **5. Get Request Events**

**Endpoint:** `GET /api/analytics/request/{request_id}`

**Description:** Get all events for a specific `request_id`. This allows you to correlate frontend and backend events for a single request.

**Path Parameters:**
- `request_id`: Request correlation ID (UUID)

**Response:**
```json
{
  "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b",
  "total_events": 3,
  "events": [
    {
      "timestamp": "2025-10-31T17:00:00Z",
      "event": "button_click",
      "properties": {
        "button_name": "Start Chat",
        "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b"
      }
    },
    {
      "timestamp": "2025-10-31T17:00:01Z",
      "event": "api_request",
      "properties": {
        "endpoint": "/api/chat/start",
        "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b",
        "status_code": 200
      }
    },
    {
      "timestamp": "2025-10-31T17:00:01Z",
      "event": "api_request",
      "properties": {
        "endpoint": "/api/chat/messages",
        "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b",
        "status_code": 200
      }
    }
  ]
}
```

**Example Request:**
```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/request/82b0da6e-9c9b-422b-b748-9e16ea98f45b" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### **6. Get User Slow Requests**

**Endpoint:** `GET /api/analytics/user/slow-requests`

**Description:** Get all slow requests for a user (requests that exceeded the threshold).

**Query Parameters:**
- `user_id` (optional): User's distinct_id from PostHog
- `email` (optional): User's email address
- `limit` (optional): Maximum number of slow requests (default: 50, max: 500)
- `days` (optional): Number of days to look back (default: 30, max: 365)

**Response:**
```json
{
  "user_id": "user_12345",
  "total_slow_requests": 3,
  "slow_requests": [
    {
      "timestamp": "2025-10-31T17:00:00Z",
      "endpoint": "/api/chat/send",
      "method": "POST",
      "duration_ms": 1250,
      "threshold_ms": 1000,
      "request_id": "82b0da6e-9c9b-422b-b748-9e16ea98f45b"
    }
  ]
}
```

**Example Request:**
```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/slow-requests?email=user@example.com&days=7" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🔐 **Authentication**

All endpoints require authentication via JWT token:

```bash
Authorization: Bearer YOUR_JWT_TOKEN
```

The token can be obtained from:
- Login endpoint: `POST /api/auth/new_auth_route`
- Or any authenticated user session

---

## 📝 **Usage Examples**

### **Example 1: Get Current User's Activity**

```bash
# Get activity for authenticated user (no user_id/email needed)
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/activity?days=7" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### **Example 2: Get User Journey by Email**

```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/journey?email=user@example.com&days=7" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### **Example 3: Get All Errors for a User**

```bash
curl -X GET "https://test.backend.scenextras.com/api/analytics/user/errors?user_id=user_12345&days=30" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### **Example 4: Track a Specific Request**

```bash
# From a response header or event property
curl -X GET "https://test.backend.scenextras.com/api/analytics/request/82b0da6e-9c9b-422b-b748-9e16ea98f45b" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🔧 **Python Client Example**

```python
import requests

# Base URL
BASE_URL = "https://test.backend.scenextras.com"
JWT_TOKEN = "your_jwt_token"

headers = {
    "Authorization": f"Bearer {JWT_TOKEN}",
    "Content-Type": "application/json",
}

# Get user activity
response = requests.get(
    f"{BASE_URL}/api/analytics/user/activity",
    params={"email": "user@example.com", "days": 7},
    headers=headers
)
activity = response.json()

# Get user journey
response = requests.get(
    f"{BASE_URL}/api/analytics/user/journey",
    params={"user_id": "user_12345", "days": 7},
    headers=headers
)
journey = response.json()

# Get errors
response = requests.get(
    f"{BASE_URL}/api/analytics/user/errors",
    params={"email": "user@example.com", "days": 30},
    headers=headers
)
errors = response.json()

# Get events for a request
response = requests.get(
    f"{BASE_URL}/api/analytics/request/82b0da6e-9c9b-422b-b748-9e16ea98f45b",
    headers=headers
)
request_events = response.json()
```

---

## 🚀 **Use Cases**

### **1. Customer Support**

```python
# Get user's recent errors and slow requests
errors = requests.get(
    f"{BASE_URL}/api/analytics/user/errors",
    params={"email": customer_email, "days": 7},
    headers=headers
).json()

slow_requests = requests.get(
    f"{BASE_URL}/api/analytics/user/slow-requests",
    params={"email": customer_email, "days": 7},
    headers=headers
).json()

# Show customer support agent what the user experienced
```

### **2. User Journey Analysis**

```python
# Get complete user journey for analysis
journey = requests.get(
    f"{BASE_URL}/api/analytics/user/journey",
    params={"user_id": user_id, "days": 30},
    headers=headers
).json()

# Analyze user flow, identify drop-off points, etc.
```

### **3. Performance Monitoring**

```python
# Get slow requests for a user
slow_requests = requests.get(
    f"{BASE_URL}/api/analytics/user/slow-requests",
    params={"user_id": user_id, "days": 7},
    headers=headers
).json()

# Identify performance issues affecting this user
```

### **4. Error Tracking**

```python
# Get all errors for a user
errors = requests.get(
    f"{BASE_URL}/api/analytics/user/errors",
    params={"email": user_email, "days": 30},
    headers=headers
).json()

# Categorize errors, identify patterns, etc.
```

---

## ⚙️ **Configuration**

Required environment variables:

```bash
POSTHOG_SECRET_KEY=your_posthog_secret_key
POSTHOG_PROJECT_ID=your_posthog_project_id
POSTHOG_HOST=https://us.i.posthog.com  # Optional, defaults to US region
```

---

## 📊 **Response Format**

All endpoints return JSON with consistent structure:

- **Success:** HTTP 200 with data payload
- **Not Found:** HTTP 404 with error message
- **Bad Request:** HTTP 400 with error details
- **Unauthorized:** HTTP 401 (missing/invalid token)
- **Server Error:** HTTP 500 with error message

---

## 🎯 **Key Features**

1. ✅ **Complete User Journey Tracking** - See frontend → backend correlation
2. ✅ **Error Tracking** - All errors with context and traceback
3. ✅ **Performance Monitoring** - Slow requests and response times
4. ✅ **Request Correlation** - Link frontend actions to backend API calls
5. ✅ **Flexible Querying** - By user_id, email, or authenticated user
6. ✅ **Time Range Filtering** - Specify days to look back
7. ✅ **Event Type Filtering** - Filter by specific event types

---

**Status: ✅ Ready to Use**

All endpoints are fully functional and ready for production use!

