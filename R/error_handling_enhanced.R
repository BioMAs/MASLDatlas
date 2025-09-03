# Error Handling and Robustness Module
# Enhanced error handling and fallback mechanisms for MASLDatlas

#' Enhanced Python environment validation
#' @param env_name Conda environment name
#' @param required_packages List of required Python packages
validate_python_environment <- function(env_name = "fibrosis_shiny", 
                                       required_packages = c("scanpy", "decoupler", "pydeseq2")) {
  
  validation_results <- list(
    environment_status = "unknown",
    packages_status = list(),
    recommendations = c(),
    can_proceed = FALSE
  )
  
  # Check if reticulate is available
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    validation_results$environment_status <- "reticulate_missing"
    validation_results$recommendations <- c("Install reticulate package: install.packages('reticulate')")
    return(validation_results)
  }
  
  # Check conda environment
  tryCatch({
    reticulate::use_condaenv(env_name, required = FALSE)
    
    # Test if Python is available
    if (reticulate::py_available()) {
      validation_results$environment_status <- "available"
      
      # Check each required package
      for (pkg in required_packages) {
        pkg_status <- tryCatch({
          reticulate::import(pkg)
          "available"
        }, error = function(e) {
          "missing"
        })
        
        validation_results$packages_status[[pkg]] <- pkg_status
        
        if (pkg_status == "missing") {
          validation_results$recommendations <- c(
            validation_results$recommendations,
            sprintf("Install missing package: conda install -n %s %s", env_name, pkg)
          )
        }
      }
      
      # Check if all packages are available
      all_packages_available <- all(sapply(validation_results$packages_status, function(x) x == "available"))
      validation_results$can_proceed <- all_packages_available
      
    } else {
      validation_results$environment_status <- "python_unavailable"
      validation_results$recommendations <- c("Python interpreter not available in conda environment")
    }
    
  }, error = function(e) {
    validation_results$environment_status <- "conda_error"
    validation_results$recommendations <- c(
      sprintf("Conda environment '%s' not found or inaccessible", env_name),
      sprintf("Create environment: conda env create -f config/environment.yml"),
      sprintf("Error details: %s", e$message)
    )
  })
  
  return(validation_results)
}

#' Initialize Python environment with fallback options
#' @param primary_env Primary conda environment
#' @param fallback_envs List of fallback environments
#' @param install_missing Whether to attempt installation of missing packages
initialize_python_environment <- function(primary_env = "fibrosis_shiny",
                                         fallback_envs = c("base", "r-reticulate"),
                                         install_missing = FALSE) {
  
  initialization_log <- list()
  
  # Try primary environment
  cat("🐍 Initializing Python environment...\n")
  primary_result <- validate_python_environment(primary_env)
  initialization_log$primary <- primary_result
  
  if (primary_result$can_proceed) {
    cat("✅ Primary Python environment ready\n")
    
    # Import modules with error handling
    modules <- safely_import_python_modules()
    initialization_log$modules <- modules
    
    return(list(
      status = "success",
      environment = primary_env,
      modules = modules,
      log = initialization_log
    ))
  }
  
  # Try fallback environments
  cat("⚠️ Primary environment not ready, trying fallbacks...\n")
  for (fallback_env in fallback_envs) {
    cat(sprintf("  Trying: %s\n", fallback_env))
    
    fallback_result <- validate_python_environment(fallback_env)
    initialization_log[[paste0("fallback_", fallback_env)]] <- fallback_result
    
    if (fallback_result$can_proceed) {
      cat(sprintf("✅ Using fallback environment: %s\n", fallback_env))
      
      modules <- safely_import_python_modules()
      return(list(
        status = "fallback_success",
        environment = fallback_env,
        modules = modules,
        log = initialization_log
      ))
    }
  }
  
  # If installation is allowed, try to fix the primary environment
  if (install_missing && primary_result$environment_status == "available") {
    cat("🔧 Attempting to install missing packages...\n")
    
    missing_packages <- names(primary_result$packages_status)[
      sapply(primary_result$packages_status, function(x) x == "missing")
    ]
    
    if (length(missing_packages) > 0) {
      install_result <- attempt_package_installation(primary_env, missing_packages)
      initialization_log$installation_attempt <- install_result
      
      if (install_result$success) {
        modules <- safely_import_python_modules()
        return(list(
          status = "fixed_and_ready",
          environment = primary_env,
          modules = modules,
          log = initialization_log
        ))
      }
    }
  }
  
  # All attempts failed
  cat("❌ Failed to initialize Python environment\n")
  return(list(
    status = "failed",
    environment = NULL,
    modules = NULL,
    log = initialization_log,
    recommendations = primary_result$recommendations
  ))
}

