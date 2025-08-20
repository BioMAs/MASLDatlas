# Dataset Testing Scripts Documentation

## Overview

This directory contains several testing scripts to validate the dataset download system:

## Scripts

### 1. `test_dataset_download.py` - Basic Connectivity Test
**Purpose**: Test dataset accessibility and configuration validation without downloading large files.

```bash
# Basic test (recommended first step)
python3 test_dataset_download.py

# Include partial download tests
python3 test_dataset_download.py --download-test

# Show help
python3 test_dataset_download.py --help
```

**What it tests**:
- ✅ Configuration file validity
- ✅ URL accessibility for all datasets
- ✅ Checksum format validation (MD5/SHA256)
- ✅ File size verification
- ✅ Zenodo API accessibility
- ✅ Optional: Partial download tests (1KB samples)

### 2. `test_complete_download.py` - Full Download Test
**Purpose**: Test complete download pipeline with actual file downloads.

```bash
# Validation only (no downloads)
python3 test_complete_download.py --validation-only

# Quick test (download smallest dataset ~392MB)
python3 test_complete_download.py --quick-test

# Show help
python3 test_complete_download.py --help
```

**What it tests**:
- ✅ Complete download pipeline
- ✅ File integrity verification
- ✅ Checksum validation (MD5)
- ✅ Configuration validation
- ✅ Temporary directory handling

### 3. `update_dataset_config.py` - Configuration Helper
**Purpose**: Generate correct dataset metadata from Zenodo API.

```bash
# Get file information from Zenodo
python3 update_dataset_config.py
```

**What it does**:
- 📊 Retrieves actual file sizes and checksums from Zenodo
- 🔧 Helps update `datasets_sources.json` with correct values
- 🔍 Validates Zenodo record accessibility

## Usage Workflow

### Initial Setup Testing
```bash
# 1. Test basic connectivity (fast, no downloads)
python3 test_dataset_download.py

# 2. If successful, validate configuration
python3 test_complete_download.py --validation-only

# 3. Optional: Test actual download with smallest file
python3 test_complete_download.py --quick-test
```

### Troubleshooting
```bash
# If datasets_sources.json has incorrect metadata
python3 update_dataset_config.py

# Test partial downloads to verify accessibility
python3 test_dataset_download.py --download-test

# Check configuration and file listing
python3 download_datasets.py list
```

### Production Validation
```bash
# Before deployment, run full test suite
python3 test_dataset_download.py
python3 test_complete_download.py --validation-only

# Test Docker integration
docker build -t masldatlas-test .
docker run --rm masldatlas-test python3 test_dataset_download.py
```

## Expected Output

### Successful Basic Test
```
🧪 Dataset Download Test Suite
============================================================
📊 Summary:
   Total datasets: 4
   Accessible datasets: 4
   Success rate: 100.0%
   Total data size: 11,962 MB (11.7 GB)

🏁 Test Results:
   ✅ All tests passed! Dataset download system is ready.
```

### Successful Download Test
```
🏁 Test Results:
   ✅ All tests passed! Dataset download system is fully functional.
```

## Common Issues and Solutions

### 1. URL Not Accessible
```
❌ URL not accessible: HTTP 404
```
**Solution**: Check if the Zenodo record is public and files are available.

### 2. Checksum Format Error
```
❌ SHA256 format: SHA256 hash should be 64 characters, got 32
```
**Solution**: Run `update_dataset_config.py` to get correct checksums.

### 3. Size Mismatch
```
⚠️ Size mismatch: expected 797 MB, got 759.2 MB
```
**Solution**: Update `datasets_sources.json` with actual file sizes.

### 4. Network Timeout
```
❌ URL not accessible: Read timed out
```
**Solution**: Check internet connection or increase timeout in configuration.

## Configuration File Format

The tests expect `datasets_sources.json` in this format:

```json
{
  "datasets": {
    "Human": {
      "GSE181483": {
        "url": "https://zenodo.org/api/records/16887250/files/GSE181483.h5ad/content",
        "md5": "53d417ce4ca81a5838200dc14f7e12b3",
        "size_mb": 759.2,
        "size_bytes": 796102698,
        "description": "Human liver scRNA-seq dataset GSE181483"
      }
    }
  },
  "config": {
    "download_timeout": 3600,
    "retry_attempts": 3,
    "verify_checksums": true,
    "parallel_downloads": 2
  }
}
```

## Integration with Docker

These scripts are integrated into the Docker build process:

```dockerfile
# Test dataset configuration during build
RUN python3 test_dataset_download.py

# Download datasets during build (optional)
RUN python3 download_datasets.py download
```

## Automation

For CI/CD pipelines, use:

```bash
# In GitHub Actions or similar
python3 test_dataset_download.py
if [ $? -eq 0 ]; then
    echo "✅ Dataset tests passed"
else
    echo "❌ Dataset tests failed"
    exit 1
fi
```
