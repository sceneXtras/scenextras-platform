# Deployment Guide: Test8 Login Button iOS Fix

**Bug Report ID:** br_40a8ee69-c10e-4dac-8057-f9cb38d6bd74  
**Severity:** Critical  
**Target:** mobile_app_sx repository  

## Prerequisites

- Access to the `mobile_app_sx` repository
- iOS development environment (Xcode, iOS Simulator)
- Expo CLI installed
- Node.js and npm/yarn/bun
- Active Expo OTA deployment access

## Step-by-Step Deployment

### 1. Access the Mobile App Repository

```bash
# Clone or navigate to the mobile app repository
cd /path/to/mobile_app_sx

# Create a fix branch
git checkout -b fix/ios-login-button-unresponsive
```

### 2. Locate the Login Screen File

The login screen is likely in one of these locations:
```
mobile_app_sx/app/(auth)/login.tsx
mobile_app_sx/screens/LoginScreen.tsx
mobile_app_sx/src/screens/Auth/LoginScreen.tsx
mobile_app_sx/components/Auth/LoginScreen.tsx
```

Use this command to find it:
```bash
find . -type f -name "*[Ll]ogin*" | grep -iE "(screen|tsx|jsx)" | grep -v node_modules
```

### 3. Apply the Fix

Open the login screen file and apply these changes:

#### Change 1: Update TouchableOpacity Props

**Find:**
```tsx
<TouchableOpacity onPress={handleLogin}>
```

**Replace with:**
```tsx
<TouchableOpacity 
  onPress={handleLogin}
  disabled={isLoading}
  activeOpacity={0.7}
  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
>
```

#### Change 2: Fix Loading State

**Ensure the loading state is inside the button:**
```tsx
<TouchableOpacity 
  onPress={handleLogin}
  disabled={isLoading}
  activeOpacity={0.7}
  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
  style={[styles.button, isLoading && styles.buttonDisabled]}
>
  {isLoading ? (
    <ActivityIndicator color="#fff" testID="loading-indicator" />
  ) : (
    <Text style={styles.buttonText}>Login</Text>
  )}
</TouchableOpacity>
```

#### Change 3: Memoize the Handler

**Update the login handler:**
```tsx
const handleLogin = useCallback(async () => {
  if (isLoading) return; // Prevent double-tap
  
  setIsLoading(true);
  try {
    await performLogin(email, password);
  } catch (error) {
    console.error('Login failed:', error);
    // Show error to user
  } finally {
    setIsLoading(false); // Always clear loading state
  }
}, [email, password, isLoading]);
```

#### Change 4: Fix Parent View Pointer Events

**Check parent views and ensure they don't block touches:**
```tsx
<View pointerEvents="box-none"> {/* or "auto", not "none" */}
  {/* login form content */}
</View>
```

### 4. Test Locally

#### Run on iOS Simulator:
```bash
cd mobile_app_sx
bun install  # or npm install
./run.sh --ios

# Alternative:
npx expo start --ios
```

#### Manual Test Checklist:
- [ ] Login button responds immediately to tap
- [ ] Visual feedback appears (button dims)
- [ ] Loading spinner appears correctly
- [ ] Login completes successfully
- [ ] Button becomes re-enabled after login
- [ ] No console errors
- [ ] Works with keyboard open
- [ ] Works after multiple taps (double-tap prevention)

### 5. Run Automated Tests

```bash
# Run existing tests
bun run test  # or npm test

# Run type checking
bun run typecheck
```

### 6. Test on Real iOS Device

```bash
# Build for iOS device
npx expo run:ios --device
```

Test on:
- [ ] iOS 14.x
- [ ] iOS 15.x
- [ ] iOS 16.x
- [ ] iOS 17.x
- [ ] Different screen sizes (iPhone SE, iPhone 14 Pro Max)

### 7. Deploy to Staging (If Available)

```bash
# Deploy to staging via Expo OTA
npx eas update --branch staging --message "Fix iOS login button touch issue"
```

### 8. Deploy to Production

#### Option A: Expo OTA Update (Recommended for Quick Fix)
```bash
# Deploy OTA update to production
npx eas update --branch production --message "Fix: iOS login button unresponsive (br_40a8ee69)"

# Or if using specific channel:
npx eas update --channel production --message "Critical fix: iOS login button"
```

#### Option B: Full App Store Release
```bash
# Build production iOS app
npx eas build --platform ios --profile production

# Submit to App Store after build completes
npx eas submit --platform ios
```

**Note:** OTA updates are faster (immediate) but only work for JavaScript changes.
If native code changed, a full app store release is required.

### 9. Verify Deployment

After OTA deployment:
1. Wait 5-10 minutes for OTA distribution
2. Close and reopen the app on test device
3. Verify fix is applied (check console logs for new version)
4. Test login button functionality
5. Monitor Sentry/PostHog for any errors

### 10. Monitor & Rollback Plan

#### Monitoring:
```bash
# Check Expo deployment status
npx eas update:list --branch production

# Monitor logs
./run.sh --web
tail -f logs/server.log
```

#### Quick Rollback (if needed):
```bash
# Rollback to previous OTA version
npx eas update:rollback --branch production

# Alternative: Re-deploy previous working commit
git revert <commit-hash>
npx eas update --branch production --message "Rollback login fix"
```

### 11. Update Bug Report

Once deployed and verified:
1. Close the GitHub issue #6
2. Add comment with deployment details
3. Update PostHog/Sentry with fix notes
4. Notify stakeholders

```bash
# Example comment for issue:
gh issue comment 6 --body "Fixed in commit 81986c4. Deployed via OTA update. Verified on iOS 14-17."
gh issue close 6
```

## Verification Script

Create a simple test to verify the fix:

```typescript
// mobile_app_sx/__tests__/login-button-fix.test.ts
import { render, fireEvent } from '@testing-library/react-native';
import LoginScreen from '../app/(auth)/login';

test('iOS login button responds to press', async () => {
  const { getByTestId } = render(<LoginScreen />);
  const button = getByTestId('login-button');
  
  // Verify iOS touch props exist
  expect(button.props.activeOpacity).toBe(0.7);
  expect(button.props.hitSlop).toBeTruthy();
  
  // Test press works
  const mockPress = jest.fn();
  button.props.onPress = mockPress;
  fireEvent.press(button);
  expect(mockPress).toHaveBeenCalled();
});
```

## Post-Deployment Checklist

- [ ] OTA update deployed successfully
- [ ] Tested on iOS simulator
- [ ] Tested on real iOS device
- [ ] No new errors in Sentry
- [ ] PostHog analytics showing successful logins
- [ ] GitHub issue #6 closed
- [ ] Documentation updated
- [ ] Team notified of fix
- [ ] Monitoring active for 24 hours

## Rollback Triggers

Rollback immediately if:
- New crashes appear in Sentry related to login
- Login success rate drops below 95%
- User reports of inability to login increase
- Performance degradation detected

## Support Resources

- [React Native TouchableOpacity Docs](https://reactnative.dev/docs/touchableopacity)
- [Expo OTA Updates Guide](https://docs.expo.dev/eas-update/introduction/)
- [iOS Touch Event Debugging](https://reactnative.dev/docs/debugging)

## Contact

For issues with deployment:
- Check #dev-mobile-app Slack channel
- Review logs in Sentry
- Check Expo dashboard for build/update status
