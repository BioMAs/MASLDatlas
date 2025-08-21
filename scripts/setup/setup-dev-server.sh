#!/bin/bash

# 🚀 Script de Configuration du Serveur de Développement MASLDatlas
# Ce script prépare votre serveur pour le déploiement automatique via GitHub Actions

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

echo "🚀 Configuration du Serveur de Développement MASLDatlas"
echo "════════════════════════════════════════════════════════════════"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Ne pas exécuter ce script en tant que root"
    log_info "Utilisez: ./setup-dev-server.sh"
    exit 1
fi

# Configuration
DEV_USER="tdarde"
PROJECT_DIR="/home/dev/masldatlas"
CURRENT_USER=$(whoami)

log_step "1/7 Vérification des prérequis système"

# Check if user has sudo access
if ! sudo -n true 2>/dev/null; then
    log_error "L'utilisateur actuel n'a pas d'accès sudo"
    log_info "Veuillez vous assurer d'avoir les privilèges sudo"
    exit 1
fi

log_info "✅ Accès sudo vérifié"

# Check OS
if ! command -v apt &> /dev/null; then
    log_error "Ce script est conçu pour les systèmes Ubuntu/Debian"
    exit 1
fi

log_info "✅ Système Ubuntu/Debian détecté"

log_step "2/7 Installation des dépendances système"

# Update package list
log_info "Mise à jour de la liste des paquets..."
sudo apt update

# Install required packages
log_info "Installation des outils de base..."
sudo apt install -y \
    curl \
    wget \
    git \
    tar \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

log_info "✅ Outils de base installés"

log_step "3/7 Installation de Docker"

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    log_info "Docker est déjà installé"
    docker --version
else
    log_info "Installation de Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up the stable repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    log_info "✅ Docker installé avec succès"
fi

log_step "4/7 Installation de Docker Compose"

# Check if Docker Compose is already installed
if command -v docker-compose &> /dev/null; then
    log_info "Docker Compose est déjà installé"
    docker-compose --version
else
    log_info "Installation de Docker Compose..."
    
    # Download and install Docker Compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_info "✅ Docker Compose installé avec succès"
fi

log_step "5/7 Configuration de l'utilisateur dev"

# Create dev user if it doesn't exist
if ! id "$DEV_USER" &>/dev/null; then
    log_info "Création de l'utilisateur dev..."
    sudo useradd -m -s /bin/bash "$DEV_USER"
    log_info "✅ Utilisateur dev créé"
else
    log_info "✅ Utilisateur dev existe déjà"
fi

# Add users to docker group
log_info "Ajout des utilisateurs au groupe docker..."
sudo usermod -aG docker "$CURRENT_USER"
sudo usermod -aG docker "$DEV_USER"

log_step "6/7 Configuration du répertoire du projet"

# Create project directory
log_info "Création du répertoire du projet..."
sudo mkdir -p "$PROJECT_DIR"
sudo chown -R "$DEV_USER:$DEV_USER" "$PROJECT_DIR"

# Create necessary subdirectories
sudo -u "$DEV_USER" mkdir -p "$PROJECT_DIR"/{datasets,enrichment_sets,app_cache,logs}

log_info "✅ Répertoire du projet configuré"

log_step "7/7 Configuration SSH pour GitHub Actions"

# Setup SSH directory for dev user
sudo -u "$DEV_USER" mkdir -p "/home/$DEV_USER/.ssh"
sudo -u "$DEV_USER" chmod 700 "/home/$DEV_USER/.ssh"

log_info "Génération d'une clé SSH pour GitHub Actions..."

# Generate SSH key for GitHub Actions
sudo -u "$DEV_USER" ssh-keygen -t ed25519 -f "/home/$DEV_USER/.ssh/github_actions" -N "" -C "github-actions-masldatlas"

# Set proper permissions
sudo -u "$DEV_USER" chmod 600 "/home/$DEV_USER/.ssh/github_actions"
sudo -u "$DEV_USER" chmod 644 "/home/$DEV_USER/.ssh/github_actions.pub"

# Add public key to authorized_keys
sudo -u "$DEV_USER" cat "/home/$DEV_USER/.ssh/github_actions.pub" >> "/home/$DEV_USER/.ssh/authorized_keys"
sudo -u "$DEV_USER" chmod 600 "/home/$DEV_USER/.ssh/authorized_keys"

echo ""
echo "🎉 Configuration terminée avec succès !"
echo "════════════════════════════════════════════════════════════════"

log_info "📋 Résumé de la configuration :"
echo "  • Utilisateur dev : $DEV_USER"
echo "  • Répertoire projet : $PROJECT_DIR"
echo "  • Docker version : $(docker --version 2>/dev/null || echo 'Non installé')"
echo "  • Docker Compose : $(docker-compose --version 2>/dev/null || echo 'Non installé')"

echo ""
log_warn "🔧 Actions requises pour terminer la configuration :"

echo ""
echo "1. 🔑 Copiez cette clé SSH privée dans les secrets GitHub :"
echo "   Nom du secret : DEV_SERVER_SSH_KEY"
echo "   Contenu :"
echo "   ┌─────────────────────────────────────────────────────────────────┐"
sudo -u "$DEV_USER" cat "/home/$DEV_USER/.ssh/github_actions" | sed 's/^/   │ /'
echo "   └─────────────────────────────────────────────────────────────────┘"

echo ""
echo "2. 📍 Configurez ces secrets additionnels dans GitHub :"
echo "   • DEV_SERVER_HOST : $(hostname -I | awk '{print $1}') (ou votre domaine)"
echo "   • DEV_SERVER_USER : $DEV_USER"

echo ""
echo "3. 🔄 Déconnectez-vous et reconnectez-vous pour que les groupes soient pris en compte :"
echo "   logout && ssh $(whoami)@$(hostname)"

echo ""
echo "4. 🧪 Testez la connexion SSH :"
echo "   ssh -i /home/$DEV_USER/.ssh/github_actions $DEV_USER@localhost"

echo ""
log_info "📚 Documentation complète disponible dans : docs/github-actions-setup.md"

echo ""
echo "🚀 Votre serveur est maintenant prêt pour le déploiement automatique !"
