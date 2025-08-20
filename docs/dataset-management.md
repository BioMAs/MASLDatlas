# Dataset Download and Management System

## Overview

This system automatically downloads large datasets during Docker deployment, avoiding the need to store them in the Git repository.

## Supported Storage Solutions

### 1. Cloud Storage (Recommended)
- **AWS S3**: Professional, scalable
- **Google Cloud Storage**: Good integration with academia
- **Azure Blob Storage**: Enterprise-grade
- **Zenodo**: Free, academic-friendly with DOI
- **Figshare**: Academic data sharing
- **OneDrive/Google Drive**: Simple setup

### 2. File Hosting
- **GitHub Releases**: Up to 2GB per file
- **GitLab**: Larger file support
- **Dropbox**: Easy sharing
- **Academic repositories**: Institution-specific

### 3. Direct HTTP Server
- **Personal server**: Full control
- **Academic server**: Institution hosting

## Implementation

### Option A: Cloud Storage with Download Script
Best for production environments.

### Option B: GitHub Releases
Good for smaller datasets (<2GB per file).

### Option C: External URL List
Flexible, works with any HTTP-accessible storage.

## Security Considerations

- Use checksums (SHA256) to verify file integrity
- Support for authentication tokens when needed
- Retry mechanisms for failed downloads
- Progress indicators for large files

## Configuration

All dataset sources are configured in `datasets_sources.json` which maps each dataset to its download URL and metadata.
