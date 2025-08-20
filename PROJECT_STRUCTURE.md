# MASLDatlas Project Structure

This document describes the organized directory structure of the MASLDatlas project, which provides better maintainability and scalability.

## Directory Overview

```
MASLDatlas/
├── app.R                           # Main R Shiny application
├── Dockerfile                      # Container configuration
├── docker-compose.yml             # Development container setup
├── docker-compose.prod.yml        # Production container setup with Traefik
├── README.md                      # Project documentation
├── PROJECT_STRUCTURE.md           # This file
├── architecture.md                # Technical architecture documentation
├── DEPLOYMENT_SUCCESS.md          # Deployment verification guide
│
├── config/                        # 🔧 Configuration Management
│   ├── datasets_config.json       # Application configuration
│   ├── datasets_sources.json      # External dataset sources
│   └── environment.yml            # Conda environment specification
│
├── scripts/                       # 🛠️ Organized Scripts
│   ├── setup/                     # Environment and dependency setup
│   │   ├── reticulate_create_env.R        # Python-R environment bridge
│   │   ├── install_optional_packages.R   # R package installation
│   │   ├── check_dependencies.R          # Dependency verification
│   │   └── check_conda_packages.sh       # Conda package validation
│   │
│   ├── deployment/                # Container and production deployment
│   │   ├── deploy-prod.sh                # Production deployment script
│   │   ├── start.sh                      # Container startup
│   │   ├── stop.sh                       # Container shutdown
│   │   ├── rebuild.sh                    # Container rebuild
│   │   └── startup.sh                    # Application startup (internal)
│   │
│   ├── dataset-management/        # External dataset operations
│   │   ├── download_datasets.py          # Multi-source dataset downloader
│   │   ├── update_dataset_config.py      # Configuration updater
│   │   ├── configure_datasets.sh         # Dataset setup script
│   │   └── dataset_manager.R             # R-based dataset operations
│   │
│   ├── testing/                   # Comprehensive testing suite
│   │   ├── test_datasets.sh              # Interactive test menu
│   │   ├── test_dataset_download.py      # Download validation
│   │   ├── test_complete_download.py     # End-to-end download test
│   │   ├── test_dataset_management.R     # R dataset operations test
│   │   └── test_packages.R               # Package installation test
│   │
│   ├── migrate-project.sh         # Migration from flat to organized structure
│   └── rollback-project.sh        # Rollback to flat structure
│
├── docs/                          # 📚 Documentation
│   ├── dataset-deployment-guide.md       # Dataset deployment procedures
│   ├── dataset-management.md             # Dataset management guide
│   ├── dataset-testing-guide.md          # Testing procedures
│   └── migration-guide.md                # Structure migration guide
│
├── datasets/                      # 📊 Dataset Storage (Git LFS)
│   ├── Human/                     # Human scRNA-seq data
│   ├── Mouse/                     # Mouse scRNA-seq data
│   ├── Zebrafish/                 # Zebrafish scRNA-seq data
│   └── Integrated/                # Cross-species integrated data
│
├── enrichment_sets/              # 🧬 Pathway Analysis Data
│   ├── collectri.rds             # TF-target interactions
│   ├── progeny.rds               # Pathway activity scores
│   ├── msigdb.rds                # MSigDB gene sets
│   └── *.RData                   # Species-specific gene sets
│
├── tmp/                          # 🗂️ Temporary Files
│   └── *.rds, *.tmp             # Cached data and temporary outputs
│
└── www/                          # 🌐 Web Assets
    └── tabicon.PNG               # Application favicon
```

## Key Improvements

