# Chat Business Flows & Quota System

This document explains the business logic behind chat quotas, user tiers, and monetization in SceneXtras.

---

## Master Overview: Complete Chat Business Flow

```mermaid
flowchart TD
    subgraph UserTypes["User Types"]
        Free[Free User]
        Max[MAX Subscriber]
        Pro[PRO Subscriber]
        Creator[CREATOR Subscriber]
    end

    subgraph QuotaSystem["Quota System"]
        DailyQuota[Daily Chat Quota]
        PremiumQuota[Premium Model Quota]
        StoryQuota[Story Creation Quota]
        MediaQuota[Video/Image Quota]
    end

    subgraph ChatFlow["Chat Message Flow"]
        UserSends[User Sends Message]
        CheckQuota{Quota Available?}
        ProcessChat[Process Chat with LLM]
        DecrementQuota[Decrement Quota]
        StreamResponse[Stream AI Response]
        TriggerPaywall[Show Paywall]
    end

    subgraph Replenishment["Quota Replenishment"]
        DailyCron[Daily Cron Job]
        MonthlyCron[Monthly Cron Job]
        ReferralBonus[Referral Bonus]
    end

    subgraph Monetization["Monetization"]
        Paywall[Superwall Paywall]
        Stripe[Stripe Checkout]
        RevenueCat[RevenueCat Mobile]
        UpgradeTier[Upgrade User Tier]
    end

    Free --> DailyQuota
    Max --> DailyQuota
    Pro --> DailyQuota
    Creator --> DailyQuota

    DailyQuota --> UserSends
    PremiumQuota --> UserSends

    UserSends --> CheckQuota
    CheckQuota -->|Yes| ProcessChat
    CheckQuota -->|No - 402 Error| TriggerPaywall

    ProcessChat --> DecrementQuota
    DecrementQuota --> StreamResponse

    TriggerPaywall --> Paywall
    Paywall --> Stripe
    Paywall --> RevenueCat
    Stripe --> UpgradeTier
    RevenueCat --> UpgradeTier
    UpgradeTier --> DailyQuota

    DailyCron --> DailyQuota
    DailyCron --> PremiumQuota
    MonthlyCron --> StoryQuota
    ReferralBonus --> DailyQuota
```

---

## 1. User Tier Hierarchy

```mermaid
flowchart TD
    subgraph Tiers["Subscription Tiers"]
        direction TB
        FREE["FREE
        premium = 0
        No subscription"]

        MAX["MAX
        premium = 1
        Entry Premium"]

        PRO["PRO
        premium = 2
        Mid-tier Premium"]

        CREATOR["CREATOR
        premium = 3
        Highest Premium"]
    end

    FREE -->|Upgrade| MAX
    MAX -->|Upgrade| PRO
    PRO -->|Upgrade| CREATOR

    CREATOR -->|Downgrade/Cancel| PRO
    PRO -->|Downgrade/Cancel| MAX
    MAX -->|Cancel| FREE
```

### Tier Benefits Summary

| Feature | FREE | MAX | PRO | CREATOR |
|---------|------|-----|-----|---------|
| Daily Chat Quota | 60 | Unlimited | Unlimited | Unlimited |
| Premium Models/month | 5 | 50 | 300 | 10,000 |
| Stories/month | 1 | 10 | 20 | 100 |
| Video/Image per week | 2 | 10 | 10 | 10 |
| Priority Queue | No | No | Yes | Yes |
| API Access | No | No | No | Yes |

---

## 2. Quota Types & Limits

```mermaid
flowchart LR
    subgraph QuotaTypes["Quota Categories"]
        direction TB

        subgraph Daily["Daily Quotas"]
            Chat[Regular Chat]
            PremiumModel[Premium Model Usage]
        end

        subgraph Monthly["Monthly Quotas"]
            Story[Story Creation]
        end

        subgraph Weekly["Weekly Quotas"]
            Video[Video Generation]
            Image[Image Generation]
            VideoUnderstand[Video Understanding]
        end
    end

    Chat -->|Replenish| DailyCron[Daily Cron]
    PremiumModel -->|Replenish| DailyCron
    Story -->|Reset| MonthlyCron[Monthly Cron]
    Video -->|Reset| WeeklyCron[Weekly Reset]
    Image -->|Reset| WeeklyCron
```

### Quota Limits by Tier

