# Custom Cover Fetching - Complete Implementation Update

**Date**: 2025-11-21
**Author**: Claude Code
**Scope**: Complete Custom Cover Image Implementation for Mobile App

---

## Overview

The mobile app now has **complete custom cover fetching** support for both:
1. **Character/Cast Profile Images**
2. **Movie/Series/Cartoon Poster/Cover Images**

Both systems now follow the same priority-based quality scoring system as the backend's `CharacterImageManager`.

## Priority System (Unified Across All Image Types)

### Quality Score Hierarchy

1. **Character-specific images** (Score: 100)
   - Pattern: `character_specific_image_*`
   - Source: Manually curated, highest quality

2. **AI-generated images** (Score: 80)
   - Pattern: `anonymous_*`
   - Source: Replicate API / AI generation

3. **TVDB images** (Score: 65-70)
   - URL: `artworks.thetvdb.com`
   - Source: TheTVDB API

4. **TMDB images** (Score: 45-50)
   - URL: `image.tmdb.org`
   - Source: The Movie Database API

5. **Fallback/Placeholder** (Score: 0)
   - Generic placeholders when no image available

## Implementation Details

### 1. Character/Cast Profile Images

**Files Updated:**
- `helper/image-processing.ts`
  - `processCastProfilePath()` - Priority-based profile image processing
  - `resolveCharacterImage()` - Field path checking with priority order
  - `CHARACTER_IMAGE_FIELD_PATHS` - Reorganized for optimal priority

**Key Features:**
- Checks 70+ field paths in priority order
- Handles nested object paths
- Smart extraction from arrays
- Automatic URL qualification

### 2. Movie/Series/Cartoon Poster Images

**Files Updated:**
- `services/contentDiscoveryApi.ts`
  - `applyCustomPosterOverrides()` - Complete priority system for posters

- `helper/image-processing.ts`
  - `processMoviePosterPath()` - Priority-based poster processing
  - `processCachedMoviePosterPath()` - With caching support

**Key Features:**
- Checks for anonymous posters first (AI-generated covers)
- Falls back to character-specific patterns
- Then checks direct filename matches
- Finally uses title-slug based covers

### 3. Backend Image URL Handling

**Updated Functions:**
- `getBackendImageUrl()` - Handles anonymous_ and character_specific_ patterns
- `getDirectImageUrl()` - Includes priority checks before TMDB fallback
- `normalizeCharacterImageUri()` - Comprehensive URL normalization

## Complete Flow Examples

### Example 1: Popular Movies Fetch
```typescript
// When getPopularContent('movies') is called:
1. Fetch movie data from API
2. applyCustomPosterOverrides() runs:
   - Checks if poster_path contains 'anonymous_' → Use AI cover
   - Checks for 'character_specific_image_{title}' → Use curated cover
   - Checks for direct poster filename match
   - Checks for '{title}_cover.png' → Use title-based cover
   - Falls back to original TMDB poster
3. Returns movies with highest quality covers available
```

### Example 2: Character Display
```typescript
// When displaying a character:
1. resolveCharacterImage() checks fields in order:
   - profile_path (most common)
   - avatar_url (often has anonymous_ images)
   - image_url
   - nested paths (profile.image, etc.)
2. For each field value:
   - If contains 'character_specific_image_' → Priority 1
   - If contains 'anonymous_' → Priority 2
   - If TVDB URL → Priority 3
   - If TMDB path → Priority 4
3. Returns best available image
```

## API Endpoints Supported

The implementation properly handles all these backend endpoints:

1. **Custom Images**
   - `/api/image-no-auth/{filename}` - Anonymous and character-specific images
   - Direct Azure Blob Storage URLs

2. **External Sources**
   - `https://artworks.thetvdb.com/*` - TVDB images
   - `https://image.tmdb.org/t/p/*` - TMDB images

## Testing Verification

To verify the implementation works:

### For Movie/Series Posters:
1. Movies with `anonymous_*` poster_path should show AI-generated covers
2. Content with `character_specific_image_*` paths should show custom covers
3. TVDB poster URLs should be preserved and used directly
4. Title-based covers (`{title}_cover.png`) should be detected and used

### For Character Images:
1. Characters with `anonymous_*` in any image field should show AI images
2. Characters with `character_specific_image_*` should show curated images
3. TVDB character images should take precedence over TMDB
4. Proper fallback through the priority chain

## Key Functions Reference

### Poster/Cover Processing
```typescript
// Process any movie/series poster with priority system
processMoviePosterPath(posterPath?: string): string

// With caching support (mobile only)
processCachedMoviePosterPath(posterPath?: string, useCache?: boolean): Promise<string>

// Batch processing for content arrays
applyCustomPosterOverrides<T>(items: T[]): Promise<T[]>
```

### Character Image Processing
```typescript
// Process cast member profile with priority system
processCastProfilePath(profilePath?: string): string

// Resolve character image from any object
resolveCharacterImage(character: any, options?: ResolveOptions): CharacterImageResolution

// With caching support
processCachedCastProfilePath(profilePath?: string, useCache?: boolean): Promise<string>
```

## Benefits Achieved

1. **Consistency**: Mobile app matches backend and web app logic exactly
2. **Quality**: AI and custom images prioritized over stock images
3. **Performance**: Efficient field checking with early returns
4. **Completeness**: Covers both character AND content poster images
5. **Flexibility**: Graceful fallbacks at each priority level

## Migration Impact

**No Breaking Changes** - All existing image URLs continue to work. The updates add enhanced support for custom covers while maintaining backward compatibility.

## Debugging Updates (November 21, 2025)

### Issue Identified
The `/images` API endpoint was failing due to incorrect import path.

### Fixes Applied
1. **Fixed import path** in `external-code/api/media/images.ts`:
   - Changed from `import { api } from '../core'` to `import { api } from '../core/http'`

2. **Enhanced error logging** in `getAvailableImages()`:
   - Added API base URL logging
   - Detailed response structure logging
   - Comprehensive error details with status codes
   - Response data structure validation

### API Endpoint Verification
- Correct endpoint: `/api/images` (becomes `${API_URL}/api/images`)
- Returns: `{ images: Array<{ name?: string, link?: string }> }`
- Caching: 24-hour TTL with early returns for in-flight requests

## Metrics to Track

Consider tracking:
- Percentage of content using custom covers vs TMDB
- Cache hit rates for different image sources
- Load times for different image types
- User engagement with custom vs stock images
- API success/failure rates for `/images` endpoint

## Future Enhancements

1. **Batch Optimization**: Pre-fetch popular content covers
2. **Smart Caching**: Longer TTL for higher quality images
3. **A/B Testing**: Compare engagement with custom vs stock covers
4. **CDN Integration**: Cloudflare Images for automatic optimization
5. **Fallback Strategy**: Consider static fallback list if API fails

---

**Status**: ✅ Complete Implementation with Debug Fixes
**Coverage**: ✅ Both Character Images AND Content Posters
**Testing**: Enhanced error logging deployed
**Performance**: Optimized with priority-based early returns
**Debug**: Import path fixed, enhanced logging added