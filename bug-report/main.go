package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/scenextras/bug-report/handlers"
	"github.com/scenextras/bug-report/storage"
)

func main() {
	// Load environment variables
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	connectionString := os.Getenv("AZURE_STORAGE_CONNECTION_STRING")
	containerName := os.Getenv("AZURE_CONTAINER_NAME")
	if containerName == "" {
		containerName = "bug-reports"
	}

	// Initialize Azure Storage (optional - if not configured, reports will be logged only)
	var azureStorage *storage.AzureStorage
	if connectionString != "" {
		var err error
		azureStorage, err = storage.NewAzureStorage(connectionString, containerName)
		if err != nil {
			log.Printf("Warning: Failed to initialize Azure Storage: %v (reports will be logged only)", err)
		} else {
			// Ensure container exists
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			if err := azureStorage.EnsureContainer(ctx); err != nil {
				log.Printf("Warning: failed to ensure container exists: %v", err)
			}
		}
	} else {
		log.Println("Warning: AZURE_STORAGE_CONNECTION_STRING not set - reports will be logged only (no persistence)")
	}

	// Set Gin mode
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize Gin router
	router := gin.Default()

	// Configure CORS
	router.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Load HTML templates
	router.LoadHTMLGlob("templates/*")

	// Initialize handlers
	reportHandler := handlers.NewReportHandler(azureStorage)
	inspectorHandler := handlers.NewInspectorHandler(azureStorage)

	// API routes
	api := router.Group("/api")
	{
		api.POST("/reports", reportHandler.SubmitReport)
		api.GET("/reports", reportHandler.ListReports)
		api.GET("/reports/:id", reportHandler.GetReport)
	}

	// HTML inspector routes
	router.GET("/", inspectorHandler.Index)
	router.GET("/reports/:id", inspectorHandler.Detail)

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "bug-report-api",
			"version": "1.0.0",
		})
	})

	// Start server
	log.Printf("Starting bug report API on port %s", port)
	log.Printf("Azure container: %s", containerName)
	log.Printf("LogWard integration: %v", os.Getenv("LOGWARD_API_KEY") != "")

	if err := router.Run(fmt.Sprintf(":%s", port)); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
