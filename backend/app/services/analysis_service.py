"""
Analysis service for differential expression and correlations
"""
import scanpy as sc
import pandas as pd
import numpy as np
from scipy import stats
from typing import List, Dict, Any, Optional
from loguru import logger

from app.core.models import TestMethod, CorrelationMethod

class AnalysisService:
    """Service for gene expression analysis"""
    
    def differential_expression(
        self,
        adata: sc.AnnData,
        group1: str,
        group2: str,
        groupby: str = "CellType",
        method: TestMethod = TestMethod.WILCOXON,
        layer: str = "scvi_normalized"
    ) -> pd.DataFrame:
        """
        Perform differential gene expression analysis
        
        Args:
            adata: AnnData object
            group1: First group identifier
            group2: Second group identifier  
            groupby: Column to group by
            method: Statistical test method
            layer: Data layer to use
        
        Returns:
            DataFrame with DE results
        """
        logger.info(f"🧬 Running DE: {group1} vs {group2}")
        
        # Filter to only groups of interest (single copy, no intermediate full copy)
        mask = adata.obs[groupby].isin([group1, group2])
        adata_de = adata[mask].copy()
        
        # Set ident for comparison
        adata_de.obs['ident'] = adata_de.obs[groupby]
        
        # Run rank genes groups
        sc.tl.rank_genes_groups(
            adata_de,
            groupby='ident',
            groups=[group1],
            reference=group2,
            method=method.value,
            layer=layer,
            use_raw=False
        )
        
        # Extract results
        result_df = sc.get.rank_genes_groups_df(
            adata_de, 
            group=group1,
            key='rank_genes_groups'
        )
        
        return result_df

    def compute_marker_genes(
        self,
        adata: sc.AnnData,
        groupby: str = "CellType",
        method: str = "wilcoxon",
        n_genes: int = 100,
        layer: str = "scvi_normalized"
    ) -> List[Dict[str, Any]]:
        """
        Compute marker genes using rank_genes_groups (One vs Rest)
        
        Args:
            adata: AnnData object
            groupby: Column to group by
            method: Statistical test method
            n_genes: Number of top genes to return
            layer: Data layer to use

        Returns:
            List of dictionaries containing marker genes info
        """
        logger.info(f"🧬 Computing marker genes for groupby: {groupby}")
        
        # Check if groupby column exists
        if groupby not in adata.obs.columns:
            raise ValueError(f"Column '{groupby}' not found in observations")

        # Create a copy to be safe
        adata_markers = adata.copy()
        
        sc.tl.rank_genes_groups(
            adata_markers,
            groupby=groupby,
            method=method,
            layer=layer,
            use_raw=False
        )
        
        # Extract results for all groups
        dfs = []
        groups = adata_markers.obs[groupby].unique()
        
        for group in groups:
            try:
                df = sc.get.rank_genes_groups_df(adata_markers, group=group, key='rank_genes_groups')
                if df is not None:
                    df['cluster'] = group
                    df = df.head(n_genes)
                    dfs.append(df)
            except Exception as e:
                logger.warning(f"Could not extract markers for group {group}: {e}")

        if not dfs:
            return []

        result_df = pd.concat(dfs)
        
        # Rename for frontend consistency
        result_df = result_df.rename(columns={
            'names': 'gene',
            'scores': 'score',
            'logfoldchanges': 'avg_log2FC',
            'pvals_adj': 'p_val_adj'
        })
        
        # Filter infinite or NaN
        result_df = result_df.replace([np.inf, -np.inf], np.nan).dropna(subset=['avg_log2FC', 'p_val_adj'])

        return result_df.to_dict(orient='records')

    
    def gene_correlation(
        self,
        adata: sc.AnnData,
        gene1: str,
        gene2: str,
        method: CorrelationMethod = CorrelationMethod.SPEARMAN,
        layer: str = "scvi_normalized",
        remove_zeros: bool = False
    ) -> Dict[str, Any]:
        """
        Calculate correlation between two genes
        
        Args:
            adata: AnnData object
            gene1: First gene name
            gene2: Second gene name
            method: Correlation method
            layer: Data layer to use
            remove_zeros: Whether to remove zero values
        
        Returns:
            Dictionary with correlation results
        """
        logger.info(f"🔗 Calculating correlation: {gene1} vs {gene2}")
        
        # Get expression data
        if gene1 not in adata.var_names or gene2 not in adata.var_names:
            raise ValueError(f"Gene not found in dataset")
        
        if layer not in adata.layers:
            logger.warning(f"Layer '{layer}' not found, falling back to adata.X")
            import scipy.sparse as sp
            raw1 = adata[:, gene1].X
            raw2 = adata[:, gene2].X
            expr1 = (raw1.toarray().flatten() if sp.issparse(raw1) else np.asarray(raw1).flatten())
            expr2 = (raw2.toarray().flatten() if sp.issparse(raw2) else np.asarray(raw2).flatten())
        else:
            import scipy.sparse as sp
            raw1 = adata[:, gene1].layers[layer]
            raw2 = adata[:, gene2].layers[layer]
            expr1 = (raw1.toarray().flatten() if sp.issparse(raw1) else np.asarray(raw1).flatten())
            expr2 = (raw2.toarray().flatten() if sp.issparse(raw2) else np.asarray(raw2).flatten())
        
        # Remove zeros if requested
        if remove_zeros:
            mask = (expr1 > 0) & (expr2 > 0)
            expr1 = expr1[mask]
            expr2 = expr2[mask]
        
        # Calculate correlation
        if method == CorrelationMethod.SPEARMAN:
            corr, pval = stats.spearmanr(expr1, expr2)
        else:  # Pearson
            corr, pval = stats.pearsonr(expr1, expr2)
        
        return {
            "gene1": gene1,
            "gene2": gene2,
            "correlation": float(corr),
            "pvalue": float(pval),
            "method": method.value,
            "n_cells": len(expr1),
            "expr1": expr1.tolist(),
            "expr2": expr2.tolist()
        }
    
    def get_top_correlated_genes(
        self,
        adata: sc.AnnData,
        gene: str,
        n_top: int = 20,
        layer: str = "scvi_normalized"
    ) -> pd.DataFrame:
        """
        Find top correlated genes for a given gene
        
        Args:
            adata: AnnData object
            gene: Gene name
            n_top: Number of top genes to return
            layer: Data layer to use
        
        Returns:
            DataFrame with top correlated genes
        """
        if gene not in adata.var_names:
            raise ValueError(f"Gene {gene} not found")
        
        import scipy.sparse as sp
        if layer not in adata.layers:
            logger.warning(f"Layer '{layer}' not found in get_top_correlated_genes, falling back to adata.X")
            raw = adata[:, gene].X
            gene_expr = (raw.toarray().flatten() if sp.issparse(raw) else np.asarray(raw).flatten())
        else:
            raw = adata[:, gene].layers[layer]
            gene_expr = (raw.toarray().flatten() if sp.issparse(raw) else np.asarray(raw).flatten())
        
        # Limit to first 1000 genes for performance — covers most biologically relevant candidates
        correlations = []
        for other_gene in adata.var_names[:1000]:  # Limit for performance
            if other_gene == gene:
                continue
            
            raw_o = adata[:, other_gene].layers[layer] if layer in adata.layers else adata[:, other_gene].X
            other_expr = (raw_o.toarray().flatten() if sp.issparse(raw_o) else np.asarray(raw_o).flatten())
            corr, _ = stats.spearmanr(gene_expr, other_expr)
            correlations.append({
                "gene": other_gene,
                "correlation": corr
            })
        
        df = pd.DataFrame(correlations)
        df = df.sort_values("correlation", ascending=False)
        
        return df.head(n_top)

# Global instance
analysis_service = AnalysisService()
