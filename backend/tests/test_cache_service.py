"""
Unit tests for CacheService (cache_service.py).

Redis is fully mocked so tests run without a live Redis instance.
"""
import hashlib
from unittest.mock import MagicMock, patch

import numpy as np
import pandas as pd
import pytest


# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

def _make_cache(redis_enabled: bool = False, **kwargs):
    """Create a CacheService with Redis disabled (pure in-memory fallback)."""
    from app.services.cache_service import CacheService

    return CacheService(maxsize=10, ttl=60, redis_enabled=redis_enabled, **kwargs)


# ──────────────────────────────────────────────────────────────────────────────
# Key generation
# ──────────────────────────────────────────────────────────────────────────────

class TestKeyGeneration:
    def test_same_inputs_give_same_key(self):
        svc = _make_cache()
        k1 = svc._generate_filter_key("human", "GSE181483", ["Hepatocyte"])
        k2 = svc._generate_filter_key("human", "GSE181483", ["Hepatocyte"])
        assert k1 == k2

    def test_cluster_order_is_normalised(self):
        svc = _make_cache()
        k1 = svc._generate_filter_key("human", "GSE181483", ["B", "A"])
        k2 = svc._generate_filter_key("human", "GSE181483", ["A", "B"])
        assert k1 == k2

    def test_different_inputs_give_different_keys(self):
        svc = _make_cache()
        k1 = svc._generate_filter_key("human", "GSE181483")
        k2 = svc._generate_filter_key("mouse", "GSE181483")
        assert k1 != k2

    def test_key_length_is_16_chars(self):
        svc = _make_cache()
        k = svc._generate_filter_key("human", "GSE181483")
        assert len(k) == 16


# ──────────────────────────────────────────────────────────────────────────────
# AnnData (in-memory) cache
# ──────────────────────────────────────────────────────────────────────────────

class TestAnnDataCache:
    def test_miss_returns_none(self):
        svc = _make_cache()
        result = svc.get_filtered_dataset("human", "GSE000000")
        assert result is None

    def test_store_and_retrieve(self, small_adata):
        svc = _make_cache()
        svc.set_filtered_dataset(small_adata, "human", "GSE181483", ["Hepatocyte"])
        hit = svc.get_filtered_dataset("human", "GSE181483", ["Hepatocyte"])
        assert hit is not None
        assert hit.n_obs == small_adata.n_obs

    def test_stored_value_is_a_copy(self, small_adata):
        """Mutation of the original must not affect the cached object."""
        svc = _make_cache()
        svc.set_filtered_dataset(small_adata, "human", "ds1")
        # Mutate original obs
        small_adata.obs["new_col"] = 1
        hit = svc.get_filtered_dataset("human", "ds1")
        assert "new_col" not in hit.obs.columns

    def test_eviction_after_maxsize(self, small_adata):
        svc = _make_cache()  # maxsize=10
        for i in range(12):
            svc.set_filtered_dataset(small_adata, "human", f"ds{i}")
        # Cache size should not exceed maxsize
        assert len(svc._filtered_cache) <= 10

    def test_key_returned_matches_later_get(self, small_adata):
        svc = _make_cache()
        key = svc.set_filtered_dataset(small_adata, "mouse", "GSE145086")
        expected = svc._generate_filter_key("mouse", "GSE145086")
        assert key == expected


# ──────────────────────────────────────────────────────────────────────────────
# Results cache (in-memory fallback, Redis disabled)
# ──────────────────────────────────────────────────────────────────────────────

class TestResultsCache:
    def test_miss_returns_none(self):
        svc = _make_cache()
        assert svc.get_result("nonexistent_key") is None

    def test_set_and_get_dict(self):
        svc = _make_cache()
        payload = {"score": 3.14, "genes": ["TP53", "MYC"]}
        svc.set_result("my_key", payload)
        assert svc.get_result("my_key") == payload

    def test_set_and_get_dataframe(self):
        svc = _make_cache()
        df = pd.DataFrame({"a": [1, 2], "b": [3, 4]})
        svc.set_result("df_key", df)
        result = svc.get_result("df_key")
        assert isinstance(result, pd.DataFrame)
        pd.testing.assert_frame_equal(result, df)

    def test_delete_result(self):
        svc = _make_cache()
        svc.set_result("del_key", 42)
        svc.delete_result("del_key")
        assert svc.get_result("del_key") is None


