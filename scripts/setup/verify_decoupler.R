#!/usr/bin/env Rscript

cat("=== Verification de l'installation de decoupler ===\n")

# Charger reticulate
library(reticulate)

# Afficher la configuration Python
cat("Python utilise:", py_config()$python, "\n")

# Tester l'import de decoupler
tryCatch({
  dc <- import("decoupler")
  cat("✅ decoupler importe avec succes\n")
  cat("Version decoupler:", dc$`__version__`, "\n")
  
  # Tester les fonctions principales
  if (py_has_attr(dc, "run_ulm")) {
    cat("✅ Fonction run_ulm disponible\n")
  }
  
  if (py_has_attr(dc, "run_mlm")) {
    cat("✅ Fonction run_mlm disponible\n")
  }
  
  if (py_has_attr(dc, "get_ora_df")) {
    cat("✅ Fonction get_ora_df disponible\n")
  }
  
  if (py_has_attr(dc, "plot_barplot")) {
    cat("✅ Fonction plot_barplot disponible\n")
  }
  
  cat("🎉 Verification reussie !\n")
  
}, error = function(e) {
  cat("❌ Erreur:", e$message, "\n")
  cat("Essai d'installation de decoupler...\n")
  py_install("decoupler")
  py_install("omnipath") 
  py_install("scanpy")
})
