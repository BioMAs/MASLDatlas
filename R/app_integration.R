# Application Integration Module
# Integration of performance and robustness improvements into main app

#' Source all optimization modules
source_optimization_modules <- function() {
  module_files <- c(
    "R/performance_optimization.R",
    "R/error_handling_enhanced.R", 
    "R/performance_monitoring.R"
  )
  
  for (module_file in module_files) {
    if (file.exists(module_file)) {
      tryCatch({
        source(module_file)
        cat(sprintf("✅ Loaded: %s\n", module_file))
      }, error = function(e) {
        cat(sprintf("⚠️ Failed to load %s: %s\n", module_file, e$message))
      })
    } else {
      cat(sprintf("⚠️ Module file not found: %s\n", module_file))
    }
  }
}

#' Enhanced dataset loading with optimization
optimized_dataset_loader <- function(input, session) {
  # Create enhanced reactive for dataset loading
  eventReactive(input$import_dataset, {
    req(input$selection_organism, input$selection_dataset)
    
    # Validate inputs first
    if (is.null(input$selection_organism) || is.null(input$selection_dataset) || input$selection_dataset == "") {
      show_enhanced_error(
        "Please select a valid organism and dataset",
        error_type = "validation",
        context = "Dataset Import",
        suggested_actions = c(
          "Select an organism from the dropdown",
          "Select a dataset from the available options",
          "Ensure the dataset status is 'Available'"
        )
      )
      return(NULL)
    }
    
    # Check cache first
    cache_key <- paste(input$selection_organism, input$selection_dataset, 
                      input$dataset_size_option %||% "full", sep = "_")
    
    cached_data <- get_cached_dataset(cache_key)
    if (!is.null(cached_data)) {
      cat("📋 Using cached dataset\n")
      showNotification("✅ Dataset loaded from cache", type = "message")
      return(cached_data)
    }
    
    # Load with enhanced progress and error handling
    progress <- Progress$new()
    progress$set(message = "Loading dataset...", value = 0)
    on.exit(progress$close())
    
    loading_result <- monitor_execution(
      function() {
        load_dataset_with_fallbacks(
          input$selection_organism,
          input$selection_dataset, 
          input$dataset_size_option
        )
      },
      operation_name = paste("Load", input$selection_dataset)
    )
    
    if (loading_result$success && !is.null(loading_result$data)) {
      # Cache the loaded dataset
      cache_dataset(cache_key, loading_result$data)
      
      # Update UI
      shinyjs::disable("import_dataset")
      updateActionButton(session, "import_dataset", label = "", icon("circle-check"))
      
      # Show success notification
      size_info <- sprintf("%s cells × %s genes", 
                          format(loading_result$data$n_obs, big.mark = ","),
                          format(loading_result$data$n_vars, big.mark = ","))
      
      showNotification(
        paste("✅ Dataset loaded successfully:", size_info),
        type = "message"
      )
      
      return(loading_result$data)
    } else {
      show_enhanced_error(
        loading_result$error %||% "Unknown error during dataset loading",
        error_type = "loading",
        context = "Dataset Import",
        suggested_actions = c(
          "Check if the dataset file exists",
          "Verify available disk space and memory",
          "Try selecting a smaller dataset size option",
          "Contact administrator if problem persists"
        )
      )
      return(NULL)
    }
  })
}

#' Enhanced correlation analysis with optimization
optimized_correlation_analysis <- function(input, data_source) {
  eventReactive(input$top_correlated_first_gene, {
    req(data_source(), input$gene_selection_cluster_coexpression_first)
    
    # Monitor the correlation analysis
    result <- monitor_execution(
      function() {
        # Prepare data
        if (is.null(input$filter_dataset_cluster_selection)) {
          normalized_counts <- as.matrix(data_source()$X)
        } else {
          normalized_counts <- as.matrix(filtered_adata()$X)
        }
        
        normalized_counts <- as.data.frame(normalized_counts)
        colnames(normalized_counts) <- gene_list_adata()
        
        target_gene <- input$gene_selection_cluster_coexpression_first
        target_values <- normalized_counts[, target_gene]
        
        # Use optimized correlation calculation
        calculate_correlations_optimized(
          data = normalized_counts,
          target_gene = target_gene,
          method = ifelse(input$test_choice == "Spearman", "spearman", "pearson"),
          max_genes = 1000,
          progress_callback = function(value, detail) {
            # Could integrate with Shiny progress here
          }
        )
      },
      operation_name = paste("Correlation Analysis -", input$gene_selection_cluster_coexpression_first)
    )
    
    return(result)
  })
}

