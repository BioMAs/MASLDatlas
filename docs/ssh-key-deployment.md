# 🔑 Déploiement avec Clés SSH et Actions Appleboy

Ce guide explique comment configurer le déploiement automatique avec des clés SSH en utilisant les actions GitHub robustes `appleboy/scp-action` et `appleboy/ssh-action`.

## 🎯 Avantages de cette Approche

### ✅ Actions Dédiées
- **appleboy/scp-action** : Transfert de fichiers optimisé et robuste
- **appleboy/ssh-action** : Exécution de commandes SSH avec gestion d'erreurs avancée
- **Timeout** : Protection contre les blocages avec `timeout-minutes: 30`

### ✅ Sécurité Renforcée
- Authentification par clé SSH (plus sécurisée que mot de passe)
- Gestion automatique des `known_hosts`
- Pas d'exposition de mots de passe dans les logs

### ✅ Robustesse
- Gestion d'erreurs intégrée
- Retry automatique en cas d'échec temporaire
- Logs détaillés pour le debugging

## 🔧 Configuration Requise

### 1. Secrets GitHub (Environnement DEV_SCILICIUM)

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DEV_SERVER_HOST` | Adresse IP/domaine du serveur | `192.168.1.100` |
| `DEV_SERVER_USER` | Nom d'utilisateur SSH | `tdarde` |
| `DEV_SERVER_SSH_KEY` | Clé SSH privée complète | `-----BEGIN OPENSSH...` |

### 2. Génération de la Clé SSH

Utilisez le script fourni :
```bash
# Génère automatiquement la clé SSH
./scripts/setup/generate-ssh-key-github.sh

# La clé publique sera affichée pour ajout au serveur
cat ~/.ssh/masldatlas_github_deploy.pub
```

### 3. Configuration Serveur

Ajoutez la clé publique au serveur :
```bash
# Sur le serveur de développement
echo "ssh-rsa AAAAB3NzaC1yc2E..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## 🚀 Workflow Amélioré

### Structure du Nouveau Workflow

```yaml
name: Deploy MASLDatlas to Development Server

jobs:
  deploy-dev:
    timeout-minutes: 30  # Protection contre les blocages
    steps:
    - name: Transfer source code to Server
      uses: appleboy/scp-action@master
      with:
        host: ${{ secrets.DEV_SERVER_HOST }}
        username: ${{ secrets.DEV_SERVER_USER }}
        key: ${{ secrets.DEV_SERVER_SSH_KEY }}
        source: "."
        target: "/home/dev/masldatlas"
        overwrite: true

    - name: Setup datasets and deploy application
      uses: appleboy/ssh-action@master
      with:
        host: ${{ secrets.DEV_SERVER_HOST }}
        username: ${{ secrets.DEV_SERVER_USER }}
        key: ${{ secrets.DEV_SERVER_SSH_KEY }}
        script: |
          cd /home/dev/masldatlas
          docker-compose down || true
          docker-compose up -d --build --force-recreate
```

### 🔄 Processus de Déploiement

1. **Transfert de Code** : `appleboy/scp-action` transfère tous les fichiers
2. **Déploiement Unifié** : Une seule action SSH pour tout le processus
3. **Gestion d'Erreurs** : Timeout et retry automatiques
4. **Nettoyage** : Job séparé pour maintenance

## 🛠️ Fonctionnalités Intégrées

### 📦 Gestion des Sauvegardes
```bash
# Backup automatique avant déploiement
BACKUP_DIR="/home/dev/masldatlas_backup_$(date +%Y%m%d_%H%M%S)"
cp -r "/home/dev/masldatlas" "$BACKUP_DIR"
```

### 🏥 Health Check Avancé
```bash
# Vérification avec timeout et retry
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

### 🧹 Nettoyage Automatique
```bash
# Garde seulement les 5 sauvegardes les plus récentes
ls -dt /home/dev/masldatlas_backup_* | tail -n +6 | xargs rm -rf

# Nettoie les ressources Docker anciennes
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

Active avec :
- Interface GitHub Actions
- `force_rebuild: true` dans le workflow

### Branches Supportées
- `main` : Déploiement production
- `develop` : Déploiement développement

## 🐛 Debugging et Monitoring

### Logs Détaillés
```bash
# Logs de conteneur en cas d'échec
docker logs masldatlas-dev --tail 50

# Status complet du déploiement
docker-compose ps
docker ps | grep masldatlas
```

