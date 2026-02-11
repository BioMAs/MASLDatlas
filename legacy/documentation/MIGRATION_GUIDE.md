# Guide de Migration - Shiny R vers FastAPI + React

## 📋 Vue d'ensemble

Ce guide explique comment migrer progressivement de l'application Shiny R vers la nouvelle stack FastAPI + React.

## 🎯 Stratégie de Migration

### Option 1: Migration Complète (Recommandé)
Passer directement à la nouvelle stack pour tous les nouveaux développements.

### Option 2: Migration Progressive
Faire cohabiter les deux versions pendant la transition.

## 🔄 Équivalences Conceptuelles

### Réactivité et État

**Shiny R:**
```r
# Reactive value
adata <- eventReactive(input$import_dataset, {
  sc$read_h5ad(dataset_path)
})

# Observe changes
observeEvent(input$gene_name, {
  # Update plot
})
```

**FastAPI + React:**
```typescript
// React Query (server state)
const { data: adata, isLoading } = useQuery({
  queryKey: ['dataset', sessionId],
  queryFn: () => datasetService.loadDataset(request)
});

// Local state
const [geneName, setGeneName] = useState('');

// Effect on change
useEffect(() => {
  // Update plot
}, [geneName]);
```

### Visualisations

**Shiny R:**
```r
output$imageoutput_UMAP <- renderImage({
  req(adata())
  sc$pl$umap(adata(), color='CellType', show=FALSE, save='umap.png')
  list(src="figures/umap.png", height="800px")
}, deleteFile=TRUE)
```

**FastAPI + React:**
```typescript
// Backend API
@router.get("/umap/{session_id}")
async def generate_umap(session_id: str, color_by: str):
    adata = current_dataset[session_id]
    image = visualization_service.generate_umap(adata, color_by)
    return {"image": image}  # base64

// Frontend Component
function UMAPVisualization({ sessionId, colorBy }) {
  const { data } = useQuery({
    queryKey: ['umap', sessionId, colorBy],
    queryFn: () => visualizationService.generateUMAP(sessionId, colorBy)
  });
  
  return <img src={data?.image} alt="UMAP" />;
}
```

### Tables de Données

**Shiny R:**
```r
output$dge_dt <- renderDT({
  datatable(result_df, options = list(pageLength = 10))
})
```

**FastAPI + React:**
```typescript
import { AgGridReact } from 'ag-grid-react';

function DGETable({ data }: { data: DGEResult[] }) {
  const columnDefs = [
    { field: 'gene', sortable: true, filter: true },
    { field: 'log2fc', sortable: true },
    { field: 'pvalue', sortable: true }
  ];
  
  return (
    <AgGridReact
      rowData={data}
      columnDefs={columnDefs}
      pagination={true}
      paginationPageSize={10}
    />
  );
}
```

### Inputs Utilisateur

**Shiny R:**
```r
selectInput("selection_organism", "Select Organism",
  choices = c("Human", "Mouse", "Zebrafish"))

textInput("gene_name", "Gene Name", value = "")
```

**React:**
```typescript
function OrganismSelector() {
  const [organism, setOrganism] = useState('');
  
  return (
    <select
      value={organism}
      onChange={(e) => setOrganism(e.target.value)}
    >
      <option value="">Select...</option>
      <option value="Human">Human</option>
      <option value="Mouse">Mouse</option>
      <option value="Zebrafish">Zebrafish</option>
    </select>
  );
}
```

## 🛠 Migration par Fonctionnalité

### 1. Chargement de Dataset

**Ancienne méthode (Shiny):**
```r
adata <- eventReactive(input$import_dataset, {
  dataset_path <- paste0("datasets/", organism, "/", dataset_name, ".h5ad")
  sc$read_h5ad(dataset_path)
})
```

**Nouvelle méthode:**

Backend (FastAPI):
```python
@router.post("/datasets/load")
async def load_dataset(request: DatasetLoadRequest):
    adata = dataset_service.load_dataset(
        request.organism,
        request.dataset_name
    )
    session_id = f"{request.organism}_{request.dataset_name}"
    current_dataset[session_id] = adata
    return {"session_id": session_id, "info": get_info(adata)}
```

Frontend (React):
```typescript
const loadDataset = useLoadDataset();

const handleLoad = async () => {
  const result = await loadDataset.mutateAsync({
    organism: 'Human',
    dataset_name: 'GSE181483'
  });
  setSessionId(result.session_id);
};
```

### 2. Analyse Différentielle

**Migration:**

