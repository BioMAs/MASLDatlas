#!/bin/bash

# Script de réorganisation et nettoyage du projet MASLDatlas
# Supprime les fichiers non utilisés et réorganise la structure

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🧹 Nettoyage et réorganisation du projet MASLDatlas"
echo "=================================================="

# 1. Nettoyer les fichiers de configuration dupliqués/non utilisés
log_info "🗂️  Nettoyage des fichiers de configuration..."

cd config/

# Garder seulement les fichiers essentiels
ESSENTIAL_CONFIG_FILES=(
    "datasets_config.json"
    "datasets_sources.json" 
    "environment.yml"
    "app_config.json"
)

log_info "Fichiers de configuration essentiels identifiés:"
for file in "${ESSENTIAL_CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (manquant)"
    fi
done

# Créer un dossier backup pour les fichiers de config non essentiels
if [ ! -d "backup_configs" ]; then
    mkdir backup_configs
    log_info "Dossier backup_configs créé"
fi

# Déplacer les fichiers de configuration non essentiels vers backup
for file in *.json; do
    if [[ ! " ${ESSENTIAL_CONFIG_FILES[@]} " =~ " ${file} " ]]; then
        if [ -f "$file" ]; then
            mv "$file" backup_configs/
            log_warning "Déplacé vers backup: $file"
        fi
    fi
done

cd ..

# 2. Nettoyer les logs anciens
log_info "📋 Nettoyage des logs..."

if [ -d "logs" ]; then
    # Garder seulement les logs récents (moins de 7 jours)
    find logs/ -name "*.log" -mtime +7 -exec rm {} \;
    find logs/ -name "*.json" -mtime +7 -exec rm {} \;
    log_success "Logs anciens supprimés"
fi

# 3. Nettoyer les backups anciens
log_info "💾 Nettoyage des backups..."

