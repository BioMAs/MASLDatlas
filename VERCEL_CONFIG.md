# Configuration Frontend Vercel + Backend Docker

## Problèmes corrigés

✅ **Double `/api` dans les URLs** - Les endpoints utilisaient `/api/datasets` avec un `baseURL` contenant déjà `/api`
✅ **CORS non configuré** - Le backend n'autorisait que localhost  
✅ **Variable d'environnement manquante** - `VITE_API_URL` doit pointer vers le backend public

## Configuration requise

### 1. Backend (Docker)

Dans votre fichier `.env` ou dans votre configuration de déploiement, ajoutez votre URL Vercel :

```bash
ALLOWED_ORIGINS=https://votre-app.vercel.app,http://localhost:5173
```

**Important:** Remplacez `votre-app.vercel.app` par votre URL Vercel réelle.

### 2. Frontend (Vercel)

Dans **Vercel Dashboard → Settings → Environment Variables**, ajoutez :

```
VITE_API_URL=https://votre-backend-public.com
```

#### Options pour exposer votre backend Docker publiquement :

**Option A: Ngrok (rapide pour tester)**
```bash
ngrok http 8000
# Utilisez l'URL fournie (ex: https://abc123.ngrok.io)
```

**Option B: Cloudflare Tunnel (gratuit, permanent)**
```bash
cloudflared tunnel --url http://localhost:8000
# Ou configurez un tunnel nommé permanent
```

**Option C: Serveur cloud**
Déployez le backend sur un VPS avec IP publique (AWS, DigitalOcean, etc.)

### 3. Développement local

Le fichier `frontend/.env` est déjà configuré pour pointer vers `http://localhost:8000`.

Pour lancer l'environnement complet en local :

```bash
# Terminal 1 - Backend
docker-compose up

# Terminal 2 - Frontend
cd frontend
npm run dev
```

Le frontend sera accessible sur `http://localhost:5173` et communiquera avec le backend sur `http://localhost:8000`.

## Vérification

Une fois configuré, testez :

1. **Vercel build** : Vérifiez que le build réussit
2. **CORS** : Ouvrez la console du navigateur sur Vercel, vérifiez qu'il n'y a pas d'erreurs CORS
3. **Datasets** : Essayez de charger un dataset, vérifiez les appels API dans l'onglet Network

## Architecture

```
┌─────────────────┐
│  Vercel         │
│  (Frontend)     │──────┐
└─────────────────┘      │
                         │ HTTPS
                         ▼
                 ┌───────────────┐
                 │  Ngrok/Tunnel │
                 │  ou Serveur   │
                 └───────────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │  Docker       │
                 │  (Backend)    │
                 │  Port 8000    │
                 └───────────────┘
```

## Fichiers modifiés

- `frontend/src/lib/api.ts` - BaseURL sans `/api`
- `frontend/src/services/*.ts` - Endpoints sans préfixe `/api`
- `docker-compose.yml` - Documentation CORS
- `frontend/.env` - Configuration locale
- `frontend/.env.example` - Template avec exemples
