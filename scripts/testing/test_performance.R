#!/usr/bin/env Rscript

# 🚀 MASLDatlas Performance Testing Suite
# Comprehensive performance testing and benchmarking
# Author: MASLDatlas Team
# Version: 1.0

library(jsonlite)
library(microbenchmark)
library(parallel)

# Configuration
PERFORMANCE_LOG <- "logs/performance_test.log"
BENCHMARK_ITERATIONS <- 10
MEMORY_CHECK_INTERVAL <- 5

# Create logs directory
if (!dir.exists("logs")) {
  dir.create("logs", recursive = TRUE)
}

# Enhanced logging function
log_perf <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0(timestamp, " [", level, "] ", message)
  cat(log_entry, "\n")
  cat(log_entry, "\n", file = PERFORMANCE_LOG, append = TRUE)
}

# Memory monitoring function
monitor_memory <- function() {
  if (requireNamespace("pryr", quietly = TRUE)) {
    mem_used <- pryr::mem_used()
    mem_mb <- as.numeric(mem_used) / 1024^2
    return(list(
      used_mb = round(mem_mb, 2),
      used_gb = round(mem_mb / 1024, 3)
    ))
  } else {
    # Fallback using base R
    gc_info <- gc()
    used_mb <- sum(gc_info[, "used"]) * 8 / 1024  # Rough estimate
    return(list(
      used_mb = round(used_mb, 2),
      used_gb = round(used_mb / 1024, 3)
    ))
  }
}

# Package loading performance test
test_package_loading <- function() {
  log_perf("🔍 Testing package loading performance...")
  
  packages <- c("shiny", "bslib", "dplyr", "ggplot2", "reticulate", "DT", "jsonlite")
  loading_times <- list()
  
  for (pkg in packages) {
    # Detach package if already loaded
    if (pkg %in% names(sessionInfo()$otherPkgs)) {
      try(detach(paste0("package:", pkg), character.only = TRUE, unload = TRUE), silent = TRUE)
    }
    
    # Measure loading time
    start_time <- Sys.time()
    success <- tryCatch({
      suppressPackageStartupMessages(library(pkg, character.only = TRUE))
      TRUE
    }, error = function(e) FALSE)
    end_time <- Sys.time()
    
    if (success) {
      load_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      loading_times[[pkg]] <- load_time
      log_perf(paste("  ✅", pkg, "loaded in", round(load_time, 3), "seconds"))
    } else {
      log_perf(paste("  ❌", pkg, "failed to load"), "ERROR")
    }
  }
  
  return(loading_times)
}

# Configuration loading performance test
test_config_loading <- function() {
  log_perf("📋 Testing configuration loading performance...")
  
  config_files <- c(
    "config/datasets_config.json",
    "config/datasets_config_safe.json",
    "config/app_config.json"
  )
  
  config_times <- list()
  
  for (config_file in config_files) {
    if (file.exists(config_file)) {
      # Benchmark configuration loading
      bench_result <- microbenchmark(
        config <- fromJSON(config_file),
        times = BENCHMARK_ITERATIONS
      )
      
      avg_time <- mean(bench_result$time) / 1e6  # Convert to milliseconds
      config_times[[basename(config_file)]] <- avg_time
      
      log_perf(paste("  📄", basename(config_file), "avg load time:", round(avg_time, 2), "ms"))
    } else {
      log_perf(paste("  ❌", config_file, "not found"), "WARN")
    }
  }
  
  return(config_times)
}

