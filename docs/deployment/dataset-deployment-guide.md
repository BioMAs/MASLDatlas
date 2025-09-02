# 📦 Dataset Deployment Guide for MASLDatlas

## Quick Start

1. **Choose your storage solution** (Zenodo recommended for academic use)
2. **Upload your H5AD files** to the chosen platform
3. **Configure dataset sources** using our helper script
4. **Deploy** and let the system handle downloads automatically

## Step-by-Step Setup

### Option 1: Zenodo (Recommended for Academic Research)

**Why Zenodo?**
- ✅ Free hosting up to 50GB per record
- ✅ DOI assignment for permanent citation
- ✅ Academic-friendly and version control
- ✅ Long-term preservation guarantee

**Setup Steps:**

1. **Create Zenodo account**: Go to https://zenodo.org
2. **Create new upload**: Click "New upload"
3. **Upload your H5AD files**: Drag and drop your datasets
4. **Add metadata**: Fill in title, description, keywords
5. **Publish**: This creates a permanent DOI and URLs
6. **Configure MASLDatlas**:
```bash
./configure_datasets.sh setup-zenodo
# Enter your Zenodo record ID when prompted
```

### Option 2: GitHub Releases (Good for <2GB files)

**Setup Steps:**

1. **Go to your repository**: https://github.com/yourusername/MASLDatlas
2. **Create release**: Click "Releases" → "Create a new release"
3. **Upload files**: Attach your H5AD files as release assets
4. **Configure MASLDatlas**:
```bash
./configure_datasets.sh setup-github yourusername/MASLDatlas
# Enter your release tag when prompted
```

### Option 3: AWS S3 (Production/Enterprise)

**Setup Steps:**

1. **Create S3 bucket**: In AWS Console
2. **Upload files**: Use AWS CLI or web interface
3. **Configure public access**: Set appropriate permissions
4. **Configure MASLDatlas**:
```bash
./configure_datasets.sh setup-s3
# Enter bucket name and region when prompted
```

## Configuration Examples

### Complete Zenodo Configuration
```json
{
  "datasets": {
    "Human": {
      "GSE136103": {
        "url": "https://zenodo.org/record/8123456/files/GSE136103.h5ad",
        "sha256": "a1b2c3d4e5f6789abcdef123456789abcdef123456789abcdef123456789abcdef",
        "size_mb": 450,
        "description": "Human liver scRNA-seq dataset GSE136103"
      },
      "GSE181483": {
        "url": "https://zenodo.org/record/8123456/files/GSE181483.h5ad",
        "sha256": "b2c3d4e5f6789abcdef123456789abcdef123456789abcdef123456789abcdef1",
        "size_mb": 380,
        "description": "Human liver scRNA-seq dataset GSE181483"
      }
    },
    "Mouse": {
      "GSE145086": {
        "url": "https://zenodo.org/record/8123456/files/GSE145086.h5ad",
        "sha256": "c3d4e5f6789abcdef123456789abcdef123456789abcdef123456789abcdef12",
        "size_mb": 320,
        "description": "Mouse liver scRNA-seq dataset GSE145086"
      }
    }
  }
}
```

## Security and Verification

### Generate Checksums
```bash
# Generate SHA256 hashes for all your local H5AD files
./configure_datasets.sh generate-hashes

# This creates dataset_hashes.txt with checksums
# Copy these hashes to your datasets_sources.json
```

### Validate Configuration
```bash
# Check your configuration is valid
./configure_datasets.sh validate

# Test downloads
python3 download_datasets.py list
python3 download_datasets.py download --species Human  # Test one species
```

## Deployment Scenarios

### Docker Build Time (Recommended)
```dockerfile
# Datasets downloaded during image build
# Pros: Faster container startup
# Cons: Larger image size, slower builds
```

### Container Startup (Alternative)
```bash
# Datasets downloaded when container starts
docker run -e AUTO_DOWNLOAD_DATASETS=true masldatlas-app

# Pros: Smaller images, flexible
# Cons: Slower first startup
```

### Hybrid Approach
```bash
# Build with small datasets, download large ones at runtime
# Best of both worlds for production
```

## Production Deployment

### With Docker Compose
```yaml
# docker-compose.prod.yml
environment:
  - AUTO_DOWNLOAD_DATASETS=true
  - SKIP_DATASET_CHECK=false
volumes:
  - masldatlas_datasets:/app/datasets  # Persistent storage
```

### Monitoring and Maintenance
```bash
# Check dataset status
docker exec masldatlas-container python3 download_datasets.py list

# Re-download if needed
docker exec masldatlas-container python3 download_datasets.py download

# View download logs
docker logs masldatlas-container
```

## Troubleshooting

### Common Issues

**Download Fails:**
```bash
# Check URL accessibility
curl -I "your_dataset_url"

# Test with single dataset
python3 download_datasets.py download --species Human --no-parallel

# Check logs for specific errors
```

**Checksum Mismatch:**
```bash
# Regenerate checksums
./configure_datasets.sh generate-hashes

# Update datasets_sources.json with new hashes
```

**Container Startup Timeout:**
```bash
# Skip dataset check for debugging
docker run -e SKIP_DATASET_CHECK=true masldatlas-app

# Or disable auto-download
docker run -e AUTO_DOWNLOAD_DATASETS=false masldatlas-app
```

## Best Practices

### For Academic Use
- ✅ Use Zenodo for permanent archival
- ✅ Include proper metadata and descriptions
- ✅ Version your datasets with releases
- ✅ Document data provenance

### For Production
- ✅ Use cloud storage (S3, GCS, Azure)
- ✅ Enable redundancy and backups
- ✅ Monitor download performance
- ✅ Implement access controls

### For Development
- ✅ Use smaller test datasets
- ✅ Cache downloads between builds
- ✅ Version control your configurations
- ✅ Document dataset sources

## Migration Guide

### From Local to External Storage

1. **Backup your current datasets**
2. **Choose storage provider**
3. **Upload datasets with proper naming**
4. **Configure datasets_sources.json**
5. **Test download process**
6. **Update deployment scripts**
7. **Remove local datasets from Git**

---

## Support

For issues with dataset management:
1. Check the [troubleshooting section](#troubleshooting)
2. Validate your configuration with `./configure_datasets.sh validate`
3. Test downloads manually with `python3 download_datasets.py`
4. Check container logs for detailed error messages
