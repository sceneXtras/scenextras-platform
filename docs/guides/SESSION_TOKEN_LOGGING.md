# Session Token Logging Enhancement

## Changes Made

Added full session token logging to `conversationTokenManager.ts` for debugging purposes.

### File Modified
**File:** `mobile_app_sx/services/conversationTokenManager.ts`

### Changes Summary

Added `sessionToken: <full-token>` to all logging statements in:
1. `getToken()` - When resolving tokens (6 locations)
2. `setToken()` - When storing tokens (1 location)

### Before
```typescript
logger.info('Token resolved', {
  scope: 'characterMovie',
  conversationId: convId,
  groupId,
  characterName: cname,
  movieName: mname,
  tokenPreview: maskToken(vm),
  tokenLength: vm.length,
});
```

### After
```typescript
logger.info('Token resolved', {
  scope: 'characterMovie',
  conversationId: convId,
  groupId,
  characterName: cname,
  movieName: mname,
  tokenPreview: maskToken(vm),
  tokenLength: vm.length,
  sessionToken: vm, // FULL TOKEN FOR DEBUGGING
});
```

## Updated Logging Locations

### getToken() - 6 locations:
1. **conversationId scope** - Line ~91
2. **groupId scope** - Line ~108
3. **groupIdLegacy scope** - Line ~124
4. **characterMovie scope** - Line ~141
5. **character scope** - Line ~158
6. **characterLegacy scope** - Line ~182

### setToken() - 1 location:
1. **Token stored** - Line ~225

## What You'll See in Logs

### When Token is Stored
```
INFO [ConversationTokenManager] Token stored | {
  "conversationId": undefined,
  "groupId": undefined,
  "characterName": "bruce wayne",
  "movieName": "the dark knight",
  "wroteScopes": {
    "conversationId": false,
    "groupId": false,
    "characterMovie": true,
    "character": true
  },
  "tokenPreview": "b496d5...df26",
  "tokenLength": 36,
  "sessionToken": "b496d54c-c5d8-4a14-8338-e3dc326bdf26"  ← FULL TOKEN
}
```

### When Token is Retrieved
```
INFO [ConversationTokenManager] Token resolved | {
  "scope": "characterMovie",
  "conversationId": undefined,
  "groupId": undefined,
  "characterName": "bruce wayne",
  "movieName": "the dark knight",
  "tokenPreview": "b496d5...df26",
  "tokenLength": 36,
  "sessionToken": "b496d54c-c5d8-4a14-8338-e3dc326bdf26"  ← FULL TOKEN
}
```

## Verification Steps

### Test 1: First Message to Character
1. Navigate to Bruce Wayne from The Dark Knight
2. Send intro message
3. Check logs for "Token stored" message
4. Verify `sessionToken` field contains full UUID
5. Verify `characterName: "bruce wayne"` (normalized, lowercase)
6. Verify `movieName: "the dark knight"` (normalized, lowercase)
7. Verify `wroteScopes.characterMovie: true`

### Test 2: Subsequent Messages (Same Character-Movie)
1. Send another message to Bruce Wayne / The Dark Knight
2. Check logs for "Token resolved" message
3. Verify `scope: "characterMovie"`
4. Verify same `sessionToken` value as Test 1
5. Confirm no "Token stored" message (using existing token)

### Test 3: Different Movie, Same Character Name
1. Navigate to Bruce Wayne from Batman Begins
2. Send message
3. Check logs for "Token stored" with NEW sessionToken
4. Verify `movieName: "batman begins"` (different from Test 1)
5. Verify different `sessionToken` value

### Test 4: Navigation from Drawer
1. Navigate from recent chats to existing chat
2. Send message
3. Check logs for "Token resolved"
4. Verify SAME `sessionToken` as original chat
5. Confirm character-movie matching works correctly

## Expected Token Behavior

### Correct Scoping
✅ **Each character-movie pair should have ONE unique session token**

Examples:
- Bruce Wayne + The Dark Knight → Token A
- Bruce Wayne + Batman Begins → Token B (different)
- Joker + The Dark Knight → Token C (different)

### Persistence
✅ **Token should persist across:**
- App restarts
- Navigation changes
- Opening from drawer vs cast screen

### Resolution Order (Priority)
1. `conversationId` (if set by backend)
2. `groupId` (for group chats)
3. `character+movie` (most common for 1-on-1 chats) ← **Primary for debugging**
4. `character` only (fallback/legacy)

## Debugging Common Issues

### Issue: Different tokens for same character-movie
**Check logs for:**
- Different `characterName` normalization (case, spaces)
- Different `movieName` normalization
- Token being stored without `movieName`

**Example Problem:**
```
Token stored | characterName: "Bruce Wayne", movieName: "the dark knight"  ← Not normalized!
Token resolved | characterName: "bruce wayne", movieName: "the dark knight" ← Can't find it
```

### Issue: Token not found when expected
**Check logs for:**
- Missing "Token stored" message
- Scope mismatch (e.g., stored as "character" but looking for "characterMovie")
- Token stored with different character/movie name

### Issue: Multiple tokens for same character
**This is the bug we're fixing!** With composite characterId, each character-movie pair will have consistent identification, ensuring session tokens are correctly reused.

## Important Notes

### Security Warning
⚠️ **These logs expose full session tokens!**

**For Production:**
- Remove or comment out `sessionToken: <value>` lines
- Keep only `tokenPreview` for debugging
- Session tokens allow API access to user conversations

**For Development/Staging:**
- Keep logging enabled for debugging
- Monitor token consistency
- Verify no duplicate tokens per character-movie pair

### Storage Keys Format

The actual AsyncStorage keys used:
```
conv_token:v1:charMovie:bruce wayne:the dark knight
conv_token:v1:char:bruce wayne
conv_token:v1:conv:<conversation-id>
conv_token:v1:group:<group-id>
```

Normalized names are lowercase with trimmed whitespace.

## Related Changes

This logging enhancement works together with:
1. **Composite characterId fix** (`RECENT_CHATS_FIX_IMPLEMENTATION.md`)
   - Ensures consistent character-movie pairing
   - Prevents duplicate recent chat entries
   
2. **Session token scoping** (already correct)
   - Tokens properly scoped to normalized character+movie names
   - Independent of characterId format

## Rollback Instructions

To remove full token logging:

```bash
cd mobile_app_sx/services
# Edit conversationTokenManager.ts
# Remove all lines with: sessionToken: v, // FULL TOKEN FOR DEBUGGING
# Remove all lines with: sessionToken: vLegacy, // FULL TOKEN FOR DEBUGGING
# Remove all lines with: sessionToken: vm, // FULL TOKEN FOR DEBUGGING
# Remove all lines with: sessionToken: token, // FULL TOKEN FOR DEBUGGING
```

Or restore from git:
```bash
git checkout HEAD -- services/conversationTokenManager.ts
```

## Testing Verification

Run the app and perform a complete flow:
1. Chat with character A from movie 1
2. Note the session token
3. Navigate away and back
4. Send another message
5. Verify SAME session token is used
6. Chat with character A from movie 2
7. Verify DIFFERENT session token
8. Check recent chats show correct entries (no duplicates)

All session tokens should be properly logged with full UUID values for verification.
