# Premium Flag Usage Analysis - SceneXtras

## Executive Summary

The "premium" flag is a **numeric integer field in the User database model** that represents subscription/premium tier status. It serves as the primary source of truth for user premium status across all three applications (Python API, React Web, React Native Mobile).

### Premium Value Mapping
```
0 = Free/Standard User
1 = MAX/PRO User (basic premium tier)
2 = PRO/Advanced User (advanced premium tier)  
3 = CREATOR User (highest premium tier)
```

---

## 1. Backend - Python API (sceneXtras/api/)

### 1.1 Database Model Definition

**File**: `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/model/models.py`
**Line 45**: `premium = Column(Integer, default=0)`

```python
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True)
    password = Column(String(255))
    # ... other fields ...
    premium = Column(Integer, default=0)  # LINE 45
    quota_premium_model = Column(Integer, default=5)
    subscription_end_date = Column(DateTime, nullable=True)
    unsubscribed = Column(Integer, default=0)
```

**Key observations**:
- `premium` is Integer type (0-3 values)
- Default is 0 (free user)
- Separate field `quota_premium_model` tracks premium model quota
- Related to `subscription_end_date` for expiration tracking

### 1.2 Premium Flag Conversion - API Response

**File**: `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/auth/authentation_logic.py`
**Lines 633-683**: `user_to_user_dto()` function

```python
def user_to_user_dto(user: User, history: List[str] = []) -> dict | UserDTO:
    """Convert User model instance to UserDTO and return as dict"""
    # LINE 637: Convert premium to isPremium string
    isPremium = "premium" if user.premium else "normal"
    
    # ... build DTO ...
    dto = UserDTO(
        email=user.email,
        isPremium=isPremium,          # LINE 654 - Derived from premium flag
        status=isPremium,              # LINE 655 - Also set to isPremium value
        premium=user.premium,          # LINE 661 - Raw premium number also included
        # ... other fields ...
    )
    return dto
```

**Critical Logic**:
- `isPremium` is set to `"premium"` if `user.premium` is truthy (any non-zero value)
- `isPremium` is set to `"normal"` if `user.premium` is 0
- **DISCREPANCY**: This doesn't differentiate between tiers (1, 2, 3) - treats all non-zero as "premium"
- Both the raw `premium` (numeric) and derived `isPremium` (string) are returned in API response

### 1.3 Premium Tier Detection Functions

**File**: `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/chat/chat_gpt_client.py`

```python
def is_premium_user(current_user: User) -> bool:
    """Returns True if user has any premium tier"""
    return current_user.premium >= 1

def is_pro_user(current_user: User) -> bool:
    """Returns True if user is PRO tier"""
    return current_user.premium == 2

def is_free_user(current_user: User) -> bool:
    """Returns True if user is free tier"""
    return current_user.premium == 0

def is_creator_user(current_user: User) -> bool:
    """Returns True if user is CREATOR tier"""
    return current_user.premium == 3
```

### 1.4 Premium Status Setting from RevenueCat

**File**: `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/auth/auth_req.py`
**Lines 500-550** (approximate): RevenueCat subscription sync logic

```python
# Determine premium level based on subscription type
if subscription_type == "pro":
    current_user.premium = 1
elif subscription_type == "pro_monthly":
    current_user.premium = 2
elif subscription_type == "creator":
    current_user.premium = 3
elif subscription_type in ["daily_pass", "trial"]:
    current_user.premium = 1  # Daily passes get basic premium
else:
    current_user.premium = 1  # Default to basic
```

**Key findings**:
- Premium flag is updated by RevenueCat webhook handler
- Maps subscription products to numeric premium tiers:
  - `pro` → 1 (MAX tier)
  - `pro_monthly` → 2 (PRO tier)
  - `creator` → 3 (CREATOR tier)
  - `daily_pass` → 1
  - `trial` → 1

### 1.5 API Endpoints That Return Premium

Endpoints that include premium flag in response:

1. **Auth endpoints** (`/auth/*`):
   - Login endpoints return UserDTO with `isPremium` and `premium`

2. **User endpoints** (`/api/users/*`):
   - GET `/api/users/me` returns full user profile with premium

3. **Chat endpoints** (`/api/chat/*`):
   - Log premium status in chat requests
   - Pass `user_premium=current_user.premium` to chat services

---

## 2. React Web Frontend (frontend_webapp/)

### 2.1 Type Definition

**File**: `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/types/UserType.ts`
**Lines 29, 22**: User interface

```typescript
export interface User {
  // ... other fields ...
  isPremium?: string;      // LINE 22 - "premium" or "normal" string
  premium?: number;        // LINE 29 - Raw numeric tier value (0-3)
  // ... other fields ...
}
```

### 2.2 How Frontend Uses Premium Flag

**File**: `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/App.tsx`

