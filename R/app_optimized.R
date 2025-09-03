# Optimized App Modifications
# Enhanced version of the main app.R with performance and robustness improvements

# Source the optimization modules first
tryCatch({
  source("R/performance_optimization.R")
  source("R/error_handling_enhanced.R") 
  source("R/performance_monitoring.R")
  source("R/app_integration.R")
  cat("✅ All optimization modules loaded successfully\n")
}, error = function(e) {
  cat("⚠️ Some optimization modules could not be loaded:", e$message, "\n")
  cat("The app will run with basic functionality\n")
})

# Enhanced Python environment initialization
python_env_result <- initialize_python_environment()
if (python_env_result$status == "success") {
  # Assign modules to global environment for app usage
  sc <<- python_env_result$modules$sc
  dc <<- python_env_result$modules$dc
  pydeseq2_dds <<- python_env_result$modules$pydeseq2_dds
  pydeseq2_ds <<- python_env_result$modules$pydeseq2_ds
  
  cat("✅ Python modules initialized successfully\n")
} else {
  cat("❌ Python environment initialization failed\n")
  cat("Recommendations:\n")
  for (rec in python_env_result$recommendations) {
    cat(sprintf("  - %s\n", rec))
  }
  
  # Set modules to NULL for graceful degradation
  sc <<- NULL
  dc <<- NULL
  pydeseq2_dds <<- NULL
  pydeseq2_ds <<- NULL
}

# Enhanced dataset loading function to replace the original
create_optimized_dataset_loader <- function() {
  function(input, output, session) {
    eventReactive(input$import_dataset, {
      
      # Input validation
      if (is.null(input$selection_organism) || is.null(input$selection_dataset) || input$selection_dataset == "") {
        showNotification("❌ Please select a valid organism and dataset", type = "error")
        return(NULL)
      }
      
      # Check if dataset name indicates unavailability
      if (grepl("No datasets available|Error|Contact admin|Status:", input$selection_dataset, ignore.case = TRUE)) {
        showNotification("❌ This dataset is not currently available", type = "error", duration = 10)
        return(NULL)
      }
      
      # Create cache key
      cache_key <- paste(input$selection_organism, input$selection_dataset, 
                        input$dataset_size_option %||% "full", sep = "_")
      
      # Check cache first
      if (exists("get_cached_dataset", mode = "function")) {
        cached_data <- get_cached_dataset(cache_key)
        if (!is.null(cached_data)) {
          showNotification("✅ Dataset loaded from cache", type = "message")
          return(cached_data)
        }
      }
      
      # Enhanced loading with progress and monitoring
      progress <- Progress$new()
      progress$set(message = "Loading dataset...", value = 0)
      on.exit(progress$close())
      
      start_time <- Sys.time()
      
      tryCatch({
        # Use validation function to check dataset path
        dataset_info <- validate_dataset_path(input$selection_organism, input$selection_dataset)
        
        if (!dataset_info$exists) {
          organism_data <- get_organism_data(datasets_config, input$selection_organism)
          
          error_message <- paste0("❌ Dataset file not found: ", basename(dataset_info$path))
          if (organism_data$status != "Available") {
            error_message <- paste0(error_message, "\n💡 Status: ", organism_data$status)
          }
          
          showNotification(error_message, type = "error", duration = 15)
          return(NULL)
        }
        
        dataset_path <- dataset_info$path
        
        # Handle large dataset optimization
        is_large_dataset <- grepl("Fibrotic.*Cross.*Species.*002", input$selection_dataset)
        
        if (is_large_dataset && !is.null(input$dataset_size_option) && input$dataset_size_option != "full") {
          size_suffix <- switch(input$dataset_size_option,
                               "sub5k" = "_sub5k",
                               "sub10k" = "_sub10k", 
                               "sub20k" = "_sub20k",
                               "")
          
          optimized_path <- paste0("datasets_optimized/", 
                                  tools::file_path_sans_ext(input$selection_dataset), 
                                  size_suffix, ".h5ad")
          
          if (file.exists(optimized_path)) {
            dataset_path <- optimized_path
            showNotification(
              paste("✅ Loading", input$dataset_size_option, "version for better performance"), 
              type = "message"
            )
          }
        }
        
        progress$set(value = 0.3, detail = "Reading file...")
        
        # Monitor memory before loading
        if (exists("monitor_memory_usage", mode = "function")) {
          monitor_memory_usage(threshold_gb = 6)
        }
        
        # Load dataset with monitoring
        if (!is.null(sc)) {
          adata <- sc$read_h5ad(dataset_path)
        } else {
          stop("Python scanpy module not available")
        }
        
        progress$set(value = 0.8, detail = "Processing metadata...")
        
        # Cache the dataset if caching is available
        if (exists("cache_dataset", mode = "function")) {
          cache_dataset(cache_key, adata)
        }
        
        # Log performance
        end_time <- Sys.time()
        duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
        
        if (exists("log_operation_performance", mode = "function")) {
          log_operation_performance(
            paste("Load", input$selection_dataset),
            start_time, end_time
          )
        }
        
        # Update UI
        shinyjs::disable("import_dataset")
        updateActionButton(session, "import_dataset", label = "", icon("circle-check"))
        
        progress$set(value = 1, detail = "Complete!")
        
        showNotification(
          paste("✅ Dataset loaded successfully:", 
                format(adata$n_obs, big.mark = ","), "cells ×", 
                format(adata$n_vars, big.mark = ","), "genes",
                sprintf("(%.1fs)", duration)),
          type = "message"
        )
        
        return(adata)
        
      }, error = function(e) {
        progress$close()
        
        error_msg <- paste("❌ Error loading dataset:", e$message)
        
        # Enhanced error reporting
        if (exists("show_enhanced_error", mode = "function")) {
          show_enhanced_error(
            e$message,
            error_type = "loading",
            context = "Dataset Import",
            suggested_actions = c(
              "Check if the dataset file exists",
              "Verify available disk space and memory", 
              "Try selecting a smaller dataset size option",
              "Contact administrator if problem persists"
            )
          )
        } else {
          showNotification(error_msg, type = "error", duration = NULL)
        }
        
        return(NULL)
      })
    })
  }
}

