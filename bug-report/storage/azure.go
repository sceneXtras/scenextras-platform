package storage

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"strings"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob/blob"
	"github.com/scenextras/bug-report/models"
)

// AzureStorage handles Azure Blob Storage operations
type AzureStorage struct {
	client        *azblob.Client
	containerName string
}

// NewAzureStorage creates a new Azure Storage client
func NewAzureStorage(connectionString, containerName string) (*AzureStorage, error) {
	client, err := azblob.NewClientFromConnectionString(connectionString, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create Azure client: %w", err)
	}

	return &AzureStorage{
		client:        client,
		containerName: containerName,
	}, nil
}

// SaveReport saves a bug report to Azure Blob Storage
func (s *AzureStorage) SaveReport(ctx context.Context, report *models.BugReport) error {
	// Save metadata.json
	metadataPath := fmt.Sprintf("%s/metadata.json", report.ID)
	metadataJSON, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	if err := s.uploadBlob(ctx, metadataPath, metadataJSON, "application/json"); err != nil {
		return fmt.Errorf("failed to upload metadata: %w", err)
	}

	// Save logs.json
	logsPath := fmt.Sprintf("%s/logs.json", report.ID)
	logsJSON, err := json.MarshalIndent(report.Logs, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal logs: %w", err)
	}

	if err := s.uploadBlob(ctx, logsPath, logsJSON, "application/json"); err != nil {
		return fmt.Errorf("failed to upload logs: %w", err)
	}

	return nil
}

// SaveScreenshot saves a screenshot to Azure Blob Storage
func (s *AzureStorage) SaveScreenshot(ctx context.Context, reportID string, data []byte) (string, error) {
	path := fmt.Sprintf("%s/screenshot.png", reportID)
	if err := s.uploadBlob(ctx, path, data, "image/png"); err != nil {
		return "", fmt.Errorf("failed to upload screenshot: %w", err)
	}

	// Return the blob URL
	url := fmt.Sprintf("https://%s.blob.core.windows.net/%s/%s",
		s.getStorageAccountName(), s.containerName, path)
	return url, nil
}

// GetReport retrieves a bug report from Azure Blob Storage
func (s *AzureStorage) GetReport(ctx context.Context, reportID string) (*models.BugReport, error) {
	metadataPath := fmt.Sprintf("%s/metadata.json", reportID)
	data, err := s.downloadBlob(ctx, metadataPath)
	if err != nil {
		return nil, fmt.Errorf("failed to download metadata: %w", err)
	}

	var report models.BugReport
	if err := json.Unmarshal(data, &report); err != nil {
		return nil, fmt.Errorf("failed to unmarshal metadata: %w", err)
	}

	return &report, nil
}

// ListReports lists all bug reports in Azure Blob Storage
func (s *AzureStorage) ListReports(ctx context.Context) ([]*models.BugReport, error) {
	var reports []*models.BugReport

	pager := s.client.NewListBlobsFlatPager(s.containerName, &azblob.ListBlobsFlatOptions{
		Prefix: nil,
	})

	// Collect all report IDs (from metadata.json blobs)
	reportIDs := make(map[string]bool)
	for pager.More() {
		resp, err := pager.NextPage(ctx)
		if err != nil {
			return nil, fmt.Errorf("failed to list blobs: %w", err)
		}

		for _, blob := range resp.Segment.BlobItems {
			if strings.HasSuffix(*blob.Name, "/metadata.json") {
				reportID := strings.TrimSuffix(*blob.Name, "/metadata.json")
				reportIDs[reportID] = true
			}
		}
	}

	// Fetch each report
	for reportID := range reportIDs {
		report, err := s.GetReport(ctx, reportID)
		if err != nil {
			// Log error but continue
			fmt.Printf("Warning: failed to get report %s: %v\n", reportID, err)
			continue
		}
		reports = append(reports, report)
	}

	return reports, nil
}

// uploadBlob uploads data to Azure Blob Storage
func (s *AzureStorage) uploadBlob(ctx context.Context, path string, data []byte, contentType string) error {
	_, err := s.client.UploadBuffer(ctx, s.containerName, path, data, &azblob.UploadBufferOptions{
		HTTPHeaders: &blob.HTTPHeaders{
			BlobContentType: &contentType,
		},
	})
	return err
}

// downloadBlob downloads data from Azure Blob Storage
func (s *AzureStorage) downloadBlob(ctx context.Context, path string) ([]byte, error) {
	resp, err := s.client.DownloadStream(ctx, s.containerName, path, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	return io.ReadAll(resp.Body)
}

// getStorageAccountName extracts the storage account name from the client
func (s *AzureStorage) getStorageAccountName() string {
	// Extract from client URL
	url := s.client.URL()
	parts := strings.Split(url, ".")
	if len(parts) > 0 {
		return strings.TrimPrefix(parts[0], "https://")
	}
	return "unknown"
}

// EnsureContainer ensures the container exists
func (s *AzureStorage) EnsureContainer(ctx context.Context) error {
	_, err := s.client.CreateContainer(ctx, s.containerName, nil)
	if err != nil {
		// Check if container already exists (ignore this error)
		if !strings.Contains(err.Error(), "ContainerAlreadyExists") {
			return fmt.Errorf("failed to create container: %w", err)
		}
	}
	return nil
}

// GetScreenshotURL returns the URL for a screenshot
func (s *AzureStorage) GetScreenshotURL(reportID string) string {
	return fmt.Sprintf("https://%s.blob.core.windows.net/%s/%s/screenshot.png",
		s.getStorageAccountName(), s.containerName, reportID)
}

// Helper to read from io.ReadCloser
func readAll(r io.ReadCloser) ([]byte, error) {
	defer r.Close()
	buf := new(bytes.Buffer)
	_, err := buf.ReadFrom(r)
	return buf.Bytes(), err
}
