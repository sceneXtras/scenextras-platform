# Sentry Session Tracking Implementation

## Overview

This document describes the end-to-end Sentry session tracking implementation across all SceneXtras services. Sessions are tracked from frontend (web/mobile) through backend API calls, allowing you to trace user actions across the entire application stack.

## Architecture

### Components

1. **Frontend Web App** (`frontend_webapp/`) - React SPA with Sentry React SDK
2. **Mobile App** (`mobile_app_sx/`) - React Native app with Sentry React Native SDK  
3. **Backend API** (`sceneXtras/api/`) - FastAPI service with Sentry Python SDK

### Session Flow

```
User Action (Frontend)
    ↓
[Sentry Trace Headers] (sentry-trace, baggage)
    ↓
HTTP Request → Backend API
    ↓
[Backend extracts trace headers]
    ↓
[Backend sets user context]
    ↓
[Backend processes request]
    ↓
[All errors/exceptions linked to same trace]
```

## Implementation Details

### Frontend Web App

**Location:** `frontend_webapp/src/index.tsx`

**Configuration:**
- Sentry initialized lazily after first paint
- Browser tracing enabled with `tracesSampleRate: 0.2` (production)
- Trace propagation enabled to backend API via `tracePropagationTargets`
- Session replay enabled for error sessions (`replaysOnErrorSampleRate: 1.0`)

**User Context:**
- Set in `frontend_webapp/src/stores/useAuthStore.ts`
- Called when user logs in: `Sentry.setUser({ id, email, username })`
- Cleared on logout: `Sentry.setUser(null)`

**Trace Propagation:**
- Automatically adds `sentry-trace` and `baggage` headers to API requests
- Targets configured: `localhost`, `scenextras.herokuapp.com/api`, and `API_URL`

### Mobile App

**Location:** `mobile_app_sx/app/_layout.tsx`

**Configuration:**
- Sentry initialized on native platforms only (not web)
- Tracing enabled: `tracesSampleRate: 0.1` (production) or `0.25` (dev/staging)
- Trace propagation enabled to backend API
- Platform-specific context added to all events

**User Context:**
- Set in `mobile_app_sx/store/authStore.ts` in `setSession()` method
- Called when session is set: `Sentry.setUser({ id, email, username })`
- Cleared on logout: `Sentry.setUser(null)`

**Trace Propagation:**
- Automatically adds `sentry-trace` and `baggage` headers to API requests
- Targets configured: `localhost`, `scenextras.herokuapp.com/api`, and `EXPO_PUBLIC_API_URL`

### Backend API

**Location:** `sceneXtras/api/main.py`

**Configuration:**
- Sentry initialized with FastAPI integration
- Auto-traces FastAPI routes via `FastApiIntegration()`
- Trace sampling rate varies by environment:
  - Production: 1% (`traces_sample_rate: 0.01`)
  - Staging: 10% (`traces_sample_rate: 0.1`)
  - Test: 50% (`traces_sample_rate: 0.5`)
  - Local: 25% (`traces_sample_rate: 0.25`)

**User Context:**
- Set in `identify_user_middleware` middleware
- Initial context set before request processing (anonymous user_id)
- Updated after authentication completes with actual user data:
  - User ID from authenticated user
  - User email from authenticated user
  - Tagged as `authenticated: true`

**Trace Propagation:**
- FastAPI integration automatically extracts trace headers from incoming requests
- Links backend traces to frontend traces via trace headers
- User context is set after authentication, linking errors to specific users

## User Context Flow

### Frontend → Backend

1. **Frontend (Web/Mobile):**
   ```typescript
   // When user logs in
   Sentry.setUser({
     id: user.id,
     email: user.email,
     username: user.name
   });
   ```

2. **API Request:**
   - Sentry automatically adds `sentry-trace` and `baggage` headers
   - Headers contain trace ID, span ID, and sampling decision

3. **Backend Middleware:**
   ```python
   # Initial context (before auth)
   sentry_sdk.configure_scope().set_user({"id": user_id})
   
   # After authentication
   if user_email and authenticated_user_id:
       sentry_sdk.configure_scope().set_user({
           "id": authenticated_user_id,
           "email": user_email
       })
   ```

## Verification

### Check Trace Propagation

1. **Frontend Request:**
   - Open browser DevTools → Network tab
   - Make an API request
   - Check request headers for:
     - `sentry-trace`: Should contain trace ID
     - `baggage`: Should contain Sentry metadata

2. **Backend Logs:**
   - Check Sentry dashboard for traces
   - Verify trace spans link frontend → backend
   - Verify user context is set correctly

### Check User Context

1. **Frontend:**
   - Open browser console
   - Run: `Sentry.getCurrentHub().getScope()._user`
   - Should show user object when logged in

2. **Backend:**
   - Check Sentry events in dashboard
   - User context should appear in event details
   - Should show user ID and email for authenticated requests

## Environment Variables

### Frontend Web
- `REACT_APP_SENTRY_DSN` - Sentry DSN (required for production)

### Mobile App
- `EXPO_PUBLIC_SENTRY_DSN` - Sentry DSN (required for native platforms)

### Backend API
- `SENTRY_DSN` - Sentry DSN (required for production)
- Sentry configuration via `environment_config.py`:
  - Automatically disabled in development/test if DSN not set
  - Sampling rates configured per environment

## Troubleshooting

### Traces Not Linking

**Symptoms:** Frontend and backend traces appear separately in Sentry

**Solutions:**
1. Verify `tracePropagationTargets` includes your API URL
2. Check that API requests are going to configured targets
3. Verify backend FastAPI integration is enabled
4. Check network tab for `sentry-trace` header presence

### User Context Not Set

**Symptoms:** Sentry events show anonymous users

**Solutions:**
1. Verify `setUser()` is called after login
2. Check auth store/user store for correct user data
3. Verify backend middleware runs after authentication
4. Check Sentry scope configuration

### Mobile App Not Tracking

**Symptoms:** No Sentry events from mobile app

**Solutions:**
1. Verify Sentry is initialized (only on native platforms, not web)
2. Check `EXPO_PUBLIC_SENTRY_DSN` is set
3. Verify tracing is enabled (`tracesSampleRate > 0`)
4. Check environment configuration

## Best Practices

1. **Always set user context after authentication**
   - Frontend: Set in auth store when user logs in
   - Backend: Set in middleware after authentication completes

2. **Use trace propagation for API calls**
   - Configure `tracePropagationTargets` to include API URLs
   - FastAPI integration handles extraction automatically

3. **Sample appropriately**
   - Production: Lower sampling rates (1-10%)
   - Development: Higher sampling rates (25-50%)
   - Error sessions: Always capture (100%)

4. **Clear user context on logout**
   - Prevents associating new sessions with previous user
   - Helps with privacy compliance

## Related Files

- `frontend_webapp/src/index.tsx` - Sentry initialization
- `frontend_webapp/src/stores/useAuthStore.ts` - User context management
- `mobile_app_sx/app/_layout.tsx` - Sentry initialization
- `mobile_app_sx/store/authStore.ts` - User context management
- `sceneXtras/api/main.py` - Backend Sentry configuration and middleware
- `sceneXtras/api/helper/environment_config.py` - Environment-specific Sentry config