### Vérification Manuelle
```bash
# Test de connexion SSH
ssh -i ~/.ssh/masldatlas_github_deploy tdarde@192.168.1.100

# Vérification application
curl http://192.168.1.100:3838/
```

## 📊 Monitoring du Déploiement

Le workflow génère automatiquement un rapport de déploiement incluant :

- ⏰ Heure de déploiement
- 🌿 Branche et commit déployés
- 👤 Auteur du déploiement
- 🐳 Status des conteneurs
- 📊 Status des datasets
- 💾 Utilisation disque

## 🔍 Résolution de Problèmes

### ❌ Erreur : "ssh: no key found" / "ssh: handshake failed"

**Symptômes** :
```
2025/08/21 09:23:38 ssh.ParsePrivateKey: ssh: no key found
error copy file to dest: ***, error message: ssh: handshake failed: ssh: unable to authenticate
```

**Causes et Solutions** :

#### 1. 🔧 Format de Clé SSH Incorrect

**Problème** : La clé SSH dans le secret GitHub n'est pas au bon format.

**Solution** :
```bash
# 1. Générez une nouvelle clé SSH
./scripts/setup/generate-ssh-key-github.sh

# 2. Copiez EXACTEMENT la clé privée complète (avec les retours à la ligne)
cat ~/.ssh/github_actions_masldatlas

# 3. Dans GitHub : Settings → Environments → DEV_SCILICIUM → DEV_SERVER_SSH_KEY
# Collez la clé COMPLÈTE incluant :
# -----BEGIN OPENSSH PRIVATE KEY-----
# [contenu de la clé]
# -----END OPENSSH PRIVATE KEY-----
```

#### 2. 🔑 Clé Publique Non Ajoutée au Serveur

**Problème** : La clé publique correspondante n'est pas sur le serveur.

**Solution** :
```bash
# Sur votre serveur de développement
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Ajoutez la clé publique (générée par le script)
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... github-actions-masldatlas-tdarde" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Vérifiez les permissions
ls -la ~/.ssh/
```

#### 3. 🚫 Configuration SSH Serveur Restrictive

**Problème** : Le serveur refuse l'authentification par clé.

**Solution** :
```bash
# Sur le serveur, vérifiez /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config

# Assurez-vous que ces lignes sont présentes et activées :
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no  # (optionnel, pour sécurité)

# Redémarrez SSH
sudo systemctl restart sshd
```

#### 4. 🔐 Test Manuel de la Clé

**Vérification complète** :
```bash
# 1. Test local de la clé
ssh-keygen -l -f ~/.ssh/github_actions_masldatlas
# Doit afficher : 256 SHA256:... github-actions-masldatlas-user (ED25519)

# 2. Test de connexion manuelle
ssh -i ~/.ssh/github_actions_masldatlas -o StrictHostKeyChecking=no tdarde@VOTRE_IP

# 3. Debug verbose si échec
ssh -vvv -i ~/.ssh/github_actions_masldatlas tdarde@VOTRE_IP
```

#### 5. 🔄 Alternative : Regénération Complète

Si le problème persiste :
```bash
# 1. Supprimez l'ancienne clé
rm -f ~/.ssh/github_actions_masldatlas*

# 2. Regénérez
./scripts/setup/generate-ssh-key-github.sh

# 3. Reconfigurez les secrets GitHub
# 4. Réajoutez la clé publique au serveur
```

### Échec de Connexion SSH
```bash
# Vérifier la clé SSH
ssh-keygen -l -f ~/.ssh/masldatlas_github_deploy

# Tester la connexion
ssh -vvv -i ~/.ssh/masldatlas_github_deploy tdarde@host
```

### Timeout de Déploiement
- Le workflow a un timeout de 30 minutes
- Les health checks ont 12 tentatives (2 minutes)
- Ajustez selon vos besoins serveur

### Erreurs Docker
```bash
# Vérifier l'espace disque
df -h

# Nettoyer manuellement
docker system prune -f --volumes
```

## 📚 Ressources

- [appleboy/scp-action](https://github.com/appleboy/scp-action)
- [appleboy/ssh-action](https://github.com/appleboy/ssh-action)
- [Documentation SSH Keys GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

---

Cette approche garantit un déploiement **robuste**, **sécurisé** et **maintenable** pour votre application MASLDatlas ! 🚀
