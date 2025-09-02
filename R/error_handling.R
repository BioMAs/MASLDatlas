# 🛡️ MASLDatlas Error Handling and Configuration Module
# Robust error handling and configuration management
# Author: MASLDatlas Team
# Version: 1.0

# Enhanced configuration loader with fallback
load_datasets_config <- function(config_file = "config/datasets_config.json", 
                                 fallback_file = "config/datasets_config_safe.json") {
  
  # Try to load main configuration
  tryCatch({
    if (file.exists(config_file)) {
      config <- jsonlite::fromJSON(config_file)
      
      # Validate configuration structure
      if (is.list(config) && length(config) > 0) {
        cat("✅ Loaded main configuration:", config_file, "\n")
        return(config)
      } else {
        warning("Main configuration file is empty or invalid")
      }
    } else {
      warning("Main configuration file not found:", config_file)
    }
  }, error = function(e) {
    warning("Error loading main configuration:", e$message)
  })
  
  # Try fallback configuration
  tryCatch({
    if (file.exists(fallback_file)) {
      config <- jsonlite::fromJSON(fallback_file)
      
      if (is.list(config) && length(config) > 0) {
        cat("⚠️ Using fallback configuration:", fallback_file, "\n")
        return(config)
      }
    }
  }, error = function(e) {
    warning("Error loading fallback configuration:", e$message)
  })
  
  # Create minimal safe configuration
  cat("🚨 Creating minimal safe configuration\n")
  minimal_config <- list(
    "Human" = list("Datasets" = c()),
    "Mouse" = list("Datasets" = c()),
    "Zebrafish" = list("Datasets" = c()),
    "Integrated" = list("Datasets" = c())
  )
  
  return(minimal_config)
}

# Enhanced Python environment setup
setup_python_environment <- function(retry_count = 3) {
  for (attempt in 1:retry_count) {
    tryCatch({
      cat("🐍 Attempting Python setup (attempt", attempt, "of", retry_count, ")\n")
      
      # Check if we're in a conda environment
      if (Sys.getenv("CONDA_DEFAULT_ENV") != "") {
        reticulate::use_condaenv("fibrosis_shiny", required = TRUE)
        cat("🔧 Using conda environment: fibrosis_shiny\n")
      } else {
        reticulate::use_virtualenv("fibrosis_shiny")
        cat("🔧 Using virtual environment: fibrosis_shiny\n")
      }
      
      # Test import of critical modules
      sc <- reticulate::import("scanpy")
      dc <- reticulate::import("decoupler")
      
      # Optional modules
      pydeseq2_dds <- NULL
      pydeseq2_ds <- NULL
      
      tryCatch({
        pydeseq2_dds <- reticulate::import("pydeseq2.dds")
        pydeseq2_ds <- reticulate::import("pydeseq2.ds")
        cat("✅ PyDESeq2 modules loaded\n")
      }, error = function(e) {
        cat("⚠️ PyDESeq2 modules not available:", e$message, "\n")
      })
      
      cat("✅ Python environment setup successful\n")
      return(list(
        sc = sc,
        dc = dc,
        pydeseq2_dds = pydeseq2_dds,
        pydeseq2_ds = pydeseq2_ds,
        status = "success"
      ))
      
    }, error = function(e) {
      cat("❌ Python setup attempt", attempt, "failed:", e$message, "\n")
      if (attempt == retry_count) {
        cat("🚨 All Python setup attempts failed. Running with limited functionality.\n")
        return(list(
          sc = NULL,
          dc = NULL,
          pydeseq2_dds = NULL,
          pydeseq2_ds = NULL,
          status = "failed",
          error = e$message
        ))
      }
      Sys.sleep(2)  # Wait before retry
    })
  }
}

# Safe dataset file checker
check_dataset_file <- function(dataset_path, species = "Unknown") {
  if (!file.exists(dataset_path)) {
    return(list(
      exists = FALSE,
      error = paste("Dataset file not found:", dataset_path),
      species = species
    ))
  }
  
  file_info <- file.info(dataset_path)
  file_size_mb <- round(file_info$size / 1024 / 1024, 1)
  
  # Check if file is readable
  tryCatch({
    # Try to get file header without fully loading
    con <- file(dataset_path, "rb")
    header <- readBin(con, "raw", n = 100)
    close(con)
    
    return(list(
      exists = TRUE,
      size_mb = file_size_mb,
      readable = TRUE,
      species = species,
      path = dataset_path
    ))
  }, error = function(e) {
    return(list(
      exists = TRUE,
      size_mb = file_size_mb,
      readable = FALSE,
      error = paste("File not readable:", e$message),
      species = species
    ))
  })
}

# Enhanced notification system
show_enhanced_notification <- function(message, type = "default", duration = 5) {
  
  # Determine notification styling based on type
  css_class <- switch(type,
    "success" = "alert-success",
    "warning" = "alert-warning", 
    "error" = "alert-danger",
    "info" = "alert-info",
    "alert-secondary"  # default
  )
  
  icon_name <- switch(type,
    "success" = "check-circle",
    "warning" = "exclamation-triangle",
    "error" = "times-circle", 
    "info" = "info-circle",
    "bell"  # default
  )
  
  # Show notification with styling
  showNotification(
    ui = tags$div(
      class = paste("alert", css_class),
      tags$i(class = paste("fa fa-", icon_name)),
      " ",
      message
    ),
    duration = duration,
    type = "message"
  )
  
  # Log the notification
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0(timestamp, " [", toupper(type), "] ", message, "\n")
  
  # Ensure logs directory exists
  if (!dir.exists("logs")) {
    dir.create("logs", recursive = TRUE)
  }
  
  cat(log_entry, file = "logs/app_notifications.log", append = TRUE)
}

# Memory usage checker
check_memory_usage <- function() {
  tryCatch({
    if (requireNamespace("pryr", quietly = TRUE)) {
      mem_used <- pryr::mem_used()
      mem_mb <- as.numeric(mem_used) / 1024^2
      
      return(list(
        available = TRUE,
        usage_mb = round(mem_mb, 1),
        usage_gb = round(mem_mb / 1024, 2)
      ))
    } else {
      return(list(available = FALSE, message = "pryr package not available"))
    }
  }, error = function(e) {
    return(list(available = FALSE, error = e$message))
  })
}

# Application health status
get_app_health <- function() {
  health <- list(
    timestamp = Sys.time(),
    r_version = R.version.string,
    shiny_version = packageVersion("shiny"),
    status = "healthy",
    warnings = c(),
    errors = c()
  )
  
  # Check memory
  mem_check <- check_memory_usage()
  if (mem_check$available) {
    health$memory_mb <- mem_check$usage_mb
    if (mem_check$usage_mb > 8000) {  # 8GB threshold
      health$warnings <- c(health$warnings, "High memory usage detected")
    }
  }
  
  # Check datasets directory
  if (!dir.exists("datasets")) {
    health$warnings <- c(health$warnings, "Datasets directory not found")
  }
  
  # Check configuration
  if (!file.exists("config/datasets_config.json")) {
    health$warnings <- c(health$warnings, "Main configuration file missing")
  }
  
  # Set overall status
  if (length(health$errors) > 0) {
    health$status <- "unhealthy"
  } else if (length(health$warnings) > 0) {
    health$status <- "warning"
  }
  
  return(health)
}
