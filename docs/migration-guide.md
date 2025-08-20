# Project Migration Guide

## Overview

The MASLDatlas project has been restructured for better organization and maintainability. This guide will help you migrate from the old structure to the new one.

## What Changed

### Old Structure
```
MASLDatlas/
├── app.R
├── datasets_sources.json
├── test_dataset_download.py
├── download_datasets.py
├── startup.sh
├── deploy-prod.sh
└── ...
```

### New Structure
```
MASLDatlas/
├── app.R
├── config/
│   ├── datasets_sources.json
│   └── environment.yml
├── scripts/
│   ├── setup/
│   ├── deployment/
│   ├── dataset-management/
│   └── testing/
└── ...
```

## Migration Steps

### 1. Automatic Migration (Recommended)

If you have an existing project, you can migrate automatically:

```bash
# Run the migration script
./scripts/migrate-project.sh
```

### 2. Manual Migration

If you prefer to migrate manually:

1. **Move configuration files:**
   ```bash
   mkdir -p config
   mv datasets_sources.json config/ 2>/dev/null || true
   mv datasets_config.json config/ 2>/dev/null || true
   mv environment.yml config/ 2>/dev/null || true
   ```

2. **Create script directories:**
   ```bash
   mkdir -p scripts/{setup,deployment,dataset-management,testing}
   ```

3. **Move scripts to appropriate directories:**
   ```bash
   # Setup scripts
   mv reticulate_create_env.R scripts/setup/ 2>/dev/null || true
   mv install_optional_packages.R scripts/setup/ 2>/dev/null || true
   mv check_dependencies.R scripts/setup/ 2>/dev/null || true
   mv check_conda_packages.sh scripts/setup/ 2>/dev/null || true

   # Deployment scripts
   mv deploy-prod.sh scripts/deployment/ 2>/dev/null || true
   mv start.sh scripts/deployment/ 2>/dev/null || true
   mv stop.sh scripts/deployment/ 2>/dev/null || true
   mv rebuild.sh scripts/deployment/ 2>/dev/null || true
   mv startup.sh scripts/deployment/ 2>/dev/null || true

   # Dataset management scripts
   mv download_datasets.py scripts/dataset-management/ 2>/dev/null || true
   mv update_dataset_config.py scripts/dataset-management/ 2>/dev/null || true
   mv configure_datasets.sh scripts/dataset-management/ 2>/dev/null || true
   mv dataset_manager.R scripts/dataset-management/ 2>/dev/null || true

   # Testing scripts
   mv test_*.py scripts/testing/ 2>/dev/null || true
   mv test_*.R scripts/testing/ 2>/dev/null || true
   mv test_*.sh scripts/testing/ 2>/dev/null || true
   ```

4. **Clean up temporary files:**
   ```bash
   mkdir -p tmp
   mv *.rds tmp/ 2>/dev/null || true
   mv *.tmp tmp/ 2>/dev/null || true
   ```

### 3. Update Your Commands

After migration, update your command usage:

#### Old Commands → New Commands

**Testing:**
```bash
# Old
python3 test_dataset_download.py

# New
python3 scripts/testing/test_dataset_download.py
# OR use the test suite
./scripts/testing/test_datasets.sh
```

**Dataset Management:**
```bash
# Old
python3 download_datasets.py download

# New
python3 scripts/dataset-management/download_datasets.py download
```

**Deployment:**
```bash
# Old
./deploy-prod.sh your-domain.com

# New
./scripts/deployment/deploy-prod.sh your-domain.com
```

**Setup:**
```bash
# Old
source("reticulate_create_env.R")

# New
source("scripts/setup/reticulate_create_env.R")
```

### 4. Update Docker and CI/CD

The Dockerfile and GitHub Actions workflows have been automatically updated to use the new structure. No manual changes needed.

### 5. Update Custom Scripts

If you have custom scripts that reference the old paths, update them:

```bash
# Find and update references
grep -r "datasets_sources.json" . --exclude-dir=.git
# Replace with: config/datasets_sources.json

grep -r "download_datasets.py" . --exclude-dir=.git
# Replace with: scripts/dataset-management/download_datasets.py
```

## Benefits of New Structure

1. **Better Organization:** Related scripts are grouped together
2. **Easier Navigation:** Clear separation of concerns
3. **Scalability:** Easy to add new scripts and features
4. **Professional Structure:** Follows industry best practices
5. **Improved Testing:** Comprehensive test suite with interactive menu

## Verification

After migration, verify everything works:

```bash
# Test the new structure
./scripts/testing/test_datasets.sh production

# Build Docker image
docker build -t masldatlas-test .

# Test deployment scripts
./scripts/deployment/start.sh --test
```

## Rollback

If you need to rollback to the old structure:

```bash
# This will move files back to root directory
./scripts/rollback-migration.sh
```

⚠️ **Note:** Rollback will only work if you haven't deleted the migration backup files.

## Getting Help

If you encounter issues during migration:

1. Check the [troubleshooting guide](docs/troubleshooting.md)
2. Run the test suite: `./scripts/testing/test_datasets.sh`
3. Review the [project structure documentation](PROJECT_STRUCTURE.md)
4. Open an issue on GitHub

## Migration Checklist

- [ ] Backup your current project
- [ ] Run migration script or move files manually
- [ ] Update any custom scripts or documentation
- [ ] Test the new structure
- [ ] Update deployment procedures
- [ ] Train team members on new command structure
- [ ] Update CI/CD pipelines (if using custom ones)
