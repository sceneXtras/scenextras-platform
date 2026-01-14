# RevenueCat Premium Level Mapping Implementation

## Overview
Implemented a comprehensive solution where **RevenueCat entitlements OVERRIDE database premium levels**, ensuring subscription status is always synchronized correctly from the mobile app to the backend.

## Premium Level Mapping
```
NORMAL   = 0  (Free/Standard User)
MAX      = 1  (MAX/Basic Premium tier)
PRO      = 2  (PRO/Advanced Premium tier)
CREATOR  = 3  (CREATOR/Highest Premium tier)
```

## Key Changes Implemented

### 1. RevenueCat Backend Sync Service
**File:** `mobile_app_sx/services/revenueCatBackendSync.ts`

#### Added Premium Level Enum
```typescript
export enum PremiumLevel {
  NORMAL = 0,   // Free/Standard User
  MAX = 1,      // MAX/Basic Premium tier
  PRO = 2,      // PRO/Advanced Premium tier
  CREATOR = 3,  // CREATOR/Highest Premium tier
}
```

#### Created Entitlement Mapping Function
```typescript
export function mapEntitlementsToPremiumLevel(
  entitlements: Record<string, PurchasesEntitlementInfo> | undefined,
  productIds: string[] = []
): PremiumLevel
```

This function:
- Maps RevenueCat entitlement IDs to premium levels
- Supports product IDs: `CREATOR_1`, `MAX`, `PRO`, `2222`, `3333`, `4444`
- Returns the highest premium level from active entitlements
- Defaults to `PremiumLevel.MAX` for any unrecognized active entitlement
- Returns `PremiumLevel.NORMAL` if no active entitlements

#### Updated Sync Payload
Added `premiumLevel` field to the sync payload:
```typescript
interface RevenueCatSyncPayload {
  // ... existing fields ...
  premiumLevel: PremiumLevel; // CRITICAL: OVERRIDES database value
}
```

### 2. Superwall RevenueCat Provider
**File:** `mobile_app_sx/components/providers/SuperwallRevenueCatProvider.tsx`

#### Added Premium Level to Subscription Mapping
```typescript
const mapPremiumLevelToSubscription = (premiumLevel: PremiumLevel): UserProfile['subscription'] => {
  switch (premiumLevel) {
    case PremiumLevel.NORMAL: return 'Standard User';
    case PremiumLevel.MAX:    return 'Premium';
    case PremiumLevel.PRO:    return 'Premium';
    case PremiumLevel.CREATOR: return 'Premium';
  }
}
```

#### Enhanced Subscription Persistence
The `persistSubscriptionStatus` function now:
1. Maps entitlements to premium level FIRST (source of truth)
2. Updates local store with BOTH subscription string AND numeric premium level
3. Syncs to backend with premium level override flag

### 3. API Client Enhanced Logging
**File:** `mobile_app_sx/src/lib/apiClient.ts`

Added comprehensive logging for POST requests to track:
- Request start/end timestamps
- Payload size
- Response status and duration
- Full error stack traces

### 4. User Store Enhanced Logging
**File:** `mobile_app_sx/store/userStore.ts`

Added special logging for subscription changes:
```typescript
if (subscription changed) {
  logger.info('🎉 [USER-STORE] SUBSCRIPTION CHANGED', {
    from: 'Standard User',
    to: 'Premium',
    change: 'Standard User → Premium'
  });
}
```

### 5. Type Definitions
**File:** `mobile_app_sx/types/index.ts`

Updated UserProfile interface:
```typescript
export interface UserProfile {
  subscription: 'Standard User' | 'Premium';
  premium?: number; // 0-3, matches backend User.premium
  // ... other fields
}
```

## Data Flow

```
1. User purchases subscription in Superwall paywall
   ↓
2. RevenueCat processes purchase, returns CustomerInfo
   ↓
3. mapEntitlementsToPremiumLevel() determines premium level
   ↓
4. Local store updated with premium level + subscription string
   ↓
5. POST /api/payments/revenuecat/sync with:
   {
     premiumLevel: 0-3,  // OVERRIDES database
     entitlements: [...],
     status: 'ACTIVE'/'INACTIVE'
   }
   ↓
6. Backend updates User.premium = premiumLevel from payload
```

## Log Output Examples

### Purchase Flow Logs
```
💳 [RC-SUPERWALL] Purchase requested from Superwall
🎯 [RC-PREMIUM-MAP] Mapping entitlements to premium level
🎨 [RC-PREMIUM-MAP] Found CREATOR entitlement (level: 3)
✅ [RC-PREMIUM-MAP] Final premium level determined: CREATOR
💾 [RC-SUPERWALL] Starting subscription persistence
📝 [RC-SUPERWALL] Updating local user store subscription and premium level
🎉 [USER-STORE] SUBSCRIPTION CHANGED: Standard User → Premium
📤 [RC-SUPERWALL] Syncing to backend with premium override
🚀 [RC-BACKEND-SYNC] Starting RevenueCat backend sync
🎯 [RC-BACKEND-SYNC] Premium level determined from entitlements: 3 (CREATOR)
📦 [RC-BACKEND-SYNC] Prepared sync payload (premiumLevel: 3)
🌐 [RC-BACKEND-SYNC] Sending sync request to backend
📤 [API-CLIENT] POST request starting: /api/payments/revenuecat/sync
📥 [API-CLIENT] POST response received (status: 200, duration: 145ms)
✅ [RC-BACKEND-SYNC] RevenueCat backend sync completed successfully
```

## Backend Requirements

The backend endpoint at `/api/payments/revenuecat/sync` must:

1. Read the `premiumLevel` field from the payload
2. **OVERRIDE** the existing `User.premium` value with this level
3. Update the database: `user.premium = payload.premiumLevel`

Example backend handler:
```python
@router.post("/api/payments/revenuecat/sync")
async def sync_revenuecat_status(payload: RevenueCatSyncPayload):
    # CRITICAL: Use premium level from RevenueCat as source of truth
    user.premium = payload.premium_level  # 0-3

    # Update subscription status
    if payload.status == "ACTIVE":
        user.subscription_status = "active"
    else:
        user.subscription_status = "inactive"

    db.session.commit()
    return {"status": "synced", "premium": user.premium}
```

## Testing the Implementation

1. **View logs during purchase**:
   - Filter by `[RC-PREMIUM-MAP]` to see entitlement mapping
   - Filter by `[USER-STORE]` to see subscription changes
   - Filter by `[RC-BACKEND-SYNC]` to see backend sync

2. **Verify premium level override**:
   - Purchase `CREATOR_1` product → Should set premium=3
   - Purchase `MAX` product → Should set premium=1
   - Purchase `PRO` product → Should set premium=2
   - No active entitlements → Should set premium=0

3. **Check payload**:
   - Look for `📨 [RC-BACKEND-SYNC] Full sync payload` in DEBUG logs
   - Verify `premiumLevel` field is included and correct

## Benefits of This Implementation

✅ **Single Source of Truth**: RevenueCat entitlements always override database
✅ **Tier Preservation**: Premium levels (0-3) maintain tier distinction
✅ **Complete Traceability**: Every step is logged with timestamps
✅ **Error Recovery**: Failed syncs are logged with full context
✅ **Backward Compatible**: Works with existing backend premium field
✅ **Future-Proof**: Easy to add new tiers or modify mappings

## Next Steps for Backend

The backend should:
1. Accept the `premiumLevel` field from the payload
2. Always override `User.premium` with the RevenueCat value
3. Return the updated premium level in the response
4. Invalidate any cached user data after update