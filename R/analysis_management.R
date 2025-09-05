# Analysis Results Management System
# Système de gestion des résultats d'analyse avec identifiants uniques

#' Generate unique analysis identifier
#' @param analysis_type Type d'analyse (dge, pseudo_bulk, etc.)
#' @param params Paramètres de l'analyse
#' @return Identifiant unique pour l'analyse
generate_analysis_id <- function(analysis_type, params = list()) {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  param_hash <- digest::digest(params, algo = "md5")
  short_hash <- substr(param_hash, 1, 8)
  
  return(paste(analysis_type, timestamp, short_hash, sep = "_"))
}

#' Store analysis results with optimization recommendations
#' @param analysis_id Identifiant unique de l'analyse
#' @param results Résultats de l'analyse
#' @param optimization_results Résultats d'optimisation des seuils
#' @param metadata Métadonnées de l'analyse
store_analysis_results <- function(analysis_id, results, optimization_results = NULL, metadata = list()) {
  if (!exists("global_analysis_cache")) {
    global_analysis_cache <<- list()
  }
  
  global_analysis_cache[[analysis_id]] <<- list(
    results = results,
    optimization = optimization_results,
    metadata = metadata,
    timestamp = Sys.time()
  )
  
  return(analysis_id)
}

#' Retrieve analysis results
#' @param analysis_id Identifiant de l'analyse
#' @return Résultats de l'analyse ou NULL si non trouvé
get_analysis_results <- function(analysis_id) {
  if (exists("global_analysis_cache") && analysis_id %in% names(global_analysis_cache)) {
    return(global_analysis_cache[[analysis_id]])
  }
  return(NULL)
}

#' Format optimization results for display
#' @param optimization_results Résultats d'optimisation
#' @return HTML formaté pour affichage
format_optimization_display <- function(optimization_results) {
  if (is.null(optimization_results)) {
    return("Aucune optimisation disponible")
  }
  
  # Extraire les informations principales
  best_composite <- optimization_results$best_composite
  most_degs <- optimization_results$most_degs_with_enrichment
  best_ratio <- optimization_results$best_enrichment_ratio
  
  html_content <- tags$div(
    class = "optimization-results",
    tags$h4("🎯 Recommandations d'Optimisation", style = "color: #2c3e50; margin-bottom: 15px;"),
    
    # Meilleur score composite
    tags$div(
      class = "recommendation-card",
      style = "border: 2px solid #27ae60; border-radius: 8px; padding: 15px; margin-bottom: 10px; background-color: #f8fff9;",
      tags$h5("🏆 MEILLEUR SCORE COMPOSITE", style = "color: #27ae60; margin: 0 0 10px 0;"),
      tags$p(
        style = "margin: 5px 0; font-weight: bold;",
        sprintf("FC ≥ %.1f, p-adj ≤ %.3f", best_composite$fc_threshold, best_composite$pval_threshold)
      ),
      tags$p(
        style = "margin: 5px 0;",
        sprintf("DEGs: %d, Enrichis: %d, Ratio: %.1f%%", 
                best_composite$n_degs, best_composite$n_enriched, best_composite$enrichment_ratio * 100)
      )
    ),
    
    # Plus grand nombre de DEGs
    tags$div(
      class = "recommendation-card",
      style = "border: 2px solid #3498db; border-radius: 8px; padding: 15px; margin-bottom: 10px; background-color: #f8fbff;",
      tags$h5("📊 PLUS GRAND NOMBRE DE DEGs (avec enrichissement)", style = "color: #3498db; margin: 0 0 10px 0;"),
      tags$p(
        style = "margin: 5px 0; font-weight: bold;",
        sprintf("FC ≥ %.1f, p-adj ≤ %.3f", most_degs$fc_threshold, most_degs$pval_threshold)
      ),
      tags$p(
        style = "margin: 5px 0;",
        sprintf("DEGs: %d, Enrichis: %d, Ratio: %.1f%%", 
                most_degs$n_degs, most_degs$n_enriched, most_degs$enrichment_ratio * 100)
      )
    ),
    
    # Meilleur ratio d'enrichissement
    tags$div(
      class = "recommendation-card",
      style = "border: 2px solid #e74c3c; border-radius: 8px; padding: 15px; margin-bottom: 10px; background-color: #fff8f8;",
      tags$h5("🎯 MEILLEUR RATIO D'ENRICHISSEMENT (≥50 DEGs)", style = "color: #e74c3c; margin: 0 0 10px 0;"),
      tags$p(
        style = "margin: 5px 0; font-weight: bold;",
        sprintf("FC ≥ %.1f, p-adj ≤ %.3f", best_ratio$fc_threshold, best_ratio$pval_threshold)
      ),
      tags$p(
        style = "margin: 5px 0;",
        sprintf("DEGs: %d, Enrichis: %d, Ratio: %.1f%%", 
                best_ratio$n_degs, best_ratio$n_enriched, best_ratio$enrichment_ratio * 100)
      )
    ),
    
    # Boutons d'action
    tags$div(
      class = "optimization-actions",
      style = "margin-top: 15px; text-align: center;",
      tags$button(
        "Appliquer Meilleur Score",
        class = "btn btn-success",
        style = "margin-right: 10px;",
        onclick = sprintf("Shiny.setInputValue('apply_best_composite', '%s_%s', {priority: 'event'});", 
                         best_composite$fc_threshold, best_composite$pval_threshold)
      ),
      tags$button(
        "Appliquer Plus de DEGs",
        class = "btn btn-primary",
        style = "margin-right: 10px;",
        onclick = sprintf("Shiny.setInputValue('apply_most_degs', '%s_%s', {priority: 'event'});", 
                         most_degs$fc_threshold, most_degs$pval_threshold)
      ),
      tags$button(
        "Appliquer Meilleur Ratio",
        class = "btn btn-warning",
        onclick = sprintf("Shiny.setInputValue('apply_best_ratio', '%s_%s', {priority: 'event'});", 
                         best_ratio$fc_threshold, best_ratio$pval_threshold)
      )
    )
  )
  
  return(html_content)
}

#' List all stored analyses
#' @return Liste des identifiants d'analyses avec métadonnées
list_stored_analyses <- function() {
  if (!exists("global_analysis_cache")) {
    return(data.frame(
      analysis_id = character(0),
      type = character(0),
      timestamp = character(0),
      description = character(0)
    ))
  }
  
  analyses_info <- lapply(names(global_analysis_cache), function(id) {
    analysis <- global_analysis_cache[[id]]
    data.frame(
      analysis_id = id,
      type = analysis$metadata$type %||% "unknown",
      timestamp = as.character(analysis$timestamp),
      description = analysis$metadata$description %||% "No description",
      stringsAsFactors = FALSE
    )
  })
  
  do.call(rbind, analyses_info)
}

#' Clean old analyses (keep only last 10)
clean_old_analyses <- function(max_keep = 10) {
  if (!exists("global_analysis_cache")) {
    return()
  }
  
  if (length(global_analysis_cache) > max_keep) {
    # Trier par timestamp et garder les plus récents
    timestamps <- sapply(global_analysis_cache, function(x) x$timestamp)
    sorted_ids <- names(sort(timestamps, decreasing = TRUE))
    
    # Garder seulement les max_keep plus récents
    to_keep <- sorted_ids[1:max_keep]
    global_analysis_cache <<- global_analysis_cache[to_keep]
  }
}

# Opérateur de coalescence nulle
`%||%` <- function(x, y) if (is.null(x)) y else x
