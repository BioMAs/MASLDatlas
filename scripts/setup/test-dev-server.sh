#!/bin/bash

# 🧪 Script de Test de Configuration GitHub Actions
# Vérifie que votre serveur est correctement configuré pour le déploiement automatique

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_test() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_success() { echo -e "${GREEN}[✅]${NC} $1"; }
log_fail() { echo -e "${RED}[❌]${NC} $1"; }

# Configuration
DEV_USER="tdarde"
PROJECT_DIR="/home/dev/masldatlas"
ERRORS=0
WARNINGS=0

echo "🧪 Test de Configuration GitHub Actions MASLDatlas"
echo "═══════════════════════════════════════════════════════════════"

increment_error() {
    ERRORS=$((ERRORS + 1))
}

increment_warning() {
    WARNINGS=$((WARNINGS + 1))
}

# Test 1: Check if dev user exists
log_test "1. Vérification de l'utilisateur dev"
if id "$DEV_USER" &>/dev/null; then
    log_success "Utilisateur dev existe"
else
    log_fail "Utilisateur dev n'existe pas"
    increment_error
fi

# Test 2: Check project directory
log_test "2. Vérification du répertoire du projet"
if [ -d "$PROJECT_DIR" ]; then
    log_success "Répertoire $PROJECT_DIR existe"
    
    # Check ownership
    if [ "$(stat -c %U "$PROJECT_DIR")" = "$DEV_USER" ]; then
        log_success "Propriétaire correct : $DEV_USER"
    else
        log_fail "Propriétaire incorrect : $(stat -c %U "$PROJECT_DIR") (attendu: $DEV_USER)"
        increment_error
    fi
else
    log_fail "Répertoire $PROJECT_DIR n'existe pas"
    increment_error
fi

# Test 3: Check Docker installation
log_test "3. Vérification de Docker"
if command -v docker &> /dev/null; then
    log_success "Docker est installé : $(docker --version)"
    
    # Check if Docker service is running
    if systemctl is-active --quiet docker; then
        log_success "Service Docker actif"
    else
        log_fail "Service Docker inactif"
        increment_error
    fi
    
    # Check if dev user is in docker group
    if groups "$DEV_USER" | grep -q docker; then
        log_success "Utilisateur dev dans le groupe docker"
    else
        log_fail "Utilisateur dev pas dans le groupe docker"
        increment_error
    fi
else
    log_fail "Docker n'est pas installé"
    increment_error
fi

# Test 4: Check Docker Compose
log_test "4. Vérification de Docker Compose"
if command -v docker-compose &> /dev/null; then
    log_success "Docker Compose installé : $(docker-compose --version)"
else
    log_fail "Docker Compose n'est pas installé"
    increment_error
fi

# Test 5: Check SSH configuration
log_test "5. Vérification de la configuration SSH"
SSH_DIR="/home/$DEV_USER/.ssh"
if [ -d "$SSH_DIR" ]; then
    log_success "Répertoire SSH existe"
    
    # Check SSH key for GitHub Actions
    if [ -f "$SSH_DIR/github_actions" ]; then
        log_success "Clé SSH GitHub Actions existe"
        
        # Check permissions
        PERM=$(stat -c %a "$SSH_DIR/github_actions")
        if [ "$PERM" = "600" ]; then
            log_success "Permissions de clé correctes (600)"
        else
            log_warn "Permissions de clé incorrectes : $PERM (attendu: 600)"
            increment_warning
        fi
    else
        log_fail "Clé SSH GitHub Actions manquante"
        increment_error
    fi
    
    # Check authorized_keys
    if [ -f "$SSH_DIR/authorized_keys" ]; then
        log_success "Fichier authorized_keys existe"
    else
        log_warn "Fichier authorized_keys manquant"
        increment_warning
    fi
else
    log_fail "Répertoire SSH manquant"
    increment_error
fi

