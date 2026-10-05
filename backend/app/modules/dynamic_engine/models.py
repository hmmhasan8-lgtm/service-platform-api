"""
SQLAlchemy Models for Dynamic Modular Metadata Engine.
Implements custom_modules, custom_entities, custom_fields, entity_records,
and record_unlocks as defined in the approved architecture.
"""

import enum
import uuid
from datetime import datetime
from typing import Any, List, Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    Double,
    Enum,
    Float,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------
class FieldDataType(str, enum.Enum):
    TEXT = "text"
    NUMBER = "number"
    CURRENCY = "currency"
    SELECT = "select"
    MULTISELECT = "multiselect"
    DATE = "date"
    BOOLEAN = "boolean"
    FILE_URL = "file_url"
    GEO_POINT = "geo_point"
    PHONE = "phone"


class RecordStatusType(str, enum.Enum):
    ACTIVE = "active"
    PAUSED = "paused"
    CLOSED = "closed"
    ARCHIVED = "archived"


class ModerationStatusType(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


# ---------------------------------------------------------------------------
# 1. CustomModule
# ---------------------------------------------------------------------------
class CustomModule(Base):
    __tablename__ = "custom_modules"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    module_key: Mapped[str] = mapped_column(
        String(64), unique=True, nullable=False, index=True
    )
    name_translations: Mapped[dict[str, Any]] = mapped_column(
        JSONB, nullable=False, default=dict
    )  # {"en": "Vehicle Rental", "bn": "যানবাহন ভাড়া"}
    icon: Mapped[str] = mapped_column(
        String(64), nullable=False, default="layers"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    allowed_countries: Mapped[list[str]] = mapped_column(
        JSONB, default=lambda: ["*"], nullable=False
    )  # ["*"] or ["BD", "IN"]
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Relationships
    entities: Mapped[List["CustomEntity"]] = relationship(
        "CustomEntity", back_populates="module", cascade="all, delete-orphan"
    )

    __table_args__ = (
        Index(
            "idx_modules_countries_gin", allowed_countries, postgresql_using="gin"
        ),
    )


# ---------------------------------------------------------------------------
# 2. CustomEntity
# ---------------------------------------------------------------------------
class CustomEntity(Base):
    __tablename__ = "custom_entities"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    module_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("custom_modules.id", ondelete="CASCADE"),
        nullable=False,
    )
    entity_key: Mapped[str] = mapped_column(
        String(64), nullable=False, index=True
    )  # e.g., 'vehicles', 'drivers'
    name_translations: Mapped[dict[str, Any]] = mapped_column(
        JSONB, nullable=False, default=dict
    )
    description_translations: Mapped[dict[str, Any]] = mapped_column(
        JSONB, default=dict
    )
    supports_unlock: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    base_unlock_fee_usd: Mapped[float] = mapped_column(
        Numeric(10, 2), default=0.50, nullable=False
    )
    unlock_validity_days: Mapped[int] = mapped_column(
        Integer, default=7, nullable=False
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Relationships
    module: Mapped["CustomModule"] = relationship(
        "CustomModule", back_populates="entities"
    )
    fields: Mapped[List["CustomField"]] = relationship(
        "CustomField", back_populates="entity", cascade="all, delete-orphan"
    )
    records: Mapped[List["EntityRecord"]] = relationship(
        "EntityRecord", back_populates="entity"
    )

    __table_args__ = (
        UniqueConstraint(
            "module_id", "entity_key", name="uq_custom_entities_module_entity"
        ),
    )


# ---------------------------------------------------------------------------
# 3. CustomField
# ---------------------------------------------------------------------------
class CustomField(Base):
    __tablename__ = "custom_fields"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    entity_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("custom_entities.id", ondelete="CASCADE"),
        nullable=False,
    )
    field_key: Mapped[str] = mapped_column(
        String(64), nullable=False
    )  # e.g., 'security_deposit', 'contact_mobile'
    field_type: Mapped[FieldDataType] = mapped_column(
        Enum(FieldDataType, name="field_data_type"), nullable=False
    )
    labels: Mapped[dict[str, Any]] = mapped_column(
        JSONB, nullable=False, default=dict
    )  # {"en": "Security Deposit", "bn": "জামানতের পরিমাণ"}
    placeholders: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    help_texts: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)

    # Validation Rules
    is_required: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    validation_regex: Mapped[Optional[str]] = mapped_column(
        String(255), nullable=True
    )
    min_value: Mapped[Optional[float]] = mapped_column(
        Numeric(15, 2), nullable=True
    )
    max_value: Mapped[Optional[float]] = mapped_column(
        Numeric(15, 2), nullable=True
    )
    options: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONB, default=list
    )  # [{"value": "petrol", "label": {"en": "Petrol", "bn": "পেট্রোল"}}]

    # Business Logic & Security
    is_private: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )  # True = Stored in encrypted_private_data & masked before unlock
    is_searchable: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    is_highlighted: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    section: Mapped[str] = mapped_column(
        String(32), default="general", nullable=False
    )

    # Country Filters
    target_countries: Mapped[list[str]] = mapped_column(
        JSONB, default=lambda: ["*"], nullable=False
    )  # e.g. ["BD"] or ["*"]
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )

    # Relationships
    entity: Mapped["CustomEntity"] = relationship(
        "CustomEntity", back_populates="fields"
    )

    __table_args__ = (
        UniqueConstraint(
            "entity_id", "field_key", name="uq_custom_fields_entity_key"
        ),
        Index(
            "idx_custom_fields_countries_gin",
            target_countries,
            postgresql_using="gin",
        ),
        Index(
            "idx_custom_fields_lookup",
            entity_id,
            is_active,
            is_searchable,
            sort_order,
        ),
    )


