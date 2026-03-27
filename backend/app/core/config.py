"""
Application configuration
"""
from pydantic_settings import BaseSettings
from pathlib import Path
from typing import List
import os

class Settings(BaseSettings):
    """Application settings"""
    
    # Environment
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # API
    API_V1_PREFIX: str = "/api"
    PROJECT_NAME: str = "MASLDatlas"
    VERSION: str = "2.0.0"
    
    # CORS - Allow configuration via environment variable
    ALLOWED_ORIGINS: List[str] = []
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Parse ALLOWED_ORIGINS from environment variable if set
        if not self.ALLOWED_ORIGINS:
            origins_env = os.getenv("ALLOWED_ORIGINS", "")
            if origins_env:
                self.ALLOWED_ORIGINS = [origin.strip() for origin in origins_env.split(",")]
            else:
                # Default origins for development
                self.ALLOWED_ORIGINS = [
                    "http://localhost:5173",  # Vite dev server
                    "http://localhost:3000",
                    "http://localhost:8080",
                ]
    
    # Paths
    BASE_DIR: Path = Path(__file__).parent.parent.parent.parent
    
    @property
    def _base_dir_computed(self) -> Path:
        """
        Compute base dir based on environment.
        This is a workaround because defining BASE_DIR directly with conditional logic 
        in Pydantic field defaults can be tricky if we want it to be static.
        However, for simplicity, we'll determine it outside or use a validator.
        """
        return self.BASE_DIR

def get_base_dir() -> Path:
    """Helper to determine base directory"""
    file_path = Path(__file__).resolve()
    
    # Check for Docker structure (/app/app/core/config.py -> /app)
    # inside container: /app/app (source) and /app/datasets (volume)
    # file is at /app/app/core/config.py
    # parent.parent.parent is /app
    root_docker = file_path.parent.parent.parent
    if (root_docker / "datasets").exists():
        return root_docker
        
    # Check for Local structure (backend/app/core/config.py -> project_root)
    # file is at .../backend/app/core/config.py
    # parent.parent.parent.parent is .../project_root
    root_local = file_path.parent.parent.parent.parent
    return root_local

class Settings(BaseSettings):
    """Application settings"""
    
    # Environment
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # API
    API_V1_PREFIX: str = "/api"
    PROJECT_NAME: str = "MASLDatlas"
    VERSION: str = "2.0.0"
    
    # CORS - Allow configuration via environment variable
    ALLOWED_ORIGINS: List[str] = []
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Parse ALLOWED_ORIGINS from environment variable if set
        if not self.ALLOWED_ORIGINS:
            origins_env = os.getenv("ALLOWED_ORIGINS", "")
            if origins_env:
                self.ALLOWED_ORIGINS = [origin.strip() for origin in origins_env.split(",")]
            else:
                # Default origins for development
                self.ALLOWED_ORIGINS = [
                    "http://localhost:5173",  # Vite dev server
                    "http://localhost:3000",
                    "http://localhost:8080",
                ]
    
    # Paths
    BASE_DIR: Path = get_base_dir()
    DATA_DIR: Path = BASE_DIR / "datasets"
    CONFIG_DIR: Path = BASE_DIR / "config"
    CONFIG_PATH: str = str(CONFIG_DIR / "datasets_config.json")
    CACHE_DIR: Path = BASE_DIR / "cache"
    ENRICHMENT_DIR: Path = BASE_DIR / "enrichment_sets"
    
    # Cache
    CACHE_ENABLED: bool = True
    CACHE_TTL: int = 3600  # 1 hour

    # Redis (optional — falls back to in-memory if unavailable)
    REDIS_URL: str = "redis://masldatlas-redis:6379/0"
    REDIS_ENABLED: bool = True
    
    # Dataset limits
    MAX_CELLS_DISPLAY: int = 100000
    MAX_GENES_DISPLAY: int = 50000
    
    # Computation
    N_JOBS: int = -1  # Use all available cores
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
