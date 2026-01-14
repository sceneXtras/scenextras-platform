# SceneXtras Bot Architecture Analysis

## Executive Summary

The SceneXtras bot is a sophisticated multi-service ecosystem that enables users to have conversations with fictional characters from movies, TV shows, anime, and cartoons. This analysis breaks down the complete architecture, API calls, and replication strategies for the Scenester/SceneXtras bot system.

## System Architecture Overview

### Core Services
1. **Python API Backend** (FastAPI) - Main AI chat service
2. **React Web Frontend** - User interface and client-side logic
3. **Go Search Engine** - High-performance character/content search
4. **React Native Mobile App** - Cross-platform mobile experience
5. **Automation Framework** - Playwright-based bot automation

### Data Flow
```
User → Frontend → API Backend → AI Models → Database → Response → Frontend → User
```

## 1. Python API Backend (FastAPI)

### Core Chat Processing

#### Main Chat Endpoint: `/talk_with`
**Location**: `sceneXtras/api/router/gpt_chat_router.py:697`

**Request Structure**:
```python
@chat_router.post("/talk_with")
async def talk_with_entity(
    request: Request,
    chat_input: str = Form(...),  # JSON string
    introduction: bool = Form(False),
    forced_intro_message: Optional[str] = Form(None),
    json_data: Optional[str] = Form(None),  # Group chat data
    current_user: Optional[User] = Depends(get_current_user),
    session: Session = Depends(get_session),
    file: Optional[UploadFile] = File(None),
)
```

**Key API Calls Made**:

1. **Authentication & User Management**
   - `get_current_user()` - JWT token validation
   - `getCurrentUserQuota()` - Check user message credits
   - `isUserPRO()`, `isUserMAX()`, `isUserFREE()` - Subscription tier checks

2. **AI Model Integration**
   - **OpenAI GPT Models**: `openai_client.chat.completions.create()`
   - **Anthropic Claude**: `anthropic_claude.messages.create()`
   - **Google Gemini**: `google_gemini.GenerativeModel().start_chat()`
   - **DeepSeek**: `deepseek_client.chat.completions.create()`
   - **OpenRouter**: `openrouter_client.chat.completions.create()`

3. **Character Context Retrieval**
   - `getSpecificCharacterInfo(series, character)` - TMDB API calls
   - `search_wikipedia(chat_input)` - Wikipedia character data
   - `search_community_content(chat_input)` - Local database queries

4. **Conversation Management**
   - `get_or_initialize_conversation_history()` - Session management
   - `save_conversation_history()` - Persistent storage
   - `fetch_all_user_conversations()` - Chat history retrieval

#### AI Model Selection Logic
**Location**: `sceneXtras/api/chat/chat_gpt_client.py:2317`

```python
def get_models(current_user: User, chat_input: ChatInput, conversation_history: ConversationHistory):
    model_input = get_model_choice(chat_input)
    
    # Auto-seed conversations for 'creative' model
    if model_input == "creative":
        chat_input.seeded = True
        chat_input.fallback_model_choice = ModelChoice("emotion")
    
    # Handle seeded conversations
    if chat_input.seeded and conversation_history:
        actual_model, fallback_activated = _get_seeded_model_choice(chat_input, conversation_history)
        return actual_model, actual_model, actual_model
```

**Model Constants**:
- `CREATIVE_MODEL_CHOICE = "claude-3-5-haiku-latest"`
- `FAST_MODEL_CHOICE = "gemini-2.0-flash-001"`
- `ACCURATE_MODEL_CHOICE = "gpt-4o"`
- `REALISTIC_GEMINI_MODEL_CHOICE = "gemini-2.5-flash"`

### Character Context System

#### Wikipedia Integration
**Location**: `sceneXtras/api/chat/chat_gpt_client.py:274`

```python
def search_wikipedia(chat_input, *, use_perplexity: bool = False):
    query = f"{chat_input.character} from {chat_input.series}"
    result = shared_resources.check_cache_or_search_wikipedia(query)
    return result
```

#### Community Content Database
**Location**: `sceneXtras/api/chat/chat_gpt_client.py:279`

