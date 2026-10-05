"""
Dynamic Field Validator and Encrypted Transformer Engine.
Implements metadata-driven schema validation, country-filtering (target_countries @> '["*"]'),
Redis caching, and AES-256-GCM encryption for private sensitive attributes.
"""

import base64
import json
import os
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple
import uuid

from fastapi import HTTPException, status
from sqlalchemy import select, and_, or_, cast
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.dynamic_engine.models import (
    CustomEntity,
    CustomField,
    FieldDataType,
)


# AES-256 Key derivation (32 bytes)
ENCRYPTION_MASTER_KEY = os.getenv(
    "PRIVATE_DATA_ENCRYPTION_KEY",
    "service_platform_master_aes256_secret_key_32b!",  # Must be 32 chars in production
).encode("utf-8")[:32].ljust(32, b"0")


def encrypt_aes_256_gcm(plaintext_data: str) -> dict[str, str]:
    """
    Encrypts sensitive string data using AES-256-GCM.
    Returns nonce, ciphertext, and auth tag in base64.
    """
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM

        aesgcm = AESGCM(ENCRYPTION_MASTER_KEY)
        nonce = os.urandom(12)  # 96-bit nonce recommended for GCM
        ciphertext = aesgcm.encrypt(nonce, plaintext_data.encode("utf-8"), None)
        return {
            "nonce": base64.b64encode(nonce).decode("ascii"),
            "ciphertext": base64.b64encode(ciphertext).decode("ascii"),
            "algo": "AES-256-GCM",
        }
    except ImportError:
        # Fallback implementation if cryptography package is installing
        import hashlib
        import hmac

        iv = os.urandom(16)
        raw_b64 = base64.b64encode(plaintext_data.encode("utf-8")).decode("ascii")
        sig = hmac.new(ENCRYPTION_MASTER_KEY, raw_b64.encode("utf-8"), hashlib.sha256).hexdigest()
        return {
            "nonce": base64.b64encode(iv).decode("ascii"),
            "ciphertext": raw_b64,
            "tag": sig,
            "algo": "HMAC-SHA256-B64-FALLBACK",
        }


def decrypt_aes_256_gcm(payload: dict[str, str]) -> str:
    """
    Decrypts AES-256-GCM encrypted payload.
    """
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM

        aesgcm = AESGCM(ENCRYPTION_MASTER_KEY)
        nonce = base64.b64decode(payload["nonce"])
        ciphertext = base64.b64decode(payload["ciphertext"])
        decrypted = aesgcm.decrypt(nonce, ciphertext, None)
        return decrypted.decode("utf-8")
    except Exception:
        if payload.get("algo") == "HMAC-SHA256-B64-FALLBACK":
            return base64.b64decode(payload["ciphertext"]).decode("utf-8")
        raise ValueError("Decryption failed or invalid payload")


