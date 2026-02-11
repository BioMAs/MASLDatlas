from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from loguru import logger
import pandas as pd
import numpy as np

from app.api.datasets import current_dataset
from app.services.dataset_service import dataset_service
from app.services.pseudobulk_service import pseudobulk_service

router = APIRouter()

class PseudobulkRequest(BaseModel):
    sample_col: str = "Sample" # Column identifying replicates
    condition_col: str = "Condition" # Column to test
    reference_level: str # e.g. "Healthy" (Reference/Control)
    target_level: str # e.g. "Disease" (Target/Case)
    cell_type_col: Optional[str] = "CellType"
    cell_type: Optional[str] = None # Specific cell type to filter for

@router.post("/run/{session_id}")
async def run_pseudobulk(
    session_id: str,
    request: PseudobulkRequest
):
    """
    Run Pseudo-bulk DE analysis using DESeq2
    """
    if session_id not in current_dataset:
        raise HTTPException(status_code=404, detail="Dataset not loaded")
    
    try:
        # Load FULL dataset specifically for analysis (Dual Path Optimization)
        try:
            organism, dataset_name = session_id.split("_", 1)
            adata = dataset_service.load_dataset(organism, dataset_name, size_option="full")
        except Exception as e:
            logger.warning(f"Using cached dataset due to error loading full: {e}")
            adata = current_dataset[session_id]

        # Filter by cell type if specified
        if request.cell_type and request.cell_type_col:
            if request.cell_type_col not in adata.obs:
                raise HTTPException(status_code=400, detail=f"Column {request.cell_type_col} not found")
                
            subset = adata[adata.obs[request.cell_type_col] == request.cell_type].copy()
            if subset.n_obs == 0:
                 raise HTTPException(status_code=400, detail=f"No cells found for {request.cell_type}")
        else:
            subset = adata
            
        # Validate columns
        if request.sample_col not in subset.obs:
            raise HTTPException(status_code=400, detail=f"Column {request.sample_col} not found. Available: {list(subset.obs.columns)}")
        if request.condition_col not in subset.obs:
            raise HTTPException(status_code=400, detail=f"Column {request.condition_col} not found")
            
        # Aggregate
        counts, meta = pseudobulk_service.aggregate_counts(
            subset,
            sample_col=request.sample_col,
            group_col=request.condition_col
        )
        
        # Check sufficiency
        # We need at least 2 samples?
        if len(counts) < 2:
             raise HTTPException(status_code=400, detail=f"Not enough samples ({len(counts)}) for analysis")
             
        # Run DESeq2
        # Contrast format: [variable, target, reference]
        contrast = [request.condition_col, request.target_level, request.reference_level]
        
        res = pseudobulk_service.run_deseq2(
            counts_df=counts,
            metadata_df=meta,
            design_factor=request.condition_col,
            contrast=contrast
        )
        
        # Convert results to JSON friendly list
        # res has index=Gene, and columns like baseMean, log2FoldChange, lfcSE, stat, pvalue, padj
        
        # Replace NaNs with None/null for JSON
        res = res.where(pd.notnull(res), None)
        
        results_list = []
        for gene, row in res.iterrows():
            results_list.append({
                "gene": str(gene),
                "baseMean": row.get('baseMean'),
                "log2FoldChange": row.get('log2FoldChange'),
                "lfcSE": row.get('lfcSE'),
                "stat": row.get('stat'),
                "pvalue": row.get('pvalue'),
                "padj": row.get('padj')
            })
            
        return {
            "success": True,
            "results": results_list,
            "sample_count": len(counts),
            "design": f"~{request.condition_col}",
            "contrast": f"{request.target_level} vs {request.reference_level}"
        }
        
    except Exception as e:
        logger.error(f"Error in pseudobulk: {e}")
        # Print full stack trace in logs if possible, but here just str(e)
        import traceback
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))
