# Superwall Purchase and Subscription Display Fix

## Problems Fixed

1. **RevenueCat sync wasn't triggering after Superwall purchase**
2. **Account subscription ticket wasn't showing the correct premium tier**

## Solutions Implemented

### 1. Manual RevenueCat Sync After Superwall Purchase
**File:** `mobile_app_sx/hooks/useSuperwall.ts`

Added manual RevenueCat sync trigger when Superwall completes a purchase:

```typescript
if (resultType === 'purchased') {
  // After 2 seconds, manually trigger RevenueCat sync
  setTimeout(async () => {
    // Get current customer info from RevenueCat
    const customerInfo = await purchases.getCustomerInfo();

    // Map entitlements to premium level
    const premiumLevel = mapEntitlementsToPremiumLevel(
      customerInfo.entitlements.active,
      customerInfo.allPurchasedProductIdentifiers
    );

    // Sync to backend
    await syncRevenueCatCustomerInfo(customerInfo, status);

    // Refresh user data from backend
    await userStore.refreshConsolidatedData();
  }, 2000);
}
```

### 2. Fixed Account Subscription Ticket Display
**File:** `mobile_app_sx/app/(tabs)/profile.tsx`

Updated tier detection to use numeric premium level:

```typescript
const currentTierKey = useMemo(() => {
  // First check numeric premium level (most accurate)
  const premiumLevel = userProfile?.premium ?? consolidatedData?.user?.premium;

  if (premiumLevel !== undefined) {
    switch (premiumLevel) {
      case 0: return null;           // Standard User
      case 1: return 'MAX';          // MAX tier
      case 2: return 'PRO';          // PRO tier
      case 3: return 'CREATOR';      // CREATOR tier
    }
  }

  // Fallback to text matching...
}, [userProfile, consolidatedData]);
```

## Complete Purchase Flow with Fixes

```
1. User purchases CREATOR_1 in Superwall
        ↓
2. Superwall completes purchase internally
        ↓
3. useSuperwall hook detects purchase
        ↓
4. [NEW] Manual RevenueCat sync triggered
   ├─ Get customer info from RevenueCat
   ├─ Map entitlements to premium level (0-3)
   ├─ Sync to backend via POST /api/payments/revenuecat/sync
   └─ Refresh user data from backend
        ↓
5. Profile ticket shows correct tier (CREATOR)
```

## New Logs You'll See

After purchase:
```
💰 [SUPERWALL-HOOK] Purchase detected, triggering syncs
🔄 [SUPERWALL-HOOK] Triggering manual RevenueCat sync after purchase
📤 [SUPERWALL-HOOK] Starting manual RevenueCat backend sync
📦 [SUPERWALL-HOOK] Got customer info, syncing to backend
🎯 [RC-PREMIUM-MAP] Mapping entitlements to premium level
🎨 [RC-PREMIUM-MAP] Found CREATOR entitlement (level: 3)
🚀 [RC-BACKEND-SYNC] Starting RevenueCat backend sync
📦 [RC-BACKEND-SYNC] Prepared sync payload (premiumLevel: 3)
🌐 [RC-BACKEND-SYNC] Sending sync request to backend
✅ [SUPERWALL-HOOK] Manual RevenueCat sync completed
🔄 [SUPERWALL-HOOK] Refreshing user data from backend
✅ [SUPERWALL-HOOK] User data refreshed
```

In Profile:
```
[Profile] User profile data: {
  subscription: 'Premium',
  premium: 3,
  consolidatedPremium: 3
}
[Profile] Using premium level for tier: 3
```

## Why This Was Needed

Superwall's internal purchase mechanism doesn't automatically trigger our custom purchase controller. The purchase happens through Superwall's SDK directly, bypassing our `SuperwallRevenueCatProvider` controller. This fix adds a manual sync that:

1. Detects when Superwall completes a purchase
2. Fetches the updated entitlements from RevenueCat
3. Maps them to the correct premium level (0-3)
4. Syncs to backend
5. Refreshes user data
6. Updates the UI with correct tier

## Testing

1. Purchase a subscription (e.g., CREATOR_1)
2. Check logs for sync messages
3. Verify profile ticket shows correct tier (CREATOR, not generic "Premium")
4. Backend should receive `premiumLevel: 3` in sync payload

## Backend Requirement

The backend must process the `premiumLevel` field from the sync payload:

```python
@router.post("/api/payments/revenuecat/sync")
async def sync_revenuecat_status(payload):
    # Use premiumLevel from payload
    user.premium = payload.premium_level  # 0, 1, 2, or 3
    db.session.commit()
```

This ensures the database always reflects the correct tier from RevenueCat entitlements.