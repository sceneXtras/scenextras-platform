# SceneXtras System Architecture - Business Flow Diagrams

This document provides a comprehensive view of the SceneXtras ecosystem, showing how all services interact to deliver the core product: AI-powered character conversations.

**Generated**: January 14, 2026

---

## 1. System Overview - All Services

```mermaid
graph TB
    subgraph Clients["Client Applications"]
        WEB["React Web App<br/>frontend_webapp<br/>:3000"]
        MOBILE["React Native App<br/>mobile_app_sx<br/>Expo"]
        BACKOFFICE["Admin Panel<br/>website-backoffice<br/>Internal"]
    end

    subgraph Gateway["API Gateway Layer"]
        GATEWAY["Go Auth Gateway<br/>golang_auth_gateway<br/>:8080<br/>JWT Validation + Quota"]
    end

    subgraph Backend["Backend Services"]
        API["Python FastAPI<br/>sceneXtras/api<br/>:8080<br/>AI Chat + Business Logic"]
        SEARCH["Go Search Engine<br/>golang_search_engine<br/>:8080<br/>Autocomplete + Content"]
    end

    subgraph Data["Data Layer"]
        SUPABASE["Supabase<br/>Auth + PostgreSQL"]
        REDIS["Redis<br/>Caching"]
        BADGER["BadgerDB<br/>Search Index"]
    end

    subgraph External["External Services"]
        LLM["AI Models<br/>Claude, GPT, Gemini<br/>DeepSeek, Groq"]
        TMDB["TMDB API<br/>Movie/TV Data"]
        STRIPE["Stripe<br/>Payments"]
        POSTHOG["PostHog<br/>Analytics + Flags"]
        REVENUECAT["RevenueCat<br/>Subscriptions"]
    end

    subgraph Automation["Automation"]
        N8N["n8n Workflows<br/>E2E Testing<br/>Content Automation"]
    end

    WEB --> GATEWAY
    MOBILE --> GATEWAY
    BACKOFFICE --> API

    GATEWAY -->|"/api/chat/*"| API
    GATEWAY -->|"/api/search/*"| SEARCH

    API --> SUPABASE
    API --> REDIS
    API --> LLM
    API --> STRIPE

    SEARCH --> BADGER
    SEARCH --> TMDB

    WEB --> POSTHOG
    MOBILE --> POSTHOG
    MOBILE --> REVENUECAT

    N8N --> API
    N8N --> WEB

    style Gateway fill:#ff6b6b
    style Backend fill:#4ecdc4
    style Data fill:#45b7d1
    style External fill:#96ceb4
    style Clients fill:#ffeaa7
```

---

## 2. User Journey - From Launch to First Chat

```mermaid
stateDiagram-v2
    [*] --> AppLaunch: User opens app

    AppLaunch --> CheckSession: Check Supabase session

    CheckSession --> HasSession: Session found?

    HasSession -->|No| LoginScreen: Show login options
    LoginScreen --> AuthMethod: User chooses

    AuthMethod --> EmailAuth: Email/Password
    AuthMethod --> GoogleOAuth: Google OAuth
    AuthMethod --> AppleOAuth: Apple OAuth
    AuthMethod --> FacebookOAuth: Facebook OAuth

    EmailAuth --> ValidateCredentials: POST to Supabase
    GoogleOAuth --> ValidateCredentials
    AppleOAuth --> ValidateCredentials
    FacebookOAuth --> ValidateCredentials

    ValidateCredentials --> AuthFailed: Invalid credentials
    AuthFailed --> LoginScreen

    ValidateCredentials --> AuthSuccess: Valid token
    AuthSuccess --> FetchUserConfig: GET /api/user/config

    HasSession -->|Yes| FetchUserConfig

    FetchUserConfig --> CheckOnboarding: is_onboarded?

    CheckOnboarding -->|No| OnboardingFlow: 10-21 screens
    OnboardingFlow --> CompleteOnboarding: All steps done
    CompleteOnboarding --> MarkOnboarded: PUT /api/user/config
    MarkOnboarded --> HomePage

    CheckOnboarding -->|Yes| HomePage: Show search/browse

    HomePage --> SearchCharacter: User searches
    SearchCharacter --> SearchEngine: GET /api/search?q=...
    SearchEngine --> SearchResults: Return matches
    SearchResults --> SelectCharacter: User picks character

    SelectCharacter --> InitChat: Open chat screen
    InitChat --> LoadHistory: GET /api/messages/:characterId
    LoadHistory --> ChatReady: Messages loaded

    ChatReady --> SendMessage: User types message
    SendMessage --> GatewayCheck: Auth Gateway validates

    GatewayCheck --> QuotaCheck: Check user quota
    QuotaCheck --> QuotaOK: Has credits?

    QuotaOK -->|No| ShowPaywall: 402 - Upgrade modal
    ShowPaywall --> PurchaseFlow: User buys credits
    PurchaseFlow --> QuotaRefilled: Credits added
    QuotaRefilled --> SendMessage

    QuotaOK -->|Yes| CallLLM: Stream to AI model
    CallLLM --> ReceiveResponse: Character replies
    ReceiveResponse --> DisplayMessage: Show in chat
    DisplayMessage --> ChatReady: Ready for next

    ChatReady --> [*]: User exits
```

