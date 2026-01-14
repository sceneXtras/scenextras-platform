# SceneXtras Microservices Architecture Plan

**Date:** January 2025
**Purpose:** Complete architectural analysis and microservices migration strategy
**Current Stack:** Python FastAPI backend, React Web, React Native Mobile, Go Search Engine, Supabase, Dokku hosting

---

## Table of Contents

1. [Current Application Analysis](#current-application-analysis)
2. [Core Functionalities](#core-functionalities)
3. [Key User Flows](#key-user-flows)
4. [Primary Use Cases](#primary-use-cases)
5. [Microservices Architecture Design](#microservices-architecture-design)
6. [Database Strategy](#database-strategy)
7. [Authentication Strategy](#authentication-strategy)
8. [Data Consistency Patterns](#data-consistency-patterns)
9. [Dokku Implementation](#dokku-implementation)
10. [Migration Strategy](#migration-strategy)
11. [Code Examples](#code-examples)
12. [Deployment Guide](#deployment-guide)

---

## Current Application Analysis

### Overview
SceneXtras is a multi-service application ecosystem for interactive movie/TV character conversations and content discovery consisting of:

1. **Python API Backend** (`sceneXtras/api/`) - FastAPI service (~20K+ lines)
2. **React Web Frontend** (`frontend_webapp/`) - React 18+ TypeScript SPA
3. **React Native Mobile App** (`mobile_app_sx/`) - Expo-based cross-platform app
4. **Go Search Engine** (`golang_search_engine/`) - High-performance autocomplete service

### Backend Architecture (Python FastAPI)

#### Key Modules
- `auth/` - Authentication, JWT tokens, user management
- `chat/` - AI chat service with multiple LLM providers
- `router/` - API route handlers (~20K+ lines)
- `model/` - Database models (SQLAlchemy)
- `db/` - Database operations and Supabase integration
- `services/` - Business logic services
- `middleware/` - Request/response middleware
- `external_api/` - Third-party API integrations

#### Database
- PostgreSQL via Supabase with Alembic migrations
- Redis caching layer
- Supabase Auth integration

#### External Integrations (15+ services)
- **LLM Providers:** Anthropic (Claude), OpenAI (GPT), Groq, Google (Gemini), DeepSeek
- **Content APIs:** TMDB, TVDB, Wikipedia, Perplexity
- **Payments:** Stripe, RevenueCat
- **Storage:** Azure Blob Storage
- **Email:** SendGrid
- **Monitoring:** Sentry, PostHog
- **Auth:** Firebase Admin, Supabase Auth

#### API Endpoints (Major Routes)

**Authentication** (`/api/auth/*`)
- Login/signup, OAuth (Google, Apple, Facebook)
- JWT token management
- User profile management
- Referral system

**Chat System** (`/api/chat/*`)
- One-on-one character conversations
- Group/multi-character chats
- Message history, pinning, likes/dislikes
- Voice chat (transcription + TTS)
- Image understanding (vision models)

**Payments** (`/api/payments/*`)
- Stripe checkout sessions
- Subscription management (upgrade/downgrade/cancel)
- Webhook handling
- Billing portal

**Content Discovery** (`/api/resources/*`, `/api/autocomplete/*`)
- Movie/series/anime/cartoon search
- Character search and filtering
- Actor filmography
- Popular content recommendations

**Media** (`/api/images/*`)
- Image generation (Gemini, Imagen)
- Image recognition/analysis
- Image storage and retrieval

**Community** (`/api/story/*`)
- Story creation and publishing
- Fandom rooms
- Scenario library
- User-generated content

**Analytics** (`/api/analytics/*`)
- User statistics
- Conversation analytics
- Platform-wide metrics

### Frontend Web Architecture (React)

#### State Management
- **Zustand Stores:** Auth, modals, onboarding, character, room, story wizard
- **React Query:** Server state with 5-30 min stale times
- **Context Providers:** Hybrid messaging system, Novu notifications

#### Key Features
- Character discovery with search and filtering
- Real-time chat with AI characters
- Premium subscription management (Stripe)
- User gamification (daily streaks, achievements, XP)
- Story creation wizard
- Fandom rooms (collaborative spaces)
- Voice chat support
- Conversation exports and sharing

#### Technology Stack
- React 18+ with TypeScript
- Material UI + Chakra UI hybrid
- TanStack Query (React Query)
- Zustand for global state
- Framer Motion + GSAP animations
- Axios for API calls
- Supabase SDK for auth
- IndexedDB for local caching

### Mobile App Architecture (React Native)

#### State Management (24 Zustand Stores)
- `authStore` - Session management, OAuth
- `userStore` - Profile, credits, subscriptions
- `messageStore` - Message persistence, quota management
- `characterStore` - Character data, favorites
- `scenarioStore` - Scenario library
- MMKV + AsyncStorage for persistence

#### Key Features
- Offline-capable chat with local persistence
- Image caching system (87% cache hit rate, 70% data savings)
- Expo Router (file-based navigation)
- Mixpanel analytics
- RevenueCat + Superwall paywalls
- Platform-specific optimizations

#### Technology Stack
- React Native with Expo SDK 54
- NativeWind (Tailwind CSS)
- Zustand + MMKV storage
- Supabase for auth
- TypeScript (strict mode)

### Go Search Engine

#### Architecture
- Trie-based autocomplete engine
- BadgerDB for persistent storage
- Multi-dimensional search (exact, prefix, substring, fuzzy)
- Levenshtein distance for typo tolerance
- Sub-30ms response times (10x faster than SQLite)

#### Features
- Real-time TMDB/TVDB data sync
- Multi-tier caching
- No mock data fallback
- Health check endpoints

---

## Core Functionalities

### 1. AI Character Conversations 🎭
**The heart of SceneXtras** - Users can have realistic conversations with movie/TV characters.

**Key Components:**
- Multi-provider LLM routing (Claude, GPT-4o, Gemini, Groq, DeepSeek)
- Context injection (TMDB + Wikipedia data)
- Conversation history with 12K-64K token limits (tier-based)
- Real-time streaming responses
- Message persistence (Supabase + local cache)

**Features:**
- One-on-one character conversations
- Group/multi-character chats
- Voice chat (audio input/output with transcription & TTS)
- Image understanding (vision models)
- Rich media messaging (text, images, video, audio)
- Message editing, pinning, deletion
- Follow-up question suggestions
- Conversation exports and sharing

### 2. Content Discovery & Search 🔍
**Character discovery from movies, TV shows, anime, and cartoons**

**Backend:**
- TMDB/TVDB API integration with intelligent caching
- Wikipedia integration for character backgrounds
- Community content (user-created characters/universes)

**Frontend:**
- Character carousels and grids
- Actor filmography browsing
- Search filtering by content type
- Popular content recommendations

**Mobile:**
- Lazy-loaded character grids
- Cached image system
- Offline content browsing

### 3. Tiered Subscription System 💳
**Three-tier monetization with quota-based limits**

**Tiers:**
- **Free:** 5 conversations/day, standard models, 12K token limit
- **Pro ($9.99/mo):** Unlimited conversations, premium models, 64K token limit, 5 images/month
- **Max ($19.99/mo):** All features, unlimited images, priority inference

**Quota Types:**
- Regular conversation tokens
- Premium model usage (Claude Sonnet, GPT-4)
- Video conversations
- Image recognition
- Image generation
- Story creation

**Payment Integration:**
- Stripe (web/API) with checkout sessions and webhooks
- RevenueCat + Superwall (mobile) with cross-platform sync
- Billing portal for subscription management
- Promo codes and free trial support

### 4. User Progression & Gamification 🏆
**Engagement system to drive retention**

**Features:**
- **Win Streak System:** Daily login rewards with milestone bonuses
- **XP Progression:** Leveling system with achievements
- **Flip Ticket Rewards:** Gamified credit distribution
- **Analytics Dashboard:** User percentile ranking, conversation stats
- **Achievement Badges:** Unlockable rewards for milestones

### 5. Community Content Creation ✍️
**Users create and share custom content**

**Features:**
- Custom character creation with personality definitions
- User-generated universes/movies
- Story wizard (multi-step story creation)
- Fandom rooms (collaborative spaces for fans)
- Scenario library (public & personal roleplays)
- Chat exports to multiple formats (PDF, text, social media)
- Community voting and engagement tracking

### 6. Referral & Viral Growth 📣
**Built-in viral mechanics**

**Implementation:**
- Referral code generation per user
- Bonus credit allocation for referrer and referee
- Referral link sharing with tracking
- Retroactive referral confirmation
- Email notifications for referrals

---

## Key User Flows

### Flow 1: New User Onboarding

```
Landing/Login → Sign Up (Email/OAuth)
    ↓
Email Verification (OTP)
    ↓
Onboarding Form (15 screens on mobile):
├─ Name, age, location
├─ Avatar selection
├─ Interests/preferences
├─ Referral code entry (optional)
└─ Social media opt-in
    ↓
Home Screen → Discover Popular Characters
    ↓
Premium Modal Prompt (for free users)
```

**Backend Flow:**
1. `POST /api/auth/create-account` - Validate email, send OTP
2. `POST /api/auth/verify-otp` - Confirm account, return JWT
3. `PUT /api/auth/users/me/details` - Save preferences
4. Publish event: `user.created`

### Flow 2: Character Conversation (Core Flow)

```
Home/Search Page
    ↓
Browse/Search Characters → Select Character
    ↓
Chat Screen Loads:
├─ Fetch conversation history (if exists)
├─ Display character intro message
└─ Check user quota availability
    ↓
User Types Message → Send
    ↓
Backend Processing:
├─ Check quota (regular/premium)
├─ Fetch character context (TMDB + Wikipedia)
├─ Build prompt with conversation history
├─ Call LLM (Claude/GPT/Gemini)
├─ Stream response back
├─ Deduct quota tokens
└─ Generate follow-up questions
    ↓
Response Displayed:
├─ Save to database (Supabase)
├─ Cache locally (web: IndexedDB, mobile: MMKV)
├─ Update UI with typing indicator
└─ Show remaining quota
    ↓
User Actions:
├─ Continue conversation
├─ Pin important messages
├─ Like/dislike responses
├─ Export conversation
└─ Share with friends
```

**Technical Flow:**
```
Client → POST /api/chat/talk_with
    ↓
Backend: handle_chat()
    ├─ getCurrentUserQuota(user_id)
    ├─ get_or_initialize_conversation_history()
    ├─ build_character_context(TMDB, Wikipedia)
    ├─ continue_conversation(LLM call)
    ├─ save_conversation_to_supabase()
    ├─ deduct_quota(tokens_used)
    └─ return response + follow_up_questions
    ↓
Client: Display response, cache locally
```

### Flow 3: Quota Exhaustion → Premium Upgrade

```
User Sends Message → Quota Check Fails
    ↓
Checkout Modal Opens:
├─ Display subscription tiers (Free/Pro/Max)
├─ Show feature comparison
└─ Apply promo code (if available)
    ↓
User Selects Tier → Stripe Checkout (web) / RevenueCat (mobile)
    ↓
Payment Processing → Webhook Received (backend)
    ↓
Backend Updates:
├─ Set user.premium = 1 or 2
├─ Update subscriptions table
├─ Grant tier-specific quotas
├─ Invalidate user cache (Redis)
└─ Publish event: subscription.upgraded
    ↓
Event Consumers:
├─ Chat Service: Update quota cache
├─ Analytics Service: Track conversion
├─ Email Service: Send confirmation
└─ Mobile Push: Notify user
    ↓
Return to Chat → Resume Conversation with New Quota
```

### Flow 4: Story Creation & Sharing

```
Ongoing Chat Conversation
    ↓
User Clicks "Create Story" Button
    ↓
Story Wizard Opens:
Step 1: Universe/World Selection (TMDB or custom)
Step 2: Character Selection (up to 5 characters)
Step 3: Scenario Creation (setting, tone, themes)
Step 4: Story Generation (AI-powered draft)
    ↓
Review & Edit Story
    ↓
Publish Options:
├─ Export to PDF/Text
├─ Share on social media (Twitter, Facebook, Reddit)
├─ Create Fandom Room (collaborative space)
└─ Generate shareable link
    ↓
Fandom Room Created:
├─ Invite others via referral code
├─ Collaborative editing
├─ Community voting/likes
└─ Engagement tracking (PostHog)
```

### Flow 5: Group/Multi-Character Chat

```
Chats Screen → "Create Group Chat" Button
    ↓
Select Multiple Characters:
├─ Search from favorites
├─ Browse popular characters
└─ Add from recent chats
    ↓
Initialize Group Conversation:
├─ Backend creates multi-character context
├─ Each character has distinct personality
├─ System prompts encourage natural interjections
└─ Conversation threading across participants
    ↓
User Sends Message → All Characters Respond:
├─ Characters take turns based on relevance
├─ Individual personalities maintained
├─ Action lines distinguish speakers
└─ Group dynamics emerge naturally
```

---

## Primary Use Cases

### Use Case 1: Casual Fan Engagement
**Persona:** Movie fan who wants to explore "what if" scenarios

**Journey:**
1. Discovers SceneXtras via social media
2. Signs up with Google OAuth
3. Browses popular characters (e.g., Batman, Iron Man)
4. Starts conversation: "What would you do if you had Superman's powers?"
5. Engages in 5-10 message exchange
6. Shares interesting responses on Twitter
7. Invites friends via referral link

**Key Metrics:** Session duration, messages per conversation, social shares

### Use Case 2: Premium Roleplayer
**Persona:** Dedicated user who creates elaborate storylines

**Journey:**
1. Free user hits quota limit after 5 conversations
2. Upgrades to Pro tier ($9.99/mo) for premium models
3. Creates custom character from favorite anime
4. Builds multi-episode story arc over weeks
5. Uses image generation for scene visuals
6. Exports conversations as fanfiction
7. Creates fandom room, invites collaborators
8. Hosts group chats with 3+ characters

**Key Metrics:** Subscription retention, story creation rate, community engagement

### Use Case 3: Voice Chat User
**Persona:** User who prefers voice interaction while multitasking

**Journey:**
1. Opens mobile app during commute
2. Selects character from favorites
3. Taps microphone button → speaks message
4. Audio transcribed via Deepgram ASR
5. Character responds with text
6. Text-to-speech (Playht/ElevenLabs) plays audio response
7. Hands-free conversation continues
8. Conversation saved for later review

**Key Metrics:** Voice session duration, audio quality ratings, transcription accuracy

### Use Case 4: Community Content Creator
**Persona:** Creative user who builds custom universes

**Journey:**
1. Creates custom movie/universe (e.g., "Cyberpunk 2099")
2. Defines 5 original characters with backstories
3. Publishes to community database
4. Other users discover and chat with characters
5. Creator receives engagement notifications
6. Community votes on favorite characters
7. Creator earns badges/credits for popular content

**Key Metrics:** Content creation rate, views per custom character, community votes

---

## Microservices Architecture Design

### Recommended Service Decomposition (7 Services)

```
┌─────────────────────────────────────────────────────────────┐
│                     API GATEWAY / ROUTING                    │
│                   (Dokku Native Nginx)                       │
│              • JWT Validation (per service)                  │
│              • SSL/TLS (Let's Encrypt)                       │
│              • Subdomain Routing                             │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│ Auth/User    │      │ Chat Service │     │ Payment      │
│ Service      │      │              │     │ Service      │
│              │      │              │     │              │
│ FastAPI      │      │ FastAPI      │     │ FastAPI      │
│ Port: 8080   │      │ Port: 8080   │     │ Port: 8080   │
└──────────────┘      └──────────────┘     └──────────────┘
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│ Content      │      │ Media        │     │ Community    │
│ Service (Go) │      │ Service      │     │ Service      │
│              │      │              │     │              │
│ Existing!    │      │ FastAPI      │     │ FastAPI      │
│ Port: 8080   │      │ Port: 8080   │     │ Port: 8080   │
└──────────────┘      └──────────────┘     └──────────────┘
                              │
                      ┌───────┴───────┐
                      ▼               ▼
              ┌──────────────┐ ┌──────────────┐
              │ Analytics    │ │ RabbitMQ     │
              │ Service      │ │ Message Queue│
              │              │ │              │
              │ FastAPI      │ │ Events       │
              └──────────────┘ └──────────────┘
```

### Service Responsibilities

#### 1. Auth/User Service
**Routes:** `/api/auth/*`, `/api/user_management/*`

**Responsibilities:**
- User registration and login
- JWT token generation and validation
- OAuth integration (Google, Apple, Facebook)
- User profile management
- Referral system
- Onboarding flow

**Data Ownership:**
- users table
- user_profiles table
- user_auth_tokens table

**External Dependencies:**
- Supabase Auth
- Firebase Admin (fallback)
- SendGrid (OTP emails)

#### 2. Chat Service
**Routes:** `/api/chat/*`

**Responsibilities:**
- Character conversation handling
- LLM integration (Claude, GPT, Gemini)
- Conversation history management
- Message persistence
- Token usage tracking
- Follow-up question generation
- Voice chat (transcription + TTS)

**Data Ownership:**
- conversations table
- messages table
- message_reactions table

**External Dependencies:**
- Anthropic API
- OpenAI API
- Google Generative AI
- Groq API
- TMDB (character context)
- Wikipedia (character background)

#### 3. Payment Service
**Routes:** `/api/payments/*`

**Responsibilities:**
- Stripe checkout session creation
- Subscription management (create/upgrade/downgrade/cancel)
- Webhook handling (Stripe events)
- Quota allocation and management
- Billing portal access
- Promo code application

**Data Ownership:**
- subscriptions table
- user_quotas table
- payment_transactions table

**External Dependencies:**
- Stripe API
- RevenueCat (mobile)

#### 4. Content Service (Go)
**Routes:** `/api/search/*`, `/api/resources/*`, `/api/autocomplete/*`

**Responsibilities:**
- Character search and autocomplete
- Movie/series data retrieval
- TMDB cache management
- Actor filmography
- Popular content recommendations

**Data Ownership:**
- search_index (BadgerDB)
- tmdb_cache (BadgerDB)

**External Dependencies:**
- TMDB API
- TVDB API

#### 5. Media Service
**Routes:** `/api/images/*`, `/api/image/*`

**Responsibilities:**
- Image generation (Gemini, Imagen, Replicate)
- Image recognition/analysis
- Image storage and retrieval
- Video processing (future)
- Audio file management

**Data Ownership:**
- media_metadata table

**External Dependencies:**
- Azure Blob Storage
- Google Generative AI (Imagen)
- Replicate API

#### 6. Community Service
**Routes:** `/api/story/*`, `/api/notifications/*`

**Responsibilities:**
- Story creation and publishing
- Fandom room management
- Scenario library
- User-generated content moderation
- Community voting and engagement

**Data Ownership:**
- stories table
- fandom_rooms table
- scenarios table
- community_votes table

**External Dependencies:**
- SendGrid (notification emails)
- PostHog (engagement tracking)

#### 7. Analytics Service
**Routes:** `/api/analytics/*`, `/api/conversation-stats/*`

**Responsibilities:**
- User statistics aggregation
- Conversation analytics
- Platform-wide metrics
- Win streak tracking
- Engagement tier calculation

**Data Ownership:**
- user_analytics table
- conversation_stats table
- platform_metrics table

**External Dependencies:**
- PostHog API
- Sentry (error tracking)

---

## Database Strategy

### Hybrid Approach (Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│           SHARED SUPABASE (Primary Project)                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ TABLES (Owned by specific services, read by all)      │ │
│  │                                                        │ │
│  │ • users              (Auth Service owns)              │ │
│  │ • user_profiles      (Auth Service owns)              │ │
│  │ • user_auth_tokens   (Supabase Auth)                  │ │
│  │ • subscriptions      (Payment Service owns)           │ │
│  │ • user_quotas        (Payment Service owns)           │ │
│  │                                                        │ │
│  │ WHY SHARED:                                            │ │
│  │ - Authentication context needed by ALL services       │ │
│  │ - Quotas accessed on every chat request              │ │
│  │ - Subscriptions need strong consistency               │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         SERVICE-SPECIFIC DATABASES                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Chat Service DB (PostgreSQL - Railway/DigitalOcean)        │
│  ├─ conversations                                           │
│  ├─ messages                                                │
│  └─ message_reactions                                       │
│                                                              │
│  Community Service DB (PostgreSQL - Railway/DO)             │
│  ├─ stories                                                 │
│  ├─ fandom_rooms                                            │
│  └─ scenarios                                               │
│                                                              │
│  Content Service DB (BadgerDB - existing)                   │
│  ├─ search_index                                            │
│  └─ tmdb_cache                                              │
│                                                              │
│  Media Service DB (PostgreSQL - Railway/DO)                 │
│  └─ media_metadata (blob URLs in Azure)                     │
│                                                              │
│  Analytics Service DB (PostgreSQL - Railway/DO)             │
│  ├─ user_analytics                                          │
│  └─ conversation_stats                                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         SHARED CACHE LAYER (Redis Cluster)                  │
│                                                              │
│  • User session data (TTL: 1 hour)                          │
│  • User quota cache (TTL: 5 minutes)                        │
│  • Popular characters (TTL: 24 hours)                       │
│  • TMDB data cache (TTL: 7 days)                            │
│  • Event deduplication (TTL: 24 hours)                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Rationale for Hybrid Approach

**Shared Database Benefits:**
- ✅ User authentication context available to all services (no sync needed)
- ✅ Strong consistency for critical data (quotas, subscriptions)
- ✅ Simple quota management (no distributed state)
- ✅ Leverages existing Supabase Auth
- ✅ Cost-effective ($25/month Supabase base)

**Service-Specific Database Benefits:**
- ✅ True isolation for domain data
- ✅ Independent scaling per service
- ✅ No schema conflicts
- ✅ Service can choose optimal database (BadgerDB for Go service)
- ✅ Failure isolation (chat DB down ≠ payment DB down)

### Shared Supabase Schema

```sql
-- Users table (Auth Service owns, all services read)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    premium INTEGER DEFAULT 0,  -- 0=free, 1=pro, 2=max
    stripe_customer_id TEXT,
    referral_code TEXT UNIQUE,
    referred_by UUID REFERENCES users(id),
    confirmed BOOLEAN DEFAULT false,
    temporary_account BOOLEAN DEFAULT false,
    created_supabase BOOLEAN DEFAULT false,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User profiles (Auth Service owns)
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    name TEXT,
    avatar_url TEXT,
    phone TEXT,
    country TEXT,
    language TEXT DEFAULT 'en',
    preferences JSONB,
    onboarding_status TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Subscriptions (Payment Service owns)
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) UNIQUE,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    tier INTEGER DEFAULT 0,  -- 0=free, 1=pro, 2=max
    status TEXT,  -- active, cancelled, paused
    current_period_end TIMESTAMP,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User quotas (Payment Service owns, Chat Service reads/writes)
CREATE TABLE user_quotas (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    quota INTEGER DEFAULT 5,                    -- Regular chat tokens
    quota_premium_model INTEGER DEFAULT 0,      -- Premium LLM usage
    quota_image_generation INTEGER DEFAULT 0,   -- Image generation
    quota_image_recognition INTEGER DEFAULT 0,  -- Image analysis
    quota_video INTEGER DEFAULT 0,              -- Video chat minutes
    quota_story INTEGER DEFAULT 0,              -- Story creation
    tokens_used INTEGER DEFAULT 0,
    premium_tokens_used INTEGER DEFAULT 0,
    last_reset TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Atomic quota deduction function
CREATE OR REPLACE FUNCTION deduct_user_quota(
    p_user_id UUID,
    p_quota_type TEXT,
    p_amount INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_remaining INTEGER;
BEGIN
    UPDATE user_quotas
    SET
        quota = CASE WHEN p_quota_type = 'regular'
                     THEN GREATEST(quota - p_amount, 0)
                     ELSE quota END,
        quota_premium_model = CASE WHEN p_quota_type = 'premium'
                                   THEN GREATEST(quota_premium_model - p_amount, 0)
                                   ELSE quota_premium_model END,
        quota_image_generation = CASE WHEN p_quota_type = 'image_gen'
                                      THEN GREATEST(quota_image_generation - p_amount, 0)
                                      ELSE quota_image_generation END,
        tokens_used = tokens_used + CASE WHEN p_quota_type = 'regular' THEN p_amount ELSE 0 END,
        premium_tokens_used = premium_tokens_used + CASE WHEN p_quota_type = 'premium' THEN p_amount ELSE 0 END,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING CASE p_quota_type
        WHEN 'regular' THEN quota
        WHEN 'premium' THEN quota_premium_model
        WHEN 'image_gen' THEN quota_image_generation
        ELSE quota
    END INTO v_remaining;

    RETURN v_remaining;
END;
$$ LANGUAGE plpgsql;

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_referral_code ON users(referral_code);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_stripe_customer ON subscriptions(stripe_customer_id);
CREATE INDEX idx_quotas_user_id ON user_quotas(user_id);
```

### Chat Service Database Schema

```sql
-- Conversations (Chat Service owns)
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- Reference to shared users table
    character_name TEXT NOT NULL,
    character_series TEXT,
    conversation_type TEXT DEFAULT 'single',  -- single, group
    participants JSONB,  -- For group chats
    token_count INTEGER DEFAULT 0,
    message_count INTEGER DEFAULT 0,
    last_message_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Messages (Chat Service owns)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender TEXT NOT NULL,  -- 'user' or character name
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',  -- text, image, audio
    metadata JSONB,  -- tokens, model used, etc.
    pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Message reactions (Chat Service owns)
CREATE TABLE message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    reaction_type TEXT NOT NULL,  -- like, dislike
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(message_id, user_id, reaction_type)
);

-- Indexes
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_character ON conversations(character_name);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_reactions_message_id ON message_reactions(message_id);
```

### Community Service Database Schema

```sql
-- Stories (Community Service owns)
CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    universe TEXT,
    characters JSONB,
    published BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Fandom rooms (Community Service owns)
CREATE TABLE fandom_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    universe TEXT,
    members JSONB,
    settings JSONB,
    referral_code TEXT UNIQUE,
    member_count INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Scenarios (Community Service owns)
CREATE TABLE scenarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID,
    title TEXT NOT NULL,
    description TEXT,
    characters JSONB,
    setting TEXT,
    tone TEXT,
    is_public BOOLEAN DEFAULT false,
    rating NUMERIC(3,2),
    view_count INTEGER DEFAULT 0,
    use_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_stories_user_id ON stories(user_id);
CREATE INDEX idx_stories_published ON stories(published) WHERE published = true;
CREATE INDEX idx_fandom_rooms_creator ON fandom_rooms(creator_id);
CREATE INDEX idx_fandom_rooms_referral ON fandom_rooms(referral_code);
CREATE INDEX idx_scenarios_public ON scenarios(is_public) WHERE is_public = true;
```

---

## Authentication Strategy

### Approach: Per-Service JWT Validation (Dokku)

Since Dokku doesn't provide gateway-level authentication, each service validates JWTs independently.

```
┌──────────┐
│  Client  │ (Web/Mobile)
└─────┬────┘
      │ 1. Request with JWT
      │    Authorization: Bearer eyJhbG...
      │
      ├──────────────────┬──────────────────┬──────────────────┐
      ▼                  ▼                  ▼                  ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│Chat Service │   │Payment Svc  │   │Auth Service │   │Content Svc  │
│             │   │             │   │             │   │             │
│2. Validate  │   │2. Validate  │   │2. Validate  │   │2. Validate  │
│   JWT       │   │   JWT       │   │   JWT       │   │   JWT       │
│             │   │             │   │             │   │             │
│3. Extract   │   │3. Extract   │   │3. Extract   │   │3. Extract   │
│   user_id   │   │   user_id   │   │   user_id   │   │   user_id   │
│             │   │             │   │             │   │             │
│4. Business  │   │4. Business  │   │4. Business  │   │4. Business  │
│   Logic     │   │   Logic     │   │   Logic     │   │   Logic     │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
```

### Shared Authentication Library

```python
# shared/auth.py
# This file should be copied to each service or published as a shared package

from fastapi import Header, HTTPException, Depends
from jose import jwt, JWTError
import os
import httpx
from functools import lru_cache
from datetime import datetime, timedelta

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

# JWT validation
def decode_jwt(token: str) -> dict:
    """Decode and validate Supabase JWT"""
    try:
        payload = jwt.decode(
            token,
            SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated"
        )
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid authentication token: {str(e)}"
        )

# Dependency for protected endpoints
async def get_current_user(authorization: str = Header(None)) -> dict:
    """
    FastAPI dependency for protected endpoints.
    Validates JWT and returns user context.

    Usage:
        @app.post("/protected")
        async def protected_endpoint(
            current_user: dict = Depends(get_current_user)
        ):
            user_id = current_user["user_id"]
            # ... business logic
    """
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Missing authorization header"
        )

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Invalid authorization header format"
        )

    token = authorization.replace("Bearer ", "")
    payload = decode_jwt(token)

    return {
        "user_id": payload.get("sub"),
        "email": payload.get("email"),
        "role": payload.get("role", "user"),
        "tier": payload.get("app_metadata", {}).get("tier", 0)
    }

# Optional: User tier check decorator
def requires_tier(min_tier: int):
    """
    Decorator to require minimum subscription tier.

    Usage:
        @app.post("/premium-feature")
        @requires_tier(1)  # Requires Pro tier
        async def premium_feature(
            current_user: dict = Depends(get_current_user)
        ):
            # ... business logic
    """
    async def tier_dependency(current_user: dict = Depends(get_current_user)):
        user_tier = current_user.get("tier", 0)
        if user_tier < min_tier:
            raise HTTPException(
                status_code=402,
                detail={
                    "code": "INSUFFICIENT_TIER",
                    "message": f"This feature requires tier {min_tier} or higher",
                    "current_tier": user_tier
                }
            )
        return current_user

    return tier_dependency

# Rate limiting by user
from collections import defaultdict
from time import time

class RateLimiter:
    def __init__(self, max_requests: int, window_seconds: int):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = defaultdict(list)

    def is_allowed(self, user_id: str) -> bool:
        now = time()
        cutoff = now - self.window_seconds

        # Remove old requests
        self.requests[user_id] = [
            req_time for req_time in self.requests[user_id]
            if req_time > cutoff
        ]

        # Check limit
        if len(self.requests[user_id]) >= self.max_requests:
            return False

        # Record request
        self.requests[user_id].append(now)
        return True

# Global rate limiter (100 req/min per user)
rate_limiter = RateLimiter(max_requests=100, window_seconds=60)

async def rate_limit_check(current_user: dict = Depends(get_current_user)):
    """Rate limiting dependency"""
    user_id = current_user["user_id"]

    if not rate_limiter.is_allowed(user_id):
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Please try again later."
        )

    return current_user
```

### Service Implementation Example

```python
# chat_service/main.py
from fastapi import FastAPI, Depends, Header
from shared.auth import get_current_user, requires_tier, rate_limit_check
import os

app = FastAPI(title="Chat Service")

# Simple protected endpoint
@app.post("/talk_with")
async def chat(
    message: str,
    character: str,
    current_user: dict = Depends(get_current_user)  # Validates JWT
):
    user_id = current_user["user_id"]
    user_email = current_user["email"]

    # Business logic here
    response = await handle_chat(user_id, character, message)
    return response

# Premium-only endpoint
@app.post("/premium_chat")
async def premium_chat(
    message: str,
    model: str,  # Premium models like GPT-4, Claude Opus
    current_user: dict = Depends(requires_tier(1))  # Pro tier required
):
    user_id = current_user["user_id"]

    # Use premium model
    response = await handle_premium_chat(user_id, model, message)
    return response

# Rate-limited endpoint
@app.post("/generate_image")
async def generate_image(
    prompt: str,
    current_user: dict = Depends(rate_limit_check)  # Rate limited
):
    user_id = current_user["user_id"]

    # Generate image
    image_url = await generate_image_impl(user_id, prompt)
    return {"image_url": image_url}

# Public endpoint (no auth)
@app.get("/health")
async def health():
    return {"status": "healthy"}
```

---

## Data Consistency Patterns

### Event-Driven Architecture

```
┌─────────────────┐
│ Payment Service │
│                 │
│ Subscription    │
│ Updated         │
└────────┬────────┘
         │
         │ 1. Publish Event
         │    "subscription.upgraded"
         ▼
┌─────────────────────────────────┐
│   RabbitMQ (Message Queue)      │
│                                  │
│  Exchange: scenextras.events    │
│  Type: Topic                     │
└─────────────────────────────────┘
         │
         │ 2. Route to subscribers
         │
    ┌────┴────┬────────┬────────┐
    │         │        │        │
    ▼         ▼        ▼        ▼
┌────────┐ ┌──────┐ ┌──────┐ ┌──────┐
│ Chat   │ │Analyt│ │Email │ │Mobile│
│ Svc    │ │ics   │ │ Svc  │ │Notif │
│        │ │ Svc  │ │      │ │      │
│Update  │ │Track │ │Send  │ │Push  │
│quota   │ │event │ │email │ │notif │
└────────┘ └──────┘ └──────┘ └──────┘
```

### Event Schema

```python
# shared/events.py
from enum import Enum
from pydantic import BaseModel
from datetime import datetime
from typing import Dict, Any
import uuid

class EventType(Enum):
    # User events
    USER_CREATED = "user.created"
    USER_UPDATED = "user.updated"
    USER_DELETED = "user.deleted"

    # Subscription events
    SUBSCRIPTION_CREATED = "subscription.created"
    SUBSCRIPTION_UPGRADED = "subscription.upgraded"
    SUBSCRIPTION_DOWNGRADED = "subscription.downgraded"
    SUBSCRIPTION_CANCELLED = "subscription.cancelled"
    SUBSCRIPTION_PAUSED = "subscription.paused"
    SUBSCRIPTION_RESUMED = "subscription.resumed"

    # Quota events
    QUOTA_UPDATED = "quota.updated"
    QUOTA_DEPLETED = "quota.depleted"
    QUOTA_RESET = "quota.reset"

    # Conversation events
    CONVERSATION_CREATED = "conversation.created"
    CONVERSATION_COMPLETED = "conversation.completed"
    MESSAGE_SENT = "message.sent"

    # Story events
    STORY_CREATED = "story.created"
    STORY_PUBLISHED = "story.published"

    # Analytics events
    USER_ENGAGEMENT = "user.engagement"

class Event(BaseModel):
    """Standard event format for all services"""
    event_id: str = None
    event_type: EventType
    timestamp: datetime = None
    user_id: str
    data: Dict[str, Any]
    metadata: Dict[str, Any] = {}

    def __init__(self, **data):
        if "event_id" not in data or data["event_id"] is None:
            data["event_id"] = str(uuid.uuid4())
        if "timestamp" not in data or data["timestamp"] is None:
            data["timestamp"] = datetime.utcnow()
        super().__init__(**data)

# Example event instances
subscription_upgraded_event = Event(
    event_type=EventType.SUBSCRIPTION_UPGRADED,
    user_id="user_123",
    data={
        "old_tier": 0,
        "new_tier": 1,
        "subscription_id": "sub_abc123",
        "quotas": {
            "quota": -1,  # Unlimited
            "quota_premium_model": 100,
            "quota_image_generation": 5
        }
    },
    metadata={
        "source": "payment_service",
        "stripe_event_id": "evt_xyz789"
    }
)

conversation_created_event = Event(
    event_type=EventType.CONVERSATION_CREATED,
    user_id="user_123",
    data={
        "conversation_id": "conv_456",
        "character_name": "Tony Stark",
        "character_series": "Iron Man",
        "message_count": 1
    },
    metadata={
        "source": "chat_service"
    }
)
```

### Event Publisher

```python
# shared/event_publisher.py
import pika
import json
import os
from .events import Event
import logging

logger = logging.getLogger(__name__)

class EventPublisher:
    """Publishes events to RabbitMQ"""

    def __init__(self, rabbitmq_url: str = None):
        self.rabbitmq_url = rabbitmq_url or os.getenv("RABBITMQ_URL")

        if not self.rabbitmq_url:
            raise ValueError("RABBITMQ_URL environment variable not set")

        self.connection = None
        self.channel = None
        self._connect()

    def _connect(self):
        """Establish connection to RabbitMQ"""
        try:
            self.connection = pika.BlockingConnection(
                pika.URLParameters(self.rabbitmq_url)
            )
            self.channel = self.connection.channel()

            # Declare exchange (idempotent)
            self.channel.exchange_declare(
                exchange='scenextras.events',
                exchange_type='topic',
                durable=True
            )

            logger.info("Connected to RabbitMQ")

        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {e}")
            raise

    def publish(self, event: Event):
        """Publish event to exchange"""
        try:
            # Ensure connection is alive
            if self.connection is None or self.connection.is_closed:
                self._connect()

            # Publish message
            self.channel.basic_publish(
                exchange='scenextras.events',
                routing_key=event.event_type.value,  # e.g., "subscription.upgraded"
                body=event.json(),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Persistent message
                    content_type='application/json',
                    message_id=event.event_id,
                    timestamp=int(event.timestamp.timestamp())
                )
            )

            logger.info(
                f"Published event: {event.event_type.value} "
                f"(id={event.event_id}, user={event.user_id})"
            )

        except Exception as e:
            logger.error(f"Failed to publish event: {e}")
            # Don't raise - event publishing is fire-and-forget
            # Services should still function if event bus is down

    def close(self):
        """Close connection"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            logger.info("Closed RabbitMQ connection")

# Singleton instance
_publisher = None

def get_event_publisher() -> EventPublisher:
    """Get global event publisher instance"""
    global _publisher
    if _publisher is None:
        _publisher = EventPublisher()
    return _publisher
```

### Event Consumer

```python
# shared/event_consumer.py
import pika
import json
import threading
from typing import Callable, Dict
from .events import Event, EventType
import logging

logger = logging.getLogger(__name__)

class EventConsumer:
    """Consumes events from RabbitMQ"""

    def __init__(
        self,
        queue_name: str,
        rabbitmq_url: str = None,
        routing_keys: list = None
    ):
        self.queue_name = queue_name
        self.rabbitmq_url = rabbitmq_url or os.getenv("RABBITMQ_URL")
        self.routing_keys = routing_keys or []

        self.connection = None
        self.channel = None
        self.handlers: Dict[EventType, Callable] = {}

        self._connect()

    def _connect(self):
        """Establish connection and declare queue"""
        try:
            self.connection = pika.BlockingConnection(
                pika.URLParameters(self.rabbitmq_url)
            )
            self.channel = self.connection.channel()

            # Declare queue
            self.channel.queue_declare(
                queue=self.queue_name,
                durable=True
            )

            # Bind to routing keys
            for routing_key in self.routing_keys:
                self.channel.queue_bind(
                    exchange='scenextras.events',
                    queue=self.queue_name,
                    routing_key=routing_key
                )
                logger.info(f"Bound {self.queue_name} to {routing_key}")

            logger.info(f"Consumer connected: {self.queue_name}")

        except Exception as e:
            logger.error(f"Failed to connect consumer: {e}")
            raise

    def register_handler(self, event_type: EventType, handler: Callable):
        """Register event handler"""
        self.handlers[event_type] = handler
        logger.info(f"Registered handler for {event_type.value}")

    def start(self):
        """Start consuming events (blocking)"""
        logger.info(f"Starting consumer: {self.queue_name}")

        self.channel.basic_qos(prefetch_count=1)  # Process one at a time
        self.channel.basic_consume(
            queue=self.queue_name,
            on_message_callback=self._handle_message
        )

        try:
            self.channel.start_consuming()
        except KeyboardInterrupt:
            self.channel.stop_consuming()
        finally:
            self.close()

    def start_in_background(self):
        """Start consumer in background thread"""
        thread = threading.Thread(target=self.start, daemon=True)
        thread.start()
        logger.info(f"Started consumer in background: {self.queue_name}")

    def _handle_message(self, ch, method, properties, body):
        """Handle incoming message"""
        try:
            # Parse event
            event_dict = json.loads(body)
            event = Event(**event_dict)

            logger.info(f"Received event: {event.event_type.value} (id={event.event_id})")

            # Check for duplicate (idempotency)
            if self._is_duplicate(event.event_id):
                logger.warning(f"Duplicate event detected: {event.event_id}")
                ch.basic_ack(delivery_tag=method.delivery_tag)
                return

            # Find handler
            handler = self.handlers.get(event.event_type)
            if handler:
                handler(event)
                logger.info(f"Processed event: {event.event_id}")
            else:
                logger.warning(f"No handler for {event.event_type.value}")

            # Mark as processed
            self._mark_processed(event.event_id)

            # Acknowledge message
            ch.basic_ack(delivery_tag=method.delivery_tag)

        except Exception as e:
            logger.error(f"Error processing event: {e}")
            # Nack and requeue (will retry)
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

    def _is_duplicate(self, event_id: str) -> bool:
        """Check if event already processed (using Redis)"""
        import redis
        r = redis.from_url(os.getenv("REDIS_URL"))
        return r.exists(f"processed:{event_id}")

    def _mark_processed(self, event_id: str):
        """Mark event as processed (TTL 24 hours)"""
        import redis
        r = redis.from_url(os.getenv("REDIS_URL"))
        r.setex(f"processed:{event_id}", 86400, "1")

    def close(self):
        """Close connection"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            logger.info(f"Closed consumer: {self.queue_name}")
```

### Service-Specific Consumer Implementation

```python
# chat_service/event_handlers.py
from shared.event_consumer import EventConsumer
from shared.events import EventType, Event
import logging
import redis
import os

logger = logging.getLogger(__name__)

redis_client = redis.from_url(os.getenv("REDIS_URL"))

# Initialize consumer
consumer = EventConsumer(
    queue_name='chat_service.events',
    routing_keys=[
        'subscription.*',  # All subscription events
        'quota.*',         # All quota events
        'user.deleted'     # User deletion
    ]
)

# Handler for subscription upgrades
def handle_subscription_upgraded(event: Event):
    """Update local cache when subscription changes"""
    user_id = event.user_id
    new_tier = event.data.get("new_tier")
    quotas = event.data.get("quotas", {})

    logger.info(f"User {user_id} upgraded to tier {new_tier}")

    # Invalidate caches
    redis_client.delete(f"user:{user_id}:quota")
    redis_client.delete(f"user:{user_id}:tier")

    # Update local quota cache with new values
    for quota_type, quota_value in quotas.items():
        redis_client.setex(
            f"user:{user_id}:{quota_type}",
            300,  # 5 minutes
            quota_value
        )

    logger.info(f"Updated cache for user {user_id}")

def handle_subscription_cancelled(event: Event):
    """Handle subscription cancellation"""
    user_id = event.user_id

    logger.info(f"User {user_id} cancelled subscription")

    # Invalidate all caches
    redis_client.delete(f"user:{user_id}:quota")
    redis_client.delete(f"user:{user_id}:tier")

    # Optionally: Send in-app notification about downgrade

def handle_user_deleted(event: Event):
    """Clean up user data when account deleted"""
    user_id = event.user_id

    logger.info(f"User {user_id} deleted, cleaning up chat data")

    # Delete conversations and messages
    # (cascade delete handled by DB foreign keys)

    # Delete from cache
    redis_client.delete(f"user:{user_id}:*")

    logger.info(f"Cleaned up data for user {user_id}")

# Register handlers
consumer.register_handler(EventType.SUBSCRIPTION_UPGRADED, handle_subscription_upgraded)
consumer.register_handler(EventType.SUBSCRIPTION_CANCELLED, handle_subscription_cancelled)
consumer.register_handler(EventType.USER_DELETED, handle_user_deleted)

# Start consumer in background
consumer.start_in_background()
```

```python
# payment_service/webhooks.py
from fastapi import FastAPI, Request
import stripe
from shared.event_publisher import get_event_publisher
from shared.events import Event, EventType
import os

app = FastAPI()
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
event_publisher = get_event_publisher()

@app.post("/webhook")
async def stripe_webhook(request: Request):
    """Handle Stripe webhook events"""
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        # Verify webhook signature
        event = stripe.Webhook.construct_event(
            payload,
            sig_header,
            os.getenv("STRIPE_WEBHOOK_SECRET")
        )
    except ValueError:
        return {"error": "Invalid payload"}, 400
    except stripe.error.SignatureVerificationError:
        return {"error": "Invalid signature"}, 400

    # Handle subscription events
    if event.type == "customer.subscription.updated":
        subscription = event.data.object
        user_id = subscription.metadata.get("user_id")

        # Update database
        await update_subscription_in_db(user_id, subscription)

        # Determine tier from price
        tier = get_tier_from_price(subscription.plan.id)
        quotas = get_tier_quotas(tier)

        # Publish event for other services
        event_publisher.publish(Event(
            event_type=EventType.SUBSCRIPTION_UPGRADED,
            user_id=user_id,
            data={
                "old_tier": 0,  # TODO: Get from DB
                "new_tier": tier,
                "subscription_id": subscription.id,
                "quotas": quotas
            },
            metadata={
                "stripe_event_id": event.id,
                "source": "payment_service"
            }
        ))

    elif event.type == "customer.subscription.deleted":
        subscription = event.data.object
        user_id = subscription.metadata.get("user_id")

        # Publish cancellation event
        event_publisher.publish(Event(
            event_type=EventType.SUBSCRIPTION_CANCELLED,
            user_id=user_id,
            data={
                "subscription_id": subscription.id,
                "cancelled_at": subscription.canceled_at
            },
            metadata={
                "stripe_event_id": event.id,
                "source": "payment_service"
            }
        ))

    return {"received": True}
```

---

## Dokku Implementation

### Why Dokku is Perfect for This

Dokku is a Docker-powered Platform-as-a-Service (like Heroku) that runs on your own server. It already provides:
- ✅ Nginx reverse proxy (built-in)
- ✅ SSL/TLS (via dokku-letsencrypt plugin)
- ✅ Zero-downtime deploys
- ✅ Git-based deployment
- ✅ Service linking (PostgreSQL, Redis, RabbitMQ)

**No need for Kong, Traefik, or other gateways - Dokku handles routing!**

### Architecture with Dokku

```
┌─────────────────────────────────────────────────────────────┐
│                  Dokku Server (Self-Hosted)                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Subdomain Routing (Nginx - Built-in):                      │
│  ├─ chat.api.scenextras.com     → chat-service    (8080)    │
│  ├─ payment.api.scenextras.com  → payment-service (8080)    │
│  ├─ search.api.scenextras.com   → content-service (8080)    │
│  ├─ media.api.scenextras.com    → media-service   (8080)    │
│  ├─ auth.api.scenextras.com     → auth-service    (8080)    │
│  ├─ community.api.scenextras.com → community-svc  (8080)    │
│  └─ analytics.api.scenextras.com → analytics-svc  (8080)    │
│                                                              │
│  Shared Services:                                            │
│  ├─ PostgreSQL (scenextras-db)                              │
│  ├─ Redis (scenextras-cache)                                │
│  └─ RabbitMQ (scenextras-queue)                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step-by-Step Setup

#### 1. Install Dokku Plugins

```bash
# On your Dokku server (SSH into it)

# PostgreSQL plugin (for shared & service DBs)
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres

# Redis plugin (for caching)
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis

# RabbitMQ plugin (for events)
sudo dokku plugin:install https://github.com/dokku/dokku-rabbitmq.git rabbitmq

# Let's Encrypt plugin (for SSL)
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git letsencrypt
```

#### 2. Create Shared Services

```bash
# On Dokku server

# Create shared PostgreSQL database
dokku postgres:create scenextras-db

# Create Redis cache
dokku redis:create scenextras-cache

# Create RabbitMQ queue
dokku rabbitmq:create scenextras-queue

# View connection info
dokku postgres:info scenextras-db
dokku redis:info scenextras-cache
dokku rabbitmq:info scenextras-queue
```

#### 3. Create Apps (Services)

```bash
# On Dokku server

# Create all service apps
dokku apps:create chat-service
dokku apps:create payment-service
dokku apps:create content-service
dokku apps:create media-service
dokku apps:create auth-service
dokku apps:create community-service
dokku apps:create analytics-service

# Set domains (subdomain-based routing)
dokku domains:set chat-service chat.api.scenextras.com
dokku domains:set payment-service payment.api.scenextras.com
dokku domains:set content-service search.api.scenextras.com
dokku domains:set media-service media.api.scenextras.com
dokku domains:set auth-service auth.api.scenextras.com
dokku domains:set community-service community.api.scenextras.com
dokku domains:set analytics-service analytics.api.scenextras.com
```

#### 4. Link Services to Shared Resources

```bash
# Link PostgreSQL to services that need it
dokku postgres:link scenextras-db chat-service
dokku postgres:link scenextras-db payment-service
dokku postgres:link scenextras-db auth-service
dokku postgres:link scenextras-db community-service
dokku postgres:link scenextras-db analytics-service

# Link Redis to all services (for caching)
dokku redis:link scenextras-cache chat-service
dokku redis:link scenextras-cache payment-service
dokku redis:link scenextras-cache auth-service
dokku redis:link scenextras-cache content-service
dokku redis:link scenextras-cache media-service
dokku redis:link scenextras-cache community-service
dokku redis:link scenextras-cache analytics-service

# Link RabbitMQ to event-driven services
dokku rabbitmq:link scenextras-queue chat-service
dokku rabbitmq:link scenextras-queue payment-service
dokku rabbitmq:link scenextras-queue auth-service
dokku rabbitmq:link scenextras-queue analytics-service
```

#### 5. Set Environment Variables

```bash
# Chat Service
dokku config:set chat-service \
  ANTHROPIC_API_KEY="sk-ant-..." \
  OPENAI_API_KEY="sk-..." \
  GROQ_API_KEY="gsk_..." \
  GOOGLE_GENAI_API_KEY="..." \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_KEY="eyJ..." \
  SUPABASE_JWT_SECRET="..." \
  TMDB_API_KEY="..." \
  SENTRY_DSN="..."

# Payment Service
dokku config:set payment-service \
  STRIPE_SECRET_KEY="sk_live_..." \
  STRIPE_WEBHOOK_SECRET="whsec_..." \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_KEY="eyJ..." \
  SUPABASE_JWT_SECRET="..."

# Content Service (Go)
dokku config:set content-service \
  TMDB_API_KEY="..." \
  TVDB_API_KEY="..." \
  PORT="8080"

# Media Service
dokku config:set media-service \
  AZURE_STORAGE_CONNECTION_STRING="..." \
  GOOGLE_GENAI_API_KEY="..." \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_KEY="eyJ..." \
  SUPABASE_JWT_SECRET="..."

# Auth Service
dokku config:set auth-service \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_KEY="eyJ..." \
  SUPABASE_JWT_SECRET="..." \
  SENDGRID_API_KEY="SG..." \
  FIREBASE_ADMIN_SDK='{"type":"service_account",...}'

# Community Service
dokku config:set community-service \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_KEY="eyJ..." \
  SUPABASE_JWT_SECRET="..." \
  SENDGRID_API_KEY="SG..."

# Analytics Service
dokku config:set analytics-service \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_KEY="eyJ..." \
  SUPABASE_JWT_SECRET="..." \
  POSTHOG_PUBLIC_KEY="..." \
  POSTHOG_PROJECT_ID="..."
```

#### 6. Enable SSL

```bash
# Enable Let's Encrypt for all services
dokku letsencrypt:enable chat-service
dokku letsencrypt:enable payment-service
dokku letsencrypt:enable content-service
dokku letsencrypt:enable media-service
dokku letsencrypt:enable auth-service
dokku letsencrypt:enable community-service
dokku letsencrypt:enable analytics-service

# Auto-renew (cron job)
dokku letsencrypt:cron-job --add
```

#### 7. Configure DNS

Add these DNS records to your domain:

```
Type  Name                           Value
A     chat.api.scenextras.com       YOUR_DOKKU_SERVER_IP
A     payment.api.scenextras.com    YOUR_DOKKU_SERVER_IP
A     search.api.scenextras.com     YOUR_DOKKU_SERVER_IP
A     media.api.scenextras.com      YOUR_DOKKU_SERVER_IP
A     auth.api.scenextras.com       YOUR_DOKKU_SERVER_IP
A     community.api.scenextras.com  YOUR_DOKKU_SERVER_IP
A     analytics.api.scenextras.com  YOUR_DOKKU_SERVER_IP
```

---

## Migration Strategy

### Strangler Fig Pattern (20 Weeks)

Gradually extract services from monolith without breaking clients.

```
Week 0: Monolith handles everything
    ↓
Week 4: Content Service extracted (Go - already isolated)
    ↓
Week 6: Media Service extracted
    ↓
Week 9: Payment Service extracted
    ↓
Week 12: Auth Service extracted
    ↓
Week 16: Chat Service extracted (most complex)
    ↓
Week 20: Community & Analytics Services extracted
    ↓
Monolith retired ✅
```

### Phase 1: Foundation (Weeks 1-2)

**Goal:** Set up infrastructure without changing code

**Tasks:**
1. Install Dokku plugins (postgres, redis, rabbitmq, letsencrypt)
2. Create shared services (scenextras-db, scenextras-cache, scenextras-queue)
3. Deploy existing monolith as-is to Dokku
4. Set up monitoring (Sentry, PostHog)

**Commands:**
```bash
# Deploy monolith
dokku apps:create api-monolith
dokku domains:set api-monolith api.scenextras.com
dokku postgres:link scenextras-db api-monolith
dokku redis:link scenextras-cache api-monolith

# From local machine
cd sceneXtras/api
git remote add dokku dokku@your-server.com:api-monolith
git push dokku main

# Enable SSL
dokku letsencrypt:enable api-monolith
```

**Success Criteria:**
- ✅ Monolith running on Dokku
- ✅ SSL working
- ✅ Database connected
- ✅ No downtime for users

---

### Phase 2: Extract Content Service (Weeks 3-4)

**Goal:** Move search/autocomplete to separate service (Go engine)

**Rationale:** Already isolated, minimal risk

**Tasks:**
1. Create content-service app on Dokku
2. Deploy existing Go search engine
3. Update frontend to call new subdomain
4. Monitor for errors

**Commands:**
```bash
# Create app
dokku apps:create content-service
dokku domains:set content-service search.api.scenextras.com
dokku config:set content-service TMDB_API_KEY="..." TVDB_API_KEY="..."

# Deploy
cd golang_search_engine
git remote add dokku dokku@your-server.com:content-service
git push dokku main

# Enable SSL
dokku letsencrypt:enable content-service
```

**Frontend Changes:**
```typescript
// OLD
const results = await fetch('https://api.scenextras.com/api/search?q=batman');

// NEW
const results = await fetch('https://search.api.scenextras.com/search?q=batman');
```

**Success Criteria:**
- ✅ Search works on new subdomain
- ✅ No performance regression
- ✅ Monolith no longer handles /api/search/*

---

### Phase 3: Extract Media Service (Weeks 5-6)

**Goal:** Move image generation/recognition to separate service

**Tasks:**
1. Create new FastAPI service for media
2. Copy image-related code from monolith
3. Deploy to Dokku
4. Update frontend URLs

**Service Structure:**
```
media_service/
├── Dockerfile
├── main.py
├── requirements.txt
├── image_generation.py
├── image_recognition.py
└── azure_storage.py
```

**Commands:**
```bash
# Create app
dokku apps:create media-service
dokku domains:set media-service media.api.scenextras.com
dokku config:set media-service \
  AZURE_STORAGE_CONNECTION_STRING="..." \
  GOOGLE_GENAI_API_KEY="..."

# Deploy
cd media_service
git init
git add .
git commit -m "Initial media service"
git remote add dokku dokku@your-server.com:media-service
git push dokku main

# Enable SSL
dokku letsencrypt:enable media-service
```

**Success Criteria:**
- ✅ Image generation works
- ✅ Azure Blob Storage accessible
- ✅ Monolith no longer handles /api/images/*

---

### Phase 4: Extract Payment Service (Weeks 7-9)

**Goal:** Move Stripe integration to separate service

**CRITICAL:** This handles money - requires extra testing

**Tasks:**
1. Create payment service with Stripe logic
2. Update Stripe webhook URL to new service
3. Set up event publishing (subscription.upgraded, etc.)
4. Test thoroughly in Stripe test mode
5. Deploy to production

**Service Structure:**
```
payment_service/
├── Dockerfile
├── main.py
├── requirements.txt
├── stripe_client.py
├── webhooks.py
├── subscription_manager.py
└── quota_manager.py
```

**Commands:**
```bash
# Create app
dokku apps:create payment-service
dokku domains:set payment-service payment.api.scenextras.com
dokku postgres:link scenextras-db payment-service  # For subscriptions table
dokku rabbitmq:link scenextras-queue payment-service  # For events
dokku config:set payment-service \
  STRIPE_SECRET_KEY="sk_test_..." \
  STRIPE_WEBHOOK_SECRET="whsec_..." \
  SUPABASE_URL="..." \
  SUPABASE_KEY="..."

# Deploy
cd payment_service
git remote add dokku dokku@your-server.com:payment-service
git push dokku main

dokku letsencrypt:enable payment-service
```

**IMPORTANT: Update Stripe Webhook URL**
```
OLD: https://api.scenextras.com/api/payments/webhook
NEW: https://payment.api.scenextras.com/webhook
```

**Success Criteria:**
- ✅ Test subscription creation works
- ✅ Webhooks received and processed
- ✅ Events published to RabbitMQ
- ✅ Chat service receives quota updates
- ✅ Rollback plan tested

---

### Phase 5: Extract Auth Service (Weeks 10-12)

**Goal:** Move authentication logic to separate service

**Tasks:**
1. Create auth service with Supabase integration
2. Copy auth-related code from monolith
3. Deploy and test OAuth flows
4. Update frontend auth calls

**Service Structure:**
```
auth_service/
├── Dockerfile
├── main.py
├── requirements.txt
├── supabase_auth.py
├── jwt_handler.py
├── oauth_handlers.py
├── referral_system.py
└── onboarding.py
```

**Commands:**
```bash
# Create app
dokku apps:create auth-service
dokku domains:set auth-service auth.api.scenextras.com
dokku postgres:link scenextras-db auth-service
dokku rabbitmq:link scenextras-queue auth-service
dokku config:set auth-service \
  SUPABASE_URL="..." \
  SUPABASE_KEY="..." \
  SUPABASE_JWT_SECRET="..." \
  SENDGRID_API_KEY="..." \
  FIREBASE_ADMIN_SDK='{...}'

# Deploy
cd auth_service
git remote add dokku dokku@your-server.com:auth-service
git push dokku main

dokku letsencrypt:enable auth-service
```

**Frontend Changes:**
```typescript
// OLD
await fetch('https://api.scenextras.com/api/auth/signup', {...});

// NEW
await fetch('https://auth.api.scenextras.com/signup', {...});
```

**Success Criteria:**
- ✅ Signup/login works
- ✅ OAuth (Google, Apple) works
- ✅ JWT tokens valid across services
- ✅ Referral system functional

---

### Phase 6: Extract Chat Service (Weeks 13-16)

**Goal:** Move conversation engine to separate service

**MOST COMPLEX** - handles LLM calls, conversation history

**Tasks:**
1. Create chat service with LLM integrations
2. Create separate database for conversations
3. Migrate existing conversation data
4. Deploy with event consumers (for quota updates)
5. Test thoroughly

**Service Structure:**
```
chat_service/
├── Dockerfile
├── main.py
├── requirements.txt
├── llm_client.py (Claude, GPT, Gemini)
├── conversation_manager.py
├── context_builder.py (TMDB, Wikipedia)
├── quota_checker.py
├── event_handlers.py (subscription events)
└── database.py
```

**Database Migration:**
```bash
# Create separate DB for chat service
dokku postgres:create chat-service-db

# Migrate data
# 1. Export from shared DB
dokku postgres:export scenextras-db > conversations_backup.sql

# 2. Extract conversations & messages tables
grep -A 1000 "CREATE TABLE conversations" conversations_backup.sql > chat_data.sql
grep -A 1000 "CREATE TABLE messages" conversations_backup.sql >> chat_data.sql

# 3. Import to chat service DB
dokku postgres:import chat-service-db < chat_data.sql
```

**Commands:**
```bash
# Create app
dokku apps:create chat-service
dokku domains:set chat-service chat.api.scenextras.com
dokku postgres:link chat-service-db chat-service  # Service-specific DB
dokku postgres:link scenextras-db chat-service    # Shared DB (for quotas)
dokku redis:link scenextras-cache chat-service
dokku rabbitmq:link scenextras-queue chat-service
dokku config:set chat-service \
  ANTHROPIC_API_KEY="..." \
  OPENAI_API_KEY="..." \
  GROQ_API_KEY="..." \
  GOOGLE_GENAI_API_KEY="..." \
  TMDB_API_KEY="..." \
  SUPABASE_URL="..." \
  SUPABASE_KEY="..." \
  SUPABASE_JWT_SECRET="..."

# Deploy
cd chat_service
git remote add dokku dokku@your-server.com:chat-service
git push dokku main

dokku letsencrypt:enable chat-service
```

**Frontend Changes:**
```typescript
// OLD
await fetch('https://api.scenextras.com/api/chat/talk_with', {...});

// NEW
await fetch('https://chat.api.scenextras.com/talk_with', {...});
```

**Success Criteria:**
- ✅ Chat works with all LLM providers
- ✅ Conversation history preserved
- ✅ Quota deduction works
- ✅ Event consumer receives subscription updates
- ✅ Performance same or better

---

### Phase 7: Extract Remaining Services (Weeks 17-20)

**Goal:** Complete migration

#### Community Service (Week 17-18)

**Handles:** Stories, fandom rooms, scenarios

```bash
dokku apps:create community-service
dokku domains:set community-service community.api.scenextras.com
dokku postgres:create community-service-db
dokku postgres:link community-service-db community-service
dokku postgres:link scenextras-db community-service  # For user data
dokku redis:link scenextras-cache community-service

# Deploy
cd community_service
git remote add dokku dokku@your-server.com:community-service
git push dokku main
dokku letsencrypt:enable community-service
```

#### Analytics Service (Week 19-20)

**Handles:** User statistics, conversation analytics, platform metrics

```bash
dokku apps:create analytics-service
dokku domains:set analytics-service analytics.api.scenextras.com
dokku postgres:create analytics-service-db
dokku postgres:link analytics-service-db analytics-service
dokku postgres:link scenextras-db analytics-service  # For user data
dokku rabbitmq:link scenextras-queue analytics-service  # Listen to all events

# Deploy
cd analytics_service
git remote add dokku dokku@your-server.com:analytics-service
git push dokku main
dokku letsencrypt:enable analytics-service
```

---

### Phase 8: Retire Monolith (Week 21)

**Goal:** Shut down original monolith

**Pre-requisites:**
- ✅ All routes migrated to services
- ✅ No traffic to monolith for 1 week
- ✅ Monitoring shows services healthy

**Commands:**
```bash
# Scale down monolith
dokku ps:scale api-monolith web=0

# Monitor for 48 hours - any issues?

# If all good, destroy app
dokku apps:destroy api-monolith
```

**Celebrate! 🎉** Full microservices architecture complete.

---

## Code Examples

### Complete Chat Service Example

```python
# chat_service/main.py
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from shared.auth import get_current_user
from shared.event_publisher import get_event_publisher
from shared.events import Event, EventType
import os
import anthropic
import openai
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Chat Service")

# Initialize clients
anthropic_client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
openai_client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
event_publisher = get_event_publisher()

# Database connection
import asyncpg
from contextlib import asynccontextmanager

db_pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup/shutdown events"""
    global db_pool

    # Startup
    db_pool = await asyncpg.create_pool(
        os.getenv("CHAT_DATABASE_URL"),
        min_size=5,
        max_size=20
    )
    logger.info("Database pool created")

    # Start event consumer
    from .event_handlers import consumer
    consumer.start_in_background()
    logger.info("Event consumer started")

    yield

    # Shutdown
    await db_pool.close()
    logger.info("Database pool closed")

app = FastAPI(title="Chat Service", lifespan=lifespan)

# Request/response models
class ChatRequest(BaseModel):
    message: str
    character: str
    series: str
    conversation_id: str = None
    model: str = "claude-3-haiku"

class ChatResponse(BaseModel):
    response: str
    conversation_id: str
    message_id: str
    remaining_quota: int
    follow_up_questions: list[str]

# Quota management
import redis
redis_client = redis.from_url(os.getenv("REDIS_URL"))
import asyncpg

async def get_user_quota(user_id: str) -> int:
    """Get user quota with Redis caching"""

    # Check cache first
    cached = redis_client.get(f"quota:{user_id}")
    if cached:
        return int(cached)

    # Cache miss - query shared Supabase
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT quota FROM user_quotas WHERE user_id = $1",
            user_id
        )

    if not row:
        return 0

    quota = row['quota']

    # Cache for 5 minutes
    redis_client.setex(f"quota:{user_id}", 300, quota)

    return quota

async def deduct_quota(user_id: str, tokens: int):
    """Deduct quota atomically"""

    # Call Supabase function for atomic deduction
    async with db_pool.acquire() as conn:
        remaining = await conn.fetchval(
            "SELECT deduct_user_quota($1, 'regular', $2)",
            user_id,
            tokens
        )

    # Invalidate cache
    redis_client.delete(f"quota:{user_id}")

    return remaining

# Conversation management
async def get_or_create_conversation(
    user_id: str,
    character: str,
    conversation_id: str = None
):
    """Get existing or create new conversation"""

    async with db_pool.acquire() as conn:
        if conversation_id:
            # Fetch existing
            row = await conn.fetchrow(
                """
                SELECT * FROM conversations
                WHERE id = $1 AND user_id = $2
                """,
                conversation_id,
                user_id
            )
            if row:
                return dict(row)

        # Create new conversation
        conv_id = await conn.fetchval(
            """
            INSERT INTO conversations (user_id, character_name, character_series)
            VALUES ($1, $2, $3)
            RETURNING id
            """,
            user_id,
            character,
            ""
        )

        return {
            "id": conv_id,
            "user_id": user_id,
            "character_name": character,
            "messages": []
        }

async def get_conversation_messages(conversation_id: str):
    """Fetch conversation history"""

    async with db_pool.acquire() as conn:
        rows = await conn.fetch(
            """
            SELECT sender, content, created_at
            FROM messages
            WHERE conversation_id = $1
            ORDER BY created_at ASC
            LIMIT 50
            """,
            conversation_id
        )

    return [
        {
            "role": "user" if row['sender'] == "user" else "assistant",
            "content": row['content']
        }
        for row in rows
    ]

async def save_message(conversation_id: str, sender: str, content: str) -> str:
    """Save message to database"""

    async with db_pool.acquire() as conn:
        message_id = await conn.fetchval(
            """
            INSERT INTO messages (conversation_id, sender, content)
            VALUES ($1, $2, $3)
            RETURNING id
            """,
            conversation_id,
            sender,
            content
        )

        # Update conversation last_message_at
        await conn.execute(
            """
            UPDATE conversations
            SET last_message_at = NOW(), message_count = message_count + 1
            WHERE id = $1
            """,
            conversation_id
        )

    return message_id

# LLM integration
async def call_llm(model: str, messages: list, system_prompt: str):
    """Call appropriate LLM based on model"""

    if model.startswith("claude"):
        response = anthropic_client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=1000,
            system=system_prompt,
            messages=messages
        )
        return {
            "content": response.content[0].text,
            "tokens": response.usage.input_tokens + response.usage.output_tokens
        }

    elif model.startswith("gpt"):
        messages_with_system = [{"role": "system", "content": system_prompt}] + messages
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages_with_system,
            max_tokens=1000
        )
        return {
            "content": response.choices[0].message.content,
            "tokens": response.usage.total_tokens
        }

    else:
        raise ValueError(f"Unknown model: {model}")

# Context building
import httpx

async def build_character_context(character: str, series: str) -> str:
    """Build character context from TMDB and Wikipedia"""

    # Check cache
    cache_key = f"context:{character}:{series}"
    cached = redis_client.get(cache_key)
    if cached:
        return cached.decode('utf-8')

    # Fetch from TMDB
    tmdb_key = os.getenv("TMDB_API_KEY")
    async with httpx.AsyncClient() as client:
        # Search for character
        response = await client.get(
            f"https://api.themoviedb.org/3/search/multi",
            params={"api_key": tmdb_key, "query": series}
        )
        results = response.json().get("results", [])

    if not results:
        context = f"You are {character} from {series}."
    else:
        movie = results[0]
        context = f"""You are {character} from {series}.

{movie.get('overview', '')}

Speak in character, maintaining their personality and mannerisms."""

    # Cache for 24 hours
    redis_client.setex(cache_key, 86400, context)

    return context

# Main chat endpoint
@app.post("/talk_with", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    current_user: dict = Depends(get_current_user)
):
    """Handle character conversation"""

    user_id = current_user["user_id"]

    # 1. Check quota
    quota = await get_user_quota(user_id)
    if quota < 10:
        raise HTTPException(
            status_code=402,
            detail={
                "code": "INSUFFICIENT_QUOTA",
                "message": "Not enough quota remaining",
                "remaining": quota
            }
        )

    # 2. Get or create conversation
    conversation = await get_or_create_conversation(
        user_id,
        request.character,
        request.conversation_id
    )

    # 3. Get conversation history
    messages = await get_conversation_messages(conversation["id"])

    # 4. Build character context
    system_prompt = await build_character_context(
        request.character,
        request.series
    )

    # 5. Add user message
    messages.append({
        "role": "user",
        "content": request.message
    })

    # 6. Call LLM
    try:
        llm_response = await call_llm(
            request.model,
            messages,
            system_prompt
        )
    except Exception as e:
        logger.error(f"LLM call failed: {e}")
        raise HTTPException(500, "AI service temporarily unavailable")

    # 7. Save messages
    await save_message(conversation["id"], "user", request.message)
    message_id = await save_message(
        conversation["id"],
        request.character,
        llm_response["content"]
    )

    # 8. Deduct quota
    remaining = await deduct_quota(user_id, llm_response["tokens"])

    # 9. Publish analytics event
    event_publisher.publish(Event(
        event_type=EventType.MESSAGE_SENT,
        user_id=user_id,
        data={
            "conversation_id": conversation["id"],
            "character": request.character,
            "tokens": llm_response["tokens"],
            "model": request.model
        }
    ))

    # 10. Return response
    return ChatResponse(
        response=llm_response["content"],
        conversation_id=conversation["id"],
        message_id=message_id,
        remaining_quota=remaining,
        follow_up_questions=[]  # TODO: Generate follow-ups
    )

# Health check
@app.get("/health")
async def health():
    """Health check endpoint"""

    checks = {
        "database": False,
        "redis": False,
        "llm": False
    }

    try:
        # Check database
        async with db_pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        checks["database"] = True
    except Exception as e:
        logger.error(f"Database health check failed: {e}")

    try:
        # Check Redis
        redis_client.ping()
        checks["redis"] = True
    except Exception as e:
        logger.error(f"Redis health check failed: {e}")

    try:
        # Check LLM (simple test)
        anthropic_client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=10,
            messages=[{"role": "user", "content": "Hi"}]
        )
        checks["llm"] = True
    except Exception as e:
        logger.error(f"LLM health check failed: {e}")

    healthy = all(checks.values())

    return {
        "status": "healthy" if healthy else "unhealthy",
        "checks": checks,
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8080))
    )
```

```dockerfile
# chat_service/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code
COPY . .

# Dokku sets PORT environment variable
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}
```

```
# chat_service/requirements.txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
anthropic==0.7.0
openai==1.3.0
asyncpg==0.29.0
redis==5.0.1
pika==1.3.2
httpx==0.25.2
python-jose[cryptography]==3.3.0
```

---

### Payment Service with Event Publishing

```python
# payment_service/main.py
from fastapi import FastAPI, Request, Depends, HTTPException
from pydantic import BaseModel
import stripe
from shared.auth import get_current_user
from shared.event_publisher import get_event_publisher
from shared.events import Event, EventType
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Payment Service")

# Initialize Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
stripe_webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

# Event publisher
event_publisher = get_event_publisher()

# Database
import asyncpg
db_pool = None

@app.on_event("startup")
async def startup():
    global db_pool
    db_pool = await asyncpg.create_pool(os.getenv("DATABASE_URL"))
    logger.info("Payment service started")

@app.on_event("shutdown")
async def shutdown():
    await db_pool.close()

# Tier configuration
TIER_QUOTAS = {
    0: {  # Free
        "quota": 5,
        "quota_premium_model": 0,
        "quota_image_generation": 0,
        "quota_image_recognition": 0
    },
    1: {  # Pro ($9.99/mo)
        "quota": -1,  # Unlimited
        "quota_premium_model": 100,
        "quota_image_generation": 5,
        "quota_image_recognition": 10
    },
    2: {  # Max ($19.99/mo)
        "quota": -1,  # Unlimited
        "quota_premium_model": -1,  # Unlimited
        "quota_image_generation": -1,  # Unlimited
        "quota_image_recognition": -1  # Unlimited
    }
}

PRICE_TO_TIER = {
    "price_free": 0,
    "price_pro": 1,
    "price_max": 2,
}

# Request models
class CheckoutRequest(BaseModel):
    price_id: str
    success_url: str = None
    cancel_url: str = None

# Endpoints
@app.post("/create-checkout-session")
async def create_checkout(
    request: CheckoutRequest,
    current_user: dict = Depends(get_current_user)
):
    """Create Stripe checkout session"""

    user_id = current_user["user_id"]
    user_email = current_user["email"]

    # Get or create Stripe customer
    async with db_pool.acquire() as conn:
        stripe_customer_id = await conn.fetchval(
            "SELECT stripe_customer_id FROM users WHERE id = $1",
            user_id
        )

    if not stripe_customer_id:
        customer = stripe.Customer.create(
            email=user_email,
            metadata={"user_id": user_id}
        )
        stripe_customer_id = customer.id

        # Update database
        async with db_pool.acquire() as conn:
            await conn.execute(
                "UPDATE users SET stripe_customer_id = $1 WHERE id = $2",
                stripe_customer_id,
                user_id
            )

    # Create checkout session
    session = stripe.checkout.Session.create(
        customer=stripe_customer_id,
        mode="subscription",
        line_items=[{
            "price": request.price_id,
            "quantity": 1
        }],
        success_url=request.success_url or "https://scenextras.com/payment-success",
        cancel_url=request.cancel_url or "https://scenextras.com/payment-failure",
        metadata={"user_id": user_id}
    )

    return {"checkout_url": session.url}

@app.post("/webhook")
async def stripe_webhook(request: Request):
    """Handle Stripe webhook events"""

    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(
            payload,
            sig_header,
            stripe_webhook_secret
        )
    except ValueError:
        raise HTTPException(400, "Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(400, "Invalid signature")

    logger.info(f"Received webhook: {event.type}")

    # Handle subscription created
    if event.type == "customer.subscription.created":
        subscription = event.data.object
        await handle_subscription_created(subscription, event.id)

    # Handle subscription updated
    elif event.type == "customer.subscription.updated":
        subscription = event.data.object
        await handle_subscription_updated(subscription, event.id)

    # Handle subscription deleted (cancelled)
    elif event.type == "customer.subscription.deleted":
        subscription = event.data.object
        await handle_subscription_cancelled(subscription, event.id)

    # Handle payment succeeded
    elif event.type == "invoice.payment_succeeded":
        invoice = event.data.object
        await handle_payment_succeeded(invoice, event.id)

    return {"received": True}

async def handle_subscription_created(subscription, stripe_event_id):
    """Handle new subscription"""

    customer_id = subscription.customer

    # Get user_id from customer
    async with db_pool.acquire() as conn:
        user_id = await conn.fetchval(
            "SELECT id FROM users WHERE stripe_customer_id = $1",
            customer_id
        )

    if not user_id:
        logger.error(f"User not found for customer {customer_id}")
        return

    # Determine tier from price
    price_id = subscription.items.data[0].price.id
    tier = PRICE_TO_TIER.get(price_id, 0)
    quotas = TIER_QUOTAS[tier]

    # Update database
    async with db_pool.acquire() as conn:
        # Update subscription
        await conn.execute(
            """
            INSERT INTO subscriptions (user_id, stripe_customer_id, stripe_subscription_id, tier, status, current_period_end)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (user_id) DO UPDATE
            SET stripe_subscription_id = $3, tier = $4, status = $5, current_period_end = $6
            """,
            user_id,
            customer_id,
            subscription.id,
            tier,
            subscription.status,
            subscription.current_period_end
        )

        # Update user tier
        await conn.execute(
            "UPDATE users SET premium = $1 WHERE id = $2",
            tier,
            user_id
        )

        # Update quotas
        await conn.execute(
            """
            UPDATE user_quotas
            SET quota = $2, quota_premium_model = $3, quota_image_generation = $4, quota_image_recognition = $5
            WHERE user_id = $1
            """,
            user_id,
            quotas["quota"],
            quotas["quota_premium_model"],
            quotas["quota_image_generation"],
            quotas["quota_image_recognition"]
        )

    # Publish event
    event_publisher.publish(Event(
        event_type=EventType.SUBSCRIPTION_CREATED,
        user_id=user_id,
        data={
            "tier": tier,
            "subscription_id": subscription.id,
            "quotas": quotas
        },
        metadata={
            "stripe_event_id": stripe_event_id,
            "source": "payment_service"
        }
    ))

    logger.info(f"Subscription created for user {user_id}, tier {tier}")

async def handle_subscription_updated(subscription, stripe_event_id):
    """Handle subscription upgrade/downgrade"""

    customer_id = subscription.customer

    # Get user_id
    async with db_pool.acquire() as conn:
        result = await conn.fetchrow(
            """
            SELECT id, premium
            FROM users
            WHERE stripe_customer_id = $1
            """,
            customer_id
        )

    if not result:
        logger.error(f"User not found for customer {customer_id}")
        return

    user_id = result['id']
    old_tier = result['premium']

    # Determine new tier
    price_id = subscription.items.data[0].price.id
    new_tier = PRICE_TO_TIER.get(price_id, 0)

    if old_tier == new_tier:
        logger.info(f"No tier change for user {user_id}")
        return

    quotas = TIER_QUOTAS[new_tier]

    # Update database
    async with db_pool.acquire() as conn:
        await conn.execute(
            """
            UPDATE subscriptions
            SET tier = $2, status = $3, current_period_end = $4
            WHERE user_id = $1
            """,
            user_id,
            new_tier,
            subscription.status,
            subscription.current_period_end
        )

        await conn.execute(
            "UPDATE users SET premium = $1 WHERE id = $2",
            new_tier,
            user_id
        )

        await conn.execute(
            """
            UPDATE user_quotas
            SET quota = $2, quota_premium_model = $3, quota_image_generation = $4, quota_image_recognition = $5
            WHERE user_id = $1
            """,
            user_id,
            quotas["quota"],
            quotas["quota_premium_model"],
            quotas["quota_image_generation"],
            quotas["quota_image_recognition"]
        )

    # Publish event
    event_type = EventType.SUBSCRIPTION_UPGRADED if new_tier > old_tier else EventType.SUBSCRIPTION_DOWNGRADED

    event_publisher.publish(Event(
        event_type=event_type,
        user_id=user_id,
        data={
            "old_tier": old_tier,
            "new_tier": new_tier,
            "subscription_id": subscription.id,
            "quotas": quotas
        },
        metadata={
            "stripe_event_id": stripe_event_id,
            "source": "payment_service"
        }
    ))

    logger.info(f"Subscription updated for user {user_id}: {old_tier} → {new_tier}")

async def handle_subscription_cancelled(subscription, stripe_event_id):
    """Handle subscription cancellation"""

    customer_id = subscription.customer

    # Get user_id
    async with db_pool.acquire() as conn:
        user_id = await conn.fetchval(
            "SELECT id FROM users WHERE stripe_customer_id = $1",
            customer_id
        )

    if not user_id:
        return

    # Downgrade to free tier
    free_quotas = TIER_QUOTAS[0]

    async with db_pool.acquire() as conn:
        await conn.execute(
            """
            UPDATE subscriptions
            SET tier = 0, status = 'cancelled'
            WHERE user_id = $1
            """,
            user_id
        )

        await conn.execute(
            "UPDATE users SET premium = 0 WHERE id = $1",
            user_id
        )

        await conn.execute(
            """
            UPDATE user_quotas
            SET quota = $2, quota_premium_model = $3, quota_image_generation = $4, quota_image_recognition = $5
            WHERE user_id = $1
            """,
            user_id,
            free_quotas["quota"],
            free_quotas["quota_premium_model"],
            free_quotas["quota_image_generation"],
            free_quotas["quota_image_recognition"]
        )

    # Publish event
    event_publisher.publish(Event(
        event_type=EventType.SUBSCRIPTION_CANCELLED,
        user_id=user_id,
        data={
            "subscription_id": subscription.id,
            "cancelled_at": subscription.canceled_at
        },
        metadata={
            "stripe_event_id": stripe_event_id,
            "source": "payment_service"
        }
    ))

    logger.info(f"Subscription cancelled for user {user_id}")

async def handle_payment_succeeded(invoice, stripe_event_id):
    """Handle successful payment"""

    customer_id = invoice.customer

    logger.info(f"Payment succeeded for customer {customer_id}: ${invoice.amount_paid / 100}")

    # Could publish event for analytics
    # event_publisher.publish(...)

@app.get("/health")
async def health():
    """Health check"""
    return {
        "status": "healthy",
        "stripe_connected": stripe.api_key is not None
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8080)))
```

---

## Deployment Guide

### Local Development Setup

```bash
# Clone repository
git clone https://github.com/your-org/scenextras.git
cd scenextras

# Install dependencies for each service
cd chat_service
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Set up .env file
cp .env.example .env
# Edit .env with your API keys

# Run locally
uvicorn main:app --reload --port 8001
```

### Docker Compose for Local Development

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: scenextras
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"  # Management UI
    environment:
      RABBITMQ_DEFAULT_USER: scenextras
      RABBITMQ_DEFAULT_PASS: scenextras

  chat-service:
    build: ./chat_service
    ports:
      - "8001:8080"
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/scenextras
      REDIS_URL: redis://redis:6379
      RABBITMQ_URL: amqp://scenextras:scenextras@rabbitmq:5672
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      OPENAI_API_KEY: ${OPENAI_API_KEY}
    depends_on:
      - postgres
      - redis
      - rabbitmq

  payment-service:
    build: ./payment_service
    ports:
      - "8002:8080"
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/scenextras
      REDIS_URL: redis://redis:6379
      RABBITMQ_URL: amqp://scenextras:scenextras@rabbitmq:5672
      STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY}
      STRIPE_WEBHOOK_SECRET: ${STRIPE_WEBHOOK_SECRET}
    depends_on:
      - postgres
      - redis
      - rabbitmq

volumes:
  postgres-data:
```

```bash
# Start all services locally
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose logs -f chat-service

# Stop all services
docker-compose down
```

### Dokku Deployment (Production)

#### Initial Setup (One-time)

```bash
# SSH into Dokku server
ssh root@your-server.com

# Install Dokku (if not already installed)
wget https://raw.githubusercontent.com/dokku/dokku/v0.30.0/bootstrap.sh
sudo DOKKU_TAG=v0.30.0 bash bootstrap.sh

# Install plugins
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git
sudo dokku plugin:install https://github.com/dokku/dokku-rabbitmq.git
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# Create shared services
dokku postgres:create scenextras-db
dokku redis:create scenextras-cache
dokku rabbitmq:create scenextras-queue
```

#### Deploy First Service (Chat Service)

```bash
# On Dokku server
dokku apps:create chat-service
dokku domains:set chat-service chat.api.scenextras.com
dokku postgres:link scenextras-db chat-service
dokku redis:link scenextras-cache chat-service
dokku rabbitmq:link scenextras-queue chat-service

# Set environment variables
dokku config:set chat-service \
  ANTHROPIC_API_KEY="sk-ant-..." \
  OPENAI_API_KEY="sk-..." \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_KEY="eyJ..." \
  SUPABASE_JWT_SECRET="your-jwt-secret"

# Enable SSL
dokku letsencrypt:enable chat-service
dokku letsencrypt:cron-job --add

# From local machine
cd chat_service
git remote add dokku dokku@your-server.com:chat-service
git push dokku main

# Dokku will automatically:
# 1. Build Docker image
# 2. Run migrations (if configured)
# 3. Deploy with zero downtime
# 4. Update nginx config
# 5. Restart service
```

#### Deploy Additional Services

```bash
# Repeat for each service:
# - payment-service
# - content-service
# - media-service
# - auth-service
# - community-service
# - analytics-service

# Example: Payment Service
dokku apps:create payment-service
dokku domains:set payment-service payment.api.scenextras.com
dokku postgres:link scenextras-db payment-service
dokku redis:link scenextras-cache payment-service
dokku rabbitmq:link scenextras-queue payment-service
dokku config:set payment-service \
  STRIPE_SECRET_KEY="sk_live_..." \
  STRIPE_WEBHOOK_SECRET="whsec_..." \
  SUPABASE_URL="..." \
  SUPABASE_KEY="..." \
  SUPABASE_JWT_SECRET="..."
dokku letsencrypt:enable payment-service

# From local
cd payment_service
git remote add dokku dokku@your-server.com:payment-service
git push dokku main
```

### Deployment Script

```bash
#!/bin/bash
# deploy-all.sh - Deploy all services to Dokku

set -e

DOKKU_HOST="your-server.com"
SERVICES=("chat-service" "payment-service" "content-service" "media-service" "auth-service" "community-service" "analytics-service")

for service in "${SERVICES[@]}"; do
    echo "========================================="
    echo "Deploying $service..."
    echo "========================================="

    cd "$service"

    # Add git remote if not exists
    if ! git remote | grep -q dokku; then
        git remote add dokku "dokku@${DOKKU_HOST}:${service}"
    fi

    # Deploy
    git push dokku main

    echo "✅ $service deployed successfully"

    cd ..
done

echo ""
echo "========================================="
echo "All services deployed! 🎉"
echo "========================================="
```

### Monitoring Deployments

```bash
# View app logs
dokku logs chat-service -t

# Check app status
dokku ps:report chat-service

# View resource usage
dokku resource:report chat-service

# Scale service (add more instances)
dokku ps:scale chat-service web=3

# Restart service
dokku ps:restart chat-service

# Rollback to previous version
dokku ps:rebuild chat-service --ref previous
```

---

## Summary & Recommendations

### ✅ Proceed with Microservices IF:
- Team size ≥ 3 engineers
- Current traffic >500 req/min
- Planning to scale 10x in next year
- Multiple features in development simultaneously

### 🏗️ Recommended Architecture:
- **7 Services:** Auth, Chat, Payment, Content (Go), Media, Community, Analytics
- **Database:** Shared Supabase + Service DBs + Redis
- **Auth:** Per-service JWT validation (shared library)
- **Communication:** Sync via subdomain routing, Async via RabbitMQ
- **Deployment:** Dokku with subdomain-based routing

### 💰 Cost Comparison:

**Current (Monolith):**
- Supabase: $25/month
- Hosting: ~$50/month
- **Total: ~$75/month**

**Microservices:**
- Supabase (shared): $25/month
- Dokku hosting: ~$100/month (single server can handle all services)
- **Total: ~$125/month**
- **Extra cost: $50/month for better architecture**

### 🚀 Migration Timeline:
- **Week 0-2:** Infrastructure setup
- **Week 3-4:** Extract Content Service
- **Week 5-6:** Extract Media Service
- **Week 7-9:** Extract Payment Service
- **Week 10-12:** Extract Auth Service
- **Week 13-16:** Extract Chat Service
- **Week 17-20:** Extract Community & Analytics
- **Week 21:** Retire Monolith

### ⚠️ Critical Success Factors:
1. **Monitoring from Day 1** - Set up Sentry + logging before migrating
2. **Event Idempotency** - Use Redis to detect duplicate events
3. **Feature Flags** - Gradual rollout with rollback capability
4. **Shared Auth Library** - Consistent JWT validation across services
5. **Database Backups** - Regular backups before migrations
6. **Load Testing** - Test each service under load before switching traffic

### 📚 Next Steps:
1. Review this document with team
2. Decide: proceed or wait?
3. If proceeding: Set up Dokku server
4. Start Phase 1 (infrastructure)
5. Extract first service (Content Service)

---

**Document Version:** 1.0
**Last Updated:** January 2025
**Maintained By:** SceneXtras Engineering Team
