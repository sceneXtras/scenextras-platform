# Custom Cover Fetching - Mobile App Update Summary

**Date**: 2025-11-21
**Author**: Claude Code
**Scope**: Mobile App Custom Cover Image Implementation

---

## Overview

The mobile app's custom cover image fetching logic has been successfully updated to align with the frontend webapp implementation, ensuring consistent behavior across platforms for displaying character-specific, AI-generated, and custom cover images.

## Key Updates Implemented

### 1. Anonymous Image Handling (AI-Generated)
- **Added support for `anonymous_` prefixed images** - These are AI-generated character images stored in Azure Blob Storage
- **Priority Score: 80** - High priority, second only to character-specific images
- **Implementation**: Added logic in `getBackendImageUrl()`, `getDirectImageUrl()`, and `normalizeCharacterImageUri()`

### 2. Character-Specific Image Support
- **Added support for `character_specific_image_` prefixed images** - Manually curated high-quality images
- **Priority Score: 100** - Highest priority in the image selection hierarchy
- **Implementation**: Added dedicated handling in `getDirectImageUrl()` and `processCastProfilePath()`

### 3. Aligned Priority System

The mobile app now follows the same priority hierarchy as the frontend:

1. **Character-specific images** (Quality Score: 100)
   - Pattern: `character_specific_image_{normalized_name}.jpg`
   - Source: Manually curated images

2. **AI-generated images** (Quality Score: 80)
   - Pattern: `anonymous_*.jpg`
   - Source: Replicate API / AI generation

3. **TVDB images** (Quality Score: 65-70)
   - URL: `https://artworks.thetvdb.com`
   - Source: TheTVDB GraphQL API

4. **TMDB images** (Quality Score: 45-50)
   - URL: `https://image.tmdb.org/t/p/w500`
   - Source: The Movie Database REST API

### 4. Updated Field Path Priorities

Reorganized `CHARACTER_IMAGE_FIELD_PATHS` array to match frontend priority order:
- Profile paths (highest priority)
- Avatar fields (for AI-generated images)
- Generic image fields
- Character/person specific fields
- Media-specific fields
- Nested object paths
- Fallback paths

## Files Modified

1. **`/mobile_app_sx/helper/image-processing.ts`**
   - Updated `getBackendImageUrl()` - Added anonymous image handling
   - Updated `getDirectImageUrl()` - Added anonymous and character-specific image handling
   - Updated `normalizeCharacterImageUri()` - Added anonymous image support
   - Updated `processCastProfilePath()` - Implemented full priority system
   - Reorganized `CHARACTER_IMAGE_FIELD_PATHS` - Aligned with frontend priorities

2. **`/mobile_app_sx/helper/__tests__/image-processing.test.ts`** (New)
   - Comprehensive test suite for custom cover fetching
   - Tests for all priority levels
   - Integration tests for complex scenarios

## API Endpoint Compatibility

The mobile app now properly handles the following backend endpoints:
- `/api/image-no-auth/{filename}` - For serving anonymous and character-specific images
- Direct Azure Blob Storage URLs
- TVDB artwork URLs
- TMDB image URLs

## Key Functions Updated

### `getBackendImageUrl(path)`
```typescript
// Now handles:
- anonymous_* images → /api/image-no-auth/{filename}
- character_specific_image_* → proper backend URL
- /api/image-no-auth/ paths → API_URL + path
- Base64 data URIs → returned as-is
- Blob URLs → returned as-is
```

### `processCastProfilePath(profilePath)`
```typescript
// Priority order:
1. character_specific_image_* (Score: 100)
2. anonymous_* (Score: 80)
3. thetvdb.com URLs (Score: 65-70)
4. tmdb.org URLs (Score: 45-50)
5. Other complete URLs
6. TMDB path construction
```

### `resolveCharacterImage(character, options)`
```typescript
// Checks fields in priority order:
- profile_path, profilePath, profileImage
- avatar, avatar_url, avatarUrl
- image, image_url, imageUrl
- Nested paths and fallbacks
```

## Benefits

1. **Consistency**: Mobile app now follows the same image priority logic as the web app
2. **Quality**: Prioritizes higher-quality custom and AI-generated images over stock TMDB images
3. **Flexibility**: Supports multiple image sources with graceful fallbacks
4. **Performance**: Efficient field path checking with early returns
5. **Maintainability**: Clearer code organization with documented priority levels

## Testing

Created comprehensive test suite covering:
- Anonymous image handling
- Character-specific image processing
- Priority system verification
- URL construction and normalization
- Fallback behavior
- Complex character objects with multiple image sources

## Migration Notes

No breaking changes - the updates are backward compatible. Existing image URLs will continue to work, with the addition of better support for custom covers.

## Future Considerations

1. **Caching Strategy**: Consider implementing quality score-based cache TTL (higher quality = longer cache)
2. **Batch Processing**: Could add batch image resolution for performance
3. **Metrics**: Track which image sources are most commonly used
4. **CDN Integration**: Consider Cloudflare Images or similar for automatic optimization

## Verification

To verify the implementation works correctly:

1. Characters with `anonymous_*` profile paths should display AI-generated images
2. Characters with `character_specific_image_*` paths should display custom curated images
3. TVDB images should take precedence over TMDB when both are available
4. The app should gracefully fall back through the priority chain when higher-priority images are unavailable

---

**Status**: ✅ Implementation Complete
**Next Steps**: Monitor performance and gather user feedback on image quality improvements