---

## 3. High-Trust Security Model - Request Flow

```mermaid
sequenceDiagram
    participant Client as Client App
    participant Gateway as Go Auth Gateway
    participant Backend as Python API
    participant DB as Supabase DB
    participant LLM as AI Model

    Client->>Gateway: POST /api/chat/message<br/>Authorization: Bearer {JWT}

    Gateway->>Gateway: Validate JWT<br/>(ES256 JWKS or HS256)

    alt Invalid Token
        Gateway-->>Client: 401 Unauthorized
    end

    Gateway->>Gateway: Extract user_id from claims
    Gateway->>DB: Check quota (SELECT credits)

    alt Quota Exhausted
        Gateway-->>Client: 402 Payment Required
    end

    Gateway->>Backend: Proxy request with headers<br/>X-User-Id: {user_id}<br/>X-Quota-Remaining: {credits}<br/>X-Request-Id: {uuid}

    Note over Backend: Backend TRUSTS headers<br/>No re-validation needed

    Backend->>LLM: Stream message with system prompt
    LLM-->>Backend: AI response chunks
    Backend->>DB: Deduct credits, log message
    Backend-->>Gateway: Response with character message
    Gateway-->>Client: 200 OK + response
```

---

## 4. Search Engine Flow - Character Discovery

```mermaid
stateDiagram-v2
    [*] --> UserTyping: User types in search

    UserTyping --> Normalize: Lowercase, trim
    Normalize --> CacheCheck: Check LRU cache

    CacheCheck --> CacheHit: Found?

    CacheHit -->|Yes| ReturnCached: Return (5min TTL)
    ReturnCached --> DisplayResults

    CacheHit -->|No| LoadIndex: Load SearchableIndex
    LoadIndex --> DualSearch: Execute search

    state DualSearch {
        [*] --> PrefixTrie: Prefix matching
        [*] --> TokenIndex: Token lookup
        PrefixTrie --> Merge
        TokenIndex --> Merge
    }

    DualSearch --> RankResults: Score by popularity
    RankResults --> FuzzyMatch: 70% similarity
    FuzzyMatch --> FilterType: Filter by entity type
    FilterType --> StoreCache: Cache results
    StoreCache --> DisplayResults

    DisplayResults --> ShowCharacters: Movies, Series, Anime
    ShowCharacters --> UserSelects: Tap character
    UserSelects --> OpenChat: Navigate to chat
    OpenChat --> [*]
```

---

## 5. Payment & Subscription Flow