# Python environment performance test
test_python_performance <- function() {
  log_perf("🐍 Testing Python environment performance...")
  
  python_times <- list()
  
  # Test reticulate initialization
  start_time <- Sys.time()
  tryCatch({
    library(reticulate)
    
    # Try different Python environments
    env_methods <- c("conda", "virtualenv")
    
    for (method in env_methods) {
      method_start <- Sys.time()
      success <- tryCatch({
        if (method == "conda" && Sys.getenv("CONDA_DEFAULT_ENV") != "") {
          use_condaenv("fibrosis_shiny")
        } else {
          use_virtualenv("fibrosis_shiny")
        }
        TRUE
      }, error = function(e) FALSE)
      method_end <- Sys.time()
      
      if (success) {
        init_time <- as.numeric(difftime(method_end, method_start, units = "secs"))
        python_times[[paste0(method, "_init")]] <- init_time
        log_perf(paste("  ✅", method, "environment initialized in", round(init_time, 3), "seconds"))
        break
      }
    }
    
    # Test Python module imports
    modules <- c("scanpy", "pandas", "numpy")
    for (module in modules) {
      module_start <- Sys.time()
      success <- tryCatch({
        import(module)
        TRUE
      }, error = function(e) FALSE)
      module_end <- Sys.time()
      
      if (success) {
        import_time <- as.numeric(difftime(module_end, module_start, units = "secs"))
        python_times[[paste0(module, "_import")]] <- import_time
        log_perf(paste("    📦", module, "imported in", round(import_time, 3), "seconds"))
      } else {
        log_perf(paste("    ❌", module, "import failed"), "WARN")
      }
    }
    
  }, error = function(e) {
    log_perf(paste("Python environment test failed:", e$message), "ERROR")
  })
  
  return(python_times)
}

# Memory stress test
test_memory_usage <- function() {
  log_perf("🧠 Testing memory usage patterns...")
  
  memory_stats <- list()
  
  # Baseline memory
  baseline <- monitor_memory()
  memory_stats$baseline_mb <- baseline$used_mb
  log_perf(paste("  📊 Baseline memory:", baseline$used_mb, "MB"))
  
  # Test vector allocation
  log_perf("  📈 Testing large vector allocation...")
  start_mem <- monitor_memory()
  
  # Allocate large vectors of different sizes
  test_sizes <- c(1e6, 5e6, 1e7)  # 1M, 5M, 10M elements
  
  for (size in test_sizes) {
    alloc_start <- Sys.time()
    tryCatch({
      large_vector <- rnorm(size)
      alloc_end <- Sys.time()
      
      current_mem <- monitor_memory()
      alloc_time <- as.numeric(difftime(alloc_end, alloc_start, units = "secs"))
      
      memory_stats[[paste0("alloc_", size)]] <- list(
        time_seconds = alloc_time,
        memory_mb = current_mem$used_mb
      )
      
      log_perf(paste("    🔢", format(size, scientific = FALSE), "elements allocated in", 
                    round(alloc_time, 3), "seconds, memory:", current_mem$used_mb, "MB"))
      
      # Clean up
      rm(large_vector)
      gc()
      
    }, error = function(e) {
      log_perf(paste("    ❌ Failed to allocate", size, "elements:", e$message), "ERROR")
    })
  }
  
  # Force garbage collection and check memory cleanup
  gc()
  final_mem <- monitor_memory()
  memory_stats$final_mb <- final_mem$used_mb
  log_perf(paste("  🧹 Memory after cleanup:", final_mem$used_mb, "MB"))
  
  return(memory_stats)
}

# Dataset loading simulation
test_dataset_loading_simulation <- function() {
  log_perf("📊 Testing dataset loading simulation...")
  
  # Simulate loading different sized datasets
  simulated_sizes <- c(1000, 5000, 10000, 20000)
  loading_stats <- list()
  
  for (size in simulated_sizes) {
    log_perf(paste("  🧪 Simulating", size, "cell dataset..."))
    
    start_time <- Sys.time()
    start_mem <- monitor_memory()
    
    # Simulate a single-cell dataset structure
    tryCatch({
      # Gene expression matrix (cells x genes)
      n_genes <- 2000
      expression_matrix <- matrix(
        rpois(size * n_genes, lambda = 2),
        nrow = size,
        ncol = n_genes
      )
      
      # Metadata
      metadata <- data.frame(
        cell_id = paste0("cell_", 1:size),
        cluster = sample(1:10, size, replace = TRUE),
        cell_type = sample(c("TypeA", "TypeB", "TypeC"), size, replace = TRUE),
        stringsAsFactors = FALSE
      )
      
      end_time <- Sys.time()
      end_mem <- monitor_memory()
      
      load_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
      memory_used <- end_mem$used_mb - start_mem$used_mb
      
      loading_stats[[paste0("size_", size)]] <- list(
        cells = size,
        genes = n_genes,
        load_time_seconds = load_time,
        memory_mb = memory_used,
        mb_per_1k_cells = round(memory_used / (size / 1000), 2)
      )
      
      log_perf(paste("    ✅ Loaded in", round(load_time, 3), "seconds,", 
                    round(memory_used, 1), "MB additional memory"))
      
      # Clean up
      rm(expression_matrix, metadata)
      gc()
      
    }, error = function(e) {
      log_perf(paste("    ❌ Failed to simulate", size, "cells:", e$message), "ERROR")
    })
  }
  
  return(loading_stats)
}