# ---------------------------------------------------------------------------
# 4. EntityRecord
# ---------------------------------------------------------------------------
class EntityRecord(Base):
    __tablename__ = "entity_records"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    entity_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("custom_entities.id"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    country_code: Mapped[str] = mapped_column(
        String(4), nullable=False, index=True
    )  # 'BD', 'IN', 'US'

    status: Mapped[RecordStatusType] = mapped_column(
        Enum(RecordStatusType, name="record_status_type"),
        default=RecordStatusType.ACTIVE,
        nullable=False,
    )
    moderation_status: Mapped[ModerationStatusType] = mapped_column(
        Enum(ModerationStatusType, name="moderation_status_type"),
        default=ModerationStatusType.PENDING,
        nullable=False,
    )
    moderation_notes: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )
    moderated_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )
    moderated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    approx_location: Mapped[Optional[str]] = mapped_column(
        String(120), nullable=True
    )  # Public approx area
    thumbnail_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Dynamic Data (Plain JSONB for public fields)
    dynamic_data: Mapped[dict[str, Any]] = mapped_column(
        JSONB, default=dict, nullable=False
    )

    # Encrypted Private Data (AES-256 Encrypted for sensitive fields like mobile, GPS, NID)
    encrypted_private_data: Mapped[dict[str, Any]] = mapped_column(
        JSONB, default=dict, nullable=False
    )

    geo_latitude: Mapped[Optional[float]] = mapped_column(Double, nullable=True)
    geo_longitude: Mapped[Optional[float]] = mapped_column(
        Double, nullable=True
    )

    views_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    unlocks_count: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )

    # Relationships
    entity: Mapped["CustomEntity"] = relationship(
        "CustomEntity", back_populates="records"
    )
    unlocks: Mapped[List["RecordUnlock"]] = relationship(
        "RecordUnlock", back_populates="record", cascade="all, delete-orphan"
    )

    __table_args__ = (
        Index(
            "idx_entity_records_dynamic_gin",
            dynamic_data,
            postgresql_using="gin",
        ),
        Index(
            "idx_entity_records_search",
            country_code,
            entity_id,
            status,
            moderation_status,
        ),
    )


# ---------------------------------------------------------------------------
# 5. RecordUnlock (Renewal Support with Partial Index)
# ---------------------------------------------------------------------------
class RecordUnlock(Base):
    __tablename__ = "record_unlocks"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    record_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("entity_records.id", ondelete="CASCADE"),
        nullable=False,
    )
    buyer_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    fee_amount: Mapped[float] = mapped_column(
        Numeric(12, 2), nullable=False
    )
    currency: Mapped[str] = mapped_column(String(4), nullable=False)
    payment_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )
    unlocked_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, nullable=False
    )
    valid_until: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    is_refunded: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    refunded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    record: Mapped["EntityRecord"] = relationship(
        "EntityRecord", back_populates="unlocks"
    )

    __table_args__ = (
        # Renewal-friendly Partial Index (Fix 1 from architectural review)
        Index(
            "idx_record_unlocks_active",
            record_id,
            buyer_user_id,
            valid_until.desc(),
            postgresql_where=(is_refunded.is_(False)),
        ),
    )


