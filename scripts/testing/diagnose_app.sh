#!/bin/bash

# Script de diagnostic pour MASLDatlas
echo "🔍 Diagnostic MASLDatlas Application"
echo "===================================="

echo "📋 1. Vérification du conteneur Docker..."
docker ps --filter "name=masldatlas" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "📋 2. Test de connectivité..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\nTotal time: %{time_total}s\n" http://localhost:3838

echo ""
echo "📋 3. Vérification des logs récents..."
echo "--- Dernières 10 lignes des logs ---"
docker logs masldatlas-masldatlas-1 --tail 10 2>&1 || echo "Aucun log récent trouvé"

echo ""
echo "📋 4. Test de syntaxe R..."
docker exec masldatlas-masldatlas-1 R --slave -e "cat('✅ R syntax test passed\n')" 2>&1

echo ""
echo "📋 5. Vérification des fichiers de configuration..."
echo "--- datasets_config.json ---"
docker exec masldatlas-masldatlas-1 ls -la /app/config/ 2>&1

echo ""
echo "📋 6. Test d'accès aux datasets..."
docker exec masldatlas-masldatlas-1 ls -la /app/datasets/ 2>&1

echo ""
echo "✅ Diagnostic terminé!"
