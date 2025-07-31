# Dataset Management Functions for MASLDatlas
# This script provides functions to easily manage datasets configuration

library(jsonlite)

# Function to load the current datasets configuration
load_datasets_config <- function(config_file = "datasets_config.json") {
  if(file.exists(config_file)) {
    return(fromJSON(config_file))
  } else {
    warning("Configuration file not found. Creating new configuration.")
    return(list())
  }
}

# Function to save datasets configuration
save_datasets_config <- function(config, config_file = "datasets_config.json") {
  write_json(config, config_file, pretty = TRUE, auto_unbox = TRUE)
  cat("Configuration saved to", config_file, "\n")
}

# Function to add a new dataset to an existing organism
add_dataset <- function(organism, category, dataset_name, config_file = "datasets_config.json") {
  config <- load_datasets_config(config_file)
  
  # Initialize organism if it doesn't exist
  if(!(organism %in% names(config))) {
    config[[organism]] <- list()
  }
  
  # Initialize category if it doesn't exist
  if(!(category %in% names(config[[organism]]))) {
    config[[organism]][[category]] <- character(0)
  }
  
  # Add dataset if it doesn't already exist
  if(!(dataset_name %in% config[[organism]][[category]])) {
    config[[organism]][[category]] <- c(config[[organism]][[category]], dataset_name)
    save_datasets_config(config, config_file)
    cat("Added dataset '", dataset_name, "' to ", organism, " -> ", category, "\n")
  } else {
    cat("Dataset '", dataset_name, "' already exists in ", organism, " -> ", category, "\n")
  }
  
  return(config)
}

# Function to remove a dataset
remove_dataset <- function(organism, category, dataset_name, config_file = "datasets_config.json") {
  config <- load_datasets_config(config_file)
  
  if(organism %in% names(config) && 
     category %in% names(config[[organism]]) &&
     dataset_name %in% config[[organism]][[category]]) {
    
    config[[organism]][[category]] <- config[[organism]][[category]][
      config[[organism]][[category]] != dataset_name
    ]
    
    # Remove empty categories
    if(length(config[[organism]][[category]]) == 0) {
      config[[organism]][[category]] <- NULL
    }
    
    # Remove empty organisms
    if(length(config[[organism]]) == 0) {
      config[[organism]] <- NULL
    }
    
    save_datasets_config(config, config_file)
    cat("Removed dataset '", dataset_name, "' from ", organism, " -> ", category, "\n")
  } else {
    cat("Dataset '", dataset_name, "' not found in ", organism, " -> ", category, "\n")
  }
  
  return(config)
}

# Function to list all datasets
list_all_datasets <- function(config_file = "datasets_config.json") {
  config <- load_datasets_config(config_file)
  
  if(length(config) == 0) {
    cat("No datasets configured.\n")
    return()
  }
  
  for(organism in names(config)) {
    cat("\n", organism, ":\n")
    for(category in names(config[[organism]])) {
      cat("  ", category, ":\n")
      for(dataset in config[[organism]][[category]]) {
        cat("    -", dataset, "\n")
      }
    }
  }
}

# Example usage:
# Add a new human dataset
# add_dataset("Human", "Individual Dataset", "GSE123456")

# Add a new mouse dataset
# add_dataset("Mouse", "Datasets", "GSE789012")

# Remove a dataset
# remove_dataset("Human", "Individual Dataset", "GSE123456")

# List all datasets
# list_all_datasets()
