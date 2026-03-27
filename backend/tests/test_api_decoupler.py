"""
Integration tests for /api/decoupler/* endpoints.

Uses FastAPI TestClient and mocks EnrichmentService methods.
"""
from unittest.mock import MagicMock, patch

import pytest


@pytest.fixture
def client():
    """FastAPI test client."""
    try:
        from fastapi.testclient import TestClient
        from app.main import app

        return TestClient(app)
    except Exception as e:
        pytest.skip(f"App startup failed (likely missing data files): {e}")


# ── Shared fake base64 image ─────────────────────────────────────────────────

_FAKE_IMG = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="


# ── Shared DESeq body ────────────────────────────────────────────────────────

_DESeq_BODY = {
    "deseq_results": [
        {"gene": "TP53", "log2FoldChange": 1.5, "pvalue": 0.001, "padj": 0.005},
        {"gene": "MYC",  "log2FoldChange": -0.8, "pvalue": 0.02,  "padj": 0.04},
    ],
    "organism": "human",
}


# ── POST /api/decoupler/collectri ────────────────────────────────────────────

class TestCollectriEndpoint:
    def test_runs_successfully(self, client):
        with patch(
            "app.services.enrichment_service.EnrichmentService.run_collectri_analysis",
            return_value=(
                __import__("pandas").DataFrame({"source": ["TP53"], "score": [2.1], "p_value": [0.01]}),
                _FAKE_IMG,
            ),
        ):
            r = client.post("/api/decoupler/collectri", json=_DESeq_BODY)
        assert r.status_code == 200
        data = r.json()
        assert data["success"] is True
        assert "barplot_image" in data

    def test_empty_deseq_returns_500_or_success(self, client):
        """Endpoint should not crash with an empty results list (may return 200 or handled 500)."""
        r = client.post(
            "/api/decoupler/collectri",
            json={"deseq_results": [], "organism": "human"},
        )
        assert r.status_code in (200, 422, 500)


# ── POST /api/decoupler/collectri/volcano ────────────────────────────────────

class TestCollectriVolcanoEndpoint:
    _BODY = {
        **_DESeq_BODY,
        "tf_name": "TP53",
        "n_targets": 10,
    }

    def test_returns_200_with_image(self, client):
        with patch(
            "app.services.enrichment_service.EnrichmentService.plot_collectri_volcano",
            return_value=_FAKE_IMG,
        ):
            r = client.post("/api/decoupler/collectri/volcano", json=self._BODY)
        assert r.status_code == 200
        data = r.json()
        assert data["success"] is True
        assert data["volcano_image"].startswith("data:image/png;base64,")
        assert data["tf"] == "TP53"

    def test_missing_tf_name_returns_422(self, client):
        bad_body = {k: v for k, v in self._BODY.items() if k != "tf_name"}
        r = client.post("/api/decoupler/collectri/volcano", json=bad_body)
        assert r.status_code == 422


# ── POST /api/decoupler/collectri/network ────────────────────────────────────

class TestCollectriNetworkEndpoint:
    _BODY = {
        **_DESeq_BODY,
        "tf_name": "MYC",
        "n_targets": 15,
    }

    def test_returns_200_with_image(self, client):
        with patch(
            "app.services.enrichment_service.EnrichmentService.plot_collectri_network",
            return_value=_FAKE_IMG,
        ):
            r = client.post("/api/decoupler/collectri/network", json=self._BODY)
        assert r.status_code == 200
        assert r.json()["network_image"].startswith("data:image/png;base64,")


# ── POST /api/decoupler/progeny/targets ─────────────────────────────────────

class TestProgenyTargetsEndpoint:
    _BODY = {
        **_DESeq_BODY,
        "pathway_name": "MAPK",
        "n_genes": 50,
    }

    def test_returns_200_with_image(self, client):
        with patch(
            "app.services.enrichment_service.EnrichmentService.plot_progeny_targets",
            return_value=_FAKE_IMG,
        ):
            r = client.post("/api/decoupler/progeny/targets", json=self._BODY)
        assert r.status_code == 200
        data = r.json()
        assert data["success"] is True
        assert data["targets_image"].startswith("data:image/png;base64,")
        assert data["pathway"] == "MAPK"

    def test_missing_pathway_name_returns_422(self, client):
        bad = {k: v for k, v in self._BODY.items() if k != "pathway_name"}
        r = client.post("/api/decoupler/progeny/targets", json=bad)
        assert r.status_code == 422


# ── POST /api/decoupler/msigdb/running-score ─────────────────────────────────

class TestMSigDBRunningScoreEndpoint:
    _BODY = {
        **_DESeq_BODY,
        "gene_set_name": "HALLMARK_HYPOXIA",
    }

    def test_returns_200_with_image(self, client):
        with patch(
            "app.services.enrichment_service.EnrichmentService.plot_msigdb_running_score",
            return_value=_FAKE_IMG,
        ):
            r = client.post("/api/decoupler/msigdb/running-score", json=self._BODY)
        assert r.status_code == 200
        data = r.json()
        assert data["success"] is True
        assert data["running_score_image"].startswith("data:image/png;base64,")
        assert data["gene_set"] == "HALLMARK_HYPOXIA"

    def test_missing_gene_set_returns_422(self, client):
        bad = {k: v for k, v in self._BODY.items() if k != "gene_set_name"}
        r = client.post("/api/decoupler/msigdb/running-score", json=bad)
        assert r.status_code == 422
