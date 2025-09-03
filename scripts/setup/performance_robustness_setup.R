# Sistema de monitoramento de performance e robustesse para MASLDatlas
# Performance and Robustness Monitoring System for MASLDatlas

# Script principal para aplicar melhorias de performance e robustez
# Main script to apply performance and robustness improvements

cat("🚀 Initializing MASLDatlas Performance and Robustness Enhancements\n")
cat("=================================================================\n")

# 1. SISTEMA DE CACHE INTELIGENTE / INTELLIGENT CACHING SYSTEM
cache_system_setup <- function() {
  cat("📋 Setting up intelligent caching system...\n")
  
  # Create cache environment if it doesn't exist
  if (!exists("dataset_cache", envir = .GlobalEnv)) {
    assign("dataset_cache", new.env(parent = emptyenv()), envir = .GlobalEnv)
    cat("  ✅ Dataset cache environment created\n")
  }
  
  # Cache management functions
  cache_info <- function() {
    cache_env <- get("dataset_cache", envir = .GlobalEnv)
    cache_items <- ls(cache_env)
    
    if (length(cache_items) == 0) {
      return("Cache is empty")
    }
    
    cache_sizes <- sapply(cache_items, function(item) {
      obj <- get(item, envir = cache_env)
      if (is.list(obj) && "data" %in% names(obj)) {
        return(object.size(obj$data) / 1024^3)  # GB
      } else {
        return(object.size(obj) / 1024^3)  # GB
      }
    })
    
    total_size <- sum(cache_sizes, na.rm = TRUE)
    
    return(list(
      items = length(cache_items),
      total_size_gb = total_size,
      items_detail = data.frame(
        item = cache_items,
        size_gb = cache_sizes,
        stringsAsFactors = FALSE
      )
    ))
  }
  
  # Store cache functions globally
  assign("cache_info", cache_info, envir = .GlobalEnv)
  
  cat("  ✅ Cache system ready\n")
}

# 2. MONITORAMENTO DE MEMÓRIA / MEMORY MONITORING
memory_monitoring_setup <- function() {
  cat("💾 Setting up memory monitoring...\n")
  
  get_memory_info <- function() {
    memory_info <- list()
    
    # R memory usage
    if (requireNamespace("pryr", quietly = TRUE)) {
      memory_info$r_memory_mb <- as.numeric(pryr::mem_used()) / 1024^2
    } else {
      memory_info$r_memory_mb <- as.numeric(object.size(.GlobalEnv)) / 1024^2
    }
    
    # System memory (basic estimation)
    if (Sys.info()["sysname"] == "Darwin") {  # macOS
      memory_info$system <- "macOS - memory monitoring available"
    } else if (Sys.info()["sysname"] == "Linux") {
      memory_info$system <- "Linux - memory monitoring available"
    } else {
      memory_info$system <- "Windows - basic monitoring"
    }
    
    memory_info$timestamp <- Sys.time()
    memory_info$status <- if (memory_info$r_memory_mb < 1000) "Good" else 
                         if (memory_info$r_memory_mb < 4000) "Warning" else "Critical"
    
    return(memory_info)
  }
  
  memory_cleanup <- function() {
    # Force garbage collection
    for (i in 1:3) gc(verbose = FALSE)
    
    # Clean temporary files
    temp_files <- list.files("figures", pattern = "\\.(png|jpg|jpeg)$", full.names = TRUE)
    if (length(temp_files) > 0) {
      # Remove files older than 1 hour
      old_files <- temp_files[file.mtime(temp_files) < Sys.time() - 3600]
      if (length(old_files) > 0) {
        file.remove(old_files)
        cat(sprintf("  🧹 Cleaned %d temporary image files\n", length(old_files)))
      }
    }
    
    return(get_memory_info())
  }
  
  # Store globally
  assign("get_memory_info", get_memory_info, envir = .GlobalEnv)
  assign("memory_cleanup", memory_cleanup, envir = .GlobalEnv)
  
  cat("  ✅ Memory monitoring ready\n")
}

