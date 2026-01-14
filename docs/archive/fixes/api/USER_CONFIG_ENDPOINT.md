# User Configuration Endpoint Documentation

## Overview

The `/users/config` endpoint manages user-specific configuration and notification preferences in the SceneXtras application.

## Endpoint Details

### Base URL
```
PATCH /api/users/config
```

### Authentication
- **Required**: Yes
- **Method**: Bearer token in Authorization header
- **Token**: Supabase session access token

---

## Request Schema

### ConfigUpdate Model

The endpoint accepts a JSON payload with the following structure:

```typescript
interface ConfigUpdate {
  config: Record<string, any>;
  notifications?: NotificationsConfig; // Optional since 2025-10-15
}

interface NotificationsConfig {
  daily_notifications: boolean;
  movie_notifications: boolean;
  anime_notifications: boolean;
  series_notifications: boolean;
  actors_notifications: boolean;
}
```

### Backend Validation (Pydantic)

```python
class NotificationsConfig(BaseModel):
    daily_notifications: bool = False
    movie_notifications: bool = False
    anime_notifications: bool = False
    series_notifications: bool = False
    actors_notifications: bool = False

class ConfigUpdate(BaseModel):
    config: Dict[str, Any]
    notifications: Optional[NotificationsConfig] = None  # Optional since 2025-10-15
```

**Note**: As of 2025-10-15, the `notifications` field is optional. If not provided, existing notifications are preserved. If no notifications exist, defaults (all `false`) are initialized.

---

## Request Examples

### Minimal Valid Request (Config Only - No Notifications)
```json
{
  "config": {
    "is_onboarded": true
  }
}
```
**Note**: Notifications are optional. Existing notifications will be preserved, or defaults will be used if none exist.

### With Notifications
```json
{
  "config": {
    "is_onboarded": true
  },
  "notifications": {
    "daily_notifications": false,
    "movie_notifications": false,
    "anime_notifications": false,
    "series_notifications": false,
    "actors_notifications": false
  }
}
```

### Complete Configuration Update
```json
{
  "config": {
    "is_onboarded": true,
    "theme": "dark",
    "language": "en",
    "timezone": "America/New_York",
    "preferences": {
      "autoplay": true,
      "show_spoilers": false
    }
  },
  "notifications": {
    "daily_notifications": true,
    "movie_notifications": true,
    "anime_notifications": false,
    "series_notifications": true,
    "actors_notifications": false
  }
}
```

---

## Response Schema

### Success Response (200 OK)
```json
{
  "message": "User configuration updated successfully",
  "config": {
    "is_onboarded": true,
    "theme": "dark",
    "notifications": {
      "daily_notifications": true,
      "movie_notifications": true,
      "anime_notifications": false,
      "series_notifications": true,
      "actors_notifications": false
    }
  }
}
```

### Error Responses

#### 401 Unauthorized
```json
{
  "detail": "UNAUTHORIZED"
}
```

#### 422 Unprocessable Entity (Missing Required Fields)
```json
{
  "detail": [
    {
      "type": "missing",
      "loc": ["body", "notifications"],
      "msg": "Field required",
      "input": {
        "config": {
          "is_onboarded": true
        }
      }
    }
  ]
}
```

#### 500 Internal Server Error
```json
{
  "detail": "Failed to update configuration"
}
```

---

## Backend Implementation

### File Location
`sceneXtras/api/router/user_router.py`

### Key Features

1. **Configuration Merging**: The endpoint merges new config with existing config rather than replacing it
2. **Notifications Handling**: Notifications are stored within the config object under the `notifications` key
3. **Database Storage**: Configuration is stored in the `user_configurations` table in Supabase
4. **Cache Invalidation**: Automatically invalidates relevant caches after update:
   - User cache (via `resilient_supabase`)
   - User details cache (Redis)

### Implementation Logic

```python
@user_router.patch("/users/config")
async def update_user_config(
    request: Request,
    config_update: ConfigUpdate,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    supabase_client: Client = Depends(get_supabase_client),
):
    # 1. Fetch existing configuration
    result = supabase_client.table("user_configurations")
        .select("*")
        .eq("user_id", current_user.id)
        .execute()
    
    # 2. Merge with new configuration
    current_config = result.data[0]["config"] if result.data else {}
    current_config.update(config_update.config)
    
    # 3. Handle notifications (optional field)
    if config_update.notifications is not None:
        current_config["notifications"] = config_update.notifications.dict()
    elif "notifications" not in current_config:
        # Initialize with defaults if no notifications exist
        current_config["notifications"] = NotificationsConfig().dict()
    
    # 4. Update or insert configuration
    if row_id:
        # Update existing
        supabase_client.table("user_configurations")
            .update({"config": current_config})
            .eq("id", row_id)
            .execute()
    else:
        # Insert new
        supabase_client.table("user_configurations")
            .insert({"user_id": current_user.id, "config": current_config})
            .execute()
    
    # 5. Invalidate caches
    resilient_supabase.invalidate_user_cache(email=current_user.email)
    cache.delete(f"userdetails:{current_user.id}")
    
    return {
        "message": "User configuration updated successfully",
        "config": current_config
    }
```

---

## Frontend Integration

