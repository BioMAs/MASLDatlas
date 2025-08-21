# 🔑 Déploiement avec Mot de Passe et Actions Appleboy

Ce guide explique comment configurer le déploiement automatique avec authentification par **mot de passe** en utilisant les actions GitHub robustes `appleboy/scp-action` et `appleboy/ssh-action`.

## 🎯 Avantages de cette Approche

### ✅ Simplicité Maximum
- **Pas de clés SSH** : Aucune génération ou gestion de clés complexes
- **Authentification directe** : Utilise le mot de passe utilisateur standard
- **Configuration rapide** : 3 secrets seulement à configurer

### ✅ Actions Robustes
- **appleboy/scp-action** : Transfert de fichiers optimisé avec mot de passe
- **appleboy/ssh-action** : Exécution de commandes SSH sécurisée
- **Timeout intégré** : Protection contre les blocages avec `timeout-minutes: 30`

### ✅ Compatibilité
- Fonctionne avec tous les serveurs SSH standards
- Pas de configuration SSH spéciale requise
- Support natif des mots de passe dans les actions appleboy

## 🔧 Configuration Requise

### 1. Secrets GitHub (Environnement DEV_SCILICIUM)

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DEV_SERVER_HOST` | Adresse IP/domaine du serveur | `192.168.1.100` |
| `DEV_SERVER_USER` | Nom d'utilisateur SSH | `tdarde` |
| `DEV_SERVER_PASSWORD` | Mot de passe utilisateur | `VotreMotDePasseFort123!` |

### 2. Configuration Serveur SSH

Assurez-vous que votre serveur accepte l'authentification par mot de passe :

```bash
# Sur le serveur, vérifiez /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config

# Assurez-vous que ces lignes sont configurées :
PasswordAuthentication yes
PubkeyAuthentication yes
AuthenticationMethods password

# Redémarrez SSH si modifications
sudo systemctl restart sshd
```

### 3. Vérification de Connexion

Testez la connexion SSH avec mot de passe :
```bash
ssh tdarde@VOTRE_IP
# Saisissez votre mot de passe quand demandé
```

## 🚀 Workflow Configuré

### Structure du Workflow

```yaml
name: Deploy MASLDatlas to Development Server

jobs:
  deploy-dev:
    timeout-minutes: 30
    steps:
    - name: Transfer source code to Server
      uses: appleboy/scp-action@master
      with:
        host: ${{ secrets.DEV_SERVER_HOST }}
        username: ${{ secrets.DEV_SERVER_USER }}
        password: ${{ secrets.DEV_SERVER_PASSWORD }}
        source: "."
        target: "/home/dev/masldatlas"
        overwrite: true

    - name: Setup datasets and deploy application
      uses: appleboy/ssh-action@master
      with:
        host: ${{ secrets.DEV_SERVER_HOST }}
        username: ${{ secrets.DEV_SERVER_USER }}
        password: ${{ secrets.DEV_SERVER_PASSWORD }}
        script: |
          cd /home/dev/masldatlas
          docker-compose down || true
          docker-compose up -d --build --force-recreate
```

### 🔄 Processus de Déploiement

1. **Transfert de Code** : `appleboy/scp-action` transfère tous les fichiers avec mot de passe
2. **Déploiement Unifié** : `appleboy/ssh-action` exécute le déploiement complet
3. **Gestion d'Erreurs** : Timeout et gestion d'erreurs automatiques
4. **Nettoyage** : Job séparé pour maintenance des anciens déploiements

## 🛠️ Fonctionnalités Intégrées

### 📦 Sauvegarde Automatique
```bash
# Backup avant déploiement
BACKUP_DIR="/home/dev/masldatlas_backup_$(date +%Y%m%d_%H%M%S)"
cp -r "/home/dev/masldatlas" "$BACKUP_DIR"
```

### 🏥 Health Check Complet
```bash
# Vérification santé avec retry
max_attempts=12
while [ $attempt -le $max_attempts ]; do
  if curl -f http://localhost:3838/ >/dev/null 2>&1; then
    echo "✅ Application healthy!"
    break
  fi
  sleep 10
  attempt=$((attempt + 1))
done
```

### 🧹 Maintenance Automatique
```bash
# Garde les 5 sauvegardes les plus récentes
ls -dt /home/dev/masldatlas_backup_* | tail -n +6 | xargs rm -rf

# Nettoie Docker
docker system prune -f --filter "until=24h"
```

## 🎛️ Options de Déploiement

### Force Rebuild
```yaml
workflow_dispatch:
  inputs:
    force_rebuild:
      description: 'Force rebuild datasets'
      type: boolean
```

### Branches Supportées
- `main` : Déploiement automatique
- `develop` : Déploiement automatique

## 🔒 Sécurité

### Bonnes Pratiques
1. **Mot de passe fort** : Minimum 12 caractères avec symboles
2. **Rotation régulière** : Changez le mot de passe tous les 3-6 mois
3. **Accès limité** : Utilisateur dédié au déploiement si possible
4. **Logs sécurisés** : Les mots de passe n'apparaissent jamais dans les logs GitHub

### Configuration Sécurisée
```bash
# Créez un utilisateur dédié au déploiement (optionnel)
sudo useradd -m -s /bin/bash deploy-user
sudo usermod -aG docker deploy-user

# Configurez un mot de passe fort
sudo passwd deploy-user
```

## 🐛 Debugging et Monitoring

### Logs Détaillés
```bash
# Vérification des connexions SSH sur le serveur
sudo tail -f /var/log/auth.log | grep ssh

# Logs de conteneur en cas d'échec
docker logs masldatlas-dev --tail 50
```

### Test Manuel
```bash
# Test de connexion
ssh tdarde@192.168.1.100

# Test de l'application
curl http://192.168.1.100:3838/
```

## 📊 Monitoring du Déploiement

Le workflow génère automatiquement :
- ⏰ Rapport de déploiement horodaté
- 🌿 Informations de branche et commit
- 🐳 Status des conteneurs Docker
- 📊 Status des datasets
- 💾 Utilisation disque

## 🔍 Résolution de Problèmes

### Échec d'Authentification
```bash
# Vérifiez que PasswordAuthentication est activé
sudo grep PasswordAuthentication /etc/ssh/sshd_config

# Testez la connexion manuelle
ssh -v tdarde@VOTRE_IP
```

### Timeout de Connexion
```bash
# Vérifiez la connectivité réseau
ping VOTRE_IP

# Vérifiez que SSH écoute
nmap -p 22 VOTRE_IP
```

### Erreurs Docker
```bash
# Vérifiez l'espace disque
df -h

# Permissions Docker
sudo usermod -aG docker $USER
```

## 📚 Avantages par Rapport aux Clés SSH

| Aspect | Mot de Passe | Clés SSH |
|--------|--------------|----------|
| **Simplicité** | ✅ Très simple | ❌ Configuration complexe |
| **Maintenance** | ✅ Aucune | ❌ Rotation des clés |
| **Debugging** | ✅ Facile à tester | ❌ Erreurs cryptiques |
| **Compatibilité** | ✅ Universelle | ❌ Problèmes de format |
| **Setup Initial** | ✅ 5 minutes | ❌ 15-30 minutes |

---

Cette approche garantit un déploiement **simple**, **robuste** et **maintenable** sans la complexité des clés SSH ! 🚀
