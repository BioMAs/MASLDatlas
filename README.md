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
source("reticulate_create_env.R")
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
./start.sh          # Default port 3838
./start.sh 8080     # Custom port 8080
```

**Stop the application:**
```bash
./stop.sh
```

**Rebuild the Docker image (if packages are missing):**
```bash
./rebuild.sh
```

These scripts will automatically:
- Build the Docker image if needed
- Handle port conflicts
- Mount necessary volumes
- Provide helpful status messages

## Production Deployment

For production environments, consider the following:

### Resource Requirements
- **RAM**: Minimum 4GB, recommended 8GB+
- **CPU**: Multi-core recommended for multiple users
- **Storage**: 10GB+ for application and datasets

### Security Considerations
```bash
# Run container with limited privileges
docker run -p 3838:3838 --user 1000:1000 masldatlas-app

# Use read-only filesystem where possible
docker run -p 3838:3838 --read-only --tmpfs /tmp masldatlas-app
```

### Monitoring
```bash
# Monitor resource usage
docker stats masldatlas

# View application logs
docker logs -f masldatlas

# Health check
curl -f http://localhost:3838 || echo "Application not responding"
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

The application uses a JSON configuration file (`datasets_config.json`) to manage available datasets. This allows adding new datasets without modifying the application code.

### Adding New Datasets

1. **Using the R script (recommended):**
```R
source("dataset_manager.R")

# Add a new dataset
add_dataset("Human", "Individual Dataset", "GSE123456")
add_dataset("Mouse", "Datasets", "GSE789012")

# List all datasets
list_all_datasets()
```

2. **Manual editing of datasets_config.json:**
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
- Verify `datasets_config.json` is properly formatted: `cat datasets_config.json | python -m json.tool`

**Performance issues:**
- Increase Docker memory allocation (Docker Desktop > Preferences > Resources)
- Monitor container resources: `docker stats masldatlas`

**Container exits immediately:**
- Check container logs: `docker logs masldatlas-app`
- Run container interactively for debugging: `docker run -it --entrypoint /bin/bash masldatlas-app`

**Missing R packages error (e.g., "there is no package called 'dplyr'"):**
- Rebuild the Docker image: `docker build --no-cache -t masldatlas-app .`
- Ensure all R packages are listed in `environment.yml`
- Check if the conda environment is properly activated in the container
- Some packages (like `fenr`, `shinydisconnect`) are only available via CRAN and are installed separately in the Dockerfile

**Package not found during conda build:**
- Check if the package is available via conda: `conda search -c conda-forge -c r r-packagename`
- If not available, add it to the CRAN installation section in the Dockerfile
- Use the `check_conda_packages.sh` script to verify package availability

**Locale warnings (LC_* settings failed):**
- These warnings are usually harmless but if they cause issues, try:
  ```bash
  docker run -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -p 3838:3838 masldatlas-app
  ```

## License

[Add your license information here]

## Contact

[Add your contact information here]