```typescript
// Check if user is logged in, NOT premium, and has completed onboarding
const isUserFree = user && user.isPremium !== 'premium';

// Also checks numeric premium value
if (user.isPremium === 'premium') {
    // User is premium
}

// Checks specific tier
if (user.premium === 1) {
    // MAX tier
} else if (user.premium === 2) {
    // PRO tier
} else if (user.premium === 3) {
    // CREATOR tier
}
```

### 2.3 Premium Checks Throughout Components

**Pattern 1: String comparison using isPremium**
```typescript
user?.isPremium !== 'premium'  // Check if NOT premium
user?.isPremium === 'premium'  // Check if IS premium
```

**Pattern 2: Numeric comparison using premium**
```typescript
user?.premium != 2  // Check if NOT PRO tier
user?.premium === 3 // Check if IS CREATOR tier
user.premium >= 2   // Check if PRO or CREATOR
```

**Files using premium flag**:
- `/src/components/chat/InnerChat.tsx` - Chat quotas, premium features
- `/src/components/chat/ChatInputAndOptionsContainer.tsx` - Command availability
- `/src/components/user/Account.tsx` - Display subscription tier
- `/src/components/user/NotificationSystem.tsx` - Premium notifications
- `/src/components/search/CreateStoryCard.tsx` - Premium feature gates
- `/src/components/modals/UnsubscribeModal.tsx` - Show tier in cancellation

### 2.4 PaymentSuccessful Component Polling

**File**: `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/components/payments/PaymentSuccessful.tsx`

```typescript
// Poll for premium status update after payment
const check for any premium tier (1=MAX, 2=PRO, 3=CREATOR) or active subscription
if (
  (currentUser?.premium &&
   currentUser.premium >= 1 &&
   currentUser.premium <= 3) ||
  currentUser?.stripe_subscription_id
) {
  // Premium status confirmed - redirect to dashboard
}
```

---

## 3. React Native Mobile (mobile_app_sx/)

### 3.1 Type Definition

**File**: `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/types/consolidatedUser.ts`
**Lines 23-24**: User interface

```typescript
export interface User {
  id: string;
  email: string;
  // ... other fields ...
  premium?: number;          // LINE 23 - Numeric tier (0-3)
  subscription_status?: string; // LINE 24 - String status
}
```

### 3.2 Mobile User Store

**File**: `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/store/userStore.ts`

```typescript
// Default values
userProfile: {
  subscription: 'Standard User',  // Default subscription display
  // ...
},

// Data sources
consolidatedData: ConsolidatedUserData | null,  // Includes premium field
```

### 3.3 Consolidated API Response Handling

**File**: `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/services/consolidatedUserApi.ts`

```typescript
// Fallback user data when API fails
const fallbackUserId = userId || session?.user?.id || '';
return {
  user: {
    id: fallbackUserId,
    email,
    xp: 0,
    premium: 0,                    // Default to free (LINE 47)
    subscription_status: 'unavailable',
    // ...
  },
  // ...
};
```

### 3.4 Mobile Subscription Mapping

**File**: `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/services/validationService.ts`

```typescript
subscription: z.enum(['free', 'premium', 'pro']).default('free')
```

**File**: `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/hooks/useSuperwall.ts`

```typescript
userType: userProfile.subscription === 'Premium' ? 'premium' : 'free'
```

### 3.5 Superwall Integration

**File**: `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/services/superwall.ts`

```typescript
userType?: 'free' | 'premium';

// Paywall placements tied to premium status
PREMIUM_FEATURES: 'premium_features', // Main premium feature paywall
```

---

## 4. Discrepancies and Issues Found

### Issue 1: Premium String vs Numeric Mismatch

**Problem**: 
- Backend derives `isPremium` as "premium" or "normal" string from any non-zero premium value
- Frontend receives both `isPremium` (string) and `premium` (numeric)
- **Mismatch**: Frontend sometimes uses `isPremium` (loses tier info), sometimes uses `premium` (preserves tier info)

**Example**:
```typescript
// This loses tier information
if (user.isPremium === 'premium') { /* treat all tiers same */ }

// This preserves tier information
if (user.premium === 2) { /* PRO only */ }
```

### Issue 2: RevenueCat Subscription Sync Logic

**Location**: `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/auth/auth_req.py`

**Problem**:
- Premium flag is set from RevenueCat webhook
- But there's also Superwall paywall logic on mobile
- **Question**: How does Superwall sync back to premium flag?

**Code Gap**: No obvious endpoint that updates `premium` from Superwall/RevenueCat on mobile

### Issue 3: Subscription Status vs Premium Inconsistency

**In consolidatedUser.ts**:
```typescript
premium?: number;             // 0-3 numeric
subscription_status?: string; // Separate string field
```

**Issue**: 
- `premium` is the authoritative numeric value
- `subscription_status` is sometimes "unavailable" in fallback
- Frontend uses `subscription: 'Premium' | 'Standard User'` but this doesn't come from backend

