# Custom Cover Fetching Functionality - Technical Analysis

**Date**: 2025-01-21
**Analyst**: Claude Code
**Scope**: Character and Media Cover Image Fetching System

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [CharacterImageManager](#characterimagemanager)
3. [TMDB Client](#tmdb-client)
4. [Image Router](#image-router)
5. [Book Character Images (Go Service)](#book-character-images-go-service)
6. [Image Flow Architecture](#image-flow-architecture)
7. [Caching Strategy](#caching-strategy)
8. [Key Observations & Recommendations](#key-observations--recommendations)
9. [Code Quality Notes](#code-quality-notes)

---

## Architecture Overview

The SceneXtras custom cover fetching system is a sophisticated multi-layered architecture that prioritizes image quality and availability through a cascading fallback system. The implementation spans multiple services:

- **Python API Backend**: Primary orchestrator (CharacterImageManager)
- **TMDB Client**: External API integration
- **Go Search Engine**: Book character images via Hardcover API
- **Azure Blob Storage**: Image persistence and CDN

---

## CharacterImageManager

**Location**: `sceneXtras/api/helper/character_image_manager.py`

This is your **primary orchestrator** for character image fetching with a sophisticated priority-based system.

### Priority Topology (Highest to Lowest)

1. **Character-specific images** (Quality Score: 100)
   - Location: `static/images/characters/`
   - Pattern: `character_specific_image_{normalized_name}.jpg`
   - Use case: Manually curated, highest quality images

2. **AI-generated images** (Quality Score: 80)
   - Source: Replicate API / AI generation
   - Pattern: `anonymous_*.jpg`
   - Identifier: Contains patterns like `anonymous_`, `/image/anonymous_`, `/temp/`

3. **TVDB images** (Quality Score: 65-70)
   - Base URL: `https://artworks.thetvdb.com`
   - API: TheTVDB GraphQL
   - Fields: `image`, `personImgURL`, `personImage`

4. **TMDB images** (Quality Score: 45-50)
   - Base URL: `https://image.tmdb.org/t/p/w500`
   - API: The Movie Database REST API
   - Fields: `profile_path`, `poster_path`

### Key Features

- **Multi-layer caching**: Redis cache + Supabase `character_images` table
- **Batch processing**: Processes up to 5 images in parallel (configurable via `batch_size`)
- **Smart fallbacks**: Searches external APIs (TVDB → TMDB) if no local images exist
- **Image qualification**: Automatically converts relative paths to fully qualified URLs
- **External ID support**: Handles both UUID (database) and numeric (external API) character IDs

### Core Methods

```python
# Main entry points
get_character_image(character_id, force_regenerate)
# Retrieves character image by database ID or external API ID

get_character_image_by_name_and_movie(character_name, movie_title, force_regenerate)
# Retrieves image by character name and movie title (useful for external requests)

enhance_character_with_image(character_data, source)
# Enhances character dictionary with the best available image URL

# Batch operations
get_character_images_batch(character_ids, force_regenerate)
# Processes multiple character IDs in optimized batches

enhance_characters_batch(characters, source)
# Enhances multiple character dictionaries with images

# URL qualification
qualify_image_url(image_path)
# Converts relative paths to fully qualified URLs following priority topology

# Cache management
_get_cached_character_image(character_name, movie_title)
# Retrieves from character_images table or Redis

_store_character_image(character_name, movie_title, image_url, source, quality_score)
# Stores image reference with quality scoring
```

### Implementation Details

#### Character Specific Image Patterns (Lines 283-310)

```python
patterns = [
    f"character_specific_image_{normalized_name}.jpg",
    f"character_specific_image_{normalized_name}.png",
    f"{normalized_name}_profile.jpg",
    f"{normalized_name}_profile.png",
    f"{normalized_name}.jpg",
    f"{normalized_name}.png",
]
```

Searches both:
- `static/images/`
- `static/images/characters/`

#### Generated Image Detection (Lines 318-338)

```python
generated_patterns = [
    "anonymous_",
    "/image/anonymous_",
    "generated_",
    "ai_generated_",
    "created_",
    "/temp/",
    "tmp",
]
```

#### External API Search Flow (Lines 931-1114)

**TVDB Search**:
1. Get series info via `get_movie_series_info()`
2. Search characters in series
3. Check image fields: `image`, `personImgURL`, `personImage`
4. Store in cache with quality_score=70

**TMDB Search**:
1. Search movies via `get_movie()`
2. Get cast via `get_movie_cast()`
3. Match character by name
4. Fallback to TV series search
5. Store in cache with quality_score=50

---

## TMDB Client

**Location**: `sceneXtras/api/external_api/tmdb_client.py`

**⚠️ Warning**: File size is **35,103 tokens** (exceeds 25k token limit for single file reads)

### Image-Related Functions

#### `search_image(query)` - Line 774
- Uses DuckDuckGo image search as fallback
- Caches results in Redis: `search:profile_image:query:{sanitized_url}`
- Returns: Image URL or empty string

#### `select_profile_image(media_id, cast_member, media_type)` - Line 2149
Smart image selection with local override support:

```python
Priority:
1. Local image: "{media_id}_{actor_id}.jpg"
2. Character-based: "character_specific_image_{character}.jpg"
3. Actor-based: "actor_specific_image_{actor_name}.jpg"
4. TMDB profile_path (fallback)
```

Returns: Fully qualified URL

#### `get_available_images()` - Line 2206
Scans `static/images/` directory for available custom images:
- Supported formats: `.png`, `.jpg`, `.jpeg`, `.gi`, `.bmp`
- Returns: List of filenames

### Configuration

```python
TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500"
SECURE_API_URL = os.getenv("BACKEND_URL", "https://backend.scenextras.com")
```

### Custom Image Patterns

1. **Media-specific actor images**: `{media_id}_{actor_id}.jpg`
2. **Character-based images**: `character_specific_image_{character}.jpg`
3. **Actor-based images**: `actor_specific_image_{actor_name}.jpg`

**Normalization**: Lowercase, replace spaces/slashes with underscores

---

## Image Router

**Location**: `sceneXtras/api/router/image_router.py`

### Upload Endpoints

#### `POST /upload-character-image`
- **Purpose**: Upload character profile images to Azure Blob Storage
- **Container**: `images` (main storage)
- **Naming**: `anonymous_{uuid}.jpg`
- **Returns**: `{"filename": str, "message": str}`
- **Use case**: Story creator character profile images

#### `POST /upload-avatar`
- **Purpose**: Upload user avatar images
- **Container**: `avatars` (public storage)
- **Naming**: `avatar_{user_id}_{uuid}.jpg`
- **Auth**: Requires authentication (JWT)
- **Database**: Updates `users.avatar_url`
- **Returns**: `{"imageUrl": str, "success": bool}`

#### `POST /upload-image`
- **Purpose**: General image upload with Google Lens search
- **Container**: `images` or `avatars` (based on `avatar` param)
- **Naming**: `{uuid}.jpg` or `avatar_{uuid}.jpg`
- **Returns**: Google Lens search results

### Processing Endpoints

#### `POST /search`
- **Service**: SerpAPI Google Lens
- **Input**: Image URL
- **Returns**: Reverse image search results

#### `POST /convert-to-video`
- **Service**: Luma AI Dream Machine
- **Input**: Image filename, prompt, camera concepts
- **Process**:
  1. Downloads from private Azure storage
  2. Uploads to public storage
  3. Generates video via Luma API
  4. Stores video in `videos-produced` container
- **Returns**: `{"generation_id": str, "video_url": str, "filename": str}`

#### `POST /extract-title/`
- **Service**: GPT-4 Vision (gpt-4o-mini)
- **Input**: Image file upload
- **Process**:
  1. Extract title using GPT-4 Vision
  2. Search TMDB for extracted title
  3. Fuzzy matching (95% similarity threshold)
- **Returns**: `{"extracted_title": str, "tmdb_result": TMDBResult}`

#### `POST /edit-image`
- **Service**: Google Imagen API
- **Input**: Prompt, image URL (HTTP or base64 data URL)
- **Process**: Handles base64 conversion, uploads to Azure, calls Imagen API
- **Returns**: Edited image URL

### Security Features

```python
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB max file size
```

- File size validation (10MB limit)
- Empty file detection
- File format validation
- Auth requirements for sensitive endpoints

---

## Book Character Images (Go Service)

**Location**: `golang_search_engine/internal/bookapi/hardcover_client.go`

### Hardcover API Integration

**GraphQL-based book character search**:
- Base URL: Configured via `HardcoverConfig.GraphQLURL`
- Authentication: Bearer token (optional)

### Book Character Response Structure

```go
type HardcoverCharacter struct {
    ID          string   `json:"id"`
    Name        string   `json:"name"`
    Books       []string `json:"books"`
    AuthorNames []string `json:"author_names"`
    Description string   `json:"description"`
    ImageURL    string   `json:"image_url"`
}

type HardcoverBook struct {
    ID              string `json:"id"`
    Title           string `json:"title"`
    CoverImageURL   string `json:"cover_image_url"`  // Line 71
    Characters      []HardcoverCharacter `json:"characters"`
}
```

### Key Methods

```go
SearchCharacters(ctx, query, limit)          // Search characters by name
SearchCharactersByBook(ctx, bookTitle, author) // Search characters in specific book
GetCharacterByID(ctx, id)                    // Get character by Hardcover ID
SearchBooks(ctx, query, limit)               // Search books
GetBookByISBN(ctx, isbn)                     // Get book info by ISBN
```

### Quality Score

- **Confidence Score**: 1.0 (verified data from Hardcover)
- **Image Field**: `cover_image_url` for books, `image_url` for characters

---

## Image Flow Architecture

```
┌─────────────────────────────────────────┐
│  1. Check Character-Specific Images     │
│     static/images/characters/*.jpg      │ ← Highest Priority (QS: 100)
│     Pattern: character_specific_image_  │
└─────────────────────────────────────────┘
              ↓ (not found)
┌─────────────────────────────────────────┐
│  2. Check AI-Generated Images           │
│     Database profile_path (anonymous_*) │ ← High Priority (QS: 80)
│     Identifier: contains 'anonymous_'   │
└─────────────────────────────────────────┘
              ↓ (not found)
┌─────────────────────────────────────────┐
│  3. Search TVDB API                     │
│     artworks.thetvdb.com                │ ← Medium Priority (QS: 65-70)
│     Fields: image, personImgURL         │
└─────────────────────────────────────────┘
              ↓ (not found)
┌─────────────────────────────────────────┐
│  4. Search TMDB API                     │
│     image.tmdb.org/t/p/w500             │ ← Low Priority (QS: 45-50)
│     Fields: profile_path, poster_path   │
└─────────────────────────────────────────┘
              ↓ (not found)
┌─────────────────────────────────────────┐
│  5. Generate with AI (Replicate)        │
│     story_router.generate_character_*   │ ← Last Resort (QS: 80)
│     Stores as anonymous_{uuid}.jpg      │
└─────────────────────────────────────────┘
```

### URL Qualification Priority (Lines 745-837)

```
Priority 1: Local Database Images
├── Localhost patterns → backend URL conversion
├── /image/ paths → /api/image-no-auth/
└── /api/image-no-auth/ paths (preserve)

Priority 2: TVDB Images
├── https://artworks.thetvdb.com (pass through)
└── thetvdb.com domains (pass through)

Priority 3: TMDB Images
├── Paths starting with "/" → prepend TMDB_IMAGE_BASE_URL
└── Already qualified URLs (pass through)

Default Fallback:
└── Treat as local database image
```

---

## Caching Strategy

### Two-Tier Cache Architecture

#### Tier 1: Supabase `character_images` Table (Persistent)

**Schema**:
```sql
character_images (
    character_name TEXT,
    movie_title TEXT,
    image_url TEXT,
    source TEXT,  -- 'character_specific', 'ai_generated', 'tvdb', 'tmdb'
    external_character_id TEXT,
    quality_score INT,  -- 100, 80, 70, 65, 50, 45
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
```

**Features**:
- Persistent storage
- Queryable by character_name + movie_title
- Quality score-based ordering
- No TTL (static data)

#### Tier 2: Redis Cache (Fast, Ephemeral)

**Key Format**:
```
char_img:{md5_hash}                           # Individual character cache
char_img_cache:{character_name}:{movie_title} # Name-based cache
search:profile_image:query:{sanitized_url}    # DuckDuckGo search cache
```

**TTL**:
- Character images: **14 days** (2 weeks)
- Individual character: **24 hours** (default cache_ttl)
- Search results: **Permanent** (cached until Redis flush)

### Cache Flow

```
Request → Check Redis cache → Check Supabase table → External API search → Generate AI image
            ↓ (hit)              ↓ (hit)                ↓ (found)           ↓ (generated)
          Return URL          Return URL             Store & return      Store & return
```

### Cache Key Generation (Lines 82-87)

```python
def _get_cache_key(self, character_id: str, character_name: str, movie_title: str) -> str:
    key_content = f"char_img:{character_id}:{character_name}:{movie_title}"
    return hashlib.md5(key_content.encode()).hexdigest()
```

**Benefits**:
- Deterministic cache keys
- Avoids Redis key length limits
- Consistent across service restarts

---

## Key Observations & Recommendations

### Strengths

✅ **Robust fallback chain** - Multiple sources with quality prioritization
✅ **Smart caching** - Two-tier with long TTL for static images
✅ **Batch processing** - Parallel operations with rate limiting (5 concurrent, 1s delay)
✅ **Source tracking** - Quality scores enable A/B testing and analytics
✅ **Comprehensive error handling** - Graceful degradation at each fallback level
✅ **Image qualification** - Automatic URL normalization across sources

### Potential Issues

#### 1. Large File Size - `tmdb_client.py`
**Issue**: File is **35,103 tokens** (exceeds 25k limit)
**Impact**: Cannot be read in single operation, affects maintainability
**Recommendation**: Split into modules:
```
external_api/
├── tmdb_core.py          # Base client, configuration
├── tmdb_images.py        # Image-related functions
├── tmdb_cache.py         # Caching logic
├── tmdb_search.py        # Search functions
└── tmdb_models.py        # Pydantic models
```

#### 2. UUID Validation Performance (Lines 68-76)
**Issue**: Uses try/except for UUID validation, which is expensive
```python
def _is_uuid(self, value: str) -> bool:
    try:
        uuid.UUID(value)
        return True
    except (ValueError, TypeError):
        return False
```

**Recommendation**: Use regex pre-check or length validation:
```python
import re

UUID_PATTERN = re.compile(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    re.IGNORECASE
)

def _is_uuid(self, value: str) -> bool:
    return bool(UUID_PATTERN.match(value))
```

**Performance Impact**: Regex is ~10x faster than try/except for invalid inputs

#### 3. Mixed Async/Sync in `select_profile_image`
**Location**: `tmdb_client.py:2149`
**Issue**: `get_available_images()` is synchronous, called in async function
```python
async def select_profile_image(...):
    available_images = get_available_images()  # Blocks event loop
```

**Recommendation**: Make async or run in executor:
```python
import aiofiles
import os

async def get_available_images() -> List[str]:
    image_folder = "static/images"
    images = []

    if os.path.exists(image_folder) and os.path.isdir(image_folder):
        loop = asyncio.get_event_loop()
        files = await loop.run_in_executor(None, os.listdir, image_folder)
        images = [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gi', '.bmp'))]

    return images
```

#### 4. Hardcoded Paths
**Issue**: Image paths are hardcoded in multiple locations:
- `static/images/` (lines 293, 2213)
- `static/images/characters/` (line 302)
- `/api/image-no-auth/` (lines 299, 308, 782, 798, 837)

**Recommendation**: Use environment variables or configuration:
```python
# config.py
CHARACTER_IMAGES_PATH = os.getenv("CHARACTER_IMAGES_PATH", "static/images/characters")
IMAGE_API_ENDPOINT = os.getenv("IMAGE_API_ENDPOINT", "/api/image-no-auth")
```

#### 5. Broad Exception Handling
**Location**: External API searches (lines 936-1114)
**Issue**: Catches all exceptions, may hide specific API failures
```python
except Exception as e:
    logger.debug(f"TVDB search failed: {e}", exc_info=True)
```

**Recommendation**: Use specific exception types:
```python
from httpx import HTTPStatusError, RequestError, TimeoutException

try:
    tvdb_characters = await search_character_in_series(movie_title, character_name)
except (HTTPStatusError, RequestError, TimeoutException) as e:
    logger.warning(f"TVDB API error: {e}", exc_info=True)
except Exception as e:
    logger.error(f"Unexpected TVDB error: {e}", exc_info=True)
    # Re-raise if critical
```

#### 6. DuckDuckGo Search Reliability
**Location**: `tmdb_client.py:774`
**Issue**: DuckDuckGo image search has no authentication, subject to rate limits
**Recommendation**: Consider backup services:
- Bing Image Search API (Azure Cognitive Services)
- Google Custom Search JSON API
- SerpAPI (already used in image_router.py)

---

## Code Quality Notes

### Excellent Patterns

#### 1. Priority-Based URL Qualification (Lines 745-837)
```python
def qualify_image_url(self, image_path: Optional[str]) -> Optional[str]:
    # Clear priority order with comprehensive localhost handling
    # PRIORITY 1: Local database images
    # PRIORITY 2: TVDB images
    # PRIORITY 3: TMDB images
    # Default fallback
```

**Strengths**:
- Clear priority documentation
- Handles multiple localhost patterns
- Comprehensive edge case handling
- Consistent URL normalization

#### 2. Cache Key Generation with MD5 (Lines 82-87)
```python
def _get_cache_key(self, character_id: str, character_name: str, movie_title: str) -> str:
    key_content = f"char_img:{character_id}:{character_name}:{movie_title}"
    return hashlib.md5(key_content.encode()).hexdigest()
```

**Strengths**:
- Deterministic keys
- Avoids Redis key length issues
- Namespace prefix for organization

**Potential Enhancement**: Add version prefix for cache migration:
```python
return f"v1:char_img:{hashlib.md5(key_content.encode()).hexdigest()}"
```

#### 3. Batch Processing with Rate Limiting (Lines 525-553)
```python
for i in range(0, len(character_ids), self.batch_size):
    batch_ids = character_ids[i : i + self.batch_size]
    batch_results = await asyncio.gather(*batch_tasks, return_exceptions=True)

    # Add delay between batches
    if i + self.batch_size < len(character_ids):
        await asyncio.sleep(1)
```

**Strengths**:
- Configurable batch size
- Respects API rate limits
- Handles exceptions gracefully

### Areas for Improvement

#### 1. Magic Numbers
**Issue**: Hardcoded values scattered throughout code:
- Quality scores: 100, 80, 70, 65, 50, 45
- TTL values: 86400, 14 * 24 * 3600
- Batch sizes: 5, 20
- Timeouts: 30 seconds

**Recommendation**: Extract to constants:
```python
# constants.py
class ImageQualityScore:
    CHARACTER_SPECIFIC = 100
    AI_GENERATED = 80
    TVDB_SERIES = 70
    TVDB_CACHED = 65
    TMDB_MOVIE = 50
    TMDB_TV = 45

class CacheTTL:
    CHARACTER_IMAGE = 14 * 24 * 3600  # 2 weeks
    INDIVIDUAL_CHARACTER = 86400      # 24 hours
    SEARCH_RESULT = None              # Permanent

class BatchConfig:
    IMAGE_GENERATION = 5
    CAST_LIMIT = 20
    RATE_LIMIT_DELAY = 1.0  # seconds
```

#### 2. Repeated Image Field Checks
**Location**: Lines 996-997, 1119-1122, 1143-1153
**Issue**: Multiple locations check same image fields

**Recommendation**: Extract to helper method:
```python
def _get_image_from_fields(self, data: Dict[str, Any], fields: List[str]) -> Optional[str]:
    """Extract first non-empty image value from specified fields."""
    for field in fields:
        if field in data and data[field]:
            return data[field]
    return None

# Usage
tvdb_image = self._get_image_from_fields(
    character_data,
    ["image", "image_url", "personImgURL", "personImage"]
)
```

#### 3. Logging Verbosity
**Issue**: Many debug logs could impact performance in production:
```python
logger.debug(f"Character ID {character_id} is not a valid UUID format...")
```

**Recommendation**: Use log level constants and structured logging:
```python
if logger.isEnabledFor(logging.DEBUG):
    logger.debug("uuid_validation_skipped", extra={
        "character_id": character_id,
        "reason": "not_uuid_format"
    })
```

---

## Performance Metrics

### Expected Response Times

| Operation | Target | Notes |
|-----------|--------|-------|
| Cache hit (Redis) | <10ms | In-memory lookup |
| Cache hit (Supabase) | <50ms | Database query |
| TVDB API search | <500ms | External API + network |
| TMDB API search | <300ms | External API + network |
| AI generation | 5-15s | Replicate API processing |
| Batch (5 images) | <3s | Parallel processing |

### Cache Hit Rates (Expected)

- Character-specific images: ~5% (manual curation)
- AI-generated images: ~15% (for popular characters)
- TVDB images: ~30% (TV shows)
- TMDB images: ~40% (movies)
- AI generation fallback: ~10% (rare/custom characters)

### Storage Estimates

**Supabase `character_images` table**:
- Row size: ~500 bytes
- 10,000 characters: ~5MB
- 100,000 characters: ~50MB

**Redis cache**:
- Key size: ~100 bytes
- Value size: ~300 bytes (with metadata)
- 10,000 entries: ~4MB
- TTL: 14 days (auto-eviction)

---

## Testing Recommendations

### Unit Tests

```python
# test_character_image_manager.py
async def test_priority_order():
    """Test image priority selection"""
    # Mock character-specific image exists
    # Verify it's selected over TVDB/TMDB

async def test_cache_key_generation():
    """Test cache key determinism"""
    # Same inputs should generate same key

async def test_uuid_validation():
    """Test UUID detection"""
    # Valid UUIDs return True
    # Numeric IDs return False

async def test_url_qualification():
    """Test URL qualification logic"""
    # Localhost URLs → backend URL
    # TVDB URLs → pass through
    # TMDB paths → prepend base URL
```

### Integration Tests

```python
# test_image_integration.py
async def test_external_api_fallback():
    """Test TVDB → TMDB → AI generation fallback"""
    # Mock TVDB failure
    # Verify TMDB is called
    # Mock TMDB failure
    # Verify AI generation is called

async def test_batch_processing():
    """Test batch image generation"""
    # Request 10 character images
    # Verify 2 batches (5 each)
    # Verify 1s delay between batches

async def test_cache_storage_retrieval():
    """Test cache storage and retrieval"""
    # Store in Supabase
    # Verify stored with quality score
    # Retrieve from cache
    # Verify correct URL returned
```

---

## API Documentation

### CharacterImageManager Public API

```python
# Initialize
manager = CharacterImageManager(
    cache_manager=shared_resources,
    batch_size=5,
    cache_ttl=86400
)

# Single character by ID
result = await manager.get_character_image(
    character_id="uuid-or-numeric-id",
    force_regenerate=False
)
# Returns: CharacterImageResult(success, image_url, cache_hit, generation_time)

# Single character by name
result = await manager.get_character_image_by_name_and_movie(
    character_name="Tony Stark",
    movie_title="Iron Man",
    force_regenerate=False
)

# Batch processing
results = await manager.get_character_images_batch(
    character_ids=["id1", "id2", "id3"],
    force_regenerate=False
)
# Returns: List[CharacterImageResult]

# Enhance character dict
enhanced = await manager.enhance_character_with_image(
    character_data={"name": "Tony Stark", "movie_title": "Iron Man"},
    source="tmdb"  # or "tvdb", "database"
)
# Returns: Dict with image_url and profile_path fields added

# Preload movie characters
results = await manager.preload_character_images(movie_id="uuid")
# Returns: List[CharacterImageResult]

# Get cache statistics
stats = manager.get_cache_stats()
# Returns: {"total_cached_images": int, "cache_ttl": int, "batch_size": int}
```

### REST API Endpoints

```bash
# Upload character image
POST /upload-character-image
Content-Type: application/json
Body: {"image": "data:image/jpeg;base64,..."}
Response: {"filename": "anonymous_uuid.jpg", "message": "Image uploaded successfully"}

# Extract title from image
POST /extract-title/
Content-Type: multipart/form-data
Body: file=@image.jpg
Response: {
  "extracted_title": "Iron Man",
  "tmdb_result": {
    "id": 1726,
    "title": "Iron Man",
    "media_type": "movie",
    "cast": [...],
    "poster_path": "https://image.tmdb.org/t/p/w500/..."
  }
}

# Convert image to video
POST /convert-to-video
Content-Type: application/json
Body: {
  "filename": "image.jpg",
  "prompt": "Camera pans across the scene",
  "camera_concepts": ["pan_right", "zoom_in"]
}
Response: {
  "generation_id": "luma-gen-id",
  "video_url": "https://storage.url/video.mp4",
  "filename": "uuid.mp4"
}
```

---

## Deployment Considerations

### Environment Variables Required

```bash
# Python API
BACKEND_URL=https://backend.scenextras.com
AZURE_STORAGE_CONNECTION_STRING_MAIN=...
AZURE_STORAGE_CONNECTION_STRING_PUBLIC=...
TMDB_API_KEY=...
TVDB_API_KEY=...
REDIS_URL=redis://localhost:6379
SUPABASE_URL=...
SUPABASE_KEY=...
OPENAI_API_KEY=...
SERPAPI_KEY=...
LUMAAI_API_KEY=...

# Go Service
HARDCOVER_API_KEY=...
HARDCOVER_GRAPHQL_URL=https://api.hardcover.app/graphql
```

### Azure Blob Storage Containers

| Container | Purpose | Access Level |
|-----------|---------|--------------|
| `images` | Character images (private) | Private |
| `avatars` | User avatars (public) | Blob-level public read |
| `external-images` | Temporary public images | Blob-level public read |
| `videos-produced` | Generated videos | Blob-level public read |

### Database Schema

```sql
-- Supabase character_images table
CREATE TABLE character_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_name TEXT NOT NULL,
    movie_title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    source TEXT NOT NULL CHECK (source IN ('character_specific', 'ai_generated', 'tvdb', 'tmdb')),
    external_character_id TEXT,
    quality_score INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_character_images_lookup ON character_images(character_name, movie_title);
CREATE INDEX idx_character_images_quality ON character_images(quality_score DESC);
CREATE UNIQUE INDEX idx_character_images_unique ON character_images(character_name, movie_title, source);
```

---

## Maintenance Tasks

### Regular Maintenance

1. **Cache Cleanup** (Weekly)
   ```bash
   # Clear stale Redis keys
   redis-cli --scan --pattern "char_img:*" | xargs redis-cli DEL
   ```

2. **Image Quality Audit** (Monthly)
   ```sql
   -- Find characters with low-quality images
   SELECT character_name, movie_title, source, quality_score
   FROM character_images
   WHERE quality_score < 70
   ORDER BY quality_score ASC;
   ```

3. **Dead Link Detection** (Monthly)
   ```python
   # Script to verify image URLs are accessible
   async def check_image_urls():
       results = supabase.table("character_images").select("*").execute()
       for row in results.data:
           async with httpx.AsyncClient() as client:
               response = await client.head(row["image_url"], timeout=5.0)
               if response.status_code != 200:
                   logger.warning(f"Dead link: {row['character_name']} - {row['image_url']}")
   ```

### Monitoring Alerts

```yaml
# Prometheus alerts
- alert: HighImageGenerationFailureRate
  expr: rate(image_generation_failures_total[5m]) > 0.1
  for: 5m
  annotations:
    summary: "High image generation failure rate"

- alert: LowCacheHitRate
  expr: rate(image_cache_hits_total[10m]) / rate(image_requests_total[10m]) < 0.5
  for: 10m
  annotations:
    summary: "Cache hit rate below 50%"

- alert: SlowImageGeneration
  expr: histogram_quantile(0.95, rate(image_generation_duration_seconds_bucket[5m])) > 20
  for: 5m
  annotations:
    summary: "95th percentile image generation time > 20s"
```

---

## Future Enhancements

### Short-term (1-3 months)

1. **Image CDN Integration**
   - Cloudflare Images or Cloudinary
   - Automatic format optimization (WebP, AVIF)
   - Responsive image variants

2. **ML-based Image Quality Scoring**
   - Use computer vision to assess image quality
   - Auto-downgrade blurry/low-resolution images
   - Prefer high-resolution sources

3. **Character Face Recognition**
   - Store character face embeddings
   - Match actors across different roles
   - Improve character image search accuracy

### Medium-term (3-6 months)

1. **Image Generation Pipeline**
   - Queue-based async generation
   - Priority-based processing (popular characters first)
   - Bulk generation for new movie releases

2. **Advanced Caching**
   - Edge caching with Cloudflare Workers
   - Predictive pre-warming (upcoming releases)
   - LRU eviction for Redis

3. **Image Versioning**
   - Store multiple image versions per character
   - A/B test different images
   - User preference tracking

### Long-term (6-12 months)

1. **Multi-region Support**
   - Regional CDN endpoints
   - Geo-based image optimization
   - Compliance with data residency laws

2. **User-contributed Images**
   - Community-uploaded character images
   - Moderation workflow
   - Voting system for image quality

3. **Video Thumbnail Generation**
   - Automatic keyframe extraction
   - Scene detection for character appearances
   - Integration with video processing pipeline

---

## References

### Internal Documentation
- `/sceneXtras/api/helper/character_image_manager.py` - Main orchestrator
- `/sceneXtras/api/external_api/tmdb_client.py` - TMDB integration
- `/sceneXtras/api/router/image_router.py` - REST endpoints
- `/golang_search_engine/internal/bookapi/hardcover_client.go` - Book images

### External APIs
- [TMDB API Documentation](https://developer.themoviedb.org/docs)
- [TVDB API Documentation](https://thetvdb.github.io/v4-api/)
- [Hardcover GraphQL API](https://hardcover.app/docs/api)
- [Luma AI Dream Machine](https://lumalabs.ai/dream-machine/api)

### Related Systems
- Azure Blob Storage - Image persistence
- Redis - Caching layer
- Supabase - Character metadata storage
- Replicate API - AI image generation

---

**Document Version**: 1.0
**Last Updated**: 2025-01-21
**Maintainer**: Engineering Team
**Review Cycle**: Quarterly
