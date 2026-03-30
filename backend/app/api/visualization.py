"""
API endpoints for visualizations
"""
import hashlib
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from loguru import logger

from app.services.visualization_service import visualization_service
from app.api.datasets import current_dataset
from app.services.cache_service import get_cache_service

router = APIRouter()


# ── Client-side data endpoints ──────────────────────────────────────────────

@router.get("/umap-data/{session_id}")
async def get_umap_data(
    session_id: str,
    color_by: str = Query("CellType", description="Column or gene to colour by"),
    filter_column: Optional[str] = Query(None),
    filter_values: Optional[List[str]] = Query(None),
):
    """Return raw UMAP coordinates for client-side Plotly rendering."""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")

    cache = get_cache_service()
    parts = f"umap-data:{session_id}:{color_by}:{filter_column}:{sorted(filter_values or [])}"
    cache_key = hashlib.sha256(parts.encode()).hexdigest()[:20]
    cached = cache.get_result(cache_key)
    if cached is not None:
        return cached

    try:
        adata = current_dataset[session_id]
        if filter_column and filter_values:
            if filter_column not in adata.obs.columns:
                raise HTTPException(status_code=400, detail=f"Filter column '{filter_column}' not found")
            adata = adata[adata.obs[filter_column].isin(filter_values)]

        result = {"success": True, **visualization_service.extract_umap_data(adata, color_by)}
        cache.set_result(cache_key, result)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error extracting UMAP data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/violin-data/{session_id}")
async def get_violin_data(
    session_id: str,
    genes: str = Query(..., description="Comma-separated gene names"),
    groupby: str = Query("CellType"),
    filter_column: Optional[str] = Query(None),
    filter_values: Optional[List[str]] = Query(None),
):
    """Return per-cell expression per group for client-side Plotly violin."""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")

    gene_list = [g.strip() for g in genes.split(',')]

    cache = get_cache_service()
    parts = f"violin-data:{session_id}:{','.join(sorted(gene_list))}:{groupby}:{filter_column}:{sorted(filter_values or [])}"
    cache_key = hashlib.sha256(parts.encode()).hexdigest()[:20]
    cached = cache.get_result(cache_key)
    if cached is not None:
        return cached

    try:
        adata = current_dataset[session_id]
        if filter_column and filter_values:
            if filter_column not in adata.obs.columns:
                raise HTTPException(status_code=400, detail=f"Filter column '{filter_column}' not found")
            adata = adata[adata.obs[filter_column].isin(filter_values)]
            if groupby in adata.obs and hasattr(adata.obs[groupby], 'cat'):
                adata.obs[groupby] = adata.obs[groupby].cat.remove_unused_categories()

        var_names_set = set(adata.var_names)
        var_names_lower = None
        final_genes = []
        for g in gene_list:
            if g in var_names_set:
                final_genes.append(g)
            else:
                if var_names_lower is None:
                    var_names_lower = {n.lower(): n for n in adata.var_names}
                canonical = var_names_lower.get(g.lower())
                if canonical:
                    final_genes.append(canonical)
                else:
                    raise HTTPException(status_code=404, detail=f"Gene not found: {g}")

        result = {"success": True, **visualization_service.extract_violin_data(adata, final_genes, groupby)}
        cache.set_result(cache_key, result)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error extracting violin data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/dotplot-data/{session_id}")
