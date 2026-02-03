#!/bin/bash
# View Logs Script
# Helpful script to view Docker container logs from journald

set -e

CONTAINER_NAME=${1}
LINES=${2:-100}
FOLLOW=${3:-false}

if [ -z "$CONTAINER_NAME" ]; then
    echo "Usage: $0 <container_name> [lines] [follow]"
    echo ""
    echo "Examples:"
    echo "  $0 django 100              # View last 100 lines"
    echo "  $0 postgres 50 true        # Follow last 50 lines"
    echo ""
    echo "Available containers:"
    docker ps --format "{{.Names}}"
    exit 1
fi

echo "Viewing logs for: $CONTAINER_NAME"
echo "========================================="

if [ "$FOLLOW" = "true" ]; then
    journalctl -u docker.service -n "$LINES" -f | grep "$CONTAINER_NAME"
else
    journalctl -u docker.service -n "$LINES" | grep "$CONTAINER_NAME"
fi
