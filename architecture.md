# MASLDatlas Architecture Documentation

## 🏗️ System Architecture Overview

The MASLDatlas application is built as a containerized R Shiny application with a multi-layered architecture designed for scalability, maintainability, and production deployment.

## 📋 Architecture Components

### 1. Application Layer
- **R Shiny Application**: Interactive web interface for scRNA-seq data analysis
- **Reticulate Integration**: Seamless R-Python interoperability
- **Package Management**: Robust handling of R/Python dependencies

### 2. Data Layer
- **H5AD Files**: Single-cell datasets stored in AnnData format
- **JSON Configuration**: Dynamic dataset management through `datasets_config.json`
- **Enrichment Sets**: Pre-computed gene sets for pathway analysis
- **Cache System**: Application-level caching for improved performance

### 3. Container Layer
- **Multi-stage Docker Build**: Optimized container size and build time
- **Conda Environment**: Isolated Python/R environment management
- **Health Checks**: Built-in container health monitoring

### 4. Orchestration Layer (Production)
- **Docker Compose**: Service orchestration and management
- **Traefik Integration**: Reverse proxy and load balancing
- **SSL/TLS Termination**: Automatic HTTPS certificate management

## 🔧 Technical Stack

### Backend Technologies
- **R (4.4.3)**: Primary application runtime
- **Python (3.9+)**: Data analysis libraries
- **Conda**: Package and environment management
- **reticulate**: R-Python bridge

### Key R Packages
```
Core: shiny, bslib, dplyr, ggplot2
UI: shinycssloaders, shinyjs, shinyWidgets
Data: DT, readr, stringr, jsonlite
Analysis: ggpubr, shinyBS
Optional: fenr, shinydisconnect
```

### Key Python Packages
```
Core: scanpy, decoupler, pydeseq2
Graph: python-igraph, leidenalg
Visualization: marsilea
Utilities: omnipath, adjustText, psutil
```

### Infrastructure
- **Docker**: Containerization platform
- **Traefik**: Reverse proxy and load balancer
- **Linux**: Base operating system (Debian)

## 🐳 Container Architecture

### Development Container
```
masldatlas-app:latest
├── Base: continuumio/miniconda3:latest
├── System Dependencies: libcurl4, libssl, locale
├── Conda Environment: fibrosis_shiny
├── R Packages: conda + CRAN installation
├── Python Packages: pip installation
├── Application Code: /app
└── Entry Point: shiny::runApp()
```

### Production Stack
```
Production Environment
├── Traefik (Reverse Proxy)
│   ├── SSL/TLS Termination
│   ├── Load Balancing
│   ├── Route Management
│   └── Health Monitoring
├── MASLDatlas Service
│   ├── Application Container
│   ├── Volume Mounts
│   ├── Health Checks
│   └── Resource Limits
└── Data Volumes
    ├── Datasets
    ├── Cache
    └── Logs
```

## 🌐 Network Architecture

### Development
```
Host (localhost:3838) → Docker Container (3838) → Shiny App
```

### Production with Traefik
```
Internet → Traefik (80/443) → MASLDatlas Container (3838) → Shiny App
                ↓
            SSL Certificate
            Load Balancing
            Health Checks
```

## 📁 Directory Structure

```
MASLDatlas/
├── app.R                          # Main Shiny application
├── dataset_manager.R              # Dataset management utilities
├── datasets_config.json           # Dataset configuration
├── environment.yml                # Conda environment spec
├── Dockerfile                     # Container definition
├── docker-compose.yml             # Development orchestration
├── docker-compose.prod.yml        # Production orchestration
├── install_optional_packages.R    # Package installation script
├── test_packages.R                # Package testing script
├── start.sh / stop.sh / rebuild.sh # Management scripts
├── datasets/                      # Data files
│   ├── Human/
│   ├── Mouse/
│   ├── Zebrafish/
│   └── Integrated/
├── enrichment_sets/               # Gene sets for analysis
├── www/                          # Static web assets
├── app_cache/                    # Application cache
└── docs/
    ├── README.md
    ├── architecture.md
    └── DEPLOYMENT_SUCCESS.md
```

