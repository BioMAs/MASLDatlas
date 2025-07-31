# Dockerfile for MASLDatlas R Shiny App
FROM continuumio/miniconda3:latest

# Set environment variables
ENV CONDA_ENV=fibrosis_shiny
ENV DEBIAN_FRONTEND=noninteractive

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
        locales \
        && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Copy environment.yml and install conda env
COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml
SHELL ["/bin/bash", "-c"]

# Activate conda env by default
RUN echo "conda activate $CONDA_ENV" >> ~/.bashrc
ENV PATH /opt/conda/envs/$CONDA_ENV/bin:$PATH

# Install R packages not available via conda (if any)
# (Optional: Add install commands here if needed)

# Copy app files
WORKDIR /app
COPY . /app

# Expose Shiny port
EXPOSE 3838

# Run the app
CMD ["R", "-e", "shiny::runApp('/app', host='0.0.0.0', port=3838)"]
