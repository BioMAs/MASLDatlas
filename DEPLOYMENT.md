# Guide de Déploiement - MASLDatlas v2.0

## Architecture de Déploiement

### Backend : Docker (Local ou Cloud)
Le backend FastAPI est conteneurisé avec Docker et peut être déployé :
- Localement pour le développement
- Sur un serveur cloud (AWS, GCP, Azure)
- Via un service d'hébergement Docker (Railway, Fly.io, Render)

### Frontend : Vercel
Le frontend React/Vite est déployé sur Vercel pour un hébergement optimisé et un déploiement continu.

---

## 🐳 Déploiement Backend (Docker)

### Prérequis
- Docker et Docker Compose installés
- Port 8000 disponible
- Accès aux volumes de données (datasets, config, enrichment_sets)

### Configuration

1. **Créer le fichier d'environnement**
```bash
cp .env.example .env
```

2. **Éditer `.env` avec vos paramètres**
```env
# Production settings
ENVIRONMENT=production
DEBUG=false

# CORS - Ajouter l'URL de votre frontend Vercel
ALLOWED_ORIGINS=https://your-app.vercel.app,http://localhost:5173

# Cache
CACHE_ENABLED=true
CACHE_TTL=3600
```

3. **Démarrer les services**
```bash
# Build et démarrage
docker-compose up -d --build

# Vérifier le statut
docker-compose ps

# Voir les logs
docker-compose logs -f backend
```

4. **Vérifier le health check**
```bash
curl http://localhost:8000/health
```

### Services Inclus

#### Backend (FastAPI)
- **Port** : 8000
- **Health check** : `http://localhost:8000/health`
- **API Docs** : `http://localhost:8000/api/docs`
- **Volumes** :
  - `./datasets` → Données en lecture seule
  - `./config` → Configuration
  - `./enrichment_sets` → Sets d'enrichissement
  - `./cache` → Cache persistant

#### Redis
- **Port** : 6379
- **Volume** : `redis-data` (volume Docker nommé)
- **Usage** : Cache pour améliorer les performances

### Exposition Publique du Backend

Pour que Vercel puisse accéder à votre backend, vous avez plusieurs options :

#### Option 1 : Ngrok (Développement/Test)
```bash
# Installer ngrok
brew install ngrok

# Exposer le port 8000
ngrok http 8000

# Copier l'URL générée (ex: https://abc123.ngrok.io)
# L'utiliser comme VITE_API_URL dans Vercel
```

#### Option 2 : Reverse Proxy Nginx (Production)
Configurer un reverse proxy avec nom de domaine et certificat SSL :
```nginx
server {
    listen 443 ssl;
    server_name api.masldatlas.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Option 3 : Déploiement Cloud
Déployer sur une plateforme cloud :
- **Railway** : `railway up`
- **Fly.io** : `flyctl deploy`
- **Render** : Connect GitHub repo
- **AWS ECS/Fargate** : Utiliser le Dockerfile

---

## ⚡ Déploiement Frontend (Vercel)

### Prérequis
- Compte Vercel
- Vercel CLI : `npm i -g vercel`
- Backend accessible publiquement

### Configuration

1. **Naviguer vers le frontend**
```bash
cd frontend
```

2. **Créer `.env.local` pour le développement**
```bash
cp .env.example .env.local
```

Éditer `.env.local` :
```env
# Pour développement local avec backend Docker
VITE_API_URL=http://localhost:8000/api
```

3. **Installer les dépendances**
```bash
npm install
```

4. **Tester en local**
```bash
npm run dev
# Ouvre http://localhost:5173
```

### Déploiement sur Vercel

#### Méthode 1 : Via CLI (Recommandée)

```bash
# Depuis le dossier frontend/
vercel

# Suivre les instructions :
# - Link to existing project? No
# - Project name: masldatlas
# - Directory: ./
# - Override settings? No
```

**Configurer les variables d'environnement** :
```bash
# Ajouter l'URL de votre backend
vercel env add VITE_API_URL

# Exemple de valeur :
# Production: https://api.masldatlas.com/api
# ou avec ngrok: https://abc123.ngrok.io/api
```

**Déployer en production** :
```bash
vercel --prod
```

#### Méthode 2 : Via Interface Vercel

1. Aller sur [vercel.com](https://vercel.com)
2. **Import Git Repository**
3. Sélectionner votre repo GitHub
4. **Configure Project** :
   - **Framework Preset** : Vite
   - **Root Directory** : `frontend`
   - **Build Command** : `npm run build`
   - **Output Directory** : `dist`

5. **Environment Variables** :
   - Ajouter `VITE_API_URL` avec l'URL de votre backend
   - Exemple : `https://api.masldatlas.com/api`

6. Cliquer sur **Deploy**

### Mise à Jour du CORS

