# Dockerfile for MASLDatlas R Shiny App
FROM continuumio/miniconda3:latest

# Set environment variables
ENV CONDA_ENV=fibrosis_shiny
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libgit2-dev \
        libglpk-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev \
        libxt-dev \
        pandoc \
        wget \
        curl \
        locales \
        && rm -rf /var/lib/apt/lists/*

# Set locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Copy environment.yml and install conda env
COPY config/environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml && \
    conda clean -afy

# Activate conda env by default
SHELL ["conda", "run", "-n", "fibrosis_shiny", "/bin/bash", "-c"]
ENV PATH=/opt/conda/envs/$CONDA_ENV/bin:$PATH

# Copy and run script to install optional R packages
COPY scripts/setup/install_optional_packages.R /tmp/install_optional_packages.R
RUN conda run -n $CONDA_ENV Rscript /tmp/install_optional_packages.R || echo "Optional packages installation completed with warnings"

# 🚀 PERFORMANCE OPTIMIZATION: Copy optimization modules early for better build caching
COPY R/ /app/R/
COPY scripts/setup/performance_robustness_setup.R /app/scripts/setup/performance_robustness_setup.R

# 🚀 PERFORMANCE: Pre-test optimization system during build
RUN conda run -n $CONDA_ENV Rscript -e \
  "setwd('/app'); tryCatch({ source('scripts/setup/performance_robustness_setup.R'); cat('✅ Optimization system validated in Docker\n') }, error = function(e) { cat('⚠️ Optimization system will be loaded at runtime\n') })" \
  || echo "Optimization pre-test completed"

# Copy dataset management files (for runtime use, not build time)
COPY scripts/dataset-management/download_datasets.py /app/scripts/dataset-management/download_datasets.py
COPY config/datasets_sources.json /app/config/datasets_sources.json

# Install Python dependencies for dataset downloader (datasets will be downloaded at runtime)
RUN conda run -n $CONDA_ENV pip install requests

# Copy app files
WORKDIR /app
COPY . /app

# Create datasets directory for volume mount
RUN mkdir -p /app/datasets

# Make startup script executable
RUN chmod +x /app/scripts/deployment/startup.sh

# Expose Shiny port
EXPOSE 3838

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3838 || exit 1

# Use startup script that handles dataset download and app startup
CMD ["conda", "run", "-n", "fibrosis_shiny", "/app/scripts/deployment/startup.sh"]