async def get_dotplot_data(
    session_id: str,
    genes: str = Query(..., description="Comma-separated gene names"),
    groupby: str = Query("CellType"),
    filter_column: Optional[str] = Query(None),
    filter_values: Optional[List[str]] = Query(None),
):
    """Return mean expression + fraction expressing for client-side Plotly dot plot."""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")

    gene_list = [g.strip() for g in genes.split(',')]

    cache = get_cache_service()
    parts = f"dotplot-data:{session_id}:{','.join(sorted(gene_list))}:{groupby}:{filter_column}:{sorted(filter_values or [])}"
    cache_key = hashlib.sha256(parts.encode()).hexdigest()[:20]
    cached = cache.get_result(cache_key)
    if cached is not None:
        return cached

    try:
        adata = current_dataset[session_id]
        if filter_column and filter_values:
            if filter_column not in adata.obs.columns:
                raise HTTPException(status_code=400, detail=f"Filter column '{filter_column}' not found")
            adata = adata[adata.obs[filter_column].isin(filter_values)]

        missing = [g for g in gene_list if g not in adata.var_names]
        if missing:
            raise HTTPException(status_code=404, detail=f"Genes not found: {', '.join(missing)}")

        result = {"success": True, **visualization_service.extract_dotplot_data(adata, gene_list, groupby)}
        cache.set_result(cache_key, result)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error extracting dotplot data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def generate_umap(
    session_id: str,
    color_by: str = Query("CellType", description="Column to color by"),
    filter_column: Optional[str] = Query(None, description="Column to filter by"),
    filter_values: Optional[List[str]] = Query(None, description="Values to include in filter")
):
    """Generate UMAP visualization"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        # Apply filter if provided
        if filter_column and filter_values:
            if filter_column not in adata.obs.columns:
                 raise HTTPException(status_code=400, detail=f"Filter column '{filter_column}' not found")
            adata = adata[adata.obs[filter_column].isin(filter_values)]
        
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
    groupby: str = Query("CellType", description="Column to group by"),
    filter_column: Optional[str] = Query(None, description="Column to filter by"),
    filter_values: Optional[List[str]] = Query(None, description="Values to include in filter")
):
    """Generate violin plot"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        # Apply filter if provided
        if filter_column and filter_values:
            if filter_column not in adata.obs.columns:
                 raise HTTPException(status_code=400, detail=f"Filter column '{filter_column}' not found")
            adata = adata[adata.obs[filter_column].isin(filter_values)].copy()

            # Fix for unused categories showing up in plots
            if groupby in adata.obs and hasattr(adata.obs[groupby], 'cat'):
                 adata.obs[groupby] = adata.obs[groupby].cat.remove_unused_categories()
            
        gene_list = [g.strip() for g in genes.split(',')]
        
        # Validate genes and handle case sensitivity
        var_names_set = set(adata.var_names)
        final_gene_list = []
        missing = []
        
        # Lazy loading of case-insensitive map
        var_names_lower = None

        for g in gene_list:
            if g in var_names_set:
                final_gene_list.append(g)
            else:
                # Try case-insensitive match
                if var_names_lower is None:
                     var_names_lower = {name.lower(): name for name in adata.var_names}
                
                if g.lower() in var_names_lower:
                    final_gene_list.append(var_names_lower[g.lower()])
                else:
                    missing.append(g)

        if missing:
            raise HTTPException(
                status_code=404,
                detail=f"Genes not found: {', '.join(missing)}"
            )
        
        image = visualization_service.generate_violin_plot(
            adata,
            final_gene_list,
            groupby
        )
        
        return {
            "success": True,
            "image": image,
            "genes": final_gene_list
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating violin plot: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dotplot/{session_id}")
async def generate_dotplot(
    session_id: str,
    genes: str = Query(..., description="Comma-separated gene names"),
    groupby: str = Query("CellType", description="Column to group by"),
    filter_column: Optional[str] = Query(None, description="Column to filter by"),
    filter_values: Optional[List[str]] = Query(None, description="Values to include in filter")
):
    """Generate DotPlot"""
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        # Apply filter if provided
        if filter_column and filter_values:
            if filter_column not in adata.obs.columns:
                 raise HTTPException(status_code=400, detail=f"Filter column '{filter_column}' not found")
            adata = adata[adata.obs[filter_column].isin(filter_values)].copy()

            # Fix for unused categories showing up in plots
            if groupby in adata.obs and hasattr(adata.obs[groupby], 'cat'):
                 adata.obs[groupby] = adata.obs[groupby].cat.remove_unused_categories()
            
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


@router.get("/rank-genes-groups/{session_id}")
async def rank_genes_groups_plot(
    session_id: str,
    n_genes: int = 20,
    group: Optional[str] = Query(None, description="Specific group/cluster to visualize (equivalent to legacy imageoutput_CellType_groups)"),
    groupby: str = Query("CellType", description="Grouping variable used to compute rank_genes_groups")
):
    """
    Generate rank genes groups visualization.
    Shows top marker genes per group as ranked plot.
    If 'group' is provided, only shows that cluster's panel (legacy imageoutput_CellType_groups behaviour).
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        import scanpy as sc

        # Recompute if groupby changed or results not yet computed
        current_groupby = adata.uns.get('rank_genes_groups', {}).get('params', {}).get('groupby')
        if 'rank_genes_groups' not in adata.uns or current_groupby != groupby:
            logger.info(f"Computing rank_genes_groups with groupby='{groupby}'...")
            sc.tl.rank_genes_groups(adata, groupby, method='wilcoxon')

        groups_filter = [group] if group else None

        image = visualization_service.generate_rank_genes_groups_plot(
            adata,
            n_genes=n_genes,
            groupby=groupby,
            groups=groups_filter
        )
        
        return {
            "success": True,
            "image": image,
            "group": group,
            "groupby": groupby
        }
        
    except Exception as e:
        logger.error(f"Error generating rank genes groups plot: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/rank-genes-dotplot/{session_id}")
async def rank_genes_dotplot(
    session_id: str,
    n_genes: int = 10
):
    """
    Generate dotplot of top marker genes
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        if 'rank_genes_groups' not in adata.uns:
            import scanpy as sc
            sc.tl.rank_genes_groups(adata, 'CellType', method='wilcoxon')
        
        image = visualization_service.generate_rank_genes_groups_dotplot(
            adata,
            n_genes=n_genes
        )
        
        return {
            "success": True,
            "image": image
        }
        
    except Exception as e:
        logger.error(f"Error generating dotplot: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/violin-gene/{session_id}/{gene}")
async def violin_gene_plot(
    session_id: str,
    gene: str,
    groupby: str = "CellType",
    splitby: Optional[str] = None
):
    """
    Generate violin plot for a specific gene
    Interactive selection from DGE table
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        adata = current_dataset[session_id]
        
        image = visualization_service.generate_interactive_violin(
            adata,
            gene=gene,
            groupby=groupby,
            splitby=splitby
        )
        
        return {
            "success": True,
            "gene": gene,
            "image": image
        }
        
    except Exception as e:
        logger.error(f"Error generating violin plot for {gene}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
