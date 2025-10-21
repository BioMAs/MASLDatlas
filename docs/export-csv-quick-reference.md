# 🗺️ Référence Rapide: Reactive Objects dans app.R

**Date:** 13 octobre 2025  
**Usage:** Guide pour adapter les downloadHandler() de l'export CSV

---

## 📋 Reactive Objects Identifiés

D'après l'analyse de `app.R`, voici les objets reactive() correspondant aux différents résultats d'analyse:

### 1. Cell Type Markers
```r
# Output UI: DTOutput("table_cluster_markers")  [ligne 422]
# Render: renderDT() [ligne 1099]
# Reactive probable: marker_genes() ou cluster_markers()

# Pour le downloadHandler:
output$download_markers <- downloadHandler(
  filename = function() {
    paste0("Cell_markers_", Sys.Date(), ".csv")
  },
  content = function(file) {
    # ADAPTER LE NOM DU REACTIVE ICI
    req(marker_data())  # Trouver le bon nom dans app.R
    write.csv(as.data.frame(marker_data()), file, row.names = TRUE)
  }
)
```

### 2. Gene Correlation Analysis
```r
# Output UI: 
# - DTOutput("first_gene_correlation_table")  [ligne 571]
# - DTOutput("second_gene_correlation_table") [ligne 572]

# Render:
# - renderDT() [ligne 1872 - first_gene_correlation_table]
# - renderDT() [ligne 1963 - second_gene_correlation_table]

# Reactive: statistics_coexpression [ligne 1667]
statistics_coexpression <- reactive({ ... })

# Pour le downloadHandler:
output$download_correlation <- downloadHandler(
  filename = function() {
    paste0("Correlation_results_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(statistics_coexpression())
    write.csv(as.data.frame(statistics_coexpression()), file, row.names = TRUE)
  }
)
```

### 3. Differential Gene Expression (DGE)
```r
# Output UI: DTOutput("dge_dt") [ligne 626]
# Render: renderDT() [ligne 2180]
# Reactive: de_dge_calculation [ligne 2164]

de_dge_calculation <- reactive({ ... })

# Pour le downloadHandler:
output$download_dge <- downloadHandler(
  filename = function() {
    paste0("DGE_results_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(de_dge_calculation())
    write.csv(as.data.frame(de_dge_calculation()), file, row.names = TRUE)
  }
)
```

### 4. Enrichment Analysis (DE)
```r
# Output UI: DTOutput("de_enrichment_table") [ligne 707]
# Render: renderDT() [ligne 2381]
# Reactive: de_enrichment_calc [ligne 2280]

de_enrichment_calc <- reactive({ ... })

# Note: Ce reactive contient probablement MSIGDB/Progeny/CollecTRI
# Il faudra peut-être séparer par méthode

# Pour le downloadHandler:
output$download_enrichment <- downloadHandler(
  filename = function() {
    paste0("Enrichment_results_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(de_enrichment_calc())
    write.csv(as.data.frame(de_enrichment_calc()), file, row.names = TRUE)
  }
)
```

### 5. Pseudo-bulk Analysis
```r
# Output UI: 
# - DTOutput("pca_pseudo_bulk_results_table") [ligne 765]
# - DTOutput("pseudo_enrichment_table") [ligne 813]

# Render:
# - renderDT() [ligne 2769 - pca_pseudo_bulk_results_table]
# - renderDT() [ligne 2898 - pseudo_enrichment_table]

# Reactive: À identifier dans le code (probablement autour ligne 2700+)

# Pour le downloadHandler:
output$download_pseudobulk <- downloadHandler(
  filename = function() {
    paste0("Pseudobulk_results_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(pseudobulk_data())  # TROUVER LE BON NOM
    write.csv(as.data.frame(pseudobulk_data()), file, row.names = TRUE)
  }
)

output$download_pseudo_enrichment <- downloadHandler(
  filename = function() {
    paste0("Pseudobulk_enrichment_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(pseudo_enrichment_data())  # TROUVER LE BON NOM
    write.csv(as.data.frame(pseudo_enrichment_data()), file, row.names = TRUE)
  }
)
```

---

## 🔍 Comment Trouver le Bon Reactive

