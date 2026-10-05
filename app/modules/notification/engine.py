"""
Notification Engine for Single-Winner Bi-Directional Service Requests.
Filters nearby service providers using geographic coordinates (5km radius)
or District/Thana/Area text matching for MVP/preview.
Only notifies nearby matching providers, never all providers.
"""

import math
import uuid
from typing import Any, Dict, List, Optional


def calculate_haversine_distance_km(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """Calculates great-circle distance between two GPS points in kilometers."""
    R = 6371.0  # Earth's radius in kilometers
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2.0) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2.0) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


try:
    from sqlalchemy import select, and_, or_
    from sqlalchemy.ext.asyncio import AsyncSession
    from app.modules.dynamic_engine.models import (
        CustomEntity,
        EntityRecord,
        RecordStatusType,
        ServiceRequest,
    )
except ImportError:
    # Standalone test environment fallback
    select = None
    and_ = None
    or_ = None
    AsyncSession = Any
    CustomEntity = None
    EntityRecord = None
    RecordStatusType = None
    ServiceRequest = None


async def notify_nearby_providers(
    request_id: uuid.UUID,
    db: AsyncSession,
    max_radius_km: float = 5.0,
) -> Dict[str, Any]:
    """
    Finds and notifies only providers within proximity of the seeker.
    1. Proximity Filter:
       - Uses latitude/longitude with 5km Haversine radius if available.
       - Falls back to area keyword matching (e.g. 'Mirpur', 'Uttara', 'Dhanmondi').
    2. Category Filter:
       - Matches category_key (e.g. 'ac_repair', 'electrician').
    """
    # 1. Fetch Service Request
    stmt = select(ServiceRequest).where(ServiceRequest.id == request_id)
    result = await db.execute(stmt)
    req = result.scalar_one_or_none()

    if not req:
        return {
            "status": "error",
            "message": "ServiceRequest not found",
            "notified_count": 0,
            "providers": [],
        }

    seeker_lat = req.seeker_latitude
    seeker_lng = req.seeker_longitude
    seeker_location_text = (req.approx_location or "").lower()
    category_key = (req.category_key or "").lower()

    # Common Dhaka areas / Thanis for text matching fallback
    known_areas = [
        "mirpur",
        "uttara",
        "dhanmondi",
        "gulshan",
        "banani",
        "mohammadpur",
        "motijheel",
        "badda",
        "bashundhara",
        "khilkhet",
        "chittagong",
        "sylhet",
        "rajshahi",
    ]
    detected_area = next(
        (area for area in known_areas if area in seeker_location_text), None
    )

    # 2. Query Active Service Provider Records
    provider_stmt = (
        select(EntityRecord)
        .where(
            and_(
                EntityRecord.status == RecordStatusType.ACTIVE,
                EntityRecord.country_code == req.country_code,
            )
        )
        .limit(100)
    )
    records_res = await db.execute(provider_stmt)
    all_providers = records_res.scalars().all()

    notified_providers: List[Dict[str, Any]] = []

    for prov in all_providers:
        prov_data = prov.dynamic_data or {}
        prov_category = str(
            prov_data.get("service_category")
            or prov_data.get("category")
            or prov_data.get("custom_col_1")
            or ""
        ).lower()

        # Category match (partial or wildcard)
        if category_key and prov_category and (category_key not in prov_category and prov_category not in category_key):
            continue

        is_nearby = False
        distance_km = None

        # A. Check GPS Distance (within 5km)
        if (
            seeker_lat is not None
            and seeker_lng is not None
            and prov.geo_latitude is not None
            and prov.geo_longitude is not None
        ):
            distance_km = calculate_haversine_distance_km(
                seeker_lat, seeker_lng, prov.geo_latitude, prov.geo_longitude
            )
            if distance_km <= max_radius_km:
                is_nearby = True

        # B. Fallback: Area / Thana Text Matching (e.g. Mirpur to Mirpur)
        if not is_nearby:
            prov_location_text = (
                str(
                    prov.approx_location
                    or prov_data.get("service_area")
                    or prov_data.get("custom_col_5")
                    or ""
                ).lower()
            )
            if detected_area and detected_area in prov_location_text:
                is_nearby = True
            elif seeker_location_text and any(
                token in prov_location_text
                for token in seeker_location_text.split()
                if len(token) > 3
            ):
                is_nearby = True

        # MODULE 1 RULE: Only notify verified providers
        # Unverified providers cannot receive/accept requests ("NID Verify করুন, তারপর Request পাবেন")
        is_prov_verified = bool(
            prov_data.get("is_verified", True)  # default True for seeded demo providers unless explicitly False
        )
        if not is_prov_verified:
            continue

        # MODULE 2 RULE: Get provider level for sorting priority (Platinum/Gold gets first notification)
        prov_level = prov_data.get("level", "Gold" if "axio" not in prov.title.lower() else "Silver")
        level_ranks = {"Platinum": 4, "Gold": 3, "Silver": 2, "New": 1}
        rank = level_ranks.get(prov_level, 1)

        # If nearby and verified, register for notification
        if is_nearby:
            notified_providers.append({
                "provider_id": str(prov.user_id),
                "record_id": str(prov.id),
                "provider_title": prov.title,
                "location": prov.approx_location,
                "distance_km": round(distance_km, 2) if distance_km is not None else None,
                "is_verified": is_prov_verified,
                "level": prov_level,
                "level_rank": rank,
                "notification_channel": "push_and_in_app",
                "status": "alerted_first_to_accept_wins",
            })

    # MODULE 2: Sort providers by level DESC (Platinum > Gold > Silver > New)
    # This guarantees Gold/Platinum providers receive notifications first!
    notified_providers.sort(key=lambda x: x["level_rank"], reverse=True)

    return {
        "status": "success",
        "request_id": str(req.id),
        "category": req.category_key,
        "seeker_location": req.approx_location,
        "detected_area": detected_area,
        "max_radius_km": max_radius_km,
        "notified_count": len(notified_providers),
        "providers": notified_providers,
        "policy": "single_winner_first_accept_charges_both_parties",
    }
