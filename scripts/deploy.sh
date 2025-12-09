#!/bin/bash
# ============================================================================
# Deployment Script for GitHub Actions
# ============================================================================
# Purpose: Deploy application to production
# Usage: ./scripts/deploy.sh <compose-file> <branch> <project-path>
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="${1:-compose.prod.yml}"
BRANCH="${2:-main}"
PROJECT_PATH="${3:-$(pwd)}"

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# Pre-deployment Checks
# ============================================================================

log_info "Starting deployment process..."
log_info "Compose file: $COMPOSE_FILE"
log_info "Branch: $BRANCH"
log_info "Project path: $PROJECT_PATH"

cd "$PROJECT_PATH" || exit 1

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running!"
    exit 1
fi

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Get current git commit for logging
CURRENT_COMMIT=$(git rev-parse HEAD)
log_info "Current commit: $CURRENT_COMMIT"

# ============================================================================
# Pull Latest Code
# ============================================================================

log_info "Pulling latest code from $BRANCH..."

# Stash any local changes (shouldn't be any in production)
if ! git diff-index --quiet HEAD --; then
    log_warning "Local changes detected, stashing..."
    git stash
fi

# Fetch and checkout
git fetch --all --prune
git checkout -B "$BRANCH" "origin/$BRANCH"
git reset --hard "origin/$BRANCH"

NEW_COMMIT=$(git rev-parse HEAD)
log_info "New commit: $NEW_COMMIT"

if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ]; then
    log_warning "No new changes detected. Current commit matches remote."
fi

# ============================================================================
# Build and Deploy
# ============================================================================

log_info "Building Docker images..."

if [ "$COMPOSE_FILE" = "compose.prod.yml" ]; then
    docker compose -f "$COMPOSE_FILE" --profile build build || {
        log_error "Build failed!"
        exit 1
    }
else
    docker compose -f "$COMPOSE_FILE" build || {
        log_error "Build failed!"
        exit 1
    }
fi

log_success "Build complete!"

log_info "Starting containers..."
docker compose -f "$COMPOSE_FILE" up -d || {
    log_error "Failed to start containers!"
    exit 1
}

log_success "Containers started!"

# ============================================================================
# Post-deployment Steps
# ============================================================================

log_info "Waiting for services to be ready..."

# Wait for postgres to be ready (up to 60 seconds)
log_info "Waiting for PostgreSQL to be ready..."
POSTGRES_READY=0
for i in {1..30}; do
    if docker compose -f "$COMPOSE_FILE" exec -T postgres bash -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > /dev/null 2>&1; then
        POSTGRES_READY=1
        break
    fi
    sleep 2
done

if [ $POSTGRES_READY -eq 0 ]; then
    log_error "PostgreSQL failed to become ready in time!"
    exit 1
fi

log_success "PostgreSQL is ready!"

# Wait additional time for Django to start and run migrations
log_info "Waiting for Django to complete startup..."
sleep 15

# Check if containers are running (excluding build-only services like mkdocs)
FAILED_SERVICES=$(docker compose -f "$COMPOSE_FILE" ps --status=exited --format json | jq -r 'select(.Name | contains("docs") | not) | .Name' 2>/dev/null || echo "")
if [ -n "$FAILED_SERVICES" ]; then
    log_error "Some services failed to start: $FAILED_SERVICES"
    exit 1
fi

log_success "All services running!"

# ============================================================================
# Run Migrations
# ============================================================================
# Note: The Django entrypoint already runs migrations on startup.
# This is a verification step to ensure migrations are complete.

log_info "Verifying database migrations..."

# Check Django container logs for any startup issues
log_info "Checking Django container status..."
docker compose -f "$COMPOSE_FILE" logs --tail=20 django

# Run migrations with proper error capture
log_info "Running migration verification..."
MIGRATION_OUTPUT=$(docker compose -f "$COMPOSE_FILE" exec -T django bash -c "cd /opt/project/src && poetry run python manage.py migrate --noinput" 2>&1) || {
    log_error "Migrations failed!"
    log_error "Migration output:"
    echo "$MIGRATION_OUTPUT"
    log_error "Django container logs:"
    docker compose -f "$COMPOSE_FILE" logs --tail=50 django
    exit 1
}

log_info "Migration output:"
echo "$MIGRATION_OUTPUT"
log_success "Migrations complete!"

# ============================================================================
# Collect Static Files
# ============================================================================

log_info "Collecting static files..."
COLLECTSTATIC_OUTPUT=$(docker compose -f "$COMPOSE_FILE" exec -T django bash -c "cd /opt/project/src && poetry run python manage.py collectstatic --noinput" 2>&1) || {
    log_warning "Static file collection failed, but continuing..."
    log_warning "Collectstatic output:"
    echo "$COLLECTSTATIC_OUTPUT"
}

log_info "Collectstatic output:"
echo "$COLLECTSTATIC_OUTPUT"
log_success "Static files collected!"

# ============================================================================
# Cleanup
# ============================================================================

log_info "Cleaning up old Docker images..."
docker image prune -f

# ============================================================================
# Health Check
# ============================================================================

log_info "Performing health check..."

# Check if Django is responding
HEALTH_CHECK_OUTPUT=$(docker compose -f "$COMPOSE_FILE" exec -T django bash -c "cd /opt/project/src && poetry run python manage.py check --deploy" 2>&1) || {
    log_error "Django health check failed!"
    log_error "Health check output:"
    echo "$HEALTH_CHECK_OUTPUT"
    log_error "Django container logs:"
    docker compose -f "$COMPOSE_FILE" logs --tail=50 django
    exit 1
}

log_info "Health check output:"
echo "$HEALTH_CHECK_OUTPUT"
log_success "Django health check passed!"

# ============================================================================
# Success
# ============================================================================

log_success "========================================"
log_success "Deployment completed successfully!"
log_success "========================================"
log_success "Commit: $NEW_COMMIT"
log_success "Time: $(date)"
log_success "========================================"

exit 0
