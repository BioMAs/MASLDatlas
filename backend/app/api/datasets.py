"""
API endpoints for dataset operations
"""
from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from loguru import logger

from app.core.models import DatasetLoadRequest, DatasetInfo, OrganismType
from app.services.dataset_service import dataset_service

router = APIRouter()

# Global dataset storage (in production, use Redis or similar)
current_dataset = {}

@router.get("/organisms")
def get_organisms():
    """Get list of available organisms and their datasets"""
    try:
        return dataset_service.get_available_organisms()
    except Exception as e:
        logger.error(f"Error fetching organisms: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/load")
def load_dataset(request: DatasetLoadRequest):
    """Load a dataset into memory"""
    try:
        logger.info(f"Loading dataset: {request.organism}/{request.dataset_name}")

        
        adata = dataset_service.load_dataset(
            request.organism.value,
            request.dataset_name,
            request.size_option
        )
        
        # Store in global state (session ID in production)
        session_id = f"{request.organism.value}_{request.dataset_name}"
        current_dataset[session_id] = adata
        
        # Get dataset info
        info = dataset_service.get_dataset_info(adata)
        
        return {
            "success": True,
            "session_id": session_id,
            "info": info
        }
        
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error loading dataset: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/info/{session_id}")
async def get_dataset_info(session_id: str):
    """Get information about a loaded dataset"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        info = dataset_service.get_dataset_info(adata)
        return info
    except Exception as e:
        logger.error(f"Error getting dataset info: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/genes/{session_id}")
async def get_dataset_genes(session_id: str):
    """Get list of all genes in the dataset"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        return {
            "genes": adata.var_names.tolist()
        }
    except Exception as e:
        logger.error(f"Error fetching gene list: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/gene-expression/{session_id}/{gene}")
async def get_gene_expression(session_id: str, gene: str):
    """Get expression values for a specific gene"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        if gene not in adata.var_names:
            raise HTTPException(status_code=404, detail=f"Gene {gene} not found")
        
        # Get expression data
        expr = adata[:, gene].layers['scvi_normalized'].toarray().flatten()
        
        # Get UMAP coordinates if available
        umap_coords = None
        if 'X_umap' in adata.obsm:
            umap_coords = {
                "x": adata.obsm['X_umap'][:, 0].tolist(),
                "y": adata.obsm['X_umap'][:, 1].tolist()
            }
        
        return {
            "gene": gene,
            "expression": expr.tolist(),
            "umap_coordinates": umap_coords,
            "cell_types": adata.obs['CellType'].tolist() if 'CellType' in adata.obs else None
        }
        
    except Exception as e:
        logger.error(f"Error getting gene expression: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/subset-stats/{session_id}")
async def get_subset_stats(
    session_id: str,
    filter_column: str = Query(..., description="Column to filter by"),
    filter_value: str = Query(..., description="Value to include in filter")
):
    """Get stats for a subset of the dataset"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        # Check column exists
        if filter_column not in adata.obs.columns:
             raise HTTPException(status_code=400, detail=f"Filter column '{filter_column}' not found")
             
        subset = adata[adata.obs[filter_column] == filter_value]
        
        return {
            "n_cells": int(subset.n_obs),
            "n_genes": int(subset.n_vars)
        }
    except Exception as e:
        logger.error(f"Error calculating stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/filter/{session_id}")
async def filter_dataset(
    session_id: str,
    filter_column: str,
    filter_values: List[str]
):
    """Filter dataset by metadata column"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        if filter_column not in adata.obs.columns:
            raise HTTPException(
                status_code=400,
                detail=f"Column {filter_column} not found in metadata"
            )
        
        filtered_adata = dataset_service.filter_by_clusters(
            adata,
            filter_values,
            filter_column
        )
        
        # Store filtered dataset with new session ID
        filtered_session_id = f"{session_id}_filtered"
        current_dataset[filtered_session_id] = filtered_adata
        
        info = dataset_service.get_dataset_info(filtered_adata)
        
        return {
            "success": True,
            "session_id": filtered_session_id,
            "info": info
        }
        
    except Exception as e:
        logger.error(f"Error filtering dataset: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{session_id}")
async def unload_dataset(session_id: str):
    """Unload a dataset from memory"""
    if session_id in current_dataset:
        del current_dataset[session_id]
        return {"success": True, "message": "Dataset unloaded"}
    
    raise HTTPException(status_code=404, detail="Dataset not found")
