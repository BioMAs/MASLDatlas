#!/usr/bin/env Rscript

# Test script to verify all R packages load correctly
# This can be run inside the Docker container to check the environment

cat("=== Testing R Package Loading ===\n")

# List of all required packages
packages <- c(
  "shiny", "bslib", "dplyr", "ggplot2", "shinycssloaders", 
  "shinyjs", "reticulate", "DT", "readr", "shinyBS", 
  "ggpubr", "shinyWidgets", "stringr", "jsonlite"
)

# Optional packages
optional_packages <- c("fenr", "shinydisconnect")

# Test required packages
cat("\n--- Testing Required Packages ---\n")
failed_packages <- c()

for (pkg in packages) {
  tryCatch({
    library(pkg, character.only = TRUE)
    cat("✅", pkg, "\n")
  }, error = function(e) {
    cat("❌", pkg, "- ERROR:", e$message, "\n")
    failed_packages <<- c(failed_packages, pkg)
  })
}

# Test optional packages
cat("\n--- Testing Optional Packages ---\n")
for (pkg in optional_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✅", pkg, "(optional)\n")
  } else {
    cat("⚠️ ", pkg, "(optional - not available)\n")
  }
}

# Test Python environment
cat("\n--- Testing Python Environment ---\n")
tryCatch({
  reticulate::use_virtualenv("fibrosis_shiny")
  sc <- reticulate::import("scanpy")
  dc <- reticulate::import("decoupler")
  cat("✅ Python environment and packages loaded successfully\n")
}, error = function(e) {
  cat("❌ Python environment error:", e$message, "\n")
})

# Summary
cat("\n=== Summary ===\n")
if (length(failed_packages) == 0) {
  cat("✅ All required packages loaded successfully!\n")
  cat("📦 Ready to run MASLDatlas application\n")
} else {
  cat("❌ Failed packages:", paste(failed_packages, collapse = ", "), "\n")
  cat("🔧 Please check package installation\n")
}

cat("\n=== R Session Info ===\n")
print(sessionInfo())