# ──────────────────────────────────────────────────────────────────────────────
# clear_all
# ──────────────────────────────────────────────────────────────────────────────

class TestClearAll:
    def test_clear_empties_filtered_cache(self, small_adata):
        svc = _make_cache()
        svc.set_filtered_dataset(small_adata, "human", "ds1")
        svc.clear_all()
        assert len(svc._filtered_cache) == 0

    def test_clear_empties_results_cache(self):
        svc = _make_cache()
        svc.set_result("k", "v")
        svc.clear_all()
        assert svc.get_result("k") is None


# ──────────────────────────────────────────────────────────────────────────────
# Stats
# ──────────────────────────────────────────────────────────────────────────────

class TestCacheStats:
    def test_stats_structure(self, small_adata):
        svc = _make_cache()
        svc.set_filtered_dataset(small_adata, "human", "ds1")
        svc.set_result("r1", {"x": 1})
        stats = svc.get_cache_stats()
        assert "filtered_datasets" in stats
        assert "results" in stats
        assert stats["filtered_datasets"]["size"] == 1

    def test_stats_reports_in_memory_backend(self):
        svc = _make_cache(redis_enabled=False)
        stats = svc.get_cache_stats()
        assert stats["results"]["backend"] == "memory_fallback"


# ──────────────────────────────────────────────────────────────────────────────
# Redis path — mocked
# ──────────────────────────────────────────────────────────────────────────────

class TestRedisResultsCache:
    """Test _RedisResultsCache encode/decode round-trip via mocked Redis client."""

    def test_encode_decode_roundtrip(self):
        from app.services.cache_service import _RedisResultsCache

        cache = _RedisResultsCache(redis_url="redis://localhost:6379", ttl=60)
        payload = {"answer": 42, "items": [1, 2, 3]}
        encoded = cache._encode(payload)
        assert isinstance(encoded, bytes)
        decoded = cache._decode(encoded)
        assert decoded == payload

    def test_redis_set_get_via_mock(self):
        from app.services.cache_service import _RedisResultsCache

        mock_client = MagicMock()
        cache = _RedisResultsCache.__new__(_RedisResultsCache)
        cache._ttl = 60
        cache._redis_ok = True
        cache._client = mock_client
        from cachetools import TTLCache
        cache._fallback = TTLCache(maxsize=50, ttl=60)

        # Simulate Redis returning encoded value
        payload = {"score": 9.9}
        encoded = cache._encode(payload)
        mock_client.get.return_value = encoded

        cache.set("key1", payload)
        result = cache.get("key1")
        assert result == payload

    def test_redis_connection_failure_falls_back(self):
        """When Redis raises, the cache must fall back silently."""
        from app.services.cache_service import _RedisResultsCache

        mock_client = MagicMock()
        mock_client.get.side_effect = Exception("connection refused")

        cache = _RedisResultsCache.__new__(_RedisResultsCache)
        cache._ttl = 60
        cache._redis_ok = True
        cache._client = mock_client
        from cachetools import TTLCache
        cache._fallback = TTLCache(maxsize=50, ttl=60)

        # Should not raise
        result = cache.get("key_x")
        assert result is None
        # redis_ok should be set to False after the error
        assert cache._redis_ok is False

    def test_stats_redis_connected(self):
        from app.services.cache_service import _RedisResultsCache

        mock_client = MagicMock()
        mock_client.info.return_value = {"used_memory_human": "1.5M"}
        mock_client.dbsize.return_value = 7

        cache = _RedisResultsCache.__new__(_RedisResultsCache)
        cache._ttl = 60
        cache._redis_ok = True
        cache._client = mock_client
        from cachetools import TTLCache
        cache._fallback = TTLCache(maxsize=50, ttl=60)

        s = cache.stats()
        assert s["backend"] == "redis"
        assert s["connected"] is True
        assert s["keys_total_db"] == 7
