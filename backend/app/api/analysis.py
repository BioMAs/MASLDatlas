"""
API endpoints for analysis operations
"""
from fastapi import APIRouter, HTTPException
from loguru import logger
from typing import Optional, List

from app.core.models import (
    DifferentialExpressionRequest,
    MarkerGeneRequest,
    CorrelationRequest,
    DGEResult
)
from app.services.analysis_service import analysis_service
from app.api.datasets import current_dataset
from app.services.dataset_service import dataset_service
from app.services.cache_service import get_cache_service

router = APIRouter()

@router.post(
    "/differential-expression/{session_id}",
    summary="Differential gene expression (Scanpy rank_genes_groups)",
    responses={
        200: {"description": "DEG table with logFC, p-values and Scanpy scores."},
        404: {"description": "Session not found — load a dataset first."},
        500: {"description": "Analysis error (check group names)."},
    },
)
async def differential_expression(
    session_id: str,
    request: DifferentialExpressionRequest
):
    """
    Run **differential gene expression** analysis between two cell groups
    using Scanpy's `rank_genes_groups`.

    **Methods available:**
    - `wilcoxon` — Wilcoxon rank-sum test (default, non-parametric, robust)
    - `t-test` — Welch's t-test (faster, assumes normality)
    - `logreg` — logistic regression (multi-class capable)

    **groupby** can be any categorical metadata column (e.g. `CellType`, `condition`).
    `group1` is the **reference** group; `group2` is the **target** (numerator in log2FC).

    Results are filtered by `min_logfc` and `max_pval` before returning.
    The full dataset (not the filtered session) is always used for statistical accuracy.

    Returns a list of records with fields:
    `names`, `logfoldchanges`, `pvals`, `pvals_adj`, `scores`.
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Load FULL dataset specifically for analysis (Dual Path)
        try:
             organism, dataset_name = session_id.split("_", 1)
             adata = dataset_service.load_dataset(organism, dataset_name, size_option="full")
        except:
             adata = current_dataset[session_id]

        # Check cache before computing
        import hashlib as _hashlib
        cache_service = get_cache_service()
        _cache_parts = f"dge:{session_id}:{request.group1}:{request.group2}:{request.groupby}:{request.method}:{request.min_logfc}:{request.max_pval}"
        _cache_key = _hashlib.sha256(_cache_parts.encode()).hexdigest()[:20]
        _cached = cache_service.get_result(_cache_key)
        if _cached is not None:
            logger.info(f"DEG cache HIT: {_cache_key}")
            return _cached
        
        result = analysis_service.differential_expression(
            adata,
            request.group1,
            request.group2,
            request.groupby,
            request.method
            # layer defaults to 'scvi_normalized'; override here if needed
        )
        
        # Filter results
        result = result[
            (abs(result['logfoldchanges']) >= request.min_logfc) &
            (result['pvals_adj'] <= request.max_pval)
        ]
        
        response = {
            "success": True,
            "n_genes": len(result),
            "results": result.to_dict(orient='records')
        }
        cache_service.set_result(_cache_key, response)
        return response
        
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

@router.post(
    "/filter-by-clusters/{session_id}",
    summary="Filter dataset by cluster selection (cached)",
    responses={
        200: {"description": "Filtered dataset info + cache status."},
        400: {"description": "Invalid cluster names."},
        404: {"description": "Session not found."},
    },
)
async def filter_by_clusters(
    session_id: str,
    clusters: List[str],
    cluster_column: str = "CellType"
):
    """
    Filter the active dataset to retain only cells belonging to the specified
    `clusters` in `cluster_column`.

    The filtered `AnnData` is **stored in the server-side in-memory cache** (TTL 1 h)
    so that subsequent DGE / marker-gene calls can reuse it without re-filtering.
    On cache hit the operation is near-instantaneous.

    **Typical use-case**: the user selects a subset of cell-types in the UI
    before running DGE, reducing computation time and noise.

    Returns original vs filtered cell counts and the updated dataset metadata.
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Extract organism and dataset from session_id
        organism, dataset_name = session_id.split("_", 1)
        
        # Check cache first
        cache_service = get_cache_service()
        cached_filtered = cache_service.get_filtered_dataset(
            organism=organism,
            dataset=dataset_name,
            clusters=clusters
        )
        
        if cached_filtered is not None:
            logger.info(f"✅ Using cached filtered dataset")
            filtered_adata = cached_filtered
        else:
            # Load full dataset and filter
            adata = dataset_service.load_dataset(organism, dataset_name, size_option="full")
            filtered_adata = dataset_service.filter_by_clusters(
                adata, 
                clusters, 
                cluster_column
            )
            
            # Cache the filtered dataset
            filter_key = cache_service.set_filtered_dataset(
                filtered_adata,
                organism=organism,
                dataset=dataset_name,
                clusters=clusters
            )
            logger.info(f"💾 Cached new filtered dataset with key: {filter_key}")
        
        # Return dataset info
        info = dataset_service.get_dataset_info(filtered_adata)
        
        return {
            "success": True,
            "n_cells_original": current_dataset[session_id].n_obs,
            "n_cells_filtered": filtered_adata.n_obs,
            "n_clusters_selected": len(clusters),
            "clusters_selected": clusters,
            "dataset_info": info
        }
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error filtering by clusters: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get(
    "/cache/stats",
    summary="Cache statistics (filtered datasets + Redis results)",
)
async def get_cache_stats():
    """
    Returns hit/miss counters and memory usage for both cache layers:

    - **filtered_datasets** — in-process TTLCache storing `AnnData` objects
    - **results** — Redis cache (or in-memory fallback) for analysis result objects

    Useful to monitor server-side cache health without accessing the host directly.
    """
    cache_service = get_cache_service()
    return cache_service.get_cache_stats()