### Méthode 1: Rechercher dans app.R
```r
# 1. Identifier le DTOutput dans l'UI (ex: "dge_dt")
# 2. Chercher le renderDT correspondant:
grep -n "renderDT.*dge_dt" app.R
# → ligne 2180

# 3. Lire le code autour de cette ligne pour voir quel reactive est utilisé
# Dans renderDT(), chercher req() ou validation qui référence un reactive
```

### Méthode 2: Chercher par pattern
```bash
# Chercher tous les reactive() dans app.R
grep -n "reactive({" app.R

# Chercher les assignations de reactive
grep -n "<- reactive" app.R

# Résultats connus:
# - Ligne 1667: statistics_coexpression <- reactive({
# - Ligne 2164: de_dge_calculation <- reactive({
# - Ligne 2280: de_enrichment_calc <- reactive({
```

### Méthode 3: Lire le renderDT
```r
# Exemple: output$dge_dt <- renderDT({ ... })
# À l'intérieur, chercher:
# - req(mon_reactive())
# - validation(need(mon_reactive(), ...))
# - direct usage: data <- mon_reactive()
```

---

## 📝 Template de Download Handler

```r
# Template universel pour n'importe quel résultat

output$download_XXXX <- downloadHandler(
  filename = function() {
    # Nom descriptif + timestamp
    paste0("DESCRIPTION_", Sys.Date(), ".csv")
  },
  content = function(file) {
    # 1. Require le reactive (failsafe)
    req(mon_reactive())
    
    # 2. Optionnel: Progress bar
    withProgress(message = "Exporting data...", {
      
      # 3. Convertir en data.frame si nécessaire
      data_to_export <- as.data.frame(mon_reactive())
      
      # 4. Écrire le CSV
      write.csv(
        data_to_export,
        file,
        row.names = TRUE,  # Ajuster selon le besoin
        quote = TRUE       # Pour éviter problèmes caractères spéciaux
      )
    })
    
    # 5. Notification de succès
    showNotification(
      paste("Exported", nrow(mon_reactive()), "rows"),
      type = "message",
      duration = 3
    )
  }
)
```

---

## 🎯 Plan d'Action

### Étape 1: Identifier les Reactives (30 min)
```r
# Ouvrir app.R et noter les noms exacts des reactive() pour:
- [ ] Cell markers: _________________
- [ ] Correlation: statistics_coexpression ✓
- [ ] DGE: de_dge_calculation ✓
- [ ] Enrichment: de_enrichment_calc ✓
- [ ] Pseudo-bulk: _________________
- [ ] Pseudo-enrichment: _________________
```

### Étape 2: Copier le Template (1h)
```r
# Créer un downloadHandler pour chaque résultat identifié
# Adapter le nom du reactive et le filename
```

### Étape 3: Ajouter les Boutons UI (1h)
```r
# Pour chaque DTOutput dans l'UI, ajouter avant ou après:
downloadButton("download_XXXX", "📥 Download CSV", icon = icon("download"))
```

### Étape 4: Tester (1-2h)
```r
# Pour chaque export:
# 1. Lancer l'analyse
# 2. Cliquer sur le bouton download
# 3. Vérifier le CSV dans Excel/LibreOffice
# 4. Vérifier que les données sont complètes
```

### Étape 5: Documentation (30 min)
```markdown
# Mettre à jour le README ou créer docs/user-guide.md
# Expliquer comment exporter les résultats
```

---

## 🐛 Debugging Tips

### Erreur: "object 'X' not found"
```r
# Le reactive n'existe pas ou mal nommé
# Solution: Vérifier le nom exact dans app.R
```

### Erreur: "promise already under evaluation"
```r
# Circular dependency entre reactives
# Solution: Utiliser isolate() ou eventReactive()
```

### Le CSV est vide
```r
# Le reactive retourne NULL
# Solution: Ajouter validation avant l'export:
req(mon_reactive())
validate(need(!is.null(mon_reactive()), "No data available"))
```

### Caractères bizarres dans Excel
```r
# Problème d'encodage
# Solution: Spécifier UTF-8
write.csv(data, file, row.names = TRUE, fileEncoding = "UTF-8")
```

---

## 📚 Ressources

- Code source complet: `/docs/export-csv-implementation.md`
- Plan d'amélioration: `/docs/IMPROVEMENT_PLAN.md` (Section 4.3)
- Shiny downloadHandler: https://shiny.rstudio.com/reference/shiny/latest/downloadHandler.html

---

**Prêt à implémenter?** Suivez le guide d'implémentation dans `export-csv-implementation.md`!