### 🎯 **Organized by Purpose**
- **config/**: All configuration files in one place
- **scripts/**: Categorized by functionality (setup, deployment, testing, etc.)
- **docs/**: Comprehensive documentation
- **tmp/**: Temporary files isolated from source code

### 🔄 **Easy Migration**
- **Forward Migration**: `./scripts/migrate-project.sh`
- **Rollback**: `./scripts/rollback-project.sh` 
- **Dry Run**: Add `--dry-run` flag to see changes without applying

### 🧪 **Comprehensive Testing**
- **Interactive Menu**: `./scripts/testing/test_datasets.sh`
- **Specific Tests**: Individual test scripts for different components
- **Validation**: Automated testing for downloads, packages, and configuration

### 🚀 **Streamlined Deployment**
- **Development**: `./scripts/deployment/start.sh`
- **Production**: `./scripts/deployment/deploy-prod.sh domain.com`
- **Management**: Separate scripts for stop, rebuild, startup

## Command Updates

### Before (Flat Structure)
```bash
# Development
python3 test_dataset_download.py
./deploy-prod.sh domain.com
Rscript install_optional_packages.R

# Testing
./test_datasets.sh
python3 test_complete_download.py
```

### After (Organized Structure)
```bash
# Development  
python3 scripts/testing/test_dataset_download.py
./scripts/deployment/deploy-prod.sh domain.com
Rscript scripts/setup/install_optional_packages.R

# Testing
./scripts/testing/test_datasets.sh
python3 scripts/testing/test_complete_download.py
```

## Migration Guide

### Automatic Migration
```bash
# Migrate to organized structure
./scripts/migrate-project.sh

# View changes without applying
./scripts/migrate-project.sh --dry-run

# Rollback if needed
./scripts/rollback-project.sh
```

### Manual Updates Needed
If you have custom scripts or CI/CD pipelines, update paths:

1. **Configuration Files**: `datasets_sources.json` → `config/datasets_sources.json`
2. **Setup Scripts**: `install_optional_packages.R` → `scripts/setup/install_optional_packages.R`
3. **Deployment**: `deploy-prod.sh` → `scripts/deployment/deploy-prod.sh`
4. **Testing**: `test_*.py` → `scripts/testing/test_*.py`

## Benefits

### 👥 **Team Collaboration**
- Clear separation of concerns
- Easy to find relevant scripts
- Standardized project structure

### 📈 **Scalability**
- Room for growth in each category
- No more cluttered root directory
- Professional project organization

### 🔧 **Maintainability**
- Related files grouped together
- Easier debugging and updates
- Clear dependency relationships

### 🚀 **Production Ready**
- Industry-standard structure
- Docker and CI/CD friendly
- Easy onboarding for new team members

## Getting Started

### New Installation
```bash
git clone <repository>
cd MASLDatlas

# Install dependencies
./scripts/setup/check_conda_packages.sh
Rscript scripts/setup/install_optional_packages.R

# Test setup
./scripts/testing/test_datasets.sh

# Start development
./scripts/deployment/start.sh
```

### Existing Installation
```bash
# Migrate to new structure
./scripts/migrate-project.sh

# Verify migration
./scripts/testing/test_datasets.sh info

# Update your bookmarks and scripts
```

## Support

- **Migration Issues**: See `docs/migration-guide.md`
- **Testing Problems**: See `docs/dataset-testing-guide.md`
- **Deployment Help**: See `docs/dataset-deployment-guide.md`
- **Architecture**: See `architecture.md`

---

*This structure follows industry best practices for R Shiny applications and provides a solid foundation for continued development and collaboration.*

## Directory Purpose

### `/config/`
Configuration files for the application and deployment:
- **datasets_config.json**: Defines which datasets are available in the UI
- **datasets_sources.json**: External download sources for large datasets
- **environment.yml**: Conda environment specification with all dependencies

### `/scripts/`
All executable scripts organized by purpose:

#### `/scripts/setup/`
Environment and dependency setup:
- Initial R/Python environment configuration
- Package installation and verification
- Dependency checking

#### `/scripts/deployment/`
Container and deployment management:
- Production deployment automation
- Local development container management
- Docker image building and lifecycle

#### `/scripts/dataset-management/`
Dataset download and configuration:
- External dataset download from Zenodo/GitHub/S3
- Configuration generation and updates
- R-based dataset management functions

#### `/scripts/testing/`
Testing and validation:
- Complete test suite with interactive menu
- Dataset connectivity and download testing
- Package and dependency validation

### `/docs/`
Project documentation:
- System architecture and design decisions
- Deployment and testing guides
- Dataset management procedures

### Application Directories
- `/datasets/`: Runtime datasets (downloaded automatically)
- `/enrichment_sets/`: Gene enrichment analysis data
- `/www/`: Static web assets
- `/app_cache/`: Application runtime cache

## Usage Patterns

### Development Workflow
```bash
# Setup environment
./scripts/setup/reticulate_create_env.R

# Test system
./scripts/testing/test_datasets.sh production

# Start development
./scripts/deployment/start.sh
```

### Production Deployment
```bash
# Deploy to production
./scripts/deployment/deploy-prod.sh your-domain.com

# Monitor deployment
docker-compose -f docker-compose.prod.yml logs -f
```

### Dataset Management
```bash
# Configure datasets
./scripts/dataset-management/configure_datasets.sh setup-zenodo

# Test downloads
./scripts/testing/test_dataset_download.py

# Download manually
./scripts/dataset-management/download_datasets.py download
```
