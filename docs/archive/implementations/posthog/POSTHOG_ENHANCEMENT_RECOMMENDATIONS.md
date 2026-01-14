# PostHog Enhancement Recommendations

Based on PostHog best practices and industry use cases, here are recommended enhancements to improve your analytics implementation.

## Current Implementation Summary

**Event Tracking:**
- ✅ 186+ frontend events tracked
- ✅ 55+ backend events tracked
- ✅ Chat, payment, subscription, authentication events
- ✅ Session replay enabled
- ✅ Feature flags support (basic)

**Gaps Identified:**
- ❌ No consistent naming convention
- ❌ No funnel/conversion tracking
- ❌ Limited feature flag usage
- ❌ No A/B testing infrastructure
- ❌ No internal user filtering
- ❌ No reverse proxy setup
- ❌ Missing user journey tracking
- ❌ Limited cohort analysis

---

## Priority 1: Critical Enhancements

### 1. Consistent Event Naming Convention

**Current Issue:** Mixed naming conventions (`message_sent`, `checkout_initiated`, `subscription_updated`)

**Recommendation:** Implement `category:object_action` format

**Example Structure:**
```
chat:message_sent
chat:message_edited
chat:character_selected

payment:checkout_initiated
payment:subscription_created
payment:subscription_cancelled

user:profile_updated
user:login_successful
user:signup_completed

content:character_viewed
content:search_performed
content:image_generated
```

**Implementation:**
- Create event naming guide document
- Add validation function to enforce naming
- Gradually migrate existing events

**Benefits:**
- Easier to query and analyze
- Prevents duplicate events
- Better organization in PostHog dashboard

---

### 2. Conversion Funnel Tracking

**Current Gap:** No end-to-end funnel tracking for key user journeys

**Recommended Funnels:**

#### A. User Onboarding Funnel
```
1. landing_page_viewed
2. signup_initiated
3. email_verified
4. onboarding_completed
5. first_character_selected
6. first_message_sent
```

#### B. Subscription Conversion Funnel
```
1. limit_modal_shown
2. checkout_modal_opened
3. plan_selected
4. checkout_initiated
5. payment_processed
6. subscription_active
```

#### C. Engagement Funnel
```
1. app_opened
2. character_selected
3. message_sent
4. response_received
5. multiple_messages (3+)
6. feature_used (image_gen, voice, etc.)
```

**Implementation:**
- Add funnel analysis dashboard in PostHog
- Track conversion rates at each step
- Identify drop-off points

---

### 3. Internal User Filtering

**Current Gap:** Internal team actions polluting analytics

**Recommendation:** Filter out internal users

**Implementation:**

**Python Backend:**
```python
# Add to posthog_telemetry.py
def _is_internal_user(self, user_id: Union[str, int], email: Optional[str] = None) -> bool:
    """Check if user is internal team member"""
    internal_domains = ['@scenextras.com', '@yourcompany.com']
    internal_user_ids = ['12345', '67890']  # Known internal IDs
    
    if user_id in internal_user_ids:
        return True
    
    if email and any(email.endswith(domain) for domain in internal_domains):
        return True
    
    return False

def _capture_event(self, distinct_id, event, properties):
    # Skip internal users
    if self._is_internal_user(distinct_id, properties.get('email')):
        return
    
    # Add is_internal flag for filtering
    properties['is_internal'] = False
    # ... rest of capture logic
```

**Frontend:**
```typescript
// Add to posthogUtils.ts
const isInternalUser = (userId: string, email?: string): boolean => {
  const internalDomains = ['@scenextras.com'];
  const internalUserIds = ['12345'];
  
  if (internalUserIds.includes(userId)) return true;
  if (email && internalDomains.some(d => email.endsWith(d))) return true;
  
  return false;
};

// Update trackEvent
export const trackEvent = (eventName: string, properties = {}) => {
  const userId = getCurrentUserId();
  const email = getUserEmail();
  
  if (isInternalUser(userId, email)) {
    return; // Skip tracking
  }
  
  if (isPostHogAvailable()) {
    safePosthog.capture(eventName, {
      ...properties,
      is_internal: false,
    });
  }
};
```

