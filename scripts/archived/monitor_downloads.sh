#!/bin/bash

# 📊 Script de monitoring du téléchargement des datasets
# Affiche le progrès en temps réel

echo "📊 Monitoring du téléchargement MASLDatlas"
echo "=========================================="

watch_downloads() {
    while true; do
        clear
        echo "📊 État du téléchargement des datasets - $(date)"
        echo "================================================"
        echo ""
        
        # Vérifier si le répertoire datasets existe
        if [ -d "datasets" ]; then
            echo "📁 Répertoires créés :"
            find datasets -type d | sort
            echo ""
            
            echo "📦 Fichiers en cours de téléchargement :"
            find datasets -name "*.h5ad" -exec ls -lh {} \; 2>/dev/null | while read -r line; do
                echo "  $line"
            done
            
            echo ""
            echo "💾 Espace disque utilisé :"
            du -sh datasets 2>/dev/null || echo "  Calcul en cours..."
            
            echo ""
            echo "🎯 Datasets attendus :"
            echo "  Human/GSE181483.h5ad    (759 MB)"
            echo "  Mouse/GSE145086.h5ad    (1570 MB)"  
            echo "  Zebrafish/GSE181987.h5ad (392 MB)"
            echo ""
            echo "📊 Total attendu : ~2.7 GB"
            echo ""
            
            # Vérifier les téléchargements terminés
            completed=0
            total=3
            
            [ -f "datasets/Human/GSE181483.h5ad" ] && ((completed++)) && echo "✅ Human dataset téléchargé"
            [ -f "datasets/Mouse/GSE145086.h5ad" ] && ((completed++)) && echo "✅ Mouse dataset téléchargé"
            [ -f "datasets/Zebrafish/GSE181987.h5ad" ] && ((completed++)) && echo "✅ Zebrafish dataset téléchargé"
            
            echo ""
            echo "📈 Progrès : $completed/$total datasets"
            
            if [ $completed -eq $total ]; then
                echo ""
                echo "🎉 TÉLÉCHARGEMENT TERMINÉ !"
                echo "Tous les datasets ont été téléchargés avec succès."
                break
            fi
        else
            echo "⏳ Initialisation du téléchargement..."
        fi
        
        echo ""
        echo "⏸️  Ctrl+C pour arrêter le monitoring"
        echo "🔄 Mise à jour automatique dans 10 secondes..."
        
        sleep 10
    done
}

# Fonction de monitoring simple (sans clear)
simple_monitor() {
    echo "📊 État actuel des téléchargements :"
    echo ""
    
    if [ -d "datasets" ]; then
        echo "📁 Structure des répertoires :"
        tree datasets 2>/dev/null || find datasets -type d | sort
        echo ""
        
        echo "📦 Fichiers présents :"
        find datasets -name "*.h5ad" -exec ls -lh {} \; 2>/dev/null || echo "  Aucun fichier .h5ad trouvé"
        echo ""
        
        echo "💾 Espace utilisé :"
        du -sh datasets 2>/dev/null || echo "  Calcul impossible"
    else
        echo "📁 Le répertoire datasets n'existe pas encore"
    fi
}

# Mode d'utilisation
case "${1:-simple}" in
    "watch")
        watch_downloads
        ;;
    "simple"|*)
        simple_monitor
        ;;
esac
