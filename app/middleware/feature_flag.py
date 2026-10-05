"""
Country-Aware Dynamic Feature Flag Middleware & Guard.
Verifies system_features table for country-specific flags with Global '*' fallback.
Returns 403 FEATURE_DISABLED if a module or feature is disabled for the caller's country.
"""

import json
from typing import Callable, Optional
from fastapi import HTTPException, Request, Response, status
from fastapi.responses import JSONResponse
from sqlalchemy import and_, or_, select
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint

from app.core.database import AsyncSessionLocal
from app.modules.dynamic_engine.models import SystemFeature
from app.modules.dynamic_engine.validator import CacheManager
from app.middleware.country_resolver import resolve_country_from_request, DEFAULT_COUNTRY_CODE


class FeatureFlagService:
    """
    Evaluates whether a given feature is enabled for a country code.
    Resolution Order:
    1. Check Redis cache: 'feature:{feature_key}:{country_code}'
    2. Check system_features where feature_key = X AND country_code = Country
    3. Fallback: check system_features where feature_key = X AND country_code = '*'
    4. Default: Enabled (True) if no entry exists
    """

    @classmethod
    async def is_feature_enabled(cls, feature_key: str, country_code: str) -> bool:
        cache_key = f"feature:{feature_key}:{country_code.upper()}"
        cached = await CacheManager.get(cache_key)
        if cached is not None:
            return cached == "1"

        async with AsyncSessionLocal() as session:
            # Query country-specific and global fallback in one roundtrip
            stmt = (
                select(SystemFeature)
                .where(
                    and_(
                        SystemFeature.feature_key == feature_key,
                        SystemFeature.country_code.in_([country_code.upper(), "*"]),
                    )
                )
            )
            result = await session.execute(stmt)
            records = result.scalars().all()

            # 1. Look for exact country match
            country_record = next(
                (r for r in records if r.country_code.upper() == country_code.upper()),
                None,
            )
            if country_record is not None:
                enabled = country_record.is_enabled
                await CacheManager.set(cache_key, "1" if enabled else "0", ttl_seconds=300)
                return enabled

            # 2. Look for Global '*' fallback match
            global_record = next(
                (r for r in records if r.country_code == "*"),
                None,
            )
            if global_record is not None:
                enabled = global_record.is_enabled
                await CacheManager.set(cache_key, "1" if enabled else "0", ttl_seconds=300)
                return enabled

            # 3. Default fallback if not defined: True
            await CacheManager.set(cache_key, "1", ttl_seconds=300)
            return True


# ---------------------------------------------------------------------------
# Path to Feature Mapping (Auto-intercept common modular endpoints)
# ---------------------------------------------------------------------------
PATH_FEATURE_MAP = {
    "/api/v1/records/vehicle_rental": "vehicle_rental",
    "/api/v1/records/vehicles": "vehicle_rental",
    "/api/v1/chat": "direct_chat",
    "/api/v1/messages": "direct_chat",
    "/api/v1/kyc": "kyc_verification",
}


class FeatureFlagMiddleware(BaseHTTPMiddleware):
    """
    Middleware that automatically extracts country_code and evaluates
    system_features for incoming request paths.
    Returns 403 JSONResponse if feature is disabled in the detected country.
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Skip founder routes and health checks from regular feature blocking
        path = request.url.path
        if path.startswith("/founder") or path in ("/health", "/docs", "/openapi.json"):
            return await call_next(request)

        # Resolve country code from request state or resolver
        country_code = getattr(
            request.state, "country_code", None
        ) or resolve_country_from_request(request)
        request.state.country_code = country_code

        # Check path against automatic feature mapping
        matched_feature: Optional[str] = None
        for prefix, feature_key in PATH_FEATURE_MAP.items():
            if path.startswith(prefix):
                matched_feature = feature_key
                break

        if matched_feature:
            is_enabled = await FeatureFlagService.is_feature_enabled(
                matched_feature, country_code
            )
            if not is_enabled:
                return JSONResponse(
                    status_code=status.HTTP_403_FORBIDDEN,
                    content={
                        "error": "FEATURE_DISABLED",
                        "message": f"Feature '{matched_feature}' is currently unavailable in your region ({country_code}).",
                        "feature_key": matched_feature,
                        "country_code": country_code,
                    },
                )

        return await call_next(request)


# ---------------------------------------------------------------------------
# Route Dependency: enforce feature flag on specific router endpoints
# ---------------------------------------------------------------------------
def require_feature(feature_key: str) -> Callable:
    """
    FastAPI dependency factory:
    Usage: @router.post("/items", dependencies=[Depends(require_feature("vehicle_rental"))])
    """

    async def _dependency(request: Request) -> None:
        country_code = getattr(
            request.state, "country_code", None
        ) or resolve_country_from_request(request)

        is_enabled = await FeatureFlagService.is_feature_enabled(
            feature_key, country_code
        )
        if not is_enabled:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "error": "FEATURE_DISABLED",
                    "message": f"Feature '{feature_key}' is disabled for country '{country_code}'",
                    "feature_key": feature_key,
                    "country_code": country_code,
                },
            )

    return _dependency
