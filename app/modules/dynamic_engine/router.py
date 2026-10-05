"""
Client-Facing Dynamic Engine Router.
Endpoints:
1. GET /api/v1/entities/{entity_key}/fields - Returns metadata schema for dynamic form rendering.
2. GET /api/v1/records/{entity_key} - Feed & Search API with dynamic JSONB filtering and private data masking.
3. POST /api/v1/records/{entity_key} - Submits dynamic post with AES-256 encryption for private fields.
"""

import json
import math
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from pydantic import BaseModel, Field
from sqlalchemy import and_, desc, func, or_, select
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import decode_user_token, decrypt_aes_256_gcm
from app.middleware.country_resolver import resolve_country_from_request
from app.modules.dynamic_engine.models import (
    CustomEntity,
    CustomField,
    EntityRecord,
    ModerationStatusType,
    RecordStatusType,
    RecordUnlock,
)
from app.modules.dynamic_engine.validator import (
    DynamicFieldValidator,
    ValidationResult,
    detect_contact_leakage,
)


router = APIRouter(prefix="/api/v1", tags=["Client Dynamic Feed & Posts"])


# ---------------------------------------------------------------------------
# Request Schemas
# ---------------------------------------------------------------------------
class CreateRecordPayload(BaseModel):
    title: str = Field(..., min_length=3, max_length=255, description="Public post title")
    approx_location: Optional[str] = Field(None, max_length=120, description="Approximate public area e.g. 'Mirpur-10, Dhaka'")
    thumbnail_url: Optional[str] = Field(None, description="Image attachment link")
    geo_latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    geo_longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    fields: dict[str, Any] = Field(..., description="Dynamic key-value pair fields mapped to custom_fields definition")


def get_current_user_id_optional(
    authorization: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None),
) -> Optional[uuid.UUID]:
    """Extracts user UUID from Bearer JWT or client test header."""
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        try:
            payload = decode_user_token(token)
            return uuid.UUID(payload.get("sub"))
        except Exception:
            pass

    if x_user_id:
        try:
            return uuid.UUID(x_user_id)
        except Exception:
            pass

    return None


# ---------------------------------------------------------------------------
# 1. GET /api/v1/entities/{entity_key}/fields (Public Schema for Flutter App)
# ---------------------------------------------------------------------------
@router.get("/entities/{entity_key}/fields", status_code=status.HTTP_200_OK)
async def get_entity_fields_schema(
    entity_key: str,
    request: Request,
    lang: str = Query("bn", description="Language code for labels: 'bn', 'en'"),
    country: Optional[str] = Query(None, description="Country ISO code override"),
    db: AsyncSession = Depends(get_db),
):
    """
    Returns active custom fields schema for an entity filtered by country.
    Includes is_private flag (so Flutter can display the 🔒 Lock Icon),
    but contains NO user data values. Uses Redis Cache for sub-millisecond retrieval.
    """
    resolved_country = country or getattr(request.state, "country_code", None) or resolve_country_from_request(request)

    # 1. Locate Entity
    stmt = select(CustomEntity).where(
        and_(
            CustomEntity.entity_key == entity_key.strip().lower(),
            CustomEntity.is_active.is_(True),
        )
    )
    res = await db.execute(stmt)
    entity = res.scalar_one_or_none()

    if not entity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Entity '{entity_key}' not found or inactive",
        )

    # 2. Fetch via Validator (Redis Cache First, target_countries @> '["*"]' query)
    fields = await DynamicFieldValidator.fetch_applicable_fields(
        db, entity.id, resolved_country
    )

    return {
        "status": "success",
        "entity_key": entity.entity_key,
        "country": resolved_country.upper(),
        "supports_unlock": entity.supports_unlock,
        "base_unlock_fee_usd": float(entity.base_unlock_fee_usd),
        "fields_count": len(fields),
        "fields": fields,
    }


