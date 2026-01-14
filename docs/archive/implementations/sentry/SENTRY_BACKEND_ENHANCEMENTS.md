# Backend Sentry Error Analysis Enhancements

## Date: 2025-01-XX

## Overview

Enhanced Sentry error tracking in the Python backend to provide better error analysis, debugging, and performance monitoring. These improvements help developers understand errors faster with richer context, better grouping, and source code visibility.

## ✅ Implemented Enhancements

### 1. Enhanced Error Context (CRITICAL)

**Files Modified:**
- `sceneXtras/api/helper/exception_logger.py` - Enhanced exception logging with source code context
- `sceneXtras/api/main.py` - Enhanced `before_send_sentry` and error handling

**Features:**
- **Source Code Context**: Automatically extracts source code around error location (5 lines before/after)
- **Local Variables**: Captures sanitized local variables from the error frame
- **Error Location**: Adds filename, function name, and line number to Sentry context
- **Sanitization**: Automatically sanitizes sensitive data (passwords, tokens, API keys)

**Example Context Added:**
```python
{
  "error_location": {
    "filename": "/app/router/gpt_chat_router.py",
    "function": "talk_with_entity",
    "line": 712
  },
  "local_variables": {
    "chat_input_obj": "<ChatInput object>",
    "character": "Batman",
    "user_id": "12345"
  }
}
```

### 2. Better Error Grouping & Fingerprinting

**Files Modified:**
- `sceneXtras/api/main.py` - Enhanced `before_send_sentry` function
- `sceneXtras/api/db/database.py` - Database error fingerprinting

**Features:**
- **Custom Error Titles**: More descriptive error messages
  - "HTTP Error: ..." for HTTPException
  - "Database Error: ..." for database errors
  - "Validation Error: ..." for validation errors
- **Error Grouping Tags**: Automatic categorization
  - `error_group: http_error`
  - `error_group: database_error`
  - `error_group: connection_error`
  - `error_group: application_error`
- **Custom Fingerprints**: Better error grouping in Sentry
  - Database errors grouped by type (connection, timeout, constraint)
  - HTTP errors grouped separately
  - Connection errors grouped together

**Benefits:**
- Similar errors are grouped together automatically
- Easier to identify error patterns
- Reduced noise from duplicate errors

### 3. Request Context Enhancement

**Files Modified:**
- `sceneXtras/api/main.py` - Enhanced error handling in middleware

**Features:**
- **Request Context**: Full request information added to Sentry
  - Path, method, client IP
  - User ID (if authenticated)
  - Request duration
- **Query Parameters**: Sanitized query parameters included
- **Error Tags**: Automatic error group tagging based on exception type

**Example Context:**
```python
{
  "request": {
    "path": "/api/talk_with",
    "method": "POST",
    "client_ip": "192.168.1.1",
    "user_id": "12345",
    "duration_ms": 1250
  },
  "query_params": {
    "character": "Batman",
    "introduction": "false"
  }
}
```

### 4. Database Error Enhancement

**Files Modified:**
- `sceneXtras/api/db/database.py` - Enhanced database error handling

**Features:**
- **Database Context**: Full database connection context
  - Host, database name
  - Connection pool statistics
  - Error type
- **Error Fingerprinting**: Custom fingerprints for database errors
  - `["database-error", "connection"]` for connection errors
  - `["database-error", "timeout"]` for timeout errors
  - `["database-error", "constraint"]` for constraint violations
- **Error Tags**: Database-specific tags for filtering

**Benefits:**
- Database errors are easier to diagnose
- Pool statistics help identify connection issues
- Better error grouping by database error type

### 5. Performance Monitoring with Transactions

**Files Modified:**
- `sceneXtras/api/main.py` - Added Sentry transactions to request middleware

**Features:**
- **Request Transactions**: Every HTTP request tracked as a Sentry transaction
  - Operation: `http.server`
  - Name: `{METHOD} {PATH}`
  - Status: `ok` or `internal_error`
  - Duration tracking
- **Slow Request Detection**: Automatic tagging of slow requests
  - Tag: `slow_request: true`
  - Tag: `request_duration_ms: {duration}`
- **Status Code Tracking**: Response status codes included in transaction data

**Benefits:**
- Full request performance visibility
- Identify slow endpoints automatically
- Track performance trends over time

### 6. Sentry Utilities Module

**Files Created:**
- `sceneXtras/api/helper/sentry_utils.py` - Utility functions for Sentry