#' Safely import Python modules with fallbacks
safely_import_python_modules <- function() {
  modules <- list()
  
  module_configs <- list(
    sc = list(name = "scanpy", required = TRUE),
    dc = list(name = "decoupler", required = TRUE),
    pydeseq2_dds = list(name = "pydeseq2.dds", required = FALSE),
    pydeseq2_ds = list(name = "pydeseq2.ds", required = FALSE)
  )
  
  for (module_key in names(module_configs)) {
    config <- module_configs[[module_key]]
    
    tryCatch({
      module <- reticulate::import(config$name)
      modules[[module_key]] <- module
      cat(sprintf("✅ Imported: %s\n", config$name))
    }, error = function(e) {
      if (config$required) {
        cat(sprintf("❌ Failed to import required module: %s\n", config$name))
        modules[[module_key]] <- NULL
      } else {
        cat(sprintf("⚠️ Optional module not available: %s\n", config$name))
        modules[[module_key]] <- NULL
      }
    })
  }
  
  return(modules)
}

#' Attempt to install missing Python packages
#' @param env_name Environment name
#' @param packages List of packages to install
attempt_package_installation <- function(env_name, packages) {
  installation_results <- list(
    success = FALSE,
    installed_packages = c(),
    failed_packages = c(),
    errors = c()
  )
  
  for (pkg in packages) {
    cat(sprintf("  Installing %s...\n", pkg))
    
    install_cmd <- sprintf("conda install -n %s -y %s", env_name, pkg)
    
    tryCatch({
      result <- system(install_cmd, intern = TRUE, ignore.stderr = TRUE)
      
      # Test if package is now available
      test_import <- tryCatch({
        reticulate::import(pkg)
        TRUE
      }, error = function(e) FALSE)
      
      if (test_import) {
        installation_results$installed_packages <- c(installation_results$installed_packages, pkg)
        cat(sprintf("    ✅ Successfully installed: %s\n", pkg))
      } else {
        installation_results$failed_packages <- c(installation_results$failed_packages, pkg)
        cat(sprintf("    ❌ Installation failed: %s\n", pkg))
      }
      
    }, error = function(e) {
      installation_results$failed_packages <- c(installation_results$failed_packages, pkg)
      installation_results$errors <- c(installation_results$errors, e$message)
      cat(sprintf("    ❌ Installation error for %s: %s\n", pkg, e$message))
    })
  }
  
  installation_results$success <- length(installation_results$failed_packages) == 0
  return(installation_results)
}

#' Enhanced dataset loading with multiple fallback strategies
#' @param organism Organism name
#' @param dataset Dataset name
#' @param size_option Size option for large datasets
#' @param fallback_strategies List of fallback strategies
load_dataset_with_fallbacks <- function(organism, dataset, size_option = NULL, 
                                       fallback_strategies = c("optimized", "subset", "cached")) {
  
  loading_log <- list()
  
  # Primary dataset path
  primary_path <- construct_dataset_path(organism, dataset, size_option)
  loading_log$primary_path <- primary_path
  
  # Try primary path
  if (file.exists(primary_path$path)) {
    cat(sprintf("📂 Loading from primary path: %s\n", basename(primary_path$path)))
    
    tryCatch({
      data <- load_dataset_safely(primary_path$path)
      loading_log$method <- "primary"
      loading_log$success <- TRUE
      
      return(list(
        data = data,
        method = "primary",
        log = loading_log
      ))
      
    }, error = function(e) {
      cat(sprintf("❌ Primary loading failed: %s\n", e$message))
      loading_log$primary_error <- e$message
    })
  }
  
  # Try fallback strategies
  for (strategy in fallback_strategies) {
    cat(sprintf("🔄 Trying fallback strategy: %s\n", strategy))
    
    fallback_result <- tryCatch({
      switch(strategy,
        "optimized" = load_optimized_version(organism, dataset),
        "subset" = load_subset_version(organism, dataset),
        "cached" = load_from_cache(organism, dataset),
        NULL
      )
    }, error = function(e) {
      cat(sprintf("  Strategy %s failed: %s\n", strategy, e$message))
      NULL
    })
    
    if (!is.null(fallback_result)) {
      loading_log$method <- strategy
      loading_log$success <- TRUE
      
      return(list(
        data = fallback_result,
        method = strategy,
        log = loading_log
      ))
    }
  }
  
  # All strategies failed
  loading_log$success <- FALSE
  cat("❌ All loading strategies failed\n")
  
  return(list(
    data = NULL,
    method = "failed",
    log = loading_log,
    error = "Unable to load dataset with any available method"
  ))
}

#' Safely load dataset with memory monitoring
#' @param file_path Path to dataset file
load_dataset_safely <- function(file_path) {
  # Check available memory before loading
  initial_memory <- check_available_memory()
  file_size_gb <- file.size(file_path) / 1024^3
  
  if (file_size_gb > initial_memory$available_gb * 0.5) {
    warning(sprintf("Dataset (%.1f GB) may exceed available memory (%.1f GB)", 
                   file_size_gb, initial_memory$available_gb))
  }
  
  # Monitor loading process
  start_time <- Sys.time()
  cat(sprintf("📊 Loading dataset: %.1f GB\n", file_size_gb))
  
  # Use global sc module if available
  if (exists("sc", envir = .GlobalEnv) && !is.null(get("sc", envir = .GlobalEnv))) {
    sc <- get("sc", envir = .GlobalEnv)
    data <- sc$read_h5ad(file_path)
  } else {
    stop("Python scanpy module not available")
  }
  
  load_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  cat(sprintf("✅ Loaded in %.1f seconds\n", load_time))
  
  return(data)
}

