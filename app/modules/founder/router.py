"""
Founder Control Center Endpoints.
Provides administrative APIs to dynamically manage:
1. Modules: Create (POST /founder/modules), Update & Active/Inactive (PUT /founder/modules/{id}), List (GET /founder/modules)
2. Entities (Tables): Create (POST /founder/entities), Rename & Active/Inactive (PUT /founder/entities/{id}), List (GET /founder/entities)
3. 15 Generic Column Definitions: (PUT /founder/entities/{id} with field_definitions, POST /founder/fields)
4. Country-specific Feature Flags: (PUT /founder/features/{feature_key})
5. Immutable Audit Logs: (GET /founder/audit-logs)
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import and_, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.middleware.founder_security import require_founder_auth
from app.modules.dynamic_engine.models import (
    AuditLog,
    CustomEntity,
    CustomField,
    CustomModule,
    FieldDataType,
    StaffUser,
    SystemFeature,
)
from app.modules.dynamic_engine.validator import CacheManager


router = APIRouter(prefix="/founder", tags=["Founder Control Center"])


def generate_default_15_columns() -> list[dict[str, Any]]:
    """Generates standard 15 generic column definitions for new tables."""
    cols = []
    for i in range(1, 16):
        cols.append({
            "col_key": f"custom_col_{i}",
            "label_en": f"Custom Field {i}",
            "label_bn": f"কাস্টম ফিল্ড {i}",
            "data_type": "text",
            "is_private": False,
            "is_active": i <= 3,  # First 3 active by default
            "is_required": False,
            "options": [],
            "target_countries": ["*"],
        })
    return cols


# ---------------------------------------------------------------------------
# Pydantic Request Models
# ---------------------------------------------------------------------------
class CreateModuleRequest(BaseModel):
    module_key: str = Field(..., min_length=2, max_length=64, description="Unique key e.g. 'home_service'")
    name_en: Optional[str] = None
    name_bn: Optional[str] = None
    name_translations: Optional[dict[str, str]] = None
    icon: Optional[str] = "layers"
    allowed_countries: Optional[list[str]] = Field(default=["*"])
    is_active: bool = True
    sort_order: int = 0


class UpdateModuleRequest(BaseModel):
    name_en: Optional[str] = None
    name_bn: Optional[str] = None
    name_translations: Optional[dict[str, str]] = None
    is_active: Optional[bool] = None
    allowed_countries: Optional[list[str]] = None
    icon: Optional[str] = None
    sort_order: Optional[int] = None


class CreateEntityRequest(BaseModel):
    module_id: uuid.UUID
    entity_key: str = Field(..., min_length=2, max_length=64, description="Unique table key e.g. 'ac_services'")
    name_en: Optional[str] = None
    name_bn: Optional[str] = None
    name_translations: Optional[dict[str, str]] = None
    unlock_fee: Optional[float] = None
    base_unlock_fee_usd: Optional[float] = 0.50
    validity_days: Optional[int] = None
    unlock_validity_days: Optional[int] = 7
    supports_unlock: bool = True
    is_active: bool = True
    field_definitions: Optional[list[dict[str, Any]]] = None
    sort_order: int = 0


class UpdateEntityRequest(BaseModel):
    name_en: Optional[str] = None
    name_bn: Optional[str] = None
    name_translations: Optional[dict[str, str]] = None
    unlock_fee: Optional[float] = None
    base_unlock_fee_usd: Optional[float] = None
    validity_days: Optional[int] = None
    unlock_validity_days: Optional[int] = None
    is_active: Optional[bool] = None
    supports_unlock: Optional[bool] = None
    field_definitions: Optional[list[dict[str, Any]]] = None
    sort_order: Optional[int] = None


class CreateFieldRequest(BaseModel):
    entity_id: uuid.UUID
    field_key: str = Field(..., min_length=2, max_length=64)
    field_type: FieldDataType
    labels: dict[str, str]
    placeholders: Optional[dict[str, str]] = Field(default=dict)
    help_texts: Optional[dict[str, str]] = Field(default=dict)
    is_required: bool = False
    validation_regex: Optional[str] = None
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    options: Optional[list[dict[str, Any]]] = Field(default=list)
    is_private: bool = False
    is_searchable: bool = True
    is_highlighted: bool = False
    section: str = "general"
    target_countries: list[str] = Field(default=["*"])
    sort_order: int = 0


class UpdateFeatureFlagRequest(BaseModel):
    country_code: str
    is_enabled: bool
    config: Optional[dict[str, Any]] = Field(default=dict)
    description: Optional[str] = None


# ---------------------------------------------------------------------------
# 1. MODULES CRUD
# ---------------------------------------------------------------------------
@router.get("/modules", status_code=status.HTTP_200_OK)
async def list_modules(
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    """GET /founder/modules - List all business modules."""
    stmt = select(CustomModule).order_by(CustomModule.sort_order, CustomModule.created_at)
    modules = (await db.execute(stmt)).scalars().all()
    return {
        "status": "success",
        "count": len(modules),
        "modules": [m.to_dict() for m in modules],
    }


@router.post("/modules", status_code=status.HTTP_201_CREATED)
async def create_custom_module(
    payload: CreateModuleRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    """POST /founder/modules - Create new module (e.g. home_service, delivery)."""
    m_key = payload.module_key.strip().lower()

    # Check duplicate
    stmt = select(CustomModule).where(CustomModule.module_key == m_key)
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Module with key '{m_key}' already exists",
        )

    # Format name translations
    translations = payload.name_translations or {}
    if payload.name_en:
        translations["en"] = payload.name_en
    if payload.name_bn:
        translations["bn"] = payload.name_bn
    if not translations:
        translations = {"en": m_key.replace("_", " ").title(), "bn": m_key}

    module = CustomModule(
        module_key=m_key,
        name_translations=translations,
        icon=payload.icon or "layers",
        allowed_countries=[c.upper() for c in (payload.allowed_countries or ["*"])],
        sort_order=payload.sort_order,
        is_active=payload.is_active,
    )
    db.add(module)
    await db.commit()
    await db.refresh(module)

    return {
        "status": "success",
        "message": f"Module '{module.module_key}' created successfully",
        "module": module.to_dict(),
    }


@router.put("/modules/{module_id}", status_code=status.HTTP_200_OK)
async def update_custom_module(
    module_id: uuid.UUID,
    payload: UpdateModuleRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    """PUT /founder/modules/{module_id} - Rename module and toggle active/inactive."""
    module = (await db.execute(select(CustomModule).where(CustomModule.id == module_id))).scalar_one_or_none()
    if not module:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Module not found")

    if payload.name_translations:
        module.name_translations = {**module.name_translations, **payload.name_translations}
    if payload.name_en:
        module.name_translations["en"] = payload.name_en
    if payload.name_bn:
        module.name_translations["bn"] = payload.name_bn

    if payload.is_active is not None:
        module.is_active = payload.is_active

    if payload.allowed_countries is not None:
        module.allowed_countries = [c.upper() for c in payload.allowed_countries]

    if payload.icon is not None:
        module.icon = payload.icon

    if payload.sort_order is not None:
        module.sort_order = payload.sort_order

    await db.commit()
    await db.refresh(module)

    return {
        "status": "success",
        "message": f"Module '{module.module_key}' updated successfully",
        "module": module.to_dict(),
    }


# ---------------------------------------------------------------------------
# 2. ENTITIES (TABLES) CRUD
# ---------------------------------------------------------------------------
@router.get("/entities", status_code=status.HTTP_200_OK)
async def list_entities(
    module_id: Optional[uuid.UUID] = Query(None),
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    """GET /founder/entities - List all tables (entities), optionally filtered by module."""
    stmt = select(CustomEntity)
    if module_id:
        stmt = stmt.where(CustomEntity.module_id == module_id)
    stmt = stmt.order_by(CustomEntity.sort_order, CustomEntity.created_at)

    entities = (await db.execute(stmt)).scalars().all()
    return {
        "status": "success",
        "count": len(entities),
        "entities": [e.to_dict() for e in entities],
    }


@router.post("/entities", status_code=status.HTTP_201_CREATED)
async def create_custom_entity(
    payload: CreateEntityRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    """POST /founder/entities - Create new table (entity) under a module."""
    # Verify module exists
    module = (await db.execute(select(CustomModule).where(CustomModule.id == payload.module_id))).scalar_one_or_none()
    if not module:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent module not found")

    e_key = payload.entity_key.strip().lower()

    # Check duplicate
    stmt = select(CustomEntity).where(
        and_(
            CustomEntity.module_id == payload.module_id,
            CustomEntity.entity_key == e_key,
        )
    )
    if (await db.execute(stmt)).scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Table/Entity '{e_key}' already exists in module '{module.module_key}'",
        )

    translations = payload.name_translations or {}
    if payload.name_en:
        translations["en"] = payload.name_en
    if payload.name_bn:
        translations["bn"] = payload.name_bn
    if not translations:
        translations = {"en": e_key.replace("_", " ").title(), "bn": e_key}

    unlock_fee = payload.unlock_fee if payload.unlock_fee is not None else payload.base_unlock_fee_usd
    validity_days = payload.validity_days if payload.validity_days is not None else payload.unlock_validity_days

    # 15 Generic Columns definition
    columns_15 = payload.field_definitions or generate_default_15_columns()

    entity = CustomEntity(
        module_id=payload.module_id,
        entity_key=e_key,
        name_translations=translations,
        description_translations={},
        supports_unlock=payload.supports_unlock,
        base_unlock_fee_usd=unlock_fee or 0.50,
        unlock_validity_days=validity_days or 7,
        sort_order=payload.sort_order,
        is_active=payload.is_active,
        field_definitions=columns_15,
    )
    db.add(entity)
    await db.commit()
    await db.refresh(entity)

    return {
        "status": "success",
        "message": f"Table '{entity.entity_key}' created with 15 generic columns",
        "entity": entity.to_dict(),
    }


@router.put("/entities/{entity_id}", status_code=status.HTTP_200_OK)
async def update_custom_entity(
    entity_id: uuid.UUID,
    payload: UpdateEntityRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    """PUT /founder/entities/{entity_id} - Rename table, change active status, unlock fee, or 15 columns."""
    entity = (await db.execute(select(CustomEntity).where(CustomEntity.id == entity_id))).scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Table/Entity not found")

    if payload.name_translations:
        entity.name_translations = {**entity.name_translations, **payload.name_translations}
    if payload.name_en:
        entity.name_translations["en"] = payload.name_en
    if payload.name_bn:
        entity.name_translations["bn"] = payload.name_bn

    fee = payload.unlock_fee if payload.unlock_fee is not None else payload.base_unlock_fee_usd
    if fee is not None:
        entity.base_unlock_fee_usd = fee

    validity = payload.validity_days if payload.validity_days is not None else payload.unlock_validity_days
    if validity is not None:
        entity.unlock_validity_days = validity

    if payload.is_active is not None:
        entity.is_active = payload.is_active

    if payload.supports_unlock is not None:
        entity.supports_unlock = payload.supports_unlock

    if payload.field_definitions is not None:
        entity.field_definitions = payload.field_definitions

    if payload.sort_order is not None:
        entity.sort_order = payload.sort_order

    await db.commit()
    await db.refresh(entity)

    # Invalidate cache
    await CacheManager.invalidate_entity_fields(str(entity.id))

    return {
        "status": "success",
        "message": f"Table '{entity.entity_key}' updated successfully",
        "entity": entity.to_dict(),
    }


# ---------------------------------------------------------------------------
# 3. LEGACY / SPECIFIC FIELD CREATOR
# ---------------------------------------------------------------------------
@router.post("/fields", status_code=status.HTTP_201_CREATED)
async def create_custom_field(
    payload: CreateFieldRequest,
    founder: StaffUser = Depends(require_founder_auth),
    db: AsyncSession = Depends(get_db),
):
    entity = (await db.execute(select(CustomEntity).where(CustomEntity.id == payload.entity_id))).scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Target entity not found")

    f_key = payload.field_key.strip().lower()
    stmt = select(CustomField).where(
        and_(
            CustomField.entity_id == payload.entity_id,
            CustomField.field_key == f_key,
        )
    )
    if (await db.execute(stmt)).scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Field '{f_key}' already exists for this entity",
        )

    field = CustomField(
        entity_id=payload.entity_id,
        field_key=f_key,
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

    await CacheManager.invalidate_entity_fields(str(entity.id))

    return {
        "status": "success",
        "message": f"Field '{field.field_key}' registered. Cache invalidated.",
        "field": field.to_dict(),
    }


# ---------------------------------------------------------------------------
# 4. COUNTRY-WISE FEATURE FLAGS
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
        feature.is_enabled = payload.is_enabled
        if payload.config:
            feature.config = payload.config
        if payload.description:
            feature.description = payload.description
        feature.updated_by = founder.id
    else:
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

    cache_key = f"feature:{key}:{target_country}"
    await CacheManager.set(cache_key, "1" if payload.is_enabled else "0", ttl_seconds=300)

    return {
        "status": "success",
        "message": f"Feature '{key}' set to {payload.is_enabled} for country '{target_country}'",
        "feature": feature.to_dict(),
    }


# ---------------------------------------------------------------------------
# 5. AUDIT LOGS
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
