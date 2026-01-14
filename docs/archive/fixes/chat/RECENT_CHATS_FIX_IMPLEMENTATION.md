# Recent Chats Duplicate Fix - Implementation Complete

## Changes Made

### 1. Fixed Character ID Generation at Origin
**File:** `mobile_app_sx/app/chat/[movie]/[character].tsx`

Changed from:
```typescript
const id = characterContext?.id || params.character;
```

To:
```typescript
// Generate composite chat ID from character and movie slugs: "{character-slug}:{movie-slug}"
const characterSlug = params.character; // e.g., "bruce-wayne"
const movieSlug = params.movie; // e.g., "the-dark-knight"
const id = `${characterSlug}:${movieSlug}`; // e.g., "bruce-wayne:the-dark-knight"

// Keep numeric ID from context for legacy compatibility if needed
const numericCharacterId = characterContext?.id;
```

### 2. Updated All saveRecentChat Calls
**File:** `mobile_app_sx/app/chat/[movie]/[character].tsx` (3 locations)

Added new fields to all `saveRecentChat()` calls:
```typescript
saveRecentChat({
  characterId: id, // Now: "bruce-wayne:the-dark-knight"
  characterName: character.name,
  actorName: character.actor,
  movieName: character.from || movieData?.title || 'Unknown',
  characterSlug: characterSlug, // NEW: "bruce-wayne"
  movieSlug: movieSlug, // NEW: "the-dark-knight"
  numericId: numericCharacterId, // NEW: "3894" (if available)
  avatar: character.avatar,
  isGroup: false,
  poster: resolvedPoster || movieData?.poster || character.poster,
});
```

### 3. Updated RecentChat Interface
**Files:** 
- `mobile_app_sx/store/messageStore.ts`
- `mobile_app_sx/services/recentChatsService.ts`

```typescript
interface RecentChat {
  characterId: string; // NOW: Composite key "{character-slug}:{movie-slug}"
  characterName: string;
  actorName?: string;
  movieName: string;
  characterSlug?: string; // NEW: For navigation
  movieSlug?: string; // NEW: For navigation
  numericId?: string; // NEW: For legacy compatibility
  avatar?: string;
  poster?: string;
  lastMessageTime: Date;
  isGroup: boolean;
  // ... other fields
}
```

### 4. Updated Navigation Helpers
**File:** `mobile_app_sx/services/recentChatsService.ts`

Added composite key parsing:
```typescript
function parseChatKey(key: string): { character: string; movie: string } | null {
  const parts = key.split(':');
  if (parts.length !== 2) return null;
  return { character: parts[0], movie: parts[1] };
}
```

Updated `getChatNavigationPath()`:
```typescript
// Try to parse composite key first (new format)
const parsed = parseChatKey(chat.characterId);
if (parsed) {
  return `/chat/${parsed.movie}/${parsed.character}`;
}

// Fallback for backward compatibility
const movieSlug = chat.movieSlug || slugify(chat.from || '');
const characterSlug = chat.characterSlug || slugify(chat.name || '');
return `/chat/${movieSlug}/${characterSlug}`;
```

Updated `prepareNavigationContext()`:
```typescript
// For non-group chats, extract character slug from composite key
let characterIdForContext = chat.characterId;
if (!isGroup) {
  const parsed = parseChatKey(chat.characterId);
  characterIdForContext = parsed?.character || chat.characterSlug || chat.characterId;
}
```

## How It Works

### Before (Broken):
1. Navigate from cast screen → `characterId = "3894"` (numeric ID)
2. Save recent chat with `characterId: "3894"`
3. Navigate from drawer → `characterId = "bruce-wayne"` (slug from context)
4. Save recent chat with `characterId: "bruce-wayne"`
5. **Result:** Two separate entries for same character ❌

### After (Fixed):
1. Navigate from cast screen → `id = "bruce-wayne:the-dark-knight"` (composite)
2. Save recent chat with `characterId: "bruce-wayne:the-dark-knight"`
3. Navigate from drawer → Parse composite key → navigate to same chat
4. Save recent chat with `characterId: "bruce-wayne:the-dark-knight"`
5. **Result:** Single entry, updated timestamp ✅