## 🔄 Data Flow

### Application Startup
1. **Container Initialization**: Conda environment activation
2. **Package Loading**: R/Python dependencies validation
3. **Configuration Loading**: Dataset and enrichment sets discovery
4. **Application Launch**: Shiny server startup on port 3838

### User Interaction Flow
1. **Dataset Selection**: User chooses organism and dataset
2. **Data Loading**: H5AD file parsing and validation
3. **Analysis Pipeline**: 
   - UMAP visualization
   - Cluster analysis
   - Differential expression
   - Enrichment analysis
4. **Results Display**: Interactive plots and tables

### Data Processing Pipeline
```
H5AD Files → Scanpy → R (reticulate) → Shiny UI
     ↓
Gene Sets → Decoupler → Analysis → Visualization
     ↓
Cache → Performance Optimization
```

## 🔒 Security Architecture

### Container Security
- **Non-root User**: Application runs with limited privileges
- **Read-only Filesystem**: Immutable container filesystem where possible
- **Resource Limits**: CPU and memory constraints
- **Health Checks**: Automated container health monitoring

### Network Security
- **Traefik Integration**: Centralized SSL/TLS management
- **Internal Networks**: Container-to-container communication
- **Port Isolation**: Only necessary ports exposed

### Data Security
- **Volume Mounts**: Secure data access patterns
- **Environment Variables**: Sensitive configuration management
- **Access Controls**: File permission management

## 📊 Monitoring and Logging

### Application Monitoring
- **Health Endpoints**: Built-in health checks
- **Resource Monitoring**: CPU, memory, disk usage
- **Performance Metrics**: Response times and throughput

### Container Monitoring
- **Docker Stats**: Real-time resource usage
- **Log Aggregation**: Centralized logging
- **Alert System**: Automated failure notifications

### Traefik Monitoring
- **Dashboard**: Web-based monitoring interface
- **Metrics Export**: Prometheus-compatible metrics
- **Access Logs**: Detailed request logging

## 🚀 Deployment Strategies

### Development Deployment
```bash
# Local development
docker-compose up -d

# Direct container run
docker run -p 3838:3838 masldatlas-app
```

### Production Deployment
```bash
# Production with Traefik
docker-compose -f docker-compose.prod.yml up -d

# Health verification
curl -f https://masldatlas.yourdomain.com/health
```

### Scaling Considerations
- **Horizontal Scaling**: Multiple container instances
- **Load Balancing**: Traefik automatic distribution
- **Session Management**: Stateless application design
- **Resource Planning**: Memory-intensive data processing

## 🔧 Maintenance and Updates

### Update Process
1. **Code Updates**: Git pull and rebuild
2. **Dependency Updates**: Environment specification updates
3. **Container Rebuild**: Docker image recreation
4. **Rolling Deployment**: Zero-downtime updates with Traefik

### Backup Strategy
- **Data Volumes**: Regular dataset backups
- **Configuration**: Version-controlled settings
- **Container Images**: Tagged release management

### Performance Optimization
- **Layer Caching**: Docker build optimization
- **Conda Packages**: Faster dependency resolution
- **Application Cache**: R/Python object caching
- **Static Assets**: CDN integration potential

## 🧪 Testing Strategy

### Unit Testing
- **Package Loading**: `test_packages.R`
- **Data Validation**: Dataset integrity checks
- **Function Testing**: Core analysis functions

### Integration Testing
- **Container Health**: Automated health checks
- **End-to-end**: Full application workflow testing
- **Performance**: Load testing and benchmarking

### Production Testing
- **Smoke Tests**: Post-deployment validation
- **Monitoring**: Continuous health monitoring
- **User Acceptance**: Real-world usage validation

---

## 📚 Additional Resources

- [Deployment Guide](DEPLOYMENT_SUCCESS.md)
- [User Manual](README.md)
- [API Documentation](api-docs.md) *(future)*
- [Troubleshooting Guide](README.md#troubleshooting)
