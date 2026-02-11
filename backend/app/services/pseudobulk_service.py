"""
Service for Pseudo-bulk analysis using PyDESeq2
"""
import scanpy as sc
import pandas as pd
import numpy as np
from pydeseq2.dds import DeseqDataSet
from pydeseq2.ds import DeseqStats
from loguru import logger
from typing import List, Dict, Any, Optional

class PseudobulkService:
    def aggregate_counts(
        self, 
        adata: sc.AnnData, 
        sample_col: str, 
        group_col: str,
        layer: str = "counts"
    ) -> tuple[pd.DataFrame, pd.DataFrame]:
        """
        Aggregate single-cell counts into pseudo-bulk samples.
        
        Args:
            adata: AnnData object
            sample_col: Column distinguishing biological replicates (e.g. 'SampleID')
            group_col: Column to include in metadata (e.g. 'Condition')
        
        Returns:
            counts_df: DataFrame (samples x genes)
            metadata_df: DataFrame (samples x metadata)
        """
        logger.info(f"Aggregating counts by {sample_col}")
        
        # Check columns exist
        if sample_col not in adata.obs.columns:
            raise ValueError(f"Sample column {sample_col} not found")
        if group_col and group_col not in adata.obs.columns:
             raise ValueError(f"Group column {group_col} not found")
            
        # Get unique samples
        samples = adata.obs[sample_col].unique()
        
        counts_list = []
        meta_list = []
        
        valid_samples = []

        for sample in samples:
            mask = adata.obs[sample_col] == sample
            subset = adata[mask]
            
            if subset.n_obs == 0:
                continue
                
            # Get counts
            # Try to find raw counts
            X = None
            if layer in subset.layers:
                X = subset.layers[layer]
            elif subset.raw:
                try:
                    X = subset.raw.X
                except:
                    X = subset.X
            else:
                X = subset.X 
            
            # Sum
            if hasattr(X, "sum"):
                summed = X.sum(axis=0)
                if hasattr(summed, "A1"): 
                    summed = summed.A1
                elif hasattr(summed, "toarray"):
                    summed = summed.toarray().flatten()
                else: 
                     # Sometime it returns matrix type
                     summed = np.asarray(summed).flatten()
            else:
                summed = np.sum(X, axis=0)
                
            # Ensure 1D array
            if len(summed.shape) > 1:
                summed = summed.flatten()
                
            counts_list.append(summed)
            
            # Metadata
            # Assume sample-level metadata is constant per sample. Take mode or first.
            meta_row = {}
            meta_row[sample_col] = sample
            if group_col:
                meta_row[group_col] = subset.obs[group_col].iloc[0]
            
            meta_list.append(meta_row)
            valid_samples.append(sample)
            
        if not counts_list:
            raise ValueError("No samples found or empty aggregation")
            
        counts_df = pd.DataFrame(counts_list, index=valid_samples, columns=adata.var_names)
        metadata_df = pd.DataFrame(meta_list, index=valid_samples)
        
        return counts_df, metadata_df

    def run_deseq2(
        self,
        counts_df: pd.DataFrame,
        metadata_df: pd.DataFrame,
        design_factor: str,
        contrast: Optional[List[str]] = None
    ) -> pd.DataFrame:
        """
        Run DESeq2 analysis
        
        Args:
            counts_df: Aggregated counts (Samples x Genes)
            metadata_df: Metadata (Samples x Covariates)
            design_factor: Column in metadata to test (e.g. 'Condition')
            contrast: List [factor, tested_level, ref_level] e.g. ["Condition", "Disease", "Healthy"]
        """
        logger.info(f"Running DESeq2 with design ~{design_factor}")
        
        # Ensure integer counts
        counts_df = counts_df.round().astype(int)
        
        # Remove genes with 0 counts everywhere
        counts_df = counts_df.loc[:, (counts_df != 0).any(axis=0)]
        
        # Create DDS
        # Quiet mode to reduce logs
        dds = DeseqDataSet(
            counts=counts_df,
            metadata=metadata_df,
            design_factors=design_factor,
            refit_cooks=True, 
            n_cpus=1,
            quiet=True
        )
        
        # Run DESeq2
        dds.deseq2()
        
        # Run Stats
        stat_res = DeseqStats(dds, contrast=contrast, n_cpus=1, quiet=True)
        stat_res.summary()
        
        res_df = stat_res.results_df
        
        # Add gene symbols if they are index
        res_df['Gene'] = res_df.index
        
        # Sort by p-adj
        res_df = res_df.sort_values('padj')
        
        return res_df

pseudobulk_service = PseudobulkService()
