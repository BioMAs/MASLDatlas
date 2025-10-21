# 📥 Guide d'Implémentation: Export CSV des Résultats

**Date:** 13 octobre 2025  
**Priorité:** 🟡 IMPORTANT (PRIORITÉ 2)  
**Effort:** 4-6 heures (version simple) ou 16-20 heures (version complète)  
**Impact:** ⭐ Très élevé - Demande utilisateur forte

---

## 🎯 Objectif

Permettre aux utilisateurs d'exporter tous les résultats d'analyse (expression différentielle, enrichissement, corrélations, etc.) au format CSV et Excel pour:
- Analyses ultérieures dans R, Python, Excel
- Publications scientifiques
- Partage avec collaborateurs
- Archivage des résultats

---

## 🚀 OPTION 1: Implémentation Rapide (4-6h)

### Avantages
✅ Rapide à implémenter  
✅ Pas de refactorisation nécessaire  
✅ Impact utilisateur immédiat  
✅ Facile à tester  

### Code à Ajouter dans app.R

```r
# ========================================
# SECTION: Download Handlers
# À ajouter dans la section server()
# ========================================

# 1. Export Differential Expression Results
output$download_dge <- downloadHandler(
  filename = function() {
    paste0("DGE_results_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(dge_results())  # Remplacer par votre reactive() de résultats DGE
    
    withProgress(message = "Exporting DGE results...", {
      write.csv(
        as.data.frame(dge_results()),
        file,
        row.names = TRUE,
        quote = TRUE
      )
    })
    
    showNotification(
      paste("Exported", nrow(dge_results()), "genes"),
      type = "message",
      duration = 3
    )
  }
)

# 2. Export MSIGDB Enrichment
output$download_msigdb <- downloadHandler(
  filename = function() {
    paste0("MSIGDB_enrichment_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(msigdb_results())  # Remplacer par votre reactive()
    
    withProgress(message = "Exporting MSIGDB results...", {
      write.csv(
        as.data.frame(msigdb_results()),
        file,
        row.names = TRUE
      )
    })
    
    showNotification("MSIGDB results exported successfully", type = "message")
  }
)

# 3. Export Progeny Enrichment
output$download_progeny <- downloadHandler(
  filename = function() {
    paste0("Progeny_enrichment_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(progeny_results())
    write.csv(as.data.frame(progeny_results()), file, row.names = TRUE)
    showNotification("Progeny results exported", type = "message")
  }
)

# 4. Export CollecTRI Enrichment
output$download_collectri <- downloadHandler(
  filename = function() {
    paste0("CollecTRI_enrichment_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(collectri_results())
    write.csv(as.data.frame(collectri_results()), file, row.names = TRUE)
    showNotification("CollecTRI results exported", type = "message")
  }
)

# 5. Export Correlation Results
output$download_correlation <- downloadHandler(
  filename = function() {
    paste0("Correlation_results_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(correlation_results())
    write.csv(as.data.frame(correlation_results()), file, row.names = TRUE)
    showNotification("Correlation results exported", type = "message")
  }
)

# 6. Export Cell Type Markers
output$download_markers <- downloadHandler(
  filename = function() {
    paste0("Cell_markers_", Sys.Date(), ".csv")
  },
  content = function(file) {
    req(marker_genes())
    write.csv(as.data.frame(marker_genes()), file, row.names = TRUE)
    showNotification("Cell markers exported", type = "message")
  }
)

# 7. Export ALL Results (Excel Multi-Sheet) - OPTIONNEL
output$download_all_excel <- downloadHandler(
  filename = function() {
    paste0("MASLDatlas_all_results_", Sys.Date(), ".xlsx")
  },
  content = function(file) {
    # Nécessite: install.packages("writexl")
    req(requireNamespace("writexl", quietly = TRUE))
    
    withProgress(message = "Creating Excel workbook...", value = 0, {
      
      sheets <- list()
      
      incProgress(0.2, detail = "Collecting results")
      
      # Ajouter chaque résultat disponible
      if (!is.null(dge_results())) {
        sheets$DifferentialExpression <- as.data.frame(dge_results())
      }
      
      if (!is.null(msigdb_results())) {
        sheets$Enrichment_MSIGDB <- as.data.frame(msigdb_results())
      }
      
      if (!is.null(progeny_results())) {
        sheets$Enrichment_Progeny <- as.data.frame(progeny_results())
      }
      
      if (!is.null(collectri_results())) {
        sheets$Enrichment_CollecTRI <- as.data.frame(collectri_results())
      }
      
      if (!is.null(correlation_results())) {
        sheets$Correlation <- as.data.frame(correlation_results())
      }
      
      if (!is.null(marker_genes())) {
        sheets$CellMarkers <- as.data.frame(marker_genes())
      }
      
      incProgress(0.6, detail = "Writing Excel file")
      
      writexl::write_xlsx(sheets, path = file)
      
      incProgress(1.0, detail = "Complete!")
    })
    
    showNotification(
      paste("Exported", length(sheets), "sheets to Excel"),
      type = "message",
      duration = 5
    )
  }
)
```

