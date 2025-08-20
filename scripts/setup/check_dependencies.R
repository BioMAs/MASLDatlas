# Script to check R package dependencies
# Run this to verify all required packages are available

cat("=== Checking R Package Dependencies ===\n")

# List of required packages from app.R
required_packages <- c(
  "shiny",
  "bslib", 
  "dplyr",
  "ggplot2",
  "shinydisconnect",
  "shinycssloaders",
  "shinyjs",
  "reticulate",
  "DT",
  "readr",
  "shinyBS",
  "ggpubr",
  "shinyWidgets",
  "fenr",
  "stringr",
  "jsonlite"
)

# Packages that are typically not available via conda
cran_only_packages <- c("shinydisconnect", "fenr")

missing_packages <- c()
available_packages <- c()

for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    available_packages <- c(available_packages, pkg)
    if (pkg %in% cran_only_packages) {
      cat("✅", pkg, "(CRAN only)\n")
    } else {
      cat("✅", pkg, "\n")
    }
  } else {
    missing_packages <- c(missing_packages, pkg)
    if (pkg %in% cran_only_packages) {
      cat("❌", pkg, "(CRAN only)\n")
    } else {
      cat("❌", pkg, "\n")
    }
  }
}

cat("\n=== Summary ===\n")
cat("Available packages:", length(available_packages), "/", length(required_packages), "\n")

if (length(missing_packages) > 0) {
  cat("❌ Missing packages:\n")
  conda_packages <- setdiff(missing_packages, cran_only_packages)
  cran_packages <- intersect(missing_packages, cran_only_packages)
  
  if (length(conda_packages) > 0) {
    cat("\n📦 Add to environment.yml (conda):\n")
    for (pkg in conda_packages) {
      cat("  - r-", tolower(pkg), "\n", sep = "")
    }
  }
  
  if (length(cran_packages) > 0) {
    cat("\n🔧 Install via CRAN in Dockerfile:\n")
    cat("install.packages(c(", paste0("'", cran_packages, "'", collapse = ", "), "))\n")
  }
} else {
  cat("✅ All required packages are available!\n")
}

cat("\n=== R Session Info ===\n")
print(sessionInfo())
