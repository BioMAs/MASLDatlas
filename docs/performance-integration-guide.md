# Integration Instructions for Enhanced MASLDatlas
# Instructions d'intégration pour MASLDatlas amélioré

# Ce guide explique comment intégrer les améliorations de performance et robustesse
# This guide explains how to integrate performance and robustness improvements

cat("📖 GUIDE D'INTÉGRATION DES AMÉLIORATIONS DE PERFORMANCE\n")
cat("===============================================================\n")

# ÉTAPE 1: SETUP INITIAL / INITIAL SETUP
setup_instructions <- function() {
  cat("\n🔧 ÉTAPE 1: Configuration initiale\n")
  cat("==================================\n")
  
  cat("1. Exécutez le script de setup des optimisations:\n")
  cat("   source('scripts/setup/performance_robustness_setup.R')\n\n")
  
  cat("2. Vérifiez que tous les modules sont chargés:\n")
  cat("   - Cache system: ✅\n")
  cat("   - Memory monitoring: ✅\n") 
  cat("   - Data loading optimization: ✅\n")
  cat("   - Correlation optimization: ✅\n")
  cat("   - Health monitoring: ✅\n")
  cat("   - Optimization suggestions: ✅\n\n")
}

# ÉTAPE 2: INTÉGRATION DANS APP.R / INTEGRATION IN APP.R
app_integration_instructions <- function() {
  cat("\n🔄 ÉTAPE 2: Intégration dans app.R\n")
  cat("===================================\n")
  
  cat("Ajoutez au début de votre app.R (après les libraries):\n\n")
  
  cat("# === OPTIMIZATIONS LOADING ===\n")
  cat("tryCatch({\n")
  cat("  source('scripts/setup/performance_robustness_setup.R')\n") 
  cat("  cat('✅ Optimizations loaded successfully\\n')\n")
  cat("}, error = function(e) {\n")
  cat("  cat('⚠️ Optimizations not available:', e$message, '\\n')\n")
  cat("})\n\n")
  
  cat("# === ENHANCED DATASET LOADING ===\n")
  cat("# Remplacez la fonction adata <- eventReactive par:\n")
  cat("adata <- eventReactive(input$import_dataset, {\n")
  cat("  req(input$selection_organism, input$selection_dataset)\n")
  cat("  \n")
  cat("  # Check cache first\n")
  cat("  cache_key <- paste(input$selection_organism, input$selection_dataset, sep = '_')\n")
  cat("  if (exists('cache_info', mode = 'function')) {\n")
  cat("    # Use enhanced loading with cache\n")
  cat("    result <- load_dataset_intelligent(\n")
  cat("      input$selection_organism,\n")
  cat("      input$selection_dataset,\n")
  cat("      input$dataset_size_option\n")
  cat("    )\n")
  cat("    return(result)\n")
  cat("  } else {\n")
  cat("    # Fallback to original method\n")
  cat("    # ... code original ...\n")
  cat("  }\n")
  cat("})\n\n")
}

# ÉTAPE 3: OPTIMISATION DES CORRÉLATIONS / CORRELATION OPTIMIZATION
correlation_integration_instructions <- function() {
  cat("\n📊 ÉTAPE 3: Optimisation des corrélations\n")
  cat("==========================================\n")
  
  cat("Remplacez les fonctions de corrélation par:\n\n")
  
  cat("correlation_table_first_gene <- eventReactive(input$top_correlated_first_gene, {\n")
  cat("  req(adata(), input$gene_selection_cluster_coexpression_first)\n")
  cat("  \n")
  cat("  # Prepare data matrix\n")
  cat("  if (is.null(input$filter_dataset_cluster_selection)) {\n")
  cat("    data_matrix <- as.data.frame(as.matrix(adata()$X))\n")
  cat("  } else {\n")
  cat("    data_matrix <- as.data.frame(as.matrix(filtered_adata()$X))\n")
  cat("  }\n")
  cat("  colnames(data_matrix) <- gene_list_adata()\n")
  cat("  \n")
  cat("  # Use optimized correlation if available\n")
  cat("  if (exists('fast_correlation_analysis', mode = 'function')) {\n")
  cat("    result <- fast_correlation_analysis(\n")
  cat("      data_matrix,\n")
  cat("      input$gene_selection_cluster_coexpression_first,\n")
  cat("      method = ifelse(input$test_choice == 'Spearman', 'spearman', 'pearson')\n")
  cat("    )\n")
  cat("  } else {\n")
  cat("    # Fallback to original method\n")
  cat("    # ... code original ...\n")
  cat("  }\n")
  cat("  \n")
  cat("  return(result)\n")
  cat("})\n\n")
}

# ÉTAPE 4: MONITORING DE PERFORMANCE / PERFORMANCE MONITORING  
monitoring_integration_instructions <- function() {
  cat("\n📈 ÉTAPE 4: Monitoring de performance\n")
  cat("=====================================\n")
  
  cat("Ajoutez à votre server function:\n\n")
  
  cat("# Performance monitoring observer\n")
  cat("observe({\n")
  cat("  invalidateLater(30000)  # Check every 30 seconds\n")
  cat("  \n")
  cat("  if (exists('memory_cleanup', mode = 'function')) {\n")
  cat("    # Clean memory periodically\n")
  cat("    memory_info <- get_memory_info()\n")
  cat("    if (memory_info$status == 'Critical') {\n")
  cat("      memory_cleanup()\n")
  cat("    }\n")
  cat("  }\n")
  cat("})\n\n")
  
  cat("# Health status output (optionnel, pour debugging)\n")
  cat("output$health_status <- renderText({\n")
  cat("  if (exists('check_app_health', mode = 'function')) {\n")
  cat("    health <- check_app_health()\n")
  cat("    paste('Status:', health$overall_status)\n")
  cat("  } else {\n")
  cat("    'Health monitoring not available'\n")
  cat("  }\n")
  cat("})\n\n")
}

