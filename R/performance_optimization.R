# Performance Optimization Module
# Optimizations for MASLDatlas application performance and robustness

#' Dataset Caching System
#' Implements memory-efficient caching for loaded datasets
dataset_cache <- new.env(parent = emptyenv())

#' Cache dataset with memory management
#' @param key Cache key (organism + dataset name)
#' @param data Dataset to cache
#' @param max_cache_size Maximum cache size in GB
cache_dataset <- function(key, data, max_cache_size = 4) {
  # Check current cache size
  current_size <- sum(sapply(ls(dataset_cache), function(x) {
    tryCatch({
      object.size(get(x, envir = dataset_cache)) / 1024^3  # Convert to GB
    }, error = function(e) 0)
  }))
  
  # Clear cache if too large
  if (current_size > max_cache_size) {
    clear_old_cache_entries()
  }
  
  # Add timestamp for LRU eviction
  data_with_meta <- list(
    data = data,
    timestamp = Sys.time(),
    size_gb = object.size(data) / 1024^3
  )
  
  assign(key, data_with_meta, envir = dataset_cache)
  
  cat(sprintf("✅ Dataset cached: %s (%.2f GB)\n", key, data_with_meta$size_gb))
}

#' Get dataset from cache
#' @param key Cache key
get_cached_dataset <- function(key) {
  if (exists(key, envir = dataset_cache)) {
    cached_item <- get(key, envir = dataset_cache)
    # Update timestamp for LRU
    cached_item$timestamp <- Sys.time()
    assign(key, cached_item, envir = dataset_cache)
    return(cached_item$data)
  }
  return(NULL)
}

#' Clear old cache entries (LRU eviction)
clear_old_cache_entries <- function() {
  cache_items <- ls(dataset_cache)
  if (length(cache_items) > 0) {
    # Get timestamps
    timestamps <- sapply(cache_items, function(x) {
      get(x, envir = dataset_cache)$timestamp
    })
    
    # Remove oldest 50% of items
    oldest_items <- names(sort(timestamps))[1:max(1, length(timestamps) %/% 2)]
    for (item in oldest_items) {
      rm(list = item, envir = dataset_cache)
    }
    
    cat(sprintf("🧹 Cleared %d old cache entries\n", length(oldest_items)))
  }
}

#' Memory-efficient data loading with progress
#' @param file_path Path to dataset file
#' @param progress_callback Function to update progress
#' @param chunk_processing Whether to process in chunks
load_dataset_optimized <- function(file_path, progress_callback = NULL, chunk_processing = FALSE) {
  file_size_mb <- file.size(file_path) / 1024^2
  
  if (!is.null(progress_callback)) {
    progress_callback(0.1, detail = "Checking file...")
  }
  
  # For large files, recommend subset usage
  if (file_size_mb > 1000 && !chunk_processing) {  # > 1GB
    warning(sprintf("Large file detected (%.1f MB). Consider using optimized subsets.", file_size_mb))
  }
  
  if (!is.null(progress_callback)) {
    progress_callback(0.3, detail = "Loading data...")
  }
  
  # Use efficient loading based on file size
  tryCatch({
    if (chunk_processing && file_size_mb > 2000) {
      # For very large files, implement streaming
      data <- load_in_chunks(file_path, progress_callback)
    } else {
      # Standard loading with monitoring
      data <- sc$read_h5ad(file_path)
    }
    
    if (!is.null(progress_callback)) {
      progress_callback(0.9, detail = "Finalizing...")
    }
    
    return(data)
    
  }, error = function(e) {
    if (!is.null(progress_callback)) {
      progress_callback(1, detail = "Error occurred")
    }
    stop(sprintf("Failed to load dataset: %s", e$message))
  })
}

#' Optimized correlation analysis with limitations
#' @param data Expression matrix
#' @param target_gene Target gene for correlation
#' @param method Correlation method
#' @param max_genes Maximum number of genes to analyze
#' @param progress_callback Progress update function
calculate_correlations_optimized <- function(data, target_gene, method = "spearman", 
                                           max_genes = 1000, progress_callback = NULL) {
  
  if (!is.null(progress_callback)) {
    progress_callback(0.1, detail = "Preparing data...")
  }
  
  # Limit to most variable genes for performance
  if (ncol(data) > max_genes) {
    if (!is.null(progress_callback)) {
      progress_callback(0.3, detail = "Selecting variable genes...")
    }
    
    gene_vars <- apply(data, 2, var, na.rm = TRUE)
    top_genes <- names(sort(gene_vars, decreasing = TRUE)[1:max_genes])
    data <- data[, top_genes, drop = FALSE]
    
    cat(sprintf("📊 Limited analysis to %d most variable genes for performance\n", max_genes))
  }
  
  if (!is.null(progress_callback)) {
    progress_callback(0.5, detail = "Calculating correlations...")
  }
  
  target_values <- data[, target_gene]
  
  # Vectorized correlation calculation
  correlations <- sapply(colnames(data), function(gene) {
    if (method == "spearman") {
      cor(target_values, data[, gene], method = "spearman", use = "complete.obs")
    } else {
      cor(target_values, data[, gene], method = "pearson", use = "complete.obs")
    }
  })
  
  # Calculate p-values efficiently
  if (!is.null(progress_callback)) {
    progress_callback(0.8, detail = "Calculating p-values...")
  }
  
  n <- nrow(data)
  t_stats <- correlations * sqrt((n - 2) / (1 - correlations^2))
  p_values <- 2 * pt(abs(t_stats), df = n - 2, lower.tail = FALSE)
  
  # Create result dataframe
  result_df <- data.frame(
    Gene = names(correlations),
    Correlation = correlations,
    p_value = p_values,
    stringsAsFactors = FALSE
  )
  
  # Bonferroni correction
  result_df$Bonferroni_p_value <- pmin(1, result_df$p_value * nrow(result_df))
  
  # Sort by absolute correlation
  result_df <- result_df[order(abs(result_df$Correlation), decreasing = TRUE), ]
  
  if (!is.null(progress_callback)) {
    progress_callback(1, detail = "Complete!")
  }
  
  return(result_df)
}