# ---------------------------------------------------------------------------
# 2. GET /api/v1/records/{entity_key} (Feed & Dynamic Search API)
# ---------------------------------------------------------------------------
@router.get("/records/{entity_key}", status_code=status.HTTP_200_OK)
async def list_records_feed(
    entity_key: str,
    request: Request,
    search: Optional[str] = Query(None, description="Keyword search in title"),
    country: Optional[str] = Query(None, description="Filter by country"),
    lat: Optional[float] = Query(None, ge=-90.0, le=90.0),
    lng: Optional[float] = Query(None, ge=-180.0, le=180.0),
    radius_km: Optional[float] = Query(10.0, ge=0.5, le=100.0),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    """
    Public Feed and Search API:
    - Filters: moderation_status='approved' AND status='active'
    - Dynamic Filters: Parses query params like filter[fuel_type]=cng -> dynamic_data @> '{"fuel_type": "cng"}'
    - Geo-Distance Filtering (Haversine formula)
    - STRICT PRIVACY: Private fields are completely masked with '*** Unlock Required ***'
      unless caller holds an active unlock record (valid_until > now and is_refunded == false).
    """
    resolved_country = country or getattr(request.state, "country_code", None) or resolve_country_from_request(request)
    current_user_id = get_current_user_id_optional(
        request.headers.get("authorization"), request.headers.get("x-user-id")
    )

    # 1. Fetch Entity & Custom Fields to identify which keys are is_private
    stmt_entity = select(CustomEntity).where(
        and_(
            CustomEntity.entity_key == entity_key.strip().lower(),
            CustomEntity.is_active.is_(True),
        )
    )
    entity = (await db.execute(stmt_entity)).scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail=f"Entity '{entity_key}' not found")

    applicable_fields = await DynamicFieldValidator.fetch_applicable_fields(
        db, entity.id, resolved_country
    )
    private_field_keys = {f["field_key"] for f in applicable_fields if f.get("is_private")}

    # 2. Build Query
    base_conditions = [
        EntityRecord.entity_id == entity.id,
        EntityRecord.status == RecordStatusType.ACTIVE,
        EntityRecord.moderation_status == ModerationStatusType.APPROVED,
        EntityRecord.country_code == resolved_country.upper(),
    ]

    # Keyword Search
    if search and search.strip():
        base_conditions.append(EntityRecord.title.ilike(f"%{search.strip()}%"))

    # Dynamic JSONB Filters: query params like `filter[fuel_type]=cng` or `filter[transmission]=auto`
    for param_name, param_val in request.query_params.items():
        if param_name.startswith("filter[") and param_name.endswith("]"):
            field_name = param_name[7:-1].strip()
            if field_name:
                # Value type conversion
                typed_val: Any = param_val
                if param_val.isdigit():
                    typed_val = int(param_val)
                elif param_val.lower() in ("true", "false"):
                    typed_val = param_val.lower() == "true"
                # JSONB containment query
                base_conditions.append(
                    EntityRecord.dynamic_data.contains({field_name: typed_val})
                )

    # Haversine Distance Filter (if lat & lng provided)
    if lat is not None and lng is not None:
        # Haversine distance in KM
        haversine_km = 6371 * func.acos(
            func.cos(func.radians(lat))
            * func.cos(func.radians(EntityRecord.geo_latitude))
            * func.cos(func.radians(EntityRecord.geo_longitude) - func.radians(lng))
            + func.sin(func.radians(lat))
            * func.sin(func.radians(EntityRecord.geo_latitude))
        )
        base_conditions.append(EntityRecord.geo_latitude.isnot(None))
        base_conditions.append(EntityRecord.geo_longitude.isnot(None))
        base_conditions.append(haversine_km <= radius_km)

    query = (
        select(EntityRecord)
        .where(and_(*base_conditions))
        .order_by(desc(EntityRecord.created_at))
        .offset(offset)
        .limit(limit)
    )

    records = (await db.execute(query)).scalars().all()

    # 3. Batch Check Unlocked Records for current user
    unlocked_record_ids = set()
    now = datetime.now(timezone.utc)
    if current_user_id and records:
        rec_ids = [r.id for r in records]
        unlock_stmt = select(RecordUnlock.record_id).where(
            and_(
                RecordUnlock.record_id.in_(rec_ids),
                RecordUnlock.buyer_user_id == current_user_id,
                RecordUnlock.valid_until > now,
                RecordUnlock.is_refunded.is_(False),
            )
        )
        unlocked_record_ids = set((await db.execute(unlock_stmt)).scalars().all())

    # 4. Transform Records with Masking & Zero Sensitive Data Leakage
    feed_items = []
    for rec in records:
        is_owner = current_user_id == rec.user_id if current_user_id else False
        is_unlocked = is_owner or (rec.id in unlocked_record_ids)

        # dynamic_data is public
        transformed_data = dict(rec.dynamic_data)

        # Private data treatment
        if is_unlocked:
            # Authorized: decrypt AES-256 private fields
            if rec.encrypted_private_data and "ciphertext" in rec.encrypted_private_data:
                try:
                    decrypted_dict = json.loads(decrypt_aes_256_gcm(rec.encrypted_private_data))
                    transformed_data.update(decrypted_dict)
                except Exception:
                    pass
        else:
            # Unauthorized: mask all private fields completely
            for p_key in private_field_keys:
                transformed_data[p_key] = "*** Unlock Required ***"

        feed_items.append({
            "id": str(rec.id),
            "title": rec.title,
            "country_code": rec.country_code,
            "approx_location": rec.approx_location,
            "thumbnail_url": rec.thumbnail_url,
            "data": transformed_data,
            "is_unlocked": is_unlocked,
            "unlock_price_usd": float(entity.base_unlock_fee_usd),
            "views_count": rec.views_count,
            "unlocks_count": rec.unlocks_count,
            "geo_coordinates": {
                "latitude": rec.geo_latitude if is_unlocked else None,
                "longitude": rec.geo_longitude if is_unlocked else None,
            },
            "created_at": rec.created_at.isoformat(),
        })

    return {
        "status": "success",
        "entity_key": entity_key,
        "country": resolved_country.upper(),
        "count": len(feed_items),
        "offset": offset,
        "limit": limit,
        "records": feed_items,
    }


