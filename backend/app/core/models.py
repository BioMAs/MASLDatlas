"""
Pydantic models for request/response validation
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from enum import Enum

# Enums
class OrganismType(str, Enum):
    HUMAN = "Human"
    MOUSE = "Mouse"
    ZEBRAFISH = "Zebrafish"
    INTEGRATED = "Integrated"

class TestMethod(str, Enum):
    WILCOXON = "wilcoxon"
    TTEST = "t-test"
    LOGREG = "logreg"

class CorrelationMethod(str, Enum):
    SPEARMAN = "spearman"
    PEARSON = "pearson"

class EnrichmentDatabase(str, Enum):
    GO_BP = "GO_Biological_Process"
    GO_ALL = "Gene_Ontology"
    KEGG = "KEGG"
    REACTOME = "Reactome"
    WIKIPATHWAYS = "WikiPathways"

# Request models
class DatasetLoadRequest(BaseModel):
    organism: OrganismType
    dataset_name: str
    size_option: Optional[str] = "full"

class GeneExpressionRequest(BaseModel):
    gene_name: str
    color_by: Optional[str] = "CellType"

class DifferentialExpressionRequest(BaseModel):
    group1: str
    group2: str
    groupby: str = "CellType"
    method: TestMethod = TestMethod.WILCOXON
    min_logfc: float = 0.5
    max_pval: float = 0.05

class MarkerGeneRequest(BaseModel):
    groupby: str = "CellType"
    method: TestMethod = TestMethod.WILCOXON
    n_genes: int = 100

class CorrelationRequest(BaseModel):
    gene1: str
    gene2: str
    method: CorrelationMethod = CorrelationMethod.SPEARMAN
    remove_zeros: bool = False

class EnrichmentRequest(BaseModel):
    gene_list: List[str]
    database: EnrichmentDatabase
    organism: OrganismType

class GeneSetScoreRequest(BaseModel):
    gene_set: Dict[str, List[str]]
    method: str = "aucell"

# Response models
class DatasetInfo(BaseModel):
    organism: str
    dataset_name: str
    n_cells: int
    n_genes: int
    cell_types: List[str]
    metadata_columns: List[str]
    available_layers: List[str]

class GeneExpressionResponse(BaseModel):
    gene: str
    expression_data: Dict[str, Any]
    umap_coordinates: Optional[Dict[str, List[float]]] = None

class DGEResult(BaseModel):
    gene: str
    log2fc: float
    pvalue: float
    pvalue_adj: float
    score: Optional[float] = None

class CorrelationResult(BaseModel):
    gene1: str
    gene2: str
    correlation: float
    pvalue: float
    method: str
    n_cells: int

class EnrichmentResult(BaseModel):
    term_id: str
    term_name: str
    pvalue: float
    odds_ratio: float
    n_genes: int
    genes: List[str]

class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None
