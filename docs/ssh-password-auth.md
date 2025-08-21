# 🔐 Configuration Authentification SSH par Mot de Passe

## 🎯 Nouvelle Approche : User + Password

Plus simple et souvent plus pratique pour les environnements de développement, l'authentification par nom d'utilisateur et mot de passe élimine les problèmes de format de clés SSH.

## ✅ Avantages de cette Approche

### Simplicité
- 🚫 **Pas de gestion de clés SSH** : Fini les problèmes de format
- 🔑 **Credentials standards** : Utilise les identifiants existants
- 🛠️ **Configuration minimale** : Juste username/password

### Sécurité
- 🔐 **Secrets GitHub** : Mot de passe stocké de façon sécurisée
- 🌐 **Connexions chiffrées** : SSH reste sécurisé
- 🎯 **Environnement isolé** : Secrets dans DEV_SCILICIUM

### Compatibilité
- ✅ **Serveurs existants** : Fonctionne avec configuration SSH standard
- ✅ **Pas d'installation** : Utilise sshpass (installé automatiquement)
- ✅ **Multi-plateformes** : Compatible Linux/Unix

## 🔧 Configuration Requise

### 1. 🖥️ Sur Votre Serveur

#### Vérifier SSH avec Authentification par Mot de Passe
```bash
# Vérifier que l'authentification par mot de passe est activée
sudo nano /etc/ssh/sshd_config

# S'assurer que ces lignes sont présentes et non commentées :
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes

# Redémarrer SSH si des modifications sont nécessaires
sudo systemctl restart ssh
```

#### Test de Connexion
```bash
# Tester la connexion depuis une autre machine
ssh tdarde@votre-serveur-ip

# Ou localement
ssh tdarde@localhost
```

### 2. 🔐 Configuration GitHub Environment

Dans **Settings** → **Environments** → **DEV_SCILICIUM**, ajouter les secrets :

| Secret | Valeur | Description |
|--------|--------|-------------|
| `DEV_SERVER_HOST` | `192.168.1.100` | IP ou domaine du serveur |
| `DEV_SERVER_USER` | `tdarde` | Nom d'utilisateur SSH |
| `DEV_SERVER_PASSWORD` | `votre_mot_de_passe` | Mot de passe du compte |

### 3. 🧪 Test des Credentials

```bash
# Depuis une machine externe, tester :
ssh tdarde@votre-serveur-ip
# Entrer le mot de passe

# Si succès, les credentials sont corrects
```

## 🚀 Workflow Mis à Jour

### Nouvelles Fonctionnalités

#### Installation Automatique de sshpass
```yaml
- name: Setup SSH connection with password
  run: |
    # Install sshpass for password authentication
    sudo apt-get update && sudo apt-get install -y sshpass
    
    # Test SSH connection
    sshpass -p "${{ secrets.DEV_SERVER_PASSWORD }}" ssh -o StrictHostKeyChecking=no \
      ${{ secrets.DEV_SERVER_USER }}@${{ secrets.DEV_SERVER_HOST }} 'echo "Connection successful"'
```

#### Connexions SSH Simplifiées
```yaml
# Toutes les commandes SSH utilisent maintenant :
sshpass -p "${{ secrets.DEV_SERVER_PASSWORD }}" ssh -o StrictHostKeyChecking=no \
  ${{ secrets.DEV_SERVER_USER }}@${{ secrets.DEV_SERVER_HOST }} 'commande'

# Transfer de fichiers :
sshpass -p "${{ secrets.DEV_SERVER_PASSWORD }}" scp -o StrictHostKeyChecking=no \
  fichier.tar.gz ${{ secrets.DEV_SERVER_USER }}@${{ secrets.DEV_SERVER_HOST }}:destination/
```

## 📋 Étapes de Migration

### 1. 🗑️ Nettoyer les Anciens Secrets SSH
```bash
# Dans GitHub → Settings → Environments → DEV_SCILICIUM
# Supprimer (optionnel) :
- DEV_SERVER_SSH_KEY (plus nécessaire)
```

### 2. ✅ Ajouter les Nouveaux Secrets
```bash
# Ajouter dans DEV_SCILICIUM :
DEV_SERVER_PASSWORD = mot_de_passe_de_tdarde
```

### 3. 🧪 Test de Déploiement
```bash
# Push pour tester le nouveau workflow
git add .
git commit -m "feat: switch to password authentication"
git push origin main
```

## 🔐 Sécurité et Bonnes Pratiques

### Sécurisation du Mot de Passe

#### Utiliser un Mot de Passe Fort
```bash
# Générer un mot de passe sécurisé
openssl rand -base64 32

# Ou utiliser pwgen
pwgen -s 20 1
```

#### Considérer un Utilisateur Dédié
```bash
# Créer un utilisateur spécifique pour le déploiement
sudo useradd -m -s /bin/bash github-deploy
sudo usermod -aG docker github-deploy

# Lui donner un mot de passe
sudo passwd github-deploy

# Ajuster les permissions
sudo chown -R github-deploy:github-deploy /home/dev/masldatlas
```

### Protection du Serveur

#### Limitation des Connexions SSH
```bash
# Dans /etc/ssh/sshd_config
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Redémarrer SSH
sudo systemctl restart ssh
```

#### Firewall (Optionnel)
```bash
# Limiter SSH à certaines IPs si nécessaire
sudo ufw allow from GITHUB_RUNNER_IP to any port 22
```

## 🎯 Avantages vs Inconvénients

### ✅ Avantages
- **Simplicité de configuration** : Pas de gestion de clés
- **Compatibilité universelle** : Fonctionne partout
- **Debug facile** : Moins de points de défaillance
- **Mise en place rapide** : Configuration en minutes

### ⚠️ Considérations
- **Mot de passe en secret** : Doit être bien protégé
- **Rotation périodique** : Changer le mot de passe régulièrement
- **Utilisateur dédié** : Recommandé pour la sécurité

## 🚀 Résultat Final

Après cette configuration :
- ✅ **Connexions SSH fiables** : Plus d'erreurs de clés
- ✅ **Déploiement simplifié** : Workflow plus robuste
- ✅ **Maintenance réduite** : Moins de composants à gérer
- ✅ **Debugging facile** : Messages d'erreur clairs

---

**Status** : 🔐 AUTHENTIFICATION PAR MOT DE PASSE CONFIGURÉE  
**Next Step** : Configurer DEV_SERVER_PASSWORD dans GitHub  
**Result** : Déploiement automatique simplifié et fiable ✅
