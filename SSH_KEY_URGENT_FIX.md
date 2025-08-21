# 🚨 Dépannage Urgent : Erreur SSH "no key found"

## ⚡ Solution Rapide

Vous avez cette erreur dans GitHub Actions :
```
ssh.ParsePrivateKey: ssh: no key found
ssh: handshake failed: ssh: unable to authenticate
```

### 🔧 Étapes de Résolution (5 minutes)

#### 1. Regénération de la Clé SSH
```bash
cd /Users/tdarde/Documents/GitHub/MASLDatlas
./scripts/setup/generate-ssh-key-github.sh
```

#### 2. Copie de la Clé Privée
```bash
# Affichez la clé privée COMPLÈTE
cat ~/.ssh/github_actions_masldatlas

# ⚠️ IMPORTANT : Copiez TOUT le contenu, y compris :
# -----BEGIN OPENSSH PRIVATE KEY-----
# [tout le contenu]
# -----END OPENSSH PRIVATE KEY-----
```

#### 3. Configuration GitHub (2 minutes)
1. Allez sur : https://github.com/BioMAs/MASLDatlas/settings/environments
2. Cliquez sur `DEV_SCILICIUM`
3. Dans **Environment secrets**, modifiez `DEV_SERVER_SSH_KEY`
4. Collez la clé privée **COMPLÈTE** (avec les `-----BEGIN` et `-----END`)
5. Sauvegardez

#### 4. Configuration Serveur (1 minute)
```bash
# Sur votre serveur de développement
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Ajoutez la clé publique
cat ~/.ssh/github_actions_masldatlas.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### 5. Test Immédiat
```bash
# Test local de la connexion
ssh -i ~/.ssh/github_actions_masldatlas tdarde@VOTRE_IP

# Si succès, relancez GitHub Actions :
git commit --allow-empty -m "fix: Test SSH deployment"
git push origin main
```

## 🔍 Vérifications Rapides

### Clé SSH Valide ?
```bash
ssh-keygen -l -f ~/.ssh/github_actions_masldatlas
# Doit afficher : 256 SHA256:... (ED25519)
```

### Serveur SSH Configuré ?
```bash
# Sur le serveur
sudo grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config
# Doit afficher :
# PubkeyAuthentication yes
# AuthorizedKeysFile .ssh/authorized_keys
```

### Permissions Correctes ?
```bash
# Sur le serveur
ls -la ~/.ssh/
# Doit afficher :
# drwx------ ... .ssh/
# -rw------- ... authorized_keys
```

## 🚀 Alternative Express : Clé Existante

Si vous avez déjà une clé SSH qui fonctionne :

```bash
# Utilisez votre clé SSH existante
cat ~/.ssh/id_rsa  # ou id_ed25519

# Copiez cette clé dans le secret GitHub DEV_SERVER_SSH_KEY
# Assurez-vous que la clé publique est sur le serveur :
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys  # sur le serveur
```

## ⚠️ Points Critiques

1. **Format de Clé** : TOUJOURS copier la clé avec `-----BEGIN` et `-----END`
2. **Retours à la Ligne** : Préservez TOUS les retours à la ligne
3. **Permissions** : `~/.ssh` = 700, `authorized_keys` = 600
4. **Type de Clé** : ED25519 recommandé (plus sécurisé que RSA)

## 📞 Si Ça Ne Marche Toujours Pas

1. **Debug SSH détaillé** :
   ```bash
   ssh -vvv -i ~/.ssh/github_actions_masldatlas tdarde@VOTRE_IP
   ```

2. **Vérifiez les logs serveur** :
   ```bash
   sudo tail -f /var/log/auth.log  # ou /var/log/secure
   ```

3. **Test avec une clé temporaire** :
   ```bash
   ssh-keygen -t ed25519 -f /tmp/test_key -N ""
   ssh-copy-id -i /tmp/test_key tdarde@VOTRE_IP
   ssh -i /tmp/test_key tdarde@VOTRE_IP
   ```

---

**🎯 Objectif** : GitHub Actions doit pouvoir se connecter en SSH avec la clé privée stockée dans le secret `DEV_SERVER_SSH_KEY`.

**✅ Test de Réussite** : Quand GitHub Actions affiche "Transfer source code to Server" sans erreur SSH.

**⏱️ Temps de résolution** : Maximum 5 minutes si vous suivez les étapes dans l'ordre.
