#!/usr/bin/env Rscript
#
# Large Dataset Optimization Script for MASLDatlas
# Optimizes large datasets for better Shiny performance
#

library(reticulate)
library(jsonlite)

# Function to check and setup Python environment
setup_python_env <- function() {
  tryCatch({
    # Try to use conda environment
    if (Sys.getenv("CONDA_DEFAULT_ENV") != "") {
      use_condaenv("fibrosis_shiny", required = TRUE)
    } else {
      use_virtualenv("fibrosis_shiny")
    }
    
    # Import Python modules
    sc <<- import("scanpy")
    np <<- import("numpy")
    cat("✅ Python environment setup successful\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ Python environment setup failed:", e$message, "\n")
    return(FALSE)
  })
}

# Function to create subsampled version
create_subsampled_dataset <- function(input_file, output_file, n_cells = 10000) {
  cat("🎲 Creating subsampled dataset with", n_cells, "cells...\n")
  
  # Load dataset
  cat("📥 Loading dataset:", input_file, "\n")
  adata <- sc$read_h5ad(input_file)
  
  cat("📊 Original shape:", adata$n_obs, "cells ×", adata$n_vars, "genes\n")
  
  # Check if we need to subsample
  if (adata$n_obs <= n_cells) {
    cat("⚠️ Dataset already has", adata$n_obs, "cells, no subsampling needed\n")
    return(input_file)
  }
  
  # Set random seed for reproducibility
  np$random$seed(42L)
  
  # Random sampling
  sample_indices <- np$random$choice(adata$n_obs, size = as.integer(n_cells), replace = FALSE)
  adata_sub <- adata[sample_indices]$copy()
  
  # Save subsampled dataset
  adata_sub$write(output_file, compression = "gzip")
  
  cat("✅ Subsampled dataset saved:", output_file, "\n")
  cat("📊 New shape:", adata_sub$n_obs, "cells ×", adata_sub$n_vars, "genes\n")
  
  # Calculate size reduction
  if (file.exists(input_file) && file.exists(output_file)) {
    original_size <- file.info(input_file)$size
    new_size <- file.info(output_file)$size
    reduction_factor <- original_size / new_size
    cat("📉 Size reduction:", round(reduction_factor, 1), "x smaller\n")
  }
  
  return(output_file)
}

# Function to create metadata-only version
create_metadata_only <- function(input_file, output_file) {
  cat("🗂️ Creating metadata-only version...\n")
  
  # Load dataset
  adata <- sc$read_h5ad(input_file)
  
  # Remove expression data but keep metadata and embeddings
  adata$X <- NULL
  adata$raw <- NULL
  
  # Save metadata-only version
  adata$write(output_file, compression = "gzip")
  
  cat("✅ Metadata-only version saved:", output_file, "\n")
  
  return(output_file)
}

# Function to optimize dataset for Shiny
optimize_for_shiny <- function(input_file, output_file) {
  cat("⚡ Creating Shiny-optimized version...\n")
  
  # Load dataset
  adata <- sc$read_h5ad(input_file)
  
  # Keep only highly variable genes if available
  if ("highly_variable" %in% colnames(adata$var)) {
    cat("🧬 Filtering to highly variable genes...\n")
    adata <- adata[, adata$var$highly_variable]$copy()
  } else {
    cat("🧬 Computing highly variable genes...\n")
    sc$pp$highly_variable_genes(adata, min_mean = 0.0125, max_mean = 3, min_disp = 0.5)
    adata <- adata[, adata$var$highly_variable]$copy()
  }
  
  # Ensure essential embeddings are computed
  if (!"X_umap" %in% names(adata$obsm)) {
    cat("🗺️ Computing UMAP embedding...\n")
    sc$pp$neighbors(adata)
    sc$tl$umap(adata)
  }
  
  if (!"X_pca" %in% names(adata$obsm)) {
    cat("📊 Computing PCA...\n")
    sc$tl$pca(adata)
  }
  
  # Pre-compute clustering if not available
  if (!"leiden" %in% colnames(adata$obs)) {
    cat("🔗 Computing Leiden clustering...\n")
    sc$tl$leiden(adata, resolution = 0.5)
  }
  
  # Save optimized dataset
  adata$write(output_file, compression = "gzip")
  
  cat("✅ Shiny-optimized version saved:", output_file, "\n")
  cat("📊 Optimized shape:", adata$n_obs, "cells ×", adata$n_vars, "genes\n")
  
  return(output_file)
}

# Main optimization function
optimize_large_dataset <- function(dataset_path, strategies = c("sub5k", "sub10k", "shiny_opt")) {
  cat("🚀 Starting dataset optimization for:", dataset_path, "\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  if (!setup_python_env()) {
    stop("Cannot proceed without Python environment")
  }
  
  if (!file.exists(dataset_path)) {
    stop("Dataset file not found:", dataset_path)
  }
  
  # Create output directory
  output_dir <- "datasets_optimized"
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Get base filename without extension
  base_name <- tools::file_path_sans_ext(basename(dataset_path))
  
  results <- list()
  
  # Create different optimized versions
  for (strategy in strategies) {
    tryCatch({
      if (strategy == "sub5k") {
        output_file <- file.path(output_dir, paste0(base_name, "_sub5k.h5ad"))
        results[[strategy]] <- create_subsampled_dataset(dataset_path, output_file, 5000)
        
      } else if (strategy == "sub10k") {
        output_file <- file.path(output_dir, paste0(base_name, "_sub10k.h5ad"))
        results[[strategy]] <- create_subsampled_dataset(dataset_path, output_file, 10000)
        
      } else if (strategy == "sub20k") {
        output_file <- file.path(output_dir, paste0(base_name, "_sub20k.h5ad"))
        results[[strategy]] <- create_subsampled_dataset(dataset_path, output_file, 20000)
        
      } else if (strategy == "metadata") {
        output_file <- file.path(output_dir, paste0(base_name, "_metadata.h5ad"))
        results[[strategy]] <- create_metadata_only(dataset_path, output_file)
        
      } else if (strategy == "shiny_opt") {
        output_file <- file.path(output_dir, paste0(base_name, "_shiny_optimized.h5ad"))
        results[[strategy]] <- optimize_for_shiny(dataset_path, output_file)
      }
      
    }, error = function(e) {
      cat("❌", strategy, "optimization failed:", e$message, "\n")
    })
  }
  
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("✅ Dataset optimization complete!\n")
  cat("📁 Output directory:", output_dir, "\n")
  
  return(results)
}

# Command line interface
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  cat("Usage: Rscript optimize_large_dataset.R <dataset_path> [strategies]\n")
  cat("Strategies: sub5k, sub10k, sub20k, metadata, shiny_opt\n")
  cat("Example: Rscript optimize_large_dataset.R datasets/Integrated/Fibrotic\\ Integrated\\ Cross\\ Species-002.h5ad sub5k,sub10k,shiny_opt\n")
  quit(status = 1)
}

dataset_path <- args[1]
strategies <- if (length(args) > 1) {
  strsplit(args[2], ",")[[1]]
} else {
  c("sub5k", "sub10k", "shiny_opt")
}

# Run optimization
optimize_large_dataset(dataset_path, strategies)
