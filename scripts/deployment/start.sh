#!/bin/bash

# Quick start script for MASLDatlas Docker deployment
# Usage: ./start.sh [port]

set -e

PORT=${1:-3838}
IMAGE_NAME="masldatlas-app"
CONTAINER_NAME="masldatlas"

echo "=== MASLDatlas Quick Start Script ==="
echo "Port: $PORT"
echo "Image: $IMAGE_NAME"
echo "Container: $CONTAINER_NAME"
echo

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🔄 Stopping existing container..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1 || true
    docker rm $CONTAINER_NAME > /dev/null 2>&1 || true
fi

# Check if image exists, build if not
if ! docker images --format 'table {{.Repository}}' | grep -q "^${IMAGE_NAME}$"; then
    echo "🔨 Building Docker image (this may take a few minutes)..."
    docker build -t $IMAGE_NAME .
else
    echo "✅ Docker image found: $IMAGE_NAME"
    echo "💡 To rebuild the image, run: docker build --no-cache -t $IMAGE_NAME ."
fi

# Check if port is available
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "❌ Error: Port $PORT is already in use. Please choose a different port."
    echo "Usage: $0 [port]"
    exit 1
fi

# Start the container
echo "🚀 Starting MASLDatlas container..."
docker run -d \
    --name $CONTAINER_NAME \
    -p $PORT:3838 \
    -v "$(pwd)/datasets:/app/datasets" \
    -v "$(pwd)/datasets_config.json:/app/datasets_config.json" \
    -v "$(pwd)/enrichment_sets:/app/enrichment_sets" \
    $IMAGE_NAME

# Wait for the application to start
echo "⏳ Waiting for application to start..."
sleep 10

# Check if container is running
if docker ps --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ MASLDatlas is running successfully!"
    echo "🌐 Access the application at: http://localhost:$PORT"
    echo
    echo "📋 Useful commands:"
    echo "  View logs:     docker logs $CONTAINER_NAME"
    echo "  Stop app:      docker stop $CONTAINER_NAME"
    echo "  Remove app:    docker rm $CONTAINER_NAME"
else
    echo "❌ Error: Container failed to start. Check logs with:"
    echo "  docker logs $CONTAINER_NAME"
    exit 1
fi
