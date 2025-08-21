# 🚀 Déploiement Automatique MASLDatlas

Ce guide vous explique comment configurer le déploiement automatique de MASLDatlas sur votre serveur de développement via GitHub Actions.

## 🎯 Vue d'ensemble

Le système de déploiement automatique permet de :
- **Déployer automatiquement** lors des pushs sur `main` ou `develop`
- **Gérer les volumes** et datasets de façon optimisée
- **Sauvegarder** automatiquement avant chaque déploiement
- **Monitorer** la santé de l'application
- **Nettoyer** les anciens déploiements

## 📋 Guide de Configuration Rapide

### 1. 🔧 Configuration du Serveur

Sur votre serveur de développement, exécutez :

```bash
# Téléchargez ou clonez le repository
git clone https://github.com/BioMAs/MASLDatlas.git
cd MASLDatlas

# Exécutez le script de configuration
./scripts/setup/setup-dev-server.sh

# Testez la configuration
./scripts/setup/test-dev-server.sh
```

### 2. 🔑 Configuration GitHub Secrets

Allez dans **Settings** → **Environments** → **New environment** et créez l'environnement `DEV_SCILICIUM`, puis ajoutez :

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DEV_SERVER_SSH_KEY` | Clé SSH privée | Générée par le script de setup |
| `DEV_SERVER_HOST` | IP/Domaine du serveur | `192.168.1.100` |
| `DEV_SERVER_USER` | Utilisateur SSH | `tdarde` |

📚 **Guide détaillé** : [docs/environment-dev-scilicium.md](docs/environment-dev-scilicium.md)

### 3. 🚀 Premier Déploiement

Poussez du code sur la branche `main` :

```bash
git add .
git commit -m "feat: enable automatic deployment"
git push origin main
```

Le déploiement se lance automatiquement ! 🎉

## 📁 Structure de Déploiement

```
/home/dev/masldatlas/
├── app.R                          # Application Shiny
├── docker-compose.yml             # Configuration Docker
├── Dockerfile                     # Image Docker
├── datasets/                      # Datasets (12GB, volumes montés)
│   ├── Human/
│   ├── Mouse/
│   ├── Zebrafish/
│   └── Integrated/
├── config/                        # Configuration
├── enrichment_sets/               # Sets d'enrichissement
├── scripts/                       # Scripts de gestion
└── logs/                          # Logs d'application
```

> **Note** : Le déploiement utilise l'environnement GitHub `DEV_SCILICIUM` pour une sécurité renforcée.

## 🔄 Workflows Disponibles

### 1. Deploy to Development Server
- **Déclencheur** : Push sur `main` ou `develop`
- **Actions** : 
  - Sauvegarde de l'ancien déploiement
  - Déploiement du nouveau code
  - Gestion des datasets
  - Build et démarrage Docker
  - Tests de santé
  - Nettoyage

### 2. Manual Deployment
- **Déclencheur** : Manuel via l'interface GitHub
- **Options** : Force rebuild des datasets
- **Usage** : Actions → Deploy to Development Server → Run workflow

## 📊 Monitoring

### Logs GitHub Actions
- **Accès** : Repository → Actions → Workflow run
- **Contenu** : Logs détaillés de chaque étape
- **Debug** : Messages d'erreur et statuts

### Logs Serveur
```bash
# Logs du conteneur
docker logs masldatlas-dev -f

# Status de l'application
curl http://localhost:3838

# Status des datasets
cd /home/dev/masldatlas
./scripts/dataset-management/manage_volume.sh status
```

## 🛠️ Commandes Utiles

### Sur le Serveur de Développement

```bash
# Accéder au projet
cd /home/dev/masldatlas

# Voir les conteneurs
docker ps | grep masldatlas

# Redémarrer l'application
docker-compose restart masldatlas

# Voir l'usage disque
du -sh datasets/

# Logs en temps réel
docker logs -f masldatlas-dev

# Reconstruire complètement
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Via GitHub Actions

```bash
# Déploiement manuel avec rebuild
# → Actions → Deploy to Development Server
# → ✅ Force rebuild datasets

# Monitoring via curl
curl -I http://votre-serveur:3838
```

## 🚨 Dépannage

### Problème de Connexion SSH

```bash
# Test de connexion
ssh dev@votre-serveur

# Vérification des clés
ls -la /home/dev/.ssh/

# Permissions correctes
chmod 600 /home/dev/.ssh/github_actions
chmod 644 /home/dev/.ssh/github_actions.pub
```

### Problème Docker

```bash
# Redémarrage Docker
sudo systemctl restart docker

# Nettoyage
docker system prune -a

# Vérification des groupes
groups dev | grep docker
```

### Problème de Datasets

```bash
# Re-téléchargement
cd /home/dev/masldatlas
./scripts/dataset-management/manage_volume.sh download

# Vérification
./scripts/dataset-management/manage_volume.sh status

# Test de l'accès
ls -la datasets/Human/
```

### Problème d'Espace Disque

```bash
# Vérification de l'espace
df -h /home/dev/masldatlas

# Nettoyage des anciens backups
rm -rf /home/dev/masldatlas_backup_*

# Nettoyage Docker
docker system prune -a --volumes
```

## 🔧 Configuration Avancée

### Personnalisation des Branches

Pour déployer sur d'autres branches, modifiez `.github/workflows/deploy-dev.yml` :

```yaml
on:
  push:
    branches: [ main, develop, feature/my-branch ]
```

### Variables d'Environnement

Ajustez selon vos besoins dans le docker-compose :

```yaml
environment:
  - AUTO_DOWNLOAD_DATASETS=true
  - SKIP_DATASET_CHECK=false
  - R_LIBS_USER=/app/rlibs
```

### Ressources Docker

Modifiez les limites dans `docker-compose.prod.yml` :

```yaml
deploy:
  resources:
    limits:
      memory: 8G        # Augmenter si nécessaire
      cpus: '4.0'       # Augmenter si nécessaire
```

## 📈 Performance et Optimisation

### Temps de Déploiement
- **Premier déploiement** : ~10-15 minutes (avec datasets)
- **Déploiements suivants** : ~2-5 minutes (volumes réutilisés)
- **Build seulement** : ~30 secondes (layers Docker cached)

### Optimisations
- ✅ Datasets en volumes externes (pas dans l'image)
- ✅ Cache Docker pour les layers
- ✅ Téléchargement conditionnel des datasets
- ✅ Nettoyage automatique des anciens backups

## 💡 Bonnes Pratiques

1. **Tests locaux** avant push
2. **Monitoring** des logs après déploiement
3. **Sauvegarde** des données importantes
4. **Mise à jour régulière** des dépendances système
5. **Nettoyage périodique** Docker et datasets

## 📞 Support

En cas de problème :

1. **Consultez les logs** GitHub Actions
2. **Vérifiez les prérequis** avec `./scripts/setup/test-dev-server.sh`
3. **Testez la connectivité** SSH manuellement
4. **Consultez la documentation** dans `docs/`

---

🎉 **Félicitations !** Votre environnement de déploiement automatique est maintenant configuré et opérationnel.
