# Sentry Implementation Testing Guide

## Date: 2025-01-XX

## Overview

This guide helps you verify that all Sentry enhancements are working correctly after deploying to your test branch.

## 🧪 Testing Checklist

### 1. Frontend Web App - Sentry Tracking

#### Test User Context
1. **Login to the web app** (test environment)
2. **Open browser DevTools** → Console
3. **Check Sentry initialization**:
   ```javascript
   // In browser console, check if Sentry is initialized
   window.Sentry && console.log('Sentry initialized:', window.Sentry.getCurrentHub().getClient())
   ```
4. **Verify user context**:
   - Login with a test account
   - Check Sentry dashboard → Issues → Should show user email/ID
   - User context should include: `is_premium`, `remaining_quota`, `streak`, `created_at`

#### Test Breadcrumbs
1. **Perform actions**:
   - Make API calls (e.g., send a chat message)
   - Navigate between pages
   - Trigger errors
2. **Check Sentry dashboard**:
   - Go to an error → Breadcrumbs section
   - Should see: API requests, responses, navigation events, auth events

#### Test Performance Tracking
1. **Send a chat message**:
   - Open chat interface
   - Send a message
   - Wait for response
2. **Check Sentry Performance**:
   - Sentry dashboard → Performance
   - Filter by transaction: "Chat Message Send"
   - Should see duration, status, and operation details

#### Test Error Tracking
1. **Trigger a test error**:
   ```javascript
   // In browser console
   Sentry.captureException(new Error('Test error from frontend'))
   ```
2. **Check Sentry dashboard**:
   - Error should appear with full context
   - Should include breadcrumbs leading to error
   - Should have user context attached

### 2. Backend API - Sentry Tracking

#### Test Error Context Enhancement
1. **Trigger a database error** (optional - temporary):
   ```bash
   # Temporarily break database connection or use test endpoint
   curl http://localhost:8080/test-error-logging
   # (requires admin auth)
   ```
2. **Check Sentry dashboard**:
   - Error should show:
     - Source code context (filename, function, line number)
     - Local variables (sanitized)
     - Request context (path, method, user_id)
     - Error group tag (`error_group: database_error`)

#### Test Performance Transactions
1. **Make API requests**:
   ```bash
   curl http://localhost:8080/api/some-endpoint
   ```
2. **Check Sentry Performance**:
   - Sentry dashboard → Performance
   - Filter by transaction: "GET /api/..."
   - Should see:
     - Duration
     - Status code
     - Request duration in transaction data

#### Test Error Grouping
1. **Trigger different error types**:
   - HTTP errors (4xx, 5xx)
   - Database errors
   - Validation errors
2. **Check Sentry dashboard**:
   - Errors should be grouped by type
   - Error titles should be descriptive ("Database Error: ...", "HTTP Error: ...")
   - Error fingerprints should group similar errors

#### Test Database Error Context
1. **Trigger database error**:
   ```bash
   # If you have database access, temporarily break connection
   # Or use existing endpoints that might fail
   ```
2. **Check Sentry dashboard**:
   - Error should include:
     - Database context (host, database, pool stats)
     - Error fingerprint: `["database-error", "connection"]`
     - Error group tag: `database_error`

### 3. Go Search Engine - Sentry Tracking

#### Test Sentry Initialization
1. **Start the Go service**:
   ```bash
   cd golang_search_engine
   make run
   ```
2. **Check logs**:
   - Should see: "Sentry initialized - Environment: ..."
   - Or: "Sentry disabled or DSN not configured"

#### Test Error Tracking
1. **Trigger an error**:
   ```bash
   # Make invalid request
   curl http://localhost:8080/api/search?q=
   # Or trigger internal error
   ```
2. **Check Sentry dashboard**:
   - Error should appear
   - Should have service tag: `service: autocomplete`
   - Should include request context

#### Test Performance Tracking
1. **Make search requests**:
   ```bash
   curl http://localhost:8080/api/search?q=batman
   ```
2. **Check Sentry Performance**:
   - Sentry dashboard → Performance
   - Should see transactions for search requests
   - Should include duration and status

### 4. Sourcemap Uploads - GitHub Actions

#### Check Workflow Run
1. **Go to GitHub** → Actions tab
2. **Find workflow run** for your test branch
3. **Check workflow steps**:
   - ✅ Build with Sourcemaps
   - ✅ Verify Sentry Release
   - ✅ PostHog Sourcemap Processing
   - ✅ Notify Build Status

#### Verify Sentry Sourcemaps
1. **In Sentry dashboard**:
   - Go to Settings → Projects → Your Project
   - Go to Releases → Find release: `sceneXtras@{commit-sha}`
   - Check if sourcemaps are listed
   - Click on an error → Should show original source code (not minified)

#### Verify PostHog Sourcemaps
1. **In PostHog dashboard**:
   - Go to Settings → Project Settings
   - Check sourcemaps section
   - Should see uploaded sourcemaps for version

### 5. Mobile App - Sentry Tracking

