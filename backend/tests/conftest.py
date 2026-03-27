"""
Shared pytest fixtures for MASLDatlas backend tests.
"""
import numpy as np
import pandas as pd
import pytest


# ─── Minimal AnnData fixture ─────────────────────────────────────────────────

@pytest.fixture
def small_adata():
    """20-cell, 15-gene AnnData with CellType metadata and a tiny UMAP."""
    try:
        import anndata as ad
        import scipy.sparse as sp
    except ImportError:
        pytest.skip("anndata not installed")

    n_obs, n_vars = 20, 15
    rng = np.random.default_rng(42)
    X = sp.csr_matrix(rng.integers(0, 10, size=(n_obs, n_vars)).astype(np.float32))
    obs = pd.DataFrame(
        {
            "CellType": (["Hepatocyte"] * 10 + ["HSC"] * 10),
        },
        index=[f"cell_{i}" for i in range(n_obs)],
    )
    var = pd.DataFrame(
        {"gene_symbol": [f"Gene{i}" for i in range(n_vars)]},
        index=[f"Gene{i}" for i in range(n_vars)],
    )
    adata = ad.AnnData(X=X, obs=obs, var=var)
    adata.obsm["X_umap"] = rng.random((n_obs, 2))
    return adata


# ─── Minimal DESeq-style DataFrame fixture ──────────────────────────────────

@pytest.fixture
def small_deseq():
    """
    50-gene pseudo-DESeq2 result DataFrame indexed by gene symbol,
    with log2FoldChange and pvalue columns.
    """
    rng = np.random.default_rng(0)
    n = 50
    genes = [f"Gene{i}" for i in range(n)]
    lfc = rng.standard_normal(n) * 2          # range ~ -6 to 6
    pval = rng.uniform(0, 0.1, n)
    pdf = pd.DataFrame({"log2FoldChange": lfc, "pvalue": pval}, index=genes)
    pdf.index.name = "gene"
    return pdf
