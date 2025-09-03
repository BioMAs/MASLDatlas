# 🐳 MASLDatlas Docker - Guide Simplifié

## 📋 Vue d'Ensemble

Votre application MASLDatlas dispose de deux configurations Docker optimisées :
- **Development/Tests** : Configuration locale avec optimisations de base
- **Production** : Configuration complète avec Traefik et optimisations avancées

## 🚀 Configuration Docker

### 📦 **Pour les Tests Locaux** (`docker-compose.yml`)
```yaml
# Optimisations de base pour développement
- 6GB RAM, 2 CPU cores
- Cache tmpfs 500MB + 1GB temp
- Modules d'optimisation montés
- Health checks simples
```

### 🌐 **Pour la Production** (`docker-compose.prod.yml`)
```yaml
# Configuration production avec Traefik
- 8GB RAM, 4 CPU cores  
- Cache tmpfs 2GB + 1GB temp
- SSL/HTTPS automatique via Traefik
- Sécurité renforcée
- Logging optimisé
```

## 🛠️ Utilisation

### 🔧 **Tests Locaux**
```bash
# Démarrage local avec optimisations
docker-compose up -d

# Accès: http://localhost:3838
# Arrêt: docker-compose down
```

### 🌐 **Déploiement Production**
```bash
# Démarrage automatisé
./scripts/deploy-prod.sh

# Ou manuellement
docker-compose -f docker-compose.prod.yml up -d

# Accès: https://masldatlas.scilicium.com
```

## ⚡ Optimisations Incluses

### 🚀 **Performance**
- **Cache tmpfs** : Cache ultra-rapide en mémoire
- **Modules R optimisés** : Systèmes d'optimisation intégrés
- **Ressources dédiées** : RAM et CPU alloués intelligemment
- **Health checks** : Surveillance automatique

### 🔒 **Production**
- **HTTPS automatique** : Certificats SSL via Traefik
- **Headers de sécurité** : HSTS, XSS protection
- **Compression** : Gzip automatique
- **Logs structurés** : Logging optimisé

## 📊 Performance Attendue

| Configuration | RAM | CPU | Cache | Performance |
|---------------|-----|-----|-------|-------------|
| **Local** | 6GB | 2 cores | 1.5GB | Optimisée |
| **Production** | 8GB | 4 cores | 3GB | Maximale |

## 🔧 Commandes Utiles

### 📊 **Monitoring**
```bash
# Statut des services
docker-compose ps

# Logs en temps réel
docker-compose logs -f

# Métriques ressources
docker stats
```

### 🛠️ **Maintenance**
```bash
# Redémarrage
docker-compose restart

# Mise à jour
docker-compose up -d --build

# Nettoyage
docker-compose down -v
```

## 🎯 Résultat

Vous avez maintenant :
- ✅ **Configuration locale** optimisée pour le développement
- ✅ **Configuration production** avec Traefik et sécurité
- ✅ **Scripts de déploiement** automatisés
- ✅ **Optimisations de performance** intégrées

**Simple, efficace et production-ready ! 🚀**