## Key Benefits

1. **Unique Identification:** Each character-movie pair has exactly one entry
2. **No Duplicates:** Deduplication logic works correctly with consistent keys
3. **Backward Compatible:** Falls back to individual slug fields if composite key can't be parsed
4. **Session Token Compatibility:** Session tokens continue to work (they use normalized character+movie names)
5. **Group Chat Support:** Group chats use `groupId` as before, unaffected by changes

## Testing Scenarios

### ✅ Test 1: Cast Screen → Send Message
- Navigate to Bruce Wayne from "The Dark Knight" cast screen
- Send message
- Check recent chats: Should show 1 entry with `characterId: "bruce-wayne:the-dark-knight"`

### ✅ Test 2: Drawer → Send Message (Same Character)
- Open recent chats drawer
- Click on Bruce Wayne / The Dark Knight
- Send another message
- Check recent chats: Should still show 1 entry (updated timestamp)

### ✅ Test 3: Different Movie, Same Character Name
- Chat with Bruce Wayne from "The Dark Knight"
- Chat with Bruce Wayne from "Batman Begins"
- Check recent chats: Should show 2 separate entries:
  - `"bruce-wayne:the-dark-knight"`
  - `"bruce-wayne:batman-begins"`

### ✅ Test 4: Navigation from Recent Chats
- Click any character in recent chats
- Should navigate to correct chat URL: `/chat/{movie-slug}/{character-slug}`
- Context should be set properly for continuing conversation

### ✅ Test 5: Group Chats
- Create group chat with multiple characters
- Check recent chats: Group chat uses `groupId` as before
- Navigate from drawer → Group chat should work normally

## Migration Notes

### Existing Users
- Old entries with non-composite keys will still work
- New messages will create entries with composite keys
- Over time, old entries will naturally be replaced
- No data loss or breaking changes

### Clean Start Option
If you want to clear old entries:
```typescript
// In messageStore or app initialization
const cleanLegacyRecentChats = () => {
  // Clear all recent chats that don't have composite keys
  const chats = useMessageStore.getState().recentChats;
  const cleanChats = chats.filter(chat => 
    chat.characterId.includes(':') || chat.isGroup
  );
  useMessageStore.setState({ recentChats: cleanChats });
};
```

## Related Systems

### Session Tokens ✅ (No Changes Needed)
- Session tokens are managed separately in `conversationTokenManager.ts`
- Already properly scoped to `character+movie` pairs using normalized names
- Work independently of `characterId` changes

### Message Store ✅ (Works Automatically)
- Messages are filtered by `characterId` in `getMessagesByCharacter()`
- Will automatically use new composite keys
- No changes needed to message retrieval logic

## Files Modified

1. ✅ `mobile_app_sx/app/chat/[movie]/[character].tsx` - Origin of ID generation
2. ✅ `mobile_app_sx/store/messageStore.ts` - RecentChat interface
3. ✅ `mobile_app_sx/services/recentChatsService.ts` - Interfaces, navigation, parsing
4. ✅ `mobile_app_sx/app/cast/[movieId].tsx` - Already had slug fields for groups

## Verification

To verify the fix is working, check the logs:

**Before:**
```
INFO [MessageStore] Recent chat saved | {"characterId": "3894", ...}
INFO [MessageStore] Recent chat saved | {"characterId": "bruce-wayne", ...}
// Two different IDs = duplicate entries
```

**After:**
```
INFO [MessageStore] Recent chat saved | {"characterId": "bruce-wayne:the-dark-knight", ...}
INFO [MessageStore] Recent chat saved | {"characterId": "bruce-wayne:the-dark-knight", ...}
// Same ID = updated single entry
```

## Summary

The fix addresses the root cause by generating consistent composite keys at the origin of ID creation, rather than trying to patch the symptom downstream. This ensures that every character-movie pair has a unique, predictable identifier throughout the application lifecycle.
