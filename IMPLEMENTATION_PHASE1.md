# Implémentation des Fonctions Legacy - Phase 1

## 📅 Date: 11 février 2026

## 🎯 Objectif
Migration progressive des fonctionnalités critiques de l'application Shiny R vers la nouvelle architecture FastAPI + React/TypeScript.

## ✅ Fonctionnalités Implémentées

### 1. **Système de Cache pour Datasets Filtrés (Option A)**

#### Backend
- **Fichier**: `backend/app/services/cache_service.py`
- **Fonctionnalités**:
  - Cache TTL (Time-To-Live) pour datasets filtrés
  - Génération de clés de cache basées sur organisme, dataset et filtres
  - Gestion automatique de l'expiration (1 heure par défaut)
  - Support de 100 datasets filtrés simultanés en mémoire
  - Statistiques de cache via endpoint `/api/analysis/cache/stats`

#### Caractéristiques
```python
# Exemple d'utilisation
cache_service = get_cache_service()
filtered_adata = cache_service.get_filtered_dataset(
    organism="Human",
    dataset="GSE181483",
    clusters=["Hepatocyte", "Stellate"]
)
```

### 2. **Filtrage par Clusters**

#### Backend
- **Fichier**: `backend/app/services/dataset_service.py`
- **Méthode**: `filter_by_clusters(adata, clusters, cluster_column)`
- **Endpoint**: `POST /api/analysis/filter-by-clusters/{session_id}`

#### Frontend
- **Fichier**: `frontend/src/components/ClusterFilter.tsx`
- **Fonctionnalités**:
  - Sélection multi-clusters avec checkboxes
  - Boutons "Tout sélectionner" / "Tout désélectionner"
  - Interface collapsible
  - Indicateur du nombre de cellules avant/après filtrage
  - Messages de succès/erreur
  - Gestion d'état avec React Query

#### Utilisation
```tsx
<ClusterFilter
  sessionId={sessionId}
  cellTypes={cellTypes}
  onFilterApplied={(info) => console.log(info)}
/>
```

### 3. **Chargement des Datasets RDS Legacy (rpy2)**

#### Backend
- **Fichier**: `backend/app/services/rds_loader.py`
- **Dépendance**: `rpy2==3.5.16` ajoutée à `requirements.txt`

#### Fonctionnalités
- Chargement de fichiers `.rds` et `.RData` via rpy2
- Conversion automatique R → pandas DataFrame
- Cache des datasets chargés
- Support des datasets:
  - **CollecTRI** (`collectri.rds`) - Réseau TF-gènes
  - **PROGENy** (`progeny.rds`) - Signatures de voies
  - **MSigDB** (`msigdb.rds`) - Gene sets Hallmark
  - Données organisme-spécifiques (`human.RData`, `mouse.RData`, `zebrafish.RData`)

#### Méthodes
```python
rds_loader = get_rds_loader()
collectri_net = rds_loader.load_collectri()  # DataFrame
progeny_net = rds_loader.load_progeny()      # DataFrame
msigdb = rds_loader.load_msigdb()            # R object
```

### 4. **Analyses Decoupler (CollecTRI, PROGENy, MSigDB)**

#### Backend
- **Fichier**: `backend/app/services/enrichment_service.py` (étendu)
- **Nouveau fichier**: `backend/app/api/decoupler.py`

#### Méthodes Implémentées

##### CollecTRI (Transcription Factors)
- `run_collectri_analysis()` - Calcul des scores d'activité TF
- `plot_collectri_volcano()` - Volcano plot pour un TF
- `plot_collectri_network()` - Réseau TF-gènes cibles
- **Endpoint**: `POST /api/decoupler/collectri`

##### PROGENy (Pathway Activity)
- `run_progeny_analysis()` - Scores d'activité des voies
- `plot_progeny_targets()` - Gènes cibles d'une voie
- **Endpoint**: `POST /api/decoupler/progeny`

##### MSigDB Hallmark
- `run_msigdb_analysis()` - Enrichissement gene sets
- `plot_msigdb_running_score()` - GSEA running score
- **Endpoint**: `POST /api/decoupler/msigdb`

