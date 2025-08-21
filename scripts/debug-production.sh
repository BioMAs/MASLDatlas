#!/bin/bash

# 🔍 Script de Diagnostic Docker MASLDatlas Production

echo "🔍 Diagnostic MASLDatlas - $(date)"
echo "=================================================="

# Vérification des fichiers de configuration
echo ""
echo "📋 1. Vérification des fichiers de configuration"
echo "------------------------------------------------"

if [ -f "./config/datasets_config.json" ]; then
    echo "✅ datasets_config.json trouvé"
    echo "📏 Taille: $(wc -c < ./config/datasets_config.json) bytes"
    echo "🔍 Validation JSON:"
    if python3 -m json.tool ./config/datasets_config.json > /dev/null 2>&1; then
        echo "✅ JSON valide"
    else
        echo "❌ JSON invalide!"
        echo "Contenu du fichier:"
        cat ./config/datasets_config.json
    fi
else
    echo "❌ datasets_config.json MANQUANT!"
fi

if [ -f "./config/datasets_sources.json" ]; then
    echo "✅ datasets_sources.json trouvé"
    echo "📏 Taille: $(wc -c < ./config/datasets_sources.json) bytes"
    echo "🔍 Validation JSON:"
    if python3 -m json.tool ./config/datasets_sources.json > /dev/null 2>&1; then
        echo "✅ JSON valide"
    else
        echo "❌ JSON invalide!"
        echo "Contenu du fichier:"
        cat ./config/datasets_sources.json
    fi
else
    echo "❌ datasets_sources.json MANQUANT!"
fi

# Vérification des datasets
echo ""
echo "📊 2. Vérification des datasets"
echo "--------------------------------"

if [ -d "./datasets" ]; then
    echo "✅ Dossier datasets trouvé"
    echo "📁 Contenu:"
    find ./datasets -name "*.h5ad" -exec ls -lh {} \; || echo "Aucun fichier .h5ad trouvé"
    echo "📊 Nombre total de fichiers .h5ad: $(find ./datasets -name "*.h5ad" | wc -l)"
else
    echo "❌ Dossier datasets MANQUANT!"
    echo "Création du dossier..."
    mkdir -p datasets/{Human,Mouse,Zebrafish,Integrated}
fi

# Vérification des enrichment sets
echo ""
echo "🧬 3. Vérification des enrichment sets"
echo "---------------------------------------"

if [ -d "./enrichment_sets" ]; then
    echo "✅ Dossier enrichment_sets trouvé"
    echo "📁 Contenu:"
    ls -lh ./enrichment_sets/ || echo "Dossier vide"
else
    echo "❌ Dossier enrichment_sets MANQUANT!"
    echo "Création du dossier..."
    mkdir -p enrichment_sets
fi

# Vérification des volumes Docker
echo ""
echo "🐳 4. Vérification des volumes Docker"
echo "-------------------------------------"

echo "📦 Volumes Docker existants:"
docker volume ls | grep masldatlas || echo "Aucun volume masldatlas trouvé"

echo ""
echo "🔍 Inspection des volumes:"
docker volume inspect masldatlas_masldatlas_cache 2>/dev/null || echo "Volume masldatlas_cache non trouvé"
docker volume inspect masldatlas_masldatlas_logs 2>/dev/null || echo "Volume masldatlas_logs non trouvé"

# Vérification des containers
echo ""
echo "🐳 5. Vérification des containers"
echo "---------------------------------"

echo "📦 Containers MASLDatlas:"
docker ps -a | grep masldatlas || echo "Aucun container masldatlas trouvé"

if docker ps | grep masldatlas-prod > /dev/null; then
    echo ""
    echo "📊 Logs récents du container:"
    docker logs masldatlas-prod --tail 20
fi

# Test de connectivité
echo ""
echo "🌐 6. Test de connectivité"
echo "---------------------------"

if docker ps | grep masldatlas-prod > /dev/null; then
    echo "🔗 Test HTTP local:"
    if curl -f http://localhost:3838/ > /dev/null 2>&1; then
        echo "✅ Application accessible sur http://localhost:3838/"
    else
        echo "❌ Application non accessible sur http://localhost:3838/"
    fi
    
    echo ""
    echo "🔍 Vérification des fichiers dans le container:"
    docker exec masldatlas-prod ls -la /app/config/ 2>/dev/null || echo "Impossible d'accéder aux fichiers config du container"
else
    echo "⚠️ Container masldatlas-prod non en cours d'exécution"
fi

# Vérification des réseaux
echo ""
echo "🌐 7. Vérification des réseaux Docker"
echo "------------------------------------"

echo "📡 Réseaux Docker:"
docker network ls | grep -E "(web|masldatlas)" || echo "Réseaux masldatlas non trouvés"

# Recommandations
echo ""
echo "💡 8. Recommandations"
echo "--------------------"

echo "🔧 Pour résoudre les problèmes détectés:"
echo ""

if [ ! -f "./config/datasets_config.json" ] || [ ! -f "./config/datasets_sources.json" ]; then
    echo "1. 📋 Fichiers de configuration manquants:"
    echo "   git checkout config/datasets_config.json"
    echo "   git checkout config/datasets_sources.json"
    echo ""
fi

if [ $(find ./datasets -name "*.h5ad" | wc -l) -lt 4 ]; then
    echo "2. 📊 Télécharger les datasets:"
    echo "   ./scripts/dataset-management/manage_volume.sh download"
    echo ""
fi

if ! docker ps | grep masldatlas-prod > /dev/null; then
    echo "3. 🐳 Redémarrer le container:"
    echo "   docker-compose -f docker-compose.prod.yml down"
    echo "   docker-compose -f docker-compose.prod.yml up -d"
    echo ""
fi

echo "4. 🧹 Nettoyer et reconstruire si nécessaire:"
echo "   docker-compose -f docker-compose.prod.yml down -v"
echo "   docker system prune -f"
echo "   docker-compose -f docker-compose.prod.yml up -d --build"

echo ""
echo "=================================================="
echo "🏁 Diagnostic terminé - $(date)"
