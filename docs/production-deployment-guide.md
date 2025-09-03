# 🚀 Guide de Déploiement Production MASLDatlas

## 📋 **Étapes sur le serveur de production**

### 🖥️ **1. Préparation du serveur**

```bash
# Connexion SSH au serveur
ssh user@masldatlas.scilicium.com

# Mise à jour système
sudo apt update && sudo apt upgrade -y

# Installation Docker
sudo apt install docker.io docker-compose-plugin -y
sudo systemctl enable docker
sudo systemctl start docker

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
# Redémarrer la session SSH après cette commande
```

### 🌐 **2. Installation Traefik**

```bash
# Création du réseau Traefik
sudo docker network create web

# Configuration Traefik (voir docs/traefik-setup.md)
sudo mkdir -p /opt/traefik
cd /opt/traefik

# Créer les fichiers de configuration Traefik
# (Copier le contenu de docs/traefik-setup.md)

# Démarrer Traefik
sudo docker-compose up -d
```

### 📦 **3. Déploiement MASLDatlas**

```bash
# Cloner le projet
cd /opt
sudo git clone https://github.com/BioMAs/MASLDatlas.git
sudo chown -R $USER:$USER MASLDatlas
cd MASLDatlas

# Déploiement automatique
chmod +x scripts/deploy-prod.sh
./scripts/deploy-prod.sh
```

## 🔍 **4. Vérifications**

### ✅ **Vérifier les services**

```bash
# Statut des conteneurs
docker-compose -f docker-compose.prod.yml ps

# Logs de l'application
docker-compose -f docker-compose.prod.yml logs -f masldatlas

# Logs Traefik
cd /opt/traefik && docker-compose logs -f traefik
```

### 🌐 **Tester l'application**

```bash
# Test local
curl -f http://localhost:3838

# Test via Traefik
curl -f https://masldatlas.scilicium.com
```

## 🛠️ **5. Commandes utiles**

### 🔄 **Redémarrage**

```bash
# Redémarrer l'application
docker-compose -f docker-compose.prod.yml restart

# Redémarrer avec reconstruction
docker-compose -f docker-compose.prod.yml up -d --build
```

### 📊 **Monitoring**

```bash
# Ressources utilisées
docker stats

# Espace disque
df -h

# Logs système
sudo journalctl -u docker.service
```

### 🆕 **Mise à jour**

```bash
# Mettre à jour le code
git pull origin main

# Redéployer
./scripts/deploy-prod.sh
```

## 🎯 **Résultat attendu**

Une fois déployé, votre application sera accessible :

- ✅ **HTTPS automatique** : `https://masldatlas.scilicium.com`
- ✅ **Performance optimisée** : 8GB RAM, 4 CPU, cache tmpfs
- ✅ **Sécurité** : Headers de sécurité, certificats SSL
- ✅ **Monitoring** : Health checks automatiques

## 🆘 **Dépannage**

### 🚨 **Si l'application ne démarre pas**

```bash
# Vérifier les erreurs
docker-compose -f docker-compose.prod.yml logs masldatlas

# Vérifier l'espace disque
df -h

# Redémarrer Docker
sudo systemctl restart docker
```

### 🌐 **Si le HTTPS ne fonctionne pas**

```bash
# Vérifier Traefik
cd /opt/traefik
docker-compose logs traefik

# Vérifier les certificats
docker exec traefik cat /acme.json
```
