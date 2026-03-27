"""
Hybrid cache service:
- AnnData (filtered datasets): in-process TTLCache (objects too large for Redis).
- Analysis results (small serialisable objects): Redis with pickle+zlib,
  transparent fallback to TTLCache when Redis is unavailable.
"""
from __future__ import annotations

import hashlib
import pickle
import zlib
from typing import Any, Dict, List, Optional

import anndata as ad
from cachetools import TTLCache
from loguru import logger

# Redis is optional — import guarded so the service starts without it
try:
    import redis as _redis_module

    _REDIS_AVAILABLE = True
except ImportError:
    _REDIS_AVAILABLE = False
    logger.warning("⚠️  redis-py not installed – results cache will use in-memory fallback")


# ──────────────────────────────────────────────────────────────────────────────
# Redis results cache helper
# ──────────────────────────────────────────────────────────────────────────────

class _RedisResultsCache:
    """
    Thin wrapper around redis.Redis that serialises values with pickle+zlib.

    Falls back silently to an in-memory TTLCache on any Redis error so the
    application never crashes due to a cache backend issue.
    """

    _PREFIX = "masldatlas:results:"

    def __init__(self, redis_url: str, ttl: int, fallback_maxsize: int = 200) -> None:
        self._ttl = ttl
        self._fallback: TTLCache = TTLCache(maxsize=fallback_maxsize, ttl=ttl)
        self._client: Optional[Any] = None
        self._redis_ok = False

        if not _REDIS_AVAILABLE:
            logger.info("📦 Results cache: in-memory (redis-py unavailable)")
            return

        try:
            client = _redis_module.Redis.from_url(
                redis_url,
                socket_connect_timeout=2,
                socket_timeout=2,
                decode_responses=False,
            )
            client.ping()
            self._client = client
            self._redis_ok = True
            logger.info(f"✅ Redis results cache connected: {redis_url}")
        except Exception as exc:
            logger.warning(f"⚠️  Redis unavailable ({exc}) – falling back to in-memory results cache")

    # ------------------------------------------------------------------
    def _encode(self, value: Any) -> bytes:
        return zlib.compress(pickle.dumps(value, protocol=pickle.HIGHEST_PROTOCOL), level=6)

    def _decode(self, raw: bytes) -> Any:
        return pickle.loads(zlib.decompress(raw))

    def _full_key(self, key: str) -> str:
        return f"{self._PREFIX}{key}"

    # ------------------------------------------------------------------
    def get(self, key: str) -> Optional[Any]:
        if self._redis_ok and self._client is not None:
            try:
                raw = self._client.get(self._full_key(key))
                if raw is not None:
                    logger.debug(f"✅ Redis HIT: {key}")
                    return self._decode(raw)
                logger.debug(f"❌ Redis MISS: {key}")
                return None
            except Exception as exc:
                logger.warning(f"⚠️  Redis GET error ({exc}), falling back to memory")
                self._redis_ok = False

        # In-memory fallback
        return self._fallback.get(key)

    def set(self, key: str, value: Any) -> None:
        if self._redis_ok and self._client is not None:
            try:
                encoded = self._encode(value)
                self._client.setex(self._full_key(key), self._ttl, encoded)
                logger.debug(f"💾 Redis SET: {key} ({len(encoded):,} bytes compressed)")
                return
            except Exception as exc:
                logger.warning(f"⚠️  Redis SET error ({exc}), falling back to memory")
                self._redis_ok = False

        # In-memory fallback
        self._fallback[key] = value
        logger.debug(f"💾 Memory results SET: {key}")

    def delete(self, key: str) -> None:
        if self._redis_ok and self._client is not None:
            try:
                self._client.delete(self._full_key(key))
                return
            except Exception:
                pass
        self._fallback.pop(key, None)

    def clear(self) -> None:
        if self._redis_ok and self._client is not None:
            try:
                pattern = f"{self._PREFIX}*"
                keys = self._client.keys(pattern)
                if keys:
                    self._client.delete(*keys)
            except Exception as exc:
                logger.warning(f"⚠️  Redis CLEAR error: {exc}")
        self._fallback.clear()

    def stats(self) -> Dict:
        if self._redis_ok and self._client is not None:
            try:
                info = self._client.info("memory")
                count = self._client.dbsize()
                return {
                    "backend": "redis",
                    "keys_total_db": count,
                    "used_memory_human": info.get("used_memory_human", "n/a"),
                    "connected": True,
                }
            except Exception:
                pass
        return {
            "backend": "memory_fallback",
            "size": len(self._fallback),
            "maxsize": self._fallback.maxsize,
            "connected": False,
        }


# ──────────────────────────────────────────────────────────────────────────────
# Main CacheService
# ──────────────────────────────────────────────────────────────────────────────

