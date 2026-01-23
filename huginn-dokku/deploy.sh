#!/bin/bash
set -e

# Huginn Dokku Deployment Script
# Usage: ./deploy.sh [setup|deploy|config|logs|status]

DOKKU_HOST="dokku-scenextras.eastus.cloudapp.azure.com"
SSH_KEY="~/.ssh/dokku_azure"
APP_NAME="huginn"
DOMAIN="huginn.scenextras.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ssh_dokku() {
    ssh -i $SSH_KEY dokku@$DOKKU_HOST "$@"
}

setup() {
    echo -e "${GREEN}Setting up Huginn on Dokku...${NC}"

    # Create app
    echo "Creating app..."
    ssh_dokku "dokku apps:create $APP_NAME" 2>/dev/null || echo "App already exists"

    # Create PostgreSQL database
    echo "Setting up PostgreSQL..."
    ssh_dokku "dokku postgres:create huginn-db" 2>/dev/null || echo "Database already exists"
    ssh_dokku "dokku postgres:link huginn-db $APP_NAME" 2>/dev/null || echo "Database already linked"

    # Set domain
    echo "Configuring domain..."
    ssh_dokku "dokku domains:add $APP_NAME $DOMAIN" 2>/dev/null || echo "Domain already configured"

    # Enable SSL (Let's Encrypt)
    echo "Enabling SSL..."
    ssh_dokku "dokku letsencrypt:enable $APP_NAME" 2>/dev/null || echo "SSL setup may need manual intervention"

    # Configure environment variables
    echo "Setting environment variables..."
    configure_env

    # Set port mapping
    ssh_dokku "dokku ports:set $APP_NAME http:80:3000 https:443:3000"

    # Scale workers
    ssh_dokku "dokku ps:scale $APP_NAME web=1 worker=1"

    echo -e "${GREEN}Setup complete! Now run: ./deploy.sh deploy${NC}"
}

configure_env() {
    # Generate secrets if not provided
    SECRET_KEY=${HUGINN_SECRET_KEY:-$(openssl rand -hex 64)}
    INVITATION_CODE=${HUGINN_INVITATION_CODE:-$(openssl rand -hex 16)}

    ssh_dokku "dokku config:set --no-restart $APP_NAME \
        RAILS_ENV=production \
        DOMAIN=$DOMAIN \
        FORCE_SSL=true \
        RAILS_SERVE_STATIC_FILES=true \
        RAILS_LOG_TO_STDOUT=true \
        SECRET_KEY_BASE=$SECRET_KEY \
        INVITATION_CODE=$INVITATION_CODE \
        SEED_USERNAME=admin \
        SEED_PASSWORD=${HUGINN_ADMIN_PASSWORD:-changeme123} \
        SEED_EMAIL=${HUGINN_ADMIN_EMAIL:-admin@example.com} \
        TIMEZONE=${TIMEZONE:-America/Los_Angeles} \
        SMTP_DOMAIN=${SMTP_DOMAIN:-} \
        SMTP_USER_NAME=${SMTP_USER:-} \
        SMTP_PASSWORD=${SMTP_PASSWORD:-} \
        SMTP_SERVER=${SMTP_SERVER:-} \
        SMTP_PORT=${SMTP_PORT:-587} \
        SMTP_AUTHENTICATION=${SMTP_AUTH:-plain} \
        SMTP_ENABLE_STARTTLS_AUTO=${SMTP_STARTTLS:-true} \
        EMAIL_FROM_ADDRESS=${EMAIL_FROM:-huginn@$DOMAIN}"

    echo -e "${YELLOW}IMPORTANT: Save these credentials!${NC}"
    echo "Invitation Code: $INVITATION_CODE"
    echo "Admin Password: ${HUGINN_ADMIN_PASSWORD:-changeme123}"
}

deploy() {
    echo -e "${GREEN}Deploying Huginn...${NC}"

    # Initialize git if needed
    if [ ! -d .git ]; then
        git init
        git add .
        git commit -m "Initial Huginn deployment"
    fi

    # Add dokku remote
    git remote remove dokku 2>/dev/null || true
    git remote add dokku dokku@$DOKKU_HOST:$APP_NAME

    # Deploy
    git add .
    git commit -m "Deploy $(date +%Y%m%d-%H%M%S)" --allow-empty
    git push dokku main:main --force

    echo -e "${GREEN}Deployment complete!${NC}"
    echo "Access Huginn at: https://$DOMAIN"
}

logs() {
    ssh_dokku "dokku logs $APP_NAME -t"
}

status() {
    echo "=== App Status ==="
    ssh_dokku "dokku ps:report $APP_NAME"
    echo ""
    echo "=== Health Check ==="
    curl -s "https://$DOMAIN/status" || echo "Service may still be starting..."
}

rollback() {
    echo -e "${YELLOW}Rolling back Huginn...${NC}"
    ssh_dokku "dokku ps:rollback $APP_NAME"
}

restart() {
    echo "Restarting Huginn..."
    ssh_dokku "dokku ps:restart $APP_NAME"
}

enter() {
    echo "Entering Huginn container..."
    ssh_dokku "dokku enter $APP_NAME"
}

rails_console() {
    echo "Starting Rails console..."
    ssh_dokku "dokku run $APP_NAME bundle exec rails console"
}

run_script() {
    if [ -z "$1" ]; then
        echo "Usage: ./deploy.sh run-script <script.rb>"
        exit 1
    fi

    # Copy script to server and run it
    SCRIPT_CONTENT=$(cat "$1")
    ssh_dokku "dokku run $APP_NAME bundle exec rails runner '$SCRIPT_CONTENT'"
}

case "${1:-help}" in
    setup)
        setup
        ;;
    deploy)
        deploy
        ;;
    config)
        configure_env
        ;;
    logs)
        logs
        ;;
    status)
        status
        ;;
    rollback)
        rollback
        ;;
    restart)
        restart
        ;;
    enter)
        enter
        ;;
    console)
        rails_console
        ;;
    run-script)
        run_script "$2"
        ;;
    *)
        echo "Huginn Dokku Deployment"
        echo ""
        echo "Usage: ./deploy.sh <command>"
        echo ""
        echo "Commands:"
        echo "  setup       - Create app, database, configure SSL"
        echo "  deploy      - Deploy/redeploy Huginn"
        echo "  config      - Update environment variables"
        echo "  logs        - Tail application logs"
        echo "  status      - Check app status"
        echo "  rollback    - Rollback to previous version"
        echo "  restart     - Restart all processes"
        echo "  enter       - Enter container shell"
        echo "  console     - Start Rails console"
        echo "  run-script  - Run a Ruby script in container"
        echo ""
        echo "Environment variables (set before running):"
        echo "  HUGINN_ADMIN_PASSWORD - Admin password (required)"
        echo "  HUGINN_ADMIN_EMAIL    - Admin email"
        echo "  SMTP_SERVER           - SMTP server for notifications"
        echo "  SMTP_USER             - SMTP username"
        echo "  SMTP_PASSWORD         - SMTP password"
        ;;
esac