#' Check available system memory
check_available_memory <- function() {
  memory_info <- list(
    total_gb = 0,
    available_gb = 0,
    used_gb = 0,
    status = "unknown"
  )
  
  tryCatch({
    # Try different methods to get memory info
    if (Sys.info()["sysname"] == "Darwin") {  # macOS
      # Use vm_stat for macOS
      vm_output <- system("vm_stat", intern = TRUE)
      # Parse output (simplified)
      memory_info$status <- "estimated"
      memory_info$available_gb <- 8  # Default estimate
    } else if (Sys.info()["sysname"] == "Linux") {
      # Use /proc/meminfo for Linux
      meminfo <- readLines("/proc/meminfo")
      # Parse meminfo (simplified)
      memory_info$status <- "available"
    } else {
      # Windows or other
      memory_info$status <- "unsupported"
    }
    
    if (requireNamespace("pryr", quietly = TRUE)) {
      memory_info$used_gb <- as.numeric(pryr::mem_used()) / 1024^3
    }
    
  }, error = function(e) {
    memory_info$status <- "error"
  })
  
  return(memory_info)
}

#' Enhanced error notification system
#' @param error_message Error message
#' @param error_type Type of error
#' @param context Context where error occurred
#' @param suggested_actions Suggested user actions
show_enhanced_error <- function(error_message, error_type = "general", 
                               context = "", suggested_actions = NULL) {
  
  # Create structured error message
  full_message <- error_message
  
  if (context != "") {
    full_message <- paste0("Context: ", context, "\n", full_message)
  }
  
  if (!is.null(suggested_actions) && length(suggested_actions) > 0) {
    actions_text <- paste0("💡 Suggestions:\n", paste(suggested_actions, collapse = "\n"))
    full_message <- paste0(full_message, "\n\n", actions_text)
  }
  
  # Log error for debugging
  cat(sprintf("🔥 ERROR [%s]: %s\n", error_type, error_message))
  
  # Show user notification
  if (exists("showNotification")) {
    showNotification(
      full_message,
      type = "error",
      duration = 15
    )
  }
  
  return(list(
    message = full_message,
    type = error_type,
    context = context,
    timestamp = Sys.time()
  ))
}

#' Graceful degradation handler
#' @param primary_function Primary function to execute
#' @param fallback_function Fallback function
#' @param error_message Custom error message
graceful_fallback <- function(primary_function, fallback_function = NULL, 
                             error_message = "Primary function failed") {
  
  tryCatch({
    result <- primary_function()
    return(list(
      success = TRUE,
      result = result,
      method = "primary"
    ))
    
  }, error = function(e) {
    cat(sprintf("⚠️ Primary function failed: %s\n", e$message))
    
    if (!is.null(fallback_function)) {
      tryCatch({
        fallback_result <- fallback_function()
        cat("✅ Fallback function succeeded\n")
        
        return(list(
          success = TRUE,
          result = fallback_result,
          method = "fallback",
          primary_error = e$message
        ))
        
      }, error = function(e2) {
        cat(sprintf("❌ Fallback also failed: %s\n", e2$message))
        
        return(list(
          success = FALSE,
          result = NULL,
          method = "failed",
          primary_error = e$message,
          fallback_error = e2$message
        ))
      })
    } else {
      return(list(
        success = FALSE,
        result = NULL,
        method = "failed",
        primary_error = e$message
      ))
    }
  })
}

#' Helper functions for fallback loading strategies
load_optimized_version <- function(organism, dataset) {
  optimized_path <- file.path("datasets_optimized", paste0(dataset, "_sub10k.h5ad"))
  if (file.exists(optimized_path)) {
    return(load_dataset_safely(optimized_path))
  }
  stop("Optimized version not found")
}

load_subset_version <- function(organism, dataset) {
  subset_path <- file.path("datasets_optimized", paste0(dataset, "_sub5k.h5ad"))
  if (file.exists(subset_path)) {
    return(load_dataset_safely(subset_path))
  }
  stop("Subset version not found")
}

load_from_cache <- function(organism, dataset) {
  cache_key <- paste(organism, dataset, sep = "_")
  cached_data <- get_cached_dataset(cache_key)
  if (!is.null(cached_data)) {
    return(cached_data)
  }
  stop("No cached version available")
}

construct_dataset_path <- function(organism, dataset, size_option = NULL) {
  base_path <- file.path("datasets", paste0(dataset, ".h5ad"))
  
  if (!is.null(size_option) && size_option != "full") {
    optimized_path <- file.path("datasets_optimized", paste0(dataset, "_", size_option, ".h5ad"))
    return(list(path = optimized_path, type = "optimized"))
  }
  
  return(list(path = base_path, type = "standard"))
}