#### Test User Context
1. **Login to mobile app** (test environment)
2. **Check Sentry dashboard**:
   - Errors should include user context
   - User ID and email should be attached

#### Test Performance Tracking
1. **Perform actions**:
   - Navigate between screens
   - Make API calls
   - Send chat messages
2. **Check Sentry Performance**:
   - Should see performance transactions
   - Should include trace propagation to backend

## 🔍 Quick Verification Commands

### Backend API
```bash
# Test error logging (requires admin auth)
curl -u admin:password http://localhost:8080/test-error-logging

# Check Sentry is initialized in logs
grep -i "sentry" logs/app.log | tail -20

# Test API endpoint
curl http://localhost:8080/api/ping
```

### Frontend Web
```bash
# Build and check for Sentry integration
cd frontend_webapp
yarn build
grep -r "Sentry" build/static/js/*.js | head -5

# Check Sentry initialization in source
grep -A 10 "Sentry.init" src/index.tsx
```

### Go Search Engine
```bash
# Check Sentry initialization
cd golang_search_engine
grep -i "sentry" cmd/server/main.go | head -10

# Test service
curl http://localhost:8080/health
```

## 📊 Sentry Dashboard Verification

### 1. Check Environment
- Go to Sentry → Settings → Projects
- Verify environment matches your test branch (e.g., "development", "staging")

### 2. Check Releases
- Go to Releases
- Should see release: `sceneXtras@{commit-sha}`
- Click on release → Should show sourcemaps uploaded

### 3. Check Errors
- Go to Issues
- Trigger some test errors
- Check if errors have:
  - ✅ Enhanced context (source code, local variables)
  - ✅ User context (email, ID, business data)
  - ✅ Request context (path, method, duration)
  - ✅ Error grouping tags

### 4. Check Performance
- Go to Performance
- Should see transactions for:
  - HTTP requests (backend)
  - Chat message sends (frontend)
  - Search requests (Go service)

### 5. Check Breadcrumbs
- Click on any error
- Scroll to Breadcrumbs section
- Should see:
  - API requests/responses
  - Navigation events
  - Authentication events
  - Request lifecycle events

## 🐛 Common Issues & Solutions

### Issue: Sourcemaps not showing in Sentry
**Solution:**
- Check GitHub Actions workflow logs
- Verify `SENTRY_AUTH_TOKEN` secret is set
- Check if sourcemaps were uploaded in release files
- Verify release version matches runtime version

### Issue: No errors appearing in Sentry
**Solution:**
- Check `SENTRY_DSN` environment variable is set
- Check Sentry initialization logs
- Verify environment matches Sentry project settings
- Check if errors are being filtered out

### Issue: Performance transactions not showing
**Solution:**
- Check `tracesSampleRate` is > 0
- Verify transactions are being created in code
- Check Sentry Performance tab (not just Issues)

### Issue: User context missing
**Solution:**
- Check if user is authenticated
- Verify `setUser()` is called after login
- Check Sentry user context in browser console

## ✅ Expected Results

After completing all tests, you should see:

1. **Frontend:**
   - ✅ User context in errors (email, premium status, quota)
   - ✅ Breadcrumbs for API calls and navigation
   - ✅ Performance transactions for chat messages
   - ✅ Source code visible in error stack traces

2. **Backend:**
   - ✅ Source code context in errors
   - ✅ Local variables captured
   - ✅ Request context automatically added
   - ✅ Database error context
   - ✅ Performance transactions for HTTP requests

3. **Go Service:**
   - ✅ Errors tracked with service tag
   - ✅ Performance transactions for search requests
   - ✅ Trace propagation working

4. **Sourcemaps:**
   - ✅ Sourcemaps uploaded to Sentry via GitHub Actions
   - ✅ Sourcemaps uploaded to PostHog
   - ✅ Original source code visible in Sentry errors

## 📝 Testing Script

You can run this quick test script to verify Sentry is working:

```bash
#!/bin/bash
# test_sentry.sh

echo "Testing Sentry Implementation..."

# Test backend error
echo "1. Testing backend error..."
curl -u admin:password http://localhost:8080/test-error-logging 2>/dev/null || echo "Backend test skipped (no admin auth)"

# Test Go service
echo "2. Testing Go service..."
curl http://localhost:8080/health 2>/dev/null || echo "Go service not running"

# Test frontend (if running)
echo "3. Check frontend..."
curl http://localhost:3000 2>/dev/null && echo "Frontend is running" || echo "Frontend not running"

echo "✅ Tests complete. Check Sentry dashboard for results."
```

## 🎯 Success Criteria

✅ All services initialize Sentry correctly  
✅ Errors include enhanced context (source code, local variables)  
✅ User context is attached to errors  
✅ Performance transactions are tracked  
✅ Breadcrumbs are captured for debugging  
✅ Sourcemaps are uploaded and visible in Sentry  
✅ Error grouping works correctly  
✅ Slow requests are tagged  

If all of these are true, your Sentry implementation is complete and working! 🎉