class CacheService:
    """
    Two-tier cache service:

    * ``_filtered_cache`` — in-process TTLCache for AnnData objects
      (serialising multi-GB h5ad to Redis is impractical).
    * ``_results_cache``  — Redis-backed (pickled + zlib) for small analysis
      results; transparent fallback to in-memory TTLCache.
    """

    def __init__(
        self,
        maxsize: int = 100,
        ttl: int = 3600,
        redis_url: str = "",
        redis_enabled: bool = True,
    ) -> None:
        # AnnData objects — in-process only
        self._filtered_cache: TTLCache = TTLCache(maxsize=maxsize, ttl=ttl)
        self._ttl = ttl

        # Small results — Redis with in-memory fallback
        effective_url = redis_url or "redis://localhost:6379/0"
        if redis_enabled:
            self._results_cache: _RedisResultsCache = _RedisResultsCache(
                redis_url=effective_url,
                ttl=ttl,
                fallback_maxsize=maxsize * 2,
            )
        else:
            # Explicit opt-out: use in-memory wrapper that always falls back
            self._results_cache = _RedisResultsCache(
                redis_url="redis://DISABLED:0/0",  # will fail → fallback
                ttl=ttl,
                fallback_maxsize=maxsize * 2,
            )

        logger.info(f"🗄️  CacheService ready (filtered: memory/{maxsize}, ttl={ttl}s)")

    # ── Key generation ──────────────────────────────────────────────────────

    def _generate_filter_key(
        self,
        organism: str,
        dataset: str,
        clusters: Optional[List[str]] = None,
        metadata_filters: Optional[Dict] = None,
    ) -> str:
        """SHA-256 (truncated) unique key for a dataset + filter combination."""
        parts = [f"org:{organism}", f"ds:{dataset}"]
        if clusters:
            parts.append(f"clusters:{','.join(sorted(clusters))}")
        if metadata_filters:
            parts.append(f"filters:{sorted(metadata_filters.items())}")
        return hashlib.sha256("|".join(parts).encode()).hexdigest()[:16]

    # ── AnnData (in-memory) ─────────────────────────────────────────────────

    def get_filtered_dataset(
        self,
        organism: str,
        dataset: str,
        clusters: Optional[List[str]] = None,
        metadata_filters: Optional[Dict] = None,
    ) -> Optional[ad.AnnData]:
        """Return cached filtered AnnData, or None on miss."""
        key = self._generate_filter_key(organism, dataset, clusters, metadata_filters)
        hit = self._filtered_cache.get(key)
        if hit is not None:
            logger.debug(f"✅ AnnData cache HIT: {key}")
        else:
            logger.debug(f"❌ AnnData cache MISS: {key}")
        return hit

    def set_filtered_dataset(
        self,
        adata: ad.AnnData,
        organism: str,
        dataset: str,
        clusters: Optional[List[str]] = None,
        metadata_filters: Optional[Dict] = None,
    ) -> str:
        """Store a copy of the filtered AnnData and return its cache key."""
        key = self._generate_filter_key(organism, dataset, clusters, metadata_filters)
        self._filtered_cache[key] = adata.copy()
        logger.info(f"💾 AnnData cached: {key} ({adata.n_obs:,} cells)")
        return key

    # ── Analysis results (Redis) ────────────────────────────────────────────

    def get_result(self, result_key: str) -> Optional[Any]:
        """Return a cached analysis result, or None on miss."""
        return self._results_cache.get(result_key)

    def set_result(self, result_key: str, result: Any) -> None:
        """Cache an analysis result (pickle-serialisable object)."""
        self._results_cache.set(result_key, result)

    def delete_result(self, result_key: str) -> None:
        """Remove a specific analysis result from cache."""
        self._results_cache.delete(result_key)

    # ── House-keeping ───────────────────────────────────────────────────────

    def clear_all(self) -> None:
        """Flush both caches."""
        self._filtered_cache.clear()
        self._results_cache.clear()
        logger.info("🗑️  All caches cleared")

    def get_cache_stats(self) -> Dict:
        """Return a stats dict suitable for the /cache/stats endpoint."""
        return {
            "filtered_datasets": {
                "backend": "memory",
                "size": len(self._filtered_cache),
                "maxsize": self._filtered_cache.maxsize,
                "ttl_seconds": self._ttl,
            },
            "results": self._results_cache.stats(),
        }


# ──────────────────────────────────────────────────────────────────────────────
# Module-level singleton
# ──────────────────────────────────────────────────────────────────────────────

_cache_service_instance: Optional[CacheService] = None


def get_cache_service() -> CacheService:
    """Return (and lazily create) the global CacheService singleton."""
    global _cache_service_instance
    if _cache_service_instance is None:
        from app.core.config import settings

        _cache_service_instance = CacheService(
            maxsize=100,
            ttl=settings.CACHE_TTL,
            redis_url=settings.REDIS_URL,
            redis_enabled=settings.REDIS_ENABLED,
        )
    return _cache_service_instance