```python
def search_community_content(chat_input):
    # Direct UUID lookup
    if hasattr(chat_input, "entity_id") and chat_input.entity_id:
        movie_query = supabase.table("movies").select("*").eq("id", chat_input.entity_id)
    
    # Fallback to text search
    elif chat_input.series:
        movie_query = supabase.table("movies").select("*").ilike("title", f"%{chat_input.series}%")
    
    # Get all characters from movie
    all_characters_query = supabase.table("characters").select("*").eq("movie_id", movie_id)
```

### Multi-Chat Communication System

#### Character Interjection Logic
**Location**: `sceneXtras/api/chat/chat_gpt_client.py:844`

```python
def handle_multi_chat_communication(conversationHistory, user, chat_input, model, session_token):
    # Extract clean conversation with sender information
    clean_conversation = extract_clean_conversation_with_senders(conversationHistory)
    
    # Generate multi-character prompt
    prompt_result = get_multi_character_prompt(chat_input, clean_conversation, model, user)
    
    # Send to appropriate AI model
    if model.startswith("claude-"):
        system_prompt, conversation_context = prompt_result
        response = clients["anthropic"].messages.create(
            model=model,
            temperature=0.7,
            system=system_prompt,
            max_tokens=1000,
            messages=[{"role": "user", "content": conversation_context}],
        )
```

### Image & Video Generation

#### Image Commands Processing
**Location**: `sceneXtras/api/router/gpt_chat_router.py:856`

```python
image_commands = ["/imagine", "/explore", "/meet", "/go", "/selfie", "/animate"]
matched_command = next((cmd for cmd in image_commands 
                     if chat_input_obj.message and chat_input_obj.message.startswith(cmd)), None)

if matched_command:
    # Check video quota
    if await getCurrentUserVideoQuota(current_user) <= 0 and not await isUserPRO(current_user):
        raise HTTPException(status_code=403, detail="VIDEO_QUOTA_EXCEEDED")
    
    # Generate image
    result = await generate_image(prompt=prompt, current_user=current_user, 
                              chat_input=chat_input_obj, command_type=matched_command)
```

#### Video Generation (Luma AI + Replicate)
**Location**: `sceneXtras/api/router/gpt_chat_router.py:1384`

```python
# Luma AI integration
luma_client = LumaClient(auth_token=luma_api_key)
generation = luma_client.generations.create(
    prompt=video_prompt,
    keyframes={"frame0": {"type": "image", "url": public_url}},
    aspect_ratio="16:9",
    loop=False,
    model="ray-2",
    resolution="720p",
    duration="5s",
)

# Replicate WAN video fallback
replicate_client = replicate.Client(api_token=replicate_api_key)
output = replicate_client.run(
    "wan-video/wan-2.2-i2v-fast",
    input={
        "image": public_url,
        "prompt": video_prompt,
        "go_fast": True,
        "num_frames": 81,
        "resolution": "480p",
    },
)
```

### Audio & Voice Features

#### Transcription Services
**Location**: `sceneXtras/api/router/gpt_chat_router.py:1796`

```python
async def transcribe_and_chat():
    # OpenAI Whisper for transcription
    transcript = await getOpenAITranscription(local_audio_path, chat_input)
    
    # Voice synthesis options
    if found:  # Robert Downey Jr. detection
        await getPlayHTTTS(chatbot_response, local_mp3_path)
    elif voice_id and await isUserMAX(current_user):
        await getElevenLabsTTS(chatbot_response, local_mp3_path, voice_id)
    else:
        await getOpenAITTS(chatbot_response, gender, local_mp3_path)
```

## 2. React Web Frontend

### Chat Component Architecture
**Location**: `frontend_webapp/src/components/chat/Chat.tsx:1`

#### Key Features:
- **Multi-Chat Support**: Multiple characters in conversation
- **Real-time Messaging**: WebSocket connections
- **Media Handling**: Image/video uploads and generation
- **Voice Chat**: Audio recording and TTS playback
- **Export Functionality**: Social media sharing

