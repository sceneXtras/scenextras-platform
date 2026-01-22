package models

import (
	"encoding/json"
	"testing"
	"time"
)

func TestBugReportSerialization(t *testing.T) {
	report := &BugReport{
		ID:          "br_test123",
		Title:       "Test Bug",
		Description: "Test description",
		CurrentRoute: "/test",
		NavigationHistory: []string{"/home", "/test"},
		Logs: []LogEntry{
			{
				Level:     "error",
				Message:   "Test error",
				Timestamp: "2024-01-20T10:00:00Z",
			},
		},
		DeviceInfo: DeviceInfo{
			Platform:   "iOS",
			OS:         "iOS",
			OSVersion:  "17.2",
			AppVersion: "1.0.0",
			BuildNumber: "42",
		},
		Timestamp: time.Now(),
	}

	// Test JSON marshaling
	jsonData, err := json.Marshal(report)
	if err != nil {
		t.Fatalf("Failed to marshal report: %v", err)
	}

	// Test JSON unmarshaling
	var decoded BugReport
	if err := json.Unmarshal(jsonData, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal report: %v", err)
	}

	// Verify fields
	if decoded.ID != report.ID {
		t.Errorf("Expected ID %s, got %s", report.ID, decoded.ID)
	}
	if decoded.Title != report.Title {
		t.Errorf("Expected Title %s, got %s", report.Title, decoded.Title)
	}
	if len(decoded.Logs) != len(report.Logs) {
		t.Errorf("Expected %d logs, got %d", len(report.Logs), len(decoded.Logs))
	}
}

func TestLogWardEntrySerialization(t *testing.T) {
	entry := &LogWardEntry{
		Time:    "2024-01-20T10:00:00Z",
		Service: "bug-report-api",
		Level:   "info",
		Message: "Test message",
		Channel: "bug-report",
		Context: map[string]interface{}{
			"report_id": "br_test123",
			"platform":  "iOS",
		},
		TraceID: "trace123",
	}

	// Test JSON marshaling
	jsonData, err := json.Marshal(entry)
	if err != nil {
		t.Fatalf("Failed to marshal LogWardEntry: %v", err)
	}

	// Test JSON unmarshaling
	var decoded LogWardEntry
	if err := json.Unmarshal(jsonData, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal LogWardEntry: %v", err)
	}

	// Verify fields
	if decoded.Service != entry.Service {
		t.Errorf("Expected Service %s, got %s", entry.Service, decoded.Service)
	}
	if decoded.TraceID != entry.TraceID {
		t.Errorf("Expected TraceID %s, got %s", entry.TraceID, decoded.TraceID)
	}
}
