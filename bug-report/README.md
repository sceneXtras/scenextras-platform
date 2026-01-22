# Bug Report API

A lightweight Go-Gin backend service for collecting and inspecting bug reports from mobile applications with Azure Blob Storage persistence and LogWard integration.

## Features

- **RESTful API** for bug report submission
- **Azure Blob Storage** for persistent storage
- **Screenshot support** via multipart/form-data
- **HTML Inspector** for viewing reports in browser
- **LogWard integration** for centralized logging
- **CORS enabled** for web frontend access
- **Health checks** for deployment monitoring

## Directory Structure

```
bug-report/
├── main.go                    # Entry point, router setup
├── handlers/
│   ├── report.go             # POST /api/reports, GET /api/reports/:id
│   └── inspector.go          # HTML viewer endpoints
├── storage/
│   └── azure.go              # Azure Blob Storage client
├── models/
│   └── report.go             # BugReport struct
├── templates/
│   ├── index.html            # List all reports
│   ├── detail.html           # Single report view with screenshot
│   └── error.html            # Error page
├── go.mod
├── Dockerfile
└── README.md
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/reports` | Submit bug report (multipart/form-data) |
| GET | `/api/reports` | List all reports (JSON) |
| GET | `/api/reports/:id` | Get single report (JSON) |
| GET | `/` | HTML inspector - list view |
| GET | `/reports/:id` | HTML inspector - detail view |
| GET | `/health` | Health check endpoint |

## API Usage

### Submit Bug Report

```bash
curl -X POST http://localhost:8080/api/reports \
  -F "title=App crashes on login" \
  -F "description=The app crashes when I try to login with Google" \
  -F "stepsToReproduce=1. Open app\n2. Tap Google login\n3. App crashes" \
  -F "currentRoute=/login" \
  -F 'navigationHistory=["/(tabs)/home", "/login"]' \
  -F 'logs=[{"level":"error","message":"Login failed","timestamp":"2024-01-20T10:30:00Z"}]' \
  -F 'deviceInfo={"platform":"iOS","os":"iOS","osVersion":"17.2","appVersion":"1.0.0","buildNumber":"42"}' \
  -F 'userInfo={"userId":"user123"}' \
  -F "timestamp=2024-01-20T10:30:00Z" \
  -F "traceId=trace123" \
  -F "screenshot=@screenshot.png"
```

### List All Reports

```bash
curl http://localhost:8080/api/reports
```

### Get Single Report

```bash
curl http://localhost:8080/api/reports/br_123e4567-e89b-12d3-a456-426614174000
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | `8080` | Server port |
| `AZURE_STORAGE_CONNECTION_STRING` | Yes | - | Azure Blob connection string |
| `AZURE_CONTAINER_NAME` | No | `bug-reports` | Azure container name |
| `LOGWARD_API_KEY` | No | - | LogWard API key for forwarding |
| `GIN_MODE` | No | `release` | Gin mode (debug/release) |

## Azure Blob Storage Structure

```
bug-reports-container/
├── br_123e4567-e89b-12d3-a456-426614174000/
│   ├── metadata.json    # Report metadata
│   ├── screenshot.png   # Screenshot if provided
│   └── logs.json        # Full logs JSON
```

## LogWard Integration

Bug reports are automatically forwarded to LogWard (if `LOGWARD_API_KEY` is set):

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

## Development

### Prerequisites

- Go 1.21+
- Azure Storage Account
- (Optional) LogWard API key

### Setup

```bash
# Clone repository
cd bug-report

# Install dependencies
go mod download

# Set environment variables
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=..."
export AZURE_CONTAINER_NAME="bug-reports"
export LOGWARD_API_KEY="your-logward-api-key"
export PORT=8080

# Run development server
go run main.go
```

### Testing

```bash
# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with verbose output
go test -v ./...
```

### Build

```bash
# Build binary
go build -o bug-report

# Run binary
./bug-report
```

## Docker Deployment

### Build Image

```bash
docker build -t bug-report:latest .
```

### Run Container

```bash
docker run -p 8080:8080 \
  -e AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;..." \
  -e AZURE_CONTAINER_NAME="bug-reports" \
  -e LOGWARD_API_KEY="your-api-key" \
  bug-report:latest
```

### Docker Compose Example

```yaml
version: '3.8'
services:
  bug-report:
    build: .
    ports:
      - "8080:8080"
    environment:
      - AZURE_STORAGE_CONNECTION_STRING=${AZURE_STORAGE_CONNECTION_STRING}
      - AZURE_CONTAINER_NAME=bug-reports
      - LOGWARD_API_KEY=${LOGWARD_API_KEY}
      - GIN_MODE=release
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

## HTML Inspector

Access the HTML inspector by visiting:

- List view: `http://localhost:8080/`
- Detail view: `http://localhost:8080/reports/br_123e4567-e89b-12d3-a456-426614174000`

Features:
- Responsive design
- Screenshot previews
- Log viewer with level-based styling
- Navigation history
- Device information
- Searchable/filterable (browser search)

## Response Format

### Success Response

```json
{
  "success": true,
  "reportId": "br_123e4567-e89b-12d3-a456-426614174000"
}
```

### Error Response

```json
{
  "success": false,
  "error": "Missing required fields: title, description, currentRoute"
}
```

## Security Considerations

- **CORS**: Currently allows all origins (`*`) - restrict in production
- **Authentication**: No authentication required - add JWT/API key validation for production
- **Rate Limiting**: Not implemented - add rate limiting for production
- **Input Validation**: Basic validation - enhance for production use
- **File Upload**: 32MB max file size - adjust as needed

## Performance

- **Concurrent uploads**: Azure SDK handles concurrent requests
- **Screenshot processing**: Direct stream to Azure (no local storage)
- **HTML rendering**: Server-side rendering with Gin templates
- **Health checks**: Sub-10ms response time

## Monitoring

### Health Check

```bash
curl http://localhost:8080/health
```

Response:
```json
{
  "status": "healthy",
  "service": "bug-report-api",
  "version": "1.0.0"
}
```

### Logs

The service logs to stdout. Key events:
- Report submissions
- Azure upload failures
- LogWard forwarding errors
- Server startup/shutdown

## Troubleshooting

### Container creation fails

**Error**: `failed to create container`

**Solution**: Ensure Azure Storage connection string is valid and has container creation permissions.

### Screenshot upload fails

**Error**: `failed to upload screenshot`

**Solution**: Check Azure Storage connection and container permissions. Ensure multipart form is correctly formatted.

### LogWard forwarding fails

**Error**: `Warning: LogWard returned status XXX`

**Solution**: Verify `LOGWARD_API_KEY` is valid and LogWard endpoint is reachable.

## License

MIT
