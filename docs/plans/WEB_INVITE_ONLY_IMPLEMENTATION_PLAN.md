# Web App Invite-Only Flow with App Download Redirect

## Implementation Plan

**Created:** 2025-12-05
**Status:** Planning
**Priority:** High

---

## Executive Summary

Implement invite code requirement on web app and add app download redirect/prompt to funnel web visitors to the native mobile app. The backend referral system is **fully implemented** - this plan focuses on web frontend changes.

---

## Current State Analysis

### Backend (Python API) - READY

| Component | Status | Location |
|-----------|--------|----------|
| Referral code validation | Implemented | `/api/referral-codes/validate/{code}` (public) |
| Apply referral code | Implemented | `/api/retroactive-referral` (POST) |
| Code redemption with bonus | Implemented | `REFERRAL_CODE_REDEMPTION_BONUS = 50` credits |
| Rate limiting | Implemented | Daily + total limits in ReferralCode table |

**Key Backend Files:**
- `sceneXtras/api/router/referral_code_router.py` - All referral endpoints
- `sceneXtras/api/db/models.py` - ReferralCode, ReferralRedemption models
- `sceneXtras/api/model/quotas_config.py` - Bonus configuration

### Web Frontend - PARTIAL

| Component | Status | Location |
|-----------|--------|----------|
| `applyRetroactiveReferral()` | Exists | `src/api/authClient.ts:106` |
| `getFeatureFlag()` | Exists | `src/utils/posthogUtils.ts:361` |
| Mobile detection | Exists | `src/stores/useMobileStore.ts` |
| Onboarding flow | Exists | `src/components/onboarding/OnboardingForm.tsx` |
| Referral step | Exists (at END) | OnboardingForm step 13 (id: 'referral') |
| **useFeatureFlag hook** | MISSING | Need to create |
| **InviteCodeScreen** | MISSING | Need to create |
| **AppDownloadBanner** | MISSING | Need to create |
| **Code validation service** | MISSING | Need to create |

### Mobile App (Reference Implementation)

| Component | Location |
|-----------|----------|
| ReferralCodeScreen (FIRST step) | `app/onboarding/ReferralCodeScreen.tsx` |
| referralService | `services/referralService.ts` |
| useFeatureFlag hook | `hooks/useFeatureFlag.ts` |
| isReferralSkipEnabled() | `services/featureFlags.ts` |

---

## Implementation Tasks

### Phase 1: Foundation (Feature Flags & Hooks)

#### 1.1 Create `useFeatureFlag` Hook
**File:** `frontend_webapp/src/hooks/useFeatureFlag.ts`

```typescript
import { useState, useEffect } from 'react';
import { getFeatureFlag } from '../utils/posthogUtils';

/**
 * React hook for feature flag checking with PostHog integration.
 * Returns boolean flag value with real-time updates.
 *
 * @param flagKey - Feature flag name (e.g., 'feature_web_invite_only')
 * @param defaultValue - Default value if flag not available (default: false)
 * @returns boolean - Whether feature is enabled
 */
export function useFeatureFlag(flagKey: string, defaultValue = false): boolean {
  const [isEnabled, setIsEnabled] = useState<boolean>(() => {
    // Check environment variable first (for development override)
    const envKey = `REACT_APP_${flagKey.toUpperCase()}`;
    const envValue = process.env[envKey];
    if (envValue === 'true') return true;
    if (envValue === 'false') return false;

    // Then check PostHog
    const flag = getFeatureFlag(flagKey);
    if (flag !== null) return Boolean(flag);

    return defaultValue;
  });

  useEffect(() => {
    // Re-check flag value (PostHog may load async)
    const checkFlag = () => {
      const flag = getFeatureFlag(flagKey);
      if (flag !== null) {
        setIsEnabled(Boolean(flag));
      }
    };

    // Check immediately and after a delay for async loading
    checkFlag();
    const timer = setTimeout(checkFlag, 1000);

    return () => clearTimeout(timer);
  }, [flagKey, defaultValue]);

  return isEnabled;
}

export default useFeatureFlag;
```

#### 1.2 Create Invite Code Validation Service
**File:** `frontend_webapp/src/services/inviteCodeService.ts`

```typescript
import api from '../api/apiClient';

export interface InviteCodeValidationResult {
  valid: boolean;
  reason?: string;
  code?: string;
  remaining_uses?: number;
  remaining_daily_uses?: number | null;
  bonus?: number;
}

export interface InviteCodeError extends Error {
  error_code?: string;
  status?: number;
}

/**
 * Validate an invite code in real-time (no auth required)
 */
export async function validateInviteCode(code: string): Promise<InviteCodeValidationResult> {
  try {
    const response = await api.get(`/referral-codes/validate/${code.trim().toUpperCase()}`);
    return response.data;
  } catch (error: any) {
    if (error.response?.status === 404) {
      return { valid: false, reason: 'Code not found' };
    }
    throw error;
  }
}

/**
 * Check if input is valid invite code format (alphanumeric, 4-15 chars)
 */
export function isValidCodeFormat(code: string): boolean {
  const alphanumeric = code.replace(/[^a-zA-Z0-9]/g, '');
  return alphanumeric.length >= 4 && alphanumeric.length <= 15;
}
```

