from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from loguru import logger
import pandas as pd
import numpy as np
import io
import base64
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

from app.api.datasets import current_dataset
from app.services.dataset_service import dataset_service
from app.services.pseudobulk_service import pseudobulk_service

router = APIRouter()


def _compute_pca_image(counts_df: pd.DataFrame, metadata_df: pd.DataFrame, condition_col: str) -> Optional[str]:
    """Compute PCA on pseudo-bulk counts and return base64 PNG."""
    try:
        X = np.log1p(counts_df.values.astype(float))
        X = X - X.mean(axis=0)
        std = X.std(axis=0)
        mask_var = std > 0
        if mask_var.sum() == 0:
            return None
        X = X[:, mask_var] / std[mask_var]

        n_components = min(2, X.shape[0] - 1, X.shape[1])
        if n_components < 2:
            return None

        U, S, _ = np.linalg.svd(X, full_matrices=False)
        scores = U[:, :2] * S[:2]
        var_exp = (S[:2] ** 2) / (S ** 2).sum() * 100

        conditions = metadata_df[condition_col].values
        unique_conds = np.unique(conditions)
        cmap = plt.cm.Set2(np.linspace(0, 1, len(unique_conds)))

        fig, ax = plt.subplots(figsize=(7, 6))
        for cond, color in zip(unique_conds, cmap):
            m = conditions == cond
            ax.scatter(scores[m, 0], scores[m, 1], label=str(cond), color=color,
                       s=120, edgecolors='white', linewidth=0.8, zorder=3)

        for i, sample in enumerate(counts_df.index):
            ax.annotate(str(sample), (scores[i, 0], scores[i, 1]),
                        fontsize=7, ha='center', va='bottom', color='#444444')

        ax.set_xlabel(f'PC1 ({var_exp[0]:.1f}% variance)', fontsize=11)
        ax.set_ylabel(f'PC2 ({var_exp[1]:.1f}% variance)', fontsize=11)
        ax.set_title('PCA — Pseudo-bulk Samples', fontsize=13, fontweight='bold')
        ax.legend(title=condition_col, bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=9)
        ax.grid(True, alpha=0.25, linestyle='--')
        ax.set_facecolor('#fafafa')
        plt.tight_layout()

        buf = io.BytesIO()
        fig.savefig(buf, format='png', bbox_inches='tight', dpi=150)
        buf.seek(0)
        img_b64 = base64.b64encode(buf.read()).decode('utf-8')
        plt.close(fig)
        return f"data:image/png;base64,{img_b64}"
    except Exception as e:
        logger.warning(f"PCA plot failed (non-blocking): {e}")
        return None

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
        
        # Compute PCA image (non-blocking)
        pca_image = _compute_pca_image(counts, meta, request.condition_col)

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
            "contrast": f"{request.target_level} vs {request.reference_level}",
            "pca_image": pca_image
        }
        
    except Exception as e:
        logger.error(f"Error in pseudobulk: {e}")
        # Print full stack trace in logs if possible, but here just str(e)
        import traceback
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))