```mermaid
flowchart TD
    subgraph FreeQuotas["FREE Tier Quotas"]
        F1[Chat: 60/day cap]
        F2[Premium Models: 5/month]
        F3[Stories: 1/month]
        F4[Video/Image: 2/week]
    end

    subgraph MaxQuotas["MAX Tier Quotas"]
        M1[Chat: Unlimited]
        M2[Premium Models: 50/month]
        M3[Stories: 10/month]
        M4[Video/Image: 10/week]
    end

    subgraph ProQuotas["PRO Tier Quotas"]
        P1[Chat: Unlimited]
        P2[Premium Models: 300/month]
        P3[Stories: 20/month]
        P4[Video/Image: 10/week]
    end

    subgraph CreatorQuotas["CREATOR Tier Quotas"]
        C1[Chat: Unlimited]
        C2[Premium Models: 10,000/month]
        C3[Stories: 100/month]
        C4[Video/Image: 10/week]
    end
```

---

## 3. Quota Consumption Flow

```mermaid
sequenceDiagram
    participant User as User
    participant Mobile as Mobile App
    participant Gateway as Auth Gateway
    participant API as Python API
    participant LLM as LLM Service
    participant DB as Database

    User->>Mobile: Type message, tap Send
    Mobile->>Gateway: POST /chat/message

    Gateway->>DB: Check user.quota

    alt Quota Available
        DB-->>Gateway: quota >= 1
        Gateway->>API: Forward request
        API->>LLM: Stream LLM request
        LLM-->>API: Stream response chunks
        API-->>Mobile: Stream response
        API->>DB: UPDATE quota = quota - 1
        DB-->>API: Quota decremented
        Mobile->>Mobile: Update local quota display
    else Quota Exhausted
        DB-->>Gateway: quota < 1
        Gateway-->>Mobile: 402 Payment Required
        Mobile->>Mobile: Show Paywall
    end
```

### Key Points
- **When decremented**: After successful LLM response (not on send)
- **Where checked**: Go Auth Gateway (before forwarding to API)
- **Error code**: HTTP 402 Payment Required

---

## 4. Paywall Trigger Flow

```mermaid
flowchart TD
    Start[User Action] --> CheckType{Action Type?}

    CheckType -->|Send Chat| CheckChatQuota{Chat Quota > 0?}
    CheckType -->|Use Premium Model| CheckPremiumQuota{Premium Quota > 0?}
    CheckType -->|Create Story| CheckStoryQuota{Story Quota > 0?}
    CheckType -->|Generate Video| CheckVideoQuota{Video Quota > 0?}

    CheckChatQuota -->|Yes| ProcessChat[Process Chat]
    CheckChatQuota -->|No| Show402[Return 402]

    CheckPremiumQuota -->|Yes| ProcessPremium[Process Premium]
    CheckPremiumQuota -->|No| Show402

    CheckStoryQuota -->|Yes| ProcessStory[Process Story]
    CheckStoryQuota -->|No| Show402

    CheckVideoQuota -->|Yes| ProcessVideo[Process Video]
    CheckVideoQuota -->|No| Show402

    Show402 --> PaywallUI[Display Paywall UI]

    PaywallUI --> UserChoice{User Choice}

    UserChoice -->|Subscribe| SelectTier[Select Tier]
    UserChoice -->|Dismiss| ReturnToApp[Return to App]

    SelectTier --> Payment[Process Payment]
    Payment -->|Success| UpgradeUser[Upgrade User Tier]
    Payment -->|Failed| PaywallUI

    UpgradeUser --> RefreshQuotas[Refresh All Quotas]
    RefreshQuotas --> ProcessChat
```

---

## 5. Daily Quota Replenishment

```mermaid
flowchart TD
    subgraph DailyCron["Daily Cron Job - Midnight UTC"]
        Start[Cron Triggers] --> GetUsers[Get All Users]
        GetUsers --> Loop[For Each User]

        Loop --> CheckTier{User Tier?}

        CheckTier -->|FREE| FreeReplenish[Add 100 credits, cap at 60]
        CheckTier -->|MAX/PRO/CREATOR| PremiumReplenish[Add 20 premium credits, cap at 20]

        FreeReplenish --> UpdateDB[Update Database]
        PremiumReplenish --> UpdateDB

        UpdateDB --> NextUser[Next User]
        NextUser --> Loop
    end

    subgraph Result["After Replenishment"]
        FreeUser[FREE: Up to 60 chat credits]
        PremiumUser[Premium: Up to 20 premium model credits]
    end

    UpdateDB --> FreeUser
    UpdateDB --> PremiumUser
```