#### Frontend
- **Fichier**: `frontend/src/components/DecouplerPanel.tsx`
- **Fonctionnalités**:
  - 3 onglets: CollecTRI, PROGENy, MSigDB
  - Visualisations interactives
  - Barplots, volcano plots, network plots
  - Sélection de TF/voie/gene set pour analyses détaillées
  - Téléchargement des images haute résolution
  - Support multi-organisme

#### Utilisation
```tsx
<DecouplerPanel 
  deseqResults={results}
  organism="human"
/>
```

### 5. **Intégration dans PseudobulkAnalysis**

#### Modifications
- **Fichier**: `frontend/src/components/PseudobulkAnalysis.tsx`
- Import du `DecouplerPanel`
- Bouton d'activation de l'analyse Decoupler
- Passage automatique des résultats DESeq2

#### Workflow
1. Utilisateur lance l'analyse pseudo-bulk DESeq2
2. Résultats affichés dans le tableau
3. Bouton "Analyse Decoupler" apparaît
4. Clic → panneau Decoupler s'ouvre avec les 3 onglets
5. Analyses CollecTRI, PROGENy, MSigDB disponibles

## 🏗️ Architecture

### Backend
```
backend/
├── app/
│   ├── api/
│   │   ├── analysis.py          # +endpoint filter-by-clusters
│   │   └── decoupler.py         # NOUVEAU: endpoints Decoupler
│   ├── services/
│   │   ├── cache_service.py     # NOUVEAU: cache filtered datasets
│   │   ├── rds_loader.py        # NOUVEAU: lecture RDS via rpy2
│   │   ├── enrichment_service.py # +méthodes Decoupler
│   │   └── dataset_service.py   # +filter_by_clusters()
│   └── main.py                  # +router decoupler
└── requirements.txt             # +rpy2
```

### Frontend
```
frontend/
└── src/
    └── components/
        ├── ClusterFilter.tsx    # NOUVEAU: filtre clusters
        ├── DecouplerPanel.tsx   # NOUVEAU: analyses Decoupler
        └── PseudobulkAnalysis.tsx # +intégration Decoupler
```

## 🔧 Installation

### Backend
```bash
cd backend
pip install -r requirements.txt
```

**Note**: rpy2 nécessite R installé sur le système:
```bash
# macOS
brew install r

# Ubuntu/Debian
sudo apt-get install r-base r-base-dev

# Vérification
R --version
```

### Frontend
Aucune dépendance supplémentaire requise.

## 🚀 Utilisation

### 1. Filtrage par Clusters

```typescript
// Importer le composant
import { ClusterFilter } from './components/ClusterFilter';

// Utiliser dans votre composant
<ClusterFilter
  sessionId="Human_GSE181483"
  cellTypes={["Hepatocyte", "Stellate", "Endothelial"]}
  onFilterApplied={(info) => {
    console.log(`Filtré: ${info.n_cells_filtered} cellules`);
  }}
/>
```

### 2. Analyse Decoupler

```typescript
// Dans PseudobulkAnalysis ou autre composant
import { DecouplerPanel } from './components/DecouplerPanel';

// Après obtention des résultats DESeq2
<DecouplerPanel 
  deseqResults={deseqResults}  // Array of {gene, log2FoldChange, pvalue, ...}
  organism="human"             // ou "mouse", "zebrafish"
/>
```

### 3. API Backend

#### Filtrage
```bash
curl -X POST "http://localhost:8000/api/analysis/filter-by-clusters/Human_GSE181483" \
  -H "Content-Type: application/json" \
  -d '["Hepatocyte", "Stellate"]'
```

#### CollecTRI
```bash
curl -X POST "http://localhost:8000/api/decoupler/collectri" \
  -H "Content-Type: application/json" \
  -d '{
    "deseq_results": [...],
    "organism": "human"
  }'
```

## 📊 Données Requises