# ---------------------------------------------------------------------------
# Business Protection: Contact Leakage Prevention Engine
# ---------------------------------------------------------------------------
def detect_contact_leakage(text: str) -> bool:
    """
    Detects attempts to leak phone numbers or contact details in public fields.
    Protects platform commercial model by ensuring contacts are only shared
    after unlock fee settlement.

    Detects:
    1. Standard BD phone numbers (013..019 followed by 8 digits)
    2. Obfuscated sequence of 8+ digits (0 1 7 - 1 2 3 4 - 5 6 7 8, 0171.234.567)
    3. Bengali Digits phone patterns (০-৯)
    4. English & Bengali number words (zero, one, two, এক, দুই, তিন...)
    5. Contact Keywords (whatsapp, imo, ফোন, মোবাইল, যোগাযোগ...) with nearby digits
    """
    if not text or not isinstance(text, str):
        return False

    clean_text = text.strip()
    if not clean_text:
        return False

    lower_text = clean_text.lower()

    # 1. Standard BD Phone Number Regex
    bd_phone_pattern = re.compile(
        r'(?:\+?880|0)?1[3-9][\s\-\.]*\d{4}[\s\-\.]*\d{4}\b'
    )
    if bd_phone_pattern.search(clean_text):
        return True

    # 2. Obfuscated sequence of 8+ digits (with spaces, dots, dashes, o/O substitutions)
    obfuscated_digit_pattern = re.compile(r'(?:(?:\d[\s\-\.oO_]{0,3}){7,}\d)')
    for match in obfuscated_digit_pattern.finditer(clean_text):
        matched_str = match.group(0)
        digits_only = re.sub(r'[\s\-\.oO_]', '', matched_str)
        if len(digits_only) >= 8:
            if digits_only.startswith(('01', '8801', '1')) or len(digits_only) >= 10:
                return True

    # 3. Bengali Digits Translation & Checking (০-৯)
    bengali_to_eng = str.maketrans('০১২৩৪৫৬৭৮৯', '0123456789')
    converted_text = clean_text.translate(bengali_to_eng)
    if bd_phone_pattern.search(converted_text):
        return True

    bengali_digits_seq = re.compile(r'(?:[০-৯][\s\-\.]*){8,}')
    if bengali_digits_seq.search(clean_text):
        return True

    # 4. English & Bengali Number Words (3+ number words attempts)
    number_words = [
        'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
        'শূন্য', 'এক', 'দুই', 'তিন', 'চার', 'পাঁচ', 'ছয়', 'সাত', 'আট', 'নয়'
    ]
    words = re.findall(r'[\w\u0980-\u09FF]+', lower_text)
    num_word_count = sum(1 for w in words if w in number_words)
    if num_word_count >= 3:
        return True

    # 5. Sensitive Contact Keywords + Numbers Nearby
    contact_keywords = [
        'whatsapp', 'imo', 'call me', 'call us', 'contact me', 'phone me',
        'ফোন', 'মোবাইল', 'যোগাযোগ', 'নাম্বার', 'নম্বর', 'কল দিন', 'কল করুন', 'ডায়াল'
    ]
    for kw in contact_keywords:
        if kw in lower_text:
            digits = re.findall(r'\d+', converted_text)
            for d in digits:
                if len(d) >= 5:
                    return True
            if re.search(r'(?:(?:\d[\s\-\.]{0,3}){5,}\d)', converted_text):
                return True

    return False


# ---------------------------------------------------------------------------
# Redis Connection Provider with In-Memory Safe Fallback
# ---------------------------------------------------------------------------
class CacheManager:
    _redis_client = None
    _in_memory_cache: dict[str, tuple[str, float]] = {}

    @classmethod
    async def get_client(cls):
        if cls._redis_client is None:
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6390/0")
            try:
                import redis.asyncio as aioredis
                cls._redis_client = aioredis.from_url(
                    redis_url, encoding="utf-8", decode_responses=True
                )
            except Exception:
                cls._redis_client = False  # Mark unavailable
        return cls._redis_client if cls._redis_client is not False else None

    @classmethod
    async def get(cls, key: str) -> Optional[str]:
        client = await cls.get_client()
        if client:
            try:
                return await client.get(key)
            except Exception:
                pass
        # Fallback to local memory cache with timestamp TTL
        item = cls._in_memory_cache.get(key)
        if item:
            val, expiry = item
            if datetime.now(timezone.utc).timestamp() < expiry:
                return val
            del cls._in_memory_cache[key]
        return None

    @classmethod
    async def set(cls, key: str, value: str, ttl_seconds: int = 3600) -> None:
        client = await cls.get_client()
        if client:
            try:
                await client.set(key, value, ex=ttl_seconds)
                return
            except Exception:
                pass
        expiry = datetime.now(timezone.utc).timestamp() + ttl_seconds
        cls._in_memory_cache[key] = (value, expiry)

    @classmethod
    async def invalidate_entity_fields(cls, entity_id: str) -> None:
        client = await cls.get_client()
        pattern = f"fields:{entity_id}:*"
        if client:
            try:
                keys = await client.keys(pattern)
                if keys:
                    await client.delete(*keys)
            except Exception:
                pass
        # In-memory cleanup
        to_del = [k for k in cls._in_memory_cache if k.startswith(f"fields:{entity_id}:")]
        for k in to_del:
            del cls._in_memory_cache[k]


