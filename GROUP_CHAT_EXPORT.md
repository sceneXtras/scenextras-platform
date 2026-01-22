# Group Chat Export Feature

## Overview

The Group Chat Export feature allows users to create AI-generated conversations between multiple fictional characters (up to 3). Users search and select characters via autocomplete, then trigger a group chat export that generates a multi-character dialogue.

## User Flow

1. User navigates to Profile/Admin page
2. User taps "Group Chat Export" button (feature-flagged)
3. Modal opens with autocomplete search
4. User searches and selects up to 3 characters
5. User taps "Export Group Chat"
6. System generates group conversation between selected characters
7. User is routed to viewer page to see the result

## Feature Flags

| Platform | Flag Name | Location |
|----------|-----------|----------|
| Mobile | `feature_group_chat_export` | PostHog / `useFeatureFlag` hook |
| Backend | `feature_group_chat_export` | PostHog via `is_feature_enabled()` |

**Note:** Both frontend AND backend flags must be enabled for the feature to work.

## API Endpoint

### POST `/api/talk_with_export_group`

Generates a group chat conversation between multiple characters.

**Request Body:**
```json
{
  "modal_content": "string (topic/prompt for the conversation)",
  "group_chat": true,
  "group_characters": ["Character 1", "Character 2", "Character 3"]
}
```

**Request Headers:**
```
Authorization: Bearer <supabase_access_token>
Content-Type: application/json
ngrok-skip-browser-warning: True
```

**Response (Success):**
```json
{
  "ok": true,
  "status": 200,
  "isGroupChat": true,
  "characters": [
    {
      "name": "Harry Potter",
      "actor": "Harry Potter",
      "avatar": "https://..."
    },
    {
      "name": "Iron Man",
      "actor": "Marvel Cinematic Universe",
      "avatar": "https://..."
    }
  ],
  "conversation": "...",
  "exportId": "uuid"
}
```

**Response (Fallback to Single):**
If feature flag is disabled or `group_chat: false`, falls back to single character export via `talk_with_export`.

## Frontend Components

### GroupChatModal (`/components/GroupChatModal.tsx`)

Modal component for character selection.

**Props:**
```typescript
interface GroupChatModalProps {
  visible: boolean;
  onClose: () => void;
  onExport: (characters: Character[]) => void;
}
```

**Key Features:**
- Autocomplete search using `autocompleteApi.getAutocompleteSuggestions()`
- Character chips with avatars (processed via `processCastProfilePath()`)
- Maximum 3 character selection
- Loading states during search and export

### Profile Page Integration (`/app/(drawer)/(tabs)/profile.tsx`)

- Feature flag check controls button visibility
- Opens `GroupChatModal` on button tap
- Calls `exportService.exportGroupChat()` on export

## Service Layer

### exportService (`/services/exportService.ts`)

**Function:** `exportGroupChat(characters: Character[], topic?: string)`

```typescript
export async function exportGroupChat(
  characters: Character[],
  topic?: string
): Promise<ExportGroupChatResponse> {
  const session = await getCurrentSession();
  const headers = await getAuthHeaders(session);

  const response = await fetch(`${API_BASE_URL}/api/talk_with_export_group`, {
    method: 'POST',
    headers: {
      ...headers,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      modal_content: topic || 'General conversation',
      group_chat: true,
      group_characters: characters.map(c => c.name),
    }),
  });

  return response.json();
}
```

## Character Data Processing

Characters from autocomplete are converted using `convertToCharacter()`:

```typescript
const convertToCharacter = (suggestion: AutocompleteSuggestion): Character => {
  const metadata = suggestion.metadata || {};
  const rawImagePath = metadata.character_image
    || metadata.actor_profile
    || metadata.imageUrl
    || metadata.profile_path
    || metadata.poster_path;

  const avatarUrl = rawImagePath ? processCastProfilePath(rawImagePath) : '';
  const fromSource = metadata.parent_title || metadata.movie || metadata.series || 'Unknown';

  return {
    id: metadata.id || suggestion.text.toLowerCase().replace(/\s+/g, '-'),
    name: metadata.character_name || suggestion.text,
    actor: fromSource,
    description: metadata.description || '',
    avatar: avatarUrl,
    isOnline: false,
    from: fromSource,
  };
};
```

## Image Processing

Character avatars support multiple sources:
- TVDB images
- TMDB profile/poster paths
- Custom cover images
- AI-generated images

All processed via `processCastProfilePath()` from `@/helper/image-processing`.

## Authentication

The endpoint requires valid Supabase authentication:

1. `getCurrentSession()` fetches fresh session from Supabase SDK
2. `getAuthHeaders()` prioritizes the passed session's `access_token`
3. Token is sent as `Authorization: Bearer <token>`

**Priority Order:**
1. Passed session's `access_token` (most reliable)
2. `authStore.getFreshToken()` (fallback)
3. Legacy storage token (last resort)

## Backend Implementation

Located in `/sceneXtras/api/router/gpt_chat_router.py`

**Key Steps:**
1. Validate feature flag (PostHog)
2. Validate `group_characters` array (max 3)
3. Search for each character in database
4. Generate multi-character conversation using LLM
5. Return structured response with all characters and conversation

## Testing Checklist

- [ ] Feature flag enabled on PostHog (both mobile & backend)
- [ ] Autocomplete search returns results
- [ ] Character images display correctly
- [ ] Can select up to 3 characters
- [ ] Cannot select more than 3 characters
- [ ] Export button triggers API call
- [ ] API returns group chat (not single fallback)
- [ ] Viewer page displays multi-character conversation
- [ ] Error states handled (network, auth, no results)

## Known Issues / TODOs

1. **Backend flag currently force-enabled** - Line 4086 in `gpt_chat_router.py` has `feature_enabled = True` for testing. Revert to PostHog check after testing.

2. **PostHog flag setup** - Enable `feature_group_chat_export` in PostHog dashboard for production rollout.

## File References

| File | Purpose |
|------|---------|
| `mobile_app_sx/components/GroupChatModal.tsx` | Character selection modal |
| `mobile_app_sx/services/exportService.ts` | API service layer |
| `mobile_app_sx/app/(drawer)/(tabs)/profile.tsx` | Feature entry point |
| `sceneXtras/api/router/gpt_chat_router.py:4050` | Backend endpoint |
| `mobile_app_sx/helper/image-processing.ts` | Avatar URL processing |
