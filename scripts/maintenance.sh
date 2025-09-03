#!/bin/bash

# Script de maintenance rapide du projet MASLDatlas
# Usage: ./maintenance.sh [clean|logs|docker|all]

case "${1:-all}" in
    "clean")
        echo "🧹 Nettoyage des fichiers temporaires..."
        find . -name "*.tmp" -o -name "*~" -o -name ".DS_Store" | xargs rm -f 2>/dev/null
        echo "✅ Fichiers temporaires supprimés"
        ;;
    
    "logs")
        echo "📝 Nettoyage des logs anciens..."
        find logs/ -name "*.log" -mtime +7 -exec rm {} \; 2>/dev/null
        find logs/ -name "*.json" -mtime +7 -exec rm {} \; 2>/dev/null
        echo "✅ Logs anciens supprimés"
        ;;
    
    "docker")
        echo "🐳 Nettoyage Docker..."
        if command -v docker &> /dev/null; then
            docker system prune -f --volumes 2>/dev/null
            echo "✅ Ressources Docker nettoyées"
        else
            echo "❌ Docker non disponible"
        fi
        ;;
    
    "all")
        echo "🔄 Maintenance complète..."
        $0 clean
        $0 logs
        $0 docker
        echo "🎉 Maintenance terminée !"
        ;;
    
    *)
        echo "Usage: $0 [clean|logs|docker|all]"
        echo "  clean  - Supprimer les fichiers temporaires"
        echo "  logs   - Nettoyer les logs anciens"
        echo "  docker - Nettoyer les ressources Docker"
        echo "  all    - Effectuer toutes les opérations"
        exit 1
        ;;
esac
