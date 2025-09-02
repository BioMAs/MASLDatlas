# Configuration de datasets optimisés pour les gros fichiers

Cette configuration permet de gérer les datasets volumineux comme "Fibrotic Integrated Cross Species-002" (9.2 GB) en créant des versions optimisées pour différents cas d'usage.

## Structure de datasets optimisés

```json
{
  "Human": {
    "Datasets": [
      "GSE181483"
    ]
  },
  "Mouse": {
    "Datasets": [
      "GSE145086"
    ]
  },
  "Zebrafish": {
    "Datasets": [
      "GSE181987"
    ]
  },
  "Integrated": {
    "Datasets": [
      "Fibrotic Integrated Cross Species-002",
      "Fibrotic Integrated Cross Species-002_sub5k",
      "Fibrotic Integrated Cross Species-002_sub10k",
      "Fibrotic Integrated Cross Species-002_sub20k",
      "Fibrotic Integrated Cross Species-002_shiny_optimized"
    ]
  },
  "Integrated_Large": {
    "info": "Versions complètes pour analyses avancées",
    "Datasets": [
      "Fibrotic Integrated Cross Species-002"
    ]
  }
}
```

## Versions optimisées proposées

### 1. Versions échantillonnées (Subsampled)
- **5k cells**: Fibrotic Integrated Cross Species-002_sub5k.h5ad (~100-200 MB)
- **10k cells**: Fibrotic Integrated Cross Species-002_sub10k.h5ad (~200-400 MB)
- **20k cells**: Fibrotic Integrated Cross Species-002_sub20k.h5ad (~400-800 MB)

### 2. Version optimisée Shiny
- **Shiny optimized**: Fibrotic Integrated Cross Species-002_shiny_optimized.h5ad
  - Garde seulement les gènes hautement variables
  - Pré-calcul des embeddings (UMAP, PCA)
  - Matrice dense pour accès rapide
  - Taille réduite de 60-80%

### 3. Version métadonnées seulement
- **Metadata only**: Fibrotic Integrated Cross Species-002_metadata.h5ad
  - Garde toutes les annotations cellulaires
  - Garde les embeddings UMAP/PCA
  - Supprime la matrice d'expression
  - Taille: ~10-50 MB

## Avantages de chaque version

1. **Sub5k**: Exploration rapide, tests d'interface
2. **Sub10k**: Analyse de workflow, développement
3. **Sub20k**: Analyses pilotes, validation de méthodes
4. **Shiny optimized**: Production Shiny avec performance équilibrée
5. **Metadata**: Navigation rapide, sélection de cellules
6. **Original**: Analyses complètes, publications
