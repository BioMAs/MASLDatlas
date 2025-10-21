# 📥 Guide Utilisateur - Export des Résultats en CSV

**MASLDatlas - Version 2.0**  
**Date:** 13 octobre 2025

---

## 🎯 Qu'est-ce que c'est ?

Vous pouvez maintenant **télécharger tous vos résultats d'analyse** au format CSV pour :
- 📊 Les ouvrir dans Excel, LibreOffice, ou Google Sheets
- 🔬 Les réanalyser dans R, Python, ou d'autres outils
- 📄 Les inclure dans vos publications scientifiques
- 💾 Les archiver pour vos projets

---

## 📥 Comment Exporter vos Résultats

### Étapes Générales

1. **Lancez votre analyse** dans MASLDatlas (DGE, enrichissement, corrélation, etc.)
2. **Attendez les résultats** - le tableau de résultats apparaît
3. **Cliquez sur le bouton** 📥 **"Download ... (CSV)"** sous le tableau
4. **Le fichier est téléchargé** dans votre dossier Téléchargements

C'est aussi simple que ça ! 🎉

---

## 📊 Quels Résultats Peuvent Être Exportés ?

### 1. 🧬 Marqueurs de Types Cellulaires
**Où:** Onglet "Cell Type Identification" > "Identify Cell Types"

**Quoi:** Liste des gènes marqueurs pour chaque type cellulaire

**Bouton:** 📥 Download Markers (CSV)

**Fichier:** `Cell_markers_2025-10-13.csv`

**Contient:**
- Noms des gènes
- Scores
- P-values
- Log fold changes

---

### 2. 🔗 Corrélations de Gènes
**Où:** Onglet "Correlation"

**Quoi:** Statistiques de corrélation entre deux gènes

**Bouton:** 📥 Download Correlation Results (CSV)

**Fichier:** `Correlation_results_2025-10-13.csv`

**Contient:**
- Coefficient de corrélation (Spearman ou Pearson)
- P-value
- Statistiques de test

---

### 3. 📈 Expression Différentielle (DGE)
**Où:** Onglet "Differential Expression Analysis"

**Quoi:** Gènes différentiellement exprimés entre deux groupes

**Bouton:** 📥 Download DGE Results (CSV)

**Fichier:** `DGE_results_2025-10-13.csv`

**Contient:**
- Noms des gènes
- Log2 Fold Change
- P-values
- P-values ajustées (FDR)
- Scores statistiques

---

### 4. 🧪 Enrichissement Fonctionnel
**Où:** Onglet "Differential Expression Analysis" > Sous-onglet "Enrichment"

**Quoi:** Pathways et fonctions biologiques enrichis

**Bouton:** 📥 Download Enrichment Results (CSV)

**Fichier:** `Enrichment_GO_2025-10-13.csv` (le nom change selon le type)

**Types disponibles:**
- **GO** - Gene Ontology complet
- **BP** - Biological Processes
- **KEGG** - KEGG Pathways
- **Reactome** - Reactome Pathways
- **WikiPathways** - WikiPathways

**Contient:**
- Noms des pathways
- P-values
- Gènes impliqués
- Statistiques d'enrichissement

---

### 5. 🔬 Analyse Pseudo-bulk
**Où:** Onglet "Pseudo-bulk Analysis"

**Quoi:** Résultats DESeq2 pour analyse pseudo-bulk

**Bouton:** 📥 Download Pseudo-bulk Results (CSV)

**Fichier:** `Pseudobulk_results_2025-10-13.csv`

**Contient:**
- Gene Name
- Log2 Fold Change
- P-value
- P-value ajustée
- Statistique

---

### 6. 🧬 Enrichissement Pseudo-bulk
**Où:** Onglet "Pseudo-bulk Analysis" > Section enrichissement (en bas)

**Quoi:** Pathways enrichis dans l'analyse pseudo-bulk

**Bouton:** 📥 Download Pseudo-bulk Enrichment (CSV)

**Fichier:** `Pseudobulk_enrichment_KEGG_2025-10-13.csv`

**Types disponibles:** GO, BP, KEGG, Reactome, WikiPathways

---

## 📋 Format des Fichiers

### Nom des Fichiers
Tous les fichiers suivent ce format :
```
[Type_Analyse]_[Date].csv
```

**Exemples:**
- `Cell_markers_2025-10-13.csv`
- `DGE_results_2025-10-13.csv`
- `Enrichment_KEGG_2025-10-13.csv`

