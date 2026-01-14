# PostHog Integration Guide

## Overview

PostHog is fully implemented across all three environments (Python API Backend, React Web Frontend, React Native Mobile App) for comprehensive event tracking, analytics, and user journey analysis.

---

## Configuration

### Environment Variables

**Python API** (`sceneXtras/api/.env`):
```
POSTHOG_PUBLIC_KEY=phc_xxxx        # Public key for client-side tracking
POSTHOG_SECRET_KEY=xxxx             # Secret key for server-side API access
POSTHOG_PROJECT_ID=xxxxx            # Project ID for API calls
POSTHOG_HOST=https://us.i.posthog.com  # Host URL (optional, defaults to app.posthog.com)
```

**React Web** (`frontend_webapp/.env`):
```
REACT_APP_POSTHOG_TOKEN=phc_xxxx    # Public key (primary)
REACT_APP_POSTHOG_HOST=https://us.i.posthog.com  # Host URL
REACT_APP_POSTHOG_INTERNAL_DOMAINS=scenextras.com  # Internal domains to filter
REACT_APP_POSTHOG_INTERNAL_USER_IDS=user1,user2    # Internal user IDs to filter
```

**React Native** (`mobile_app_sx/.env`):
```
EXPO_PUBLIC_POSTHOG_API_KEY=phc_xxxx  # Public key
EXPO_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com  # Host URL
```

---

## Implementation Details

### Backend (Python API)

**Location:** `sceneXtras/api/helper/posthog_helper.py` and `posthog_telemetry.py`

**Tracked Events:**
- Chat completions (`chat_completion`, `chat_error`)
- Image generation (`image_generation`, `image_generation_error`)
- Subscriptions (`subscription_created`, `subscription_updated`, `subscription_cancelled`)
- Authentication (`login`, `auth_signup`, `auth_logout`)
- Referrals (`referral_apply_success`, `referral_apply_failed`)
- Story generation (`story_generation`, `story_generation_error`)
- Voice synthesis (`voice_synthesis`, `voice_synthesis_error`)
- API performance (`api_request`, `slow_request`)
- Feature usage (`feature_usage`)

**User Identification:**
- Uses `user_id` as `distinct_id`
- Includes environment metadata in all events

### Frontend (React Web)

**Key Features:**
- PostHog initialization on app load
- Automatic page view tracking
- User identify on login
- Internal domain/user filtering

**Environment Filtering:**
- Filters events from internal test domains (default: `scenextras.com`)
- Filters internal user IDs from analytics

### Mobile App (React Native)

**Key Features:**
- PostHog initialization via Expo SDK
- User tracking on app launch
- Event capture for all user interactions
- Platform-specific event properties

---

## User Journey Tracking

### By User ID (Complete History)

**In PostHog Dashboard:**
1. Go to: Activity → Persons
2. Search for: User ID or email
3. Click on: User profile
4. View: All events for this user

**PostHog Query:**
```
Event: Any
Property: distinct_id = "user_12345"
```

### By Request ID (Correlate Frontend to Backend)

Frontend generates `request_id` UUID for each API request. Backend includes this in `api_request` events.

**Query:**
```
Event: api_request
Property: request_id = "uuid-xxxxx"
```

### By Session ID (Group Events)

PostHog automatically groups frontend events by session. Query:
```
Event: Any
Property: $session_id = "session-id"
```

---

## API Endpoints

### Get User Activity Summary

**Endpoint:** `GET /api/analytics/user/activity`

**Parameters:**
- `user_id` (optional): User's distinct_id
- `email` (optional): User's email
- `days` (optional): Days to look back (default: 30, max: 365)

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
  }
}
```

---

## Event Verification

### Backend Events

Verify server-side events are being captured:

```bash
# Check backend is sending events
curl http://localhost:8080/debug/posthog

# Response should show connected status and event counts
```

### Frontend Events

Open browser DevTools → Network tab and filter for `posthog`. You should see POST requests to PostHog API.

### Mobile Events

Enable Flipper debugging in the mobile app to inspect PostHog events.

---

## Troubleshooting

### Events Not Appearing

1. **Check environment variables** are set correctly
2. **Verify API key** has correct permissions
3. **Check request headers** include authorization
4. **Review logs** in service for PostHog errors

### Performance Issues

- PostHog events are non-blocking (fire and forget)
- Backend events are async/queued
- Frontend events use compression

### Internal User Filtering

If your events are filtered:
- Check `POSTHOG_INTERNAL_DOMAINS` for your email domain
- Check `POSTHOG_INTERNAL_USER_IDS` for your user ID
- Modify `.env` to exclude your domain/user if needed for testing

---

## References

- **Backend Implementation:** `sceneXtras/api/helper/posthog_helper.py`
- **Backend Telemetry:** `sceneXtras/api/helper/posthog_telemetry.py`
- **Frontend Integration:** `frontend_webapp/src/services/posthog.ts`
- **Mobile Integration:** `mobile_app_sx/services/posthog.ts`

---

## Historical Implementation Iterations

This document consolidates 22 previous iteration documents. Detailed implementation history is available in `/docs/archive/implementations/posthog/` if needed for reference.