# ---------------------------------------------------------------------------
# 3. POST /api/v1/records/{entity_key} (Create Post API)
# ---------------------------------------------------------------------------
@router.post("/records/{entity_key}", status_code=status.HTTP_201_CREATED)
async def create_record(
    entity_key: str,
    payload: CreateRecordPayload,
    request: Request,
    lang: str = Query("bn"),
    country: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    """
    Submits a dynamic entity record:
    - Calls DynamicFieldValidator.validate_and_transform
    - Separates public dynamic_data from private sensitive fields
    - Encrypts private fields with AES-256-GCM
    - Automatically sets status='active' and moderation_status='pending'
    """
    resolved_country = country or getattr(request.state, "country_code", None) or resolve_country_from_request(request)

    # 1. Resolve User (from token or generated ID for guest/session)
    user_id = get_current_user_id_optional(
        request.headers.get("authorization"), request.headers.get("x-user-id")
    )
    if not user_id:
        # Fallback to simulated/guest user ID if not provided
        user_id = uuid.uuid4()

    # 2. Resolve Entity
    stmt = select(CustomEntity).where(
        and_(
            CustomEntity.entity_key == entity_key.strip().lower(),
            CustomEntity.is_active.is_(True),
        )
    )
    entity = (await db.execute(stmt)).scalar_one_or_none()
    if not entity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Entity '{entity_key}' not found or inactive",
        )

    # Business Protection: Prevent Contact Number Leakage in Public Title & Location
    if detect_contact_leakage(payload.title):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="For security and to protect both parties, please do not share phone numbers in public fields. Your private mobile number will be shared automatically after the buyer pays the unlock fee. পাবলিক ফিল্ডে ফোন নম্বর শেয়ার করা নিষিদ্ধ।",
        )
    if payload.approx_location and detect_contact_leakage(payload.approx_location):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="For security and to protect both parties, please do not share phone numbers in public fields. Your private mobile number will be shared automatically after the buyer pays the unlock fee. পাবলিক ফিল্ডে ফোন নম্বর শেয়ার করা নিষিদ্ধ।",
        )

    # 3. Dynamic Validation & AES-256 Partitioning
    validation: ValidationResult = await DynamicFieldValidator.validate_and_transform(
        db=db,
        entity_key=entity.entity_key,
        country_code=resolved_country,
        submitted_fields=payload.fields,
        language=lang,
    )

    if not validation.is_valid:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "error": "VALIDATION_FAILED",
                "message": "One or more fields failed validation requirements",
                "errors": validation.errors,
            },
        )

    # 4. Create and Save Entity Record
    new_record = EntityRecord(
        entity_id=entity.id,
        user_id=user_id,
        country_code=resolved_country.upper(),
        status=RecordStatusType.ACTIVE,
        moderation_status=ModerationStatusType.PENDING,  # Requires moderation review
        title=payload.title.strip(),
        approx_location=payload.approx_location,
        thumbnail_url=payload.thumbnail_url,
        dynamic_data=validation.dynamic_data,  # Plain public JSONB
        encrypted_private_data=validation.encrypted_private_data,  # AES-256 Encrypted JSONB
        geo_latitude=payload.geo_latitude,
        geo_longitude=payload.geo_longitude,
        views_count=0,
        unlocks_count=0,
    )

    db.add(new_record)
    await db.commit()
    await db.refresh(new_record)

    return {
        "status": "success",
        "message": "Record submitted successfully and queued for moderation review",
        "record_id": str(new_record.id),
        "entity_key": entity.entity_key,
        "moderation_status": new_record.moderation_status.value,
        "public_fields_stored": list(validation.dynamic_data.keys()),
        "private_fields_encrypted": validation.encrypted_private_data.get("private_field_keys", []),
        "created_at": new_record.created_at.isoformat(),
    }
