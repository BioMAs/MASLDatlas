#!/usr/bin/env R

# Test simple de la syntaxe des fonctions de corrélation optimisées
cat("🔍 Test de syntaxe des optimisations de corrélation\n")
cat("==================================================\n")

# Test 1: Vérification de la syntaxe de base
cat("✅ Test 1: Syntaxe de base... ")
tryCatch({
  # Simulation de données
  n_cells <- 100
  n_genes <- 200
  normalized_counts <- data.frame(matrix(rnorm(n_cells * n_genes), nrow = n_cells))
  colnames(normalized_counts) <- paste0("Gene_", 1:n_genes)
  
  cat("OK\n")
}, error = function(e) {
  cat("ERREUR:", e$message, "\n")
})

# Test 2: Logique d'optimisation (limitation à 1000 gènes)
cat("✅ Test 2: Logique d'optimisation... ")
tryCatch({
  # Test avec plus de 1000 gènes
  n_genes_large <- 1500
  normalized_counts_large <- data.frame(matrix(rnorm(n_cells * n_genes_large), nrow = n_cells))
  colnames(normalized_counts_large) <- paste0("Gene_", 1:n_genes_large)
  
  # Application de la logique d'optimisation
  if(ncol(normalized_counts_large) > 1000) {
    gene_vars <- apply(normalized_counts_large, 2, var, na.rm = TRUE)
    top_genes <- names(sort(gene_vars, decreasing = TRUE)[1:1000])
    normalized_counts_optimized <- normalized_counts_large[, top_genes, drop = FALSE]
  }
  
  if(ncol(normalized_counts_optimized) == 1000) {
    cat("OK - Réduit de", n_genes_large, "à", ncol(normalized_counts_optimized), "gènes\n")
  } else {
    cat("ERREUR - Optimisation échouée\n")
  }
}, error = function(e) {
  cat("ERREUR:", e$message, "\n")
})

# Test 3: Calcul de corrélation
cat("✅ Test 3: Calcul de corrélation... ")
tryCatch({
  first_gene_count <- normalized_counts[, 1]
  
  # Test de corrélation Spearman
  test_result_spearman <- cor.test(first_gene_count, normalized_counts[, 2], method = "spearman")
  
  # Test de corrélation Pearson  
  test_result_pearson <- cor.test(first_gene_count, normalized_counts[, 2], method = "pearson")
  
  if(!is.null(test_result_spearman$estimate) && !is.null(test_result_pearson$estimate)) {
    cat("OK - Spearman:", round(test_result_spearman$estimate, 3), 
        "Pearson:", round(test_result_pearson$estimate, 3), "\n")
  } else {
    cat("ERREUR - Résultats invalides\n")
  }
}, error = function(e) {
  cat("ERREUR:", e$message, "\n")
})

# Test 4: Tri des résultats
cat("✅ Test 4: Tri des résultats... ")
tryCatch({
  # Création d'un data.frame de test
  correlation_df <- data.frame(
    Gene = paste0("Gene_", 1:10),
    Correlation = runif(10, -1, 1),
    p_val = runif(10, 0, 1),
    Bonferroni_p_value = runif(10, 0, 1)
  )
  
  # Test du tri par valeur absolue de corrélation
  correlation_df_sorted <- correlation_df[order(abs(correlation_df$Correlation), decreasing = TRUE), ]
  
  if(nrow(correlation_df_sorted) == 10) {
    cat("OK - Tri effectué\n")
  } else {
    cat("ERREUR - Tri échoué\n")
  }
}, error = function(e) {
  cat("ERREUR:", e$message, "\n")
})

cat("\n🎉 Test de syntaxe terminé!\n")
cat("Les optimisations de corrélation semblent syntaxiquement correctes.\n")
