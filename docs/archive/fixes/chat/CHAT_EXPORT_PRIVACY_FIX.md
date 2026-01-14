# Chat Export Privacy Endpoint Fix

## Problem

**Error**: 405 Method Not Allowed when trying to PATCH `/api/chat-exports/{export_id}/privacy`

```
Request URL: https://test.backend.scenextras.com/api/chat-exports/83600156-3b7f-4b90-b6d4-7886be3fedde/privacy
Request Method: PATCH
Status Code: 405 Method Not Allowed
Response: {"detail":"Method Not Allowed"}
```

## Root Cause

**Route Order Conflict in FastAPI**

The privacy PATCH endpoint was defined **after** a more generic POST endpoint:

```python
# Line 819 - Defined FIRST (catches all paths matching this pattern)
@chat_exports_router.post("/chat-exports/{export_id}/{interaction_type}")
async def update_export_interaction(...)

# Line 976 - Defined SECOND (never reached for /privacy path)
@chat_exports_router.patch("/chat-exports/{export_id}/privacy")
async def update_export_privacy(...)
```

### Why This Caused the Error

1. When a PATCH request comes to `/chat-exports/{export_id}/privacy`
2. FastAPI matches it against routes in definition order
3. The POST route `/chat-exports/{export_id}/{interaction_type}` matches the path pattern
   - `export_id` = the UUID
   - `interaction_type` = "privacy"
4. FastAPI finds a matching route but **wrong HTTP method** (POST vs PATCH)
5. Returns **405 Method Not Allowed** instead of checking the next route

### FastAPI Route Matching Rules

In FastAPI, **route order matters**:
- Routes are matched in the order they are defined
- More specific routes should come **before** more generic routes
- Path parameters (`{variable}`) create generic patterns that can match multiple paths

## Solution

**Move the specific `/privacy` endpoint BEFORE the generic `/{interaction_type}` endpoint**

### Changes Made

**File**: `sceneXtras/api/router/chat_export_router.py`

```python
# ✅ CORRECT ORDER - Specific route first

# Line 747-751 - Specific privacy endpoint (MOVED UP)
class UpdatePrivacyRequest(BaseModel):
    is_public: bool

@chat_exports_router.patch("/chat-exports/{export_id}/privacy")
async def update_export_privacy(...)

# Line 819 - Generic interaction endpoint (STAYS AFTER)
@chat_exports_router.post("/chat-exports/{export_id}/{interaction_type}")
async def update_export_interaction(...)
```

### What Was Changed

1. **Moved** `UpdatePrivacyRequest` class from line ~972 to line 747
2. **Moved** `update_export_privacy` function from line ~976 to line 751
3. **Removed** duplicate definitions that were after the interaction endpoint
4. **Result**: Privacy endpoint now defined at line 751, **before** interaction endpoint at line 819

## Verification

### Before Fix
```bash
curl -X PATCH "https://test.backend.scenextras.com/api/chat-exports/{export_id}/privacy" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_public": false}'

# Response: 405 Method Not Allowed ❌
```

### After Fix
```bash
curl -X PATCH "https://test.backend.scenextras.com/api/chat-exports/{export_id}/privacy" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_public": false}'

# Response: 200 OK ✅
{
  "success": true,
  "export_id": "83600156-3b7f-4b90-b6d4-7886be3fedde",
  "is_public": false
}
```

## Route Order in File (After Fix)

```python
Line 674: GET    /chat-exports/{export_id}                      # Get single export
Line 751: PATCH  /chat-exports/{export_id}/privacy              # Update privacy (SPECIFIC)
Line 819: POST   /chat-exports/{export_id}/{interaction_type}   # Update interactions (GENERIC)
Line 909: DELETE /chat-exports/{export_id}                      # Delete export
```

## API Endpoint Details

### Update Chat Export Privacy

**Endpoint**: `PATCH /api/chat-exports/{export_id}/privacy`

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "is_public": boolean
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "export_id": "uuid-string",
  "is_public": boolean
}
```

**Errors**:
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - User doesn't own this export
- `404 Not Found` - Export doesn't exist
- `500 Internal Server Error` - Failed to update

### Update Chat Export Interactions

**Endpoint**: `POST /api/chat-exports/{export_id}/{interaction_type}`

**Interaction Types**: `view`, `like`, `share`

**Example**:
```bash
POST /api/chat-exports/{export_id}/view
POST /api/chat-exports/{export_id}/like
POST /api/chat-exports/{export_id}/share
```

## Best Practices for FastAPI Routes

1. **Define specific routes before generic routes**
   ```python
   # ✅ Correct
   @router.get("/items/search")      # Specific
   @router.get("/items/{item_id}")   # Generic
   
   # ❌ Wrong
   @router.get("/items/{item_id}")   # Generic catches /items/search
   @router.get("/items/search")      # Never reached
   ```

2. **Use route parameters wisely**
   - Path parameters create generic patterns
   - Static paths are more specific
   - Order matters when mixing both

3. **Test route ordering**
   - Check FastAPI's automatic docs at `/docs`
   - Verify all routes are reachable
   - Test with actual HTTP requests

## Related Issues

This pattern could affect other routes in the application. Consider reviewing:
- Any routes with `/{param1}/{param2}` patterns
- Routes where specific paths share prefixes with generic paths
- Ensure specific routes are always defined first

## Files Modified

- ✅ `sceneXtras/api/router/chat_export_router.py`
  - Moved privacy endpoint before interaction endpoint
  - Removed duplicate definitions
  - Fixed route ordering issue

## Testing

After deploying, verify:
1. PATCH requests to `/api/chat-exports/{export_id}/privacy` return 200 OK
2. POST requests to `/api/chat-exports/{export_id}/view` still work
3. POST requests to `/api/chat-exports/{export_id}/like` still work
4. POST requests to `/api/chat-exports/{export_id}/share` still work
5. No other routes are affected

---

## Summary

**Problem**: 405 Method Not Allowed for PATCH `/chat-exports/{export_id}/privacy`  
**Cause**: Route defined after generic `/{interaction_type}` route  
**Fix**: Moved specific `/privacy` route before generic route  
**Result**: Privacy updates now work correctly ✅
