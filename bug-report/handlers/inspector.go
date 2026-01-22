package handlers

import (
	"net/http"
	"sort"

	"github.com/gin-gonic/gin"
	"github.com/scenextras/bug-report/storage"
)

// InspectorHandler handles HTML viewer endpoints
type InspectorHandler struct {
	storage *storage.AzureStorage
}

// NewInspectorHandler creates a new inspector handler
func NewInspectorHandler(storage *storage.AzureStorage) *InspectorHandler {
	return &InspectorHandler{
		storage: storage,
	}
}

// Index handles GET / - list all reports
func (h *InspectorHandler) Index(c *gin.Context) {
	reports, err := h.storage.ListReports(c.Request.Context())
	if err != nil {
		c.HTML(http.StatusInternalServerError, "error.html", gin.H{
			"error": "Failed to load reports",
		})
		return
	}

	// Sort by timestamp (newest first)
	sort.Slice(reports, func(i, j int) bool {
		return reports[i].Timestamp.After(reports[j].Timestamp)
	})

	c.HTML(http.StatusOK, "index.html", gin.H{
		"reports": reports,
		"count":   len(reports),
	})
}

// Detail handles GET /reports/:id - single report view
func (h *InspectorHandler) Detail(c *gin.Context) {
	reportID := c.Param("id")

	report, err := h.storage.GetReport(c.Request.Context(), reportID)
	if err != nil {
		c.HTML(http.StatusNotFound, "error.html", gin.H{
			"error": "Report not found",
		})
		return
	}

	c.HTML(http.StatusOK, "detail.html", gin.H{
		"report": report,
	})
}
