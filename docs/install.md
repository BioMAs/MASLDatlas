# Installation Guide

## Prerequisites

- **Docker Desktop**: Version 20.10 or higher.
- **System Resources**:
  - Minimum: 4GB RAM, 2 CPU cores.
  - Recommended: 8GB RAM, 4 CPU cores.
- **Disk Space**: At least 15GB of free space (for Docker images and datasets).

## Quick Start

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/BioMAs/MASLDatlas.git
    cd MASLDatlas
    ```

2.  **Run the setup script**:
    ```bash
    ./setup.sh
    ```

3.  **Start the application**:
    ```bash
    docker-compose up -d
    ```

4.  **Access the application**:
    Open your web browser and navigate to [http://localhost:3838](http://localhost:3838).

    *Note: The first startup may take several minutes as it downloads the necessary datasets.*

## Manual Installation

If you prefer not to use the setup script, you can manually prepare the environment:

1.  Create the required directories:
    ```bash
    mkdir -p datasets cache config enrichment_sets
    ```

2.  Start the application with Docker Compose:
    ```bash
    docker-compose up -d
    ```

## Troubleshooting

-   **Port Conflicts**: If port 3838 is already in use, modify the `docker-compose.yml` file to map a different port (e.g., `"8080:3838"`).
-   **Memory Issues**: If the application crashes during large dataset analysis, increase the memory allocated to Docker Desktop.