### Replenishment Rules

**How it works:** Daily task sets quota TO the cap if below it (doesn't add to existing).

| User Type | Quota Type | Daily Minimum | Behavior | Source |
|-----------|------------|---------------|----------|--------|
| FREE | Regular Chat | 60 | Set to 60 if below | `quotas_config.py:30` |
| FREE | Premium Model | 5 | Set to 5 if below | `quotas_config.py:49` |
| MAX | Premium Model | 20 | Set to 20 if below | `quotas_config.py:50` |
| PRO/CREATOR | Premium Model | - | Monthly only | `models.py:776-777` |

**Example:** FREE user with 30 credits → daily task → 60 credits (not 130)

---

## 6. Monthly Quota Reset

```mermaid
flowchart TD
    subgraph MonthlyCron["Monthly Cron Job - 1st of Month"]
        Start[Cron Triggers] --> GetUsers[Get All Users]
        GetUsers --> Loop[For Each User]

        Loop --> CheckTier{User Tier?}

        CheckTier -->|FREE| FreeReset[Reset story quota to 1]
        CheckTier -->|MAX| MaxReset[Reset story quota to 10]
        CheckTier -->|PRO| ProReset[Reset story quota to 20]
        CheckTier -->|CREATOR| CreatorReset[Reset story quota to 100]

        FreeReset --> ResetPremium[Reset premium model monthly limit]
        MaxReset --> ResetPremium
        ProReset --> ResetPremium
        CreatorReset --> ResetPremium

        ResetPremium --> UpdateDB[Update Database]
        UpdateDB --> NextUser[Next User]
        NextUser --> Loop
    end
```

---

## 7. Premium Tier Pricing

```mermaid
flowchart TD
    subgraph Pricing["Subscription Pricing"]
        direction TB

        subgraph MaxPricing["MAX Tier"]
            MaxWeek["Weekly: $2.99"]
            MaxMonth["Monthly: $11.99"]
            MaxYear["Annual: ~$99"]
        end

        subgraph ProPricing["PRO Tier"]
            ProWeek["Weekly: $4.99"]
            ProMonth["Monthly: $19.99"]
            ProYear["Annual: $199.99"]
        end

        subgraph CreatorPricing["CREATOR Tier"]
            CreatorWeek["Weekly: $7.99"]
            CreatorMonth["Monthly: $29.99"]
            CreatorYear["Annual: $299.99"]
        end
    end

    MaxWeek --> Stripe[Stripe Checkout]
    MaxMonth --> Stripe
    MaxYear --> Stripe
    ProWeek --> Stripe
    ProMonth --> Stripe
    ProYear --> Stripe
    CreatorWeek --> Stripe
    CreatorMonth --> Stripe
    CreatorYear --> Stripe

    Stripe --> Webhook[Stripe Webhook]
    Webhook --> UpdateUser[Update User Premium Status]
```

### Price Comparison

| Period | MAX | PRO | CREATOR |
|--------|-----|-----|---------|
| Weekly | $2.99 | $4.99 | $7.99 |
| Monthly | $11.99 | $19.99 | $29.99 |
| Annual | ~$99 | $199.99 | $299.99 |

---

## 8. Referral Bonus System

```mermaid
flowchart TD
    subgraph ReferralFlow["Referral Bonus Flow"]
        NewUser[New User Signs Up] --> HasCode{Has Referral Code?}

        HasCode -->|Yes| ValidateCode[Validate Code]
        HasCode -->|No| SignupBonus[+5 Credits Signup Bonus]

        ValidateCode -->|Valid| ApplyBonus[Apply Referral Bonus]
        ValidateCode -->|Invalid| SignupBonus

        ApplyBonus --> ReferrerBonus[Referrer Gets Bonus]
        ApplyBonus --> RefereeBonus[New User Gets Bonus]

        ReferrerBonus --> CalcBonus{Referral Count?}

        CalcBonus -->|1st| First[+15 Credits]
        CalcBonus -->|2nd| Second[+10 Credits]
        CalcBonus -->|3rd+| Subsequent[+5 Credits Each]

        First --> MaxDaily{Daily Max 105?}
        Second --> MaxDaily
        Subsequent --> MaxDaily

        MaxDaily -->|Under| AddCredits[Add to Quota]
        MaxDaily -->|Over| CapReached[Cap at 105/day]

        RefereeBonus --> GeneralBonus[+50 Credits]
    end
```

### Referral Bonuses

| Event | Credits |
|-------|---------|
| New user signup (no referral) | +5 |
| Referee bonus (used code) | +50 |
| Referrer 1st referral | +15 |
| Referrer 2nd referral | +10 |
| Referrer 3rd+ referrals | +5 each |
| Daily referral cap | 105 max |

---

## 9. Complete Message Lifecycle

```mermaid
flowchart TD
    subgraph Input["User Input"]
        TypeMsg[User Types Message]
        SelectModel{Model Selection}
        SelectModel -->|Standard| StandardLLM[Use Standard LLM]
        SelectModel -->|Premium| PremiumLLM[Use Premium LLM]
    end

    subgraph Validation["Quota Validation"]
        StandardLLM --> CheckStandard{Standard Quota?}
        PremiumLLM --> CheckPremium{Premium Quota?}

        CheckStandard -->|Available| PassStandard[Pass to API]
        CheckStandard -->|Empty| Paywall402[402 Paywall]

        CheckPremium -->|Available| PassPremium[Pass to API]
        CheckPremium -->|Empty| Paywall402
    end

    subgraph Processing["LLM Processing"]
        PassStandard --> RouteToLLM[Route to LLM Provider]
        PassPremium --> RouteToLLM

        RouteToLLM --> StreamResponse[Stream Response]
        StreamResponse --> Complete{Response Complete?}

        Complete -->|Yes| Decrement[Decrement Quota]
        Complete -->|Error| RetryOrFail[Retry or Show Error]
    end

    subgraph PostProcess["Post Processing"]
        Decrement --> LogAnalytics[Log to Analytics]
        LogAnalytics --> UpdateStreak[Update User Streak]
        UpdateStreak --> SaveToHistory[Save to Chat History]
        SaveToHistory --> ShowResponse[Display to User]
    end

    Paywall402 --> ShowPaywall[Display Upgrade Modal]
    ShowPaywall --> UserDecides{Subscribe?}
    UserDecides -->|Yes| ProcessPayment[Process Payment]
    UserDecides -->|No| EndSession[End or Wait]

    ProcessPayment --> RefreshQuota[Refresh Quotas]
    RefreshQuota --> TypeMsg
```

---

## Technical Implementation Notes

### Key Files

| Component | File Location |
|-----------|---------------|
| Quota Constants | `sceneXtras/api/model/quotas_config.py` |
| User Model | `sceneXtras/api/model/models.py` |
| Payment Router | `sceneXtras/api/router/payment_router.py` |
| Chat Router | `sceneXtras/api/router/gpt_chat_router.py` |
| Daily Cron | `sceneXtras/api/bash_scripts/run_daily_task.py` |
| Monthly Cron | `sceneXtras/api/bash_scripts/run_monthly_task.py` |
| Mobile Store | `mobile_app_sx/store/userStore.ts` |
| Paywall UI | `mobile_app_sx/app/subscription.tsx` |

### Quota Database Fields

```sql
-- User table quota fields
quota                   -- Regular chat credits
quota_video             -- Video generation
quota_premium_model     -- Premium LLM usage
quota_story             -- Story creation
quota_image_generation  -- Image generation
quota_image_recognition -- Image recognition
tokens_used             -- Total standard tokens consumed
premium_tokens_used     -- Total premium tokens consumed
```

### Caching Caveat

> **Important**: User quota values must be fetched fresh from DB on each request. Cached User objects become stale within seconds due to concurrent consumption. Only identity fields should be cached.

---

## Summary

The SceneXtras chat business model operates on:

1. **Tiered subscriptions** (FREE → MAX → PRO → CREATOR)
2. **Multiple quota types** (chat, premium, story, video, image)
3. **Daily replenishment** with tier-specific caps
4. **Monthly resets** for story and premium model limits
5. **402 Paywall triggers** when quotas exhausted
6. **Referral bonuses** for organic growth
7. **Stripe/RevenueCat** for payment processing