La date est ajoutée automatiquement pour éviter d'écraser vos anciens exports.

### Format CSV
- **Séparateur:** Virgule (`,`)
- **Encodage:** UTF-8
- **Première ligne:** Noms des colonnes
- **Compatible avec:** Excel, R, Python, LibreOffice, Google Sheets

---

## 💡 Conseils d'Utilisation

### ✅ Bonnes Pratiques

1. **Lancez l'analyse AVANT d'exporter**
   - Le bouton ne fonctionnera que si des résultats sont disponibles

2. **Organisez vos téléchargements**
   - Renommez les fichiers si nécessaire
   - Créez des dossiers par projet

3. **Exportez régulièrement**
   - Sauvegardez vos résultats après chaque analyse importante

4. **Vérifiez les fichiers**
   - Ouvrez le CSV pour vérifier qu'il contient bien vos données

### 🔬 Réutilisation dans R

```r
# Importer un CSV dans R
data <- read.csv("DGE_results_2025-10-13.csv")

# Voir les premières lignes
head(data)

# Filtrer les gènes significatifs
significant <- data[data$padj < 0.05, ]

# Créer un volcano plot
library(ggplot2)
ggplot(data, aes(x = log2FoldChange, y = -log10(pvalue))) +
  geom_point() +
  theme_minimal()
```

### 🐍 Réutilisation dans Python

```python
import pandas as pd
import matplotlib.pyplot as plt

# Importer le CSV
data = pd.read_csv("DGE_results_2025-10-13.csv")

# Voir les données
print(data.head())

# Filtrer
significant = data[data['padj'] < 0.05]

# Volcano plot
plt.scatter(data['log2FoldChange'], -np.log10(data['pvalue']))
plt.xlabel('Log2 Fold Change')
plt.ylabel('-Log10 P-value')
plt.show()
```

### 📊 Ouvrir dans Excel

1. **Double-cliquez** sur le fichier CSV
2. Excel l'ouvre automatiquement
3. Si problème de séparation :
   - Ouvrez Excel
   - Fichier > Importer > CSV
   - Choisissez "Virgule" comme séparateur

---

## ❓ FAQ - Questions Fréquentes

### Q1: Le bouton ne fait rien quand je clique
**R:** Assurez-vous d'avoir lancé l'analyse et que les résultats sont affichés. Le bouton est désactivé si aucune donnée n'est disponible.

### Q2: Où sont mes fichiers téléchargés ?
**R:** Par défaut dans votre dossier **Téléchargements** (ou **Downloads**). Vérifiez les paramètres de votre navigateur.

### Q3: Le fichier a des caractères bizarres dans Excel
**R:** Problème d'encodage. Dans Excel :
- Fichier > Importer > Texte CSV
- Choisir encodage **UTF-8**

### Q4: Puis-je exporter tous les résultats en une fois ?
**R:** Actuellement non. Vous devez exporter chaque analyse séparément. Un export groupé sera ajouté dans une future version.

### Q5: Les nombres ont trop de décimales
**R:** C'est normal pour les p-values. Dans Excel :
- Sélectionnez la colonne
- Format > Nombre > Scientifique (2 décimales)

### Q6: Puis-je exporter en format Excel (.xlsx) ?
**R:** Pas encore. Seul le CSV est disponible pour l'instant. Vous pouvez ouvrir le CSV dans Excel et le sauvegarder en .xlsx.

### Q7: Le téléchargement prend du temps
**R:** Normal pour les gros datasets (>10,000 gènes). Une barre de progression apparaît pendant l'export.

---

## 🐛 Problèmes Connus

### Export échoue avec message d'erreur
**Cause:** Données corrompues ou manquantes  
**Solution:** Relancez l'analyse, rechargez le dataset

### Fichier vide ou incomplet
**Cause:** Interruption pendant l'export  
**Solution:** Réessayez le téléchargement

### Notification ne disparaît pas
**Cause:** Bug visuel mineur  
**Solution:** Rafraîchissez la page

---

## 📞 Support

**Problème avec l'export ?**
1. Vérifiez que vous utilisez la dernière version de l'app
2. Consultez ce guide
3. Contactez l'équipe de développement

**Contact:** [Votre email de support]

---

## 🎉 Nouveautés

**Version 2.0 (13 octobre 2025)**
- ✨ Nouveau : Export CSV pour tous les résultats
- 📊 6 types d'exports disponibles
- 🚀 Export rapide en 1 clic
- 📁 Nommage automatique avec date

---

**Bon export ! 📥✨**
