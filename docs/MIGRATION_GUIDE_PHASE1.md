# Guide de Migration - Fonctions Legacy vers v2

## 🎯 Vue d'ensemble

Ce guide documente la correspondance entre les fonctionnalités de l'application Shiny R legacy et la nouvelle version FastAPI + React.

## 📊 Tableau de Correspondance

### ✅ Fonctionnalités Migrées (Phase 1)

| Fonctionnalité Legacy | Statut | Nouveau Composant/Endpoint | Notes |
|----------------------|--------|---------------------------|-------|
| **Filtrage par clusters** | ✅ Complet | `ClusterFilter.tsx` + `/api/analysis/filter-by-clusters` | Cache backend (Option A) |
| **CollecTRI TF Analysis** | ✅ Complet | `DecouplerPanel.tsx` (onglet 1) + `/api/decoupler/collectri` | Via rpy2 + decoupler |
| **PROGENy Pathways** | ✅ Complet | `DecouplerPanel.tsx` (onglet 2) + `/api/decoupler/progeny` | Via rpy2 + decoupler |
| **MSigDB Hallmark** | ✅ Complet | `DecouplerPanel.tsx` (onglet 3) + `/api/decoupler/msigdb` | Via decoupler |
| **Intégration Pseudo-Bulk** | ✅ Complet | `PseudobulkAnalysis.tsx` | Bouton Decoupler ajouté |

### ⏳ Fonctionnalités à Migrer (Phase 2+)

| Fonctionnalité Legacy | Priorité | Composant Prévu | ETA |
|----------------------|----------|-----------------|-----|
| **Gene Set Enrichment Custom** | 🔴 Haute | `GeneSetEnrichment.tsx` | Phase 2 |
| **Enrichissement auto DGE** | 🟠 Moyenne | Intégration `DifferentialExpression.tsx` | Phase 2 |
| **Rank Genes Groups Plot** | 🟡 Basse | `DifferentialExpression.tsx` | Phase 3 |
| **Documentation Interactive** | 🟡 Basse | `Documentation.tsx` | Phase 3 |

## 🔄 Correspondance Code

### 1. Filtrage par Clusters

#### Legacy (Shiny R)
```r
# server.R
filtered_adata <- reactive({
  req(input$selected_clusters)
  adata <- current_adata()
  adata[adata$obs$CellType %in% input$selected_clusters, ]
})
```

#### Nouvelle Version (React + FastAPI)
```typescript
// Frontend
import { ClusterFilter } from './components/ClusterFilter';

<ClusterFilter
  sessionId={sessionId}
  cellTypes={cellTypes}
  onFilterApplied={(info) => {
    console.log(`Filtered: ${info.n_cells_filtered} cells`);
  }}
/>
```

```python
# Backend
@router.post("/filter-by-clusters/{session_id}")
async def filter_by_clusters(session_id: str, clusters: List[str]):
    filtered_adata = dataset_service.filter_by_clusters(adata, clusters)
    cache_service.set_filtered_dataset(filtered_adata, ...)
    return {"n_cells_filtered": filtered_adata.n_obs}
```

### 2. CollecTRI Analysis

#### Legacy (Shiny R)
```r
# Charger réseau
collectri_net <- readRDS("enrichment_sets/collectri.rds")

# Analyse
tf_acts <- decoupler::run_ulm(
  mat = deseq_matrix,
  net = collectri_net,
  .source = "source",
  .target = "target"
)

# Visualisation
decoupler::plot_barplot(tf_acts, top = 25)
```

#### Nouvelle Version (React + FastAPI)
```typescript
// Frontend
import { DecouplerPanel } from './components/DecouplerPanel';

<DecouplerPanel 
  deseqResults={deseqResults}
  organism="human"
/>
```

```python
# Backend
@router.post("/collectri")
async def run_collectri(request: DecouplerRequest):
    rds_loader = get_rds_loader()
    collectri_net = rds_loader.load_collectri()
    
    tf_scores, barplot_img = enrichment_service.run_collectri_analysis(
        deseq_df, organism
    )
    
    return {
        "tf_scores": tf_scores.to_dict(),
        "barplot_image": barplot_img  # base64
    }
```

### 3. PROGENy Pathways

#### Legacy (Shiny R)
```r
progeny_net <- readRDS("enrichment_sets/progeny.rds")

pathway_acts <- decoupler::run_mlm(
  mat = deseq_matrix,
  net = progeny_net
)

decoupler::plot_barplot(pathway_acts)
```

#### Nouvelle Version
```python
# Backend (similaire à CollecTRI)
@router.post("/progeny")
async def run_progeny(request: DecouplerRequest):
    progeny_net = rds_loader.load_progeny()
    pathway_scores, barplot = enrichment_service.run_progeny_analysis(...)
    return {"pathway_scores": ..., "barplot_image": ...}
```

### 4. MSigDB Hallmark

#### Legacy (Shiny R)
```r
msigdb <- readRDS("enrichment_sets/msigdb.rds")

ora_results <- decoupler::get_ora_df(
  gene_list = de_genes,
  sets = msigdb
)

decoupler::plot_dotplot(ora_results, top = 25)
```

#### Nouvelle Version
```python
# Backend
@router.post("/msigdb")
async def run_msigdb(request: DecouplerRequest):
    msigdb = dc.get_resource('MSigDB')
    hallmark = msigdb[msigdb['collection'] == 'hallmark']
    
    ora_results = dc.run_ora(mat, hallmark)
    dotplot_img = enrichment_service.plot_msigdb_dotplot(...)
    
    return {"enrichment_scores": ..., "dotplot_image": ...}
```

## 🗂️ Structure des Fichiers