**Features:**
- `get_source_context()` - Extract source code around error
- `get_local_variables()` - Safely extract local variables
- `enhance_error_with_context()` - Enhance exceptions with context
- `set_error_fingerprint()` - Custom error grouping
- `add_database_context()` - Add database query context
- `add_request_context()` - Add HTTP request context
- `track_performance()` - Decorator for performance tracking
- `capture_error_with_grouping()` - Capture with custom grouping
- `set_service_context()` - Set service identification

**Usage Examples:**
```python
from helper.sentry_utils import enhance_error_with_context, add_database_context

try:
    # Database operation
    result = session.query(User).filter(User.id == user_id).first()
except Exception as e:
    add_database_context(table="users", operation="SELECT")
    enhance_error_with_context(e, {"user_id": user_id})
    raise
```

## 📊 Impact

### Before
- Basic error messages
- Limited context
- Generic error grouping
- No source code visibility
- No performance tracking

### After
- ✅ Rich error context with source code
- ✅ Local variables captured
- ✅ Smart error grouping
- ✅ Request context automatically added
- ✅ Database error context
- ✅ Performance transaction tracking
- ✅ Slow request detection
- ✅ Custom error fingerprints

## 🔍 Example Error in Sentry

**Error Title**: `Database Error: connection to server at "localhost" (127.0.0.1), port 5432 failed`

**Context Added:**
```json
{
  "error_location": {
    "filename": "/app/db/database.py",
    "function": "get_session",
    "line": 195
  },
  "local_variables": {
    "self": "<Database object>",
    "session": "<Session object>"
  },
  "database": {
    "host": "localhost",
    "database": "scenextras",
    "pool_stats": {
      "size": 5,
      "checkedin": 3,
      "checkedout": 2
    },
    "error_type": "OperationalError"
  },
  "request": {
    "path": "/api/talk_with",
    "method": "POST",
    "user_id": "12345",
    "duration_ms": 250
  }
}
```

**Tags:**
- `error_group: database_error`
- `database_error_type: OperationalError`
- `service: python-api`

**Fingerprint**: `["database-error", "connection"]`

## 🚀 Usage Recommendations

### For Critical Operations

```python
from helper.sentry_utils import track_performance, add_database_context

@track_performance("chat_message_processing")
async def process_chat_message(message: str):
    # Your code here
    pass
```

### For Database Operations

```python
from helper.sentry_utils import add_database_context

try:
    user = session.query(User).filter(User.id == user_id).first()
except Exception as e:
    add_database_context(
        table="users",
        operation="SELECT",
        params={"user_id": user_id}
    )
    raise
```

### For Custom Error Grouping

```python
from helper.sentry_utils import capture_error_with_grouping

try:
    # API call
    response = await external_api.call()
except Exception as e:
    capture_error_with_grouping(
        e,
        group_key="external_api_error",
        context={"api_name": "openai", "endpoint": "/chat"},
        level="error"
    )
```

## 📝 Configuration

All enhancements work automatically with existing Sentry configuration. No additional environment variables needed.

The enhancements are backward compatible and don't break existing error handling.

## 🔒 Security

- **Automatic Sanitization**: Sensitive data (passwords, tokens) automatically sanitized
- **Size Limits**: Local variables and context data limited to prevent excessive data
- **PII Protection**: No PII sent to Sentry in production (`send_default_pii: False`)

## ✅ Testing

To test the enhancements:

1. **Test Error Context**:
   ```bash
   curl http://localhost:8080/test-error-logging
   # (requires admin auth)
   ```

2. **Test Database Error**:
   - Temporarily break database connection
   - Make any API request
   - Check Sentry for enhanced database context

3. **Test Performance Tracking**:
   - Make slow requests (>1 second)
   - Check Sentry Performance tab for transactions
   - Verify slow request tags

## 📈 Next Steps (Optional)

1. **Add More Performance Spans**:
   - Database query spans
   - External API call spans
   - LLM processing spans

2. **Enhanced Error Fingerprinting**:
   - Add more specific fingerprints for common errors
   - Group similar validation errors

3. **Custom Metrics**:
   - Track error rates by endpoint
   - Monitor database connection pool health
   - Track slow request patterns

## Summary

The backend now has comprehensive Sentry error tracking with:
- ✅ Source code context for debugging
- ✅ Local variables captured
- ✅ Smart error grouping
- ✅ Request context automatically added
- ✅ Database error context
- ✅ Performance transaction tracking
- ✅ Slow request detection
- ✅ Custom error fingerprints

All errors are now significantly easier to debug and analyze in Sentry!

