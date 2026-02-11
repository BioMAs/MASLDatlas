"""
API endpoints for analysis operations
"""
from fastapi import APIRouter, HTTPException
from loguru import logger

from app.core.models import (
    DifferentialExpressionRequest,
    MarkerGeneRequest,
    CorrelationRequest,
    DGEResult
)
from app.services.analysis_service import analysis_service
from app.api.datasets import current_dataset
from app.services.dataset_service import dataset_service

router = APIRouter()

@router.post("/differential-expression/{session_id}")
async def differential_expression(
    session_id: str,
    request: DifferentialExpressionRequest
):
    """Perform differential gene expression analysis"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Load FULL dataset specifically for analysis (Dual Path)
        try:
             organism, dataset_name = session_id.split("_", 1)
             adata = dataset_service.load_dataset(organism, dataset_name, size_option="full")
        except:
             adata = current_dataset[session_id]
        
        result = analysis_service.differential_expression(
            adata,
            request.group1,
            request.group2,
            request.groupby,
            request.method
        )
        
        # Filter results
        result = result[
            (abs(result['logfoldchanges']) >= request.min_logfc) &
            (result['pvals_adj'] <= request.max_pval)
        ]
        
        return {
            "success": True,
            "n_genes": len(result),
            "results": result.to_dict(orient='records')
        }
        
    except Exception as e:
        logger.error(f"Error in differential expression: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/markers/{session_id}")
async def marker_genes(
    session_id: str,
    request: MarkerGeneRequest
):
    """Compute marker genes for all groups in a groupby category"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Try to load full dataset if possible or fallback to cached
        try:
             organism, dataset_name = session_id.split("_", 1)
             adata = dataset_service.load_dataset(organism, dataset_name, size_option="full")
        except:
             adata = current_dataset[session_id]
        
        results = analysis_service.compute_marker_genes(
            adata,
            groupby=request.groupby,
            method=request.method.value,
            n_genes=request.n_genes
        )
        
        return results
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error in marker gene analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/correlation/{session_id}")
async def gene_correlation(
    session_id: str,
    request: CorrelationRequest
):
    """Calculate correlation between two genes"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        result = analysis_service.gene_correlation(
            adata,
            request.gene1,
            request.gene2,
            request.method,
            remove_zeros=request.remove_zeros
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error in correlation analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/top-correlated/{session_id}/{gene}")
async def top_correlated_genes(
    session_id: str,
    gene: str,
    n_top: int = 20
):
    """Get top correlated genes"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        result = analysis_service.get_top_correlated_genes(
            adata,
            gene,
            n_top
        )
        
        return {
            "gene": gene,
            "top_genes": result.to_dict(orient='records')
        }
        
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error finding top correlated genes: {e}")
        raise HTTPException(status_code=500, detail=str(e))
