# Guide de gestion des gros datasets MASLDatlas

## Problème : Dataset "Fibrotic Integrated Cross Species-002" (9.2 GB)

Ce dataset intégré de 9.2 GB pose des problèmes de performance :
- ⏱️ Chargement très lent (30+ minutes)
- 💾 Consommation mémoire importante (>16 GB RAM)
- 🚫 Blocage de l'interface utilisateur

## Solutions mises en place

### 1. Configuration temporaire allégée ✅
**Fichier** : `config/datasets_config_temp.json`
- Exclut temporairement le gros dataset
- Permet l'utilisation normale des autres datasets
- Solution immédiate pour développement/tests

### 2. Interface de sélection de taille 🚧
**Fichier** : `app.R` (lignes 150-170)
- Sélecteur de taille pour datasets volumineux
- Options : 5k, 10k, 20k cellules ou dataset complet
- Avertissements pour dataset complet

### 3. Gestion d'erreurs avancée ✅
**Fichier** : `app.R` (lignes 620-680)
- Progress bars pour chargement
- Messages d'erreur informatifs
- Fallback vers versions optimisées

### 4. Scripts d'optimisation 🚧
**Fichiers** : 
- `scripts/dataset-management/optimize_large_dataset.py`
- `scripts/dataset-management/optimize_large_dataset.R`
- `scripts/dataset-management/create_optimized_datasets.sh`

## Prochaines étapes recommandées

### Option 1 : Installation de scanpy (Recommandée)
```bash
# Installer scanpy dans l'environnement Python
pip install scanpy pandas numpy

# Exécuter l'optimisation
cd /Users/tdarde/Documents/GitHub/MASLDatlas
./scripts/dataset-management/create_optimized_datasets.sh
```

### Option 2 : Hébergement externe
- Déplacer le dataset vers un serveur de données
- Implémenter un chargement à la demande
- API de sous-échantillonnage côté serveur

### Option 3 : Pré-traitement externe
- Créer manuellement des versions échantillonnées
- Utiliser des outils comme Seurat ou scanpy en local
- Placer les fichiers optimisés dans `datasets_optimized/`

## Structure de fichiers optimisés

```
datasets_optimized/
├── Fibrotic Integrated Cross Species-002_sub5k.h5ad     (~100-200 MB)
├── Fibrotic Integrated Cross Species-002_sub10k.h5ad    (~200-400 MB)
├── Fibrotic Integrated Cross Species-002_sub20k.h5ad    (~400-800 MB)
└── Fibrotic Integrated Cross Species-002_metadata.h5ad  (~10-50 MB)
```

## Configuration de production

Une fois les datasets optimisés créés :

1. **Revenir à la configuration complète** :
```r
# Dans app.R, ligne 61
datasets_config <- jsonlite::fromJSON("config/datasets_config.json")
```

2. **Mettre à jour datasets_config.json** :
```json
{
  "Integrated": {
    "Datasets": [
      "Fibrotic Integrated Cross Species-002_sub5k",
      "Fibrotic Integrated Cross Species-002_sub10k", 
      "Fibrotic Integrated Cross Species-002_sub20k",
      "Fibrotic Integrated Cross Species-002"
    ]
  }
}
```

## Surveillance des performances

- **Mémoire** : Surveiller l'usage RAM avec `htop`
- **Temps de chargement** : Logs dans l'application Shiny
- **Expérience utilisateur** : Tests avec différentes tailles

## Contact

Pour questions ou assistance avec l'optimisation des datasets :
- Vérifier les logs d'erreur Docker
- Consulter la documentation scanpy
- Adapter les scripts selon l'environnement local
