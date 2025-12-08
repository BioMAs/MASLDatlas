@echo off
REM MASLDatlas Setup Script for Windows

echo Starting MASLDatlas setup...

REM 1. Create necessary directories
echo Creating directories...
if not exist datasets mkdir datasets
if not exist cache mkdir cache
if not exist config mkdir config
if not exist enrichment_sets mkdir enrichment_sets

REM 2. Check for Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker is not installed.
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo Docker is installed.

echo Setup complete.
echo.
echo To start the application, run:
echo docker-compose up -d
echo.
echo The application will automatically download the necessary datasets on the first run.
echo Access the application at http://localhost:3838
pause
