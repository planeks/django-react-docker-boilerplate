#!/bin/bash
# Restore script for database and media files
# Usage: ./scripts/restore.sh <backup_archive> [compose-file]
# Restores database, media, and optionally .env from backup archive
set -euo pipefail

ARCHIVE_PATH="${1:-}"
COMPOSE_FILE="${2:-compose.prod.yml}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

log() { echo "[$(date +%H:%M:%S)] $1"; }
die() { log "ERROR: $1"; exit 1; }

[ -n "$ARCHIVE_PATH" ] || die "Usage: $0 <backup_archive> [compose-file]"
[ -f "$ARCHIVE_PATH" ] || die "Archive not found: $ARCHIVE_PATH"

cd "$PROJECT_DIR" || die "Cannot cd to $PROJECT_DIR"
[ -f "$COMPOSE_FILE" ] || die "Compose file not found: $COMPOSE_FILE"

# Determine data directory based on compose file
if [[ "$COMPOSE_FILE" == *"prod"* ]]; then
    DATA_DIR="data/prod"
    BACKUPS_DIR="data/prod_backups"
else
    DATA_DIR="data/dev"
    BACKUPS_DIR="data/dev_backups"
fi

log "Restoring from: $ARCHIVE_PATH"

# Create temp directory for extraction
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Extract archive
log "Extracting archive..."
tar -xzvf "$ARCHIVE_PATH" -C "$TEMP_DIR"

# Find database dump in extracted files
DB_DUMP=$(find "$TEMP_DIR" -name "*.sql.gz" | head -1)
[ -n "$DB_DUMP" ] || die "No database dump found in archive"
DB_DUMP_NAME=$(basename "$DB_DUMP")

log "Found database dump: $DB_DUMP_NAME"

# Restore media files if present
MEDIA_SRC=$(find "$TEMP_DIR" -type d -name "media" | head -1)
if [ -n "$MEDIA_SRC" ]; then
    log "Restoring media files..."
    mkdir -p "$DATA_DIR/media"
    cp -r "$MEDIA_SRC"/* "$DATA_DIR/media/" 2>/dev/null || true
    log "Media files restored to $DATA_DIR/media/"
fi

# Ask before restoring .env
ENV_SRC=$(find "$TEMP_DIR" -name ".env" | head -1)
if [ -n "$ENV_SRC" ]; then
    if [ -f ".env" ]; then
        log "WARNING: .env already exists. Backup saved to .env.before_restore"
        cp .env .env.before_restore
    fi
    read -p "Restore .env file? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$ENV_SRC" .env
        log ".env restored"
    fi
fi

# Copy db dump to backups directory
log "Copying database dump to $BACKUPS_DIR..."
mkdir -p "$BACKUPS_DIR"
cp "$DB_DUMP" "$BACKUPS_DIR/"

# Restore database
log "Restoring database (this will DROP and recreate the database)..."
read -p "Continue with database restore? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Stop services using the database
    log "Stopping django and celery services..."
    docker compose -f "$COMPOSE_FILE" stop django celeryworker celerybeat 2>/dev/null || true

    # Restore
    docker compose -f "$COMPOSE_FILE" exec -T postgres restore "$DB_DUMP_NAME"

    # Restart services
    log "Restarting services..."
    docker compose -f "$COMPOSE_FILE" up -d django celeryworker celerybeat 2>/dev/null || true

    log "Database restored from $DB_DUMP_NAME"
else
    log "Database restore skipped. To restore manually:"
    log "  docker compose -f $COMPOSE_FILE exec -T postgres restore $DB_DUMP_NAME"
fi

log "Restore complete"