#' Enhanced reactive system with cleanup
create_enhanced_reactives <- function(input, output, session) {
  
  # Enhanced dataset loading
  adata <- optimized_dataset_loader(input, session)
  
  # Memory monitoring reactive
  observe({
    invalidateLater(30000)  # Check every 30 seconds
    monitor_memory_usage(threshold_gb = 6)
    cleanup_performance_data()
  })
  
  # Performance monitoring UI
  output$performance_status <- renderText({
    dashboard_data <- get_dashboard_data()
    sprintf("Memory: %.1f MB | Operations: %d | Uptime: %.1f min", 
            dashboard_data$current_memory_mb %||% 0,
            dashboard_data$recent_operations,
            dashboard_data$uptime_minutes)
  })
  
  # System health monitoring
  output$system_health <- renderUI({
    health <- check_system_health()
    
    status_items <- list()
    
    # Memory status
    if (!is.null(health$memory)) {
      memory_color <- switch(health$memory$status,
                           "Good" = "green",
                           "Warning" = "orange", 
                           "Critical" = "red")
      status_items <- c(status_items, 
                       div(style = paste0("color: ", memory_color, ";"),
                           sprintf("Memory: %.1f GB (%s)", 
                                  health$memory$used_gb, health$memory$status)))
    }
    
    # Python status
    python_color <- ifelse(health$python$status == "Available", "green", "red")
    status_items <- c(status_items,
                     div(style = paste0("color: ", python_color, ";"),
                         sprintf("Python: %s", health$python$status)))
    
    # Cache status
    cache_color <- ifelse(health$cache$status == "Good", "green", "orange")
    status_items <- c(status_items,
                     div(style = paste0("color: ", cache_color, ";"),
                         sprintf("Cache: %d items (%s)", 
                                health$cache$items, health$cache$status)))
    
    do.call(div, c(list(class = "system-health"), status_items))
  })
  
  return(list(
    adata = adata
  ))
}

#' Enhanced error handling wrapper for server functions
with_error_handling <- function(expr, context = "", fallback = NULL) {
  tryCatch({
    expr
  }, error = function(e) {
    show_enhanced_error(
      e$message,
      error_type = "runtime",
      context = context,
      suggested_actions = c(
        "Try refreshing the page",
        "Check your internet connection",
        "Contact support if the problem persists"
      )
    )
    
    if (!is.null(fallback)) {
      return(fallback)
    } else {
      return(NULL)
    }
  })
}

#' Add performance CSS to UI
add_performance_css <- function() {
  tags$style(HTML("
    .system-health {
      position: fixed;
      top: 60px;
      right: 10px;
      background: rgba(255, 255, 255, 0.9);
      padding: 5px 10px;
      border-radius: 5px;
      font-size: 12px;
      border: 1px solid #ddd;
      z-index: 1000;
    }
    
    .performance-warning {
      background-color: #fff3cd;
      border: 1px solid #ffeaa7;
      color: #856404;
      padding: 10px;
      border-radius: 5px;
      margin: 10px 0;
    }
    
    .memory-warning {
      background-color: #f8d7da;
      border: 1px solid #f5c6cb;
      color: #721c24;
      padding: 10px;
      border-radius: 5px;
      margin: 10px 0;
    }
    
    .optimization-suggestion {
      background-color: #d1ecf1;
      border: 1px solid #bee5eb;
      color: #0c5460;
      padding: 10px;
      border-radius: 5px;
      margin: 10px 0;
    }
    
    .loading-optimized {
      border-left: 4px solid #28a745;
      padding-left: 15px;
    }
    
    .performance-stats {
      font-family: 'Courier New', monospace;
      font-size: 11px;
      background: #f8f9fa;
      padding: 5px;
      border-radius: 3px;
      margin: 5px 0;
    }
  "))
}

#' Initialize optimization systems
initialize_optimizations <- function() {
  cat("🚀 Initializing MASLDatlas optimizations...\n")
  
  # Source modules
  source_optimization_modules()
  
  # Initialize monitoring
  if (!exists("performance_monitor")) {
    initialize_performance_monitoring()
  }
  
  # Set up memory monitoring
  options(warn = 1)  # Show warnings immediately
  
  cat("✅ Optimization systems ready\n")
  
  # Return initialization status
  return(list(
    status = "ready",
    modules_loaded = c("performance_optimization", "error_handling_enhanced", "performance_monitoring"),
    monitoring_active = TRUE,
    cache_available = TRUE
  ))
}

#' Get optimization status for debugging
get_optimization_status <- function() {
  list(
    cache_items = length(ls(dataset_cache)),
    monitoring_operations = length(performance_monitor$operations),
    monitoring_warnings = length(performance_monitor$warnings),
    system_health = check_system_health(),
    performance_suggestions = get_optimization_suggestions()
  )
}

#' Helper function to safely get global variables
safe_get_global <- function(var_name, default = NULL) {
  if (exists(var_name, envir = .GlobalEnv)) {
    return(get(var_name, envir = .GlobalEnv))
  } else {
    return(default)
  }
}

#' null coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