```mermaid
stateDiagram-v2
    [*] --> FreeUser: New user

    FreeUser --> UseCredits: Chat consumes credits
    UseCredits --> CheckCredits: Credits remaining?

    CheckCredits -->|Yes| ContinueChat: Keep chatting
    ContinueChat --> UseCredits

    CheckCredits -->|No| TriggerPaywall: Show upgrade modal

    TriggerPaywall --> ViewPlans: User browses
    ViewPlans --> SelectPlan: Choose tier

    state SelectPlan {
        [*] --> Creator: $2.99/week or $99.99/year
        [*] --> Pro: $3.99/week or $149.99/year
        [*] --> Max: $5.99/week or $249.99/year
    }

    SelectPlan --> InitiatePayment: Tap Subscribe

    state InitiatePayment {
        [*] --> WebStripe: Web: Stripe Checkout
        [*] --> MobileRevenueCat: Mobile: RevenueCat
    }

    InitiatePayment --> ProcessPayment: Payment processing
    ProcessPayment --> PaymentResult: Success/Failure

    PaymentResult -->|Failed| RetryPayment: Show retry
    RetryPayment --> InitiatePayment

    PaymentResult -->|Success| UpdateSubscription: Sync status
    UpdateSubscription --> RefillCredits: Reset quota
    RefillCredits --> PremiumUser: Unlimited chats
    PremiumUser --> ContinueChat
```

---

## 6. Multi-Model AI Chat Architecture

```mermaid
graph TB
    subgraph Request["Incoming Chat Request"]
        MSG["User Message<br/>+ Character Context<br/>+ Model Preference"]
    end

    subgraph Router["Model Router"]
        ROUTER["Python FastAPI<br/>Model Selection Logic"]
    end

    subgraph Models["AI Model Providers"]
        CLAUDE["Claude<br/>Anthropic API<br/>claude-3-opus<br/>claude-3-sonnet"]
        GPT["GPT-4<br/>OpenAI / Azure<br/>gpt-4o<br/>gpt-4o-mini"]
        GEMINI["Gemini<br/>Google AI<br/>gemini-1.5-pro<br/>gemini-1.5-flash"]
        DEEPSEEK["DeepSeek<br/>DeepSeek API<br/>deepseek-chat"]
        GROQ["Groq<br/>Groq Cloud<br/>llama-3-70b<br/>mixtral-8x7b"]
    end

    subgraph Selection["Selection Criteria"]
        TIER["User Tier<br/>Free → Basic models<br/>Premium → All models"]
        LATENCY["Latency Requirements<br/>Fast → Groq/Gemini Flash<br/>Quality → Claude/GPT-4"]
        COST["Cost Optimization<br/>Track per-message cost<br/>Balance quality/cost"]
    end

    MSG --> ROUTER
    ROUTER --> TIER
    ROUTER --> LATENCY
    ROUTER --> COST

    TIER --> CLAUDE
    TIER --> GPT
    TIER --> GEMINI
    TIER --> DEEPSEEK
    TIER --> GROQ

    CLAUDE --> RESPONSE["Streamed Response"]
    GPT --> RESPONSE
    GEMINI --> RESPONSE
    DEEPSEEK --> RESPONSE
    GROQ --> RESPONSE

    style Models fill:#4ecdc4
    style Selection fill:#ffeaa7
```

---

## 7. Data Sync Pipeline - TMDB to Search

```mermaid
flowchart TD
    TRIGGER["Scheduled Sync<br/>or Manual Trigger"] --> FETCH["Fetch from TMDB API"]

    FETCH --> MOVIES["GET /movie/popular<br/>Paginate all pages"]
    FETCH --> SERIES["GET /tv/popular<br/>Paginate all pages"]
    FETCH --> ANIME["MAL API<br/>Anime data"]

    MOVIES --> CREDITS["Fetch credits/cast<br/>for each movie"]
    SERIES --> CREDITS

    CREDITS --> TRANSFORM["Transform to Entity<br/>- ID, Name, Type<br/>- Popularity score<br/>- Cast metadata"]
    ANIME --> TRANSFORM

    TRANSFORM --> STORE["Store in BadgerDB<br/>Key: entity_{type}_{id}"]

    STORE --> BUILD["Build Search Indexes"]

    BUILD --> TRIE["Prefix Trie<br/>Insert all names + aliases"]
    BUILD --> TOKEN["Token Index<br/>Inverted index by word"]

    TRIE --> SERIALIZE["Serialize to disk<br/>trie.gob"]
    TOKEN --> SERIALIZE

    SERIALIZE --> SWAP["Atomic Swap<br/>atomic.Value.Store()"]

    SWAP --> INVALIDATE["Invalidate Query Cache<br/>Clear LRU"]

    INVALIDATE --> READY["Search Engine Ready<br/>Sub-30ms queries"]

    style TRIGGER fill:#ff6b6b
    style TRANSFORM fill:#4ecdc4
    style SWAP fill:#45b7d1
    style READY fill:#00b894
```