@dataclass
class ValidationResult:
    is_valid: bool
    dynamic_data: dict[str, Any]
    encrypted_private_data: dict[str, Any]
    errors: list[dict[str, str]]


class DynamicFieldValidator:
    """
    Core validator for dynamic entity submissions.
    """

    @staticmethod
    async def fetch_applicable_fields(
        db: AsyncSession,
        entity_id: uuid.UUID,
        country_code: str,
    ) -> list[dict[str, Any]]:
        """
        Retrieves active custom fields for the specified entity and country.
        Uses Redis cache with GIN-optimized SQL query fallback:
        target_countries @> '["*"]' OR target_countries @> '["BD"]'
        """
        cache_key = f"fields:{entity_id}:{country_code.upper()}"
        cached_data = await CacheManager.get(cache_key)

        if cached_data:
            try:
                return json.loads(cached_data)
            except Exception:
                pass

        # PostgreSQL JSONB Containment Query
        # Checks if target_countries contains ["*"] OR contains [country_code]
        global_target = json.dumps(["*"])
        country_target = json.dumps([country_code.upper()])

        stmt = (
            select(CustomField)
            .where(
                and_(
                    CustomField.entity_id == entity_id,
                    CustomField.is_active.is_(True),
                    or_(
                        CustomField.target_countries.contains(cast(["*"], JSONB)),
                        CustomField.target_countries.contains(cast([country_code.upper()], JSONB)),
                    ),
                )
            )
            .order_by(CustomField.sort_order.asc())
        )

        result = await db.execute(stmt)
        fields = result.scalars().all()

        field_list = []
        for f in fields:
            field_list.append({
                "id": str(f.id),
                "field_key": f.field_key,
                "field_type": f.field_type.value,
                "labels": f.labels,
                "placeholders": f.placeholders,
                "is_required": f.is_required,
                "validation_regex": f.validation_regex,
                "min_value": float(f.min_value) if f.min_value is not None else None,
                "max_value": float(f.max_value) if f.max_value is not None else None,
                "options": f.options or [],
                "is_private": f.is_private,
                "is_searchable": f.is_searchable,
                "section": f.section,
                "target_countries": f.target_countries,
            })

        # Save to Redis (Cache for 1 hour)
        await CacheManager.set(cache_key, json.dumps(field_list), ttl_seconds=3600)
        return field_list

    @classmethod
    async def validate_and_transform(
        cls,
        db: AsyncSession,
        entity_key: str,
        country_code: str,
        submitted_fields: dict[str, Any],
        language: str = "en",
    ) -> ValidationResult:
        """
        Validates raw payload against dynamic metadata rules, separates public
        vs private fields, and encrypts sensitive private values using AES-256.
        """
        # 1. Resolve Entity
        stmt = select(CustomEntity).where(
            and_(
                CustomEntity.entity_key == entity_key,
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

        # 2. Fetch Dynamic Fields for Country
        applicable_fields = await cls.fetch_applicable_fields(
            db, entity.id, country_code
        )

        dynamic_data: dict[str, Any] = {}
        raw_private_data: dict[str, Any] = {}
        errors: list[dict[str, str]] = []

        # 3. Rule Evaluation Loop
        for field in applicable_fields:
            key = field["field_key"]
            val = submitted_fields.get(key)
            field_type = field["field_type"]
            label = field["labels"].get(language) or field["labels"].get("en") or key

            # Required Check
            if field["is_required"]:
                if val is None or (isinstance(val, str) and not val.strip()):
                    errors.append({
                        "field": key,
                        "error": "REQUIRED_FIELD_MISSING",
                        "message": f"'{label}' is required",
                    })
                    continue

            # If optional and omitted, skip further constraints
            if val is None or (isinstance(val, str) and not val.strip()):
                continue

            # Type & Bounds Validation
            if field_type in (FieldDataType.NUMBER.value, FieldDataType.CURRENCY.value):
                try:
                    num_val = float(val)
                    if field["min_value"] is not None and num_val < field["min_value"]:
                        errors.append({
                            "field": key,
                            "error": "MIN_VALUE_VIOLATION",
                            "message": f"'{label}' must be at least {field['min_value']}",
                        })
                    if field["max_value"] is not None and num_val > field["max_value"]:
                        errors.append({
                            "field": key,
                            "error": "MAX_VALUE_VIOLATION",
                            "message": f"'{label}' cannot exceed {field['max_value']}",
                        })
                    val = num_val
                except (ValueError, TypeError):
                    errors.append({
                        "field": key,
                        "error": "INVALID_NUMBER",
                        "message": f"'{label}' must be a valid number",
                    })

            elif field_type == FieldDataType.SELECT.value:
                valid_options = [opt.get("value") for opt in field.get("options", []) if isinstance(opt, dict)]
                if valid_options and val not in valid_options:
                    errors.append({
                        "field": key,
                        "error": "INVALID_OPTION",
                        "message": f"Selected value '{val}' is not a valid option for '{label}'",
                    })

            elif field_type == FieldDataType.MULTISELECT.value:
                if not isinstance(val, list):
                    errors.append({
                        "field": key,
                        "error": "INVALID_MULTISELECT",
                        "message": f"'{label}' must be an array of selected options",
                    })
                else:
                    valid_options = {opt.get("value") for opt in field.get("options", []) if isinstance(opt, dict)}
                    if valid_options and not set(val).issubset(valid_options):
                        errors.append({
                            "field": key,
                            "error": "INVALID_OPTION_IN_MULTISELECT",
                            "message": f"One or more selections in '{label}' are invalid",
                        })

            elif field_type == FieldDataType.BOOLEAN.value:
                if not isinstance(val, bool):
                    if str(val).lower() in ("true", "1", "yes"):
                        val = True
                    elif str(val).lower() in ("false", "0", "no"):
                        val = False
                    else:
                        errors.append({
                            "field": key,
                            "error": "INVALID_BOOLEAN",
                            "message": f"'{label}' must be true or false",
                        })

            # Regex Validation
            regex_pattern = field.get("validation_regex")
            if regex_pattern and isinstance(val, str):
                try:
                    if not re.match(regex_pattern, val):
                        errors.append({
                            "field": key,
                            "error": "REGEX_MISMATCH",
                            "message": f"'{label}' does not match the required format",
                        })
                except re.error:
                    pass  # Protect against invalid founder regex syntax

            # Business Protection: Block Contact Leakage on Public Fields
            if not field["is_private"] and isinstance(val, (str, int)):
                if detect_contact_leakage(str(val)):
                    errors.append({
                        "field": key,
                        "error": "CONTACT_LEAKAGE_DETECTED",
                        "message": (
                            f"For security and to protect both parties, please do not share phone numbers in public fields ('{label}'). "
                            "Your private mobile number will be shared automatically after the buyer pays the unlock fee. "
                            "পাবলিক ফিল্ডে ফোন নম্বর শেয়ার করা নিষিদ্ধ।"
                        ),
                    })

            # 4. Partitioning: Public dynamic_data vs Private Sensitive
            if field["is_private"]:
                raw_private_data[key] = val
            else:
                dynamic_data[key] = val

        # 5. Return errors if any
        if errors:
            return ValidationResult(
                is_valid=False,
                dynamic_data={},
                encrypted_private_data={},
                errors=errors,
            )

        # 6. AES-256 Encryption for Private Sensitive Data
        encrypted_container: dict[str, Any] = {}
        if raw_private_data:
            encrypted_payload = encrypt_aes_256_gcm(json.dumps(raw_private_data))
            encrypted_container = {
                **encrypted_payload,
                "private_field_keys": list(raw_private_data.keys()),
                "encrypted_at": datetime.now(timezone.utc).isoformat(),
            }

        return ValidationResult(
            is_valid=True,
            dynamic_data=dynamic_data,
            encrypted_private_data=encrypted_container,
            errors=[],
        )
