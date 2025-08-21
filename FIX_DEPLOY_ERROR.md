# 🚨 Résolution Erreur Deploy-Dev.yml

## ❌ Problème Identifié
L'erreur à la ligne 22 du fichier `deploy-dev.yml` indique que l'environnement `DEV_SCILICIUM` n'existe pas encore dans GitHub.

```yaml
environment: "DEV_SCILICIUM"  # ← Erreur : environnement non trouvé
```

## ✅ Solution : Créer l'Environnement GitHub

### 1. 🏗️ Créer l'Environnement
1. Allez sur : `https://github.com/BioMAs/MASLDatlas`
2. **Settings** → **Environments** → **New environment**
3. Nom : `DEV_SCILICIUM`
4. **Configure environment**

### 2. 🔧 Configuration Minimale
Dans l'environnement `DEV_SCILICIUM` :

#### Protection Rules
```yaml
✅ Required branches: 
   - main
   - develop
```

#### Environment Secrets (Requis)
```yaml
DEV_SERVER_SSH_KEY  : [Clé SSH privée]
DEV_SERVER_HOST     : [IP de votre serveur]  
DEV_SERVER_USER     : tdarde
```

### 3. 🎯 Après Création
Une fois l'environnement créé, l'erreur disparaîtra automatiquement et le workflow fonctionnera.

## 🚀 Création Rapide des Secrets

### Obtenir la Clé SSH
```bash
# Sur votre serveur, après setup-dev-server.sh
sudo cat /home/tdarde/.ssh/github_actions
```

### Obtenir l'IP du Serveur
```bash
# Sur votre serveur
hostname -I | awk '{print $1}'
# ou
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### Configuration dans GitHub
1. **Settings** → **Environments** → **DEV_SCILICIUM**
2. **Environment secrets** → **Add secret**
3. Ajouter les 3 secrets requis

## ✅ Vérification
Après création de l'environnement :
- ❌ L'erreur de linting disparaîtra
- ✅ Le workflow sera valide
- 🚀 Le déploiement automatique fonctionnera

## 🔄 Test Immédiat
```bash
# Push pour tester
git add .
git commit -m "fix: create DEV_SCILICIUM environment"
git push origin main
```

---

**Status** : ⚠️ ENVIRONNEMENT REQUIS  
**Action** : Créer `DEV_SCILICIUM` dans GitHub Settings → Environments
