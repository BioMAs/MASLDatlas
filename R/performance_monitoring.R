# Performance Monitoring and Analytics Module
# Real-time performance monitoring for MASLDatlas application

#' Performance monitoring system
performance_monitor <- new.env(parent = emptyenv())

#' Initialize performance monitoring
initialize_performance_monitoring <- function() {
  performance_monitor$start_time <- Sys.time()
  performance_monitor$operations <- list()
  performance_monitor$memory_snapshots <- list()
  performance_monitor$warnings <- list()
  
  cat("📊 Performance monitoring initialized\n")
}

#' Log operation performance
#' @param operation_name Name of the operation
#' @param start_time Start time of operation
#' @param end_time End time of operation
#' @param memory_used Memory used during operation
#' @param additional_data Additional performance data
log_operation_performance <- function(operation_name, start_time, end_time, 
                                    memory_used = NULL, additional_data = NULL) {
  
  duration_seconds <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  operation_data <- list(
    name = operation_name,
    start_time = start_time,
    end_time = end_time,
    duration_seconds = duration_seconds,
    memory_used_mb = memory_used,
    additional_data = additional_data,
    timestamp = Sys.time()
  )
  
  # Store in monitoring system
  performance_monitor$operations[[length(performance_monitor$operations) + 1]] <- operation_data
  
  # Log to console
  memory_text <- if (!is.null(memory_used)) sprintf(" (%.1f MB)", memory_used) else ""
  cat(sprintf("⏱️ %s: %.2f seconds%s\n", operation_name, duration_seconds, memory_text))
  
  # Check for performance issues
  check_performance_thresholds(operation_data)
}

#' Monitor function execution with automatic logging
#' @param func Function to monitor
#' @param operation_name Name for logging
#' @param ... Arguments to pass to the function
monitor_execution <- function(func, operation_name, ...) {
  start_time <- Sys.time()
  start_memory <- get_current_memory_usage()
  
  tryCatch({
    result <- func(...)
    end_time <- Sys.time()
    end_memory <- get_current_memory_usage()
    
    memory_diff <- if (!is.null(start_memory) && !is.null(end_memory)) {
      end_memory - start_memory
    } else NULL
    
    log_operation_performance(operation_name, start_time, end_time, memory_diff)
    
    return(result)
    
  }, error = function(e) {
    end_time <- Sys.time()
    log_operation_performance(paste(operation_name, "(FAILED)"), start_time, end_time)
    stop(e)
  })
}

#' Get current memory usage
get_current_memory_usage <- function() {
  tryCatch({
    if (requireNamespace("pryr", quietly = TRUE)) {
      return(as.numeric(pryr::mem_used()) / 1024^2)  # Convert to MB
    } else {
      return(NULL)
    }
  }, error = function(e) {
    return(NULL)
  })
}

#' Check performance thresholds and issue warnings
#' @param operation_data Operation performance data
check_performance_thresholds <- function(operation_data) {
  thresholds <- list(
    slow_operation = 10,      # seconds
    memory_intensive = 500,   # MB
    very_slow = 30           # seconds
  )
  
  warnings <- c()
  
  # Check duration thresholds
  if (operation_data$duration_seconds > thresholds$very_slow) {
    warning_msg <- sprintf("⚠️ Very slow operation: %s took %.1f seconds", 
                          operation_data$name, operation_data$duration_seconds)
    warnings <- c(warnings, warning_msg)
    
  } else if (operation_data$duration_seconds > thresholds$slow_operation) {
    warning_msg <- sprintf("⏳ Slow operation: %s took %.1f seconds", 
                          operation_data$name, operation_data$duration_seconds)
    warnings <- c(warnings, warning_msg)
  }
  
  # Check memory thresholds
  if (!is.null(operation_data$memory_used_mb) && 
      operation_data$memory_used_mb > thresholds$memory_intensive) {
    warning_msg <- sprintf("💾 Memory intensive operation: %s used %.1f MB", 
                          operation_data$name, operation_data$memory_used_mb)
    warnings <- c(warnings, warning_msg)
  }
  
  # Store warnings
  if (length(warnings) > 0) {
    performance_monitor$warnings <- c(performance_monitor$warnings, warnings)
    for (warning in warnings) {
      cat(warning, "\n")
    }
  }
}

