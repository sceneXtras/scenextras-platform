# Settings Page Crash Fix (iOS)

**Issue ID:** br_17c3398a-7da8-4184-9bd0-08b18d087838  
**Severity:** Critical  
**Platform:** iOS  
**Symptom:** Settings page shows white screen then crashes. Restart fixes temporarily.

## Root Cause Analysis

Common causes for this crash pattern in React Native/Expo:

1. **Uninitialized State Access**: Component tries to access user data before store initialization
2. **Missing Error Boundary**: Unhandled errors cause white screen of death
3. **Async Race Condition**: Data loading conflicts with component mount
4. **Memory Leak**: Previous screen not properly cleaned up
5. **Invalid Hook Usage**: Conditional hooks or hooks after return statement

## Solution

### 1. Add Error Boundary to Settings Screen

**File**: `mobile_app_sx/app/(drawer)/(tabs)/settings.tsx` or `profile.tsx`

```typescript
import React from 'react';
import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }) {
  return (
    <View style={styles.errorContainer}>
      <Text style={styles.errorTitle}>Something went wrong</Text>
      <Text style={styles.errorMessage}>{error.message}</Text>
      <Button title="Try Again" onPress={resetErrorBoundary} />
    </View>
  );
}

export default function SettingsScreen() {
  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onReset={() => {
        // Reset state here
      }}
      onError={(error, errorInfo) => {
        // Log to Sentry
        console.error('Settings screen error:', error, errorInfo);
      }}
    >
      <SettingsContent />
    </ErrorBoundary>
  );
}
```

### 2. Add Loading State Protection

**File**: `mobile_app_sx/app/(drawer)/(tabs)/settings.tsx`

```typescript
import { useUserStore } from '../../../store/userStore';

function SettingsContent() {
  const user = useUserStore((state) => state.user);
  const isLoading = useUserStore((state) => state.isLoading);
  const [isReady, setIsReady] = React.useState(false);

  React.useEffect(() => {
    // Ensure store is initialized before rendering
    const timer = setTimeout(() => setIsReady(true), 100);
    return () => clearTimeout(timer);
  }, []);

  if (isLoading || !isReady) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  if (!user) {
    return (
      <View style={styles.errorContainer}>
        <Text>Unable to load user settings</Text>
      </View>
    );
  }

  return (
    <ScrollView>
      {/* Settings UI */}
    </ScrollView>
  );
}
```

### 3. Fix Store Initialization Race Condition

**File**: `mobile_app_sx/store/userStore.ts`

```typescript
import create from 'zustand';
import { persist } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV();

interface UserStore {
  user: User | null;
  isLoading: boolean;
  isInitialized: boolean;
  initialize: () => Promise<void>;
}

export const useUserStore = create<UserStore>()(
  persist(
    (set, get) => ({
      user: null,
      isLoading: false,
      isInitialized: false,
      
      initialize: async () => {
        if (get().isInitialized) return;
        
        set({ isLoading: true });
        try {
          // Load user data
          const userData = await fetchUserData();
          set({ user: userData, isLoading: false, isInitialized: true });
        } catch (error) {
          console.error('Failed to initialize user store:', error);
          set({ isLoading: false, isInitialized: true });
        }
      },
    }),
    {
      name: 'user-store',
      storage: {
        getItem: (name) => storage.getString(name) ?? null,
        setItem: (name, value) => storage.set(name, value),
        removeItem: (name) => storage.delete(name),
      },
    }
  )
);

// Initialize on app start
useUserStore.getState().initialize();
```

### 4. Add Proper Cleanup

**File**: `mobile_app_sx/app/(drawer)/(tabs)/settings.tsx`

```typescript
function SettingsContent() {
  React.useEffect(() => {
    // Component mounted
    let isMounted = true;

    const loadData = async () => {
      try {
        // Load any async data
        const data = await fetchSettingsData();
        if (isMounted) {
          setSettingsData(data);
        }
      } catch (error) {
        if (isMounted) {
          console.error('Error loading settings:', error);
        }
      }
    };

    loadData();

    return () => {
      // Cleanup on unmount
      isMounted = false;
    };
  }, []);
}
```

### 5. Add Defensive Null Checks

**File**: Throughout Settings screen

```typescript
// Before
<Text>{user.name}</Text>
<Text>{user.email}</Text>

// After
<Text>{user?.name ?? 'Unknown'}</Text>
<Text>{user?.email ?? 'No email'}</Text>

// Or use optional chaining with fallback
const userName = user?.name || 'Guest';
const userEmail = user?.email || 'Not provided';
```

## Implementation Steps

1. Install react-error-boundary if not present:
   ```bash
   cd mobile_app_sx
   bun add react-error-boundary
   ```

2. Apply error boundary to Settings screen
3. Add loading state checks
4. Fix store initialization
5. Add cleanup in useEffect hooks
6. Add null safety checks throughout

## Testing

1. Test fresh install (no cached data)
2. Test with slow network
3. Test rapid navigation to Settings
4. Test after app has been in background
5. Monitor Sentry for any remaining errors

## Feature Flag

```typescript
// Wrap fix behind feature flag
import { useFeatureFlagEnabled } from 'posthog-js/react';

export default function SettingsScreen() {
  const useNewSettingsErrorHandling = useFeatureFlagEnabled('feature_settings_crash_fix');
  
  if (useNewSettingsErrorHandling) {
    return <SettingsScreenWithErrorBoundary />;
  }
  
  return <LegacySettingsScreen />;
}
```

## Rollout Plan

1. Deploy with feature flag at 0%
2. Test internally with flag at 100% for team
3. Gradual rollout: 10% → 25% → 50% → 100%
4. Monitor crash rate in PostHog/Sentry
5. If crashes reduce by >90%, complete rollout

## Success Metrics

- Settings page crash rate < 0.1%
- No white screen reports
- Successful loads > 99.9%
- Time to interactive < 500ms

## Notes

- The temporary fix after restart suggests a state/memory issue
- iOS-specific indicates possible React Native bridge timing issue  
- Critical severity requires immediate rollout after validation
