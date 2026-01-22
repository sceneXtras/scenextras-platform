.PHONY: help build run test clean docker-build docker-run

help:
	@echo "Bug Report API - Available commands:"
	@echo "  make build        - Build the application"
	@echo "  make run          - Run the application"
	@echo "  make test         - Run tests"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make docker-build - Build Docker image"
	@echo "  make docker-run   - Run Docker container"

build:
	@echo "Building bug-report..."
	@go build -o bug-report .

run: build
	@echo "Starting bug-report API..."
	@./bug-report

test:
	@echo "Running tests..."
	@go test ./...

test-verbose:
	@echo "Running tests (verbose)..."
	@go test -v ./...

test-coverage:
	@echo "Running tests with coverage..."
	@go test -cover ./...

clean:
	@echo "Cleaning build artifacts..."
	@rm -f bug-report
	@go clean

docker-build:
	@echo "Building Docker image..."
	@docker build -t bug-report:latest .

docker-run:
	@echo "Running Docker container..."
	@docker run -p 8080:8080 \
		--env-file .env \
		bug-report:latest

fmt:
	@echo "Formatting code..."
	@go fmt ./...

vet:
	@echo "Running go vet..."
	@go vet ./...

lint: fmt vet
	@echo "Linting complete"

deps:
	@echo "Downloading dependencies..."
	@go mod download

tidy:
	@echo "Tidying dependencies..."
	@go mod tidy
