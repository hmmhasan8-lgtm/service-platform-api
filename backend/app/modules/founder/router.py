"""
Founder Control Center Endpoints.
Provides administrative APIs to dynamically manage Modules, Entities, Fields,
Country-specific Feature Flags, and view Immutable Audit Logs.
Protected by require_founder_auth and audited automatically by FounderAuditLogMiddleware.
"""

import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import and_, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.middleware.founder_security import require_founder_auth
from app.modules.dynamic_engine.models import (
    CustomEntity,
    CustomField,
    CustomModule,
    FieldDataType,
    StaffUser,
    SystemFeature,
    AuditLog,
)
from app.modules.dynamic_engine.validator import CacheManager


router = APIRouter(prefix="/founder", tags=["Founder Control Center"])


# ---------------------------------------------------------------------------
# Request & Response Pydantic Schemas
# ---------------------------------------------------------------------------
class CreateModuleRequest(BaseModel):
    module_key: str = Field(..., min_length=2, max_length=64, description="Unique key e.g. 'vehicle_rental'")
    name_translations: dict[str, str] = Field(..., description="Localized titles e.g. {'en': 'Vehicle Rental', 'bn': 'যানবাহন ভাড়া'}")
    icon: str = Field("layers", description="Lucide or Material icon identifier")
    allowed_countries: list[str] = Field(default=["*"], description="Country ISO codes or ['*'] for global")
    sort_order: int = Field(0, description="Display order sequence")


class CreateEntityRequest(BaseModel):
    module_id: uuid.UUID
    entity_key: str = Field(..., min_length=2, max_length=64, description="Unique entity key e.g. 'vehicles'")
    name_translations: dict[str, str] = Field(..., description="Localized titles")
    description_translations: Optional[dict[str, str]] = Field(default=dict)
    supports_unlock: bool = Field(True, description="Whether contacts/locations require unlock fees")
    base_unlock_fee_usd: float = Field(0.50, ge=0.0, description="Standard unlock fee in USD")
    unlock_validity_days: int = Field(7, ge=1, le=365, description="Validity period in days")
    sort_order: int = Field(0)


class CreateFieldRequest(BaseModel):
    entity_id: uuid.UUID
    field_key: str = Field(..., min_length=2, max_length=64, description="Column key e.g. 'security_deposit'")
    field_type: FieldDataType
    labels: dict[str, str] = Field(..., description="{'en': 'Security Deposit', 'bn': 'জামানত'}")
    placeholders: Optional[dict[str, str]] = Field(default=dict)
    help_texts: Optional[dict[str, str]] = Field(default=dict)
    is_required: bool = False
    validation_regex: Optional[str] = None
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    options: Optional[list[dict[str, Any]]] = Field(default=list, description="Dropdown options [{'value': 'cng', 'label': {'en': 'CNG', 'bn': 'সিএনজি'}}]")
    is_private: bool = Field(False, description="True = AES-256 encrypted & masked until unlocked")
    is_searchable: bool = Field(True, description="Available in search filters")
    is_highlighted: bool = Field(False, description="Displayed as key badge on card view")
    section: str = Field("general", description="UI section grouping: 'general', 'specs', 'contact'")
    target_countries: list[str] = Field(default=["*"], description="Applicable countries e.g. ['BD']")
    sort_order: int = 0


class UpdateFeatureFlagRequest(BaseModel):
    country_code: str = Field(..., min_length=1, max_length=4, description="Target country ISO ('BD', 'IN', 'US') or '*' for Global")
    is_enabled: bool = Field(..., description="Enable or disable feature in target country")
    config: Optional[dict[str, Any]] = Field(default=dict, description="Country specific overrides e.g. {'unlock_fee': 20}")
    description: Optional[str] = None


# ---------------------------------------------------------------------------
# 1. POST /founder/modules - Create Custom Module
# ---------------------------------------------------------------------------
@router.post("/modules", status_code=status.HTTP_201_CREATED)
async def create_custom_module(
    payload: CreateModuleRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    # Check duplicate
    stmt = select(CustomModule).where(CustomModule.module_key == payload.module_key.strip().lower())
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Module with key '{payload.module_key}' already exists",
        )

    module = CustomModule(
        module_key=payload.module_key.strip().lower(),
        name_translations=payload.name_translations,
        icon=payload.icon,
        allowed_countries=[c.upper() for c in payload.allowed_countries],
        sort_order=payload.sort_order,
        is_active=True,
    )
    db.add(module)
    await db.commit()
    await db.refresh(module)

    return {
        "status": "success",
        "message": f"Module '{module.module_key}' successfully registered",
        "module": module.to_dict(),
    }


