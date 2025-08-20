#!/bin/bash

# Rebuild script for MASLDatlas Docker deployment
# This script forces a complete rebuild of the Docker image

set -e

IMAGE_NAME="masldatlas-app"
CONTAINER_NAME="masldatlas"

echo "=== MASLDatlas Rebuild Script ==="
echo "This will rebuild the Docker image from scratch"
echo

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🔄 Stopping and removing existing container..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1 || true
    docker rm $CONTAINER_NAME > /dev/null 2>&1 || true
fi

# Remove existing image if it exists
if docker images --format 'table {{.Repository}}' | grep -q "^${IMAGE_NAME}$"; then
    echo "🗑️  Removing existing image..."
    docker rmi $IMAGE_NAME
fi

# Clean Docker cache
echo "🧹 Cleaning Docker build cache..."
docker builder prune -f

# Rebuild image
echo "🔨 Building new Docker image (this may take several minutes)..."
docker build --no-cache -t $IMAGE_NAME .

echo "✅ Rebuild complete!"
echo "🚀 You can now run: ./start.sh"