### Legacy (Shiny R)
```
legacy/shiny/
├── app.R                    # 4724 lignes - Application complète
├── R/
│   ├── utils.R
│   └── plotting.R
└── www/
    └── styles.css
```

### Nouvelle Version (FastAPI + React)
```
backend/app/
├── api/
│   ├── analysis.py          # Filtrage, DGE, etc.
│   └── decoupler.py         # CollecTRI, PROGENy, MSigDB
├── services/
│   ├── cache_service.py     # Cache filtered datasets
│   ├── rds_loader.py        # Lecture fichiers RDS
│   └── enrichment_service.py # Analyses enrichment + Decoupler
└── main.py

frontend/src/components/
├── ClusterFilter.tsx        # Filtrage clusters
├── DecouplerPanel.tsx       # Analyses Decoupler
└── PseudobulkAnalysis.tsx   # Pseudo-bulk + Decoupler
```

## 📝 Patterns de Migration

### Pattern 1: Chargement de Données R → Python

**Avant (R)**:
```r
data <- readRDS("file.rds")
```

**Après (Python)**:
```python
from app.services.rds_loader import get_rds_loader
rds = get_rds_loader()
data = rds.load_rds("file.rds")
```

### Pattern 2: Réactivité Shiny → React State

**Avant (Shiny)**:
```r
output$plot <- renderPlot({
  req(input$gene)
  plot_gene(input$gene)
})
```

**Après (React)**:
```tsx
const [selectedGene, setSelectedGene] = useState('');

const plotMutation = useMutation({
  mutationFn: async (gene: string) => {
    const response = await fetch(`/api/plot/${gene}`);
    return response.json();
  }
});

useEffect(() => {
  if (selectedGene) {
    plotMutation.mutate(selectedGene);
  }
}, [selectedGene]);
```

### Pattern 3: Plots R → Images Base64

**Avant (R)**:
```r
output$plot <- renderPlot({
  ggplot(data) + geom_point(...)
})
```

**Après (Python + React)**:
```python
# Backend
def create_plot(data):
    fig, ax = plt.subplots()
    ax.scatter(...)
    
    buf = io.BytesIO()
    fig.savefig(buf, format='png', dpi=300)
    img_base64 = base64.b64encode(buf.getvalue()).decode()
    return f"data:image/png;base64,{img_base64}"
```

```tsx
// Frontend
<img src={plotData.image} alt="Plot" />
```

## 🔧 Configuration

### Variables d'Environnement

```bash
# Backend (.env)
DATA_DIR=/app/datasets
CONFIG_PATH=/app/config/datasets_config.json
CACHE_ENABLED=true
CACHE_TTL=3600

# Frontend (.env)
VITE_API_URL=http://localhost:8000
```

### Datasets Config

Le fichier `datasets_config.json` reste identique entre legacy et v2.

## 🚀 Workflow de Développement

### Ajouter une Nouvelle Fonctionnalité Legacy

1. **Identifier** la fonctionnalité dans `legacy/shiny/app.R`
2. **Créer** le service backend dans `backend/app/services/`
3. **Ajouter** l'endpoint dans `backend/app/api/`
4. **Créer** le composant React dans `frontend/src/components/`
5. **Tester** avec le script `scripts/verify_phase1.py`
6. **Documenter** dans ce guide

### Exemple: Ajouter "Gene Set Enrichment Custom"

```python
# 1. Service (backend/app/services/enrichment_service.py)
def run_custom_geneset_enrichment(adata, geneset, method="ulm"):
    scores = dc.run_ulm(mat=adata, net=geneset)
    return scores

# 2. Endpoint (backend/app/api/enrichment.py)
@router.post("/custom-geneset")
async def custom_geneset_enrichment(request: GeneSetRequest):
    scores = enrichment_service.run_custom_geneset_enrichment(...)
    return {"scores": scores}
```

```tsx
// 3. Composant (frontend/src/components/GeneSetEnrichment.tsx)
export function GeneSetEnrichment({ sessionId }: Props) {
  const [geneset, setGeneset] = useState([]);
  
  const mutation = useMutation({
    mutationFn: async (geneset: string[]) => {
      const response = await fetch('/api/enrichment/custom-geneset', {
        method: 'POST',
        body: JSON.stringify({ geneset })
      });
      return response.json();
    }
  });
  
  return <div>...</div>;
}
```

## 📚 Ressources

- **Documentation decoupler**: https://decoupler-py.readthedocs.io/
- **rpy2 Guide**: https://rpy2.github.io/doc/latest/html/index.html
- **React Query**: https://tanstack.com/query/latest
- **FastAPI**: https://fastapi.tiangolo.com/

## ❓ FAQ

### Q: Pourquoi utiliser rpy2 au lieu de convertir les RDS manuellement ?
**R**: Les fichiers RDS contiennent des structures R complexes. rpy2 garantit une conversion fidèle et facilite la maintenance.

### Q: Le cache backend ne risque-t-il pas de saturer la mémoire ?
**R**: Le cache utilise un TTL de 1h et une taille max de 100 items. Pour une production à grande échelle, migrer vers Redis est recommandé.

### Q: Peut-on utiliser les réseaux decoupler intégrés au lieu des RDS ?
**R**: Oui ! Utilisez `dc.get_collectri()` et `dc.get_progeny()`. Les RDS permettent d'utiliser des versions custom ou mises à jour.

### Q: Comment déboguer les erreurs decoupler ?
**R**: Activer les logs verbeux dans `enrichment_service.py` et vérifier les dimensions des matrices (samples x genes).

---

**Version**: 1.0.0  
**Dernière mise à jour**: 11 février 2026