**Benefits:**
- Cleaner analytics data
- More accurate conversion metrics
- Better understanding of real user behavior

---

### 4. User Journey Tracking

**Current Gap:** No complete user journey visibility

**Recommendation:** Track user paths through critical flows

**Add Journey Tracking:**

#### A. Signup Journey
```typescript
// Track complete signup flow
trackEvent('journey:signup_started', {
  source: 'landing_page' | 'modal' | 'referral',
  referrer: document.referrer,
});

trackEvent('journey:signup_email_entered', {
  source: 'signup_form',
});

trackEvent('journey:signup_email_verified', {
  time_to_verify_ms: Date.now() - signupStartTime,
});

trackEvent('journey:signup_completed', {
  total_time_ms: Date.now() - signupStartTime,
  steps_completed: ['email', 'verification', 'profile'],
});
```

#### B. First Chat Journey
```typescript
trackEvent('journey:first_chat_started', {
  time_since_signup_ms: Date.now() - signupTimestamp,
  characters_viewed: characterViewCount,
});

trackEvent('journey:first_message_sent', {
  time_to_first_message_ms: Date.now() - chatStartTime,
  character_name: selectedCharacter,
});

trackEvent('journey:first_response_received', {
  response_time_ms: responseTime,
  satisfaction_score: null, // Could add later
});
```

**Benefits:**
- Understand user drop-off points
- Optimize onboarding flow
- Identify friction points

---

## Priority 2: Advanced Features

### 5. Feature Flags for Gradual Rollouts

**Current State:** Basic feature flag support exists but underutilized

**Recommendation:** Implement progressive feature rollouts

**Use Cases:**

#### A. New Features
```typescript
// Example: New AI model rollout
const useNewModel = await posthogService.isFeatureEnabled('new_ai_model_v2');

if (useNewModel) {
  // Use new model
  trackEvent('feature:new_model_used', {
    model: 'gpt-4-turbo',
    feature_flag: 'new_ai_model_v2',
  });
} else {
  // Use existing model
}
```

#### B. A/B Testing UI Changes
```typescript
const buttonText = await posthogService.getFeatureFlag('buy-button-text', 'Upgrade Now');

// Track which variant was shown
trackEvent('ab_test:button_shown', {
  variant: buttonText,
  test_name: 'buy-button-text',
});
```

**Implementation Areas:**
- New character features
- UI/UX changes
- Pricing page variations
- Onboarding flow variants

**Benefits:**
- Safer deployments
- Data-driven decisions
- Faster iteration

---

### 6. Cohort Analysis

**Current Gap:** No cohort tracking

**Recommendation:** Track user cohorts by signup date

**Implementation:**

```python
# Add to posthog_telemetry.py
def capture_user_signup(self, user_id: Union[str, int], signup_date: datetime):
    """Capture user signup with cohort information"""
    properties = {
        'signup_date': signup_date.isoformat(),
        'signup_week': signup_date.strftime('%Y-W%W'),
        'signup_month': signup_date.strftime('%Y-%m'),
        'cohort': signup_date.strftime('%Y-%m'),
        'environment': self.environment,
    }
    
    self.posthog.capture(str(user_id), 'user_signup', properties)
    
    # Set user properties for cohort analysis
    self.posthog.identify(str(user_id), {
        'signup_date': signup_date.isoformat(),
        'cohort': signup_date.strftime('%Y-%m'),
    })
```

**Use Cases:**
- Compare retention rates by signup cohort
- Measure feature adoption over time
- Analyze user lifetime value by cohort

---

### 7. Revenue Attribution

**Current Gap:** Limited revenue tracking

**Recommendation:** Enhanced revenue tracking

**Add Events:**

```python
# Enhanced subscription tracking
def capture_subscription_event(
    self,
    user_id: Union[str, int],
    event_type: str,
    plan_name: str,
    plan_price: float,
    # ... existing params ...
    revenue_attribution: Optional[Dict] = None,
):
    properties = {
        # ... existing properties ...
        'revenue': plan_price,
        'revenue_usd': plan_price,
        'plan_name': plan_name,
        'attribution_source': revenue_attribution.get('source') if revenue_attribution else None,
        'attribution_campaign': revenue_attribution.get('campaign') if revenue_attribution else None,
        'attribution_medium': revenue_attribution.get('medium') if revenue_attribution else None,
    }
    
    self._capture_event(user_id, f"subscription_{event_type}", properties)
```

