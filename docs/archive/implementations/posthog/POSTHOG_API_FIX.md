# PostHog API Fix - Python 6.x Compatibility ✅

## 🐛 **Issue**

PostHog Python library version 6.7.11 changed the API signature for `capture()`. The old positional arguments format no longer works:

```python
# ❌ Old API (fails in 6.7.11)
posthog.capture(user_id, "event_name", properties={"key": "value"})
# TypeError: Client.capture() takes 2 positional arguments but 4 were given
```

## ✅ **Solution**

Updated all PostHog `capture()` calls to use keyword arguments:

```python
# ✅ New API (works in 6.7.11)
posthog.capture(
    distinct_id=user_id,
    event="event_name",
    properties={"key": "value"}
)
```

## 📝 **Files Updated**

### **1. `helper/posthog_telemetry.py`**
- Updated `_capture_event()` method
- Added fallback for older API versions
- Better error handling

### **2. `router/gpt_chat_router.py`**
- Fixed all 13+ `posthog.capture()` calls
- Updated to use keyword arguments:
  - `distinct_id=user_id`
  - `event="event_name"`
  - `properties={...}`

### **3. `chat/image_generation.py`**
- Fixed quota exceeded tracking
- Updated to use keyword arguments

## 🔧 **Implementation Details**

### **Telemetry Helper**

```python
# PostHog 6.x API: capture(distinct_id=..., event=..., properties=...)
try:
    self.posthog.capture(
        distinct_id=distinct_id,
        event=event,
        properties=properties
    )
except TypeError as e:
    # Fallback: try positional arguments for older API versions
    try:
        self.posthog.capture(distinct_id, event, properties)
    except Exception as fallback_error:
        logger.error(f"PostHog capture failed with both API formats")
        raise
```

### **Direct Calls**

```python
# Before
posthog.capture(user_id, "user exceeded quota")

# After
posthog.capture(
    distinct_id=user_id, 
    event="user exceeded quota"
)
```

## ✅ **Status**

**All PostHog capture calls updated and compatible with version 6.7.11!**

The error should no longer occur:
```
TypeError: Client.capture() takes 2 positional arguments but 4 were given
```