### Issue 4: Mobile App Subscription String Inconsistency

**In userStore.ts**:
```typescript
subscription: 'Standard User' | 'Premium'  // Default string
```

**Issue**: 
- Mobile displays `subscription: 'Standard User'` or `'Premium'`
- Backend returns `premium: 0-3` numeric values
- **Gap**: No clear mapping/conversion shown in mobile code

---

## 5. Complete Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│             PAYMENT / SUBSCRIPTION SYSTEM                   │
│  (RevenueCat, Stripe, Superwall - External Services)       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│        PYTHON API BACKEND (sceneXtras/api)                 │
│                                                             │
│  1. User.premium = Column(Integer) [0-3]  [Primary Store] │
│  2. user_to_user_dto() → isPremium string  [API Response]  │
│  3. RevenueCat webhook → updates premium   [Sync Point]    │
│                                                             │
│  Returns: {                                                 │
│    "isPremium": "premium" | "normal",      [String]        │
│    "premium": 0 | 1 | 2 | 3,               [Number]        │
│    "subscription_status": "...",           [String]        │
│  }                                                          │
└────────────────────┬─────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐      ┌──────────────────────────┐
│   React Web      │      │   React Native Mobile    │
│ (frontend_webapp)│      │   (mobile_app_sx)        │
│                  │      │                          │
│ Stores:          │      │ Stores:                  │
│ - useAuthStore   │      │ - useUserStore           │
│   user.premium   │      │ - consolidatedData       │
│   user.isPremium │      │   user.premium           │
│                  │      │   user.subscription_status
│ Uses both:       │      │                          │
│ if(isPremium)    │      │ Uses both:               │
│ if(premium==2)   │      │ if(subscription='Prem')  │
│                  │      │ if(premium==2)           │
└──────────────────┘      └──────────────────────────┘
```

---

## 6. Summary Table

| Aspect | Python API | React Web | React Native |
|--------|-----------|-----------|--------------|
| **Primary Storage** | `User.premium` (Int) | Fetched from API | Fetched from API |
| **Values** | 0-3 | 0-3 | 0-3 |
| **String Representation** | `isPremium: "premium"\|"normal"` | `isPremium: "premium"\|"normal"` or undefined | `subscription_status` varies |
| **Type Definitions** | `premium: Column(Integer)` | `premium?: number` | `premium?: number` |
| **Where Set** | User creation (0), RevenueCat webhook | From API response | From consolidated API |
| **Used For** | Quota allocation, feature gates | Feature gates, UI display | Feature gates, Superwall |
| **Tier Support** | 4 tiers (0,1,2,3) | All 4 tiers | Limited/varies |

---

## 7. Key Recommendations for Implementation

1. **Consistent Tier Support**: Ensure all applications handle all 4 premium tiers (0, 1, 2, 3) consistently

2. **Mobile Subscription Mapping**: Create explicit mapping in mobile app:
   ```typescript
   const premiumToSubscription = (premium: number) => {
     switch(premium) {
       case 0: return 'Standard User';
       case 1: return 'Premium';     // MAX
       case 2: return 'Premium Pro'; // PRO
       case 3: return 'Premium Creator'; // CREATOR
       default: return 'Standard User';
     }
   };
   ```

3. **Avoid isPremium String**: Prefer using numeric `premium` field throughout for consistency

4. **Superwall Integration**: Document how Superwall paywall status syncs back to RevenueCat/backend

5. **Audit Premium Updates**: All places that update `premium` field should be documented and consistent

---

## 8. All File Locations Found

### Backend Python Files
- `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/model/models.py` - User.premium definition
- `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/auth/authentation_logic.py` - user_to_user_dto
- `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/auth/auth_req.py` - RevenueCat sync, cache invalidation
- `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/chat/chat_gpt_client.py` - Tier detection functions
- `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/router/gpt_chat_router.py` - Premium quota handling
- `/Users/securiter/Workspace/scenextras_complex/sceneXtras/api/router/payment_router.py` - Payment handling

### React Web Files
- `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/types/UserType.ts` - User interface
- `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/helper/authHelper.ts` - Auth conversion
- `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/stores/useAuthStore.ts` - Auth store
- `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/App.tsx` - Premium checks
- `/Users/securiter/Workspace/scenextras_complex/frontend_webapp/src/components/payments/PaymentSuccessful.tsx` - Polling logic
- Multiple component files in `/src/components/` checking premium status

### React Native Files
- `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/types/consolidatedUser.ts` - User type
- `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/store/userStore.ts` - User store
- `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/services/consolidatedUserApi.ts` - API service
- `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/services/superwall.ts` - Superwall integration
- `/Users/securiter/Workspace/scenextras_complex/mobile_app_sx/hooks/useSuperwall.ts` - Superwall hook