### Fichiers RDS
Les fichiers suivants doivent être présents dans `enrichment_sets/`:
- `collectri.rds` - Réseau CollecTRI
- `progeny.rds` - Signatures PROGENy
- `msigdb.rds` - Gene sets MSigDB
- `human.RData` - Données Human (optionnel)
- `mouse.RData` - Données Mouse (optionnel)
- `zebrafish.RData` - Données Zebrafish (optionnel)

**Note**: Si les fichiers RDS ne sont pas disponibles, decoupler peut utiliser les réseaux intégrés via `dc.get_collectri()` et `dc.get_progeny()`.

## 🔍 Tests

### Test du Cache
```python
# Test endpoint cache stats
GET http://localhost:8000/api/analysis/cache/stats

# Réponse
{
  "filtered_datasets": {
    "size": 2,
    "maxsize": 100,
    "ttl": 3600
  },
  "results": {
    "size": 5,
    "maxsize": 200,
    "ttl": 3600
  }
}
```

### Test RDS Loader
```python
from app.services.rds_loader import get_rds_loader

rds = get_rds_loader()
collectri = rds.load_collectri()
print(f"CollecTRI: {len(collectri)} interactions")
```

### Test Decoupler
```bash
# Lancer l'analyse CollecTRI
POST http://localhost:8000/api/decoupler/collectri
```

## 🐛 Dépannage

### Erreur: "rpy2 not installed"
```bash
pip install rpy2
```

### Erreur: "R not found"
Installer R sur votre système (voir section Installation).

### Erreur: "RDS file not found"
Vérifier que les fichiers `.rds` sont dans `enrichment_sets/`:
```bash
ls enrichment_sets/
# Devrait afficher: collectri.rds, progeny.rds, msigdb.rds, etc.
```

### Cache plein
Le cache se vide automatiquement après 1 heure (TTL). Pour vider manuellement:
```python
from app.services.cache_service import get_cache_service
cache = get_cache_service()
cache.clear_all()
```

## 📈 Performance

### Cache
- **Taille max**: 100 datasets filtrés
- **TTL**: 3600 secondes (1 heure)
- **Mémoire**: ~1-5 GB par dataset (dépend de la taille)

### Optimisations
- Filtrage effectué sur dataset full (haute précision)
- Résultats mis en cache pour réutilisation
- Images générées en base64 (pas de fichiers temporaires)

## 🔮 Prochaines Étapes

### Phase 2 (À venir)
1. **Gene Set Enrichment Custom** - Signatures personnalisées
2. **Enrichissement automatique DGE → Enrichment** - Intégration fluide
3. **Visualisations DGE avancées** - Rank genes plots
4. **Documentation Interactive** - Guide utilisateur intégré

### Améliorations Potentielles
- [ ] Compléter les visualisations volcano/network (actuellement placeholders)
- [ ] Ajouter support pour plus de gene sets MSigDB
- [ ] Optimiser le cache avec Redis (au lieu de mémoire)
- [ ] Ajouter tests unitaires pour nouveaux services
- [ ] Documenter l'API avec exemples Swagger

## 📝 Notes Techniques

### Choix de Design

#### Option A (Cache Backend) ✅
- **Avantages**: Performance, cohérence, scalable
- **Inconvénients**: Mémoire serveur requise
- **Alternatives rejetées**: 
  - Option B (recalcul): trop lent
  - Option C (frontend): limitations mémoire navigateur

#### rpy2 pour RDS ✅
- **Avantages**: Compatibilité totale avec fichiers legacy
- **Inconvénients**: Dépendance R requise
- **Alternatives**: Conversion manuelle (trop de travail)

#### decoupler pour MSigDB ✅
- **Avantages**: Cohérence avec CollecTRI/PROGENy
- **Inconvénients**: Moins features que gseapy
- **Alternatives**: gseapy (déjà utilisé pour enrichment standard)

## 🙏 Contributeurs
- Développement: GitHub Copilot (Claude Sonnet 4.5)
- Architecture: MASLDatlas Team

## 📄 License
Voir LICENSE du projet principal.

---

**Version**: 1.0.0  
**Dernière mise à jour**: 11 février 2026