---

## 8. Mobile App State Management

```mermaid
graph TB
    subgraph Stores["Zustand Stores"]
        AUTH["authStore<br/>- session<br/>- user<br/>- isAuthenticated"]
        USER["userStore<br/>- profile<br/>- credits<br/>- preferences"]
        CHAR["characterStore<br/>- selected character<br/>- favorites<br/>- recent"]
        MSG["messageStore<br/>- chat history<br/>- pending messages<br/>- local cache"]
        UI["uiStore<br/>- modals<br/>- themes<br/>- loading states"]
    end

    subgraph Persistence["Persistence Layer"]
        MMKV["MMKV<br/>Fast KV storage<br/>Auth + User data"]
        ASYNC["AsyncStorage<br/>Messages<br/>Large data"]
    end

    subgraph Sync["Sync Strategy"]
        LAUNCH["App Launch<br/>→ Fetch consolidated user data"]
        CHAT["Send Message<br/>→ Optimistic update + API call"]
        PURCHASE["Purchase<br/>→ RevenueCat + Backend sync"]
    end

    AUTH --> MMKV
    USER --> MMKV
    CHAR --> ASYNC
    MSG --> ASYNC

    LAUNCH --> AUTH
    LAUNCH --> USER
    CHAT --> MSG
    CHAT --> USER
    PURCHASE --> USER

    style Stores fill:#a29bfe
    style Persistence fill:#74b9ff
```

---

## 9. E2E Testing & Automation Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant N8N as n8n Workflow
    participant BL as Browserless
    participant SX as SceneXtras App
    participant MCP as Reddit MCP
    participant Reddit as Reddit API

    Dev->>N8N: Trigger E2E test<br/>run-e2e-via-n8n.cjs

    N8N->>N8N: Activate webhook<br/>(Playwright automation)

    N8N->>BL: Execute browser automation

    BL->>SX: 1. Login with test credentials
    SX-->>BL: Session established

    BL->>SX: 2. Navigate to character page
    SX-->>BL: Page loaded

    BL->>SX: 3. Select character + send message
    SX-->>BL: AI response received

    BL->>BL: 4. Capture screenshot (base64)
    BL-->>N8N: Return screenshot + response

    N8N->>MCP: Connect via SSE
    MCP-->>N8N: Session established

    N8N->>MCP: reddit_submit_post<br/>{subreddit, title, image}
    MCP->>Reddit: POST /api/submit
    Reddit-->>MCP: Post URL
    MCP-->>N8N: Success response

    N8N-->>Dev: Test complete<br/>Reddit post URL
```

---

## 10. Feature Flag Architecture

```mermaid
graph TB
    subgraph PostHog["PostHog Feature Flags"]
        FLAGS["Feature Flags Dashboard"]
    end

    subgraph Integration["Integration Points"]
        REACT["React/React Native<br/>useFeatureFlagEnabled()"]
        PYTHON["Python API<br/>is_feature_enabled()"]
    end

    subgraph FlagTypes["Flag Types"]
        FEATURE["feature_*<br/>New features<br/>Default: OFF"]
        EXPERIMENT["experiment_*<br/>A/B tests<br/>Percentage rollout"]
        KILL["kill_switch_*<br/>Emergency disable<br/>Default: OFF"]
    end

    subgraph Examples["Current Flags"]
        F1["feature_new_chat_ui"]
        F2["feature_group_chat"]
        F3["feature_video_export"]
        F4["experiment_onboarding_v2"]
        F5["kill_switch_payments"]
    end

    FLAGS --> REACT
    FLAGS --> PYTHON

    REACT --> FEATURE
    REACT --> EXPERIMENT
    PYTHON --> FEATURE
    PYTHON --> KILL

    FEATURE --> F1
    FEATURE --> F2
    FEATURE --> F3
    EXPERIMENT --> F4
    KILL --> F5

    style PostHog fill:#6c5ce7
    style FlagTypes fill:#ffeaa7