#### State Management (Zustand)
```typescript
// Character Store
interface CharacterStore {
  characters: Cast[];
  selectedCharacter: Cast | null;
  recentCharacters: string[];
  // Actions
  setCharacters: (characters: Cast[]) => void;
  selectCharacter: (character: Cast) => void;
}

// Auth Store
interface AuthStore {
  user: AuthenticatedUser | null;
  isAuthenticated: boolean;
  subscription: 'FREE' | 'PRO' | 'MAX';
  // Actions
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}
```

### API Client Integration
**Location**: `frontend_webapp/src/api/apiClient.ts`

```typescript
// Main chat API call
export const talkWithEntity = async (
  chatInput: ChatInput,
  introduction: boolean = false,
  groupChatData?: GroupChatData,
  imageFile?: File
): Promise<ChatResponse> => {
  const formData = new FormData();
  formData.append('chat_input', JSON.stringify(chatInput));
  formData.append('introduction', introduction.toString());
  
  if (groupChatData) {
    formData.append('json_data', JSON.stringify(groupChatData));
  }
  
  if (imageFile) {
    formData.append('file', imageFile);
  }
  
  const response = await fetch(`${API_BASE_URL}/talk_with`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'X-Session-Token': sessionToken,
      'user_identifier': userId,
    },
    body: formData,
  });
  
  return response.json();
};
```

## 3. Go Search Engine

### High-Performance Search
**Location**: `golang_search_engine/internal/handlers/`

#### Search Endpoint:
```go
func SearchHandler(w http.ResponseWriter, r *http.Request) {
    query := r.URL.Query().Get("q")
    if query == "" {
        http.Error(w, "Query parameter 'q' is required", http.StatusBadRequest)
        return
    }
    
    // Multi-dimensional search
    results := searchService.Search(query, searchOptions{
        exact:      r.URL.Query().Get("exact") == "true",
        prefix:     r.URL.Query().Get("prefix") == "true", 
        substring:  r.URL.Query().Get("substring") == "true",
        fuzzy:      r.URL.Query().Get("fuzzy") == "true",
    })
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(results)
}
```

#### TMDB Integration
```go
func (s *SearchService) initializeFromTMDB() error {
    // Fetch popular movies
    resp, err := http.Get("https://api.themoviedb.org/3/movie/popular")
    if err != nil {
        return err
    }
    
    // Cache in BadgerDB
    for _, movie := range movies {
        s.trie.Insert(movie.Title, movie)
        s.db.Set([]byte(movie.ID), movieData)
    }
    
    return nil
}
```

## 4. Automation Framework

### Playwright Bot Automation
**Location**: `automations/examples/scenextras_automation_working.js`

