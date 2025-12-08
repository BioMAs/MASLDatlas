# Docker Optimization Guide

## Overview

Your MASLDatlas application is optimized to run in a Docker environment with maximum performance and robustness.

## Optimization Features

### Improved Docker Image
- **Optimization Modules**: Pre-installed in the image.
- **System Cache**: Configured for containerized environment.
- **Startup Scripts**: Optimized with automatic validation.
- **Environment Variables**: Configured for performance.

### Optimized Build
- **Docker Layers**: Optimized for caching.
- **Smart Exclusions**: Via improved .dockerignore.
- **Pre-build Validation**: Of the optimization system.
- **Automatic Testing**: Of modules in the image.

### Optimized Runtime
- **Smart Startup**: With validation of optimizations.
- **Memory Cleanup**: Automatic before launch.
- **R Configuration**: Optimized for containers.
- **Monitoring**: Real-time performance tracking.

## Modified/Created Docker Files

### New Files
```
docker-compose.optimized.yml     # Optimized production configuration
scripts/docker-build-optimized.sh   # Build script with optimizations
docs/docker_optimization.md         # This guide
```

### Modified Files
```
Dockerfile                       # Integration of optimization modules
scripts/deployment/startup.sh   # Optimized startup with validations
.dockerignore                    # Optimized exclusions
```

## Building the Image

### Standard Build with Optimizations
```bash
# Automated build with all optimizations
./scripts/docker-build-optimized.sh
```

### Manual Build
```bash
# Build with optimized tag
docker build -t masldatlas:optimized .
```

### Build Verification
```bash
# Verify that optimization modules are included
docker run --rm masldatlas:optimized ls -la /app/R/
docker run --rm masldatlas:optimized ls -la /app/scripts/setup/
```

## Optimized Deployment

### Option 1: Optimized Docker Compose (Recommended)
```bash
# Start with optimized configuration
docker-compose -f docker-compose.optimized.yml up -d

# View logs with optimizations
docker-compose -f docker-compose.optimized.yml logs -f masldatlas
```

### Option 2: Direct Docker Run
```bash
# Start with manual optimizations
docker run -d \
  -p 3838:3838 \
  -v $(pwd)/datasets:/app/datasets \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/enrichment_sets:/app/enrichment_sets \
  -e R_MAX_VSIZE=8Gb \
  -e MASLDATLAS_MONITORING_ENABLED=true \
  --memory=8g \
  --cpus=4 \
  --tmpfs /tmp:noexec,nosuid,size=2g \
  --tmpfs /app/cache:noexec,nosuid,size=1g \
  --name masldatlas-optimized \
  masldatlas:optimized
```

### Option 3: Standard Docker Compose
```bash
# Start with standard configuration (still includes optimizations)
docker-compose up -d
```