#' Generate performance report
generate_performance_report <- function() {
  if (length(performance_monitor$operations) == 0) {
    return("No operations recorded yet.")
  }
  
  operations_df <- do.call(rbind, lapply(performance_monitor$operations, function(op) {
    data.frame(
      operation = op$name,
      duration_seconds = op$duration_seconds,
      memory_mb = ifelse(is.null(op$memory_used_mb), NA, op$memory_used_mb),
      timestamp = as.character(op$timestamp),
      stringsAsFactors = FALSE
    )
  }))
  
  # Calculate summary statistics
  total_operations <- nrow(operations_df)
  avg_duration <- mean(operations_df$duration_seconds, na.rm = TRUE)
  max_duration <- max(operations_df$duration_seconds, na.rm = TRUE)
  slowest_operation <- operations_df$operation[which.max(operations_df$duration_seconds)]
  
  avg_memory <- mean(operations_df$memory_mb, na.rm = TRUE)
  max_memory <- max(operations_df$memory_mb, na.rm = TRUE)
  
  # Create report
  report <- list(
    summary = list(
      total_operations = total_operations,
      average_duration = avg_duration,
      maximum_duration = max_duration,
      slowest_operation = slowest_operation,
      average_memory_mb = avg_memory,
      maximum_memory_mb = max_memory,
      total_warnings = length(performance_monitor$warnings)
    ),
    operations = operations_df,
    warnings = performance_monitor$warnings,
    session_duration = as.numeric(difftime(Sys.time(), performance_monitor$start_time, units = "mins"))
  )
  
  return(report)
}

#' Print performance summary
print_performance_summary <- function() {
  report <- generate_performance_report()
  
  if (is.character(report)) {
    cat(report, "\n")
    return()
  }
  
  cat("📊 PERFORMANCE SUMMARY\n")
  cat("=====================\n")
  cat(sprintf("Session Duration: %.1f minutes\n", report$session_duration))
  cat(sprintf("Total Operations: %d\n", report$summary$total_operations))
  cat(sprintf("Average Duration: %.2f seconds\n", report$summary$average_duration))
  cat(sprintf("Maximum Duration: %.2f seconds (%s)\n", 
              report$summary$maximum_duration, report$summary$slowest_operation))
  
  if (!is.na(report$summary$average_memory_mb)) {
    cat(sprintf("Average Memory: %.1f MB\n", report$summary$average_memory_mb))
    cat(sprintf("Maximum Memory: %.1f MB\n", report$summary$maximum_memory_mb))
  }
  
  cat(sprintf("Total Warnings: %d\n", report$summary$total_warnings))
  
  if (report$summary$total_warnings > 0) {
    cat("\n⚠️ Recent Warnings:\n")
    recent_warnings <- tail(report$warnings, 5)
    for (warning in recent_warnings) {
      cat(sprintf("  - %s\n", warning))
    }
  }
  
  cat("\n")
}

#' Real-time performance dashboard data
get_dashboard_data <- function() {
  current_memory <- get_current_memory_usage()
  
  # Get recent operations (last 10)
  recent_ops <- tail(performance_monitor$operations, 10)
  
  # Calculate trends
  if (length(recent_ops) >= 2) {
    durations <- sapply(recent_ops, function(op) op$duration_seconds)
    memory_usage <- sapply(recent_ops, function(op) op$memory_used_mb %||% 0)
    
    avg_duration_trend <- mean(tail(durations, 5)) - mean(head(durations, 5))
    avg_memory_trend <- mean(tail(memory_usage, 5)) - mean(head(memory_usage, 5))
  } else {
    avg_duration_trend <- 0
    avg_memory_trend <- 0
  }
  
  return(list(
    current_memory_mb = current_memory,
    recent_operations = length(recent_ops),
    duration_trend = avg_duration_trend,
    memory_trend = avg_memory_trend,
    active_warnings = length(performance_monitor$warnings),
    uptime_minutes = as.numeric(difftime(Sys.time(), performance_monitor$start_time, units = "mins"))
  ))
}

