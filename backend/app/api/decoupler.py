"""
API endpoints for Decoupler analyses (CollecTRI, PROGENy, MSigDB)
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from loguru import logger
import pandas as pd

from app.services.enrichment_service import enrichment_service

router = APIRouter()


# ──────────────────────────────────────────────────────────────────────────────
# Request models
# ──────────────────────────────────────────────────────────────────────────────

class DecouplerRequest(BaseModel):
    """DESeq2-style result list + target organism."""

    deseq_results: List[Dict[str, Any]] = Field(
        ...,
        description=(
            "List of gene-level records. Each item must contain at least "
            "`gene` (str), `log2FoldChange` (float) and optionally `pvalue`/`padj`."
        ),
        example=[
            {"gene": "TP53", "log2FoldChange": 1.8, "pvalue": 0.001, "padj": 0.005},
            {"gene": "MYC",  "log2FoldChange": -0.9, "pvalue": 0.03,  "padj": 0.07},
        ],
    )
    organism: str = Field(
        "human",
        description="Species: `human`, `mouse`, or `zebrafish`.",
    )
    collection: str = Field(
        "hallmark",
        description=(
            "MSigDB collection to use for ORA. Options: "
            "`hallmark` (50 Hallmark gene sets), "
            "`c2.cgp` (Chemical & Genetic Perturbations), "
            "`c5.go.bp` (GO Biological Process), "
            "`c6` (Oncogenic Signatures)."
        ),
    )


class TFVisualizationRequest(BaseModel):
    """Request for TF-specific visualisation (volcano or network)."""

    tf_name: str = Field(..., description="Exact TF symbol as it appears in CollecTRI (e.g. `TP53`, `MYC`).")
    deseq_results: List[Dict[str, Any]] = Field(..., description="See `DecouplerRequest.deseq_results`.")
    n_targets: int = Field(20, ge=1, le=100, description="Max number of target genes to display.")


class PathwayVisualizationRequest(BaseModel):
    """Request for pathway-specific target-gene plot (PROGENy)."""

    pathway_name: str = Field(
        ...,
        description="Pathway name as in PROGENy (e.g. `MAPK`, `PI3K`, `TNFa`, `TGFb`, `EGFR`, …). Case-insensitive.",
    )
    deseq_results: List[Dict[str, Any]] = Field(..., description="See `DecouplerRequest.deseq_results`.")
    n_genes: int = Field(50, ge=1, le=200, description="Max number of pathway genes to plot.")


class GeneSetVisualizationRequest(BaseModel):
    """Request for MSigDB GSEA running-score plot."""

    gene_set_name: str = Field(
        ...,
        description=(
            "MSigDB gene-set name (exact or partial match, case-insensitive). "
            "Examples: `HALLMARK_HYPOXIA`, `KEGG_APOPTOSIS`, `REACTOME_`…"
        ),
    )
    deseq_results: List[Dict[str, Any]] = Field(..., description="See `DecouplerRequest.deseq_results`.")


# ──────────────────────────────────────────────────────────────────────────────
# Response models
# ──────────────────────────────────────────────────────────────────────────────

class TFScoreItem(BaseModel):
    source: str = Field(..., description="Transcription factor symbol.")
    score: float = Field(..., description="ULM activity score.")
    p_value: Optional[float] = Field(None, description="Nominal p-value from ULM.")


class PathwayScoreItem(BaseModel):
    source: str = Field(..., description="Pathway name.")
    score: float = Field(..., description="MLM activity score.")
    p_value: Optional[float] = None


class CollectriResponse(BaseModel):
    success: bool
    n_tfs: int = Field(..., description="Number of TFs with computed activity scores.")
    tf_scores: List[Dict[str, Any]] = Field(..., description="Full TF activity table.")
    barplot_image: str = Field(..., description="Base64-encoded PNG barplot (top 25 TFs).")


class ProgenyResponse(BaseModel):
    success: bool
    n_pathways: int
    pathway_scores: List[Dict[str, Any]]
    barplot_image: str = Field(..., description="Base64-encoded PNG barplot of pathway activities.")


class MSigDBResponse(BaseModel):
    success: bool
    n_gene_sets: int
    enrichment_scores: List[Dict[str, Any]]
    dotplot_image: str = Field(..., description="Base64-encoded PNG dotplot.")


class ImageResponse(BaseModel):
    success: bool
    image_b64: str = Field(..., description="Base64-encoded PNG.")


# ──────────────────────────────────────────────────────────────────────────────
# Endpoints
# ──────────────────────────────────────────────────────────────────────────────

@router.post(
    "/collectri",
    response_model=CollectriResponse,
    summary="TF activity — CollecTRI (ULM)",
    responses={
        200: {"description": "TF activity scores and barplot rendered successfully."},
        500: {"description": "Analysis failed (check organism / gene overlap)."},
    },
)
async def run_collectri(request: DecouplerRequest):
    """
    Infer **transcription-factor activity** from a DEG result list using the
    [CollecTRI](https://www.nature.com/articles/s41467-023-41229-2) network
    and the **Univariate Linear Model (ULM)** method from decoupler-py.

    The log2FoldChange of each gene is treated as a signed expression signature.
    TF activity scores reflect how well the TF's target-gene expression profile
    matches the observed fold-change pattern.

    Returns the full activity table and a horizontal barplot of the top 25 TFs
    (top 15 activated + top 10 repressed).
    """
    try:
        deseq_df = pd.DataFrame(request.deseq_results)
        if "gene" in deseq_df.columns:
            deseq_df = deseq_df.set_index("gene")

        tf_scores, barplot_img = enrichment_service.run_collectri_analysis(
            deseq_df, organism=request.organism
        )

        return CollectriResponse(
            success=True,
            n_tfs=len(tf_scores),
            tf_scores=tf_scores.reset_index().to_dict(orient="records"),
            barplot_image=barplot_img,
        )

    except Exception as e:
        logger.error(f"CollecTRI analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/collectri/volcano",
    summary="TF target-gene volcano plot",
    responses={
        200: {"description": "Volcano plot rendered as base64 PNG."},
        500: {"description": "Rendering failed."},
    },
)
async def collectri_volcano(request: TFVisualizationRequest):
    """
    Volcano plot (**−log₁₀ p-value** vs **log₂FC**) for all DEGs, with
    CollecTRI target genes of `tf_name` highlighted in colour:

    - 🔴 **Red** — activated targets (CollecTRI weight > 0)
    - 🔵 **Blue** — repressed targets (CollecTRI weight < 0)
    - ⬜ Gray — non-targets (background)

    Top 12 target genes are labelled automatically.
    A dashed line marks p = 0.05.
    """
    try:
        deseq_df = pd.DataFrame(request.deseq_results)
        if "gene" in deseq_df.columns:
            deseq_df = deseq_df.set_index("gene")

        volcano_img = enrichment_service.plot_collectri_volcano(
            deseq_results=deseq_df,
            selected_tf=request.tf_name,
        )

        return {"success": True, "tf": request.tf_name, "volcano_image": volcano_img}

    except Exception as e:
        logger.error(f"CollecTRI volcano plot failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/collectri/network",
    summary="TF–target regulatory network (radial layout)",
    responses={
        200: {"description": "Network plot rendered as base64 PNG."},
        500: {"description": "Rendering failed."},
    },
)
async def collectri_network(request: TFVisualizationRequest):
    """
    Hub-and-spoke **radial network** showing a TF at the centre and its top
    `n_targets` target genes (by absolute CollecTRI weight) on the perimeter.

    Visual encoding:
    - **Edge colour**: red = activation, blue = repression
    - **Edge width**: proportional to |weight|
    - **Node colour**: log₂FC of the target gene in DESeq2 results (RdBu_r)
    - **Central node**: gold, labelled with TF name

    A colour-bar maps node colour → log₂FC values.
    """
    try:
        deseq_df = pd.DataFrame(request.deseq_results)
        if "gene" in deseq_df.columns:
            deseq_df = deseq_df.set_index("gene")

        network_img = enrichment_service.plot_collectri_network(
            selected_tf=request.tf_name,
            deseq_results=deseq_df,
            n_targets=request.n_targets,
        )

        return {"success": True, "tf": request.tf_name, "network_image": network_img}

    except Exception as e:
        logger.error(f"CollecTRI network plot failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/progeny",
    response_model=ProgenyResponse,
    summary="Pathway activity — PROGENy (MLM)",
    responses={
        200: {"description": "Pathway activity scores and barplot."},
        500: {"description": "Analysis failed."},
    },
)
async def run_progeny(request: DecouplerRequest):
    """
    Infer **signalling pathway activity** using
    [PROGENy](https://www.nature.com/articles/s41467-017-02391-6) footprint
    weights and the **Multivariate Linear Model (MLM)** method.

    14 major signalling pathways are scored:
    EGFR, Hypoxia, JAK-STAT, MAPK, NFkB, PI3K, p53, TGFb, TNFa, Trail,
    VEGF, WNT, Androgen, Estrogen.

    Returns activity scores and a horizontal barplot (red = activated,
    blue = repressed).
    """
    try:
        deseq_df = pd.DataFrame(request.deseq_results)
        if "gene" in deseq_df.columns:
            deseq_df = deseq_df.set_index("gene")

        pathway_scores, barplot_img = enrichment_service.run_progeny_analysis(
            deseq_df, organism=request.organism
        )

        return ProgenyResponse(
            success=True,
            n_pathways=len(pathway_scores),
            pathway_scores=pathway_scores.reset_index().to_dict(orient="records"),
            barplot_image=barplot_img,
        )

    except Exception as e:
        logger.error(f"PROGENy analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/progeny/targets",
    summary="PROGENy pathway target-gene dual barplot",
    responses={
        200: {"description": "Dual barplot (PROGENy weight + DESeq2 log₂FC)."},
        500: {"description": "Rendering failed."},
    },
)
async def progeny_targets(request: PathwayVisualizationRequest):
    """
    Side-by-side horizontal barplot for the selected PROGENy pathway:

    - **Left panel**: PROGENy footprint weights per gene (signed model coefficients)
    - **Right panel**: log₂FoldChange of those same genes in the DESeq2 results

    Genes are ordered by |PROGENy weight| descending, up to `n_genes` entries.
    The pathway name is matched **case-insensitively**; partial names are not supported.
    If the pathway is not found, the response includes a list of available pathways.
    """
    try:
        deseq_df = pd.DataFrame(request.deseq_results)
        if "gene" in deseq_df.columns:
            deseq_df = deseq_df.set_index("gene")

        targets_img = enrichment_service.plot_progeny_targets(
            pathway=request.pathway_name,
            deseq_results=deseq_df,
            n_genes=request.n_genes,
        )

        return {"success": True, "pathway": request.pathway_name, "targets_image": targets_img}

    except Exception as e:
        logger.error(f"PROGENy targets plot failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/msigdb",
    response_model=MSigDBResponse,
    summary="MSigDB Hallmark ORA (Over-Representation Analysis)",
    responses={
        200: {"description": "Enrichment scores and dotplot."},
        500: {"description": "Analysis failed."},
    },
)
async def run_msigdb(request: DecouplerRequest):
    """
    Run **Over-Representation Analysis** on the MSigDB Hallmark collection
    (50 gene sets) using the decoupler-py `run_ora` method.

    The log2FoldChange is used as a ranked input; the −log₁₀(p-value) is
    returned as the enrichment score.

    Returns the top 25 enriched gene sets and a dot-plot.
    """
    try:
        deseq_df = pd.DataFrame(request.deseq_results)
        if "gene" in deseq_df.columns:
            deseq_df = deseq_df.set_index("gene")

        enrichment_scores, dotplot_img = enrichment_service.run_msigdb_analysis(
            deseq_df, gene_sets=request.collection
        )

        return MSigDBResponse(
            success=True,
            n_gene_sets=len(enrichment_scores),
            enrichment_scores=enrichment_scores.reset_index().to_dict(orient="records"),
            dotplot_image=dotplot_img,
        )

    except Exception as e:
        logger.error(f"MSigDB analysis failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/msigdb/running-score",
    summary="GSEA running enrichment score plot",
    responses={
        200: {"description": "Running-score plot rendered as base64 PNG."},
        500: {"description": "Rendering failed."},
    },
)
async def msigdb_running_score(request: GeneSetVisualizationRequest):
    """
    **GSEA-style running enrichment score** (Kolmogorov–Smirnov) for a selected
    MSigDB gene set.

    Genes are pre-ranked by **log₂FoldChange** (descending). The running sum
    increments by `1/n_hits` when a set member is encountered and decrements
    by `1/n_miss` otherwise. The enrichment score (ES) is the maximum absolute
    deviation.

    The figure has two panels:
    1. Running score curve with red/blue fill and ES annotation
    2. Hit strip showing gene-set member positions in the ranked list

    `gene_set_name` is matched **case-insensitively** (exact first, then partial).
    """
    try:
        deseq_df = pd.DataFrame(request.deseq_results)
        if "gene" in deseq_df.columns:
            deseq_df = deseq_df.set_index("gene")

        running_score_img = enrichment_service.plot_msigdb_running_score(
            gene_set=request.gene_set_name,
            deseq_results=deseq_df,
        )

        return {
            "success": True,
            "gene_set": request.gene_set_name,
            "running_score_image": running_score_img,
        }

    except Exception as e:
        logger.error(f"MSigDB running score plot failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