if [ -d "backups" ]; then
    # Garder seulement les 3 backups les plus récents
    backup_count=$(ls -1 backups/*.tar.gz 2>/dev/null | wc -l)
    if [ "$backup_count" -gt 3 ]; then
        ls -1t backups/*.tar.gz | tail -n +4 | xargs rm -f
        log_success "Anciens backups supprimés, conservés les 3 plus récents"
    else
        log_info "Nombre de backups acceptable ($backup_count/3)"
    fi
fi

# 4. Nettoyer les scripts redondants
log_info "🔧 Nettoyage des scripts redondants..."

# Identifier les scripts potentiellement redondants ou obsolètes
POTENTIALLY_OBSOLETE_SCRIPTS=(
    "apply_improvement_plan.sh"
    "finalize_improvements.sh"
    "monitor_downloads.sh"
    "quick_monitor.sh"
    "check_workflow.sh"
)

if [ ! -d "scripts/archived" ]; then
    mkdir -p scripts/archived
    log_info "Dossier scripts/archived créé"
fi

for script in "${POTENTIALLY_OBSOLETE_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        mv "$script" scripts/archived/
        log_warning "Script archivé: $script"
    fi
done

# 5. Nettoyer la documentation redondante
log_info "📚 Réorganisation de la documentation..."

if [ -d "docs" ]; then
    # Créer des sous-dossiers thématiques
    mkdir -p docs/deployment
    mkdir -p docs/development
    mkdir -p docs/troubleshooting
    
    # Déplacer les fichiers dans les bonnes catégories
    
    # Documentation de déploiement
    for doc in docs/*deployment* docs/*password* docs/*ssh*; do
        if [ -f "$doc" ]; then
            mv "$doc" docs/deployment/
        fi
    done
    
    # Documentation de développement
    for doc in docs/*environment* docs/*github*; do
        if [ -f "$doc" ]; then
            mv "$doc" docs/development/
        fi
    done
    
    # Documentation de dépannage
    for doc in docs/*troubleshooting* docs/*resolution* docs/*issue* docs/*optimization*; do
        if [ -f "$doc" ]; then
            mv "$doc" docs/troubleshooting/
        fi
    done
    
    log_success "Documentation réorganisée en sous-dossiers thématiques"
fi

# 6. Nettoyer les datasets optimisés orphelins
log_info "💽 Vérification des datasets optimisés..."

if [ -d "datasets_optimized" ]; then
    # Vérifier s'il y a des datasets optimisés sans datasets source correspondants
    orphaned_count=0
    if [ -n "$(ls -A datasets_optimized/ 2>/dev/null)" ]; then
        for optimized in datasets_optimized/*; do
            if [ -d "$optimized" ]; then
                basename_opt=$(basename "$optimized")
                if [ ! -d "datasets/$basename_opt" ]; then
                    rm -rf "$optimized"
                    orphaned_count=$((orphaned_count + 1))
                    log_warning "Dataset optimisé orphelin supprimé: $basename_opt"
                fi
            fi
        done
    fi
    
    if [ $orphaned_count -eq 0 ]; then
        log_success "Aucun dataset optimisé orphelin trouvé"
    else
        log_success "$orphaned_count datasets optimisés orphelins supprimés"
    fi
fi

# 7. Supprimer les fichiers temporaires et caches
log_info "🧽 Nettoyage des fichiers temporaires..."

# Supprimer les fichiers R temporaires
rm -f .Rhistory
rm -rf .Rproj.user/

# Supprimer les fichiers de cache Python
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -exec rm -f {} + 2>/dev/null || true

# Supprimer les fichiers de log temporaires
rm -f *.log 2>/dev/null || true

log_success "Fichiers temporaires supprimés"

# 8. Créer une structure organisée
log_info "📁 Finalisation de la structure du projet..."

# S'assurer que tous les dossiers essentiels existent
ESSENTIAL_DIRS=(
    "config"
    "scripts/dataset-management"
    "scripts/deployment"
    "scripts/monitoring"
    "scripts/setup"
    "scripts/testing"
    "docs/deployment"
    "docs/development"  
    "docs/troubleshooting"
    "R"
    "www"
    "datasets"
    "enrichment_sets"
    "logs"
    "backups"
)

for dir in "${ESSENTIAL_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_info "Dossier créé: $dir"
    fi
done

# 9. Créer un fichier de structure du projet
log_info "📋 Création du fichier de structure..."

cat > PROJECT_STRUCTURE.md << 'EOF'
# Structure du Projet MASLDatlas

## 🗂️ Organisation des Dossiers

### Dossiers Principaux
- `app.R` - Application Shiny principale
- `config/` - Fichiers de configuration
- `scripts/` - Scripts d'automatisation et d'administration
- `docs/` - Documentation du projet
- `R/` - Modules R personnalisés
- `www/` - Ressources web statiques
- `datasets/` - Données de datasets (montées via volume Docker)
- `enrichment_sets/` - Ensembles de données d'enrichissement
- `logs/` - Fichiers de logs
- `backups/` - Sauvegardes automatiques

### Configuration (`config/`)
- `datasets_config.json` - Configuration des datasets disponibles
- `datasets_sources.json` - Sources et URLs de téléchargement
- `environment.yml` - Environnement conda/Python
- `app_config.json` - Configuration de l'application
- `backup_configs/` - Sauvegardes de configurations

### Scripts (`scripts/`)
- `dataset-management/` - Gestion des datasets
- `deployment/` - Scripts de déploiement
- `monitoring/` - Surveillance et monitoring
- `setup/` - Scripts d'installation
- `testing/` - Scripts de test
- `archived/` - Scripts archivés/obsolètes

### Documentation (`docs/`)
- `deployment/` - Guides de déploiement
- `development/` - Documentation de développement
- `troubleshooting/` - Guides de dépannage

## 🔧 Fichiers Essentiels

### Configuration Docker
- `Dockerfile` - Image Docker de l'application
- `docker-compose.yml` - Orchestration locale
- `docker-compose.prod.yml` - Configuration production
- `.dockerignore` - Exclusions Docker

### Documentation Principale
- `README.md` - Guide principal
- `QUICK_START.md` - Guide de démarrage rapide
- `architecture.md` - Architecture du système
- `PROJECT_STRUCTURE.md` - Ce fichier

### Rapports
- `SUCCESS_REPORT.md` - Rapport de succès des améliorations
- `IMPROVEMENT_SUMMARY.md` - Résumé des améliorations

## 🚀 Utilisation

1. **Démarrage rapide** : Voir `QUICK_START.md`
2. **Configuration** : Modifier les fichiers dans `config/`
3. **Déploiement** : Utiliser les scripts dans `scripts/deployment/`
4. **Monitoring** : Scripts dans `scripts/monitoring/`
5. **Tests** : Scripts dans `scripts/testing/`

## 🧹 Maintenance

- Les logs sont nettoyés automatiquement (>7 jours)
- Les backups sont limités aux 3 plus récents
- Les configurations obsolètes sont archivées dans `config/backup_configs/`
- Les scripts obsolètes sont dans `scripts/archived/`
EOF

log_success "Fichier PROJECT_STRUCTURE.md créé"

# 10. Résumé final
echo ""
echo "🎉 Nettoyage et réorganisation terminés!"
echo "======================================"

log_success "✅ Fichiers de configuration nettoyés"
log_success "✅ Logs anciens supprimés"
log_success "✅ Backups optimisés"
log_success "✅ Scripts archivés"
log_success "✅ Documentation réorganisée"
log_success "✅ Fichiers temporaires supprimés"
log_success "✅ Structure du projet finalisée"

echo ""
echo "📁 Structure finale du projet:"
tree -L 2 -I 'datasets|__pycache__|*.pyc|.git' . || ls -la

echo ""
echo "💡 Prochaines étapes recommandées:"
echo "   1. Vérifier que l'application fonctionne: docker-compose up"
echo "   2. Consulter PROJECT_STRUCTURE.md pour la nouvelle organisation"
echo "   3. Mettre à jour la documentation si nécessaire"
