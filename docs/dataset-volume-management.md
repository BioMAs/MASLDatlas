# Dataset Volume Management Guide

## 🎯 Vue d'ensemble

Ce guide explique comment utiliser les volumes Docker pour gérer les datasets de MASLDatlas, au lieu de les embarquer dans l'image Docker. Cette approche offre plusieurs avantages :

- **Images plus légères** : Les datasets ne sont plus inclus dans l'image Docker
- **Flexibilité** : Possibilité de mettre à jour les datasets sans rebuilder l'image
- **Performance** : Accès direct aux datasets via le système de fichiers de l'hôte
- **Sécurité** : Datasets montés en lecture seule en production

## 📁 Structure des Volumes

```
Project Directory/
├── datasets/                   # 📊 Volume monté - Datasets principaux
│   ├── Human/                  # Données scRNA-seq humaines
│   ├── Mouse/                  # Données scRNA-seq murines  
│   ├── Zebrafish/             # Données scRNA-seq zebrafish
│   └── Integrated/            # Données intégrées multi-espèces
├── enrichment_sets/           # 🧬 Données d'enrichissement (plus petites)
├── config/                    # ⚙️ Fichiers de configuration
│   ├── datasets_sources.json  # Sources des datasets
│   └── datasets_config.json   # Configuration de l'application
└── docker-compose.yml         # 🐳 Configuration des volumes
```

## 🚀 Utilisation

### 1. Développement Local

```bash
# Vérifier la configuration des volumes
./scripts/dataset-management/manage_volume.sh status

# Télécharger les datasets dans le volume local
./scripts/dataset-management/manage_volume.sh download

# Démarrer l'application avec volumes montés
docker-compose up -d
```

### 2. Production

```bash
# Configuration des volumes en production
./scripts/deployment/deploy-prod.sh your-domain.com

# Les datasets sont montés en lecture seule
# Mise à jour des datasets :
./scripts/dataset-management/manage_volume.sh download
docker-compose -f docker-compose.prod.yml restart masldatlas
```

## 🛠️ Scripts de Gestion

### Script Principal : `manage_volume.sh`

```bash
# Afficher le statut des volumes
./scripts/dataset-management/manage_volume.sh status

# Vérifier l'accessibilité des volumes
./scripts/dataset-management/manage_volume.sh check

# Télécharger les datasets
./scripts/dataset-management/manage_volume.sh download

# Lister les datasets disponibles
./scripts/dataset-management/manage_volume.sh list

# Nettoyer les datasets
./scripts/dataset-management/manage_volume.sh clean

# Tester le montage Docker
./scripts/dataset-management/manage_volume.sh test
```

## 🐳 Configuration Docker

### Development (docker-compose.yml)
```yaml
services:
  masldatlas:
    build: .
    volumes:
      - ./datasets:/app/datasets                                    # Datasets en lecture/écriture
      - ./config/datasets_config.json:/app/config/datasets_config.json
      - ./config/datasets_sources.json:/app/config/datasets_sources.json
      - ./enrichment_sets:/app/enrichment_sets
```

### Production (docker-compose.prod.yml)
```yaml
services:
  masldatlas:
    volumes:
      - ./datasets:/app/datasets:ro                                 # Datasets en lecture seule
      - ./config/datasets_config.json:/app/config/datasets_config.json:ro
      - ./config/datasets_sources.json:/app/config/datasets_sources.json:ro
      - ./enrichment_sets:/app/enrichment_sets:ro
```

## 🔄 Migration depuis l'Ancienne Approche

### Automatique
```bash
# Les datasets existants sont automatiquement utilisés
# Aucune migration nécessaire si les datasets sont déjà dans ./datasets/
```

### Manuelle
```bash
# Si vous avez des datasets ailleurs, copiez-les :
cp -r /path/to/old/datasets/* ./datasets/

# Ou créez des liens symboliques :
ln -s /path/to/large/storage/datasets ./datasets
```

## 📊 Avantages de l'Approche Volume

### ✅ **Performance**
- Accès direct aux fichiers sans copie
- Pas de latence de réseau pour les datasets locaux
- Cache du système de fichiers optimisé

### ✅ **Flexibilité**
- Mise à jour des datasets sans rebuild
- Possibilité d'utiliser des datasets externes (NFS, etc.)
- Facilite le développement avec différents datasets

### ✅ **Ressources**
- Images Docker plus petites (~500MB vs ~5GB)
- Temps de build réduit
- Moins d'espace disque utilisé

### ✅ **Sécurité**
- Datasets montés en lecture seule en production
- Séparation claire entre application et données
- Possibilité de chiffrement des volumes

## 🚨 Considérations Importantes

### 📝 **Gestion des Permissions**
```bash
# S'assurer que les permissions sont correctes
sudo chown -R $(whoami):$(whoami) ./datasets
chmod -R 755 ./datasets
```

### 💾 **Espace Disque**
```bash
# Vérifier l'espace disponible
df -h .
du -sh ./datasets

# Les datasets peuvent être volumineux (plusieurs GB)
```

### 🔐 **Sécurité des Données**
```bash
# En production, considérer :
# - Chiffrement des volumes
# - Sauvegarde régulière
# - Accès restreint aux datasets
```

## 📋 Checklist de Migration

- [ ] ✅ Dockerfile modifié (plus de COPY datasets)
- [ ] ✅ docker-compose.yml mis à jour avec volumes
- [ ] ✅ docker-compose.prod.yml configuré
- [ ] ✅ Scripts de gestion des volumes créés
- [ ] ✅ .dockerignore mis à jour
- [ ] ✅ Tests de montage des volumes effectués

## 🔧 Dépannage

### Problème : Datasets non trouvés
```bash
# Vérifier le montage des volumes
docker-compose exec masldatlas ls -la /app/datasets

# Vérifier les permissions
./scripts/dataset-management/manage_volume.sh check
```

### Problème : Performance lente
```bash
# Vérifier l'espace disque
df -h
du -sh ./datasets

# Optimiser le stockage (SSD recommandé)
```

### Problème : Échec de téléchargement
```bash
# Télécharger manuellement
./scripts/dataset-management/manage_volume.sh download

# Vérifier la connectivité
curl -I https://github.com/
```

## 📚 Références

- [Docker Volumes Documentation](https://docs.docker.com/storage/volumes/)
- [Docker Compose Volumes](https://docs.docker.com/compose/compose-file/#volumes)
- [Best Practices for Docker Images](https://docs.docker.com/develop/dev-best-practices/)

---

**Note** : Cette approche par volumes est maintenant la méthode recommandée pour gérer les datasets volumineux dans MASLDatlas.
