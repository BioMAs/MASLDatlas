# Dataset Volume Management Guide

## Overview

This guide explains how to use Docker volumes to manage MASLDatlas datasets, instead of embedding them in the Docker image. This approach offers several advantages:

- **Lighter Images**: Datasets are not included in the Docker image.
- **Flexibility**: Ability to update datasets without rebuilding the image.
- **Performance**: Direct access to datasets via the host file system.
- **Security**: Datasets mounted as read-only in production.

## Volume Structure

```
Project Directory/
├── datasets/                   # Mounted Volume - Main Datasets
│   ├── Human/                  # Human scRNA-seq data
│   ├── Mouse/                  # Mouse scRNA-seq data
│   ├── Zebrafish/             # Zebrafish scRNA-seq data
│   └── Integrated/            # Integrated cross-species data
├── enrichment_sets/           # Enrichment data (smaller)
├── config/                    # Configuration files
│   ├── datasets_sources.json  # Dataset sources
│   └── datasets_config.json   # Application configuration
└── docker-compose.yml         # Volume configuration
```

## Usage

### 1. Local Development

```bash
# Check volume configuration
./scripts/dataset-management/manage_volume.sh status

# Download datasets to local volume
./scripts/dataset-management/manage_volume.sh download

# Start application with mounted volumes
docker-compose up -d
```

### 2. Production

```bash
# Production volume configuration
./scripts/deployment/deploy-prod.sh your-domain.com

# Datasets are mounted as read-only
# Update datasets:
./scripts/dataset-management/manage_volume.sh download
docker-compose -f docker-compose.prod.yml restart masldatlas
```

## Management Scripts

### Main Script: `manage_volume.sh`

```bash
# Show volume status
./scripts/dataset-management/manage_volume.sh status

# Check volume accessibility
./scripts/dataset-management/manage_volume.sh check

# Download datasets
./scripts/dataset-management/manage_volume.sh download

# List available datasets
./scripts/dataset-management/manage_volume.sh list

# Clean datasets
./scripts/dataset-management/manage_volume.sh clean

# Test Docker mount
./scripts/dataset-management/manage_volume.sh test
```

## Docker Configuration

### Development (docker-compose.yml)
```yaml
services:
  masldatlas:
    build: .
    volumes:
      - ./datasets:/app/datasets                                    # Read/Write Datasets
      - ./config/datasets_config.json:/app/config/datasets_config.json
      - ./config/datasets_sources.json:/app/config/datasets_sources.json
      - ./enrichment_sets:/app/enrichment_sets
```

### Production (docker-compose.prod.yml)
```yaml
services:
  masldatlas:
    volumes:
      - ./datasets:/app/datasets:ro                                 # Read-Only Datasets
      - ./config/datasets_config.json:/app/config/datasets_config.json:ro
      - ./config/datasets_sources.json:/app/config/datasets_sources.json:ro
```
