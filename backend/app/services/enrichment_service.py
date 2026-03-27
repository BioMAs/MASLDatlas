"""
Service for enrichment and pathway analysis
"""
import gseapy as gp
import decoupler as dc
import pandas as pd
import scanpy as sc
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from typing import List, Dict, Any, Optional, Tuple
from loguru import logger
import io
import base64
from app.core.models import EnrichmentDatabase, OrganismType
from app.services.rds_loader import get_rds_loader

class EnrichmentService:
    def __init__(self):
        pass

    def perform_enrichment(
        self,
        gene_list: List[str],
        database: EnrichmentDatabase,
        organism: OrganismType
    ) -> List[Dict[str, Any]]:
        """
        Perform functional enrichment analysis using gseapy (Enrichr API)
        
        Args:
            gene_list: List of gene symbols
            database: Database to query (GO, KEGG, etc.)
            organism: Organism (Human, Mouse, etc.)
            
        Returns:
            List of enrichment results
        """
        logger.info(f"🧬 Running enrichment analysis for {len(gene_list)} genes against {database.value}")
        
        # Map organism to gseapy/Enrichr format
        if organism == OrganismType.HUMAN:
            organism_name = "Human"
            kegg_lib = "KEGG_2021_Human"
        elif organism == OrganismType.MOUSE:
            organism_name = "Mouse"
            kegg_lib = "KEGG_2019_Mouse"
        elif organism == OrganismType.ZEBRAFISH:
            organism_name = "Zebrafish"
            kegg_lib = "KEGG_2019_Human" # Fallback or specific mapping needed
        elif organism == OrganismType.INTEGRATED:
            organism_name = "Human" # Assume converted to Human orthologs usually
            kegg_lib = "KEGG_2021_Human"
        else:
            organism_name = "Human"
            kegg_lib = "KEGG_2021_Human"
            
        # Map database to gseapy library names
        # Check https://maayanlab.cloud/Enrichr/#libraries for names
        db_map = {
            EnrichmentDatabase.GO_BP: "GO_Biological_Process_2023",
            EnrichmentDatabase.GO_ALL: "GO_Biological_Process_2023",
            EnrichmentDatabase.KEGG: kegg_lib,
            EnrichmentDatabase.REACTOME: "Reactome_2022",
            EnrichmentDatabase.WIKIPATHWAYS: "WikiPathways_2021_Human", 
        }
        
        gene_set = db_map.get(database, "GO_Biological_Process_2023")
        
        try:
            # Using enrichr API (requires internet access)
            # Alternatively use prerank if we had ranked list, but here we have gene list
            enr = gp.enrichr(
                gene_list=gene_list,
                gene_sets=gene_set,
                organism=organism_name,
                outdir=None # Don't write to disk
            )
            
            results = enr.results
            if results.empty:
                return []
                
            # Filter significant results
            results = results[results['Adjusted P-value'] < 0.05]
            
            output = []
            # Return top 50
            for _, row in results.head(50).iterrows():
                genes_str = row.get("Genes", "")
                genes_list = genes_str.split(";") if isinstance(genes_str, str) else []
                
                output.append({
                    "term_id": row.get("Term", "Unknown"),
                    "term_name": row.get("Term", "Unknown"),
                    "pvalue": float(row.get("Adjusted P-value", 1.0)),
                    "odds_ratio": float(row.get("Odds Ratio", 0.0)),
                    "n_genes": len(genes_list),
                    "genes": genes_list
                })
                
            return output
            
        except Exception as e:
            logger.error(f"Enrichment failed: {e}")
            # If offline or error, return empty list instead of crashing
            return []

    def calculate_activity(
        self,
        adata: sc.AnnData,
        organism: OrganismType,
        net_name: str = "collectri"
    ) -> pd.DataFrame:
        """
        Calculate pathway activity (TF or Kinetic) using decoupler
        
        Returns a DataFrame of activities (Cells x Pathways)
        """
        logger.info(f"⚡ Calculating {net_name} activity for {organism}")
        
        # Determine organism string for decoupler
        species = "human"
        if organism == OrganismType.MOUSE:
            species = "mouse"
        
        try:
            net = None
            if net_name == "collectri":
                # TF activity
                net = dc.get_collectri(organism=species, split_complexes=False)
            elif net_name == "progeny":
                # Pathway activity
                net = dc.get_progeny(organism=species, top=100)
            else:
                 raise ValueError(f"Unknown network: {net_name}")
            
            # Check if genes in adata match network
            # Decoupler needs raw counts or normalized expression? 
            # Usually normalized. adata.X should be normalized.
            
            # Using mlm (Multivariate Linear Model) or ulm (Univariate)
            # ulm is faster.
            dc.run_ulm(
                mat=adata,
                net=net,
                source='source',
                target='target',
                weight='weight',
                verbose=True,
                use_raw=False
            )
            
            # acts is stored in adata.obsm['ulm_estimate']
            acts = adata.obsm['ulm_estimate']
            
            return acts
            
        except Exception as e:
            logger.error(f"Activity calculation failed: {e}")
            raise e
    
    # ========== DECOUPLER VISUALIZATION METHODS ==========
    
    def _fig_to_base64(self, fig) -> str:
        """Convert matplotlib figure to base64 string"""
        buf = io.BytesIO()
        fig.savefig(buf, format='png', dpi=300, bbox_inches='tight')
        buf.seek(0)
        img_base64 = base64.b64encode(buf.read()).decode('utf-8')
        plt.close(fig)
        return f"data:image/png;base64,{img_base64}"
    
    def run_collectri_analysis(
        self,
        deseq_results: pd.DataFrame,
        organism: str = "human"
    ) -> Tuple[pd.DataFrame, str]:
        """
        Run CollecTRI TF enrichment analysis on DESeq2 results
        
        Args:
            deseq_results: DataFrame with gene names as index and log2FoldChange
            organism: 'human', 'mouse', or 'zebrafish'
            
        Returns:
            Tuple of (scores DataFrame, barplot base64 image)
        """
        logger.info(f"🧬 Running CollecTRI analysis for {organism}")
        
        try:
            # Load CollecTRI network from RDS
            rds_loader = get_rds_loader()
            collectri_net = rds_loader.load_collectri()
            collectri_net = rds_loader.convert_to_decoupler_network(collectri_net)
            
            # Prepare gene expression matrix (genes x samples)
            # For DESeq2, we typically have log2FC as a proxy
            mat = deseq_results[['log2FoldChange']].copy()
            mat.columns = ['sample']
            
            # Run ULM (Univariate Linear Model)
            tf_acts = dc.run_ulm(
                mat=mat.T,  # Transpose: samples x genes
                net=collectri_net,
                source='source',
                target='target',
                weight='weight',
                verbose=False
            )
            
            # Extract results
            # Use iloc[:,0] to avoid depending on the column name produced by decoupler
            scores = tf_acts[0].T  # Transpose back: TFs x samples
            scores['score'] = scores.iloc[:, 0]
            scores = scores.sort_values('score', ascending=False)
            
            # Create barplot of top 25 TFs
            fig, ax = plt.subplots(figsize=(8, 10))
            top_tfs = pd.concat([scores.head(15), scores.tail(10)])
            
            colors = ['red' if x > 0 else 'blue' for x in top_tfs['score']]
            ax.barh(range(len(top_tfs)), top_tfs['score'], color=colors)
            ax.set_yticks(range(len(top_tfs)))
            ax.set_yticklabels(top_tfs.index)
            ax.set_xlabel('TF Activity Score')
            ax.set_title('Top 25 Transcription Factors (CollecTRI)')
            ax.axvline(x=0, color='black', linestyle='--', linewidth=0.8)
            plt.tight_layout()
            
            barplot_img = self._fig_to_base64(fig)
            
            logger.info(f"✅ CollecTRI analysis complete: {len(scores)} TFs")
            return scores, barplot_img
            
        except Exception as e:
            logger.error(f"❌ CollecTRI analysis failed: {e}")
            raise
    
    def plot_collectri_volcano(
        self,
        deseq_results: pd.DataFrame,
        selected_tf: str
    ) -> str:
        """
        Volcano plot highlighting target genes of a given TF from CollecTRI.
        All genes are shown in gray; TF targets are colored by their regulatory
        weight (red = activation, blue = repression).

        Args:
            deseq_results: DataFrame indexed by gene symbol with columns
                           'log2FoldChange' and 'pvalue'.
            selected_tf: TF name to visualize.

        Returns:
            Base64 encoded PNG image.
        """
        logger.info(f"📊 Creating CollecTRI volcano plot for TF: {selected_tf}")

        try:
            # Load CollecTRI network to obtain targets for this TF
            rds_loader = get_rds_loader()
            collectri_net = rds_loader.load_collectri()
            collectri_net = rds_loader.convert_to_decoupler_network(collectri_net)

            tf_targets = collectri_net[collectri_net['source'] == selected_tf].copy()
            if tf_targets.empty:
                fig, ax = plt.subplots(figsize=(10, 8))
                ax.text(0.5, 0.5, f'TF "{selected_tf}" not found in CollecTRI network.',
                        ha='center', va='center', fontsize=12, color='gray')
                ax.set_title(f'Volcano Plot: {selected_tf}')
                return self._fig_to_base64(fig)

            # Validate required columns
            required = {'log2FoldChange', 'pvalue'}
            if not required.issubset(deseq_results.columns):
                raise ValueError(f"deseq_results must contain: {required}")

            # Build volcano data frame for all genes
            plot_df = deseq_results[['log2FoldChange', 'pvalue']].copy().dropna()
            plot_df['-log10pval'] = -np.log10(plot_df['pvalue'].clip(lower=1e-300))

            # Annotate TF targets with their regulatory weight
            target_weight = tf_targets.set_index('target')['weight'].to_dict()
            plot_df['is_target'] = plot_df.index.isin(target_weight)
            plot_df['tf_weight'] = plot_df.index.map(target_weight).fillna(0)

            fig, ax = plt.subplots(figsize=(10, 8))

            # All non-target genes (background)
            bg = plot_df[~plot_df['is_target']]
            ax.scatter(bg['log2FoldChange'], bg['-log10pval'],
                       c='#cccccc', s=8, alpha=0.4, zorder=1, label='Non-targets')

            # Activated targets (weight > 0)
            act = plot_df[plot_df['is_target'] & (plot_df['tf_weight'] > 0)]
            if not act.empty:
                ax.scatter(act['log2FoldChange'], act['-log10pval'],
                           c='#e74c3c', s=45, alpha=0.85, zorder=3,
                           label=f'Activated targets (n={len(act)})')

            # Repressed targets (weight < 0)
            rep = plot_df[plot_df['is_target'] & (plot_df['tf_weight'] < 0)]
            if not rep.empty:
                ax.scatter(rep['log2FoldChange'], rep['-log10pval'],
                           c='#3498db', s=45, alpha=0.85, zorder=3,
                           label=f'Repressed targets (n={len(rep)})')

            # Label top 12 TF targets by significance
            top_targets = plot_df[plot_df['is_target']].nlargest(12, '-log10pval')
            for gene, row in top_targets.iterrows():
                ax.annotate(gene,
                            xy=(row['log2FoldChange'], row['-log10pval']),
                            xytext=(5, 3), textcoords='offset points',
                            fontsize=7, color='#333333')

            # Reference lines
            ax.axvline(x=0, color='black', linestyle='--', linewidth=0.8, alpha=0.5)
            ax.axhline(y=-np.log10(0.05), color='orange', linestyle=':',
                       linewidth=1, alpha=0.7, label='p = 0.05')

            ax.set_xlabel('Log2 Fold Change', fontsize=12)
            ax.set_ylabel('-Log10 P-value', fontsize=12)
            ax.set_title(f'{selected_tf} Target Genes — CollecTRI', fontsize=14)
            ax.legend(loc='upper left', fontsize=8)
            sns.despine(ax=ax)
            plt.tight_layout()

            return self._fig_to_base64(fig)

        except Exception as e:
            logger.error(f"❌ CollecTRI volcano plot failed: {e}")
            fig, ax = plt.subplots(figsize=(10, 8))
            ax.text(0.5, 0.5, f'Error generating plot:\n{str(e)[:200]}',
                    ha='center', va='center', fontsize=10, color='red')
            return self._fig_to_base64(fig)
    
    def plot_collectri_network(
        self,
        selected_tf: str,
        deseq_results: pd.DataFrame,
        n_targets: int = 20
    ) -> str:
        """
        Hub-and-spoke network plot for a TF from CollecTRI.
        Edges are colored by regulatory weight (red = activation, blue = repression).
        Target nodes are colored by log2FoldChange from DESeq2 results.

        Args:
            selected_tf: TF name.
            deseq_results: DESeq2 results (indexed by gene); 'log2FoldChange' used for coloring.
            n_targets: Maximum number of target genes to display.

        Returns:
            Base64 encoded PNG image.
        """
        logger.info(f"🕸️ Creating CollecTRI network plot for TF: {selected_tf}")

        try:
            from matplotlib.lines import Line2D
            from matplotlib.patches import Patch
            import matplotlib.cm as cm_module

            # Load CollecTRI network
            rds_loader = get_rds_loader()
            collectri_net = rds_loader.load_collectri()
            collectri_net = rds_loader.convert_to_decoupler_network(collectri_net)

            tf_targets = collectri_net[collectri_net['source'] == selected_tf].copy()
            if tf_targets.empty:
                fig, ax = plt.subplots(figsize=(10, 10))
                ax.text(0.5, 0.5, f'TF "{selected_tf}" not found in CollecTRI.',
                        ha='center', va='center', fontsize=12, color='gray')
                ax.axis('off')
                return self._fig_to_base64(fig)

            # Merge with fold changes for node colors
            if not deseq_results.empty and 'log2FoldChange' in deseq_results.columns:
                tf_targets = tf_targets.merge(
                    deseq_results[['log2FoldChange']],
                    left_on='target', right_index=True,
                    how='left'
                )
            else:
                tf_targets['log2FoldChange'] = 0.0

            # Select top N targets by absolute weight
            tf_targets = tf_targets.assign(abs_weight=tf_targets['weight'].abs())
            tf_targets = tf_targets.nlargest(n_targets, 'abs_weight').reset_index(drop=True)

            n = len(tf_targets)
            angles = np.linspace(0, 2 * np.pi, n, endpoint=False)
            tx = np.cos(angles)
            ty = np.sin(angles)

            fig, ax = plt.subplots(figsize=(12, 12))
            ax.set_aspect('equal')

            max_w = tf_targets['abs_weight'].max() + 1e-9

            # Draw edges (TF → target)
            for i, row in tf_targets.iterrows():
                edge_color = '#e74c3c' if row['weight'] > 0 else '#3498db'
                alpha = 0.3 + 0.6 * row['abs_weight'] / max_w
                lw = 0.8 + 2.2 * row['abs_weight'] / max_w
                ax.plot([0, tx[i]], [0, ty[i]],
                        c=edge_color, alpha=alpha, lw=lw, zorder=1)

            # Draw target nodes (colored by fold change)
            norm_lfc = plt.Normalize(-2, 2)
            cmap = cm_module.get_cmap('RdBu_r')

            for i, row in tf_targets.iterrows():
                lfc = row['log2FoldChange'] if not pd.isna(row['log2FoldChange']) else 0.0
                node_color = cmap(norm_lfc(np.clip(lfc, -2, 2)))
                ax.scatter(tx[i], ty[i], s=220, color=node_color, zorder=3,
                           edgecolors='#333333', linewidths=0.6)
                # Label: positioned slightly further than the node
                lx, ly = tx[i] * 1.22, ty[i] * 1.22
                ha = 'left' if tx[i] >= 0 else 'right'
                va = 'bottom' if ty[i] >= 0 else 'top'
                ax.text(lx, ly, row['target'], fontsize=7, ha=ha, va=va, color='#222222')

            # Central TF node
            ax.scatter(0, 0, s=1400, color='#f39c12', zorder=4,
                       edgecolors='#222', linewidths=1.5)
            ax.text(0, 0, selected_tf, ha='center', va='center',
                    fontsize=11, fontweight='bold', color='black', zorder=5)

            # Colorbar for fold change
            sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm_lfc)
            sm.set_array([])
            cbar = plt.colorbar(sm, ax=ax, fraction=0.025, pad=0.02)
            cbar.set_label('Log2 Fold Change', fontsize=9)

            legend_elements = [
                Line2D([0], [0], color='#e74c3c', lw=2.5, label='Activation (+weight)'),
                Line2D([0], [0], color='#3498db', lw=2.5, label='Repression (−weight)'),
            ]
            ax.legend(handles=legend_elements, loc='lower right', fontsize=9)

            ax.set_title(
                f'TF-Target Regulatory Network: {selected_tf}\n'
                f'(top {n} targets by |weight|, colored by log₂FC)',
                fontsize=13
            )
            ax.set_xlim(-1.5, 1.5)
            ax.set_ylim(-1.5, 1.5)
            ax.axis('off')
            plt.tight_layout()

            return self._fig_to_base64(fig)

        except Exception as e:
            logger.error(f"❌ CollecTRI network plot failed: {e}")
            fig, ax = plt.subplots(figsize=(10, 10))
            ax.text(0.5, 0.5, f'Error generating network:\n{str(e)[:200]}',
                    ha='center', va='center', fontsize=10, color='red')
            ax.axis('off')
            return self._fig_to_base64(fig)
    
    def run_progeny_analysis(
        self,
        deseq_results: pd.DataFrame,
        organism: str = "human"
    ) -> Tuple[pd.DataFrame, str]:
        """
        Run PROGENy pathway activity analysis
        
        Returns:
            Tuple of (pathway scores DataFrame, barplot base64 image)
        """
        logger.info(f"🛤️ Running PROGENy analysis for {organism}")
        
        try:
            # Load PROGENy network
            rds_loader = get_rds_loader()
            progeny_net = rds_loader.load_progeny()
            
            # Prepare matrix
            mat = deseq_results[['log2FoldChange']].copy()
            mat.columns = ['sample']
            
            # Run MLM (Multivariate Linear Model) for pathway scores
            pathway_acts = dc.run_mlm(
                mat=mat.T,
                net=progeny_net,
                source='source',
                target='target',
                weight='weight',
                verbose=False
            )
            
            scores = pathway_acts[0].T
            # Use iloc[:,0] to avoid depending on the column name produced by decoupler
            scores['score'] = scores.iloc[:, 0]
            scores = scores.sort_values('score', ascending=False)
            
            # Create barplot
            fig, ax = plt.subplots(figsize=(10, 8))
            colors = ['red' if x > 0 else 'blue' for x in scores['score']]
            ax.barh(range(len(scores)), scores['score'], color=colors)
            ax.set_yticks(range(len(scores)))
            ax.set_yticklabels(scores.index)
            ax.set_xlabel('Pathway Activity Score')
            ax.set_title('PROGENy Pathway Activities')
            ax.axvline(x=0, color='black', linestyle='--', linewidth=0.8)
            plt.tight_layout()
            
            barplot_img = self._fig_to_base64(fig)
            
            logger.info(f"✅ PROGENy analysis complete: {len(scores)} pathways")
            return scores, barplot_img
            
        except Exception as e:
            logger.error(f"❌ PROGENy analysis failed: {e}")
            raise
    
    def plot_progeny_targets(
        self,
        pathway: str,
        deseq_results: pd.DataFrame,
        n_genes: int = 50
    ) -> str:
        """
        Side-by-side horizontal barplot showing:
        - Left: PROGENy footprint weights for the selected pathway.
        - Right: Log2FoldChange of those same genes in DESeq2 results.

        Args:
            pathway: Pathway name (e.g. 'MAPK', 'PI3K', 'TNFa', …).
            deseq_results: DESeq2 results indexed by gene symbol.
            n_genes: Maximum number of top genes to display (by |weight|).

        Returns:
            Base64 encoded PNG image.
        """
        logger.info(f"📊 Creating PROGENy target genes plot for pathway: {pathway}")

        try:
            # Load PROGENy network
            rds_loader = get_rds_loader()
            progeny_net = rds_loader.load_progeny()

            if 'source' not in progeny_net.columns:
                raise ValueError("PROGENy network is missing the 'source' column.")

            # Filter for the selected pathway (case-insensitive)
            mask = progeny_net['source'].str.upper() == pathway.upper()
            pathway_genes = progeny_net[mask].copy()

            if pathway_genes.empty:
                available = sorted(progeny_net['source'].unique().tolist())
                fig, ax = plt.subplots(figsize=(10, 6))
                ax.text(
                    0.5, 0.5,
                    f'Pathway "{pathway}" not found in PROGENy.\n'
                    f'Available: {chr(10).join(available[:20])}',
                    ha='center', va='center', fontsize=9, color='gray'
                )
                ax.set_title(f'PROGENy: {pathway}')
                return self._fig_to_base64(fig)

            # Select top N genes by |weight|
            pathway_genes = pathway_genes.assign(abs_weight=pathway_genes['weight'].abs())
            pathway_genes = pathway_genes.nlargest(n_genes, 'abs_weight')
            pathway_genes = pathway_genes.sort_values('weight', ascending=True).reset_index(drop=True)

            # Merge DESeq2 fold changes
            if not deseq_results.empty and 'log2FoldChange' in deseq_results.columns:
                pathway_genes = pathway_genes.merge(
                    deseq_results[['log2FoldChange']],
                    left_on='target', right_index=True,
                    how='left'
                )
            else:
                pathway_genes['log2FoldChange'] = np.nan
            pathway_genes['log2FoldChange'] = pathway_genes['log2FoldChange'].fillna(0)

            n = len(pathway_genes)
            fig_h = max(6, n * 0.30 + 2)
            fig, axes = plt.subplots(1, 2, figsize=(16, fig_h))

            y_pos = range(n)

            # Left: PROGENy weights
            ax1 = axes[0]
            colors_w = ['#e74c3c' if w > 0 else '#3498db' for w in pathway_genes['weight']]
            ax1.barh(y_pos, pathway_genes['weight'], color=colors_w, alpha=0.85)
            ax1.set_yticks(y_pos)
            ax1.set_yticklabels(pathway_genes['target'], fontsize=7)
            ax1.axvline(x=0, color='black', lw=0.8)
            ax1.set_xlabel('PROGENy Weight', fontsize=10)
            ax1.set_title(f'{pathway} — Footprint Weights', fontsize=11)
            sns.despine(ax=ax1)

            # Right: DESeq2 log2FC for same genes
            ax2 = axes[1]
            lfc_vals = pathway_genes['log2FoldChange'].values
            colors_fc = ['#e74c3c' if v > 0 else '#3498db' for v in lfc_vals]
            ax2.barh(y_pos, lfc_vals, color=colors_fc, alpha=0.85)
            ax2.set_yticks(y_pos)
            ax2.set_yticklabels(pathway_genes['target'], fontsize=7)
            ax2.axvline(x=0, color='black', lw=0.8)
            ax2.set_xlabel('Log2 Fold Change (DESeq2)', fontsize=10)
            ax2.set_title(f'{pathway} — Expression in Dataset', fontsize=11)
            sns.despine(ax=ax2)

            plt.suptitle(
                f'PROGENy: {pathway} Target Genes (top {n} by |weight|)',
                fontsize=13, fontweight='bold'
            )
            plt.tight_layout()

            return self._fig_to_base64(fig)

        except Exception as e:
            logger.error(f"❌ PROGENy targets plot failed: {e}")
            fig, ax = plt.subplots(figsize=(10, 8))
            ax.text(0.5, 0.5, f'Error generating plot:\n{str(e)[:200]}',
                    ha='center', va='center', fontsize=10, color='red')
            return self._fig_to_base64(fig)
    
    def run_msigdb_analysis(
        self,
        deseq_results: pd.DataFrame,
        gene_sets: str = "hallmark"
    ) -> Tuple[pd.DataFrame, str]:
        """
        Run MSigDB enrichment using decoupler
        
        Args:
            deseq_results: DESeq2 results
            gene_sets: MSigDB collection (e.g., 'hallmark')
            
        Returns:
            Tuple of (enrichment scores, dotplot image)
        """
        logger.info(f"📚 Running MSigDB {gene_sets} analysis")

        # Human-readable labels for plot titles
        _collection_labels = {
            'hallmark': 'Hallmark',
            'c2.cgp': 'Chemical & Genetic Perturbations',
            'c5.go.bp': 'GO Biological Process',
            'c6': 'Oncogenic Signatures',
        }
        collection_label = _collection_labels.get(gene_sets, gene_sets)
        
        try:
            # Get MSigDB gene sets via decoupler
            msigdb = dc.get_resource('MSigDB')
            gene_set_df = msigdb[msigdb['collection'] == gene_sets]
            if gene_set_df.empty:
                raise ValueError(
                    f"MSigDB collection '{gene_sets}' returned no gene sets. "
                    f"Available collections: {msigdb['collection'].unique().tolist()}"
                )
            
            # Prepare matrix
            mat = deseq_results[['log2FoldChange']].copy()
            mat.columns = ['sample']
            
            # Run ORA (Over-Representation Analysis)
            ora_results = dc.run_ora(
                mat=mat.T,
                net=gene_set_df,
                source='geneset',
                target='genesymbol',
                verbose=False
            )
            
            scores = ora_results[0].T
            # clip before -log10 to avoid +inf when p-value == 0 (non-JSON-serialisable)
            scores['score'] = -np.log10(scores.iloc[:, 0].clip(lower=1e-300))
            scores = scores.sort_values('score', ascending=False).head(25)
            
            # Create dotplot
            fig, ax = plt.subplots(figsize=(10, 12))
            ax.scatter(scores['score'], range(len(scores)), s=100, alpha=0.6)
            ax.set_yticks(range(len(scores)))
            ax.set_yticklabels(scores.index)
            ax.set_xlabel('-Log10 P-value')
            ax.set_title(f'MSigDB {collection_label} Enrichment')
            plt.tight_layout()
            
            dotplot_img = self._fig_to_base64(fig)
            
            logger.info(f"✅ MSigDB analysis complete")
            return scores, dotplot_img
            
        except Exception as e:
            logger.error(f"❌ MSigDB analysis failed: {e}")
            raise
    
    def plot_msigdb_running_score(
        self,
        gene_set: str,
        deseq_results: pd.DataFrame
    ) -> str:
        """
        GSEA-style running enrichment score plot for an MSigDB gene set.

        Genes are pre-ranked by log2FoldChange (descending). A KS-like
        running sum increments when a member of the gene set is encountered
        and decrements otherwise. The enrichment score (ES) is the maximum
        absolute deviation from zero.

        Args:
            gene_set: Exact or partial MSigDB geneset name (case-insensitive).
            deseq_results: DESeq2 results indexed by gene symbol with
                           'log2FoldChange' column.

        Returns:
            Base64 encoded PNG image.
        """
        logger.info(f"📈 Creating GSEA running score plot for: {gene_set}")

        try:
            if 'log2FoldChange' not in deseq_results.columns:
                raise ValueError("deseq_results must have a 'log2FoldChange' column.")

            # Get MSigDB via decoupler
            msigdb = dc.get_resource('MSigDB')

            # Match gene set name (exact first, then partial)
            gs_upper = gene_set.upper()
            mask = msigdb['geneset'].str.upper() == gs_upper
            if not mask.any():
                mask = msigdb['geneset'].str.upper().str.contains(gs_upper, na=False)

            if not mask.any():
                fig, ax = plt.subplots(figsize=(12, 6))
                ax.text(0.5, 0.5, f'Gene set "{gene_set}" not found in MSigDB.\n'
                                   f'Try a partial name such as "HALLMARK_" prefix.',
                        ha='center', va='center', fontsize=11, color='gray')
                ax.set_title(f'GSEA Running Score: {gene_set}')
                return self._fig_to_base64(fig)

            # Use the first matching gene set
            matched_name = msigdb[mask]['geneset'].iloc[0]
            set_genes = set(
                msigdb[msigdb['geneset'] == matched_name]['genesymbol']
                .dropna().str.upper().tolist()
            )

            # Rank genes by log2FC descending
            ranked = (
                deseq_results['log2FoldChange']
                .dropna()
                .sort_values(ascending=False)
            )
            genes_ranked = [str(g).upper() for g in ranked.index]
            n_total = len(genes_ranked)

            hits = np.array([1 if g in set_genes else 0 for g in genes_ranked])
            n_hits = int(hits.sum())
            n_miss = n_total - n_hits

            if n_hits == 0:
                fig, ax = plt.subplots(figsize=(12, 6))
                ax.text(0.5, 0.5,
                        f'No genes from "{matched_name}" found in the ranked list.',
                        ha='center', va='center', fontsize=11, color='gray')
                ax.set_title(f'GSEA Running Score: {matched_name}')
                return self._fig_to_base64(fig)

            # Compute running enrichment score (Kolmogorov-Smirnov-like)
            hit_inc = 1.0 / n_hits
            miss_inc = 1.0 / n_miss if n_miss > 0 else 0.0
            running = np.cumsum(np.where(hits == 1, hit_inc, -miss_inc))

            es_idx = int(np.argmax(np.abs(running)))
            es = running[es_idx]

            # ── Figure: 2 rows (running score + hit stripe) ──────────────────
            fig, axes = plt.subplots(
                2, 1, figsize=(12, 7),
                gridspec_kw={'height_ratios': [4, 1], 'hspace': 0.04}
            )
            ax_run, ax_bar = axes

            x = np.arange(n_total)

            # Running score line + fill
            ax_run.plot(x, running, lw=1.5, color='#2c3e50', zorder=3)
            ax_run.fill_between(x, 0, running, where=running > 0,
                                alpha=0.25, color='#e74c3c')
            ax_run.fill_between(x, 0, running, where=running < 0,
                                alpha=0.25, color='#3498db')
            ax_run.axhline(y=0, color='gray', lw=0.8)

            # Mark enrichment score
            ax_run.axvline(x=es_idx, color='#f39c12', lw=1.2,
                           linestyle='--', alpha=0.9)
            ax_run.scatter([es_idx], [es], color='#f39c12', s=70, zorder=5)
            offset = 'bottom' if es > 0 else 'top'
            ax_run.text(es_idx + n_total * 0.01, es,
                        f'ES = {es:.3f}', fontsize=9, color='#f39c12',
                        va=offset)

            # X-tick positions with LFC labels
            tick_pos = [
                0,
                n_total // 4,
                n_total // 2,
                3 * n_total // 4,
                n_total - 1
            ]
            ax_run.set_xticks(tick_pos)
            ax_run.set_xticklabels([])
            ax_run.set_xlim(0, n_total - 1)
            ax_run.set_ylabel('Running Enrichment Score', fontsize=10)
            ax_run.set_title(
                f'GSEA Running Score: {matched_name}\n'
                f'({n_hits} set genes / {n_total} total ranked)',
                fontsize=12
            )
            sns.despine(ax=ax_run, bottom=True)

            # Hit tick bar
            hit_positions = np.where(hits == 1)[0]
            ax_bar.vlines(hit_positions, 0, 1,
                          color='#2c3e50', lw=0.5, alpha=0.7)
            ax_bar.set_xlim(0, n_total - 1)
            ax_bar.set_ylim(0, 1)
            ax_bar.set_xticks(tick_pos)
            ax_bar.set_xticklabels(
                [f'{ranked.iloc[p]:.2f}' if p < len(ranked) else '' for p in tick_pos],
                fontsize=8
            )
            ax_bar.set_xlabel(
                'Genes ranked by Log2FC (left = up-regulated → right = down-regulated)',
                fontsize=9
            )
            ax_bar.set_yticks([])
            ax_bar.set_ylabel('Hits', fontsize=8, rotation=0, labelpad=28)
            sns.despine(ax=ax_bar, left=True)

            plt.tight_layout()

            return self._fig_to_base64(fig)

        except Exception as e:
            logger.error(f"❌ MSigDB running score plot failed: {e}")
            fig, ax = plt.subplots(figsize=(12, 6))
            ax.text(0.5, 0.5, f'Error generating running score:\n{str(e)[:200]}',
                    ha='center', va='center', fontsize=10, color='red')
            return self._fig_to_base64(fig)
    
    # ========== CUSTOM GENE SET ENRICHMENT ==========
    
    def run_custom_geneset_ulm(
        self,
        adata: sc.AnnData,
        geneset_dict: Dict[str, List[str]],
        geneset_name: str = "Custom"
    ) -> Tuple[pd.DataFrame, str, str]:
        """
        Run ULM enrichment on custom gene set
        
        Args:
            adata: AnnData object with expression data
            geneset_dict: Dict mapping geneset name to list of genes
            geneset_name: Name of the geneset for labeling
            
        Returns:
            Tuple of (scores DataFrame, UMAP image, violin plot image)
        """
        logger.info(f"🧬 Running custom gene set enrichment: {geneset_name}")
        
        try:
            # Convert geneset to decoupler network format
            # Network format: source (geneset name), target (gene), weight
            network_data = []
            for gs_name, genes in geneset_dict.items():
                for gene in genes:
                    network_data.append({
                        'source': gs_name,
                        'target': gene,
                        'weight': 1.0
                    })
            
            network = pd.DataFrame(network_data)
            
            # Run ULM (Univariate Linear Model)
            dc.run_ulm(
                mat=adata,
                net=network,
                source='source',
                target='target',
                weight='weight',
                verbose=False,
                use_raw=False
            )
            
            # Extract scores from adata.obsm
            scores = adata.obsm['ulm_estimate']
            scores_df = pd.DataFrame(
                scores,
                index=adata.obs_names,
                columns=list(geneset_dict.keys())
            )
            
            # Create UMAP colored by geneset score
            umap_img = None
            if 'X_umap' in adata.obsm:
                # Use first geneset for visualization
                first_geneset = list(geneset_dict.keys())[0]
                adata.obs[f'{geneset_name}_score'] = scores_df[first_geneset]
                
                fig, ax = plt.subplots(figsize=(10, 8))
                sc.pl.umap(
                    adata,
                    color=f'{geneset_name}_score',
                    cmap='RdBu_r',
                    ax=ax,
                    show=False
                )
                plt.title(f'UMAP - {first_geneset} Score')
                umap_img = self._fig_to_base64(fig)
            
            # Create violin plot by CellType
            violin_img = None
            if 'CellType' in adata.obs.columns:
                first_geneset = list(geneset_dict.keys())[0]
                
                fig, ax = plt.subplots(figsize=(12, 6))
                sc.pl.violin(
                    adata,
                    keys=f'{geneset_name}_score',
                    groupby='CellType',
                    rotation=90,
                    ax=ax,
                    show=False
                )
                plt.title(f'{first_geneset} Score by Cell Type')
                plt.tight_layout()
                violin_img = self._fig_to_base64(fig)
            
            logger.info(f"✅ Custom geneset enrichment complete")
            return scores_df, umap_img, violin_img
            
        except Exception as e:
            logger.error(f"❌ Custom geneset enrichment failed: {e}")
            raise
    
    def run_dual_geneset_comparison(
        self,
        adata: sc.AnnData,
        geneset1: Dict[str, List[str]],
        geneset2: Dict[str, List[str]],
        geneset1_name: str = "GeneSet1",
        geneset2_name: str = "GeneSet2"
    ) -> Tuple[pd.DataFrame, str, str]:
        """
        Compare two custom gene sets side by side
        
        Args:
            adata: AnnData object
            geneset1: First gene set
            geneset2: Second gene set
            geneset1_name: Name for first set
            geneset2_name: Name for second set
            
        Returns:
            Tuple of (combined scores, dual UMAP, dual violin)
        """
        logger.info(f"🔄 Comparing {geneset1_name} vs {geneset2_name}")
        
        try:
            # Combine both genesets
            combined_dict = {**geneset1, **geneset2}
            
            # Run enrichment
            scores_df, _, _ = self.run_custom_geneset_ulm(
                adata,
                combined_dict,
                geneset_name="Comparison"
            )
            
            # Create dual UMAP
            umap_img = None
            if 'X_umap' in adata.obsm:
                gs1_key = list(geneset1.keys())[0]
                gs2_key = list(geneset2.keys())[0]
                
                adata.obs[f'{geneset1_name}_score'] = scores_df[gs1_key]
                adata.obs[f'{geneset2_name}_score'] = scores_df[gs2_key]
                
                fig, axes = plt.subplots(1, 2, figsize=(16, 6))
                
                sc.pl.umap(
                    adata,
                    color=f'{geneset1_name}_score',
                    cmap='Blues',
                    ax=axes[0],
                    show=False,
                    title=geneset1_name
                )
                
                sc.pl.umap(
                    adata,
                    color=f'{geneset2_name}_score',
                    cmap='Reds',
                    ax=axes[1],
                    show=False,
                    title=geneset2_name
                )
                
                plt.tight_layout()
                umap_img = self._fig_to_base64(fig)
            
            # Create comparison violin plot
            violin_img = None
            if 'CellType' in adata.obs.columns:
                gs1_key = list(geneset1.keys())[0]
                gs2_key = list(geneset2.keys())[0]
                
                fig, axes = plt.subplots(2, 1, figsize=(12, 10))
                
                sc.pl.violin(
                    adata,
                    keys=f'{geneset1_name}_score',
                    groupby='CellType',
                    rotation=90,
                    ax=axes[0],
                    show=False
                )
                axes[0].set_title(f'{geneset1_name} by Cell Type')
                
                sc.pl.violin(
                    adata,
                    keys=f'{geneset2_name}_score',
                    groupby='CellType',
                    rotation=90,
                    ax=axes[1],
                    show=False
                )
                axes[1].set_title(f'{geneset2_name} by Cell Type')
                
                plt.tight_layout()
                violin_img = self._fig_to_base64(fig)
            
            logger.info(f"✅ Dual geneset comparison complete")
            return scores_df, umap_img, violin_img
            
        except Exception as e:
            logger.error(f"❌ Dual geneset comparison failed: {e}")
            raise

enrichment_service = EnrichmentService()
