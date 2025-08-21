# 🌟 Configuration Environnement DEV_SCILICIUM

Ce guide vous explique comment configurer l'environnement GitHub `DEV_SCILICIUM` pour le déploiement automatique de MASLDatlas.

## 🎯 Pourquoi un Environnement GitHub ?

Les environnements GitHub offrent :
- **🔐 Sécurité renforcée** : Secrets isolés par environnement
- **👥 Contrôle d'accès** : Restrictions sur qui peut déployer
- **📋 Approbations** : Validation requise avant déploiement
- **🕒 Délais** : Attente avant déploiement automatique
- **🌿 Protection des branches** : Déploiement sur branches spécifiques

## 📋 Étapes de Configuration

### 1. 🏗️ Créer l'Environnement

1. **Accédez à votre repository** : `https://github.com/BioMAs/MASLDatlas`
2. **Settings** → **Environments** → **New environment**
3. **Nom de l'environnement** : `DEV_SCILICIUM`
4. **Configure environment**

### 2. ⚙️ Configuration de l'Environnement

Dans la page de configuration de `DEV_SCILICIUM` :

#### Protection Rules (Recommandé)
```yaml
✅ Restrict deployments to selected branches:
   - main
   - develop
```

#### Required Reviewers (Optionnel)
```yaml
☐ Required reviewers (pour validation manuelle)
   - Ajouter les utilisateurs autorisés
```

#### Wait Timer (Optionnel)
```yaml
☐ Wait timer: 0 minutes (ou délai souhaité)
```

### 3. 🔑 Configuration des Secrets

Dans la section **Environment secrets** :

#### Secret 1: DEV_SERVER_SSH_KEY
```bash
# Nom du secret
DEV_SERVER_SSH_KEY

# Valeur (clé SSH privée générée par le script)
# Exécutez sur votre serveur :
sudo cat /home/tdarde/.ssh/github_actions
```

#### Secret 2: DEV_SERVER_HOST
```bash
# Nom du secret
DEV_SERVER_HOST

# Valeur (IP ou domaine de votre serveur)
# Exemples :
192.168.1.100          # IP locale
dev.scilicium.fr       # Domaine
scilicium-dev.com      # Sous-domaine
```

#### Secret 3: DEV_SERVER_USER
```bash
# Nom du secret
DEV_SERVER_USER

# Valeur
tdarde
```

## 🚀 Configuration Complète

Voici un exemple de configuration complète pour `DEV_SCILICIUM` :

### Variables d'Environnement GitHub
```yaml
Environment: DEV_SCILICIUM
Protection Rules:
  ✅ Required branches: main, develop
  ☐ Required reviewers: (optionnel)
  ☐ Wait timer: 0 minutes

Environment Secrets:
  🔑 DEV_SERVER_SSH_KEY: -----BEGIN OPENSSH PRIVATE KEY-----...
  🌐 DEV_SERVER_HOST: 192.168.1.100
  👤 DEV_SERVER_USER: tdarde
```

### Workflow Configuration
Le workflow utilise automatiquement l'environnement :

```yaml
jobs:
  deploy-dev:
    environment: DEV_SCILICIUM  # ← Utilise l'environnement
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: |
          ssh ${{ secrets.DEV_SERVER_USER }}@${{ secrets.DEV_SERVER_HOST }}
```

## 🧪 Test de Configuration

### 1. Vérification des Secrets
```bash
# Dans GitHub Actions, les secrets apparaîtront comme :
echo "Host: ${{ secrets.DEV_SERVER_HOST }}"     # → Host: ***
echo "User: ${{ secrets.DEV_SERVER_USER }}"     # → User: ***
echo "SSH Key: ${{ secrets.DEV_SERVER_SSH_KEY }}" # → SSH Key: ***
```

### 2. Test de Connexion
Le workflow testera automatiquement :
```bash
# Test SSH dans le workflow
ssh-keyscan -H ${{ secrets.DEV_SERVER_HOST }} >> ~/.ssh/known_hosts
ssh ${{ secrets.DEV_SERVER_USER }}@${{ secrets.DEV_SERVER_HOST }} 'echo "Connection successful"'
```

## 📊 Avantages de cette Configuration

### Sécurité
- ✅ **Secrets isolés** : Séparés par environnement
- ✅ **Accès contrôlé** : Restriction aux branches autorisées
- ✅ **Audit** : Logs des déploiements par environnement

### Flexibilité
- ✅ **Multi-environnements** : Peut créer PROD_SCILICIUM, TEST_SCILICIUM, etc.
- ✅ **Configuration spécifique** : Variables par environnement
- ✅ **Déploiements conditionnels** : Selon les branches

### Monitoring
- ✅ **Historique** : Déploiements par environnement
- ✅ **Status** : État de chaque environnement
- ✅ **Notifications** : Alertes spécifiques

## 🔄 Workflow de Déploiement

### Déclenchement Automatique
```bash
# Push sur main → Déploiement automatique
git push origin main

# Push sur develop → Déploiement automatique  
git push origin develop
```

### Déclenchement Manuel
1. **Actions** → **Deploy to Development Server**
2. **Run workflow** → **Use workflow from Branch: main**
3. **✅ Force rebuild datasets** (si nécessaire)
4. **Run workflow**

### Processus de Déploiement
```mermaid
graph TD
    A[Push Code] --> B[GitHub Actions]
    B --> C[Environment: DEV_SCILICIUM]
    C --> D[Load Secrets]
    D --> E[SSH Connection]
    E --> F[Deploy to /home/dev/masldatlas]
    F --> G[Health Check]
    G --> H[Success Notification]
```

## 🛠️ Maintenance

### Rotation des Clés SSH
```bash
# Sur le serveur
sudo -u tdarde ssh-keygen -t ed25519 -f /home/tdarde/.ssh/github_actions_new

# Mise à jour du secret GitHub
# Settings → Environments → DEV_SCILICIUM → Update DEV_SERVER_SSH_KEY
```

### Changement d'Adresse IP
```bash
# Mise à jour du secret
# Settings → Environments → DEV_SCILICIUM → Update DEV_SERVER_HOST
```

### Test de Santé
```bash
# Vérification manuelle
ssh tdarde@your-server-ip
cd /home/dev/masldatlas
docker ps | grep masldatlas
curl http://localhost:3838
```

## 📞 Support

### Problèmes Courants

#### ❌ Environment not found
- Vérifiez que `DEV_SCILICIUM` est créé dans Settings → Environments

#### ❌ Secret not accessible
- Vérifiez que les secrets sont ajoutés à l'environnement, pas au repository

#### ❌ SSH connection failed
- Testez manuellement : `ssh tdarde@your-server`
- Vérifiez la clé SSH dans les secrets

### Logs de Debug
```bash
# Dans GitHub Actions
Actions → Deploy to Development Server → Workflow run → View logs

# Sur le serveur
docker logs masldatlas-dev
tail -f /home/dev/masldatlas/logs/deploy.log
```

---

🎉 **Votre environnement DEV_SCILICIUM est maintenant configuré !**

**Prochaine étape** : Testez le déploiement en poussant du code sur la branche `main`.