#' Memory monitoring and cleanup
#' @param threshold_gb Memory threshold in GB
monitor_memory_usage <- function(threshold_gb = 8) {
  if (require(pryr, quietly = TRUE)) {
    current_usage <- pryr::mem_used() / 1024^3  # Convert to GB
    
    if (current_usage > threshold_gb) {
      # Force garbage collection
      for (i in 1:3) gc(verbose = FALSE)
      
      # Clear temporary files
      temp_files <- list.files(pattern = "^figures/", full.names = TRUE)
      old_files <- temp_files[file.mtime(temp_files) < Sys.time() - 3600]  # Older than 1 hour
      if (length(old_files) > 0) {
        file.remove(old_files)
        cat(sprintf("🧹 Cleaned %d temporary files\n", length(old_files)))
      }
      
      new_usage <- pryr::mem_used() / 1024^3
      cat(sprintf("💾 Memory: %.2f GB -> %.2f GB (freed %.2f GB)\n", 
                  current_usage, new_usage, current_usage - new_usage))
    }
  }
}

#' Optimized image generation with caching
#' @param plot_function Function to generate plot
#' @param cache_key Unique identifier for caching
#' @param file_name Output file name
#' @param force_regenerate Force regeneration of cached plot
generate_plot_cached <- function(plot_function, cache_key, file_name, force_regenerate = FALSE) {
  cache_file <- paste0("figures/cache_", cache_key, ".png")
  
  # Check if cached version exists and is recent
  if (!force_regenerate && file.exists(cache_file)) {
    cache_age <- difftime(Sys.time(), file.mtime(cache_file), units = "hours")
    if (cache_age < 24) {  # Use cache if less than 24 hours old
      file.copy(cache_file, paste0("figures/", file_name), overwrite = TRUE)
      cat(sprintf("📊 Using cached plot: %s\n", cache_key))
      return(paste0("figures/", file_name))
    }
  }
  
  # Generate new plot
  result <- plot_function()
  
  # Cache the result
  if (file.exists(paste0("figures/", file_name))) {
    file.copy(paste0("figures/", file_name), cache_file, overwrite = TRUE)
  }
  
  return(result)
}

#' Database connection pooling for better performance
#' @param max_connections Maximum number of connections
create_connection_pool <- function(max_connections = 5) {
  # This would be implemented if using external databases
  # For now, it's a placeholder for future database integration
  list(
    max_connections = max_connections,
    active_connections = 0
  )
}

#' Async data processing wrapper
#' @param processing_function Function to run
#' @param callback Callback when complete
#' @param error_callback Error handling callback
run_async_processing <- function(processing_function, callback = NULL, error_callback = NULL) {
  # Note: True async in Shiny requires packages like future/promises
  # This is a simplified version
  
  tryCatch({
    result <- processing_function()
    if (!is.null(callback)) {
      callback(result)
    }
    return(result)
  }, error = function(e) {
    if (!is.null(error_callback)) {
      error_callback(e)
    } else {
      cat(sprintf("❌ Async processing error: %s\n", e$message))
    }
  })
}

#' Performance profiling helper
#' @param expression Expression to profile
#' @param label Label for the profiling
profile_performance <- function(expression, label = "Operation") {
  start_time <- Sys.time()
  start_memory <- if (require(pryr, quietly = TRUE)) pryr::mem_used() else 0
  
  result <- expression
  
  end_time <- Sys.time()
  end_memory <- if (require(pryr, quietly = TRUE)) pryr::mem_used() else 0
  
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  memory_diff <- (end_memory - start_memory) / 1024^2  # MB
  
  cat(sprintf("⏱️ %s: %.2f seconds, %.1f MB memory change\n", 
              label, duration, memory_diff))
  
  return(result)
}

#' System health check
check_system_health <- function() {
  health_status <- list()
  
  # Check memory usage
  if (require(pryr, quietly = TRUE)) {
    memory_gb <- pryr::mem_used() / 1024^3
    health_status$memory <- list(
      used_gb = memory_gb,
      status = ifelse(memory_gb < 4, "Good", ifelse(memory_gb < 8, "Warning", "Critical"))
    )
  }
  
  # Check disk space
  disk_free_gb <- tryCatch({
    if (require(fs, quietly = TRUE)) {
      fs::fs_bytes(fs::file_info(".")$size) / 1024^3
    } else {
      # Fallback using system command
      as.numeric(system("df . | tail -1 | awk '{print $4}'", intern = TRUE)) / 1024^2
    }
  }, error = function(e) 10) # Default to 10GB if can't determine
  
  health_status$disk <- list(
    free_gb = disk_free_gb,
    status = ifelse(disk_free_gb > 10, "Good", ifelse(disk_free_gb > 5, "Warning", "Critical"))
  )
  
  # Check Python environment
  python_status <- tryCatch({
    if (require(reticulate, quietly = TRUE)) {
      reticulate::py_available()
      "Available"
    } else {
      "Reticulate not available"
    }
  }, error = function(e) "Error")
  
  health_status$python <- list(
    status = python_status
  )
  
  # Check cache size
  cache_size <- length(ls(dataset_cache))
  health_status$cache <- list(
    items = cache_size,
    status = ifelse(cache_size < 5, "Good", "Full")
  )
  
  return(health_status)
}