# ---------------------------------------------------------------------------
# 2. POST /founder/entities - Create Custom Entity (Table under Module)
# ---------------------------------------------------------------------------
@router.post("/entities", status_code=status.HTTP_201_CREATED)
async def create_custom_entity(
    payload: CreateEntityRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    # Verify module exists
    module = (await db.execute(select(CustomModule).where(CustomModule.id == payload.module_id))).scalar_one_or_none()
    if not module:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent module not found")

    # Check duplicate key in module
    stmt = select(CustomEntity).where(
        and_(
            CustomEntity.module_id == payload.module_id,
            CustomEntity.entity_key == payload.entity_key.strip().lower(),
        )
    )
    if (await db.execute(stmt)).scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Entity '{payload.entity_key}' already exists in this module",
        )

    entity = CustomEntity(
        module_id=payload.module_id,
        entity_key=payload.entity_key.strip().lower(),
        name_translations=payload.name_translations,
        description_translations=payload.description_translations or {},
        supports_unlock=payload.supports_unlock,
        base_unlock_fee_usd=payload.base_unlock_fee_usd,
        unlock_validity_days=payload.unlock_validity_days,
        sort_order=payload.sort_order,
        is_active=True,
    )
    db.add(entity)
    await db.commit()
    await db.refresh(entity)

    return {
        "status": "success",
        "message": f"Entity '{entity.entity_key}' created in module '{module.module_key}'",
        "entity": entity.to_dict(),
    }


# ---------------------------------------------------------------------------
# 3. POST /founder/fields - Add Dynamic Field to Entity
# ---------------------------------------------------------------------------
@router.post("/fields", status_code=status.HTTP_201_CREATED)
async def create_custom_field(
    payload: CreateFieldRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    # Verify entity exists
    entity = (await db.execute(select(CustomEntity).where(CustomEntity.id == payload.entity_id))).scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Target entity not found")

    # Check field duplicate
    stmt = select(CustomField).where(
        and_(
            CustomField.entity_id == payload.entity_id,
            CustomField.field_key == payload.field_key.strip().lower(),
        )
    )
    if (await db.execute(stmt)).scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Field '{payload.field_key}' already exists for this entity",
        )

    field = CustomField(
        entity_id=payload.entity_id,
        field_key=payload.field_key.strip().lower(),
        field_type=payload.field_type,
        labels=payload.labels,
        placeholders=payload.placeholders or {},
        help_texts=payload.help_texts or {},
        is_required=payload.is_required,
        validation_regex=payload.validation_regex,
        min_value=payload.min_value,
        max_value=payload.max_value,
        options=payload.options or [],
        is_private=payload.is_private,
        is_searchable=payload.is_searchable,
        is_highlighted=payload.is_highlighted,
        section=payload.section,
        target_countries=[c.upper() for c in payload.target_countries],
        sort_order=payload.sort_order,
        is_active=True,
    )
    db.add(field)
    await db.commit()
    await db.refresh(field)

    # Invalidate Redis Field Cache for this entity across all countries
    await CacheManager.invalidate_entity_fields(str(entity.id))

    return {
        "status": "success",
        "message": f"Field '{field.field_key}' successfully registered. Cache invalidated.",
        "field": field.to_dict(),
    }


# ---------------------------------------------------------------------------
# 4. PUT /founder/features/{feature_key} - Country-wise Feature Flag Control
# ---------------------------------------------------------------------------
@router.put("/features/{feature_key}", status_code=status.HTTP_200_OK)
async def set_country_feature_flag(
    feature_key: str,
    payload: UpdateFeatureFlagRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    key = feature_key.strip().lower()
    target_country = payload.country_code.strip().upper()

    stmt = select(SystemFeature).where(
        and_(
            SystemFeature.feature_key == key,
            SystemFeature.country_code == target_country,
        )
    )
    feature = (await db.execute(stmt)).scalar_one_or_none()

    if feature:
        # Update existing
        feature.is_enabled = payload.is_enabled
        if payload.config:
            feature.config = payload.config
        if payload.description:
            feature.description = payload.description
        feature.updated_by = founder.id
    else:
        # Insert new flag record
        feature = SystemFeature(
            feature_key=key,
            country_code=target_country,
            is_enabled=payload.is_enabled,
            config=payload.config or {},
            description=payload.description or f"Flag for {key} in {target_country}",
            updated_by=founder.id,
        )
        db.add(feature)

    await db.commit()
    await db.refresh(feature)

    # Invalidate Redis Feature Cache
    cache_key = f"feature:{key}:{target_country}"
    await CacheManager.set(cache_key, "1" if payload.is_enabled else "0", ttl_seconds=300)

    return {
        "status": "success",
        "message": f"Feature '{key}' set to {payload.is_enabled} for country '{target_country}'",
        "feature": feature.to_dict(),
    }


# ---------------------------------------------------------------------------
# 5. GET /founder/audit-logs - View Immutable Audit Logs
# ---------------------------------------------------------------------------
@router.get("/audit-logs", status_code=status.HTTP_200_OK)
async def list_audit_logs(
    actor_id: Optional[uuid.UUID] = Query(None),
    entity_name: Optional[str] = Query(None),
    country: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    query = select(AuditLog)

    conditions = []
    if actor_id:
        conditions.append(AuditLog.actor_id == actor_id)
    if entity_name:
        conditions.append(AuditLog.entity_name == entity_name.strip())
    if country:
        conditions.append(AuditLog.country_code == country.strip().upper())

    if conditions:
        query = query.where(and_(*conditions))

    query = query.order_by(desc(AuditLog.created_at)).offset(offset).limit(limit)

    results = (await db.execute(query)).scalars().all()

    return {
        "count": len(results),
        "offset": offset,
        "limit": limit,
        "logs": [log.to_dict() for log in results],
    }
