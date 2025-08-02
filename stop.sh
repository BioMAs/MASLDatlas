#!/bin/bash

# Stop script for MASLDatlas Docker deployment
# Usage: ./stop.sh

set -e

CONTAINER_NAME="masldatlas"

echo "=== MASLDatlas Stop Script ==="

# Check if container exists and is running
if docker ps --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🔄 Stopping MASLDatlas container..."
    docker stop $CONTAINER_NAME
    echo "✅ Container stopped successfully"
else
    echo "ℹ️  Container '$CONTAINER_NAME' is not running"
fi

# Check if container exists (stopped)
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🗑️  Removing container..."
    docker rm $CONTAINER_NAME
    echo "✅ Container removed successfully"
fi

echo "🏁 MASLDatlas has been stopped and removed"