1. Backend crée l'endpoint `/api/analysis/differential-expression`
2. Utilise scanpy comme avant: `sc.tl.rank_genes_groups()`
3. Retourne JSON au lieu de modifier l'état réactif
4. Frontend affiche avec AG-Grid au lieu de DT

### 3. Visualisations

**Stratégie:**

- Backend génère les images en base64
- Frontend affiche directement
- Ou utiliser Plotly.js côté client pour interactivité

### 4. Enrichissement

**À migrer:**

- Backend: Implémenter avec `fenr` (comme avant)
- Endpoints REST pour chaque DB (GO, KEGG, etc.)
- Frontend: Tables interactives pour résultats

## 📦 Dépendances Préservées

Ces packages Python restent utilisés:
- ✅ scanpy
- ✅ anndata  
- ✅ decoupler
- ✅ pydeseq2
- ✅ pandas/numpy

Nouveaux ajouts:
- FastAPI (framework)
- uvicorn (serveur)
- pydantic (validation)

## 🚀 Plan de Déploiement

### Phase 1: Développement (Actuel)
```bash
# Backend
cd backend && uvicorn app.main:app --reload

# Frontend
cd frontend && npm run dev
```

### Phase 2: Test
```bash
docker-compose -f docker-compose.new.yml up
```

### Phase 3: Production
```bash
docker-compose -f docker-compose.new.yml up -d
```

## 🔍 Checklist de Migration

### Backend ✅
- [x] Structure FastAPI
- [x] Endpoints datasets
- [x] Endpoints analysis
- [x] Endpoints visualization
- [x] Services de base
- [ ] Tests unitaires
- [ ] Enrichissement complet
- [ ] Pseudo-bulk DESeq2

### Frontend ✅
- [x] Setup Vite + React + TypeScript
- [x] React Query configuration
- [x] API clients
- [x] Types TypeScript
- [x] Composant DatasetSelector
- [ ] Composants UMAP
- [ ] Composants Violin/Heatmap
- [ ] Interface DGE
- [ ] Interface Correlation
- [ ] Interface Enrichissement
- [ ] TailwindCSS styling

### Infrastructure ✅
- [x] Dockerfiles
- [x] docker-compose.yml
- [x] nginx configuration
- [ ] CI/CD pipeline
- [ ] Monitoring
- [ ] Logging centralisé

## 💡 Conseils de Migration

### 1. Commencer Petit
Migrer une fonctionnalité à la fois, tester, puis passer à la suivante.

### 2. Réutiliser la Logique Python
La logique d'analyse (scanpy, etc.) est identique, seule l'interface change.

### 3. Améliorer en Migrant
Profiter de la migration pour:
- Ajouter des tests
- Améliorer les performances
- Simplifier le code
- Documenter

### 4. Documentation Continue
Documenter chaque endpoint API avec FastAPI (auto-généré).

### 5. Tests de Régression
Comparer les résultats entre ancienne et nouvelle version.

## 🐛 Debugging

### Backend
```bash
# Logs détaillés
uvicorn app.main:app --reload --log-level debug

# Python debugger
import pdb; pdb.set_trace()
```

### Frontend
```bash
# React DevTools
# Redux DevTools (si utilisé)
# Network tab pour API calls
```

## 📚 Ressources

### Documentation
- [FastAPI](https://fastapi.tiangolo.com/)
- [React](https://react.dev/)
- [TanStack Query](https://tanstack.com/query/latest)
- [Scanpy](https://scanpy.readthedocs.io/)

### Exemples
- Voir `backend/app/api/` pour exemples d'endpoints
- Voir `frontend/src/components/` pour exemples React

## ✨ Nouvelles Possibilités

Avec cette stack moderne, vous pouvez ajouter:

1. **WebSockets** pour updates en temps réel
2. **Progressive Web App** (PWA)
3. **Authentification** OAuth2
4. **API publique** pour chercheurs
5. **Tests automatisés** complets
6. **Scaling horizontal** avec Kubernetes
7. **CDN** pour assets statiques
8. **Analytics** avancés

## 🎓 Formation Équipe

### Pour Biologistes
- Utilisation de l'interface (identique en apparence)
- Nouvelles fonctionnalités disponibles

### Pour Développeurs
- FastAPI basics (1-2 jours)
- React + TypeScript (3-5 jours)
- Architecture API REST (1 jour)

## 📞 Support

Pour questions spécifiques à la migration:
1. Consulter ce guide
2. Vérifier la documentation API: `/api/docs`
3. Examiner les exemples de code
4. Tester avec Postman/Insomnia
