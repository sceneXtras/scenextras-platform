package handlers

import (
	"testing"
)

func TestReportHandlerCreation(t *testing.T) {
	// Test that handler can be created with nil storage for unit testing
	handler := &ReportHandler{
		storage:       nil,
		logwardAPIKey: "",
	}

	if handler == nil {
		t.Fatal("Expected handler to be created")
	}
}
