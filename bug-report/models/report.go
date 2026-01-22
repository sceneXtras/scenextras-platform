package models

import "time"

// BugReport represents a submitted bug report
type BugReport struct {
	ID                 string                 `json:"id"`
	Title              string                 `json:"title"`
	Description        string                 `json:"description"`
	StepsToReproduce   string                 `json:"stepsToReproduce,omitempty"`
	CurrentRoute       string                 `json:"currentRoute"`
	NavigationHistory  []string               `json:"navigationHistory"`
	Logs               []LogEntry             `json:"logs"`
	DeviceInfo         DeviceInfo             `json:"deviceInfo"`
	UserInfo           *UserInfo              `json:"userInfo,omitempty"`
	Timestamp          time.Time              `json:"timestamp"`
	TraceID            string                 `json:"traceId,omitempty"`
	ScreenshotURL      string                 `json:"screenshotUrl,omitempty"`
}

// LogEntry represents a single log entry
type LogEntry struct {
	Level     string                 `json:"level"`
	Message   string                 `json:"message"`
	Timestamp string                 `json:"timestamp"`
	Context   map[string]interface{} `json:"context,omitempty"`
}

// DeviceInfo contains device and app information
type DeviceInfo struct {
	Platform    string `json:"platform"`
	OS          string `json:"os"`
	OSVersion   string `json:"osVersion"`
	AppVersion  string `json:"appVersion"`
	BuildNumber string `json:"buildNumber"`
	DeviceModel string `json:"deviceModel,omitempty"`
	Manufacturer string `json:"manufacturer,omitempty"`
}

// UserInfo contains optional user information
type UserInfo struct {
	UserID   string `json:"userId,omitempty"`
	Username string `json:"username,omitempty"`
	Email    string `json:"email,omitempty"`
}

// LogWardEntry represents a log entry for LogWard
type LogWardEntry struct {
	Time    string                 `json:"time"`
	Service string                 `json:"service"`
	Level   string                 `json:"level"`
	Message string                 `json:"message"`
	Channel string                 `json:"channel"`
	Context map[string]interface{} `json:"context"`
	TraceID string                 `json:"trace_id,omitempty"`
}