#### Core Automation Flow:
```javascript
async function run() {
  const browser = await chromium.launch({ headless: HEADLESS });
  const context = await browser.newContext({
    ...devices['iPhone 15 Pro'],
    viewport: { width: 393, height: 852 },
  });
  const page = await context.newPage();
  
  // 1. Login automation
  await page.goto('https://test.scenextras.com/profile?login_view=password');
  await page.fill('input[type="email"]', EMAIL);
  await page.fill('input[type="password"]', PASSWORD);
  await page.locator('form:has(input[type="password"]) button[type="submit"]').click();
  
  // 2. Navigate to character
  await page.goto(`https://test.scenextras.com/chat/animes/one-punch-man`);
  
  // 3. Character selection
  const characterSelectors = [
    'img[alt*="Saitama" i]',
    'div:has-text("Saitama")',
    'a:has-text("Saitama")'
  ];
  
  // 4. Chat interaction
  await page.fill('input[placeholder*="Always wanted"]', 'can you buy me pads?');
  await page.keyboard.press('Enter');
  
  // 5. Response capture
  await page.waitForTimeout(8000);
  const pageContent = await page.content();
}
```

### Configuration System
**Location**: `automations/scenextras_config.json`

```json
{
  "sources": {
    "anime": {
      "one-punch-man": {
        "name": "One Punch Man",
        "url": "https://test.scenextras.com/chat/animes/one-punch-man-2015",
        "characters": ["Saitama", "Genos", "Garou", "Tatsumaki"]
      }
    }
  },
  "viralMessages": [
    "can you buy me pads?",
    "what's your credit score?",
    "my ex just texted me 'hey', what do I do?"
  ],
  "conversationProfiles": {
    "viral": {
      "model": "creative",
      "intro": false,
      "followup": 0,
      "actionLines": 1
    }
  }
}
```

## 5. Key API Endpoints Summary

### Core Chat Endpoints
- `POST /talk_with` - Main chat with multipart support
- `POST /talk_with_new` - Simplified chat endpoint
- `POST /talk_with_multi` - Multi-chat support
- `POST /transcribe_and_chat` - Audio transcription + chat

### Character & Content Endpoints
- `GET /autocomplete` - Character/show autocomplete
- `GET /resources/movies` - Movie database
- `GET /resources/series` - TV series database
- `GET /resources/anime` - Anime database
- `GET /resources/cartoons` - Cartoon database

### User Management Endpoints
- `POST /rating` - Character rating system
- `GET /user_tokens` - User session management
- `POST /fetch_new_messages` - Message synchronization
- `GET /example-questions` - Prompt suggestions

### Image & Media Endpoints
- `POST /generate_image` - AI image generation
- `GET /image/{filename}` - Image serving
- `POST /animate` - Video generation from images

## 6. Database Schema

### Supabase Integration
**Tables**:
- `users` - User accounts and subscriptions
- `conversations` - Chat history and sessions
- `movies` - Movie/show metadata
- `characters` - Character information
- `ratings` - User ratings
- `messages` - Individual chat messages

### Key Models
**Location**: `sceneXtras/api/model/models.py`

```python
class User(Base):
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True)
    premium = Column(Integer, default=0)  # 0=FREE, 1=PRO, 2=MAX
    quota = Column(Integer, default=10)  # Daily message limit
    stripe_customer_id = Column(String, nullable=True)

class Movie(Base):
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    universe = Column(Text, nullable=False)  # Plot/setting description
    genres = Column(JSON, nullable=False)  # Array of genres
    characters = Column(JSON, nullable=False)  # Embedded character data

class Character(Base):
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    movie_id = Column(String, ForeignKey("movies.id"), nullable=False)
    age = Column(Integer, nullable=True)
    backstory = Column(Text, nullable=False)
    skills_abilities = Column(JSON, nullable=False)
```

## 7. Replication Strategy

### Environment Setup
```bash
# Backend Setup
cd sceneXtras/api
poetry install
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export TMDB_API_KEY="your-tmdb-key"
export SUPABASE_URL="your-supabase-url"
export SUPABASE_KEY="your-supabase-key"

# Frontend Setup  
cd frontend_webapp
yarn install
export REACT_APP_API_URL="http://localhost:8080"
export REACT_APP_SUPABASE_URL="your-supabase-url"
export REACT_APP_SUPABASE_ANON_KEY="your-supabase-anon-key"

# Search Engine Setup
cd golang_search_engine
make quickstart  # Builds, runs, and initializes with sample data
export TMDB_API_KEY="your-tmdb-key"

# Mobile App Setup
cd mobile_app_sx
bun install
./run.sh --web  # Web development (recommended)
```

### Core API Calls to Replicate

#### 1. Character Chat Flow
```python
# Backend: Handle chat request
POST /talk_with
{
  "chat_input": {
    "character": "Saitama",
    "series": "One Punch Man", 
    "message": "can you buy me pads?",
    "config": {
      "model_choice": "creative",
      "tone": "neutral",
      "theme": "default"
    }
  },
  "introduction": false
}

# AI Model Call (Claude)
response = anthropic_client.messages.create(
    model="claude-3-5-haiku-latest",
    temperature=0.7,
    system=character_context_prompt,
    max_tokens=1000,
    messages=[{"role": "user", "content": user_message}],
)
```

#### 2. Image Generation Flow
```python
# Image Generation Request
POST /generate_image
{
  "prompt": "Saitama buying pads",
  "style": "anime",
  "model": "dall-e-3"
}

