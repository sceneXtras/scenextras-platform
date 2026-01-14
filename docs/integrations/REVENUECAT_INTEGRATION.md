# RevenueCat Integration Guide

## Overview

RevenueCat manages subscription and in-app purchase functionality across web and mobile platforms. This guide covers configuration, implementation, and common issues.

---

## Configuration

### Environment Variables

**React Web** (`frontend_webapp/.env`):
```
REACT_APP_REVENUECAT_WEB_KEY=pk_web_xxxxx  # Web API key
```

**React Native** (`mobile_app_sx/.env`):
```
# RevenueCat is configured in native code (iOS/Android)
# Depends on REVENUECAT_SDK_KEY in Xcode/Android Studio
```

---

## Implementation Details

### Web (React)

**Location:** `frontend_webapp/src/services/revenueCat.ts`

**Features:**
- Customer identification
- Subscription status checking
- Entitlement access control
- Premium feature gating

**Initialization:**
```typescript
// RevenueCat client initialized with web API key
// Customer linked to authenticated user
```

### Mobile (React Native)

**Location:** `mobile_app_sx/services/revenueCat.ts`

**Features:**
- In-app purchase processing
- Subscription management
- Trial period handling
- Platform-specific store integration (Apple App Store, Google Play)

**Implementation:**
- Native modules handle platform-specific purchase flows
- Custom hook `useRevenueCat()` provides subscription status
- Zustand store manages premium features state

---

## Features & Entitlements

### Premium Features

RevenueCat controls access to:
- Premium character conversations
- Advanced chat features
- Extended message history
- Priority support
- Ad-free experience

### Subscription Types

- **Monthly subscription** - Recurring monthly charge
- **Annual subscription** - Discounted yearly option
- **Trial period** - Free trial before billing

---

## Common Issues & Fixes

### Mobile Initialization Issue

**Problem:** RevenueCat initialization failures on app startup
**Status:** Fixed
**Solution:** Init called during app bootstrap with proper error handling

**Reference:** See historical fixes in `/docs/archive/fixes/payments/REVENUECAT_MOBILE_INIT_FIX.md`

### Premium Mapping Issue

**Problem:** Incorrect mapping between RevenueCat entitlements and app features
**Status:** Fixed
**Solution:** Centralized entitlement mapping in constants

**Reference:** See historical fixes in `/docs/archive/fixes/payments/REVENUECAT_PREMIUM_MAPPING_IMPLEMENTATION.md`

### Safety Check Implementation

**Problem:** Missing validation of subscription status
**Status:** Fixed
**Solution:** Added comprehensive safety checks before premium feature access

**Reference:** See historical fixes in `/docs/archive/fixes/payments/REVENUECAT_SAFETY_CHECK_IMPLEMENTATION.md`

### Web Integration

**Problem:** RevenueCat integration specific to web platform
**Status:** Implemented
**Solution:** Separate web configuration and API key handling

**Reference:** See historical implementation in `/docs/archive/fixes/payments/REVENUECAT_WEB_INTEGRATION.md`

---

## API Integration

### Get User Entitlements

```typescript
// Check if user has premium access
const customer = await Purchases.getCustomerInfo();
const isPremium = customer.entitlements.active['premium'] !== undefined;
```

### Handle Subscription Changes

```typescript
// Listen for subscription updates
Purchases.addCustomerInfoUpdateListener((customerInfo) => {
  updatePremiumStatus(customerInfo);
});
```

---

## Testing

### Test Entitlements

**iOS:**
- Sandbox testing credentials in Test Flight
- Sandbox subscriptions don't charge

**Android:**
- License testing accounts in Google Play Console
- Use test billing to avoid charges

**Web:**
- Use test mode API key for development
- No charges in test mode

---

## Troubleshooting

### Entitlements Not Loading

1. **Verify API key** is correct in environment
2. **Check network connectivity** for RevenueCat API
3. **Review Sentry logs** for initialization errors
4. **Test with valid credentials** in sandbox

### Subscription Status Not Updating

1. **Check customer is identified** with correct ID
2. **Verify entitlement key** matches configuration
3. **Test manual refresh** of customer info
4. **Review RevenueCat dashboard** for issues

### Missing Subscription Products

1. **Verify products created** in RevenueCat dashboard
2. **Check platform stores** (App Store, Play Store) have products
3. **Review mapping** between platform products and entitlements
4. **Test with test products** in sandbox

---

## Best Practices

1. **Always identify customers** before checking entitlements
2. **Use try/catch** around RevenueCat API calls
3. **Cache entitlement status** to reduce API calls
4. **Implement offline graceful degradation**
5. **Monitor subscription errors** in production
6. **Test subscription flows** regularly
7. **Keep RevenueCat SDK updated**

---

## References

- **Web Service:** `frontend_webapp/src/services/revenueCat.ts`
- **Mobile Service:** `mobile_app_sx/services/revenueCat.ts`
- **Payment Store:** `mobile_app_sx/store/paymentsStore.ts`
- **RevenueCat Dashboard:** https://app.revenuecat.com

---

## Historical Implementation Iterations

This document consolidates 4 previous implementation and fix documents. Detailed implementation history is available in `/docs/archive/fixes/payments/` if needed for reference.
