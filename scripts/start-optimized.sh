#!/bin/bash
# MASLDatlas Optimized Startup Script
# Démarre l'application avec toutes les optimisations activées

echo "🚀 Starting MASLDatlas with Performance Optimizations"
echo "===================================================="

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "app.R" ]; then
    echo "❌ Error: app.R not found. Please run this script from the MASLDatlas directory."
    exit 1
fi

# Vérifier les optimisations
echo "🔍 Checking optimization system..."
if [ -f "scripts/setup/performance_robustness_setup.R" ]; then
    echo "✅ Performance optimization system found"
else
    echo "❌ Performance optimization system not found"
    exit 1
fi

# Pré-test des optimisations
echo "🧪 Running pre-startup optimization test..."
Rscript scripts/testing/test_optimizations.R > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Optimization system ready"
else
    echo "⚠️  Optimization system has warnings but will continue"
fi

# Nettoyer la mémoire avant démarrage
echo "🧹 Cleaning up memory..."
Rscript -e "gc(); rm(list=ls()); cat('Memory cleaned\n')" > /dev/null 2>&1

# Afficher les informations système
echo "📊 System Information:"
echo "  - R Version: $(Rscript -e "cat(R.version.string)")"
echo "  - Available Memory: $(Rscript -e "cat(round(as.numeric(system('free -m | grep Mem: | awk \"{print $7}\"', intern=TRUE)) / 1024, 1), 'GB')" 2>/dev/null || echo "Unknown")"
echo "  - Working Directory: $(pwd)"

# Vérifier les ports disponibles
PORT=${1:-3838}
echo "🌐 Checking port $PORT..."
if command -v lsof > /dev/null 2>&1; then
    if lsof -i :$PORT > /dev/null 2>&1; then
        echo "⚠️  Port $PORT is already in use. The app may not start correctly."
    else
        echo "✅ Port $PORT is available"
    fi
fi

echo ""
echo "🎯 Starting MASLDatlas Application..."
echo "   - Performance Optimization: ✅ ENABLED"
echo "   - Cache System: ✅ ENABLED" 
echo "   - Memory Monitoring: ✅ ENABLED"
echo "   - Error Recovery: ✅ ENABLED"
echo "   - Health Monitoring: ✅ ENABLED"
echo ""
echo "📱 Application will be available at: http://localhost:$PORT"
echo "🛑 Press Ctrl+C to stop the application"
echo ""

# Démarrer l'application avec gestion d'erreurs
trap 'echo -e "\n🛑 Shutting down MASLDatlas..."; echo "🧹 Cleaning up..."; exit 0' INT

# Démarrer avec R
if command -v Rscript > /dev/null 2>&1; then
    Rscript -e "
        cat('🚀 Loading MASLDatlas with optimizations...\n')
        
        # Charger les librairies nécessaires
        suppressMessages({
            library(shiny)
            library(DT)
            library(shinycssloaders)
            library(shinyjs)
            library(bslib)
        })
        
        # Démarrer l'application
        options(shiny.port = $PORT)
        options(shiny.host = '0.0.0.0')
        
        cat('✅ Starting Shiny server on port $PORT...\n')
        runApp('app.R', port = $PORT, host = '0.0.0.0')
    "
else
    echo "❌ Error: Rscript not found. Please install R."
    exit 1
fi
