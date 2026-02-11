"""
API endpoints for enrichment analysis
"""
from fastapi import APIRouter, HTTPException, Body, Query
from typing import List
from loguru import logger

from app.core.models import EnrichmentRequest, OrganismType
from app.api.datasets import current_dataset
from app.services.enrichment_service import enrichment_service
from app.services.dataset_service import dataset_service

router = APIRouter()

@router.post("/functional/{session_id}")
async def functional_enrichment(
    session_id: str,
    request: EnrichmentRequest
):
    """
    Perform functional enrichment analysis
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        results = enrichment_service.perform_enrichment(
            gene_list=request.gene_list,
            database=request.database,
            organism=request.organism
        )
        
        return {
            "success": True,
            "results": results,
            "database": request.database.value,
            "n_genes": len(request.gene_list)
        }
        
    except Exception as e:
        logger.error(f"Error in enrichment analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/pathway-activity/{session_id}")
async def pathway_activity(
    session_id: str,
    method: str = Query("collectri", description="Method/Network (collectri, progeny)"),
    organism: OrganismType = Query(OrganismType.HUMAN, description="Organism")
):
    """
    Calculate pathway activity scores (collectri or progeny)
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Load FULL dataset specifically for analysis (Dual Path)
        try:
             org_part, ds_part = session_id.split("_", 1)
             adata = dataset_service.load_dataset(org_part, ds_part, size_option="full")
        except:
             adata = current_dataset[session_id]
        
        # Calculate activity
        acts = enrichment_service.calculate_activity(
            adata=adata,
            organism=organism,
            net_name=method
        )
        
        # Currently we just return success message, as visualizing whole matrix is heavy.
        # Ideally we should store it in obsm and allow visualization via UMAP/Heatmap later.
        # Here we can return the top active pathways for top variable cells?
        
        # For now, let's return a success message and maybe top pathways
        
        return {
            "success": True,
            "message": f"Activity calculated for {method}",
            "shape": acts.shape
        }
        
    except Exception as e:
        logger.error(f"Error in pathway activity: {e}")
        raise HTTPException(status_code=500, detail=str(e))
