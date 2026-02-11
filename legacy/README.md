# Legacy Code Archive

Ce dossier contient le code archivé de l'ancienne application MASLDatlas.

## Structure

### `shiny/`
Contient l'ancienne application Shiny R (obsolète):
- `app.R` - Application principale Shiny (~4724 lignes)
- `app.R.backup` - Sauvegarde de l'application
- `www/` - Assets CSS/JS custom de l'interface Shiny
- `R/` - Dossier pour modules R (actuellement vide)
- `Dockerfile` - Dockerfile pour l'application Shiny
- `docker-compose.yml` - Configuration Docker Compose Shiny (développement)
- `docker-compose.prod.yml` - Configuration Docker Compose Shiny (production)

**Note**: Cette application a été remplacée par l'architecture moderne FastAPI (backend) + React (frontend).

### `documentation/`
Documentation de migration et rapports de validation:
- `MIGRATION_GUIDE.md` - Guide de migration Shiny → FastAPI/React
- `TEST_REPORT.md` - Rapport de tests de validation
- `VALIDATION_COMPLETE.md` - Validation complète v2.0
- `README.v2.md` - Documentation v2 (remplacée par README.md principal)
- `GUIDE_TEST_IMAGES.md` - Guide de test des images haute résolution
- `MODIFICATIONS_IMAGES_HAUTE_RESOLUTION.md` - Détails des modifications

### `tests/`
Dossier réservé pour archiver d'anciens scripts de test si nécessaire.

## Application Actuelle

L'application moderne active se trouve dans:
- **Backend**: `/backend/` (FastAPI + Python)
- **Frontend**: `/frontend/` (React + TypeScript + Vite)
- **Documentation**: `/docs/` et `README.md`

Pour démarrer l'application moderne, voir [QUICKSTART.md](../QUICKSTART.md).

## Raison de l'Archivage

L'application Shiny a été remplacée par une architecture moderne pour:
- ✅ Meilleures performances (API REST vs serveur Shiny)
- ✅ Séparation frontend/backend (scalabilité)
- ✅ Interface moderne et responsive (React + Tailwind)
- ✅ Meilleure maintenabilité du code
- ✅ Support Docker optimisé

---

**Date d'archivage**: 6 février 2026  
**Conservation**: Ce code est conservé pour référence historique uniquement.
