# Structure du Projet MASLDatlas

## Fichiers Principaux
- `app.R` - Application Shiny principale
- `Dockerfile` - Configuration Docker
- `docker-compose.yml` - Orchestration Docker
- `README.md` - Documentation principale

## Configuration
- `config/` - Fichiers de configuration JSON
  - `datasets_config.json` - Configuration des datasets
  - `datasets_sources.json` - Sources des données
  - `environment.yml` - Environnement Conda

## Scripts
- `scripts/deployment/` - Scripts de déploiement
- `scripts/dataset-management/` - Gestion des datasets
- `scripts/setup/` - Scripts d'installation
- `scripts/testing/` - Scripts de test

## Assets
- `www/` - Fichiers statiques (CSS, JS, images)
- `enrichment_sets/` - Ensembles d'enrichissement
- `docs/` - Documentation technique

## Données
- `datasets/` - Datasets téléchargés
- `datasets_optimized/` - Datasets optimisés

## Développement
- `archived/` - Fichiers de développement archivés
- `backups/` - Sauvegardes automatiques
- `logs/` - Logs d'application
