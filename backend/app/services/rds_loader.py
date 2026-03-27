"""
Service for loading legacy R RDS files (CollecTRI, PROGENy, MSigDB)
Uses rpy2 to read .rds files and convert to Python data structures
"""
import pandas as pd
from pathlib import Path
from typing import Dict, Any, Optional
from loguru import logger
import os

try:
    from rpy2 import robjects
    from rpy2.robjects import pandas2ri
    from rpy2.robjects.packages import importr
    
    # Activate pandas conversion
    pandas2ri.activate()
    
    RDS_AVAILABLE = True
except ImportError:
    logger.warning("⚠️ rpy2 not available - RDS loading will be disabled")
    RDS_AVAILABLE = False


class RDSLoaderService:
    """
    Load and cache legacy R data files (.rds, .RData)
    """
    
    def __init__(self, enrichment_sets_dir: Optional[Path] = None):
        """
        Initialize RDS loader
        
        Args:
            enrichment_sets_dir: Path to enrichment_sets directory
        """
        if enrichment_sets_dir is None:
            # Default to enrichment_sets in project root
            from app.core.config import settings
            self.enrichment_sets_dir = settings.BASE_DIR / "enrichment_sets"
        else:
            self.enrichment_sets_dir = enrichment_sets_dir
        
        # Cache for loaded datasets
        self._cache: Dict[str, Any] = {}
        
        logger.info(f"📦 RDS Loader initialized (dir: {self.enrichment_sets_dir})")
        
        if not RDS_AVAILABLE:
            logger.warning("⚠️ rpy2 is not installed - RDS files cannot be loaded")
    
    def load_rds(self, filename: str) -> Any:
        """
        Load an RDS file
        
        Args:
            filename: Name of the .rds file (e.g., 'collectri.rds')
            
        Returns:
            R object converted to Python structure
        """
        if not RDS_AVAILABLE:
            raise ImportError("rpy2 is required to load RDS files. Install with: pip install rpy2")
        
        # Check cache
        if filename in self._cache:
            logger.debug(f"✅ Using cached RDS: {filename}")
            return self._cache[filename]
        
        file_path = self.enrichment_sets_dir / filename
        
        if not file_path.exists():
            raise FileNotFoundError(f"RDS file not found: {file_path}")
        
        logger.info(f"📂 Loading RDS file: {filename}")
        
        try:
            # Use R's readRDS function
            readRDS = robjects.r['readRDS']
            r_object = readRDS(str(file_path))
            
            # Cache it
            self._cache[filename] = r_object
            
            logger.info(f"✅ Loaded RDS: {filename}")
            return r_object
            
        except Exception as e:
            logger.error(f"❌ Failed to load RDS file {filename}: {e}")
            raise
    
    def load_collectri(self) -> pd.DataFrame:
        """
        Load CollecTRI transcription factor network
        
        Returns:
            DataFrame with columns: source (TF), target (gene), weight/mor
        """
        try:
            r_obj = self.load_rds("collectri.rds")
            
            # Convert R data.frame to pandas
            # collectri.rds should be a data.frame with columns: source, target, mor
            if hasattr(r_obj, 'to_csvstr'):
                # If it's a DataFrame-like object
                df = pandas2ri.rpy2py(r_obj)
            else:
                # Try manual conversion
                with (robjects.default_converter + pandas2ri.converter).context():
                    df = robjects.conversion.get_conversion().rpy2py(r_obj)
            
            logger.info(f"✅ CollecTRI loaded: {len(df)} interactions")
            return df
            
        except Exception as e:
            logger.error(f"❌ Failed to load CollecTRI: {e}")
            raise
    
    def load_progeny(self) -> pd.DataFrame:
        """
        Load PROGENy pathway signatures
        
        Returns:
            DataFrame with genes as rows and pathways as columns (or vice versa)
        """
        try:
            r_obj = self.load_rds("progeny.rds")
            
            # Convert to pandas
            with (robjects.default_converter + pandas2ri.converter).context():
                df = robjects.conversion.get_conversion().rpy2py(r_obj)
            
            logger.info(f"✅ PROGENy loaded: shape {df.shape}")
            return df
            
        except Exception as e:
            logger.error(f"❌ Failed to load PROGENy: {e}")
            raise
    
    def load_msigdb(self) -> Any:
        """
        Load MSigDB Hallmark gene sets
        
        Returns:
            Gene sets data structure (format depends on .rds structure)
        """
        try:
            r_obj = self.load_rds("msigdb.rds")
            
            # MSigDB might be a list of gene sets
            # Convert appropriately based on structure
            logger.info(f"✅ MSigDB loaded")
            return r_obj
            
        except Exception as e:
            logger.error(f"❌ Failed to load MSigDB: {e}")
            raise
    
    def load_organism_data(self, organism: str) -> Any:
        """
        Load organism-specific enrichment data
        
        Args:
            organism: 'human', 'mouse', or 'zebrafish'
            
        Returns:
            R object with organism data
        """
        filename = f"{organism.lower()}.RData"
        file_path = self.enrichment_sets_dir / filename
        
        if not file_path.exists():
            raise FileNotFoundError(f"Organism data not found: {file_path}")
        
        if not RDS_AVAILABLE:
            raise ImportError("rpy2 is required to load RData files")
        
        logger.info(f"📂 Loading RData file: {filename}")
        
        try:
            # Load .RData file
            robjects.r['load'](str(file_path))
            
            # List loaded objects
            loaded_objects = list(robjects.globalenv.keys())
            logger.info(f"✅ Loaded .RData with objects: {loaded_objects}")
            
            # Return the environment or specific objects
            return robjects.globalenv
            
        except Exception as e:
            logger.error(f"❌ Failed to load {filename}: {e}")
            raise
    
    def convert_to_decoupler_network(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Convert R network data.frame to decoupler-compatible format
        
        Expected columns: source, target, weight (or mor for mode of regulation)
        
        Args:
            df: DataFrame from R
            
        Returns:
            Cleaned DataFrame for decoupler
        """
        # Ensure required columns
        required_cols = ['source', 'target']
        
        if not all(col in df.columns for col in required_cols):
            logger.warning(f"Network missing required columns. Found: {df.columns.tolist()}")
            # Try to infer column names
            if len(df.columns) >= 2:
                df.columns = ['source', 'target'] + list(df.columns[2:])
        
        # Add weight column if missing (default to 1 or use 'mor' if available)
        if 'weight' not in df.columns:
            if 'mor' in df.columns:
                df['weight'] = df['mor']
            else:
                df['weight'] = 1
        
        # Clean up
        df = df[['source', 'target', 'weight']].copy()
        df = df.dropna()
        
        logger.info(f"📊 Network prepared: {len(df)} interactions, "
                   f"{df['source'].nunique()} sources, {df['target'].nunique()} targets")
        
        return df


# Global singleton
_rds_loader_instance: Optional[RDSLoaderService] = None

def get_rds_loader() -> RDSLoaderService:
    """Get or create global RDS loader instance"""
    global _rds_loader_instance
    if _rds_loader_instance is None:
        _rds_loader_instance = RDSLoaderService()
    return _rds_loader_instance
