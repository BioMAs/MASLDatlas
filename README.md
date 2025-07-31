# Multi-species scRNA-seq Atlas of MASLD

This Shiny application provides an interactive interface for exploring and analyzing single-cell RNA sequencing data across multiple species (Human, Mouse, and Zebrafish) in the context of MASLD (Metabolic Associated Steatotic Liver Disease).

## Prerequisites

Before running the application, ensure you have the following installed:
- R (version 4.0 or higher)
- Python 3.9
- Required R packages:
  - shiny
  - reticulate
  - shinycssloaders
  - bslib
  - DT

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

To launch the application, run:
```R
shiny::runApp()
```

The application will be available in your default web browser.

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
- `enrichment_sets/`: Contains RDS and RData files for different species and analysis types
- `www/`: Contains static assets
- `app_cache/`: Contains cached data for improved performance

## Troubleshooting

If you encounter any issues:
1. Ensure all required packages are properly installed
2. Check Python virtual environment is correctly set up
3. Verify data files are present in the correct locations
4. Clear browser cache if the interface is not loading properly

## License

[Add your license information here]

## Contact

[Add your contact information here]