### File Location
`frontend_webapp/src/api/authClient.ts`

### Function Signature
```typescript
export const updateUserConfig = async (
  session: Session | null,
  configUpdate: ConfigUpdate,
): Promise<{
  message: string;
  config: Record<string, any>;
}>
```

### Usage Example (OnboardingForm)
```typescript
import { updateUserConfig } from '../../api/authClient';

// During onboarding completion - with full notifications
const configUpdateResponse = await updateUserConfig(session, {
  config: { is_onboarded: true },
  notifications: {
    daily_notifications: formData.notifications.daily_notifications,
    movie_notifications: false,
    anime_notifications: false,
    series_notifications: false,
    actors_notifications: false,
  },
});

// Or minimal version - notifications optional (since 2025-10-15)
const configUpdateResponse = await updateUserConfig(session, {
  config: { is_onboarded: true },
});
```

---

## Common Issues and Solutions

### Issue: 422 Error - "Field required: notifications"

**Symptom**: 
```
Error: Failed to update user config: {"detail":[{"type":"missing","loc":["body","notifications"],"msg":"Field required",...}]}
```

**Cause**: The `notifications` field is missing or incomplete in the request body.

**Solution**: Always include all notification fields with boolean values:
```typescript
notifications: {
  daily_notifications: false,  // or true
  movie_notifications: false,
  anime_notifications: false,
  series_notifications: false,
  actors_notifications: false,
}
```

### Issue: Cache Stale Data

**Symptom**: Configuration updates don't reflect immediately in the UI.

**Solution**: The endpoint automatically invalidates caches. Ensure your frontend refetches data after update:
```typescript
// Update cache after successful config update
queryClient.setQueryData(['userConfigFallback', userId], {
  config: configUpdateResponse.config,
});
```

---

## Database Schema

### Table: `user_configurations`
```sql
CREATE TABLE user_configurations (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast user lookup
CREATE INDEX idx_user_configurations_user_id ON user_configurations(user_id);
```

### Config JSON Structure
```json
{
  "is_onboarded": true,
  "theme": "dark",
  "language": "en",
  "timezone": "UTC",
  "preferences": {},
  "notifications": {
    "daily_notifications": true,
    "movie_notifications": false,
    "anime_notifications": false,
    "series_notifications": false,
    "actors_notifications": false
  }
}
```

---

## Related Endpoints

### GET /users/config
Retrieves the current user's configuration.

**Response**:
```json
{
  "config": {
    "is_onboarded": true,
    "notifications": { ... }
  }
}
```

### POST /users/onboarding
Alternative endpoint specifically for updating onboarding status (simplified).

---

## Testing

### cURL Example
```bash
curl -X PATCH "http://localhost:8080/api/users/config" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "config": {
      "is_onboarded": true
    },
    "notifications": {
      "daily_notifications": false,
      "movie_notifications": false,
      "anime_notifications": false,
      "series_notifications": false,
      "actors_notifications": false
    }
  }'
```

### Python Test Example
```python
import requests

token = "YOUR_ACCESS_TOKEN"
url = "http://localhost:8080/api/users/config"

payload = {
    "config": {"is_onboarded": True},
    "notifications": {
        "daily_notifications": False,
        "movie_notifications": False,
        "anime_notifications": False,
        "series_notifications": False,
        "actors_notifications": False,
    }
}

response = requests.patch(
    url,
    json=payload,
    headers={"Authorization": f"Bearer {token}"}
)

print(response.status_code)
print(response.json())
```

---

## Changelog

### 2025-10-15 (Update 2 - Backend Flexibility)
- **Changed**: Made `notifications` field **optional** in backend `ConfigUpdate` model
- **Backend**: Now preserves existing notifications if not provided in request
- **Backend**: Initializes with defaults if no notifications exist and none provided
- **Mobile App**: Fixed mobile app onboarding to include all notification fields
- **Mobile App**: Updated `api-client.ts` to match backend schema with all fields
- **Both Apps**: Fixed `useUserQueries.ts` to send complete notification config
- **Documentation**: Updated to reflect optional notifications behavior

### 2025-10-15 (Update 1 - Frontend Fixes)
- **Fixed**: Frontend `NotificationsConfig` interface now includes all required fields
- **Fixed**: OnboardingForm now sends all notification fields with default values
- **Documentation**: Created comprehensive endpoint documentation

### Previous
- Initial implementation of user configuration endpoint
- Added cache invalidation on configuration updates

---

## Additional Notes

1. **Field Defaults**: All notification fields default to `false` in the backend Pydantic model
2. **Notifications Optional** (Since 2025-10-15): The `notifications` field is now optional in requests
   - If provided: Updates notifications with the provided values
   - If not provided: Preserves existing notifications
   - If not provided and none exist: Initializes with all fields set to `false`
3. **Configuration Persistence**: Configurations are stored per-user and persist across sessions
4. **Partial Updates**: The endpoint supports partial config updates - only specified fields are modified
5. **Notifications Scope**: When provided, the notifications object is fully replaced (not merged)
6. **Cache Strategy**: Multi-layer cache invalidation ensures consistency across the application
7. **Mobile & Web Apps**: Both apps now properly handle all notification fields
