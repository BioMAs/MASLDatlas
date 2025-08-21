# 🔧 Résolution Erreur SSH "error in libcrypto"

## ❌ Problème Identifié
L'erreur `Error loading key "(stdin)": error in libcrypto` indique que la clé SSH dans les secrets GitHub n'est pas au bon format ou est corrompue.

## ✅ Solution : Générer et Configurer Correctement la Clé SSH

### 1. 🗝️ Sur Votre Serveur - Générer la Clé SSH

```bash
# Connectez-vous à votre serveur de développement
ssh tdarde@votre-serveur-ip

# Générer une nouvelle clé SSH au format OpenSSH (recommandé)
ssh-keygen -t ed25519 -f ~/.ssh/github_actions_masldatlas -N "" -C "github-actions-masldatlas"

# Ou si ed25519 n'est pas supporté, utilisez RSA
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_actions_masldatlas -N "" -C "github-actions-masldatlas"

# Définir les bonnes permissions
chmod 600 ~/.ssh/github_actions_masldatlas
chmod 644 ~/.ssh/github_actions_masldatlas.pub

# Ajouter la clé publique aux clés autorisées
cat ~/.ssh/github_actions_masldatlas.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 2. 📋 Récupérer la Clé Privée (Format Correct)

```bash
# Afficher la clé privée complète
cat ~/.ssh/github_actions_masldatlas

# La sortie doit ressembler à :
# -----BEGIN OPENSSH PRIVATE KEY-----
# b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAFwAAAAdzc2gtcn
# [... plusieurs lignes de caractères encodés ...]
# -----END OPENSSH PRIVATE KEY-----
```

### 3. 🔐 Configurer le Secret GitHub

1. **Copiez ENTIÈREMENT** la clé privée (y compris les lignes BEGIN/END)
2. Allez dans **GitHub** → **Settings** → **Environments** → **DEV_SCILICIUM**
3. **Environment secrets** → **DEV_SERVER_SSH_KEY**
4. **Collez la clé complète** telle qu'affichée par `cat`

### 4. 🧪 Test Local de la Clé

```bash
# Tester la clé localement
ssh-keygen -l -f ~/.ssh/github_actions_masldatlas

# Sortie attendue :
# 256 SHA256:abc123... github-actions-masldatlas (ED25519)

# Tester la connexion
ssh -i ~/.ssh/github_actions_masldatlas tdarde@localhost
```

## 🔄 Format Clé SSH - Points Importants

### ✅ Format Correct (OpenSSH)
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAFwAAAAdzc2gtcn
NhAAAAAwEAAQAAAQEA2K8xB5p8FqLlKjrZ5R3QmP1K8r7X9QjN0L6VQHt4Y2rKvWN8Qm
[... plus de lignes ...]
-----END OPENSSH PRIVATE KEY-----
```

### ❌ Formats Problématiques
```
# Clé PEM (ancien format) - peut causer des erreurs
-----BEGIN RSA PRIVATE KEY-----

# Clé tronquée
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdj...
# ← Manque la fin !

# Clé avec espaces en début/fin
 -----BEGIN OPENSSH PRIVATE KEY-----
# ← Espace avant
```

## 🛠️ Script Automatique de Génération

```bash
#!/bin/bash
# generate_ssh_key_for_github.sh

echo "🔐 Génération clé SSH pour GitHub Actions MASLDatlas"

# Configuration
KEY_NAME="github_actions_masldatlas"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
USER=$(whoami)

# Générer la clé
echo "📝 Génération de la clé SSH..."
ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "github-actions-masldatlas-$USER"

# Permissions
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

# Ajouter aux authorized_keys
cat "$KEY_PATH.pub" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

echo ""
echo "✅ Clé SSH générée avec succès !"
echo ""
echo "🔑 COPIEZ cette clé privée dans GitHub Secret DEV_SERVER_SSH_KEY :"
echo "════════════════════════════════════════════════════════════════"
cat "$KEY_PATH"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📍 Clé publique (pour référence) :"
cat "$KEY_PATH.pub"
echo ""
echo "🧪 Test de la clé :"
ssh-keygen -l -f "$KEY_PATH"
```

## 🚀 Workflow Mis à Jour

Le workflow a été modifié pour :
- ✅ **Validation de format** : Vérification que la clé est valide
- ✅ **Gestion d'erreurs** : Messages explicites en cas de problème
- ✅ **Debug amélioré** : Logs détaillés pour diagnostiquer

### Étapes de Diagnostic
```yaml
# Le workflow vérifie maintenant :
1. Format de la clé SSH ✓
2. Chargement dans ssh-agent ✓
3. Connexion au serveur ✓
4. Messages d'erreur explicites ✓
```

## 📋 Checklist de Résolution

### ✅ Sur le Serveur
- [ ] Générer nouvelle clé SSH avec `ssh-keygen -t ed25519`
- [ ] Vérifier format avec `ssh-keygen -l -f clé`
- [ ] Ajouter clé publique à `authorized_keys`
- [ ] Tester connexion locale

### ✅ Dans GitHub
- [ ] Copier la clé privée COMPLÈTE (avec BEGIN/END)
- [ ] Mettre à jour secret `DEV_SERVER_SSH_KEY`
- [ ] Vérifier que l'environnement `DEV_SCILICIUM` existe
- [ ] Configurer les autres secrets (HOST, USER)

### ✅ Test Final
- [ ] Push sur main pour déclencher workflow
- [ ] Vérifier logs GitHub Actions
- [ ] Confirmer succès du déploiement

---

**Next**: Une fois la nouvelle clé configurée, le workflow devrait fonctionner parfaitement ! 🎉