# Generate performance report
generate_performance_report <- function(test_results) {
  log_perf("📊 Generating performance report...")
  
  report <- list(
    timestamp = Sys.time(),
    system_info = list(
      r_version = R.version.string,
      platform = R.version$platform,
      os = Sys.info()["sysname"],
      cores = detectCores()
    ),
    test_results = test_results,
    recommendations = c()
  )
  
  # Add recommendations based on results
  if ("memory_stats" %in% names(test_results)) {
    baseline_mb <- test_results$memory_stats$baseline_mb
    if (baseline_mb > 1000) {
      report$recommendations <- c(report$recommendations, 
        "High baseline memory usage detected. Consider optimizing startup procedures.")
    }
  }
  
  if ("python_times" %in% names(test_results)) {
    if (any(sapply(test_results$python_times, function(x) x > 10))) {
      report$recommendations <- c(report$recommendations,
        "Python environment initialization is slow. Consider pre-warming the environment.")
    }
  }
  
  # Save report
  report_file <- paste0("logs/performance_report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json")
  writeLines(toJSON(report, pretty = TRUE, auto_unbox = TRUE), report_file)
  
  log_perf(paste("📄 Performance report saved to:", report_file))
  
  return(report)
}

# Main performance test function
run_performance_tests <- function() {
  log_perf("🚀 Starting MASLDatlas Performance Test Suite")
  log_perf(paste("📅 Test started at:", Sys.time()))
  log_perf(paste("🔧 R version:", R.version.string))
  log_perf(paste("💻 Platform:", R.version$platform))
  
  test_results <- list()
  
  # Run all tests
  tryCatch({
    test_results$package_loading <- test_package_loading()
  }, error = function(e) log_perf(paste("Package loading test failed:", e$message), "ERROR"))
  
  tryCatch({
    test_results$config_loading <- test_config_loading()
  }, error = function(e) log_perf(paste("Config loading test failed:", e$message), "ERROR"))
  
  tryCatch({
    test_results$python_performance <- test_python_performance()
  }, error = function(e) log_perf(paste("Python performance test failed:", e$message), "ERROR"))
  
  tryCatch({
    test_results$memory_stats <- test_memory_usage()
  }, error = function(e) log_perf(paste("Memory test failed:", e$message), "ERROR"))
  
  tryCatch({
    test_results$dataset_simulation <- test_dataset_loading_simulation()
  }, error = function(e) log_perf(paste("Dataset simulation test failed:", e$message), "ERROR"))
  
  # Generate report
  performance_report <- generate_performance_report(test_results)
  
  log_perf("✅ Performance test suite completed")
  
  return(performance_report)
}

# Execute if run directly
if (!interactive()) {
  result <- run_performance_tests()
  
  # Print summary
  cat("\n🎯 PERFORMANCE TEST SUMMARY\n")
  cat("============================\n")
  cat("📊 Total tests run:", length(result$test_results), "\n")
  cat("⚠️ Recommendations:", length(result$recommendations), "\n")
  
  if (length(result$recommendations) > 0) {
    cat("\n💡 Recommendations:\n")
    for (i in seq_along(result$recommendations)) {
      cat(paste("  ", i, ".", result$recommendations[i], "\n"))
    }
  }
  
  cat("\n📄 Detailed report available in logs/\n")
}