# Test 6: Check network connectivity
log_test "6. Vérification de la connectivité réseau"
if ping -c 1 github.com &>/dev/null; then
    log_success "Connectivité vers GitHub OK"
else
    log_warn "Problème de connectivité vers GitHub"
    increment_warning
fi

# Test 7: Check disk space
log_test "7. Vérification de l'espace disque"
AVAILABLE_SPACE=$(df "$PROJECT_DIR" | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))

if [ "$AVAILABLE_GB" -gt 20 ]; then
    log_success "Espace disque suffisant : ${AVAILABLE_GB}GB disponibles"
elif [ "$AVAILABLE_GB" -gt 10 ]; then
    log_warn "Espace disque limité : ${AVAILABLE_GB}GB disponibles (recommandé: >20GB)"
    increment_warning
else
    log_fail "Espace disque insuffisant : ${AVAILABLE_GB}GB disponibles (minimum: 10GB)"
    increment_error
fi

# Test 8: Check required tools
log_test "8. Vérification des outils requis"
TOOLS=("curl" "wget" "git" "tar")
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        log_success "$tool installé"
    else
        log_fail "$tool manquant"
        increment_error
    fi
done

# Test 9: Test Docker functionality
log_test "9. Test de fonctionnalité Docker"
if command -v docker &> /dev/null; then
    # Test as current user
    if docker ps &>/dev/null; then
        log_success "Docker fonctionne pour l'utilisateur actuel"
    else
        log_warn "Docker ne fonctionne pas pour l'utilisateur actuel (peut nécessiter une déconnexion/reconnexion)"
        increment_warning
    fi
    
    # Test as dev user
    if sudo -u "$DEV_USER" docker ps &>/dev/null; then
        log_success "Docker fonctionne pour l'utilisateur dev"
    else
        log_warn "Docker ne fonctionne pas pour l'utilisateur dev"
        increment_warning
    fi
fi

# Test 10: Simulation de déploiement
log_test "10. Simulation de déploiement"
TEST_DIR="/tmp/masldatlas_deploy_test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Create minimal test structure
cat > "$TEST_DIR/docker-compose.yml" << 'EOF'
version: '3.8'
services:
  test:
    image: alpine:latest
    command: echo "Test deployment successful"
EOF

cd "$TEST_DIR"
if docker-compose config &>/dev/null; then
    log_success "Configuration Docker Compose valide"
else
    log_fail "Problème avec Docker Compose"
    increment_error
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "📊 Résultats des Tests"
echo "═══════════════════════════════════════════════════════════════"

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    log_success "🎉 Tous les tests passés ! Configuration parfaite."
    echo ""
    log_info "✅ Votre serveur est prêt pour le déploiement GitHub Actions"
    echo ""
    echo "🚀 Prochaines étapes :"
    echo "   1. Configurez les secrets GitHub (voir docs/github-actions-setup.md)"
    echo "   2. Poussez du code sur la branche main"
    echo "   3. Observez le déploiement automatique !"
    
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    log_warn "⚠️ Configuration OK avec $WARNINGS avertissement(s)"
    echo ""
    log_info "🔧 Votre serveur devrait fonctionner, mais vérifiez les avertissements ci-dessus"
    
    exit 0
else
    log_fail "❌ $ERRORS erreur(s) et $WARNINGS avertissement(s) trouvés"
    echo ""
    log_error "🚨 Corrigez les erreurs avant de continuer"
    echo ""
    echo "💡 Solutions suggérées :"
    
    if [ "$ERRORS" -gt 0 ]; then
        echo "   • Exécutez le script de configuration : ./scripts/setup/setup-dev-server.sh"
        echo "   • Vérifiez que vous avez les privilèges sudo"
        echo "   • Redémarrez le service Docker si nécessaire"
        echo "   • Déconnectez-vous et reconnectez-vous pour les groupes"
    fi
    
    exit 1
fi
