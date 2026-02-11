# Quick Start Guide - MASLDatlas v2.0

## 🎯 Démarrage Rapide

### Option 1: Docker (Recommandé)

```bash
# Tout en un
./start-v2.sh

# Ou manuellement
docker-compose -f docker-compose.new.yml up --build
```

Accès:
- **Frontend**: http://localhost:3000
- **API**: http://localhost:8000
- **Documentation API**: http://localhost:8000/api/docs

### Option 2: Développement Local

#### Backend
```bash
cd backend

# Créer environnement virtuel
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Installer dépendances
pip install -r requirements.txt

# Lancer le serveur
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Frontend
```bash
cd frontend

# Installer dépendances
npm install

# Lancer le serveur de développement
npm run dev
```

Accès:
- **Frontend**: http://localhost:5173
- **API**: http://localhost:8000

## 📱 Utilisation de l'Application

### 1. Charger un Dataset

1. Sélectionnez un organisme (Human, Mouse, Zebrafish, Integrated)
2. Choisissez un dataset dans la liste
3. Pour les gros datasets, sélectionnez la taille (full, large, medium, small)
4. Cliquez sur "Load Dataset"

### 2. Visualiser avec UMAP

- **Onglet "Visualize"**: Voir la projection UMAP
- **Recherche de gène**: Tapez un nom de gène pour colorer par expression
- **Téléchargement**: Cliquez sur l'icône appareil photo dans le graphique

### 3. Analyse Différentielle

1. Allez dans l'onglet "Differential Expression"
2. Sélectionnez deux groupes à comparer (ex: Hepatocyte vs Endothelial)
3. Choisissez la méthode statistique
4. Ajustez les seuils (Log FC, P-value)
5. Cliquez sur "Run Differential Expression"
6. Explorez les résultats dans le tableau
7. Téléchargez en CSV si besoin

### 4. Corrélation de Gènes

1. Onglet "Correlation"
2. Entrez deux noms de gènes
3. Choisissez la méthode (Spearman ou Pearson)
4. Optionnel: Retirer les zéros
5. Cliquez sur "Calculate Correlation"
6. Visualisez le scatter plot et les statistiques

## 🔧 Configuration Avancée

### Variables d'Environnement

Éditez `.env`:

```bash
# Backend
ENVIRONMENT=development  # ou production
DEBUG=true
PYTHONUNBUFFERED=1

# Frontend
VITE_API_URL=http://localhost:8000

# Cache (optionnel)
# REDIS_URL=redis://redis:6379/0
```

### Personnalisation

#### Ajouter un nouveau dataset

1. Placez le fichier `.h5ad` dans `datasets/[Organism]/`
2. Éditez `config/datasets_config.json`:

```json
{
  "Human": {
    "Datasets": [
      "existing_dataset",
      "your_new_dataset"
    ]
  }
}
```

3. Redémarrez l'application

#### Modifier les couleurs

Éditez `frontend/tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      primary: {
        500: '#your-color',
      },
    },
  },
}
```

## 🐛 Dépannage

### Le backend ne démarre pas

```bash
# Vérifier les logs
docker-compose -f docker-compose.new.yml logs backend

# Vérifier les dépendances Python
cd backend
pip list
```

### Le frontend ne se connecte pas à l'API

1. Vérifiez que le backend tourne sur http://localhost:8000
2. Testez l'API: http://localhost:8000/health
3. Vérifiez les CORS dans `backend/app/core/config.py`

### Dataset ne charge pas

1. Vérifiez le chemin: `datasets/[Organism]/[dataset].h5ad`
2. Vérifiez les permissions du dossier
3. Consultez les logs du backend

### Erreurs npm

```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

## 📚 Ressources

- **Documentation API complète**: http://localhost:8000/api/docs
- **Guide de migration**: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
- **README complet**: [README.v2.md](README.v2.md)

## 🆘 Support

### Problèmes courants

1. **Port déjà utilisé**: Modifiez les ports dans `docker-compose.new.yml`
2. **Mémoire insuffisante**: Augmentez la RAM de Docker Desktop (> 4GB recommandé)
3. **Dataset trop gros**: Utilisez les versions optimized (medium/small)

### Commandes utiles

```bash
# Arrêter tout
docker-compose -f docker-compose.new.yml down

# Reconstruire complètement
docker-compose -f docker-compose.new.yml up --build --force-recreate

# Voir les logs
docker-compose -f docker-compose.new.yml logs -f

# Nettoyer les volumes
docker-compose -f docker-compose.new.yml down -v
```

## ✨ Fonctionnalités à Venir

- [ ] Enrichissement fonctionnel complet
- [ ] Analyse pseudo-bulk DESeq2
- [ ] Export PDF des rapports
- [ ] Authentification utilisateur
- [ ] API publique
- [ ] Comparaisons multi-datasets

## 🎓 Tutoriels

### Exemple: Analyser un dataset Human

```bash
# 1. Démarrer l'app
./start-v2.sh

# 2. Dans le navigateur (http://localhost:3000):
# - Sélectionner "Human"
# - Choisir "GSE181483"
# - Cliquer "Load Dataset"

# 3. Visualiser:
# - Onglet "Visualize"
# - Taper "ALB" dans Gene Search
# - Observer l'expression d'Albumin

# 4. DGE:
# - Onglet "Differential Expression"
# - Group 1: Hepatocyte
# - Group 2: Endothelial
# - Run Analysis
# - Télécharger les résultats
```

## 🚀 Performance

### Optimisations

- ✅ Cache côté serveur (TTL 1h)
- ✅ Build optimisé frontend (Vite)
- ✅ Images Docker multi-stage
- ✅ Lazy loading des composants
- ⏳ Redis pour sessions (à activer)
- ⏳ CDN pour assets statiques

### Benchmarks (approximatifs)

| Action | Shiny R | FastAPI v2 |
|--------|---------|------------|
| Chargement dataset (100k cells) | 15-30s | **3-5s** |
| UMAP render | 5-10s | **1-2s** |
| DGE analysis | 20-40s | **5-10s** |
| Correlation | 10-15s | **2-3s** |

---

**MASLDatlas v2.0** - Analyse moderne de scRNA-seq 🧬