```

---

## Service Communication Matrix

| Source | Destination | Protocol | Purpose |
|--------|-------------|----------|---------|
| Web App | Auth Gateway | HTTPS | All API requests |
| Mobile App | Auth Gateway | HTTPS | All API requests |
| Auth Gateway | Python API | HTTP | Chat, user operations |
| Auth Gateway | Go Search | HTTP | Search queries |
| Python API | Supabase | PostgreSQL | User data, messages |
| Python API | Redis | Redis Protocol | Caching |
| Python API | LLM APIs | HTTPS | AI responses |
| Go Search | BadgerDB | Embedded | Search index |
| Go Search | TMDB | HTTPS | Content sync |
| Mobile App | RevenueCat | SDK | Subscriptions |
| All Apps | PostHog | HTTPS | Analytics + Flags |
| n8n | All Services | HTTP/WS | E2E Testing |

---

## Port Assignments

| Service | Port | Environment |
|---------|------|-------------|
| Auth Gateway | 8080 | Production proxy |
| Python API | 8080 | Internal |
| Go Search | 8080 | Internal |
| Web App | 3000 | Development |
| n8n | 5678 | Automation |
| Redis | 6379 | Cache |
| PostgreSQL | 5432 | Database |

---

## Key Architecture Decisions

1. **High-Trust Security Model**: Gateway validates once, backends trust injected headers
2. **Multi-Model AI**: Route to different LLMs based on tier, latency, cost
3. **Dual Search Strategy**: Prefix Trie + Token Index for sub-30ms queries
4. **Atomic Index Updates**: Zero-downtime search index swaps
5. **Quota at Gateway**: Check credits before proxying to prevent abuse
6. **Feature Flags Everywhere**: All new features wrapped in PostHog flags
7. **Mobile-First State**: MMKV for fast persistence, Zustand for state management
8. **E2E Automation**: n8n orchestrates browser automation + social posting

---

## Repository Links

| Repository | Purpose | Key Files |
|------------|---------|-----------|
| `sceneXtras/api` | Python FastAPI backend | `CLAUDE.md`, `Makefile` |
| `frontend_webapp` | React web application | `CLAUDE.md`, `package.json` |
| `golang_search_engine` | Go search service | `CLAUDE.md`, `API_DOCUMENTATION.md` |
| `golang_auth_gateway` | Go auth gateway | `CLAUDE.md`, `TESTING.md` |
| `mobile_app_sx` | React Native mobile | `CLAUDE.md`, `ONBOARDING_SETUP.md` |
| `website-backoffice` | Admin panel | `src/pages/` |
| `automations` | E2E testing, n8n | `run-e2e-via-n8n.cjs` |

---

## Document Index

Each repository contains detailed business flow diagrams:

- `golang_auth_gateway/docs/BUSINESS_FLOWS.md` - Auth, routing, quota flows
- `golang_search_engine/docs/BUSINESS_FLOWS.md` - Search, caching, sync flows
- `frontend_webapp/docs/BUSINESS_FLOWS.md` - User journeys, payment, onboarding
- `mobile_app_sx/docs/BUSINESS_FLOWS.md` - Mobile app flows, subscriptions
- `website-backoffice/docs/BUSINESS_FLOWS.md` - Admin operations
- `automations/docs/BUSINESS_FLOWS.md` - E2E testing, n8n workflows

---

**Status**: Complete
**Last Updated**: January 14, 2026
