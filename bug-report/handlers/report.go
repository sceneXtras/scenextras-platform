package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/scenextras/bug-report/models"
	"github.com/scenextras/bug-report/storage"
)

// ReportHandler handles bug report endpoints
type ReportHandler struct {
	storage       *storage.AzureStorage
	logwardAPIKey string
}

// NewReportHandler creates a new report handler
func NewReportHandler(storage *storage.AzureStorage) *ReportHandler {
	return &ReportHandler{
		storage:       storage,
		logwardAPIKey: os.Getenv("LOGWARD_API_KEY"),
	}
}

// SubmitReport handles POST /api/reports
func (h *ReportHandler) SubmitReport(c *gin.Context) {
	// Parse multipart form
	if err := c.Request.ParseMultipartForm(32 << 20); err != nil { // 32MB max
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Failed to parse multipart form",
		})
		return
	}

	// Extract form fields
	title := c.PostForm("title")
	description := c.PostForm("description")
	stepsToReproduce := c.PostForm("stepsToReproduce")
	currentRoute := c.PostForm("currentRoute")
	navigationHistoryJSON := c.PostForm("navigationHistory")
	logsJSON := c.PostForm("logs")
	deviceInfoJSON := c.PostForm("deviceInfo")
	userInfoJSON := c.PostForm("userInfo")
	timestampStr := c.PostForm("timestamp")
	traceID := c.PostForm("traceId")

	// Validate required fields
	if title == "" || description == "" || currentRoute == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Missing required fields: title, description, currentRoute",
		})
		return
	}

	// Parse timestamp
	timestamp, err := time.Parse(time.RFC3339, timestampStr)
	if err != nil {
		timestamp = time.Now()
	}

	// Parse navigation history
	var navigationHistory []string
	if err := json.Unmarshal([]byte(navigationHistoryJSON), &navigationHistory); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid navigationHistory JSON",
		})
		return
	}

	// Parse logs - accept either JSON array or raw text
	var logs []models.LogEntry
	if logsJSON != "" {
		// Try parsing as JSON first
		if err := json.Unmarshal([]byte(logsJSON), &logs); err != nil {
			// If JSON parsing fails, treat as raw log text
			logs = []models.LogEntry{{
				Timestamp: time.Now().Format(time.RFC3339),
				Level:     "info",
				Message:   logsJSON,
			}}
		}
	}

	// Parse device info
	var deviceInfo models.DeviceInfo
	if err := json.Unmarshal([]byte(deviceInfoJSON), &deviceInfo); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid deviceInfo JSON",
		})
		return
	}

	// Parse optional user info
	var userInfo *models.UserInfo
	if userInfoJSON != "" {
		if err := json.Unmarshal([]byte(userInfoJSON), &userInfo); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"success": false,
				"error":   "Invalid userInfo JSON",
			})
			return
		}
	}

	// Generate report ID
	reportID := fmt.Sprintf("br_%s", uuid.New().String())

	// Create report
	report := &models.BugReport{
		ID:                reportID,
		Title:             title,
		Description:       description,
		StepsToReproduce:  stepsToReproduce,
		CurrentRoute:      currentRoute,
		NavigationHistory: navigationHistory,
		Logs:              logs,
		DeviceInfo:        deviceInfo,
		UserInfo:          userInfo,
		Timestamp:         timestamp,
		TraceID:           traceID,
	}

	// Handle screenshot upload (only if storage is configured)
	file, _, err := c.Request.FormFile("screenshot")
	if err == nil {
		defer file.Close()

		// Read screenshot data
		screenshotData, err := io.ReadAll(file)
		if err == nil && h.storage != nil {
			// Upload screenshot
			screenshotURL, err := h.storage.SaveScreenshot(c.Request.Context(), reportID, screenshotData)
			if err != nil {
				fmt.Printf("Warning: failed to upload screenshot: %v\n", err)
			} else {
				report.ScreenshotURL = screenshotURL
			}
		}
	}

	// Save report to Azure (if storage is configured)
	if h.storage != nil {
		if err := h.storage.SaveReport(c.Request.Context(), report); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"error":   "Failed to save report",
			})
			return
		}
	} else {
		// Log report when storage is not configured
		reportJSON, _ := json.Marshal(report)
		fmt.Printf("Bug report received (no storage): %s\n", string(reportJSON))
	}

	// Forward to LogWard
	h.forwardToLogWard(report)

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"reportId": reportID,
	})
}

// GetReport handles GET /api/reports/:id
func (h *ReportHandler) GetReport(c *gin.Context) {
	reportID := c.Param("id")

	report, err := h.storage.GetReport(c.Request.Context(), reportID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Report not found",
		})
		return
	}

	c.JSON(http.StatusOK, report)
}

// ListReports handles GET /api/reports
func (h *ReportHandler) ListReports(c *gin.Context) {
	reports, err := h.storage.ListReports(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "Failed to list reports",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"reports": reports,
		"count":   len(reports),
	})
}

// forwardToLogWard forwards bug report events to LogWard
func (h *ReportHandler) forwardToLogWard(report *models.BugReport) {
	if h.logwardAPIKey == "" {
		return // LogWard not configured
	}

	entry := models.LogWardEntry{
		Time:    report.Timestamp.Format(time.RFC3339),
		Service: "bug-report-api",
		Level:   "info",
		Message: fmt.Sprintf("Bug report submitted: %s", report.Title),
		Channel: "bug-report",
		Context: map[string]interface{}{
			"report_id":          report.ID,
			"title":              report.Title,
			"current_route":      report.CurrentRoute,
			"platform":           report.DeviceInfo.Platform,
			"app_version":        report.DeviceInfo.AppVersion,
			"has_screenshot":     report.ScreenshotURL != "",
			"navigation_history": report.NavigationHistory,
		},
		TraceID: report.TraceID,
	}

	// Marshal to JSON
	jsonData, err := json.Marshal(entry)
	if err != nil {
		fmt.Printf("Warning: failed to marshal LogWard entry: %v\n", err)
		return
	}

	// Send to LogWard
	req, err := http.NewRequest("POST", "https://logging.scenextras.com/api/v1/ingest", bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Printf("Warning: failed to create LogWard request: %v\n", err)
		return
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", h.logwardAPIKey))

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Warning: failed to send to LogWard: %v\n", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		fmt.Printf("Warning: LogWard returned status %d\n", resp.StatusCode)
	}
}