# Enhanced correlation analysis with optimization
create_optimized_correlation_analysis <- function() {
  function(input, data_source, gene_list_adata, filtered_adata) {
    eventReactive(input$top_correlated_first_gene, {
      req(data_source(), input$gene_selection_cluster_coexpression_first)
      
      start_time <- Sys.time()
      
      tryCatch({
        # Prepare data
        if (is.null(input$filter_dataset_cluster_selection)) {
          normalized_counts <- as.matrix(data_source()$X)
        } else {
          normalized_counts <- as.matrix(filtered_adata()$X)
        }
        
        normalized_counts <- as.data.frame(normalized_counts)
        colnames(normalized_counts) <- gene_list_adata()
        
        target_gene <- input$gene_selection_cluster_coexpression_first
        
        # Use optimized correlation if available, otherwise fall back to original
        if (exists("calculate_correlations_optimized", mode = "function")) {
          result <- calculate_correlations_optimized(
            data = normalized_counts,
            target_gene = target_gene,
            method = ifelse(input$test_choice == "Spearman", "spearman", "pearson"),
            max_genes = 1000
          )
        } else {
          # Fallback to original method with optimization
          first_gene_count <- normalized_counts[, target_gene]
          
          # Limit to most variable genes for performance
          if (ncol(normalized_counts) > 1000) {
            gene_vars <- apply(normalized_counts, 2, var, na.rm = TRUE)
            top_genes <- names(sort(gene_vars, decreasing = TRUE)[1:1000])
            normalized_counts <- normalized_counts[, top_genes, drop = FALSE]
            
            showNotification("📊 Limited analysis to 1000 most variable genes for performance", 
                           type = "message")
          }
          
          # Vectorized correlation calculation
          correlation_df <- sapply(names(normalized_counts), function(x) {
            if (input$test_choice == "Spearman") {
              test_result <- cor.test(first_gene_count, normalized_counts[[x]], method = "spearman")
            } else {
              test_result <- cor.test(first_gene_count, normalized_counts[[x]], method = "pearson")
            }
            return(c(correlation = test_result$estimate, p_value = test_result$p.value))
          })
          
          correlation_df <- as.data.frame(t(correlation_df))
          num_tests <- ncol(normalized_counts)
          correlation_df$Bonferroni_p_value <- pmin(1, correlation_df$p_value * num_tests)
          correlation_df$Gene <- rownames(correlation_df)
          colnames(correlation_df)[1:2] <- c("Correlation", "p-val")
          correlation_df <- correlation_df[, c("Gene", "Correlation", "p-val", "Bonferroni_p_value")]
          
          result <- correlation_df[order(abs(correlation_df$Correlation), decreasing = TRUE), ]
        }
        
        # Log performance
        end_time <- Sys.time()
        duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
        
        if (exists("log_operation_performance", mode = "function")) {
          log_operation_performance(
            paste("Correlation Analysis -", target_gene),
            start_time, end_time
          )
        }
        
        if (duration > 5) {
          showNotification(
            sprintf("⏱️ Correlation analysis completed in %.1f seconds", duration),
            type = "message"
          )
        }
        
        return(result)
        
      }, error = function(e) {
        if (exists("show_enhanced_error", mode = "function")) {
          show_enhanced_error(
            e$message,
            error_type = "analysis",
            context = "Correlation Analysis",
            suggested_actions = c(
              "Try with a smaller gene set",
              "Check if the selected gene exists in the dataset",
              "Ensure sufficient memory is available"
            )
          )
        } else {
          showNotification(paste("❌ Correlation analysis failed:", e$message), 
                          type = "error")
        }
        return(NULL)
      })
    })
  }
}

