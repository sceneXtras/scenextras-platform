# Series Parameter Stale Data Fix

## Problem
When navigating between different movies/series with characters, the `series` parameter was stale and contained the old movie title, causing API requests to use the wrong conversation context.

**Example:**
- Navigate to "Walter White" in "Breaking Bad" 
- Then navigate to "Walter White" in "Captain Hook - The Cursed Tides"
- API request still sends `series: "Breaking Bad"` (stale)

## Root Causes

### 1. Session Token Fallback Issue
**File:** `mobile_app_sx/services/conversationTokenManager.ts`

The token manager was falling back to character-only tokens when no character+movie token existed. This meant reusing tokens from previous movie/character conversations.

**Flow:**
1. User chats with "Walter White" in Movie A → Token stored as `walter-white:movie-a`
2. User navigates to "Walter White" in Movie B
3. Token lookup for `walter-white:movie-b` finds nothing
4. Falls back to `walter-white` token (from Movie A conversation) ❌
5. API uses old conversation context with wrong movie

### 2. Stale Session Data
**File:** `mobile_app_sx/app/chat/[movie]/[character].tsx`

The `sessionMovieData` state was only set once and never updated when navigating to a different movie.

**Old condition:**
```typescript
if ((movieContext || characterContext || castData) && !sessionMovieData) {
  // Only runs if sessionMovieData is null
}
```

This meant once set, `movieData.title` would never update, keeping the old movie title.

## Solution

### 1. Prevent Token Fallback (conversationTokenManager.ts)
```typescript
if (cname && mname) {
  const km = keyCharMovie(cname, mname);
  const vm = await readKey(km);
  if (vm) {
    return vm;
  }
  // NEW: Don't fall back to character-only token when movie is specified
  logger.info('No token found for character+movie combination', {
    characterName: cname,
    movieName: mname,
    fallbackPrevented: true,
  });
  return null;
}
```

**Result:** Each character+movie combination gets its own conversation token. No cross-contamination.

### 2. Update Session Data on Movie Change (chat screen)
```typescript
// OLD: Only set once
if ((movieContext || characterContext || castData) && !sessionMovieData) {

// NEW: Update when movie ID changes
if ((movieContext || characterContext || castData) && 
    (!sessionMovieData || movieContext?.id !== sessionMovieData?.id)) {
```

**Result:** Session data refreshes when navigating to a different movie, so `movieData.title` stays current.

## Files Changed
1. `mobile_app_sx/services/conversationTokenManager.ts` - Prevent fallback to character-only tokens
2. `mobile_app_sx/app/chat/[movie]/[character].tsx` - Update session data on movie change

## Testing
Run the mobile app and test the flow:
```bash
cd mobile_app_sx
./run.sh --web
```

1. Navigate to a character from one movie
2. Go back and navigate to the same (or different) character from another movie
3. Send a message
4. Check logs - `series` parameter should match current movie
5. Verify API request has correct movie name

## Expected Behavior
- ✅ Each character+movie combination has its own conversation
- ✅ `series` parameter always reflects current movie
- ✅ Session tokens don't leak between different movies
- ✅ No stale data when navigating between movies

## Log Evidence
**Before fix:**
```
[ConversationTokenManager] Token resolved | {"movieName": "captain hook - the cursed tides", ...}
📤 CHAT API REQUEST: { "series": "Captain Hook - The Cursed Tides", ... }
```

**After fix:**
```
[ConversationTokenManager] No token found for character+movie combination | {"characterName": "walter white", "movieName": "breaking bad"}
📤 CHAT API REQUEST: { "series": "Breaking Bad", ... }
```