# 3. OTIMIZAÇÃO DE CARREGAMENTO DE DADOS / DATA LOADING OPTIMIZATION
data_loading_optimization <- function() {
  cat("📂 Setting up optimized data loading...\n")
  
  # Enhanced dataset validation
  validate_dataset_enhanced <- function(organism, dataset) {
    result <- list(
      valid = FALSE,
      path = NULL,
      size_gb = 0,
      recommendations = c(),
      alternatives = c()
    )
    
    # Primary path
    primary_path <- file.path("datasets", paste0(dataset, ".h5ad"))
    
    if (file.exists(primary_path)) {
      result$valid <- TRUE
      result$path <- primary_path
      result$size_gb <- file.size(primary_path) / 1024^3
      
      # Add recommendations based on size
      if (result$size_gb > 5) {
        result$recommendations <- c(
          "Large dataset detected - consider using optimized subset",
          "Ensure sufficient RAM (recommend 16GB+ for datasets > 5GB)"
        )
        
        # Check for optimized alternatives
        opt_path_10k <- file.path("datasets_optimized", paste0(tools::file_path_sans_ext(dataset), "_sub10k.h5ad"))
        opt_path_5k <- file.path("datasets_optimized", paste0(tools::file_path_sans_ext(dataset), "_sub5k.h5ad"))
        
        if (file.exists(opt_path_10k)) {
          result$alternatives <- c(result$alternatives, "10k cells subset available")
        }
        if (file.exists(opt_path_5k)) {
          result$alternatives <- c(result$alternatives, "5k cells subset available")
        }
      }
    } else {
      result$recommendations <- c(
        paste("Dataset file not found:", primary_path),
        "Check if dataset has been downloaded",
        "Run dataset download script if needed"
      )
    }
    
    return(result)
  }
  
  # Intelligent dataset loader with fallbacks
  load_dataset_intelligent <- function(organism, dataset, size_option = NULL, 
                                     progress_callback = NULL) {
    
    if (!is.null(progress_callback)) {
      progress_callback(0.1, "Validating dataset...")
    }
    
    validation <- validate_dataset_enhanced(organism, dataset)
    
    if (!validation$valid) {
      stop(paste("Dataset validation failed:", paste(validation$recommendations, collapse = "; ")))
    }
    
    dataset_path <- validation$path
    
    # Handle size options for large datasets
    if (!is.null(size_option) && size_option != "full") {
      opt_path <- file.path("datasets_optimized", 
                           paste0(tools::file_path_sans_ext(dataset), "_", size_option, ".h5ad"))
      
      if (file.exists(opt_path)) {
        dataset_path <- opt_path
        cat(sprintf("  📊 Using %s optimized version\n", size_option))
      }
    }
    
    if (!is.null(progress_callback)) {
      progress_callback(0.3, "Loading dataset...")
    }
    
    # Check if scanpy is available
    if (exists("sc", envir = .GlobalEnv) && !is.null(get("sc", envir = .GlobalEnv))) {
      sc <- get("sc", envir = .GlobalEnv)
      
      start_time <- Sys.time()
      adata <- sc$read_h5ad(dataset_path)
      load_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      
      cat(sprintf("  ✅ Dataset loaded in %.1f seconds\n", load_time))
      
      if (!is.null(progress_callback)) {
        progress_callback(1.0, "Complete!")
      }
      
      return(adata)
    } else {
      stop("Python scanpy module not available")
    }
  }
  
  # Store globally
  assign("validate_dataset_enhanced", validate_dataset_enhanced, envir = .GlobalEnv)
  assign("load_dataset_intelligent", load_dataset_intelligent, envir = .GlobalEnv)
  
  cat("  ✅ Data loading optimization ready\n")
}