# Enhanced reactive for image generation with caching
create_optimized_image_renderer <- function() {
  function(plot_function, cache_key, file_name) {
    if (exists("generate_plot_cached", mode = "function")) {
      return(generate_plot_cached(plot_function, cache_key, file_name))
    } else {
      # Fallback to direct plot generation
      return(plot_function())
    }
  }
}

# Memory monitoring observer
create_memory_monitor <- function() {
  function(session) {
    observe({
      invalidateLater(30000)  # Check every 30 seconds
      
      if (exists("monitor_memory_usage", mode = "function")) {
        monitor_memory_usage(threshold_gb = 6)
      }
      
      if (exists("cleanup_performance_data", mode = "function")) {
        cleanup_performance_data()
      }
    })
  }
}

# Performance dashboard for debugging
create_performance_dashboard <- function() {
  function(output) {
    output$performance_status <- renderText({
      if (exists("get_dashboard_data", mode = "function")) {
        dashboard_data <- get_dashboard_data()
        sprintf("Memory: %.1f MB | Operations: %d | Uptime: %.1f min", 
                dashboard_data$current_memory_mb %||% 0,
                dashboard_data$recent_operations,
                dashboard_data$uptime_minutes)
      } else {
        "Performance monitoring not available"
      }
    })
    
    output$optimization_suggestions <- renderText({
      if (exists("get_optimization_suggestions", mode = "function")) {
        suggestions <- get_optimization_suggestions()
        if (is.character(suggestions) && length(suggestions) == 1) {
          return(suggestions)
        } else {
          return(paste(suggestions, collapse = "\n"))
        }
      } else {
        "No optimization suggestions available"
      }
    })
  }
}

# Enhanced UI additions for performance monitoring
add_performance_ui <- function() {
  tagList(
    # Performance monitoring CSS
    tags$style(HTML("
      .performance-monitor {
        position: fixed;
        bottom: 10px;
        right: 10px;
        background: rgba(255, 255, 255, 0.95);
        padding: 10px;
        border-radius: 5px;
        font-size: 11px;
        border: 1px solid #ddd;
        z-index: 1000;
        max-width: 300px;
      }
      
      .performance-stats {
        font-family: monospace;
        color: #666;
      }
      
      .optimization-suggestion {
        background-color: #d1ecf1;
        border: 1px solid #bee5eb;
        color: #0c5460;
        padding: 5px;
        border-radius: 3px;
        margin: 5px 0;
        font-size: 10px;
      }
    ")),
    
    # Performance monitor panel (hidden by default, can be shown for debugging)
    conditionalPanel(
      condition = "false",  # Set to true for debugging
      div(class = "performance-monitor",
        h6("Performance Monitor"),
        div(class = "performance-stats",
          textOutput("performance_status")
        ),
        div(class = "optimization-suggestion",
          textOutput("optimization_suggestions")
        )
      )
    )
  )
}

# Helper functions
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Export the optimization functions for use in main app
cat("🚀 Enhanced app optimizations ready for integration\n")
cat("📋 Available optimizations:\n")
cat("  - Enhanced dataset loading with caching\n")
cat("  - Optimized correlation analysis\n") 
cat("  - Memory monitoring and cleanup\n")
cat("  - Performance tracking and suggestions\n")
cat("  - Enhanced error handling with fallbacks\n")
cat("  - Image generation caching\n")

# Print system status
if (exists("get_optimization_status", mode = "function")) {
  status <- get_optimization_status()
  cat(sprintf("💾 Cache items: %d\n", status$cache_items))
  cat(sprintf("📊 Monitored operations: %d\n", status$monitoring_operations))
  cat(sprintf("⚠️ Performance warnings: %d\n", status$monitoring_warnings))
}
