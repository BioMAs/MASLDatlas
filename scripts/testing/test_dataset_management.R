# Example script to test dataset management
# Run this script to test the new dataset management system

# Load the dataset management functions
source("dataset_manager.R")

# Display current configuration
cat("=== Current Dataset Configuration ===\n")
list_all_datasets()

# Example: Add a new human dataset
cat("\n=== Adding a new Human dataset ===\n")
add_dataset("Human", "Individual Dataset", "GSE123456")

# Example: Add a new category for mouse
cat("\n=== Adding a new Mouse dataset category ===\n")
add_dataset("Mouse", "Time Series", "GSE789012")

# Example: Add a new organism
cat("\n=== Adding a new organism ===\n")
add_dataset("Rat", "Liver Studies", "GSE111222")

# Display updated configuration
cat("\n=== Updated Dataset Configuration ===\n")
list_all_datasets()

# Example: Remove a dataset
cat("\n=== Removing the test Rat dataset ===\n")
remove_dataset("Rat", "Liver Studies", "GSE111222")

# Final configuration
cat("\n=== Final Dataset Configuration ===\n")
list_all_datasets()

cat("\n=== Test completed! ===\n")
cat("You can now run the Shiny app to see the updated dataset list.\n")
cat("Make sure to place the corresponding .h5ad files in the appropriate datasets/ subdirectories.\n")
