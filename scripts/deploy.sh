#!/bin/bash
# ============================================================================
# Deployment Script for GitHub Actions
# ============================================================================
# Purpose: Safe deployment with backup and rollback capability
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
BACKUP_DIR="${PROJECT_PATH}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_TAG="pre_deploy_${TIMESTAMP}"

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

# ============================================================================
# Backup Current State
# ============================================================================

log_info "Creating pre-deployment backup..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Get current git commit
CURRENT_COMMIT=$(git rev-parse HEAD)
log_info "Current commit: $CURRENT_COMMIT"

# Save current commit to backup file
echo "$CURRENT_COMMIT" > "$BACKUP_DIR/last_known_good_commit"

# Backup database (if PostgreSQL container is running)
if docker compose -f "$COMPOSE_FILE" ps postgres | grep -q "Up"; then
    log_info "Backing up database..."
    docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U postgres -Fc postgres > "$BACKUP_DIR/db_backup_${TIMESTAMP}.dump" || {
        log_warning "Database backup failed, but continuing..."
    }
    log_success "Database backed up to: db_backup_${TIMESTAMP}.dump"
fi

# Tag current Docker images
log_info "Tagging current Docker images for rollback..."
for service in $(docker compose -f "$COMPOSE_FILE" config --services); do
    IMAGE=$(docker compose -f "$COMPOSE_FILE" config | grep -A 5 "^  $service:" | grep "image:" | awk '{print $2}' || echo "")
    if [ -n "$IMAGE" ]; then
        docker tag "$IMAGE" "${IMAGE}:${BACKUP_TAG}" 2>/dev/null || log_warning "Could not tag $IMAGE"
    fi
done

log_success "Backup complete!"

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
    log_error "Rolling back..."
    rollback
    exit 1
}

log_success "Containers started!"

# ============================================================================
# Post-deployment Steps
# ============================================================================

log_info "Waiting for services to be ready..."
sleep 10

# Check if containers are running
FAILED_SERVICES=$(docker compose -f "$COMPOSE_FILE" ps --status=exited --format json | jq -r '.Name' 2>/dev/null || echo "")
if [ -n "$FAILED_SERVICES" ]; then
    log_error "Some services failed to start: $FAILED_SERVICES"
    log_error "Rolling back..."
    rollback
    exit 1
fi

log_success "All services running!"

# ============================================================================
# Run Migrations
# ============================================================================

log_info "Running database migrations..."
docker compose -f "$COMPOSE_FILE" exec -T django poetry run python manage.py migrate --noinput || {
    log_error "Migrations failed!"
    log_error "Rolling back..."
    rollback
    exit 1
}

log_success "Migrations complete!"

# ============================================================================
# Collect Static Files
# ============================================================================

log_info "Collecting static files..."
docker compose -f "$COMPOSE_FILE" exec -T django poetry run python manage.py collectstatic --noinput || {
    log_warning "Static file collection failed, but continuing..."
}

log_success "Static files collected!"

# ============================================================================
# Cleanup
# ============================================================================

log_info "Cleaning up old Docker images..."
docker image prune -f

# Keep only last 7 backups
log_info "Cleaning up old backups..."
cd "$BACKUP_DIR"
ls -t db_backup_*.dump 2>/dev/null | tail -n +8 | xargs -r rm -- 2>/dev/null || true
cd "$PROJECT_PATH"

# ============================================================================
# Health Check
# ============================================================================

log_info "Performing health check..."

# Check if Django is responding
if docker compose -f "$COMPOSE_FILE" exec -T django poetry run python manage.py check --deploy > /dev/null 2>&1; then
    log_success "Django health check passed!"
else
    log_error "Django health check failed!"
    log_error "Rolling back..."
    rollback
    exit 1
fi

# ============================================================================
# Success
# ============================================================================

log_success "========================================"
log_success "Deployment completed successfully!"
log_success "========================================"
log_success "Commit: $NEW_COMMIT"
log_success "Time: $(date)"
log_success "Backup: db_backup_${TIMESTAMP}.dump"
log_success "========================================"

exit 0

# ============================================================================
# Rollback Function
# ============================================================================

rollback() {
    log_warning "========================================"
    log_warning "ROLLING BACK TO PREVIOUS VERSION"
    log_warning "========================================"

    # Get last known good commit
    if [ -f "$BACKUP_DIR/last_known_good_commit" ]; then
        ROLLBACK_COMMIT=$(cat "$BACKUP_DIR/last_known_good_commit")
        log_info "Rolling back to commit: $ROLLBACK_COMMIT"

        # Checkout previous commit
        git checkout "$ROLLBACK_COMMIT"

        # Restart containers
        docker compose -f "$COMPOSE_FILE" up -d --force-recreate

        log_warning "Rollback complete. Please investigate the issue."
        log_warning "To restore database, run:"
        log_warning "  docker compose -f $COMPOSE_FILE exec -T postgres pg_restore -U postgres -d postgres < $BACKUP_DIR/db_backup_${TIMESTAMP}.dump"
    else
        log_error "No backup found for rollback!"
    fi
}
