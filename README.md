# Multi-species scRNA-seq Atlas of MASLD

This Shiny application provides an interactive interface for exploring and analyzing single-cell RNA sequencing data across multiple species (Human, Mouse, and Zebrafish) in the context of MASLD (Metabolic Associated Steatotic Liver Disease).

## Prerequisites

### For Local Installation
- R (version 4.0 or higher)
- Python 3.9
- Required R packages:
  - shiny, bslib, dplyr, ggplot2
  - shinydisconnect, shinycssloaders, shinyjs
  - reticulate, DT, readr, shinyBS
  - ggpubr, shinyWidgets, fenr, stringr, jsonlite

### For Docker Installation (Recommended)
- Docker Desktop installed and running
- At least 4GB of available RAM
- 10GB of free disk space

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/MASLDatlas.git
cd MASLDatlas
```

2. Set up the Python virtual environment (this will be done automatically using the provided script):
```R
source("scripts/setup/reticulate_create_env.R")
```

This script will:
- Create a Python virtual environment named "fibrosis_shiny"
- Install required Python packages:
  - scanpy
  - python-igraph
  - leidenalg
  - decoupler
  - omnipath
  - marsilea (v0.4.0)
  - pydeseq2
  - adjustText
  - psutil

## Running the Application

### Option 1: Local R Installation

To launch the application locally, run:
```R
shiny::runApp()
```

The application will be available in your default web browser.

### Option 2: Docker Container (Recommended)

#### Prerequisites for Docker
- Docker installed on your system
- At least 4GB of available RAM

#### Building and Running with Docker

1. **Build the Docker image:**
```bash
docker build -t masldatlas-app .
```

2. **Run the container:**
```bash
docker run -p 3838:3838 masldatlas-app
```

3. **Access the application:**
Open your web browser and navigate to: `http://localhost:3838`

#### Advanced Docker Usage

**Run with custom port:**
```bash
docker run -p 8080:3838 masldatlas-app
# Access at http://localhost:8080
```

**Run in detached mode (background):**
```bash
docker run -d -p 3838:3838 --name masldatlas masldatlas-app
```

**Stop the container:**
```bash
docker stop masldatlas
```

**View container logs:**
```bash
docker logs masldatlas
```

**Mount local datasets directory (for development):**
```bash
docker run -p 3838:3838 -v $(pwd)/datasets:/app/datasets masldatlas-app
```

#### Using Docker Compose (Alternative)

Create a `docker-compose.yml` file:
```yaml
version: '3.8'
services:
  masldatlas:
    build: .
    ports:
      - "3838:3838"
    volumes:
      - ./datasets:/app/datasets
      - ./datasets_config.json:/app/datasets_config.json
    restart: unless-stopped
```

Then run:
```bash
docker-compose up -d
```

#### Quick Start Scripts

For even easier deployment, use the provided scripts:

**Start the application:**
```bash
./scripts/deployment/start.sh          # Default port 3838
./scripts/deployment/start.sh 8080     # Custom port 8080
```

**Stop the application:**
```bash
./scripts/deployment/stop.sh
```

**Rebuild the Docker image (if packages are missing):**
```bash
./scripts/deployment/rebuild.sh
```

These scripts will automatically:
- Build the Docker image if needed
- Handle port conflicts
- Mount necessary volumes
- Provide helpful status messages

## Production Deployment

For production environments with Traefik reverse proxy integration:

### Prerequisites
- Docker and Docker Compose installed
- Traefik running with `traefik-network` network
- DNS pointing to your server
- SSL certificates managed by Traefik (Let's Encrypt recommended)

### Quick Production Deployment

1. **Configure your domain:**
```bash
# Copy environment template
cp .env.example .env

# Edit the domain configuration
nano .env  # Set MASLDATLAS_DOMAIN=your-domain.com
```

2. **Deploy with the automated script:**
```bash
# Deploy with custom domain
./scripts/deployment/deploy-prod.sh masld.yourdomain.com

# Or deploy with default domain from .env
./scripts/deployment/deploy-prod.sh
```

3. **Manual deployment (alternative):**
```bash
# Update domain in docker-compose.prod.yml
sed -i 's/masldatlas\.yourdomain\.com/your-domain.com/g' docker-compose.prod.yml

# Deploy the stack
docker-compose -f docker-compose.prod.yml up -d
```

### Resource Requirements
- **RAM**: Minimum 4GB, recommended 8GB+
- **CPU**: Multi-core recommended for multiple users
- **Storage**: 10GB+ for application and datasets
- **Network**: Reverse proxy (Traefik) handling SSL/TLS

### Traefik Integration Features
- **Automatic SSL/TLS**: Let's Encrypt certificate management
- **Load Balancing**: Multi-instance support
- **Health Checks**: Automatic unhealthy instance removal
- **Security Headers**: HSTS, XSS protection, content type validation
- **Rate Limiting**: Protection against abuse (100 req/min average, 200 burst)
- **HTTP to HTTPS Redirect**: Automatic secure connection enforcement

### Security Features
- **Non-root containers**: Enhanced security posture
- **Resource limits**: CPU and memory constraints
- **Security headers**: Comprehensive HTTP security headers
- **Rate limiting**: Request throttling and abuse protection
- **Internal networks**: Container isolation
- **Health monitoring**: Automated failure detection

### Monitoring and Management
```bash
# View service status
docker-compose -f docker-compose.prod.yml ps

# Monitor resource usage
docker stats masldatlas-prod

# View application logs
docker-compose -f docker-compose.prod.yml logs -f

# Health check
curl -f https://your-domain.com || echo "Application not responding"

# Update deployment
./deploy-prod.sh your-domain.com
```

### Scaling for High Availability
```yaml
# In docker-compose.prod.yml, add multiple replicas
deploy:
  replicas: 3
  update_config:
    parallelism: 1
    delay: 10s
  restart_policy:
    condition: on-failure
```

## Features

The application includes several key features:

1. **Dataset Import**
   - Select from Human, Mouse, Zebrafish, or Integrated datasets
   - Visualize UMAP plots
   - View cluster information and cell type groups

2. **Cluster Analysis**
   - Select specific clusters for analysis
   - Visualize gene expression
   - Calculate co-expression patterns

3. **Differential Expression**
   - Perform differential expression analysis
   - Visualize results through various plots
   - Access enrichment analysis (GO, BP, KEGG, Reactome, WikiPathways)

4. **Pseudo Bulk Analysis**
   - Analyze aggregated expression data

## Data Structure

The application expects data in the following locations:
- `datasets/`: Contains the H5AD files organized by organism (Human/, Mouse/, Zebrafish/, Integrated/)
- `enrichment_sets/`: Contains RDS and RData files for different species and analysis types
- `www/`: Contains static assets
- `app_cache/`: Contains cached data for improved performance
- `datasets_config.json`: Configuration file that defines available datasets

## Dataset Management

### Overview

The application uses an external dataset download system to handle large H5AD files that are too big for Git repositories. Datasets are automatically downloaded during Docker build or container startup.

### Storage Options

1. **Zenodo (Recommended for Academic Use)**
   - Free hosting up to 50GB per record
   - DOI assignment for permanent citation
   - Version control and academic-friendly

2. **GitHub Releases**
   - Free with GitHub account
   - 2GB per file limit
   - Good for smaller datasets

3. **Cloud Storage (AWS S3, Google Cloud, Azure)**
   - Professional cloud storage
   - Scalable and reliable
   - Requires account setup

4. **Custom HTTP Server**
   - Your own server or institutional storage
   - Full control over access and permissions

### Configuration

The application uses `datasets_sources.json` to configure dataset download sources:

```json
{
  "datasets": {
    "Human": {
      "GSE136103": {
        "url": "https://zenodo.org/record/XXXXXX/files/GSE136103.h5ad",
        "sha256": "a1b2c3d4e5f6789...",
        "size_mb": 450,
        "description": "Human liver scRNA-seq dataset GSE136103"
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

### Setup Instructions

1. **Configure your storage provider:**
```bash
# For Zenodo
./scripts/dataset-management/configure_datasets.sh setup-zenodo

# For GitHub Releases
./scripts/dataset-management/configure_datasets.sh setup-github yourusername/MASLDatlas

# For AWS S3
./scripts/dataset-management/configure_datasets.sh setup-s3

# For custom server
./scripts/dataset-management/configure_datasets.sh setup-custom
```

2. **Generate checksums for verification:**
```bash
./scripts/dataset-management/configure_datasets.sh generate-hashes
```

3. **Validate configuration:**
```bash
python3 scripts/testing/test_dataset_download.py
```

## Testing the Dataset System

Before deploying the application, it's recommended to test the dataset download system:

### Quick Connectivity Test
```bash
# Test dataset accessibility without downloading files
python3 scripts/testing/test_dataset_download.py
```

This script will:
- ✅ Validate configuration file format
- ✅ Check URL accessibility for all datasets  
- ✅ Verify checksum formats (MD5/SHA256)
- ✅ Compare expected vs actual file sizes
- ✅ Test Zenodo API connectivity

### Complete Download Test
```bash
# Validation only (recommended first)
python3 scripts/testing/test_complete_download.py --validation-only

# Test with smallest dataset download (~392MB)
python3 scripts/testing/test_complete_download.py --quick-test
```

### Advanced Testing
```bash
# Interactive test suite (recommended)
./scripts/testing/test_datasets.sh

# Production readiness test
./scripts/testing/test_datasets.sh production

# Include partial download tests (downloads 1KB samples)
python3 scripts/testing/test_dataset_download.py --download-test

# Update configuration with correct metadata from Zenodo
python3 scripts/dataset-management/update_dataset_config.py

# Show available test options
python3 scripts/testing/test_dataset_download.py --help
```

### Expected Output for Successful Tests
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

### Integration with Docker
```bash
# Test within Docker container
docker run --rm masldatlas-app python3 scripts/testing/test_dataset_download.py

# Test during build (automatic)
docker build -t masldatlas-test .
```

For detailed testing documentation, see [Dataset Testing Guide](docs/dataset-testing-guide.md).

### Manual Dataset Management

**Download datasets manually:**
```bash
# Download all datasets
python3 scripts/dataset-management/download_datasets.py download

# Download specific species
python3 scripts/dataset-management/download_datasets.py download --species Human Mouse

# List configured datasets
python3 scripts/dataset-management/download_datasets.py list

# Clean downloaded datasets
python3 scripts/dataset-management/download_datasets.py clean
```

**Docker environment variables:**
```bash
# Enable/disable automatic download
AUTO_DOWNLOAD_DATASETS=true

# Skip dataset checks
SKIP_DATASET_CHECK=false
```

### Application Dataset Configuration

The application uses a JSON configuration file (`datasets_config.json`) to manage available datasets for the UI. This is separate from the download configuration:

### Adding New Datasets

1. **Using the R script (recommended):**
```R
source("scripts/dataset-management/dataset_manager.R")

# Add a new dataset
add_dataset("Human", "Individual Dataset", "GSE123456")
add_dataset("Mouse", "Datasets", "GSE789012")

# List all datasets
list_all_datasets()
```

2. **Manual editing of config/datasets_config.json:**
```json
{
  "Human": {
    "Individual Dataset": ["GSE136103", "GSE181483", "GSE123456"]
  },
  "Mouse": {
    "Datasets": ["GSE145086", "GSE789012"]
  }
}
```

3. **Place the corresponding H5AD file** in the appropriate directory:
   - For Human datasets: `datasets/Human/GSE123456.h5ad`
   - For Mouse datasets: `datasets/Mouse/GSE789012.h5ad`

### Dataset File Structure
```
datasets/
├── Human/
│   ├── GSE136103.h5ad
│   └── GSE181483.h5ad
├── Mouse/
│   └── GSE145086.h5ad
├── Zebrafish/
│   └── GSE181987.h5ad
└── Integrated/
    └── Fibrotic Integrated Cross Species.h5ad
```

## Troubleshooting

### General Issues
1. Ensure all required packages are properly installed
2. Check Python virtual environment is correctly set up
3. Verify data files are present in the correct locations
4. Clear browser cache if the interface is not loading properly

### Docker-specific Issues

**Container fails to build:**
- Check Docker daemon is running: `docker info`
- Ensure sufficient disk space (at least 5GB free)
- Try building with more verbose output: `docker build --no-cache -t masldatlas-app .`

**Container starts but application is not accessible:**
- Verify port mapping: `docker ps` to see running containers
- Check if port 3838 is already in use: `lsof -i :3838` (macOS/Linux) or `netstat -an | findstr 3838` (Windows)
- Try a different port: `docker run -p 8080:3838 masldatlas-app`

**Application loads but datasets are missing:**
- Ensure datasets are in the correct directory structure
- Check file permissions: `ls -la datasets/`
- Verify `config/datasets_config.json` is properly formatted: `cat config/datasets_config.json | python -m json.tool`

**Performance issues:**
- Increase Docker memory allocation (Docker Desktop > Preferences > Resources)
- Monitor container resources: `docker stats masldatlas`

**Container exits immediately:**
- Check container logs: `docker logs masldatlas-app`
- Run container interactively for debugging: `docker run -it --entrypoint /bin/bash masldatlas-app`

**Missing R packages error (e.g., "there is no package called 'dplyr'"):**
- Rebuild the Docker image: `docker build --no-cache -t masldatlas-app .`
- Ensure all R packages are listed in `config/environment.yml`
- Check if the conda environment is properly activated in the container
- Some packages (like `fenr`, `shinydisconnect`) are only available via CRAN and are installed separately in the Dockerfile

**Package not found during conda build:**
- Check if the package is available via conda: `conda search -c conda-forge -c r r-packagename`
- If not available, add it to the CRAN installation section in the Dockerfile
- Use the `scripts/setup/check_conda_packages.sh` script to verify package availability

**Locale warnings (LC_* settings failed):**
- These warnings are usually harmless but if they cause issues, try:
  ```bash
  docker run -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -p 3838:3838 masldatlas-app
  ```

## License

[Add your license information here]

## Contact

[Add your contact information here]
