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
COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml && \
    conda clean -afy

# Activate conda env by default
SHELL ["conda", "run", "-n", "fibrosis_shiny", "/bin/bash", "-c"]
ENV PATH=/opt/conda/envs/$CONDA_ENV/bin:$PATH

# Copy and run script to install optional R packages
COPY install_optional_packages.R /tmp/install_optional_packages.R
RUN conda run -n $CONDA_ENV Rscript /tmp/install_optional_packages.R || echo "Optional packages installation completed with warnings"

# Copy app files
WORKDIR /app
COPY . /app

# Expose Shiny port
EXPOSE 3838

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3838 || exit 1

# Run the app using conda run to ensure proper environment
CMD ["conda", "run", "-n", "fibrosis_shiny", "R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=3838)"]
