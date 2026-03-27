"""
Visualization service for generating plots
"""
import scanpy as sc
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import io
import base64
from typing import Optional, List, Dict, Any
from loguru import logger

class VisualizationService:
    """Service for generating visualizations"""
    
    def __init__(self):
        # Set scanpy figure parameters
        sc.set_figure_params(
            dpi=150,
            dpi_save=300,
            format='png',
            figsize=(10, 8),
            fontsize=12,
            facecolor='white'
        )
    
    def generate_umap(
        self,
        adata: sc.AnnData,
        color_by: str = "CellType",
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate UMAP plot
        
        Args:
            adata: AnnData object
            color_by: Column to color by
            return_base64: Whether to return base64 encoded image
        
        Returns:
            Base64 encoded image or None
        """
        logger.info(f"🎨 Generating UMAP colored by {color_by}")
        
        if 'X_umap' not in adata.obsm:
            logger.warning("UMAP coordinates not found, computing...")
            sc.tl.umap(adata)
        
        fig, ax = plt.subplots(figsize=(10, 8))
        sc.pl.umap(adata, color=color_by, ax=ax, show=False)
        
        if return_base64:
            return self._fig_to_base64(fig)
        
        plt.close(fig)
        return None
    
    def generate_violin_plot(
        self,
        adata: sc.AnnData,
        genes: List[str],
        groupby: str = "CellType",
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate violin plot for gene expression
        
        Args:
            adata: AnnData object
            genes: List of genes to plot
            groupby: Column to group by
            return_base64: Whether to return base64 encoded image
        
        Returns:
            Base64 encoded image or None
        """
        logger.info(f"🎻 Generating violin plot for {len(genes)} genes")
        
        # Calculate dynamic figure size
        num_genes = len(genes)
        width = max(8, num_genes * 4)
        height = 6
        
        # Close any existing figures
        plt.close('all')
        
        if num_genes > 1:
            # For multiple genes, sc.pl.violin manages figure creation (one axes per gene)
            # using 'ax' argument is not supported for multiple keys
            with plt.rc_context({'figure.figsize': (width, height)}):
                sc.pl.violin(
                    adata, 
                    keys=genes, 
                    groupby=groupby,
                    rotation=90,
                    show=False
                )
            fig = plt.gcf()
        else:
            # For single gene, we create the figure control explicitly
            fig, ax = plt.subplots(figsize=(width, height))
            sc.pl.violin(
                adata, 
                keys=genes, 
                groupby=groupby,
                rotation=90,
                ax=ax,
                show=False
            )
        
        if return_base64:
            return self._fig_to_base64(fig)
        
        plt.close(fig)
        return None

    def generate_dotplot(
        self,
        adata: sc.AnnData,
        genes: List[str],
        groupby: str = "CellType",
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate DotPlot for gene expression
        
        Args:
            adata: AnnData object
            genes: List of genes to plot
            groupby: Column to group by
            return_base64: Whether to return base64 encoded image
        
        Returns:
            Base64 encoded image or None
        """
        logger.info(f"🔵 Generating dotplot for {len(genes)} genes")
        
        # Calculate figure size dynamically
        width = max(6, len(genes) * 0.4 + 2)
        unique_groups = len(adata.obs[groupby].unique())
        height = max(5, unique_groups * 0.3 + 1)
        
        # Scanpy's dotplot creates its own figure/ax structure, so we use scanpy's way slightly differently
        # sc.pl.dotplot returns a Dict of axes usually, but we can pass return_fig=True
        
        dp = sc.pl.dotplot(
            adata, 
            var_names=genes, 
            groupby=groupby,
            show=False,
            cmap='Reds',
            standard_scale='var',
            return_fig=True,
            figsize=(width, height)
        )
        
        # In scanpy, dp is a DotPlot object which has a figure attribute
        fig = dp.figure
        
        if return_base64:
            return self._fig_to_base64(fig)
        
        plt.close(fig)
        return None
    
    def generate_scatter_correlation(
        self,
        expr1: List[float],
        expr2: List[float],
        gene1: str,
        gene2: str,
        correlation: float,
        pvalue: float,
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate scatter plot for gene correlation
        
        Args:
            expr1: Expression values for gene 1
            expr2: Expression values for gene 2
            gene1: Name of gene 1
            gene2: Name of gene 2
            correlation: Correlation coefficient
            pvalue: P-value
            return_base64: Whether to return base64 encoded image
        
        Returns:
            Base64 encoded image or None
        """
        logger.info(f"📊 Generating correlation scatter plot")
        
        fig, ax = plt.subplots(figsize=(8, 8))
        
        ax.scatter(expr1, expr2, alpha=0.5, s=10)
        ax.set_xlabel(gene1, fontsize=12)
        ax.set_ylabel(gene2, fontsize=12)
        ax.set_title(
            f"Correlation: {correlation:.3f} (p={pvalue:.2e})",
            fontsize=14
        )
        
        # Add trend line
        z = np.polyfit(expr1, expr2, 1)
        p = np.poly1d(z)
        ax.plot(expr1, p(expr1), "r--", alpha=0.8, linewidth=2)
        
        if return_base64:
            return self._fig_to_base64(fig)
        
        plt.close(fig)
        return None
    
    def generate_volcano_plot(
        self,
        dge_results: Any,
        logfc_threshold: float = 0.5,
        pval_threshold: float = 0.05,
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate volcano plot for DGE results
        
        Args:
            dge_results: DataFrame with DGE results
            logfc_threshold: Log fold change threshold
            pval_threshold: P-value threshold
            return_base64: Whether to return base64 encoded image
        
        Returns:
            Base64 encoded image or None
        """
        logger.info(f"🌋 Generating volcano plot")
        
        import pandas as pd
        if isinstance(dge_results, pd.DataFrame):
            df = dge_results
        else:
            df = pd.DataFrame(dge_results)
        
        fig, ax = plt.subplots(figsize=(10, 8))
        
        # Calculate -log10(pvalue)
        df['-log10(pval)'] = -np.log10(df['pvals_adj'])
        
        # Color points
        colors = []
        for _, row in df.iterrows():
            if abs(row['logfoldchanges']) > logfc_threshold and row['pvals_adj'] < pval_threshold:
                colors.append('red' if row['logfoldchanges'] > 0 else 'blue')
            else:
                colors.append('gray')
        
        ax.scatter(
            df['logfoldchanges'], 
            df['-log10(pval)'],
            c=colors,
            alpha=0.6,
            s=10
        )
        
        ax.axvline(-logfc_threshold, color='black', linestyle='--', alpha=0.5)
        ax.axvline(logfc_threshold, color='black', linestyle='--', alpha=0.5)
        ax.axhline(-np.log10(pval_threshold), color='black', linestyle='--', alpha=0.5)
        
        ax.set_xlabel('Log2 Fold Change', fontsize=12)
        ax.set_ylabel('-Log10(Adjusted P-value)', fontsize=12)
        ax.set_title('Volcano Plot', fontsize=14)
        
        if return_base64:
            return self._fig_to_base64(fig)
        
        plt.close(fig)
        return None
    
    def generate_rank_genes_groups_plot(
        self,
        adata: sc.AnnData,
        n_genes: int = 20,
        groupby: str = "CellType",
        groups: Optional[List[str]] = None,
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate rank genes groups plot (heatmap of top marker genes)
        
        Args:
            adata: AnnData object with rank_genes_groups results
            n_genes: Number of top genes per group
            groupby: Grouping variable
            groups: Optional list of specific groups to display (e.g. ["Hepatocytes"])
            return_base64: Whether to return base64
            
        Returns:
            Base64 encoded image or None
        """
        logger.info(f"📊 Generating rank genes groups plot" + (f" for groups={groups}" if groups else ""))
        
        try:
            # Let scanpy create its own figure; retrieve it afterward with plt.gcf()
            sc.pl.rank_genes_groups(
                adata,
                n_genes=n_genes,
                groups=groups,
                sharey=False,
                show=False
            )
            fig = plt.gcf()
            
            if return_base64:
                img = self._fig_to_base64(fig)  # _fig_to_base64 closes fig
                return img
            
            plt.close(fig)
            return None
            
        except Exception as e:
            logger.error(f"Failed to generate rank genes groups plot: {e}")
            plt.close('all')
            return None
    
    def generate_rank_genes_groups_dotplot(
        self,
        adata: sc.AnnData,
        n_genes: int = 10,
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate dotplot of top marker genes per group
        
        Args:
            adata: AnnData with rank_genes_groups
            n_genes: Number of genes per group
            return_base64: Base64 encoding
            
        Returns:
            Base64 image or None
        """
        logger.info(f"🔵 Generating rank genes groups dotplot")
        
        try:
            fig = plt.figure(figsize=(14, 8))
            sc.pl.rank_genes_groups_dotplot(
                adata,
                n_genes=n_genes,
                show=False
            )
            
            if return_base64:
                return self._fig_to_base64(plt.gcf())
            
            plt.close(fig)
            return None
            
        except Exception as e:
            logger.error(f"Failed to generate dotplot: {e}")
            plt.close('all')
            return None
    
    def generate_interactive_violin(
        self,
        adata: sc.AnnData,
        gene: str,
        groupby: str = "CellType",
        splitby: Optional[str] = None,
        return_base64: bool = True
    ) -> Optional[str]:
        """
        Generate interactive violin plot for a single gene
        
        Args:
            adata: AnnData object
            gene: Gene to plot
            groupby: Main grouping variable
            splitby: Optional split variable (e.g., Condition)
            return_base64: Base64 encoding
            
        Returns:
            Base64 image or None
        """
        logger.info(f"🎻 Generating violin plot for gene: {gene}")
        
        if gene not in adata.var_names:
            logger.warning(f"Gene {gene} not found in dataset")
            return None
        
        fig, ax = plt.subplots(figsize=(12, 6))
        
        if splitby and splitby in adata.obs.columns:
            sc.pl.violin(
                adata,
                keys=gene,
                groupby=groupby,
                split=splitby,
                rotation=90,
                ax=ax,
                show=False
            )
        else:
            sc.pl.violin(
                adata,
                keys=gene,
                groupby=groupby,
                rotation=90,
                ax=ax,
                show=False
            )
        
        plt.title(f'Expression of {gene}', fontsize=14, fontweight='bold')
        plt.tight_layout()
        
        if return_base64:
            return self._fig_to_base64(fig)
        
        plt.close(fig)
        return None
    
    def _fig_to_base64(self, fig) -> str:
        """Convert matplotlib figure to base64 string"""
        buf = io.BytesIO()
        fig.savefig(buf, format='png', bbox_inches='tight', dpi=150)
        buf.seek(0)
        img_base64 = base64.b64encode(buf.read()).decode('utf-8')
        plt.close(fig)
        return f"data:image/png;base64,{img_base64}"

# Global instance
visualization_service = VisualizationService()
