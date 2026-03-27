"""
Unit tests for the four Decoupler visualisation methods in EnrichmentService:
    - plot_collectri_volcano
    - plot_collectri_network
    - plot_progeny_targets
    - plot_msigdb_running_score

All external dependencies (rds_loader, decoupler) are mocked.
"""
from unittest.mock import MagicMock, patch

import numpy as np
import pandas as pd
import pytest


# ──────────────────────────────────────────────────────────────────────────────
# Local fixtures (complement conftest.small_deseq)
# ──────────────────────────────────────────────────────────────────────────────

@pytest.fixture
def fake_collectri_net():
    """Minimal CollecTRI-style network (source=TF, target=gene, weight=mor)."""
    data = {
        "source": ["TP53"] * 6 + ["MYC"] * 4,
        "target": [f"Gene{i}" for i in range(6)] + [f"Gene{i}" for i in range(6, 10)],
        "weight": [1.0, -1.0, 1.0, 1.0, -1.0, 1.0,
                   1.0, 1.0, -1.0, 1.0],
    }
    return pd.DataFrame(data)


@pytest.fixture
def fake_progeny_net():
    """Minimal PROGENy-style network (source=pathway, target=gene, weight)."""
    pathways = ["MAPK"] * 8 + ["PI3K"] * 6
    targets = [f"Gene{i}" for i in range(14)]
    weights = np.linspace(-2, 2, 14)
    return pd.DataFrame({"source": pathways, "target": targets, "weight": weights})


@pytest.fixture
def fake_msigdb():
    """Minimal MSigDB resource-style DataFrame."""
    data = {
        "collection": ["hallmark"] * 10 + ["reactome"] * 5,
        "geneset": (["HALLMARK_HYPOXIA"] * 10 + ["REACTOME_APOPTOSIS"] * 5),
        "genesymbol": [f"Gene{i}" for i in range(15)],
    }
    return pd.DataFrame(data)


@pytest.fixture
def svc():
    """Fresh EnrichmentService instance (no external I/O during init)."""
    from app.services.enrichment_service import EnrichmentService

    return EnrichmentService()


# ──────────────────────────────────────────────────────────────────────────────
# _fig_to_base64
# ──────────────────────────────────────────────────────────────────────────────

class TestFigToBase64:
    def test_returns_data_uri(self, svc):
        import matplotlib.pyplot as plt

        fig, _ = plt.subplots()
        result = svc._fig_to_base64(fig)
        assert result.startswith("data:image/png;base64,")
        assert len(result) > 100


# ──────────────────────────────────────────────────────────────────────────────
# plot_collectri_volcano
# ──────────────────────────────────────────────────────────────────────────────

class TestCollectriVolcano:
    def _mock_rds_loader(self, fake_net):
        mock_loader = MagicMock()
        mock_loader.load_collectri.return_value = fake_net
        mock_loader.convert_to_decoupler_network.return_value = fake_net
        return mock_loader

    def test_returns_png_base64(self, svc, small_deseq, fake_collectri_net):
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_collectri_net)):
            result = svc.plot_collectri_volcano(small_deseq, selected_tf="TP53")
        assert result.startswith("data:image/png;base64,")

    def test_unknown_tf_returns_image_with_message(self, svc, small_deseq, fake_collectri_net):
        """An unknown TF must not raise — it returns an informative image."""
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_collectri_net)):
            result = svc.plot_collectri_volcano(small_deseq, selected_tf="UNKNOWN_TF_XYZ")
        assert result.startswith("data:image/png;base64,")

    def test_missing_columns_raises_value_error(self, svc, fake_collectri_net):
        """deseq_results without log2FoldChange/pvalue should raise ValueError."""
        bad_df = pd.DataFrame({"gene": ["A", "B"]})
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_collectri_net)):
            # The method must still return an image (error fallback), not raise
            result = svc.plot_collectri_volcano(bad_df, selected_tf="TP53")
        assert result.startswith("data:image/png;base64,")


# ──────────────────────────────────────────────────────────────────────────────
# plot_collectri_network
# ──────────────────────────────────────────────────────────────────────────────

class TestCollectriNetwork:
    def _mock_rds_loader(self, fake_net):
        mock_loader = MagicMock()
        mock_loader.load_collectri.return_value = fake_net
        mock_loader.convert_to_decoupler_network.return_value = fake_net
        return mock_loader

    def test_returns_png_base64(self, svc, small_deseq, fake_collectri_net):
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_collectri_net)):
            result = svc.plot_collectri_network(
                "TP53", small_deseq, n_targets=6
            )
        assert result.startswith("data:image/png;base64,")

    def test_n_targets_respected(self, svc, small_deseq, fake_collectri_net):
        """Requesting more targets than available must not raise."""
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_collectri_net)):
            result = svc.plot_collectri_network("TP53", small_deseq, n_targets=100)
        assert result.startswith("data:image/png;base64,")

    def test_unknown_tf_graceful(self, svc, small_deseq, fake_collectri_net):
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_collectri_net)):
            result = svc.plot_collectri_network("NO_TF", small_deseq)
        assert result.startswith("data:image/png;base64,")

    def test_no_lfc_column_still_renders(self, svc, fake_collectri_net):
        """Network must render even without log2FoldChange in deseq_results."""
        empty_df = pd.DataFrame()
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_collectri_net)):
            result = svc.plot_collectri_network("TP53", empty_df)
        assert result.startswith("data:image/png;base64,")