# Backend API Call to Image Service
image_response = openai_client.images.generate(
    model="dall-e-3",
    prompt=prompt,
    size="1024x1024",
    quality="standard",
)
```

#### 3. Search Integration
```go
// Go Search Engine Call
GET /api/search?q=one+punch+man

// TMDB API Integration
GET https://api.themoviedb.org/3/search/movie?query=one%20punch%20man
{
  "results": [
    {
      "id": 207703,
      "title": "One-Punch Man",
      "release_date": "2015-10-05",
      "overview": "The story follows Saitama..."
    }
  ]
}
```

### Automation Replication
```javascript
// Playwright Automation
node scenextras_automation_pro.js --genre anime --show "one-punch-man" --character saitama --message "can you buy me pads?"

// N8N Workflow Integration
import scenextras_viral_reply_screenshots.workflow.json
// Configure:
// - Browserless.io for headless browsing
// - Webhook endpoints for chat triggering
// - Screenshot capture for viral content
```

## 8. Monetization & Quota System

### Subscription Tiers
- **FREE**: 10 messages/day, basic models only
- **PRO**: 100 messages/day, premium models, image generation
- **MAX**: Unlimited messages, all features, voice cloning

### Quota Enforcement
```python
# Backend quota checks
if current_user.quota <= 0 and not await isUserPRO(current_user):
    raise HTTPException(status_code=403, detail="QUOTA_EXCEEDED")

if verify_model_selection(model, "creative"):
    if await getCurrentUserPremiumModelQuota(current_user) <= 0:
        raise HTTPException(status_code=403, detail="PREMIUM_MODEL_QUOTA_EXCEEDED")
```

## 9. Security & Authentication

### JWT Token System
```python
# Authentication flow
@router.post("/login")
async def login(email: str, password: str):
    user = authenticate_user(email, password)
    if user:
        access_token = create_access_token(data={"sub": user.id})
        return {"access_token": access_token, "token_type": "bearer"}
```

### API Key Management
```python
# Environment-based API keys
api_keys = {
    "openai": os.getenv("OPENAI_API_KEY"),
    "anthropic": os.getenv("ANTHROPIC_API_KEY"), 
    "google": os.getenv("GOOGLE_GENAI_API_KEY"),
    "tmdb": os.getenv("TMDB_API_KEY"),
    "supabase": os.getenv("SUPABASE_KEY"),
}
```

## 10. Performance & Scaling

### Caching Strategy
- **Redis**: Session management and real-time data
- **BadgerDB**: Search index persistence
- **Azure Blob**: Media file storage and CDN
- **Memory Caching**: Character context and prompts

### Monitoring & Analytics
```python
# PostHog integration
posthog.capture(user_id, 'chat_completion', properties={
    'model': model_used,
    'character': character_name,
    'tokens_used': total_tokens,
    'response_time_ms': response_time,
    'cost': cost
})

# Sentry error tracking
Sentry.capture_exception(exception)
```

## Conclusion

The SceneXtras bot is a comprehensive character conversation platform that combines:

1. **Multi-Model AI Integration** - OpenAI, Anthropic, Google, DeepSeek
2. **Rich Character Context** - TMDB, Wikipedia, community database
3. **Advanced Features** - Multi-chat, image/video generation, voice synthesis
4. **Scalable Architecture** - Microservices, caching, CDN
5. **Monetization System** - Tiered subscriptions with quota management
6. **Automation Support** - Playwright bots for content creation

The system processes millions of character conversations through a sophisticated pipeline of authentication, context retrieval, AI generation, and response delivery, all while maintaining character consistency and user engagement through viral content optimization.

**Key Success Factors**:
- Real-time character context from multiple sources
- Flexible AI model selection with fallbacks  
- Comprehensive media handling (images, video, audio)
- Mobile-first responsive design
- Robust automation framework for content creators
- Scalable microservices architecture

This architecture can be replicated by implementing the core components: authentication system, AI model integration, character database, search functionality, and responsive frontend with real-time capabilities.