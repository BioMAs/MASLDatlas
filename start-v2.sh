#!/bin/bash

# Script de démarrage rapide pour MASLDatlas v2.0

echo "🚀 Démarrage de MASLDatlas v2.0..."
echo ""

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez installer Docker Desktop."
    exit 1
fi

# Vérifier si Docker Compose est disponible
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas disponible."
    exit 1
fi

echo "✅ Docker est installé"
echo ""

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo "📝 Création du fichier .env..."
    cp .env.example .env
    echo "✅ Fichier .env créé"
fi

echo ""
echo "🐳 Lancement du backend Docker..."
echo "ℹ️  Frontend: Deploy separately on Vercel"
echo ""

# Lancer Docker Compose
docker-compose up --build

echo ""
echo "👋 Arrêt de MASLDatlas v2.0"