### Modifications UI

```r
# Dans votre UI, ajouter les boutons à côté des tables de résultats

# Exemple pour l'expression différentielle
tabPanel(
  "Differential Expression",
  fluidRow(
    column(
      12,
      h3("Differential Expression Results"),
      downloadButton(
        "download_dge",
        "📥 Download Results (CSV)",
        icon = icon("download"),
        class = "btn-primary"
      ),
      hr(),
      DTOutput("dge_table")
    )
  )
)

# Exemple pour enrichissement
tabPanel(
  "Enrichment Analysis",
  fluidRow(
    column(12, h3("MSIGDB Enrichment")),
    column(
      12,
      downloadButton("download_msigdb", "📥 Download MSIGDB (CSV)", icon = icon("download")),
      DTOutput("msigdb_table")
    )
  ),
  hr(),
  fluidRow(
    column(12, h3("Progeny Pathway Activity")),
    column(
      12,
      downloadButton("download_progeny", "📥 Download Progeny (CSV)", icon = icon("download")),
      DTOutput("progeny_table")
    )
  ),
  hr(),
  fluidRow(
    column(12, h3("CollecTRI TF Activity")),
    column(
      12,
      downloadButton("download_collectri", "📥 Download CollecTRI (CSV)", icon = icon("download")),
      DTOutput("collectri_table")
    )
  )
)

# Bouton global pour tout exporter
div(
  class = "text-center mt-3",
  downloadButton(
    "download_all_excel",
    "📊 Download All Results (Excel)",
    icon = icon("file-excel"),
    class = "btn-success btn-lg"
  )
)
```

### Installation Dépendances

```r
# Optionnel pour export Excel
install.packages("writexl")
```

### Checklist Implémentation Rapide

- [ ] Copier les downloadHandler() dans app.R (section server)
- [ ] Adapter les noms de reactive() à votre code
- [ ] Ajouter les downloadButton() dans votre UI
- [ ] Tester chaque bouton individuellement
- [ ] Vérifier que les CSV s'ouvrent correctement dans Excel
- [ ] (Optionnel) Installer writexl et tester export Excel
- [ ] Commit et push

**Temps estimé:** 4-6 heures

---

## 🏗️ OPTION 2: Module Complet (16-20h)

### Avantages
✅ Architecture propre et modulaire  
✅ Options de formatage avancées  
✅ Réutilisable et extensible  
✅ Meilleure UX  
✅ Plus facile à maintenir  

### Structure

```
R/
├── modules/
│   └── data_export_module.R    # Module Shiny pour export
└── utils/
    └── export_helpers.R         # Fonctions utilitaires

tests/
└── testthat/
    └── test_data_export.R       # Tests unitaires

docs/
└── export-guide.md              # Documentation utilisateur
```