#' Automatic cleanup of old performance data
cleanup_performance_data <- function(max_operations = 100, max_warnings = 50) {
  # Keep only the most recent operations
  if (length(performance_monitor$operations) > max_operations) {
    performance_monitor$operations <- tail(performance_monitor$operations, max_operations)
    cat(sprintf("🧹 Cleaned old performance data, kept %d recent operations\n", max_operations))
  }
  
  # Keep only the most recent warnings
  if (length(performance_monitor$warnings) > max_warnings) {
    performance_monitor$warnings <- tail(performance_monitor$warnings, max_warnings)
    cat(sprintf("🧹 Cleaned old warnings, kept %d recent warnings\n", max_warnings))
  }
}

#' Helper function for null coalescing
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Benchmark comparison system
create_benchmark <- function(operation_name, target_duration = NULL, target_memory = NULL) {
  benchmark <- list(
    operation_name = operation_name,
    target_duration = target_duration,
    target_memory = target_memory,
    results = list(),
    created = Sys.time()
  )
  
  class(benchmark) <- "performance_benchmark"
  return(benchmark)
}

#' Run benchmark test
run_benchmark <- function(benchmark, test_function, ...) {
  start_time <- Sys.time()
  start_memory <- get_current_memory_usage()
  
  result <- test_function(...)
  
  end_time <- Sys.time()
  end_memory <- get_current_memory_usage()
  
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  memory_used <- if (!is.null(start_memory) && !is.null(end_memory)) {
    end_memory - start_memory
  } else NULL
  
  # Store result
  test_result <- list(
    duration = duration,
    memory_used = memory_used,
    timestamp = Sys.time(),
    passed_duration = if (!is.null(benchmark$target_duration)) {
      duration <= benchmark$target_duration
    } else TRUE,
    passed_memory = if (!is.null(benchmark$target_memory) && !is.null(memory_used)) {
      memory_used <= benchmark$target_memory
    } else TRUE
  )
  
  benchmark$results[[length(benchmark$results) + 1]] <- test_result
  
  # Print results
  cat(sprintf("🏁 Benchmark '%s': %.2f seconds", benchmark$operation_name, duration))
  if (!is.null(memory_used)) {
    cat(sprintf(", %.1f MB memory", memory_used))
  }
  
  if (!test_result$passed_duration || !test_result$passed_memory) {
    cat(" ❌ FAILED")
  } else {
    cat(" ✅ PASSED")
  }
  cat("\n")
  
  return(benchmark)
}

#' Performance optimization suggestions
get_optimization_suggestions <- function() {
  report <- generate_performance_report()
  suggestions <- c()
  
  if (is.character(report)) {
    return("Collect more performance data first.")
  }
  
  # Analyze patterns
  if (report$summary$maximum_duration > 30) {
    suggestions <- c(suggestions, 
                    "🐌 Consider implementing data caching for operations taking > 30 seconds")
  }
  
  if (!is.na(report$summary$maximum_memory_mb) && report$summary$maximum_memory_mb > 1000) {
    suggestions <- c(suggestions,
                    "💾 Consider implementing memory optimization for operations using > 1GB")
  }
  
  if (report$summary$total_warnings > 10) {
    suggestions <- c(suggestions,
                    "⚠️ High number of performance warnings - review slow operations")
  }
  
  # Check for repeated slow operations
  if (nrow(report$operations) > 0) {
    slow_ops <- report$operations[report$operations$duration_seconds > 10, ]
    if (nrow(slow_ops) > 0) {
      slow_counts <- table(slow_ops$operation)
      repeated_slow <- slow_counts[slow_counts > 2]
      
      if (length(repeated_slow) > 0) {
        suggestions <- c(suggestions,
                        sprintf("🔄 Optimize frequently slow operations: %s", 
                               paste(names(repeated_slow), collapse = ", ")))
      }
    }
  }
  
  if (length(suggestions) == 0) {
    suggestions <- "✅ Performance looks good! No immediate optimizations needed."
  }
  
  return(suggestions)
}

# Initialize monitoring when module is loaded
if (!exists("performance_monitor") || is.null(performance_monitor$start_time)) {
  initialize_performance_monitoring()
}