# ---------------------------------------------------------------------------
# 6. SystemFeature (For Country-Wise Feature Flag)
# ---------------------------------------------------------------------------
class SystemFeature(Base):
    __tablename__ = "system_features"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    feature_key: Mapped[str] = mapped_column(
        String(64), nullable=False
    )  # 'vehicle_rental', 'direct_chat', etc.
    country_code: Mapped[str] = mapped_column(
        String(4), nullable=False
    )  # 'BD', 'IN', 'US', '*'
    is_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    config: Mapped[dict[str, Any]] = mapped_column(
        JSONB, default=dict, nullable=False
    )
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    updated_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )

    __table_args__ = (
        UniqueConstraint(
            "feature_key", "country_code", name="uq_system_features_key_country"
        ),
        Index(
            "idx_system_features_lookup",
            feature_key,
            country_code,
            is_enabled,
        ),
    )


# ---------------------------------------------------------------------------
# 7. User (End-user public profile)
# ---------------------------------------------------------------------------
class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    country_code: Mapped[str] = mapped_column(String(4), nullable=False, index=True)
    phone_number: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    full_name: Mapped[Optional[str]] = mapped_column(String(150), nullable=True)
    preferred_language: Mapped[str] = mapped_column(String(8), default="en", nullable=False)
    preferred_currency: Mapped[str] = mapped_column(String(4), default="BDT", nullable=False)
    avatar_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    kyc_status: Mapped[str] = mapped_column(String(32), default="unverified", nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="active", nullable=False)
    wallet_balance: Mapped[float] = mapped_column(Numeric(14, 2), default=0.00, nullable=False)

    __table_args__ = (
        UniqueConstraint("country_code", "phone_number", name="uq_users_country_phone"),
    )


# ---------------------------------------------------------------------------
# 8. StaffUser (Admin & Founder Portal)
# ---------------------------------------------------------------------------
class StaffUser(Base):
    __tablename__ = "staff_users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    phone_number: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    role_key: Mapped[str] = mapped_column(String(64), default="founder", nullable=False)
    is_totp_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    totp_secret_encrypted: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    allowed_countries: Mapped[list[str]] = mapped_column(JSONB, default=lambda: ["*"], nullable=False)
    ip_whitelist: Mapped[Optional[list[str]]] = mapped_column(JSONB, default=list, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


# ---------------------------------------------------------------------------
# 9. AuditLog (Immutable Action Trail)
# ---------------------------------------------------------------------------
class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    actor_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), nullable=True, index=True)
    actor_type: Mapped[str] = mapped_column(String(32), nullable=False)  # 'founder', 'staff', 'system'
    action: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    entity_name: Mapped[str] = mapped_column(String(64), nullable=False)
    entity_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    country_code: Mapped[Optional[str]] = mapped_column(String(4), nullable=True)
    ip_address: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    previous_state: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB, nullable=True)
    new_state: Mapped[Optional[dict[str, Any]]] = mapped_column(JSONB, nullable=True)
    meta_info: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)


# ---------------------------------------------------------------------------
# 10. Payment (Financial Transactions)
# ---------------------------------------------------------------------------
class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    country_code: Mapped[str] = mapped_column(String(4), nullable=False)
    gateway_key: Mapped[str] = mapped_column(String(32), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(14, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(4), nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="initiated", nullable=False)
    transaction_reference: Mapped[str] = mapped_column(String(128), unique=True, nullable=False, index=True)
    purpose: Mapped[str] = mapped_column(String(32), nullable=False)  # 'record_unlock'
    purpose_record_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("entity_records.id", ondelete="SET NULL"),
        nullable=True,
    )
    gateway_response: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


# ---------------------------------------------------------------------------
# 11. Conversation (Post-Unlock Direct Chat Channels)
# ---------------------------------------------------------------------------
class Conversation(Base):
    __tablename__ = "conversations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    record_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("entity_records.id", ondelete="CASCADE"), nullable=False
    )
    buyer_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    seller_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    unlock_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("record_unlocks.id", ondelete="CASCADE"), nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    last_message_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, nullable=False
    )

    messages: Mapped[List["Message"]] = relationship(
        "Message", back_populates="conversation", cascade="all, delete-orphan"
    )

    __table_args__ = (
        UniqueConstraint("record_id", "buyer_user_id", name="uq_conversations_record_buyer"),
    )


# ---------------------------------------------------------------------------
# 12. Message (Chat messages between buyer and seller)
# ---------------------------------------------------------------------------
class Message(Base):
    __tablename__ = "messages"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    sender_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    message_text: Mapped[str] = mapped_column(Text, nullable=False)
    attachment_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, nullable=False
    )

    conversation: Mapped["Conversation"] = relationship("Conversation", back_populates="messages")


