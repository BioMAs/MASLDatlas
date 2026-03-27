#!/usr/bin/env python3
"""
Script de vérification de l'installation - Phase 1
Teste les nouvelles fonctionnalités implémentées
"""
import sys
from pathlib import Path

def check_backend_dependencies():
    """Vérifie les dépendances Python"""
    print("🔍 Vérification des dépendances backend...")
    
    deps_ok = True
    
    # Check rpy2
    try:
        import rpy2
        print(f"  ✅ rpy2 {rpy2.__version__}")
    except ImportError:
        print("  ❌ rpy2 non installé - pip install rpy2")
        deps_ok = False
    
    # Check decoupler
    try:
        import decoupler as dc
        print(f"  ✅ decoupler {dc.__version__}")
    except ImportError:
        print("  ❌ decoupler non installé")
        deps_ok = False
    
    # Check cachetools
    try:
        import cachetools
        print(f"  ✅ cachetools {cachetools.__version__}")
    except ImportError:
        print("  ❌ cachetools non installé")
        deps_ok = False
    
    return deps_ok

def check_r_installation():
    """Vérifie que R est installé"""
    print("\n🔍 Vérification de R...")
    
    import subprocess
    try:
        result = subprocess.run(['R', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            version_line = result.stdout.split('\n')[0]
            print(f"  ✅ R installé: {version_line}")
            return True
        else:
            print("  ❌ R non trouvé")
            return False
    except FileNotFoundError:
        print("  ❌ R non installé ou non dans PATH")
        print("     macOS: brew install r")
        print("     Ubuntu: sudo apt-get install r-base r-base-dev")
        return False

def check_rds_files():
    """Vérifie la présence des fichiers RDS"""
    print("\n🔍 Vérification des fichiers RDS...")
    
    base_dir = Path(__file__).parent
    enrichment_dir = base_dir / "enrichment_sets"
    
    if not enrichment_dir.exists():
        print(f"  ❌ Dossier enrichment_sets non trouvé: {enrichment_dir}")
        return False
    
    required_files = [
        "collectri.rds",
        "progeny.rds",
        "msigdb.rds"
    ]
    
    all_ok = True
    for filename in required_files:
        filepath = enrichment_dir / filename
        if filepath.exists():
            size_mb = filepath.stat().st_size / (1024 * 1024)
            print(f"  ✅ {filename} ({size_mb:.2f} MB)")
        else:
            print(f"  ⚠️  {filename} non trouvé (optionnel)")
            all_ok = False
    
    return all_ok

def check_new_files():
    """Vérifie la présence des nouveaux fichiers créés"""
    print("\n🔍 Vérification des nouveaux fichiers...")
    
    base_dir = Path(__file__).parent
    
    files_to_check = {
        "Backend": [
            "backend/app/services/cache_service.py",
            "backend/app/services/rds_loader.py",
            "backend/app/api/decoupler.py"
        ],
        "Frontend": [
            "frontend/src/components/ClusterFilter.tsx",
            "frontend/src/components/DecouplerPanel.tsx"
        ]
    }
    
    all_ok = True
    for category, files in files_to_check.items():
        print(f"\n  {category}:")
        for filepath in files:
            full_path = base_dir / filepath
            if full_path.exists():
                print(f"    ✅ {filepath}")
            else:
                print(f"    ❌ {filepath} - MANQUANT")
                all_ok = False
    
    return all_ok

def test_imports():
    """Teste les imports des nouveaux modules"""
    print("\n🔍 Test des imports Python...")
    
    sys.path.insert(0, str(Path(__file__).parent / "backend"))
    
    try:
        from app.services.cache_service import get_cache_service
        cache = get_cache_service()
        print("  ✅ cache_service importé et initialisé")
        
        from app.services.rds_loader import get_rds_loader
        rds = get_rds_loader()
        print("  ✅ rds_loader importé et initialisé")
        
        from app.services import enrichment_service
        print("  ✅ enrichment_service importé")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Erreur d'import: {e}")
        return False

def test_cache_service():
    """Test du service de cache"""
    print("\n🔍 Test du service de cache...")
    
    sys.path.insert(0, str(Path(__file__).parent / "backend"))
    
    try:
        from app.services.cache_service import get_cache_service
        
        cache = get_cache_service()
        
        # Test stats
        stats = cache.get_cache_stats()
        print(f"  ✅ Cache stats: {stats['filtered_datasets']['maxsize']} datasets max")
        
        # Test key generation
        key = cache._generate_filter_key(
            "Human",
            "GSE181483",
            clusters=["Hepatocyte", "Stellate"]
        )
        print(f"  ✅ Clé de cache générée: {key[:16]}...")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Erreur de test: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Fonction principale"""
    print("=" * 60)
    print("🚀 Vérification de l'implémentation - Phase 1")
    print("=" * 60)
    
    results = []
    
    # 1. Dépendances
    results.append(("Dépendances backend", check_backend_dependencies()))
    
    # 2. R installation
    results.append(("Installation R", check_r_installation()))
    
    # 3. Fichiers RDS (optionnel)
    results.append(("Fichiers RDS", check_rds_files()))
    
    # 4. Nouveaux fichiers
    results.append(("Nouveaux fichiers", check_new_files()))
    
    # 5. Imports
    results.append(("Imports Python", test_imports()))
    
    # 6. Cache service
    results.append(("Service de cache", test_cache_service()))
    
    # Résumé
    print("\n" + "=" * 60)
    print("📊 RÉSUMÉ")
    print("=" * 60)
    
    for test_name, success in results:
        status = "✅ OK" if success else "❌ ÉCHEC"
        print(f"{status:10} - {test_name}")
    
    all_passed = all(success for _, success in results)
    
    if all_passed:
        print("\n🎉 Tous les tests sont passés !")
        print("\n📝 Prochaines étapes:")
        print("  1. Installer les dépendances frontend: cd frontend && npm install")
        print("  2. Démarrer le backend: cd backend && uvicorn app.main:app --reload")
        print("  3. Démarrer le frontend: cd frontend && npm run dev")
        print("  4. Tester l'interface à http://localhost:5173")
        return 0
    else:
        print("\n⚠️  Certains tests ont échoué. Vérifiez les messages ci-dessus.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