### Phase 2: Core Components

#### 2.1 Create Invite Code Store
**File:** `frontend_webapp/src/stores/useInviteStore.ts`

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface InviteState {
  // Code state
  inviteCode: string;
  isValidated: boolean;
  isSkipped: boolean;
  validationTimestamp: number | null;

  // Actions
  setInviteCode: (code: string) => void;
  markValidated: () => void;
  markSkipped: () => void;
  reset: () => void;
}

export const useInviteStore = create<InviteState>()(
  persist(
    (set) => ({
      inviteCode: '',
      isValidated: false,
      isSkipped: false,
      validationTimestamp: null,

      setInviteCode: (code) => set({ inviteCode: code }),
      markValidated: () => set({ isValidated: true, validationTimestamp: Date.now() }),
      markSkipped: () => set({ isSkipped: true }),
      reset: () => set({
        inviteCode: '',
        isValidated: false,
        isSkipped: false,
        validationTimestamp: null,
      }),
    }),
    {
      name: 'invite-code-storage',
    }
  )
);
```

#### 2.2 Create InviteCodeScreen Component
**File:** `frontend_webapp/src/components/invite/InviteCodeScreen.tsx`

Key features:
- Real-time validation with debounce (500ms)
- Visual feedback (validating → valid/invalid)
- Query parameter support (`?invite_code=XXX`)
- Skip button (controlled by `feature_web_invite_skip_enabled`)
- Help buttons (Discord, Contact)
- Mobile-responsive design
- Error state with shake animation

```typescript
// Component skeleton - full implementation in Phase 2
interface InviteCodeScreenProps {
  onSuccess: () => void;
  onSkip?: () => void;
  allowSkip?: boolean;
}

export function InviteCodeScreen({ onSuccess, onSkip, allowSkip = false }: InviteCodeScreenProps) {
  // State: code input, validation status, loading
  // Effects: URL param handling, debounced validation
  // Render: Input, validation feedback, continue/skip buttons
}
```

#### 2.3 Create AppDownloadBanner Component
**File:** `frontend_webapp/src/components/banners/AppDownloadBanner.tsx`

Key features:
- Only shown to mobile web users
- Dismissible with localStorage persistence
- iOS/Android detection for correct store link
- Feature flag controlled (`feature_app_download_banner`)
- Sticky positioning (top or bottom)

```typescript
interface AppDownloadBannerProps {
  position?: 'top' | 'bottom';
  onDismiss?: () => void;
}

// App Store URLs (to be configured)
const APP_STORE_URL = 'https://apps.apple.com/app/scenextras/id[APP_ID]';
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.scenextras.app';
```

### Phase 3: Integration

#### 3.1 Modify App.tsx / Routing
**File:** `frontend_webapp/src/App.tsx`

Add conditional routing for invite-gated flow:

```typescript
// Pseudo-code for routing logic
function AppRoutes() {
  const isInviteOnlyEnabled = useFeatureFlag('feature_web_invite_only');
  const { isValidated, isSkipped } = useInviteStore();

  // If invite-only enabled and user hasn't validated/skipped
  if (isInviteOnlyEnabled && !isValidated && !isSkipped) {
    return <InviteCodeScreen onSuccess={handleInviteSuccess} />;
  }

  // Normal app routes
  return <Routes>...</Routes>;
}
```

#### 3.2 Add AppDownloadBanner to Layout
**File:** `frontend_webapp/src/components/navigation/Layout.tsx`

```typescript
import { useFeatureFlag } from '../../hooks/useFeatureFlag';
import { useMobileStore } from '../../stores/useMobileStore';
import AppDownloadBanner from '../banners/AppDownloadBanner';

function Layout({ children }) {
  const showBanner = useFeatureFlag('feature_app_download_banner', true);
  const { isMobile } = useMobileStore();

  return (
    <>
      {showBanner && isMobile && <AppDownloadBanner position="top" />}
      {children}
    </>
  );
}
```

#### 3.3 Track Analytics Events
**File:** `frontend_webapp/src/utils/posthogUtils.ts`

Add tracking for:
- `web_invite_screen_viewed`
- `web_invite_code_validated` (valid/invalid, code length)
- `web_invite_code_skipped`
- `web_app_download_banner_shown`
- `web_app_download_banner_clicked` (platform: ios/android)
- `web_app_download_banner_dismissed`

---

## Feature Flags

| Flag Name | Description | Default (Dev) | Default (Prod) |
|-----------|-------------|---------------|----------------|
| `feature_web_invite_only` | Gate web access behind invite code | `false` | `false` (enable via PostHog) |
| `feature_web_invite_skip_enabled` | Allow users to skip invite requirement | `true` | `false` |
| `feature_app_download_banner` | Show app download prompt on mobile web | `true` | `true` |

### A/B Testing Strategy

Use PostHog to test:
1. **Invite timing**: Gate first vs show value prop first
2. **Skip button**: With skip vs without skip
3. **Banner position**: Top vs bottom
4. **Banner timing**: Immediate vs after 30s

---

## API Endpoints Used

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/referral-codes/validate/{code}` | GET | None | Real-time code validation |
| `/api/retroactive-referral` | POST | Required | Apply code after signup (existing) |