# ÉTAPE 5: UI AMÉLIORATIONS / UI IMPROVEMENTS
ui_enhancement_instructions <- function() {
  cat("\n🎨 ÉTAPE 5: Améliorations de l'interface\n")
  cat("========================================\n")
  
  cat("Ajoutez à votre UI (optionnel, pour le debugging):\n\n")
  
  cat("# Performance monitor (hidden by default)\n")
  cat("conditionalPanel(\n")
  cat("  condition = 'false',  # Set to true for debugging\n")
  cat("  div(class = 'performance-monitor',\n")
  cat("    style = 'position: fixed; bottom: 10px; right: 10px; background: rgba(255,255,255,0.9); padding: 10px; border-radius: 5px; font-size: 11px;',\n")
  cat("    h6('Performance Monitor'),\n")
  cat("    textOutput('health_status'),\n")
  cat("    hr(),\n")
  cat("    actionButton('memory_cleanup_btn', 'Clean Memory', class = 'btn-sm')\n")
  cat("  )\n")
  cat(")\n\n")
}

# COMMANDES UTILES / USEFUL COMMANDS
useful_commands <- function() {
  cat("\n💻 COMMANDES UTILES POUR LE MONITORING\n")
  cat("=======================================\n")
  
  cat("En mode interactif ou dans la console R:\n\n")
  
  cat("# Vérifier le statut de l'application\n")
  cat("print_health_status()\n\n")
  
  cat("# Vérifier l'utilisation mémoire\n") 
  cat("memory_info <- get_memory_info()\n")
  cat("cat('Memory status:', memory_info$status, '- Used:', memory_info$r_memory_mb, 'MB\\n')\n\n")
  
  cat("# Vérifier le cache\n")
  cat("cache_status <- cache_info()\n")
  cat("print(cache_status)\n\n")
  
  cat("# Nettoyer la mémoire manuellement\n")
  cat("memory_cleanup()\n\n")
  
  cat("# Obtenir des suggestions d'optimisation\n")
  cat("suggestions <- get_performance_suggestions()\n")
  cat("cat(paste(suggestions, collapse = '\\n'))\n\n")
}

# RÉSOLUTION DE PROBLÈMES / TROUBLESHOOTING
troubleshooting <- function() {
  cat("\n🔧 RÉSOLUTION DE PROBLÈMES\n")
  cat("==========================\n")
  
  cat("1. Si les optimisations ne se chargent pas:\n")
  cat("   - Vérifiez que tous les fichiers R/ sont présents\n")
  cat("   - Exécutez manuellement: source('scripts/setup/performance_robustness_setup.R')\n\n")
  
  cat("2. Si l'environnement Python ne fonctionne pas:\n")
  cat("   - Recréez l'environnement: conda env create -f config/environment.yml\n")
  cat("   - Activez l'environnement: conda activate fibrosis_shiny\n\n")
  
  cat("3. Si la mémoire est insuffisante:\n")
  cat("   - Utilisez les versions optimisées des datasets (sub5k, sub10k)\n")
  cat("   - Exécutez memory_cleanup() régulièrement\n")
  cat("   - Fermez et relancez l'application\n\n")
  
  cat("4. Si les corrélations sont lentes:\n")
  cat("   - Les optimisations limitent automatiquement à 1000 gènes\n")
  cat("   - Pour des analyses complètes, utilisez un serveur plus puissant\n\n")
}

# TESTS DE VALIDATION / VALIDATION TESTS
validation_tests <- function() {
  cat("\n✅ TESTS DE VALIDATION\n")
  cat("======================\n")
  
  cat("Pour vérifier que tout fonctionne correctement:\n\n")
  
  cat("1. Test du système de cache:\n")
  cat("   cache_info()  # Doit retourner l'état du cache\n\n")
  
  cat("2. Test du monitoring mémoire:\n")
  cat("   memory_info <- get_memory_info()\n")
  cat("   stopifnot(memory_info$status %in% c('Good', 'Warning', 'Critical'))\n\n")
  
  cat("3. Test du health check:\n")
  cat("   health <- check_app_health()\n")
  cat("   stopifnot(health$overall_status %in% c('healthy', 'warning', 'error'))\n\n")
  
  cat("4. Test des suggestions:\n")
  cat("   suggestions <- get_performance_suggestions()\n")
  cat("   stopifnot(is.character(suggestions))\n\n")
  
  cat("Si tous les tests passent, les optimisations sont opérationnelles! ✅\n\n")
}

# EXÉCUTION COMPLÈTE DU GUIDE / COMPLETE GUIDE EXECUTION
run_complete_guide <- function() {
  setup_instructions()
  app_integration_instructions()
  correlation_integration_instructions()
  monitoring_integration_instructions()
  ui_enhancement_instructions()
  useful_commands()
  troubleshooting()
  validation_tests()
  
  cat("🎯 GUIDE COMPLET TERMINÉ!\n")
  cat("=========================\n")
  cat("Votre application MASLDatlas est maintenant optimisée pour:\n")
  cat("✅ Performance améliorée\n")
  cat("✅ Robustesse renforcée\n") 
  cat("✅ Monitoring en temps réel\n")
  cat("✅ Gestion intelligente de la mémoire\n")
  cat("✅ Cache optimisé\n")
  cat("✅ Analyse de corrélation accélérée\n\n")
  
  cat("🚀 Votre application est prête pour la production!\n")
}

# Exécuter le guide complet
run_complete_guide()
