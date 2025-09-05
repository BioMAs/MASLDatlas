#!/usr/bin/env Rscript

# Script specifically for installing and testing fenr package
cat("=== Installing fenr package for enrichment analysis ===\n")

# Check if remotes is available
if (!require('remotes', quietly = TRUE)) {
  cat("Installing remotes package...\n")
  install.packages('remotes', repos='https://cran.r-project.org')
}

# Try multiple installation methods for fenr
install_fenr <- function() {
  # Method 1: Try CRAN first
  cat("Method 1: Trying CRAN installation...\n")
  tryCatch({
    install.packages('fenr', repos='https://cran.r-project.org', dependencies=TRUE)
    if (require('fenr', quietly = TRUE)) {
      cat("✅ fenr successfully installed from CRAN\n")
      return(TRUE)
    }
  }, error = function(e) {
    cat("❌ CRAN installation failed:", e$message, "\n")
  })
  
  # Method 2: Try GitHub if CRAN failed
  cat("Method 2: Trying GitHub installation...\n")
  tryCatch({
    remotes::install_github('bartongroup/fenr', force = TRUE, dependencies = TRUE)
    if (require('fenr', quietly = TRUE)) {
      cat("✅ fenr successfully installed from GitHub\n")
      return(TRUE)
    }
  }, error = function(e) {
    cat("❌ GitHub installation failed:", e$message, "\n")
  })
  
  # Method 3: Try with different options
  cat("Method 3: Trying with upgrade dependencies...\n")
  tryCatch({
    install.packages('fenr', repos='https://cran.r-project.org', dependencies=TRUE, 
                     type = "both", Ncpus = 2)
    if (require('fenr', quietly = TRUE)) {
      cat("✅ fenr successfully installed with dependencies upgrade\n")
      return(TRUE)
    }
  }, error = function(e) {
    cat("❌ Dependencies upgrade installation failed:", e$message, "\n")
  })
  
  return(FALSE)
}

# Test fenr functionality
test_fenr <- function() {
  if (!require('fenr', quietly = TRUE)) {
    cat("❌ fenr package not available for testing\n")
    return(FALSE)
  }
  
  cat("Testing fenr functionality...\n")
  tryCatch({
    # Test basic fenr functions
    cat("- Testing prepare_for_enrichment function... ")
    if (exists("prepare_for_enrichment", where = asNamespace("fenr"))) {
      cat("✅ Available\n")
    } else {
      cat("❌ Not found\n")
      return(FALSE)
    }
    
    cat("- Testing functional_enrichment function... ")
    if (exists("functional_enrichment", where = asNamespace("fenr"))) {
      cat("✅ Available\n")
    } else {
      cat("❌ Not found\n")
      return(FALSE)
    }
    
    cat("✅ fenr package is functional\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ Error testing fenr:", e$message, "\n")
    return(FALSE)
  })
}

# Main execution
success <- install_fenr()
if (success) {
  test_success <- test_fenr()
  if (test_success) {
    cat("🎉 fenr installation and testing completed successfully!\n")
  } else {
    cat("⚠️ fenr installed but functionality test failed\n")
  }
} else {
  cat("❌ Failed to install fenr package\n")
  cat("Enrichment analysis will be disabled in the application\n")
}

# Final status
cat("\n=== Installation Summary ===\n")
cat("fenr package available:", require('fenr', quietly = TRUE), "\n")
if (require('fenr', quietly = TRUE)) {
  cat("fenr version:", packageVersion('fenr'), "\n")
}
