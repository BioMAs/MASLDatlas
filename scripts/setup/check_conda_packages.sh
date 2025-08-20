#!/bin/bash

# Script to check if R packages are available via conda-forge and r channels
# This helps prevent build failures due to missing packages

echo "=== Checking R Package Availability via Conda ==="
echo "Channels: conda-forge, r"
echo

# List of packages to check
packages=(
    "r-shiny"
    "r-bslib" 
    "r-dplyr"
    "r-ggplot2"
    "r-shinydisconnect"
    "r-shinycssloaders"
    "r-shinyjs"
    "r-reticulate"
    "r-dt"
    "r-readr"
    "r-shinybs"
    "r-ggpubr"
    "r-shinywidgets"
    "r-fenr"
    "r-stringr"
    "r-jsonlite"
)

available=()
not_available=()

echo "Checking packages..."
for pkg in "${packages[@]}"; do
    # Check if package exists in conda-forge or r channel
    if conda search -c conda-forge -c r "$pkg" &>/dev/null; then
        available+=("$pkg")
        echo "✅ $pkg"
    else
        not_available+=("$pkg")
        echo "❌ $pkg"
    fi
done

echo
echo "=== Summary ==="
echo "Available via conda: ${#available[@]}"
echo "Not available: ${#not_available[@]}"

if [ ${#not_available[@]} -gt 0 ]; then
    echo
    echo "❌ Packages NOT available via conda:"
    for pkg in "${not_available[@]}"; do
        echo "  - $pkg"
    done
    echo
    echo "💡 These packages should be installed via install.packages() in the Dockerfile"
    echo "   or removed from environment.yml and installed separately."
fi

echo
echo "✅ Packages available via conda can be included in environment.yml"