**Track Key Metrics:**
- Customer Lifetime Value (LTV)
- Customer Acquisition Cost (CAC)
- Monthly Recurring Revenue (MRR)
- Churn rate by cohort

---

### 8. Error and Performance Tracking

**Current State:** Basic error tracking exists

**Recommendation:** Enhanced error correlation with PostHog

**Implementation:**

```typescript
// Enhanced error tracking
export const trackError = (
  errorName: string,
  errorDetails: Record<string, any> = {},
) => {
  const errorInfo = {
    ...errorDetails,
    timestamp: new Date().toISOString(),
    is_recording_active: isSessionRecordingEnabled(),
    session_url: safePosthog.get_session_replay_url(),
    // Add user context
    user_id: getCurrentUserId(),
    page_url: window.location.href,
    user_agent: navigator.userAgent,
  };

  // Track to PostHog
  trackEvent('error_occurred', {
    error_name: errorName,
    ...errorInfo,
  });

  // Also send to Sentry (existing)
  Sentry.captureException(new Error(errorName), {
    contexts: {
      posthog: errorInfo,
    },
  });
};
```

**Benefits:**
- Link errors to user sessions
- Correlate errors with user actions
- Faster debugging with session replay

---

## Priority 3: Infrastructure Improvements

### 9. Reverse Proxy Setup

**Current Gap:** Events may be blocked by ad blockers

**Recommendation:** Set up reverse proxy

**Benefits:**
- Higher event capture rate
- Reduced ad blocker interference
- More accurate analytics

**Implementation:**
- Configure nginx/cloudflare reverse proxy
- Route PostHog requests through your domain
- Update PostHog host configuration

**Example:**
```
https://analytics.scenextras.com/ → PostHog
Instead of: https://us.i.posthog.com/
```

---

### 10. Event Property Standardization

**Current Gap:** Inconsistent property names

**Recommendation:** Standardize common properties

**Standard Properties:**
```typescript
// Common properties to add to all events
const standardProperties = {
  // User context
  user_id: string,
  user_email: string (hashed),
  subscription_tier: 'free' | 'premium' | 'pro',
  subscription_status: 'active' | 'cancelled' | 'trial',
  
  // Session context
  session_id: string,
  page_url: string,
  referrer: string,
  
  // Feature context
  app_version: string,
  platform: 'web' | 'ios' | 'android',
  environment: 'production' | 'development',
  
  // Timing
  timestamp: ISO string,
  load_time_ms: number,
};
```

---

### 11. Retention Tracking

**Current Gap:** No retention analysis

**Recommendation:** Track user retention metrics

**Add Events:**

```python
# Add to posthog_telemetry.py
def capture_retention_event(
    self,
    user_id: Union[str, int],
    event_type: str,  # daily_active, weekly_active, monthly_active
    days_since_signup: int,
    is_returning: bool,
):
    """Track user retention events"""
    properties = {
        'retention_type': event_type,
        'days_since_signup': days_since_signup,
        'is_returning_user': is_returning,
        'environment': self.environment,
    }
    
    self._capture_event(user_id, f"retention_{event_type}", properties)
```

**Track:**
- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- Monthly Active Users (MAU)
- Retention by cohort

---

### 12. Content Performance Tracking

**Current Gap:** Limited content analytics

**Recommendation:** Track content engagement

**Add Events:**

