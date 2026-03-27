"""
API endpoints for enrichment analysis
"""
from fastapi import APIRouter, HTTPException, Body, Query
from pydantic import BaseModel
from typing import List, Dict
from loguru import logger

from app.core.models import EnrichmentRequest, OrganismType
from app.api.datasets import current_dataset
from app.services.enrichment_service import enrichment_service
from app.services.dataset_service import dataset_service

router = APIRouter()


class CustomGeneSetRequest(BaseModel):
    """Request for custom gene set enrichment"""
    geneset: Dict[str, List[str]]  # {"GeneSetName": ["GENE1", "GENE2", ...]}
    geneset_name: str = "Custom"


class DualGeneSetRequest(BaseModel):
    """Request for dual gene set comparison"""
    geneset1: Dict[str, List[str]]
    geneset2: Dict[str, List[str]]
    geneset1_name: str = "GeneSet1"
    geneset2_name: str = "GeneSet2"

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


@router.post("/custom-geneset/{session_id}")
async def custom_geneset_enrichment(
    session_id: str,
    request: CustomGeneSetRequest
):
    """
    Run custom gene set enrichment (ULM) on dataset
    
    Returns enrichment scores, UMAP, and violin plots
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Load full dataset
        try:
            org_part, ds_part = session_id.split("_", 1)
            adata = dataset_service.load_dataset(org_part, ds_part, size_option="full")
        except:
            adata = current_dataset[session_id]
        
        # Run enrichment
        scores_df, umap_img, violin_img = enrichment_service.run_custom_geneset_ulm(
            adata,
            request.geneset,
            request.geneset_name
        )
        
        return {
            "success": True,
            "geneset_name": request.geneset_name,
            "n_genesets": len(request.geneset),
            "n_cells": len(scores_df),
            "scores": scores_df.describe().to_dict(),
            "umap_image": umap_img,
            "violin_image": violin_img
        }
        
    except Exception as e:
        logger.error(f"Error in custom geneset enrichment: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/dual-geneset/{session_id}")
async def dual_geneset_comparison(
    session_id: str,
    request: DualGeneSetRequest
):
    """
    Compare two custom gene sets side by side
    
    Returns comparison scores and visualizations
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Load full dataset
        try:
            org_part, ds_part = session_id.split("_", 1)
            adata = dataset_service.load_dataset(org_part, ds_part, size_option="full")
        except:
            adata = current_dataset[session_id]
        
        # Run comparison
        scores_df, umap_img, violin_img = enrichment_service.run_dual_geneset_comparison(
            adata,
            request.geneset1,
            request.geneset2,
            request.geneset1_name,
            request.geneset2_name
        )
        
        return {
            "success": True,
            "geneset1_name": request.geneset1_name,
            "geneset2_name": request.geneset2_name,
            "n_cells": len(scores_df),
            "dual_umap_image": umap_img,
            "dual_violin_image": violin_img,
            "scores_summary": scores_df.describe().to_dict()
        }
        
    except Exception as e:
        logger.error(f"Error in dual geneset comparison: {e}")
        raise HTTPException(status_code=500, detail=str(e))
