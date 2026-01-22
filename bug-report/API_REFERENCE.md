# Bug Report API Reference

## Base URL
```
http://localhost:8080
https://bug-report.scenextras.com (production)
```

## Authentication
Currently no authentication required. Add JWT/API key validation for production.

## Endpoints

### Submit Bug Report
Submit a new bug report with optional screenshot.

**Endpoint:** `POST /api/reports`

**Content-Type:** `multipart/form-data`

**Form Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | Yes | Bug report title |
| description | string | Yes | Detailed bug description |
| stepsToReproduce | string | No | Steps to reproduce the bug |
| currentRoute | string | Yes | Current app route when bug occurred |
| navigationHistory | JSON array | Yes | Array of navigation routes |
| logs | JSON array | Yes | Array of log entries |
| deviceInfo | JSON object | Yes | Device and app information |
| userInfo | JSON object | No | Optional user information |
| timestamp | ISO 8601 | Yes | Bug occurrence timestamp |
| traceId | string | No | Optional trace ID |
| screenshot | file | No | PNG screenshot file |

**Request Example:**

```bash
curl -X POST http://localhost:8080/api/reports \
  -F "title=App crashes on login" \
  -F "description=The app crashes when I try to login" \
  -F "stepsToReproduce=1. Open app\n2. Tap login\n3. App crashes" \
  -F "currentRoute=/login" \
  -F 'navigationHistory=["/(tabs)/home", "/login"]' \
  -F 'logs=[{"level":"error","message":"Login failed","timestamp":"2024-01-20T10:30:00Z"}]' \
  -F 'deviceInfo={"platform":"iOS","os":"iOS","osVersion":"17.2","appVersion":"1.0.0","buildNumber":"42"}' \
  -F "timestamp=2024-01-20T10:30:00Z" \
  -F "screenshot=@screenshot.png"
```

**Success Response:**

```json
{
  "success": true,
  "reportId": "br_123e4567-e89b-12d3-a456-426614174000"
}
```

**Error Response:**

```json
{
  "success": false,
  "error": "Missing required fields: title, description, currentRoute"
}
```

---

### List All Reports
Get all submitted bug reports.

**Endpoint:** `GET /api/reports`

**Response:**

```json
{
  "success": true,
  "count": 2,
  "reports": [
    {
      "id": "br_123e4567-e89b-12d3-a456-426614174000",
      "title": "App crashes on login",
      "description": "The app crashes when I try to login",
      "stepsToReproduce": "1. Open app\n2. Tap login\n3. App crashes",
      "currentRoute": "/login",
      "navigationHistory": ["/(tabs)/home", "/login"],
      "logs": [...],
      "deviceInfo": {...},
      "timestamp": "2024-01-20T10:30:00Z",
      "screenshotUrl": "https://storage.blob.core.windows.net/..."
    }
  ]
}
```

---

### Get Single Report
Get a specific bug report by ID.

**Endpoint:** `GET /api/reports/:id`

**Parameters:**
- `id` (path) - Report ID (e.g., `br_123e4567-e89b-12d3-a456-426614174000`)

**Response:**

```json
{
  "id": "br_123e4567-e89b-12d3-a456-426614174000",
  "title": "App crashes on login",
  "description": "The app crashes when I try to login",
  "stepsToReproduce": "1. Open app\n2. Tap login\n3. App crashes",
  "currentRoute": "/login",
  "navigationHistory": ["/(tabs)/home", "/login"],
  "logs": [
    {
      "level": "error",
      "message": "Login failed",
      "timestamp": "2024-01-20T10:30:00Z",
      "context": {
        "error_code": "AUTH_FAILED"
      }
    }
  ],
  "deviceInfo": {
    "platform": "iOS",
    "os": "iOS",
    "osVersion": "17.2",
    "appVersion": "1.0.0",
    "buildNumber": "42",
    "deviceModel": "iPhone 15 Pro",
    "manufacturer": "Apple"
  },
  "userInfo": {
    "userId": "user123",
    "username": "john_doe"
  },
  "timestamp": "2024-01-20T10:30:00Z",
  "traceId": "trace123",
  "screenshotUrl": "https://storage.blob.core.windows.net/bug-reports/br_123/screenshot.png"
}
```

**Error Response (404):**

```json
{
  "success": false,
  "error": "Report not found"
}
```

---

### Health Check
Check API health status.

**Endpoint:** `GET /health`

**Response:**

```json
{
  "status": "healthy",
  "service": "bug-report-api",
  "version": "1.0.0"
}
```

---

## HTML Inspector

### List View
View all reports in browser.

**Endpoint:** `GET /`

Displays a responsive list of all bug reports with:
- Report title and ID
- Timestamp
- Platform/device info
- Tags (screenshot, trace, log count)

### Detail View
View a specific report with full details.

**Endpoint:** `GET /reports/:id`

Displays:
- Full report details
- Screenshot (if available)
- Navigation history
- Device information
- Complete log entries

---

## Data Models

### BugReport

```typescript
interface BugReport {
  id: string;                       // br_xxx UUID
  title: string;
  description: string;
  stepsToReproduce?: string;
  currentRoute: string;
  navigationHistory: string[];
  logs: LogEntry[];
  deviceInfo: DeviceInfo;
  userInfo?: UserInfo;
  timestamp: string;                // ISO 8601
  traceId?: string;
  screenshotUrl?: string;
}
```

### LogEntry

```typescript
interface LogEntry {
  level: string;                    // error, warn, info, debug
  message: string;
  timestamp: string;                // ISO 8601
  context?: Record<string, any>;
}
```

### DeviceInfo

```typescript
interface DeviceInfo {
  platform: string;                 // iOS, Android, web
  os: string;
  osVersion: string;
  appVersion: string;
  buildNumber: string;
  deviceModel?: string;
  manufacturer?: string;
}
```

### UserInfo

```typescript
interface UserInfo {
  userId?: string;
  username?: string;
  email?: string;
}
```

---

## Error Codes

| Status | Description |
|--------|-------------|
| 200 | Success |
| 400 | Bad Request (invalid JSON, missing fields) |
| 404 | Report not found |
| 500 | Internal server error |

---

## Rate Limits

No rate limits currently enforced. Recommend implementing for production:
- 100 requests per minute per IP
- 1000 requests per day per IP

---

## CORS

Currently allows all origins (`*`). Restrict in production:

```go
AllowOrigins: []string{
  "https://scenextras.com",
  "https://app.scenextras.com"
}
```

---

## Storage

Reports are stored in Azure Blob Storage with structure:

```
bug-reports/
├── br_123e4567-e89b-12d3-a456-426614174000/
│   ├── metadata.json
│   ├── logs.json
│   └── screenshot.png (if uploaded)
```

---

## LogWard Integration

If `LOGWARD_API_KEY` is set, reports are forwarded to LogWard:

**Endpoint:** `POST https://logging.scenextras.com/api/v1/ingest`

**Payload:**

```json
{
  "time": "2024-01-20T10:30:00Z",
  "service": "bug-report-api",
  "level": "info",
  "message": "Bug report submitted: App crashes on login",
  "channel": "bug-report",
  "context": {
    "report_id": "br_123e4567-e89b-12d3-a456-426614174000",
    "title": "App crashes on login",
    "current_route": "/login",
    "platform": "iOS",
    "app_version": "1.0.0",
    "has_screenshot": true,
    "navigation_history": ["/(tabs)/home", "/login"]
  },
  "trace_id": "trace123"
}
```
