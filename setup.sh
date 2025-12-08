#!/bin/bash

# MASLDatlas Setup Script
# This script prepares the environment for the MASLDatlas application.

echo "Starting MASLDatlas setup..."

# 1. Create necessary directories
echo "Creating directories..."
mkdir -p datasets
mkdir -p cache
mkdir -p config
mkdir -p enrichment_sets

# 2. Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    exit 1
fi

echo "Docker is installed."

# 3. Check for Docker Compose
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not found."
    echo "Please ensure Docker Compose is installed (usually included with Docker Desktop)."
    exit 1
fi

echo "Setup complete."
echo ""
echo "To start the application, run:"
echo "docker-compose up -d"
echo ""
echo "The application will automatically download the necessary datasets on the first run."
echo "Access the application at http://localhost:3838"
