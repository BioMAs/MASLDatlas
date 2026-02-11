"""
Service for enrichment and pathway analysis
"""
import gseapy as gp
import decoupler as dc
import pandas as pd
import scanpy as sc
import numpy as np
from typing import List, Dict, Any, Optional
from loguru import logger
from app.core.models import EnrichmentDatabase, OrganismType

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

enrichment_service = EnrichmentService()
