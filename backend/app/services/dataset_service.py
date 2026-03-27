"""
Dataset loading and management service
"""
import scanpy as sc
import json
from pathlib import Path
from typing import Optional, Dict, Any
from loguru import logger
from cachetools import TTLCache

from app.core.config import settings
from app.core.models import OrganismType

class DatasetService:
    """Service for managing dataset operations"""
    
    def __init__(self):
        self.cache = TTLCache(maxsize=10, ttl=settings.CACHE_TTL)
        self.datasets_config = self._load_config()
    
    def _load_config(self) -> Dict:
        """Load datasets configuration"""
        import os
        # Allow override via environment variable
        config_path = os.getenv('CONFIG_PATH', str(settings.CONFIG_DIR / "datasets_config.json"))
        with open(config_path) as f:
            return json.load(f)
    
    def get_available_organisms(self) -> Dict[str, Any]:
        """Get list of available organisms and their datasets"""
        result = {}
        for organism, data in self.datasets_config.items():
            datasets_data = data.get("Datasets", [])
            # Handle both list (legacy) and dict (new) formats
            dataset_list = []
            if isinstance(datasets_data, list):
                dataset_list = datasets_data
            elif isinstance(datasets_data, dict):
                dataset_list = list(datasets_data.keys())

            result[organism] = {
                "status": data.get("Status", "Unknown"),
                "description": data.get("Description", ""),
                "datasets": dataset_list
            }
        return result
    
    def load_dataset(
        self, 
        organism: str, 
        dataset_name: str,
        size_option: str = "full"
    ) -> sc.AnnData:
        """
        Load an h5ad dataset with caching
        
        Args:
            organism: Organism name (Human, Mouse, Zebrafish, Integrated)
            dataset_name: Dataset identifier
            size_option: Size option for large datasets (full, large, medium, small)
        
        Returns:
            AnnData object
        """
        cache_key = f"{organism}_{dataset_name}_{size_option}"
        
        # Check cache
        if cache_key in self.cache:
            logger.info(f"📦 Loading from cache: {cache_key}")
            return self.cache[cache_key]
        
        # Construct file path
        dataset_path = self._get_dataset_path(organism, dataset_name, size_option)
        
        # Check if file exists, if not and size_option is 'large' or 'medium', try fallback to 'full' or 'subset'
        if not dataset_path.exists():
            logger.warning(f"⚠️ Requested dataset path not found: {dataset_path}")
            
            # Fallback logic
            fallback_options = []
            if size_option in ["large", "medium", "small"]:
                fallback_options = ["full", "subset"]
            elif size_option == "subset":
                fallback_options = ["full"]
                
            for fallback in fallback_options:
                logger.info(f"🔄 Attempting fallback to size_option: {fallback}")
                try:
                    fallback_path = self._get_dataset_path(organism, dataset_name, fallback)
                    if fallback_path.exists():
                        logger.info(f"✅ Fallback successful: using {fallback_path}")
                        dataset_path = fallback_path
                        # Continue with this path
                        break
                except Exception as e:
                    logger.warning(f"Fallback check failed for {fallback}: {e}")

        # Final check
        if not dataset_path.exists():
            # ... existing debug logging ...
            parent_dir = dataset_path.parent
            logger.error(f"❌ Dataset not found at: {dataset_path}")
            if parent_dir.exists():
                logger.info(f"📂 Contents of directory {parent_dir}:")
                try:
                    files = [f.name for f in parent_dir.iterdir()]
                    logger.info(f"   Files: {files}")
                except Exception as e:
                    logger.error(f"   Failed to list directory: {e}")
            else:
                 logger.error(f"❌ Parent directory does not exist: {parent_dir}")
                 # Check grandparent
                 if parent_dir.parent.exists():
                     logger.info(f"📂 Contents of grandparent {parent_dir.parent}:")
                     try:
                        files = [f.name for f in parent_dir.parent.iterdir()]
                        logger.info(f"   Files: {files}")
                     except Exception:
                        pass

            raise FileNotFoundError(f"Dataset not found: {dataset_path}")
        
        logger.info(f"📂 Loading dataset: {dataset_path}")
        adata = sc.read_h5ad(dataset_path)
        
        # Ensure required layers exist
        if 'scvi_normalized' not in adata.layers:
            logger.warning("scvi_normalized layer not found, using X")
            adata.layers['scvi_normalized'] = adata.X.copy()
        
        # Cache the dataset
        if settings.CACHE_ENABLED:
            self.cache[cache_key] = adata
        
        return adata
    
    def _get_dataset_path(
        self, 
        organism: str, 
        dataset_name: str,
        size_option: str
    ) -> Path:
        """Construct dataset file path"""
        
        # Check if we have explicit config for this dataset
        datasets_config = self.datasets_config.get(organism, {}).get("Datasets", {})
        
        explicit_path = None
        if isinstance(datasets_config, dict) and dataset_name in datasets_config:
            dataset_conf = datasets_config[dataset_name]
            # Map size_options to config keys. 
            # If size_option is 'full', use full_path.
            # Otherwise allow explicit mapping or fallback to 'subset_path' for optimizations
            if size_option == "full":
                explicit_path = dataset_conf.get("full_path")
            elif size_option in ["subset", "fast"]: # Explicit subset modes
                 explicit_path = dataset_conf.get("subset_path")
        
        if explicit_path:
             return settings.DATA_DIR / organism / explicit_path

        # Handle size options (Legacy/Implicit logic)
        if size_option != "full":
            size_suffix = {
                "large": "_optimized_large",
                "medium": "_optimized_medium", 
                "small": "_optimized_small",
                "sub5k": "_sub5k",
                "sub10k": "_sub10k",
                "verified": "_verified"
            }.get(size_option, "")
            
            base_name = Path(dataset_name).stem
            dataset_file = f"{base_name}{size_suffix}.h5ad"
        else:
            dataset_file = f"{dataset_name}.h5ad" if not dataset_name.endswith('.h5ad') else dataset_name
        
        dataset_path = settings.DATA_DIR / organism / dataset_file
        return dataset_path
    
    def get_dataset_info(self, adata: sc.AnnData) -> Dict[str, Any]:
        """Extract metadata from AnnData object"""
        return {
            "n_cells": adata.n_obs,
            "n_genes": adata.n_vars,
            "cell_types": list(adata.obs['CellType'].unique()) if 'CellType' in adata.obs else [],
            "metadata_columns": list(adata.obs.columns),
            "available_layers": list(adata.layers.keys()),
            "has_umap": 'X_umap' in adata.obsm,
            "obs_keys": list(adata.obs.keys()),
            "var_keys": list(adata.var.keys())
        }
    
    def filter_dataset(
        self, 
        adata: sc.AnnData,
        filter_column: str,
        filter_values: list
    ) -> sc.AnnData:
        """Filter dataset by metadata column"""
        mask = adata.obs[filter_column].isin(filter_values)
        return adata[mask].copy()
    
    def filter_by_clusters(
        self,
        adata: sc.AnnData,
        clusters: list,
        cluster_column: str = "CellType"
    ) -> sc.AnnData:
        """
        Filter dataset by cluster/cell type selection
        
        Args:
            adata: AnnData object
            clusters: List of cluster/cell type names to keep
            cluster_column: Column name containing cluster assignments
            
        Returns:
            Filtered AnnData object
        """
        if cluster_column not in adata.obs.columns:
            raise ValueError(f"Column '{cluster_column}' not found in dataset")
        
        if not clusters:
            logger.warning("No clusters provided for filtering, returning original dataset")
            return adata.copy()
        
        mask = adata.obs[cluster_column].isin(clusters)
        filtered_adata = adata[mask].copy()
        
        logger.info(f"🔍 Filtered dataset: {adata.n_obs} → {filtered_adata.n_obs} cells "
                   f"(kept {len(clusters)} clusters from {cluster_column})")
        
        return filtered_adata

# Global instance
dataset_service = DatasetService()