# 4. ANÁLISE DE CORRELAÇÃO OTIMIZADA / OPTIMIZED CORRELATION ANALYSIS
correlation_optimization <- function() {
  cat("📊 Setting up optimized correlation analysis...\n")
  
  # Fast correlation with gene filtering
  fast_correlation_analysis <- function(data_matrix, target_gene, method = "spearman", 
                                       max_genes = 1000, min_variance = 0.01) {
    
    start_time <- Sys.time()
    
    # Filter genes by variance to improve performance
    if (ncol(data_matrix) > max_genes) {
      gene_vars <- apply(data_matrix, 2, var, na.rm = TRUE)
      
      # Remove low-variance genes
      high_var_genes <- gene_vars > min_variance
      data_matrix <- data_matrix[, high_var_genes, drop = FALSE]
      
      # Select top variable genes
      if (ncol(data_matrix) > max_genes) {
        top_genes <- names(sort(gene_vars[high_var_genes], decreasing = TRUE)[1:max_genes])
        data_matrix <- data_matrix[, top_genes, drop = FALSE]
      }
      
      cat(sprintf("  📊 Analysis limited to %d most variable genes\n", ncol(data_matrix)))
    }
    
    # Ensure target gene is included
    if (!target_gene %in% colnames(data_matrix)) {
      stop(paste("Target gene", target_gene, "not found in filtered dataset"))
    }
    
    target_values <- data_matrix[, target_gene]
    
    # Vectorized correlation calculation
    if (method == "spearman") {
      correlations <- apply(data_matrix, 2, function(x) {
        cor(target_values, x, method = "spearman", use = "complete.obs")
      })
    } else {
      correlations <- apply(data_matrix, 2, function(x) {
        cor(target_values, x, method = "pearson", use = "complete.obs")
      })
    }
    
    # Calculate p-values efficiently
    n <- nrow(data_matrix)
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
    
    duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    cat(sprintf("  ⏱️ Correlation analysis completed in %.2f seconds\n", duration))
    
    return(result_df)
  }
  
  # Store globally
  assign("fast_correlation_analysis", fast_correlation_analysis, envir = .GlobalEnv)
  
  cat("  ✅ Correlation optimization ready\n")
}

# 5. SISTEMA DE SAÚDE DA APLICAÇÃO / APPLICATION HEALTH SYSTEM
health_monitoring_setup <- function() {
  cat("🏥 Setting up application health monitoring...\n")
  
  check_app_health <- function() {
    health_report <- list(
      timestamp = Sys.time(),
      overall_status = "unknown",
      components = list()
    )
    
    # Check Python environment
    health_report$components$python <- list(
      status = "unknown",
      details = c()
    )
    
    if (exists("sc", envir = .GlobalEnv) && !is.null(get("sc", envir = .GlobalEnv))) {
      health_report$components$python$status <- "healthy"
      health_report$components$python$details <- c("scanpy available")
    } else {
      health_report$components$python$status <- "error"
      health_report$components$python$details <- c("scanpy not available")
    }
    
    # Check memory status
    memory_info <- get_memory_info()
    health_report$components$memory <- list(
      status = tolower(memory_info$status),
      details = sprintf("R memory: %.1f MB", memory_info$r_memory_mb)
    )
    
    # Check cache status
    cache_info_result <- cache_info()
    if (is.character(cache_info_result)) {
      health_report$components$cache <- list(
        status = "empty",
        details = "No cached items"
      )
    } else {
      health_report$components$cache <- list(
        status = "healthy",
        details = sprintf("%d items (%.2f GB)", 
                         cache_info_result$items, 
                         cache_info_result$total_size_gb)
      )
    }
    
    # Check datasets availability
    config_file <- "config/datasets_config.json"
    if (file.exists(config_file)) {
      health_report$components$datasets <- list(
        status = "healthy",
        details = "Configuration file available"
      )
    } else {
      health_report$components$datasets <- list(
        status = "warning",
        details = "Configuration file not found"
      )
    }
    
    # Determine overall status
    component_statuses <- sapply(health_report$components, function(x) x$status)
    if (all(component_statuses %in% c("healthy", "empty"))) {
      health_report$overall_status <- "healthy"
    } else if (any(component_statuses == "error")) {
      health_report$overall_status <- "error"
    } else {
      health_report$overall_status <- "warning"
    }
    
    return(health_report)
  }
  
  print_health_status <- function() {
    health <- check_app_health()
    
    cat("🏥 APPLICATION HEALTH STATUS\n")
    cat("============================\n")
    cat(sprintf("Overall Status: %s\n", toupper(health$overall_status)))
    cat(sprintf("Timestamp: %s\n\n", health$timestamp))
    
    for (component_name in names(health$components)) {
      component <- health$components[[component_name]]
      status_emoji <- switch(component$status,
                           "healthy" = "✅",
                           "warning" = "⚠️", 
                           "error" = "❌",
                           "empty" = "📭",
                           "❓")
      
      cat(sprintf("%s %s: %s\n", status_emoji, 
                  toupper(component_name), 
                  paste(component$details, collapse = ", ")))
    }
    cat("\n")
  }
  
  # Store globally
  assign("check_app_health", check_app_health, envir = .GlobalEnv)
  assign("print_health_status", print_health_status, envir = .GlobalEnv)
  
  cat("  ✅ Health monitoring ready\n")
}

