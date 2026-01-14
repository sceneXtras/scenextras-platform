# Recent Chats Duplicate Entry Issue - Analysis & Fix

## Issue Summary

Multiple entries appear for the same character-movie pair in recent chats because the `characterId` key is inconsistent.

## Root Cause

### Current Implementation Problem

**The `characterId` should be a composite key:** `{character-slug}:{movie-slug}`

**But currently it uses:**
- Sometimes: `"3894"` (numeric TMDB character ID from cast navigation)
- Sometimes: `"bruce-wayne"` (character slug from params)
- Never includes the movie slug in the key

### Evidence from Logs

```
LOG  🔍 Chat debug: {"characterContextId": "3894", ...}  
// First entry - from cast screen navigation

LOG  🔍 Chat debug: {"characterContextId": "bruce-wayne", ...}
// Second entry - from drawer navigation
```

### Where the Issue Occurs

1. **Chat Component** (`app/chat/[movie]/[character].tsx` line 232):
   ```typescript
   const id = characterContext?.id || params.character;
   ```
   - Uses `characterContext.id` which can be numeric ID or slug
   - Doesn't include movie slug in the composite key

2. **saveRecentChat calls** (multiple locations in chat component):
   ```typescript
   saveRecentChat({
     characterId: id,  // ❌ Should be "bruce-wayne:the-dark-knight"
     characterName: character.name,
     movieName: character.from || movieData?.title || 'Unknown',
     // ...
   });
   ```

3. **Deduplication logic** (`store/messageStore.ts` lines 487-489):
   ```typescript
   const existingIndex = state.recentChats.findIndex(
     rc => rc.characterId === chat.characterId || 
          (chat.isGroup && rc.groupId === chat.groupId)
   );
   ```
   - Works correctly IF characterId is consistent
   - Fails when characterId changes between numeric and slug

## Solution

### Change 1: Create Composite Key Helper

Add a utility function to generate consistent composite keys:

```typescript
// In utils or helper file
export function createChatKey(characterSlug: string, movieSlug: string): string {
  return `${characterSlug}:${movieSlug}`;
}

export function parseChatKey(key: string): { character: string; movie: string } | null {
  const parts = key.split(':');
  if (parts.length !== 2) return null;
  return { character: parts[0], movie: parts[1] };
}
```

### Change 2: Update Chat Component

**Current:**
```typescript
const id = characterContext?.id || params.character;
```

**Should be:**
```typescript
// Generate composite key from slugs (always available from URL params)
const characterSlug = params.character; // "bruce-wayne"
const movieSlug = params.movie; // "the-dark-knight"
const chatId = createChatKey(characterSlug, movieSlug); // "bruce-wayne:the-dark-knight"

// Keep numeric ID separate for API calls if needed
const characterNumericId = characterContext?.id;
```

### Change 3: Update All saveRecentChat Calls

**Current:**
```typescript
saveRecentChat({
  characterId: id,
  characterName: character.name,
  movieName: character.from || movieData?.title || 'Unknown',
  // ...
});
```

**Should be:**
```typescript
saveRecentChat({
  characterId: chatId, // "bruce-wayne:the-dark-knight"
  characterName: character.name,
  movieName: character.from || movieData?.title || 'Unknown',
  characterSlug: characterSlug, // NEW: for navigation
  movieSlug: movieSlug, // NEW: for navigation
  numericId: characterNumericId, // NEW: for API calls if needed
  // ...
});
```

### Change 4: Update RecentChat Interface

```typescript
interface RecentChat {
  characterId: string; // NOW: "character-slug:movie-slug" composite key
  characterName: string;
  actorName?: string;
  movieName: string;
  characterSlug?: string; // NEW: for navigation
  movieSlug?: string; // NEW: for navigation
  numericId?: string; // NEW: for API calls if needed
  avatar?: string;
  poster?: string;
  lastMessageTime: Date;
  isGroup: boolean;
  groupId?: string;
  groupCharacters?: any[];
  mainCharacterId?: string;
  mainCharacterName?: string;
  mainCharacterSlug?: string;
}
```

### Change 5: Update Navigation Helpers

When navigating from recent chats, parse the composite key:

```typescript
// In recentChatsService.ts or navigation helper
export function getChatNavigationPath(chat: FormattedRecentChat): string {
  if (chat.isGroup) {
    // ... existing group logic
  }
  
  // Parse composite key if available
  const parsed = parseChatKey(chat.characterId);
  if (parsed) {
    return `/chat/${parsed.movie}/${parsed.character}`;
  }
  
  // Fallback to old logic for backward compatibility
  const movieSlug = chat.movieSlug || chat.from.toLowerCase().replace(/\s+/g, '-');
  const characterSlug = chat.characterSlug || chat.name.toLowerCase().replace(/\s+/g, '-');
  return `/chat/${movieSlug}/${characterSlug}`;
}
```

## Migration Strategy

### Option 1: Clean Break (Recommended)
1. Implement composite key format
2. Clear existing recent chats on app update
3. New chats use correct format going forward

### Option 2: Gradual Migration
1. Implement composite key format
2. Add migration logic to convert old entries on load:
   ```typescript
   // In messageStore initialization
   const migrateRecentChats = (chats: RecentChat[]) => {
     return chats.map(chat => {
       if (chat.characterId.includes(':')) {
         return chat; // Already migrated
       }
       // Try to construct composite key from available data
       const characterSlug = chat.characterSlug || slugify(chat.characterName);
       const movieSlug = chat.movieSlug || slugify(chat.movieName);
       return {
         ...chat,
         characterId: createChatKey(characterSlug, movieSlug)
       };
     });
   };
   ```

## Session Token Compatibility

**Good news:** The session token system already works correctly!

From `conversationTokenManager.ts` lines 138-149:
```typescript
if (cname && mname) {
  const km = keyCharMovie(cname, mname);
  const vm = await readKey(km);
  if (vm) {
    logger.info('Token resolved', {
      scope: 'characterMovie',
      // ...
    });
    return vm;
  }
}
```

Session tokens are already scoped to `character+movie` pairs via normalized names. This is separate from the `characterId` used for recent chats deduplication.

## Files Requiring Changes

1. ✅ **Create utility:** `mobile_app_sx/utils/chatKeyUtils.ts` (new file)
2. ✅ **Update interface:** `mobile_app_sx/store/messageStore.ts` (RecentChat interface)
3. ✅ **Update chat component:** `mobile_app_sx/app/chat/[movie]/[character].tsx` (5+ saveRecentChat calls)
4. ✅ **Update navigation:** `mobile_app_sx/services/recentChatsService.ts` (getChatNavigationPath, prepareNavigationContext)
5. ✅ **Update hook:** `mobile_app_sx/hooks/useRecentChats.ts` (if needed)

## Testing Checklist

- [ ] Navigate to character from cast screen → send message → check recent chats (1 entry)
- [ ] Navigate to same character from drawer → send message → check recent chats (still 1 entry)
- [ ] Navigate to character from home search → send message → check recent chats (still 1 entry)
- [ ] Switch between different movies with same character name → check separate entries
- [ ] Group chats still work correctly
- [ ] Session tokens still resolve correctly
- [ ] Navigation from recent chats works correctly

## Priority: HIGH

This causes user confusion and data fragmentation. Every chat interaction creates potential duplicates.
