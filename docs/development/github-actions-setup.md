# Configuration des GitHub Actions pour le Déploiement Automatique

## 🔧 Configuration des Secrets GitHub

Pour activer le déploiement automatique sur votre serveur de développement, vous devez configurer l'environnement `DEV_SCILICIUM` et ses secrets dans votre repository GitHub :

### Étape 1 : Créer l'Environnement GitHub
1. Allez dans votre repository GitHub : `https://github.com/BioMAs/MASLDatlas`
2. Cliquez sur **Settings** (en haut à droite)
3. Dans le menu de gauche, cliquez sur **Environments**
4. Cliquez sur **New environment**
5. Nommez l'environnement : `DEV_SCILICIUM`
6. Cliquez sur **Configure environment**

### Étape 2 : Configurer l'Environnement (Optionnel)
Dans la configuration de l'environnement `DEV_SCILICIUM`, vous pouvez :
- **Protection rules** : Restreindre les déploiements à certaines branches
- **Required reviewers** : Demander une approbation avant déploiement
- **Wait timer** : Ajouter un délai avant déploiement

### Étape 3 : Ajouter les Secrets à l'Environnement

Dans la section **Environment secrets** de `DEV_SCILICIUM`, ajoutez :

#### 🔑 DEV_SERVER_SSH_KEY
- **Nom** : `DEV_SERVER_SSH_KEY`
- **Valeur** : Votre clé SSH privée pour accéder au serveur de développement
- **Comment l'obtenir** :
  ```bash
  # Sur votre serveur, après avoir exécuté setup-dev-server.sh
  sudo cat /home/tdarde/.ssh/github_actions
  
  # Ou si vous générez une nouvelle clé sur votre machine locale
  ssh-keygen -t ed25519 -C "github-actions-masldatlas"
  
  # Copiez la clé publique sur votre serveur de dev
  ssh-copy-id tdarde@votre-serveur-dev.com
  
  # Copiez le contenu de la clé privée pour GitHub
  cat ~/.ssh/id_ed25519
  ```

#### 🌐 DEV_SERVER_HOST
- **Nom** : `DEV_SERVER_HOST`
- **Valeur** : L'adresse IP ou nom de domaine de votre serveur de développement
- **Exemple** : `192.168.1.100` ou `dev.masldatlas.com`

#### 👤 DEV_SERVER_USER
- **Nom** : `DEV_SERVER_USER`
- **Valeur** : Le nom d'utilisateur pour la connexion SSH
- **Exemple** : `tdarde` (pour l'utilisateur qui a accès à `/home/dev/masldatlas/`)

## 📋 Prérequis sur le Serveur de Développement

Assurez-vous que votre serveur de développement dispose de :

### 1. Docker et Docker Compose
```bash
# Installation de Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Installation de Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Accès SSH configuré
```bash
# Vérifiez que l'utilisateur dev existe et a les bonnes permissions
sudo useradd -m -s /bin/bash dev
sudo usermod -aG docker dev

# Créez le répertoire pour MASLDatlas
sudo mkdir -p /home/dev/masldatlas
sudo chown -R dev:dev /home/dev/masldatlas
```

### 3. Outils nécessaires
```bash
# Installation des outils requis
sudo apt update
sudo apt install -y curl wget git tar
```

## 🚀 Fonctionnement du Déploiement Automatique

### Déclenchement Automatique
Le déploiement se déclenche automatiquement lors :
- **Push sur la branche `main`** : Déploiement en production
- **Push sur la branche `develop`** : Déploiement en développement

### Déclenchement Manuel
Vous pouvez également déclencher manuellement le déploiement :
1. Allez dans l'onglet **Actions** de votre repository
2. Sélectionnez **Deploy to Development Server**
3. Cliquez sur **Run workflow**
4. Optionnel : Cochez **Force rebuild datasets** si nécessaire

### Processus de Déploiement

1. **🔄 Sauvegarde** : Création d'une sauvegarde de l'ancien déploiement
2. **⬇️ Téléchargement** : Récupération du code depuis GitHub
3. **🛑 Arrêt** : Arrêt des conteneurs existants
4. **📦 Extraction** : Déploiement des nouveaux fichiers
5. **📊 Datasets** : Vérification et téléchargement des datasets si nécessaire
6. **🐳 Build** : Construction de l'image Docker
7. **🚀 Démarrage** : Lancement de l'application
8. **🏥 Tests** : Vérification de la santé de l'application
9. **🧹 Nettoyage** : Suppression des anciens backups et images

## 📊 Monitoring et Logs

### Accès aux Logs GitHub Actions
- Allez dans **Actions** → **Deploy to Development Server**
- Cliquez sur un run spécifique pour voir les détails

### Accès aux Logs de l'Application
```bash
# Sur le serveur de développement
cd /home/dev/masldatlas
docker logs masldatlas-dev

# Suivi en temps réel
docker logs -f masldatlas-dev
```

### Vérification de l'État
```bash
# Status des conteneurs
docker ps | grep masldatlas

# Status des datasets
./scripts/dataset-management/manage_volume.sh status

# Test de santé de l'application
curl http://localhost:3838
```

## 🔧 Configuration Avancée

### Variables d'Environnement
Vous pouvez modifier le comportement en ajustant les variables dans le workflow :

```yaml
env:
  DEV_SERVER_PATH: /home/dev/masldatlas  # Chemin sur le serveur
  CONTAINER_NAME: masldatlas-dev         # Nom du conteneur
```

### Personnalisation des Branches
Pour déployer sur d'autres branches, modifiez :

```yaml
on:
  push:
    branches: [ main, develop, feature/my-branch ]
```

## 🚨 Dépannage

### Problème de Connexion SSH
```bash
# Test de connexion manuelle
ssh dev@votre-serveur-dev.com

# Vérification des permissions de clé
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Problème Docker
```bash
# Redémarrage du service Docker
sudo systemctl restart docker

# Nettoyage complet
docker system prune -a
```

### Problème de Permissions
```bash
# Correction des permissions du projet
sudo chown -R dev:dev /home/dev/masldatlas
chmod +x /home/dev/masldatlas/scripts/**/*.sh
```

## 📞 Support

En cas de problème :
1. Vérifiez les logs GitHub Actions
2. Vérifiez les logs Docker sur le serveur
3. Testez la connexion SSH manuellement
4. Vérifiez que tous les prérequis sont installés
