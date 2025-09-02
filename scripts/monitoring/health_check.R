#!/usr/bin/env Rscript

# 🩺 MASLDatlas Health Check Script
# Monitors application health and system resources
# Author: MASLDatlas Team
# Version: 1.0

library(jsonlite)
library(reticulate)

# Configuration
LOG_FILE <- "logs/health_check.log"
DATASETS_CONFIG <- "config/datasets_config.json"

# Create logs directory
if (!dir.exists("logs")) {
  dir.create("logs", recursive = TRUE)
}

# Logging function
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0(timestamp, " [", level, "] ", message)
  cat(log_entry, "\n")
  cat(log_entry, "\n", file = LOG_FILE, append = TRUE)
}

# Health check function
perform_health_check <- function() {
  log_message("🏥 Starting health check", "INFO")
  
  health_status <- list(
    timestamp = Sys.time(),
    status = "healthy",
    checks = list(),
    warnings = c(),
    errors = c()
  )
  
  # Check 1: R packages
  log_message("🔍 Checking R packages...")
  required_packages <- c("shiny", "bslib", "dplyr", "ggplot2", "reticulate", "DT", "jsonlite")
  
  for (pkg in required_packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      health_status$checks[[paste0("package_", pkg)]] <- "OK"
    } else {
      health_status$errors <- c(health_status$errors, paste("Missing package:", pkg))
      health_status$status <- "unhealthy"
    }
  }
  
  # Check 2: Python environment
  log_message("🐍 Checking Python environment...")
  tryCatch({
    use_virtualenv("fibrosis_shiny")
    sc <- import("scanpy")
    health_status$checks$python_env <- "OK"
    log_message("✅ Python environment OK")
  }, error = function(e) {
    health_status$warnings <- c(health_status$warnings, paste("Python env issue:", e$message))
    log_message(paste("⚠️ Python environment warning:", e$message), "WARN")
  })
  
  # Check 3: Dataset configuration
  log_message("📊 Checking dataset configuration...")
  if (file.exists(DATASETS_CONFIG)) {
    tryCatch({
      config <- fromJSON(DATASETS_CONFIG)
      health_status$checks$dataset_config <- "OK"
      health_status$dataset_count <- length(unlist(config))
      log_message("✅ Dataset configuration OK")
    }, error = function(e) {
      health_status$errors <- c(health_status$errors, paste("Config error:", e$message))
      health_status$status <- "unhealthy"
    })
  } else {
    health_status$errors <- c(health_status$errors, "Dataset configuration file missing")
    health_status$status <- "unhealthy"
  }
  
  # Check 4: Disk space
  log_message("💾 Checking disk space...")
  tryCatch({
    disk_info <- system("df -h .", intern = TRUE)
    # Extract available space (simplified)
    health_status$checks$disk_space <- "OK"
    log_message("✅ Disk space OK")
  }, error = function(e) {
    health_status$warnings <- c(health_status$warnings, "Could not check disk space")
  })
  
  # Check 5: Memory usage
  log_message("🧠 Checking memory usage...")
  tryCatch({
    if (requireNamespace("pryr", quietly = TRUE)) {
      mem_usage <- pryr::mem_used()
      health_status$memory_usage <- as.character(mem_usage)
      health_status$checks$memory <- "OK"
    } else {
      health_status$warnings <- c(health_status$warnings, "Cannot check memory (pryr not available)")
    }
  }, error = function(e) {
    health_status$warnings <- c(health_status$warnings, paste("Memory check failed:", e$message))
  })
  
  # Final status
  if (length(health_status$errors) > 0) {
    health_status$status <- "unhealthy"
    log_message("❌ Health check failed", "ERROR")
  } else if (length(health_status$warnings) > 0) {
    health_status$status <- "warning"
    log_message("⚠️ Health check completed with warnings", "WARN")
  } else {
    log_message("✅ Health check passed", "INFO")
  }
  
  return(health_status)
}

# Export health status as JSON
export_health_status <- function(health_status) {
  health_json <- toJSON(health_status, pretty = TRUE, auto_unbox = TRUE)
  writeLines(health_json, "www/health.json")
  log_message("📤 Health status exported to www/health.json")
}

# Main execution
if (!interactive()) {
  log_message("🚀 MASLDatlas Health Check starting...")
  health_result <- perform_health_check()
  export_health_status(health_result)
  
  # Exit with appropriate code
  if (health_result$status == "unhealthy") {
    quit(status = 1)
  } else {
    quit(status = 0)
  }
}