```typescript
// Character/content engagement
trackEvent('content:character_viewed', {
  character_id: string,
  character_name: string,
  movie_name: string,
  view_duration_ms: number,
  source: 'search' | 'trending' | 'recommendation',
});

trackEvent('content:character_favorited', {
  character_id: string,
  character_name: string,
});

trackEvent('content:character_shared', {
  character_id: string,
  platform: 'twitter' | 'facebook' | 'copy_link',
});

// Search performance
trackEvent('search:performed', {
  query: string,
  result_count: number,
  search_type: 'character' | 'movie' | 'all',
  time_to_results_ms: number,
});

trackEvent('search:result_clicked', {
  query: string,
  result_position: number,
  result_type: 'character' | 'movie',
});
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
1. ✅ Implement consistent naming convention
2. ✅ Add internal user filtering
3. ✅ Standardize event properties
4. ✅ Set up conversion funnels

### Phase 2: Advanced Analytics (Weeks 3-4)
5. ✅ Implement user journey tracking
6. ✅ Add cohort analysis
7. ✅ Enhance revenue attribution
8. ✅ Set up retention tracking

### Phase 3: Infrastructure (Weeks 5-6)
9. ✅ Configure reverse proxy
10. ✅ Expand feature flag usage
11. ✅ Add A/B testing framework
12. ✅ Content performance tracking

---

## Quick Wins

**Can be implemented immediately:**

1. **Internal User Filtering** - 2-3 hours
2. **Event Naming Convention** - 1-2 days
3. **Standard Properties** - 1 day
4. **Conversion Funnels** - 2-3 days
5. **User Journey Tracking** - 3-4 days

**Higher Impact:**

1. **Cohort Analysis** - 1 week
2. **Revenue Attribution** - 1 week
3. **Retention Tracking** - 1 week

---

## Metrics to Track

### User Metrics
- DAU/WAU/MAU
- User retention (1-day, 7-day, 30-day)
- Time to first value
- Feature adoption rate

### Revenue Metrics
- MRR (Monthly Recurring Revenue)
- ARR (Annual Recurring Revenue)
- LTV (Lifetime Value)
- CAC (Customer Acquisition Cost)
- Churn rate
- Upgrade rate

### Engagement Metrics
- Messages per user
- Characters per user
- Session duration
- Feature usage frequency
- Content engagement rate

### Conversion Metrics
- Signup → First message conversion
- Free → Paid conversion
- Trial → Paid conversion
- Checkout → Payment success rate

---

## PostHog Dashboard Recommendations

### Create Dashboards For:

1. **User Acquisition**
   - Signup funnel
   - Source attribution
   - Conversion rates by channel

2. **User Engagement**
   - Daily active users
   - Feature usage
   - Content engagement

3. **Revenue**
   - Subscription funnels
   - Revenue by cohort
   - Churn analysis

4. **Product Health**
   - Error rates
   - Performance metrics
   - User satisfaction signals

---

## Code Examples

### Example: Enhanced Event Tracking

```python
# Enhanced telemetry capture with standard properties
def capture_event_with_context(
    self,
    user_id: Union[str, int],
    event_name: str,
    event_properties: Dict[str, Any],
    include_user_context: bool = True,
):
    """Capture event with standardized context"""
    
    # Standard properties
    properties = {
        'environment': self.environment,
        'timestamp': datetime.utcnow().isoformat(),
    }
    
    # Add user context if available
    if include_user_context:
        user_data = self._get_user_data(user_id)
        if user_data:
            properties.update({
                'user_subscription_tier': user_data.get('subscription_tier'),
                'user_account_age_days': user_data.get('account_age_days'),
            })
    
    # Merge event-specific properties
    properties.update(event_properties)
    
    # Capture event
    self._capture_event(user_id, event_name, properties)
```

### Example: Feature Flag Usage

```typescript
// Progressive feature rollout
const useNewFeature = await posthogService.isFeatureEnabled('new_chat_ui');

if (useNewFeature) {
  trackEvent('feature:new_chat_ui_enabled', {
    feature_flag: 'new_chat_ui',
    variant: 'enabled',
  });
  
  // Use new UI
} else {
  // Use existing UI
}
```

---

## Next Steps

1. **Review and prioritize** recommendations
2. **Create implementation tickets** for each enhancement
3. **Start with Quick Wins** (internal filtering, naming convention)
4. **Set up PostHog dashboards** for key metrics
5. **Document** event naming conventions
6. **Train team** on new tracking patterns

---

## Resources

- [PostHog Best Practices](https://posthog.com/docs/best-practices)
- [Event Naming Conventions](https://posthog.com/questions/best-practices-naming-convention-for-event-names-and-properties)
- [Feature Flags Guide](https://posthog.com/docs/feature-flags/best-practices)
- [A/B Testing Guide](https://posthog.com/docs/experiments/best-practices)

