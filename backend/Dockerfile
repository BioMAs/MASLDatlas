# Backend Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (R is required for rpy2/enrichment sets)
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    r-base \
    r-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ app/

# Create necessary directories
RUN mkdir -p figures cache

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