⚠️ **Important** : Une fois votre frontend déployé sur Vercel, mettre à jour le CORS du backend.

1. Récupérer l'URL de votre app Vercel (ex: `https://masldatlas.vercel.app`)

2. Mettre à jour `.env` du backend :
```env
ALLOWED_ORIGINS=https://masldatlas.vercel.app,http://localhost:5173
```

3. Redémarrer le backend :
```bash
docker-compose restart backend
```

---

## 🔧 Configuration Avancée

### Variables d'Environnement - Backend

| Variable | Description | Défaut | Exemple |
|----------|-------------|--------|---------|
| `ENVIRONMENT` | Mode d'exécution | `development` | `production` |
| `DEBUG` | Mode debug | `true` | `false` |
| `ALLOWED_ORIGINS` | CORS origins (séparés par virgules) | `http://localhost:5173` | `https://app.vercel.app,http://localhost:5173` |
| `CONFIG_PATH` | Chemin config datasets | `/app/config/datasets_config.json` | - |
| `CACHE_ENABLED` | Activer le cache | `true` | `true` |
| `CACHE_TTL` | TTL du cache (secondes) | `3600` | `7200` |
| `MAX_CELLS_DISPLAY` | Limite cellules affichées | `100000` | `50000` |
| `N_JOBS` | Cœurs CPU (-1 = tous) | `-1` | `4` |

### Variables d'Environnement - Frontend

| Variable | Description | Requis | Exemple |
|----------|-------------|--------|---------|
| `VITE_API_URL` | URL de l'API backend | ✅ | `https://api.masldatlas.com/api` |

### Optimisation Production

#### Backend
1. **Retirer le hot reload** :
   - Dans `docker-compose.yml`, commenter le volume `./backend/app:/app/app`
   - Rebuild : `docker-compose up -d --build`

2. **Limiter les ressources** :
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

3. **Monitoring** :
```bash
# Logs
docker-compose logs -f --tail=100

# Stats
docker stats masldatlas-backend masldatlas-redis
```

#### Frontend (Vercel)
- Build automatiquement optimisé (minification, tree-shaking)
- CDN global
- Compression Brotli automatique
- Headers de cache configurés dans `vercel.json`

---

## 🚀 Workflow de Développement

### Développement Local

1. **Backend** :
```bash
# Démarrer uniquement le backend
docker-compose up -d

# Ou en mode détaché
docker-compose up backend redis
```

2. **Frontend** :
```bash
cd frontend
npm run dev
# http://localhost:5173
```

### Déploiement Production

1. **Backend** :
```bash
# Mettre à jour le code
git pull

# Rebuild et redémarrer
docker-compose up -d --build
```

2. **Frontend** :
```bash
# Push sur GitHub (déploiement auto si configuré)
git push origin main

# Ou manuellement
cd frontend
vercel --prod
```

---

## 🔍 Troubleshooting

### Backend ne démarre pas
```bash
# Vérifier les logs
docker-compose logs backend

# Vérifier les volumes
ls -la datasets/ config/ enrichment_sets/

# Rebuild complet
docker-compose down -v
docker-compose up --build
```

### CORS Error sur Vercel
1. Vérifier que l'URL Vercel est dans `ALLOWED_ORIGINS`
2. Redémarrer le backend après modification
3. Vérifier dans les logs backend :
```bash
docker-compose logs -f backend | grep CORS
```

### Frontend ne trouve pas l'API
1. Vérifier `VITE_API_URL` dans Vercel dashboard
2. Tester l'API directement :
```bash
curl https://api.masldatlas.com/api/health
```
3. Vérifier les Network tab dans DevTools du navigateur

---

## 📊 Monitoring

### Backend Health Check
```bash
# Local
curl http://localhost:8000/health

# Production
curl https://api.masldatlas.com/health
```

### Uptime Monitoring
Configurer un service comme :
- **UptimeRobot** : Gratuit, ping toutes les 5 min
- **Vercel Monitoring** : Inclus pour le frontend
- **Sentry** : Pour le tracking d'erreurs

---

## 🔐 Sécurité

### Backend
- ✅ Volumes en lecture seule pour les données
- ✅ CORS restreint aux origines autorisées
- ✅ Health checks configurés
- ⚠️ Utiliser HTTPS en production (Nginx + Let's Encrypt)
- ⚠️ Ne pas exposer directement le port 8000 (utiliser reverse proxy)

### Frontend
- ✅ Déployé sur Vercel (HTTPS automatique)
- ✅ Variables d'environnement sécurisées
- ✅ Build optimisé et minifié

---

## 📖 Ressources

- [Documentation FastAPI](https://fastapi.tiangolo.com/)
- [Documentation Vercel](https://vercel.com/docs)
- [Documentation Docker](https://docs.docker.com/)
- [Vite Documentation](https://vitejs.dev/)