# 6. SISTEMA DE SUGESTÕES DE OTIMIZAÇÃO / OPTIMIZATION SUGGESTIONS SYSTEM
optimization_suggestions_setup <- function() {
  cat("💡 Setting up optimization suggestions system...\n")
  
  get_performance_suggestions <- function() {
    suggestions <- c()
    
    # Check memory usage
    memory_info <- get_memory_info()
    if (memory_info$r_memory_mb > 2000) {
      suggestions <- c(suggestions, 
                      "🐏 High memory usage detected - consider memory cleanup")
    }
    
    # Check cache efficiency
    cache_info_result <- cache_info()
    if (!is.character(cache_info_result) && cache_info_result$total_size_gb > 4) {
      suggestions <- c(suggestions,
                      "💾 Large cache detected - consider clearing old entries")
    }
    
    # Check dataset sizes
    if (dir.exists("datasets")) {
      dataset_files <- list.files("datasets", pattern = "\\.h5ad$", full.names = TRUE)
      large_datasets <- dataset_files[file.size(dataset_files) > 5 * 1024^3]  # > 5GB
      
      if (length(large_datasets) > 0) {
        suggestions <- c(suggestions,
                        sprintf("📊 %d large datasets detected - consider using optimized subsets", 
                               length(large_datasets)))
      }
    }
    
    # Check Python environment
    if (!exists("sc", envir = .GlobalEnv) || is.null(get("sc", envir = .GlobalEnv))) {
      suggestions <- c(suggestions,
                      "🐍 Python environment issues - reinstall conda environment")
    }
    
    if (length(suggestions) == 0) {
      return("✅ All systems optimized! No suggestions at this time.")
    }
    
    return(suggestions)
  }
  
  # Store globally
  assign("get_performance_suggestions", get_performance_suggestions, envir = .GlobalEnv)
  
  cat("  ✅ Optimization suggestions ready\n")
}

# EXECUÇÃO PRINCIPAL / MAIN EXECUTION
main_setup <- function() {
  cat("\n🔧 Running complete setup...\n")
  
  # Initialize all systems
  cache_system_setup()
  memory_monitoring_setup()
  data_loading_optimization()
  correlation_optimization()
  health_monitoring_setup()
  optimization_suggestions_setup()
  
  cat("\n✅ ALL OPTIMIZATION SYSTEMS READY!\n")
  cat("================================\n")
  
  # Show initial status
  print_health_status()
  
  # Show initial suggestions
  cat("💡 Performance Suggestions:\n")
  suggestions <- get_performance_suggestions()
  if (is.character(suggestions) && length(suggestions) == 1) {
    cat(paste("  ", suggestions, "\n"))
  } else {
    for (suggestion in suggestions) {
      cat(paste("  ", suggestion, "\n"))
    }
  }
  
  cat("\n🚀 MASLDatlas is ready with enhanced performance and robustness!\n")
  
  return(list(
    status = "ready",
    timestamp = Sys.time(),
    systems = c("caching", "memory_monitoring", "data_loading", 
                "correlation_optimization", "health_monitoring", "suggestions")
  ))
}

# Execute setup
setup_result <- main_setup()

# Export useful commands for interactive use
cat("\n📋 Available commands for monitoring:\n")
cat("  - cache_info()                    # Check cache status\n")
cat("  - get_memory_info()              # Check memory usage\n") 
cat("  - memory_cleanup()               # Clean memory and temp files\n")
cat("  - check_app_health()             # Full health check\n")
cat("  - print_health_status()          # Print formatted health status\n")
cat("  - get_performance_suggestions()  # Get optimization suggestions\n")

cat("\n🎯 Integration complete! Enhanced robustness and performance active.\n")
