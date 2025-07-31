# Datasets Directory Structure

This directory contains the H5AD files for all organisms and datasets used in the MASLDatlas application.

## Directory Structure

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

## Adding New Datasets

1. **Place the H5AD file** in the appropriate organism directory
2. **Update the configuration** using the dataset manager:
   ```R
   source("../dataset_manager.R")
   add_dataset("Human", "Individual Dataset", "GSE123456")
   ```
3. **Restart the Shiny application** to see the new dataset

## File Naming Convention

- Files should be named exactly as they appear in the `datasets_config.json` file
- Use `.h5ad` extension for all single-cell data files
- Avoid spaces and special characters in filenames when possible

## File Requirements

Each H5AD file should contain:
- Expression data in `adata.X`
- Cell metadata in `adata.obs` including:
  - `CellType`: Cell type annotations
  - `Group`: Experimental groups (if applicable)
- Gene metadata in `adata.var`
- UMAP coordinates (if available)

## Data Processing

All datasets should be preprocessed and normalized before being added to this directory. The application expects:
- Normalized expression data
- Cell type annotations
- UMAP embeddings for visualization