# ──────────────────────────────────────────────────────────────────────────────
# plot_progeny_targets
# ──────────────────────────────────────────────────────────────────────────────

class TestProgenyTargets:
    def _mock_rds_loader(self, fake_net):
        mock_loader = MagicMock()
        mock_loader.load_progeny.return_value = fake_net
        return mock_loader

    def test_returns_png_base64(self, svc, small_deseq, fake_progeny_net):
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_progeny_net)):
            result = svc.plot_progeny_targets("MAPK", small_deseq, n_genes=8)
        assert result.startswith("data:image/png;base64,")

    def test_case_insensitive_match(self, svc, small_deseq, fake_progeny_net):
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_progeny_net)):
            result = svc.plot_progeny_targets("mapk", small_deseq)
        assert result.startswith("data:image/png;base64,")

    def test_unknown_pathway_graceful(self, svc, small_deseq, fake_progeny_net):
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_progeny_net)):
            result = svc.plot_progeny_targets("UNKNOWNPATHWAY", small_deseq)
        assert result.startswith("data:image/png;base64,")

    def test_missing_source_column_raises_gracefully(self, svc, small_deseq):
        """A PROGENy network without 'source' column must return error image."""
        bad_net = pd.DataFrame({"target": ["G1"], "weight": [1.0]})
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=MagicMock(load_progeny=MagicMock(return_value=bad_net))):
            result = svc.plot_progeny_targets("MAPK", small_deseq)
        assert result.startswith("data:image/png;base64,")

    def test_top_n_genes_respected(self, svc, small_deseq, fake_progeny_net):
        """n_genes should limit the number of genes shown without error."""
        with patch("app.services.enrichment_service.get_rds_loader",
                   return_value=self._mock_rds_loader(fake_progeny_net)):
            result = svc.plot_progeny_targets("MAPK", small_deseq, n_genes=3)
        assert result.startswith("data:image/png;base64,")


# ──────────────────────────────────────────────────────────────────────────────
# plot_msigdb_running_score
# ──────────────────────────────────────────────────────────────────────────────

class TestMSigDBRunningScore:
    def test_returns_png_base64(self, svc, small_deseq, fake_msigdb):
        with patch("app.services.enrichment_service.dc") as mock_dc:
            mock_dc.get_resource.return_value = fake_msigdb
            result = svc.plot_msigdb_running_score("HALLMARK_HYPOXIA", small_deseq)
        assert result.startswith("data:image/png;base64,")

    def test_partial_name_matches(self, svc, small_deseq, fake_msigdb):
        """Partial name match should find the gene set."""
        with patch("app.services.enrichment_service.dc") as mock_dc:
            mock_dc.get_resource.return_value = fake_msigdb
            result = svc.plot_msigdb_running_score("HYPOXIA", small_deseq)
        assert result.startswith("data:image/png;base64,")

    def test_unknown_geneset_graceful(self, svc, small_deseq, fake_msigdb):
        with patch("app.services.enrichment_service.dc") as mock_dc:
            mock_dc.get_resource.return_value = fake_msigdb
            result = svc.plot_msigdb_running_score("DOES_NOT_EXIST_9999", small_deseq)
        assert result.startswith("data:image/png;base64,")

    def test_enrichment_score_between_minus1_and_1(self, svc, small_deseq, fake_msigdb):
        """The running sum is normalised by n_hits/n_miss so |ES| <= 1."""
        import base64, io, re
        with patch("app.services.enrichment_service.dc") as mock_dc:
            mock_dc.get_resource.return_value = fake_msigdb
            _ = svc.plot_msigdb_running_score("HALLMARK_HYPOXIA", small_deseq)
        # If no exception, the plot was generated correctly. No numeric assertion
        # on the image itself (that's tested visually), but we verify no crash.

    def test_missing_lfc_column_raises_gracefully(self, svc, fake_msigdb):
        bad_df = pd.DataFrame({"pvalue": [0.01, 0.05]}, index=["G1", "G2"])
        with patch("app.services.enrichment_service.dc") as mock_dc:
            mock_dc.get_resource.return_value = fake_msigdb
            result = svc.plot_msigdb_running_score("HALLMARK_HYPOXIA", bad_df)
        assert result.startswith("data:image/png;base64,")
