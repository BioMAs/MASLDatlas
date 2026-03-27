"""
MASLDatlas Backend API
FastAPI application for multi-species scRNA-seq analysis
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from loguru import logger
import sys

from app.core.config import settings
from app.api import datasets, analysis, visualization, enrichment, pseudobulk, decoupler

# Configure logging
logger.remove()
logger.add(
    sys.stdout,
    format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan> - <level>{message}</level>",
    level="INFO"
)

# ── Swagger tag descriptions ──────────────────────────────────────────────────
TAGS_METADATA = [
    {
        "name": "datasets",
        "description": (
            "Load and manage single-cell datasets (`.h5ad`). "
            "Supports Human (GSE181483), Mouse (GSE145086), Zebrafish (GSE181987) "
            "and integrated cross-species atlases. "
            "All analysis endpoints require an active **session_id** obtained here."
        ),
    },
    {
        "name": "analysis",
        "description": (
            "Core single-cell analysis: **differential gene expression** (Wilcoxon, t-test, logistic "
            "regression), **marker gene detection**, and **gene–gene correlation**. "
            "Results feed directly into enrichment and Decoupler panels."
        ),
    },
    {
        "name": "visualization",
        "description": (
            "Backend-rendered plots returned as base64 PNG strings: "
            "UMAP (coloured by cell-type, gene or continuous metadata), "
            "violin plots per gene and per group, dot-plots, and spatial projections."
        ),
    },
    {
        "name": "enrichment",
        "description": (
            "Functional enrichment analysis with **gseapy / Enrichr API**: "
            "GO Biological Process, KEGG, Reactome, WikiPathways. "
            "Accepts any gene list and returns top 50 significant terms (adj. p < 0.05)."
        ),
    },
    {
        "name": "pseudobulk",
        "description": (
            "Pseudo-bulk sum aggregation per cell-type followed by **PyDESeq2** "
            "differential expression. Produces normalised count matrices, "
            "MA-plots and PCA plots of pseudo-bulk profiles."
        ),
    },
    {
        "name": "decoupler",
        "description": (
            "Transcription-factor and pathway **activity inference** via the decoupler-py "
            "framework.\n\n"
            "| Method | Resource | Model |\n"
            "|--------|----------|-------|\n"
            "| CollecTRI | TF–target network | ULM (Univariate Linear Model) |\n"
            "| PROGENy | Pathway footprint weights | MLM (Multivariate Linear Model) |\n"
            "| MSigDB | Hallmark / curated gene sets | ORA (Over-Representation) |\n\n"
            "Visualisation endpoints generate:\n"
            "- **CollecTRI volcano**: target-gene regulation plot per TF\n"
            "- **CollecTRI network**: hub-and-spoke TF–target radial layout\n"
            "- **PROGENy targets**: dual barplot (weight vs log2FC per pathway)\n"
            "- **MSigDB running score**: GSEA-style enrichment curve"
        ),
    },
]

# Initialize FastAPI app
app = FastAPI(
    title="MASLDatlas API",
    description=(
        "# MASLDatlas — Multi-Species scRNA-seq Atlas API\n\n"
        "REST API powering the **MASLDatlas** platform for interactive exploration of "
        "single-cell transcriptomics data in **MASLD** (Metabolic Associated Steatotic Liver Disease).\n\n"
        "## Workflow\n"
        "1. **Load a dataset** → `POST /api/datasets/load` → receive a `session_id`\n"
        "2. **Filter clusters** → `POST /api/datasets/filter/{session_id}`\n"
        "3. **Run DGE** → `POST /api/analysis/differential-expression/{session_id}`\n"
        "4. **Enrich / Decoupler** → pass DEG results to `/api/enrichment` or `/api/decoupler`\n\n"
        "## Authentication\nNo authentication required in development. "
        "Production deploys behind a reverse proxy."
    ),
    version="2.0.0",
    openapi_tags=TAGS_METADATA,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    contact={
        "name": "MASLDatlas Team",
        "url": "https://github.com/tdarde/MASLDatlas",
    },
    license_info={
        "name": "MIT",
    },
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(datasets.router, prefix="/api/datasets", tags=["datasets"])
app.include_router(analysis.router, prefix="/api/analysis", tags=["analysis"])
app.include_router(visualization.router, prefix="/api/visualization", tags=["visualization"])
app.include_router(enrichment.router, prefix="/api/enrichment", tags=["enrichment"])
app.include_router(pseudobulk.router, prefix="/api/pseudobulk", tags=["pseudobulk"])
app.include_router(decoupler.router, prefix="/api/decoupler", tags=["decoupler"])

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "MASLDatlas API v2.0",
        "docs": "/api/docs",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": "2.0.0"
    }

@app.on_event("startup")
async def startup_event():
    """Initialize resources on startup"""
    logger.info("🚀 Starting MASLDatlas API v2.0")
    logger.info(f"📁 Data directory: {settings.DATA_DIR}")
    logger.info(f"🔧 Environment: {settings.ENVIRONMENT}")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("👋 Shutting down MASLDatlas API")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