### Voir Section 4.3 du IMPROVEMENT_PLAN.md

Le code complet du module se trouve dans:
- `/Users/tdarde/Documents/Github/MASLDatlas/docs/IMPROVEMENT_PLAN.md`
- Section: **"4.3 Téléchargement des Résultats en CSV"**

**Temps estimé:** 16-20 heures

---

## 🧪 Tests Rapides

```r
# Test manuel après implémentation

# 1. Charger un dataset
# 2. Lancer une analyse DGE
# 3. Cliquer sur "Download Results (CSV)"
# 4. Vérifier le fichier téléchargé:

test_csv <- read.csv("DGE_results_2025-10-13.csv")
head(test_csv)
nrow(test_csv)  # Doit correspondre aux résultats affichés

# 5. Ouvrir dans Excel et vérifier:
# - Les colonnes sont bien séparées
# - Les nombres sont formatés correctement
# - Les noms de gènes sont présents
# - Pas de caractères bizarres

# 6. Tester l'export Excel multi-feuilles
library(readxl)
excel_sheets("MASLDatlas_all_results_2025-10-13.xlsx")
# Doit afficher: "DifferentialExpression", "Enrichment_MSIGDB", etc.

read_excel("MASLDatlas_all_results_2025-10-13.xlsx", sheet = 1) %>% head()
```

---

## 📝 Documentation Utilisateur

Créer un fichier `/docs/user-guide-export.md`:

```markdown
# Guide: Exporting Analysis Results

## How to Export Results

1. **Run your analysis** (DGE, enrichment, correlation, etc.)
2. **Locate the download button** below the results table
3. **Click "📥 Download Results (CSV)"**
4. The file will be saved to your Downloads folder

## File Format

- **CSV format**: Compatible with Excel, R, Python, GraphPad Prism
- **Filename**: Includes analysis type and date (e.g., `DGE_results_2025-10-13.csv`)
- **Content**: All columns from the results table, including:
  - Gene IDs / Pathway names
  - Statistics (log2FC, p-values, adjusted p-values)
  - Additional metadata

## Excel Export (All Results)

To export **all analyses at once** in a single Excel file:

1. Scroll to the bottom of any results page
2. Click **"📊 Download All Results (Excel)"**
3. Open the Excel file - each analysis is in a separate sheet

## Troubleshooting

**Q: The CSV file looks weird in Excel**  
A: Make sure your Excel language settings match your system locale. Or use "Data > Text to Columns" to reformat.

**Q: I can't find the download button**  
A: Make sure you've run the analysis first. The button appears only when results are available.

**Q: Can I export intermediate results?**  
A: Currently, only final analysis results can be exported. Raw data should be saved separately.
```

---

## 🎯 Recommandation

**Pour une implémentation RAPIDE (cette semaine):**
→ Utiliser **OPTION 1** (4-6h)

**Pour une solution DURABLE (ce mois):**
→ Planifier **OPTION 2** (16-20h) après Phase 1 du plan d'amélioration

---

## 📊 Impact Attendu

### Avant
❌ Utilisateurs ne peuvent pas sauvegarder leurs résultats  
❌ Copier-coller manuel depuis l'interface (erreur-prone)  
❌ Impossibilité de réanalyser les données  
❌ Frustration utilisateurs  

### Après
✅ Export 1-clic de tous les résultats  
✅ Format CSV standard (compatible partout)  
✅ Excel multi-feuilles pour rapports complets  
✅ Archivage facile des analyses  
✅ Réutilisation dans autres outils  
✅ **Satisfaction utilisateur +50%** (estimé)

---

## 🔗 Références

- [Shiny downloadHandler Documentation](https://shiny.rstudio.com/reference/shiny/latest/downloadHandler.html)
- [writexl Package](https://cran.r-project.org/web/packages/writexl/)
- Section 4.3 de `/docs/IMPROVEMENT_PLAN.md`

---

**Questions?** Voir le plan d'amélioration complet ou contacter l'équipe de développement.