---

## File Changes Summary

### New Files (6)
```
frontend_webapp/src/
├── hooks/
│   └── useFeatureFlag.ts              # Feature flag React hook
├── services/
│   └── inviteCodeService.ts           # Invite code validation
├── stores/
│   └── useInviteStore.ts              # Invite state management
└── components/
    ├── invite/
    │   └── InviteCodeScreen.tsx       # Invite code entry screen
    └── banners/
        └── AppDownloadBanner.tsx      # App download banner
```

### Modified Files (3)
```
frontend_webapp/src/
├── App.tsx                            # Add conditional invite routing
├── components/navigation/Layout.tsx   # Add app download banner
└── utils/posthogUtils.ts              # Add analytics events
```

---

## Testing Requirements

### Unit Tests
- [ ] `useFeatureFlag` hook with mock PostHog
- [ ] `validateInviteCode` with mock API responses
- [ ] `useInviteStore` state transitions
- [ ] `isValidCodeFormat` validation logic

### Integration Tests
- [ ] InviteCodeScreen with valid/invalid codes
- [ ] Query parameter handling (`?invite_code=XXX`)
- [ ] Skip flow when enabled
- [ ] AppDownloadBanner platform detection

### E2E Tests (Playwright)
- [ ] Full invite-only flow (code entry → onboarding)
- [ ] Skip flow when flag enabled
- [ ] Banner interaction on mobile viewport
- [ ] Deep link handling

---

## Rollout Plan

### Stage 1: Internal Testing (0%)
- Enable `feature_web_invite_only` for internal users only
- Test all flows with valid/invalid codes
- Verify analytics events

### Stage 2: A/B Test (10%)
- Enable for 10% of new web visitors
- Compare metrics: bounce rate, signup rate, invite redemption
- Run for 1 week minimum

### Stage 3: Gradual Rollout (10% → 50% → 100%)
- Based on A/B results, increase rollout
- Monitor bounce rates closely
- Have kill switch ready (`feature_web_invite_only` = false)

---

## Risk Mitigations

| Risk | Mitigation |
|------|------------|
| High bounce rate from aggressive gate | A/B test timing; show value prop first option |
| Invite code sharing on forums | Single-use codes; rate limiting; daily limits |
| User frustration without codes | Skip button option; clear messaging; help resources |
| App store link incorrect/outdated | Environment variable for URLs; fallback to website |

---

## Environment Variables

Add to `.env.example`:
```bash
# Invite-Only Flow
REACT_APP_FEATURE_WEB_INVITE_ONLY=false
REACT_APP_FEATURE_WEB_INVITE_SKIP_ENABLED=true
REACT_APP_FEATURE_APP_DOWNLOAD_BANNER=true

# App Store URLs
REACT_APP_APP_STORE_URL=https://apps.apple.com/app/scenextras/id[APP_ID]
REACT_APP_PLAY_STORE_URL=https://play.google.com/store/apps/details?id=com.scenextras.app
```

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Web → App conversion | >5% | Banner clicks / Banner views |
| Invite code redemption rate | >70% | Codes redeemed / Codes entered |
| Bounce rate (invite screen) | <40% | Exit rate on invite screen |
| Time to onboarding | <30s | First valid code → onboarding start |

---

## Dependencies

- PostHog account with feature flags enabled
- App Store listing URLs (iOS + Android)
- Discord invite link for help
- Marketing assets for app download banner

---

## Estimated Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| Phase 1 | 2-3 hours | Foundation (hooks, services, store) |
| Phase 2 | 4-6 hours | Core components (InviteCodeScreen, Banner) |
| Phase 3 | 2-3 hours | Integration and routing |
| Testing | 2-3 hours | Unit, integration, E2E tests |
| **Total** | **10-15 hours** | Full implementation |

---

## Next Steps

1. [ ] Confirm App Store URLs with team
2. [ ] Create feature flags in PostHog dashboard
3. [ ] Begin Phase 1 implementation
4. [ ] Review with frontend team
5. [ ] Schedule A/B test

---

## Approval

- [ ] Frontend Lead Review
- [ ] Product Manager Approval
- [ ] Design Review (for InviteCodeScreen and Banner UI)
