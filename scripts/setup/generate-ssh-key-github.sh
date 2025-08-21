#!/bin/bash

# 🔐 Script de Génération de Clé SSH pour GitHub Actions MASLDatlas
# Ce script génère une clé SSH correctement formatée pour le déploiement automatique

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
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

echo "🔐 Génération Clé SSH pour GitHub Actions MASLDatlas"
echo "═══════════════════════════════════════════════════════════════"

# Configuration
USER=$(whoami)
KEY_NAME="github_actions_masldatlas"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
BACKUP_SUFFIX=$(date +%Y%m%d_%H%M%S)

log_step "1/5 Vérification de l'environnement"

# Check if .ssh directory exists
if [ ! -d "$HOME/.ssh" ]; then
    log_info "Création du répertoire .ssh..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi

# Backup existing key if it exists
if [ -f "$KEY_PATH" ]; then
    log_warn "Clé existante trouvée, création d'une sauvegarde..."
    cp "$KEY_PATH" "${KEY_PATH}.backup_${BACKUP_SUFFIX}"
    cp "${KEY_PATH}.pub" "${KEY_PATH}.pub.backup_${BACKUP_SUFFIX}"
fi

log_step "2/5 Génération de la clé SSH"

# Generate SSH key
log_info "Génération de la clé ED25519..."
if ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "github-actions-masldatlas-${USER}" >/dev/null 2>&1; then
    log_info "✅ Clé ED25519 générée avec succès"
else
    log_warn "ED25519 non supporté, utilisation de RSA 4096..."
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "github-actions-masldatlas-${USER}"
    log_info "✅ Clé RSA 4096 générée avec succès"
fi

log_step "3/5 Configuration des permissions"

# Set proper permissions
chmod 600 "$KEY_PATH"
chmod 644 "${KEY_PATH}.pub"

log_info "✅ Permissions configurées"

log_step "4/5 Configuration de l'accès SSH"

# Add public key to authorized_keys
if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
fi

# Check if key is already in authorized_keys
KEY_CONTENT=$(cat "${KEY_PATH}.pub")
if ! grep -q "$KEY_CONTENT" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
    cat "${KEY_PATH}.pub" >> "$HOME/.ssh/authorized_keys"
    log_info "✅ Clé publique ajoutée à authorized_keys"
else
    log_info "✅ Clé publique déjà présente dans authorized_keys"
fi

log_step "5/5 Validation et test"

# Validate key
log_info "Validation de la clé générée..."
KEY_INFO=$(ssh-keygen -l -f "$KEY_PATH")
log_info "✅ Clé valide : $KEY_INFO"

# Test local connection
log_info "Test de connexion locale..."
if ssh -i "$KEY_PATH" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USER@localhost" 'echo "Connection test successful"' >/dev/null 2>&1; then
    log_info "✅ Test de connexion réussi"
else
    log_warn "⚠️ Test de connexion échoué (peut être normal selon la configuration SSH)"
fi

echo ""
echo "🎉 Génération terminée avec succès !"
echo "═══════════════════════════════════════════════════════════════"

log_info "📋 Résumé de la configuration :"
echo "  • Utilisateur : $USER"
echo "  • Clé privée : $KEY_PATH"
echo "  • Clé publique : ${KEY_PATH}.pub"
echo "  • Type de clé : $(ssh-keygen -l -f "$KEY_PATH" | awk '{print $NF}' | tr -d '()')"

echo ""
log_warn "🔧 Actions requises dans GitHub :"

echo ""
echo "1. 🌐 Allez dans votre repository GitHub :"
echo "   https://github.com/BioMAs/MASLDatlas"
echo ""
echo "2. ⚙️ Créez/Modifiez l'environnement DEV_SCILICIUM :"
echo "   Settings → Environments → DEV_SCILICIUM"
echo ""
echo "3. 🔑 Copiez cette clé SSH privée dans le secret DEV_SERVER_SSH_KEY :"
echo ""
echo "   ┌─────────────────────────────────────────────────────────────────┐"
echo "   │                       CLÉS SSH PRIVÉE                          │"
echo "   │                   (À copier dans GitHub)                       │"
echo "   └─────────────────────────────────────────────────────────────────┘"
cat "$KEY_PATH" | sed 's/^/   │ /'
echo "   └─────────────────────────────────────────────────────────────────┘"

echo ""
echo "4. 📍 Configurez les autres secrets :"
echo "   • DEV_SERVER_HOST : $(hostname -I | awk '{print $1}') (ou votre domaine)"
echo "   • DEV_SERVER_USER : $USER"

echo ""
echo "5. 🧪 Informations de la clé publique (pour référence) :"
echo "   $(cat "${KEY_PATH}.pub")"

echo ""
log_info "📚 Documentation complète disponible dans :"
echo "  • SSH_KEY_FIX_GUIDE.md"
echo "  • docs/environment-dev-scilicium.md"

echo ""
echo "🚀 Une fois configuré dans GitHub, votre déploiement automatique sera opérationnel !"

# Cleanup function
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "Erreur lors de la génération"
        if [ -f "${KEY_PATH}.backup_${BACKUP_SUFFIX}" ]; then
            log_info "Restauration de la sauvegarde..."
            mv "${KEY_PATH}.backup_${BACKUP_SUFFIX}" "$KEY_PATH"
            mv "${KEY_PATH}.pub.backup_${BACKUP_SUFFIX}" "${KEY_PATH}.pub"
        fi
    fi
}

trap cleanup EXIT
