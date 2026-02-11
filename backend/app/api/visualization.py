"""
API endpoints for visualizations
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from loguru import logger

from app.services.visualization_service import visualization_service
from app.api.datasets import current_dataset

router = APIRouter()

@router.get("/umap/{session_id}")
async def generate_umap(
    session_id: str,
    color_by: str = Query("CellType", description="Column to color by")
):
    """Generate UMAP visualization"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        if color_by not in adata.obs.columns and color_by not in adata.var_names:
            raise HTTPException(
                status_code=400,
                detail=f"Column or gene '{color_by}' not found"
            )
        
        image = visualization_service.generate_umap(adata, color_by)
        
        return {
            "success": True,
            "image": image,
            "color_by": color_by
        }
        
    except Exception as e:
        logger.error(f"Error generating UMAP: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/violin/{session_id}")
async def generate_violin(
    session_id: str,
    genes: str = Query(..., description="Comma-separated gene names"),
    groupby: str = Query("CellType", description="Column to group by")
):
    """Generate violin plot"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        gene_list = [g.strip() for g in genes.split(',')]
        
        # Validate genes
        missing = [g for g in gene_list if g not in adata.var_names]
        if missing:
            raise HTTPException(
                status_code=404,
                detail=f"Genes not found: {', '.join(missing)}"
            )
        
        image = visualization_service.generate_violin_plot(
            adata,
            gene_list,
            groupby
        )
        
        return {
            "success": True,
            "image": image,
            "genes": gene_list
        }
        
    except Exception as e:
        logger.error(f"Error generating violin plot: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dotplot/{session_id}")
async def generate_dotplot(
    session_id: str,
    genes: str = Query(..., description="Comma-separated gene names"),
    groupby: str = Query("CellType", description="Column to group by")
):
    """Generate DotPlot"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        gene_list = [g.strip() for g in genes.split(',')]
        
        # Validate genes
        missing = [g for g in gene_list if g not in adata.var_names]
        if missing:
            raise HTTPException(
                status_code=404,
                detail=f"Genes not found: {', '.join(missing)}"
            )
        
        image = visualization_service.generate_dotplot(
            adata,
            gene_list,
            groupby
        )
        
        return {
            "success": True,
            "image": image,
            "genes": gene_list
        }
        
    except Exception as e:
        logger.error(f"Error generating dotplot: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/correlation-scatter/{session_id}")
async def correlation_scatter(
    session_id: str,
    gene1: str,
    gene2: str,
    correlation: float,
    pvalue: float
):
    """Generate correlation scatter plot"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        # Get expression data
        expr1 = adata[:, gene1].layers['scvi_normalized'].toarray().flatten().tolist()
        expr2 = adata[:, gene2].layers['scvi_normalized'].toarray().flatten().tolist()
        
        image = visualization_service.generate_scatter_correlation(
            expr1, expr2, gene1, gene2, correlation, pvalue
        )
        
        return {
            "success": True,
            "image": image
        }
        
    except Exception as e:
        logger.error(f"Error generating scatter plot: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/volcano")
async def volcano_plot(
    dge_results: dict,
    logfc_threshold: float = 0.5,
    pval_threshold: float = 0.05
):
    """Generate volcano plot from DGE results"""
    try:
        image = visualization_service.generate_volcano_plot(
            dge_results.get('results', []),
            logfc_threshold,
            pval_threshold
        )
        
        return {
            "success": True,
            "image": image
        }
        
    except Exception as e:
        logger.error(f"Error generating volcano plot: {e}")
        raise HTTPException(status_code=500, detail=str(e))
