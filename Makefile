# ============================================================================
# SceneXtras Monorepo - Root Makefile
# ============================================================================
#
# Central command hub for the entire project. Run `make` or `make help` to see
# all available commands organized by category.
#
# Services:
#   - api      : Python FastAPI backend (sceneXtras/api)
#   - web      : React web frontend (frontend_webapp)
#   - search   : Go autocomplete engine (golang_search_engine)
#   - gateway  : Go auth gateway (golang_auth_gateway)
#   - mobile   : React Native app (mobile_app_sx)
#
# ============================================================================

.PHONY: help
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
MAGENTA := \033[35m
BOLD := \033[1m
NC := \033[0m

# Service directories
API_DIR := sceneXtras/api
WEB_DIR := frontend_webapp
SEARCH_DIR := golang_search_engine
GATEWAY_DIR := golang_auth_gateway
MOBILE_DIR := mobile_app_sx

# ============================================================================
# HELP
# ============================================================================

help: ## Show this help message
	@echo ""
	@echo "$(BOLD)$(MAGENTA)╔════════════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BOLD)$(MAGENTA)║              SCENEXTRAS MONOREPO - COMMAND REFERENCE                   ║$(NC)"
	@echo "$(BOLD)$(MAGENTA)╚════════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(BOLD)$(CYAN)DEVELOPMENT - Start Services$(NC)"
	@echo "  $(GREEN)make dev-api$(NC)          Start Python API (localhost:8080)"
	@echo "  $(GREEN)make dev-api-local$(NC)    Start Python API in local SQLite mode"
	@echo "  $(GREEN)make dev-web$(NC)          Start React web frontend (localhost:3000)"
	@echo "  $(GREEN)make dev-search$(NC)       Start Go search engine (localhost:8080)"
	@echo "  $(GREEN)make dev-gateway$(NC)      Start Go auth gateway"
	@echo "  $(GREEN)make dev-mobile$(NC)       Start React Native app (web mode)"
	@echo ""
	@echo "$(BOLD)$(CYAN)TESTING$(NC)"
	@echo "  $(GREEN)make test-api$(NC)         Run Python API tests"
	@echo "  $(GREEN)make test-api-unit$(NC)    Run Python API unit tests only"
	@echo "  $(GREEN)make test-api-smoke$(NC)   Run Python API smoke tests (fast)"
	@echo "  $(GREEN)make test-web$(NC)         Run React web tests"
	@echo "  $(GREEN)make test-search$(NC)      Run Go search engine tests"
	@echo "  $(GREEN)make test-gateway$(NC)     Run Go gateway tests"
	@echo "  $(GREEN)make test-mobile$(NC)      Run React Native tests"
	@echo "  $(GREEN)make test-all$(NC)         Run all service tests"
	@echo ""
	@echo "$(BOLD)$(CYAN)CODE QUALITY$(NC)"
	@echo "  $(GREEN)make lint-api$(NC)         Lint Python API (flake8)"
	@echo "  $(GREEN)make lint-search$(NC)      Lint Go search engine"
	@echo "  $(GREEN)make lint-gateway$(NC)     Lint Go gateway"
	@echo "  $(GREEN)make quality-api$(NC)      Full quality check (lint + type + tests)"
	@echo ""
	@echo "$(BOLD)$(CYAN)BUILD$(NC)"
	@echo "  $(GREEN)make build-api$(NC)        Build Python API (Docker)"
	@echo "  $(GREEN)make build-web$(NC)        Build React web (production)"
	@echo "  $(GREEN)make build-search$(NC)     Build Go search binary"
	@echo "  $(GREEN)make build-gateway$(NC)    Build Go gateway binary"
	@echo ""
	@echo "$(BOLD)$(CYAN)PRODUCTION OPS$(NC)"
	@echo "  $(GREEN)make logs$(NC)             Interactive production log viewer"
	@echo "  $(GREEN)make logs-api$(NC)         View scenextras API logs"
	@echo "  $(GREEN)make logs-search$(NC)      View autocomplete service logs"
	@echo "  $(GREEN)make logs-gateway$(NC)     View gateway logs"
	@echo "  $(GREEN)make logs-nginx$(NC)       View nginx logs"
	@echo "  $(GREEN)make health$(NC)           Health check all production services"
	@echo ""
	@echo "$(BOLD)$(CYAN)HISTORICAL LOGS$(NC)"
	@echo "  $(GREEN)make history-api$(NC)      Search API logs (journald, last 24h)"
	@echo "  $(GREEN)make history-search$(NC)   Search autocomplete logs (journald)"
	@echo "  $(GREEN)make history-nginx$(NC)    Search rotated nginx logs"
	@echo ""
	@echo "$(BOLD)$(CYAN)DEPLOYMENT$(NC)"
	@echo "  $(GREEN)make deploy-api$(NC)       Deploy Python API to Dokku"
	@echo "  $(GREEN)make deploy-search$(NC)    Deploy search engine to Dokku"
	@echo "  $(GREEN)make deploy-gateway$(NC)   Deploy gateway to Dokku"
	@echo ""
	@echo "$(BOLD)$(CYAN)ROLLBACK$(NC)"
	@echo "  $(GREEN)make rollback-api$(NC)     Rollback API to previous release"
	@echo "  $(GREEN)make rollback-search$(NC)  Rollback search to previous release"
	@echo "  $(GREEN)make rollback-gateway$(NC) Rollback gateway to previous release"
	@echo ""
	@echo "$(BOLD)$(CYAN)SERVICE HELP$(NC)"
	@echo "  $(GREEN)make help-api$(NC)         Show Python API Makefile help"
	@echo "  $(GREEN)make help-search$(NC)      Show Go search Makefile help"
	@echo "  $(GREEN)make help-gateway$(NC)     Show Go gateway Makefile help"
	@echo ""
	@echo "$(BOLD)$(CYAN)UTILITIES$(NC)"
	@echo "  $(GREEN)make status$(NC)           Show status of all Dokku apps"
	@echo "  $(GREEN)make install-deps$(NC)     Install dependencies for all services"
	@echo "  $(GREEN)make clean$(NC)            Clean build artifacts across all services"
	@echo ""
	@echo "$(YELLOW)Tip: Run 'make help-<service>' for service-specific commands$(NC)"
	@echo ""

# ============================================================================
# DEVELOPMENT - Start Services
# ============================================================================

dev-api: ## Start Python API in development mode
	@echo "$(CYAN)Starting Python API...$(NC)"
	cd $(API_DIR) && ./start_dev.sh

dev-api-local: ## Start Python API in local SQLite mode
	@echo "$(CYAN)Starting Python API (local mode)...$(NC)"
	cd $(API_DIR) && ./start_local.sh

dev-web: ## Start React web frontend
	@echo "$(CYAN)Starting React web frontend...$(NC)"
	cd $(WEB_DIR) && yarn start

dev-search: ## Start Go search engine
	@echo "$(CYAN)Starting Go search engine...$(NC)"
	cd $(SEARCH_DIR) && make run

dev-gateway: ## Start Go auth gateway
	@echo "$(CYAN)Starting Go auth gateway...$(NC)"
	cd $(GATEWAY_DIR) && make run

dev-mobile: ## Start React Native app (web mode)
	@echo "$(CYAN)Starting React Native app (web mode)...$(NC)"
	cd $(MOBILE_DIR) && ./run.sh --web

dev-mobile-ios: ## Start React Native app (iOS)
	@echo "$(CYAN)Starting React Native app (iOS)...$(NC)"
	cd $(MOBILE_DIR) && ./run.sh --ios

dev-mobile-android: ## Start React Native app (Android)
	@echo "$(CYAN)Starting React Native app (Android)...$(NC)"
	cd $(MOBILE_DIR) && ./run.sh --android

# ============================================================================
# TESTING
# ============================================================================

test-api: ## Run Python API tests
	@echo "$(CYAN)Running Python API tests...$(NC)"
	cd $(API_DIR) && make test

test-api-unit: ## Run Python API unit tests only
	@echo "$(CYAN)Running Python API unit tests...$(NC)"
	cd $(API_DIR) && make test-unit

test-api-smoke: ## Run Python API smoke tests (fast)
	@echo "$(CYAN)Running Python API smoke tests...$(NC)"
	cd $(API_DIR) && make test-smoke

test-api-parallel: ## Run Python API tests in parallel
	@echo "$(CYAN)Running Python API tests in parallel...$(NC)"
	cd $(API_DIR) && make test-parallel

test-web: ## Run React web tests
	@echo "$(CYAN)Running React web tests...$(NC)"
	cd $(WEB_DIR) && yarn test:ci

test-search: ## Run Go search engine tests
	@echo "$(CYAN)Running Go search engine tests...$(NC)"
	cd $(SEARCH_DIR) && make test

test-gateway: ## Run Go gateway tests
	@echo "$(CYAN)Running Go gateway tests...$(NC)"
	cd $(GATEWAY_DIR) && make test

test-mobile: ## Run React Native tests
	@echo "$(CYAN)Running React Native tests...$(NC)"
	cd $(MOBILE_DIR) && bun run test

test-all: ## Run all service tests
	@echo "$(CYAN)Running all tests...$(NC)"
	@$(MAKE) test-api-smoke
	@$(MAKE) test-web
	@$(MAKE) test-search
	@$(MAKE) test-gateway
	@echo "$(GREEN)All tests completed!$(NC)"

# ============================================================================
# CODE QUALITY
# ============================================================================

lint-api: ## Lint Python API
	@echo "$(CYAN)Linting Python API...$(NC)"
	cd $(API_DIR) && make lint

lint-api-fix: ## Lint Python API with auto-fix
	@echo "$(CYAN)Linting Python API (auto-fix)...$(NC)"
	cd $(API_DIR) && make lint-fix

lint-search: ## Lint Go search engine
	@echo "$(CYAN)Linting Go search engine...$(NC)"
	cd $(SEARCH_DIR) && make lint

lint-gateway: ## Lint Go gateway
	@echo "$(CYAN)Linting Go gateway...$(NC)"
	cd $(GATEWAY_DIR) && make lint

lint-web: ## Lint React web
	@echo "$(CYAN)Linting React web...$(NC)"
	cd $(WEB_DIR) && yarn lint:check

quality-api: ## Full quality check for Python API
	@echo "$(CYAN)Running Python API quality checks...$(NC)"
	cd $(API_DIR) && make quality

type-check-api: ## Type check Python API
	@echo "$(CYAN)Type checking Python API...$(NC)"
	cd $(API_DIR) && make type-check

type-check-web: ## Type check React web
	@echo "$(CYAN)Type checking React web...$(NC)"
	cd $(WEB_DIR) && yarn type-check

# ============================================================================
# BUILD
# ============================================================================

build-api: ## Build Python API Docker image
	@echo "$(CYAN)Building Python API...$(NC)"
	cd $(API_DIR) && docker build -t scenextras-api .

build-web: ## Build React web for production
	@echo "$(CYAN)Building React web...$(NC)"
	cd $(WEB_DIR) && yarn build

build-search: ## Build Go search binary
	@echo "$(CYAN)Building Go search engine...$(NC)"
	cd $(SEARCH_DIR) && make build

build-gateway: ## Build Go gateway binary
	@echo "$(CYAN)Building Go gateway...$(NC)"
	cd $(GATEWAY_DIR) && make build

build-all: ## Build all services
	@echo "$(CYAN)Building all services...$(NC)"
	@$(MAKE) build-search
	@$(MAKE) build-gateway
	@$(MAKE) build-web
	@echo "$(GREEN)All builds completed!$(NC)"

# ============================================================================
# PRODUCTION OPS - Logs
# ============================================================================

logs: ## Interactive production log viewer
	@./scripts/ops/logs.sh

logs-api: ## View Python API logs
	@./scripts/ops/logs.sh dokku scenextras 200

logs-api-follow: ## Follow Python API logs (live)
	@./scripts/ops/logs.sh dokku scenextras -f

logs-search: ## View autocomplete service logs
	@./scripts/ops/logs.sh dokku scenextras-autocomplete 200

logs-search-follow: ## Follow autocomplete logs (live)
	@./scripts/ops/logs.sh dokku scenextras-autocomplete -f

logs-gateway: ## View gateway logs
	@./scripts/ops/logs.sh dokku scenextras-gateway 200

logs-gateway-follow: ## Follow gateway logs (live)
	@./scripts/ops/logs.sh dokku scenextras-gateway -f

logs-nginx: ## View nginx logs
	@./scripts/ops/logs.sh nginx error 100

logs-nginx-access: ## View nginx access logs
	@./scripts/ops/logs.sh nginx access 100

# ============================================================================
# PRODUCTION OPS - Historical Logs
# ============================================================================

history-api: ## Search API historical logs (last 24h)
	@./scripts/ops/logs.sh history scenextras "1 day ago"

history-search: ## Search autocomplete historical logs
	@./scripts/ops/logs.sh history scenextras-autocomplete "1 day ago"

history-gateway: ## Search gateway historical logs
	@./scripts/ops/logs.sh history scenextras-gateway "1 day ago"

history-nginx: ## Search rotated nginx logs
	@./scripts/ops/logs.sh history-nginx error "" 200

history-nginx-502: ## Search nginx for 502 errors
	@./scripts/ops/logs.sh history-nginx error "502" 200

# ============================================================================
# PRODUCTION OPS - Health & Status
# ============================================================================

health: ## Health check all production services
	@./scripts/ops/logs.sh health

status: ## Show Dokku app status
	@./scripts/ops/logs.sh status

status-api: ## Show API status
	@./scripts/ops/logs.sh status scenextras

status-search: ## Show search engine status
	@./scripts/ops/logs.sh status scenextras-autocomplete

status-gateway: ## Show gateway status
	@./scripts/ops/logs.sh status scenextras-gateway

# ============================================================================
# DEPLOYMENT
# ============================================================================

deploy-api: ## Deploy Python API to Dokku
	@echo "$(CYAN)Deploying Python API...$(NC)"
	cd $(API_DIR) && ./deploy_dokku.sh

deploy-search: ## Deploy search engine to Dokku
	@echo "$(CYAN)Deploying search engine...$(NC)"
	cd $(SEARCH_DIR) && make deploy

deploy-gateway: ## Deploy gateway to Dokku
	@echo "$(CYAN)Deploying gateway...$(NC)"
	cd $(GATEWAY_DIR) && make deploy

# ============================================================================
# ROLLBACK
# ============================================================================

rollback-api: ## Rollback API to previous release
	@echo "$(YELLOW)Rolling back API...$(NC)"
	./scripts/rollback/rollback.sh api previous

rollback-search: ## Rollback search to previous release
	@echo "$(YELLOW)Rolling back search...$(NC)"
	./scripts/rollback/rollback.sh search previous

rollback-gateway: ## Rollback gateway to previous release
	@echo "$(YELLOW)Rolling back gateway...$(NC)"
	./scripts/rollback/rollback.sh gateway previous

rollback-list-api: ## List API releases
	./scripts/rollback/rollback.sh api --list

rollback-list-search: ## List search releases
	./scripts/rollback/rollback.sh search --list

# ============================================================================
# SERVICE HELP
# ============================================================================

help-api: ## Show Python API Makefile help
	@cd $(API_DIR) && make help 2>/dev/null || cat Makefile | grep "^##"

help-search: ## Show Go search Makefile help
	@cd $(SEARCH_DIR) && make help

help-gateway: ## Show Go gateway Makefile help
	@cd $(GATEWAY_DIR) && make help

help-web: ## Show React web available scripts
	@echo "$(CYAN)React Web Scripts (yarn):$(NC)"
	@cd $(WEB_DIR) && cat package.json | grep -A 50 '"scripts"' | head -40

help-mobile: ## Show React Native available scripts
	@echo "$(CYAN)React Native Scripts (bun):$(NC)"
	@cd $(MOBILE_DIR) && cat package.json | grep -A 30 '"scripts"' | head -25

# ============================================================================
# UTILITIES
# ============================================================================

install-deps: ## Install dependencies for all services
	@echo "$(CYAN)Installing dependencies...$(NC)"
	@echo "Python API..."
	cd $(API_DIR) && poetry install
	@echo "React Web..."
	cd $(WEB_DIR) && yarn install
	@echo "Go Search..."
	cd $(SEARCH_DIR) && go mod download
	@echo "Go Gateway..."
	cd $(GATEWAY_DIR) && go mod download
	@echo "React Native..."
	cd $(MOBILE_DIR) && bun install
	@echo "$(GREEN)All dependencies installed!$(NC)"

install-api: ## Install Python API dependencies
	cd $(API_DIR) && poetry install

install-web: ## Install React web dependencies
	cd $(WEB_DIR) && yarn install

install-search: ## Install Go search dependencies
	cd $(SEARCH_DIR) && go mod download

install-gateway: ## Install Go gateway dependencies
	cd $(GATEWAY_DIR) && go mod download

install-mobile: ## Install React Native dependencies
	cd $(MOBILE_DIR) && bun install

clean: ## Clean build artifacts across all services
	@echo "$(CYAN)Cleaning build artifacts...$(NC)"
	cd $(SEARCH_DIR) && make clean 2>/dev/null || true
	cd $(GATEWAY_DIR) && make clean 2>/dev/null || true
	cd $(WEB_DIR) && rm -rf build 2>/dev/null || true
	@echo "$(GREEN)Clean complete!$(NC)"

# ============================================================================
# COVERAGE
# ============================================================================

coverage-api: ## Generate Python API coverage report
	@echo "$(CYAN)Generating Python API coverage...$(NC)"
	cd $(API_DIR) && make coverage

coverage-search: ## Generate Go search coverage report
	@echo "$(CYAN)Generating Go search coverage...$(NC)"
	cd $(SEARCH_DIR) && make test-coverage

coverage-gateway: ## Generate Go gateway coverage report
	@echo "$(CYAN)Generating Go gateway coverage...$(NC)"
	cd $(GATEWAY_DIR) && make test

# ============================================================================
# DOCKER
# ============================================================================

docker-search-up: ## Start search engine with docker-compose
	cd $(SEARCH_DIR) && make docker-up

docker-search-down: ## Stop search engine docker-compose
	cd $(SEARCH_DIR) && make docker-down

docker-search-logs: ## View search engine docker logs
	cd $(SEARCH_DIR) && make logs

# ============================================================================
# DATABASE
# ============================================================================

db-migrate: ## Run database migrations (API)
	@echo "$(CYAN)Running database migrations...$(NC)"
	cd $(API_DIR) && poetry run alembic upgrade head

db-migrate-new: ## Create new migration
	@echo "$(CYAN)Creating new migration...$(NC)"
	@read -p "Migration message: " msg; \
	cd $(API_DIR) && poetry run alembic revision --autogenerate -m "$$msg"

# ============================================================================
# QUICK SHORTCUTS
# ============================================================================

# Aliases for common operations
api: dev-api ## Alias: Start API
web: dev-web ## Alias: Start web
search: dev-search ## Alias: Start search
mobile: dev-mobile ## Alias: Start mobile
t: test-api-smoke ## Alias: Quick test
l: logs ## Alias: Logs
h: health ## Alias: Health check
