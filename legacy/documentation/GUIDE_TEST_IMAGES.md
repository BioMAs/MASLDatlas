# Guide de test - Système images haute résolution

## 🎯 Tests rapides à effectuer

### 1. Démarrage de l'application

```bash
cd /Users/tdarde/Documents/Github/MASLDatlas
docker-compose up
```

Ou si vous utilisez l'environnement local:
```bash
Rscript app.R
```

---

### 2. Tests visuels (dans l'application)

#### Test 1: UMAP CellType
1. Ouvrir l'onglet "Explore & Analyze Datasets"
2. Sélectionner un organisme et dataset
3. Vérifier que l'UMAP s'affiche **plus grand** (800px vs 500px avant)
4. Les labels doivent être **lisibles**
5. Cliquer sur "Download Image (High-Res)"
6. Vérifier que le fichier téléchargé:
   - Est au format `.png`
   - Nom: `umap_celltype_2026-02-05.png`
   - Taille: ~2-5 MB
   - Dimensions: ~3600×3000 pixels (12"×10" à 300 DPI)

#### Test 2: Violin plots
1. Dans "Visualize Expression of Gene"
2. Sélectionner un gène
3. Vérifier affichage plus grand (800px)
4. Télécharger et vérifier format PNG

#### Test 3: CollecTRI
1. Onglet "Pseudo-bulk Analysis"
2. Lancer analyse CollecTRI
3. Vérifier que les 3 plots (barplot, volcano, network) sont:
   - Plus grands à l'écran (800px)
   - Network plot plus lisible (10×10" vs 5×5" avant)
4. Télécharger chaque plot et vérifier PNG

#### Test 4: Corrélation
1. Onglet "Calculate Co-Expression"
2. Sélectionner 2 gènes
3. Générer plot de corrélation
4. Vérifier affichage
5. Télécharger → doit être PNG (pas PDF)

---

### 3. Vérifications techniques

#### Vérifier résolution d'un PNG téléchargé

**Sur macOS:**
```bash
sips -g all umap_celltype_2026-02-05.png | grep dpi
# Devrait afficher: dpiHeight: 300.000 / dpiWidth: 300.000
```

**Sur Linux:**
```bash
identify -verbose umap_celltype_2026-02-05.png | grep Resolution
# Devrait afficher: Resolution: 300x300
```

#### Vérifier dimensions

```bash
sips -g pixelWidth -g pixelHeight umap_celltype_2026-02-05.png
# Devrait être environ 3600×3000 pixels (12"×10" à 300 DPI)
```

---

### 4. Test d'intégration publication

#### Test Word
1. Ouvrir Microsoft Word
2. Insérer une image téléchargée
3. Vérifier que:
   - L'image est nette même zoomée à 200%
   - Les labels sont lisibles
   - Pas de pixellisation

#### Test PowerPoint
1. Créer une diapo
2. Insérer l'image
3. Agrandir à toute la diapo
4. Vérifier netteté

#### Test LaTeX/Overleaf
```latex
\begin{figure}[h]
  \centering
  \includegraphics[width=0.8\textwidth]{umap_celltype_2026-02-05.png}
  \caption{UMAP projection of cell types}
\end{figure}
```

---

### 5. Checklist de validation

- [ ] Application démarre sans erreur
- [ ] Images affichées plus grandes (800px vs 500px)
- [ ] Labels lisibles sur tous les plots
- [ ] Tous les boutons "Download" fonctionnent
- [ ] Tous les téléchargements sont en PNG (pas PDF)
- [ ] DPI des PNG = 300
- [ ] Dimensions environ 3600×3000 pixels
- [ ] Qualité acceptable pour publication
- [ ] Pas de régression sur les fonctionnalités existantes

---

### 6. Test de non-régression

Vérifier que les fonctionnalités suivantes fonctionnent toujours:

- [ ] Import de datasets
- [ ] Filtrage de cellules
- [ ] Analyse différentielle
- [ ] Enrichment analysis
- [ ] Pseudo-bulk analysis
- [ ] Export de tables CSV
- [ ] Toutes les visualisations

---

### 7. Tests de performance

#### Temps de génération des images

Chronométrer:
1. Génération UMAP: ~1-3 secondes (acceptable)
2. Téléchargement UMAP: ~2-5 secondes (acceptable)
3. Génération CollecTRI network: ~3-8 secondes (acceptable)

> **Note:** Les temps peuvent être légèrement plus longs qu'avant car les images sont plus grandes, mais cela reste acceptable.

---

### 8. En cas de problème

#### Si l'application ne démarre pas

```bash
# Restaurer le backup
cp app.R.backup app.R
```

#### Si les images ne s'affichent pas

Vérifier dans la console R:
```r
# Python est bien chargé?
exists("sc")  # Doit retourner TRUE

# Scanpy est configuré?
sc$settings$figdir  # Doit retourner "figures"
```

#### Si les téléchargements échouent

Vérifier que le dossier `figures/` existe:
```bash
ls -la figures/
```

---

### 9. Comparaison avant/après

#### Créer un comparatif visuel

1. Télécharger la même image avec l'ancienne version
2. Télécharger avec la nouvelle version
3. Comparer côte à côte:
   - Netteté
   - Taille des labels
   - Résolution globale

---

## 📊 Métriques de succès

### Critères de validation

| Critère | Objectif | Validation |
|---------|----------|------------|
| **Taille affichage** | 800px | ✅ / ❌ |
| **Format téléchargement** | PNG | ✅ / ❌ |
| **DPI** | 300 | ✅ / ❌ |
| **Dimensions** | ~3600×3000 px | ✅ / ❌ |
| **Labels lisibles** | Oui | ✅ / ❌ |
| **Pas de régression** | Oui | ✅ / ❌ |
| **Performance acceptable** | <10s/image | ✅ / ❌ |

---

## 🐛 Problèmes connus potentiels

### 1. Mémoire insuffisante
**Symptôme:** L'application crash lors de la génération d'images  
**Solution:** Augmenter la mémoire Docker ou réduire légèrement les dimensions

### 2. Temps de chargement longs
**Symptôme:** Les images mettent >30s à se générer  
**Solution:** Normal pour les très gros datasets, considérer un système de cache

### 3. Polices manquantes
**Symptôme:** Labels mal affichés ou warnings dans la console  
**Solution:** Installer les polices système requises par matplotlib

---

## ✅ Validation finale

Une fois tous les tests passés:

1. Commit des changements
2. Mise à jour de la documentation
3. Notification aux utilisateurs des améliorations

```bash
git add app.R MODIFICATIONS_IMAGES_HAUTE_RESOLUTION.md
git commit -m "feat: Système images haute résolution pour publications (300 DPI PNG)"
git push
```

---

**Durée estimée des tests:** 15-30 minutes  
**Priorité:** Haute (impact utilisateur important)
