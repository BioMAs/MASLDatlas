# 🚀 Configuration Express : Déploiement par Mot de Passe

## ⚡ Setup Rapide (3 minutes)

### 1. Configuration GitHub Secrets

Allez dans : **https://github.com/BioMAs/MASLDatlas/settings/environments**

1. Cliquez sur `DEV_SCILICIUM`
2. Dans **Environment secrets**, ajoutez/modifiez :

| Secret | Valeur |
|--------|--------|
| `DEV_SERVER_HOST` | L'IP de votre serveur (ex: `192.168.1.100`) |
| `DEV_SERVER_USER` | `tdarde` |
| `DEV_SERVER_PASSWORD` | Votre mot de passe SSH |

### 2. Vérification Serveur SSH

Sur votre serveur, vérifiez que SSH accepte les mots de passe :

```bash
# Vérifiez la configuration SSH
sudo grep PasswordAuthentication /etc/ssh/sshd_config
# Doit afficher : PasswordAuthentication yes

# Si non configuré, modifiez :
sudo nano /etc/ssh/sshd_config
# Changez en : PasswordAuthentication yes
# Puis : sudo systemctl restart sshd
```

### 3. Test de Connexion

```bash
# Testez la connexion SSH
ssh tdarde@VOTRE_IP
# Saisissez votre mot de passe quand demandé
```

### 4. Déclenchement du Déploiement

```bash
# Depuis votre projet local
git commit --allow-empty -m "test: Deploy with password auth"
git push origin main
```

## ✅ Workflow Configuré

Le workflow utilise maintenant :
- **appleboy/scp-action** avec `password:` au lieu de `key:`
- **appleboy/ssh-action** avec `password:` au lieu de `key:`
- **Aucune clé SSH** requise

## 🔧 Avantages Immédiats

1. **Simplicité** : Plus de gestion de clés SSH complexes
2. **Compatibilité** : Fonctionne avec tous les serveurs SSH standards  
3. **Debugging** : Plus facile de tester et diagnostiquer
4. **Rapidité** : Configuration en 3 minutes maximum

## 🎯 Si Ça Ne Marche Pas

### Problème : Authentification échoue
```bash
# Sur le serveur, vérifiez les logs
sudo tail -f /var/log/auth.log

# Testez manuellement
ssh -v tdarde@VOTRE_IP
```

### Problème : SSH refuse les mots de passe
```bash
# Activez l'authentification par mot de passe
sudo sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## 📊 Status Final

Une fois configuré, votre déploiement automatique :
- ✅ Se déclenche sur push vers `main` ou `develop`
- ✅ Transfère tous les fichiers vers `/home/dev/masldatlas`
- ✅ Redémarre Docker avec `docker-compose up -d --build --force-recreate`
- ✅ Effectue un health check sur `http://VOTRE_IP:3838`
- ✅ Nettoie automatiquement les anciennes sauvegardes

**🚀 Votre pipeline CI/CD est prêt !**
