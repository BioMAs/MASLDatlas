# Multi-species scRNA-seq Atlas of MASLD

Interactive single-cell RNA sequencing analysis platform for exploring MASLD (Metabolic Associated Steatotic Liver Disease) across Human, Mouse, and Zebrafish models.

## Features

-   **Multi-species Analysis**: Human, Mouse, and Zebrafish datasets.
-   **Interactive Visualization**: UMAP, heatmaps, and violin plots.
-   **Advanced Analysis**: Differential expression, gene set enrichment, and pathway activity scoring.
-   **Performance**: Optimized for efficient data handling and visualization.

## Quick Start

### Prerequisites

-   Docker Desktop installed.
-   Git installed.

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/BioMAs/MASLDatlas.git
    cd MASLDatlas
    ```

2.  Run the setup script:
    ```bash
    ./setup.sh
    ```

3.  Start the application:
    ```bash
    docker-compose up -d
    ```

4.  Access the application at [http://localhost:3838](http://localhost:3838).

## Adding Custom Datasets

To add your own datasets to the atlas:

1.  **Prepare your data**: Ensure your single-cell data is in `.h5ad` (AnnData) format.
2.  **Place the file**: Copy your `.h5ad` file into the appropriate species folder under `datasets/` (e.g., `datasets/Human/`).
3.  **Update Configuration**: Edit `config/datasets_config.json` to include your dataset name in the `Datasets` list for the corresponding species.
    ```json
    "Human": {
      "Datasets": [
        "GSE181483",
        "YourNewDatasetName" 
      ],
      ...
    }
    ```
4.  **Restart**: Restart the application to load the new configuration.
    ```bash
    docker-compose restart
    ```

## Documentation

-   [Installation Guide](docs/INSTALL.md)
-   [User Guide](docs/USER_GUIDE.md)
-   [Architecture](architecture.md)

## License

This project is licensed under the MIT License.
