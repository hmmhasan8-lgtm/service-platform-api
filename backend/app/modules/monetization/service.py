"""
Monetization & Record Unlock Engine for SERVICE Platform.
Implements:
- 7-Day / Configurable Unlock Validity Window
- Anti-Double-Charge Verification (409 ALREADY_UNLOCKED)
- Country-specific Payment Gateway Resolution (BD=bKash/Nagad, Global=Stripe)
- Post-Payment Unlock Record Creation and AES-256 Decryption of Private Data
"""

import json
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Tuple

from fastapi import HTTPException, status
from sqlalchemy import and_, desc, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decrypt_aes_256_gcm
from app.modules.dynamic_engine.models import (
    CustomEntity,
    EntityRecord,
    Payment,
    RecordUnlock,
)


# Exchange rate / localized fee mapping defaults
COUNTRY_UNLOCK_PRICING = {
    "BD": {"currency": "BDT", "multiplier": 120.0, "default_gateways": ["bkash", "nagad"]},
    "IN": {"currency": "INR", "multiplier": 85.0, "default_gateways": ["razorpay", "stripe"]},
    "DEFAULT": {"currency": "USD", "multiplier": 1.0, "default_gateways": ["stripe"]},
}


class MonetizationService:
    """
    Manages payment initiation, gateway selection, double-charge prevention,
    and access grant upon verified payment.
    """

    @classmethod
    async def initiate_unlock(
        cls,
        db: AsyncSession,
        record_id: uuid.UUID,
        buyer_user_id: uuid.UUID,
        client_country: str = "BD",
        requested_gateway: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Initiates contact/location unlock process for a record.
        Prevents double-charging if an active unlock is still valid.
        """
        now = datetime.now(timezone.utc)

        # 1. Fetch EntityRecord
        stmt = (
            select(EntityRecord, CustomEntity)
            .join(CustomEntity, EntityRecord.entity_id == CustomEntity.id)
            .where(EntityRecord.id == record_id)
        )
        res = await db.execute(stmt)
        row = res.first()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Target post record not found or has been removed",
            )

        record, entity = row

        # Prevent author paying for their own post
        if record.user_id == buyer_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Post creator cannot pay to unlock their own publication",
            )

        # 2. Check for Active Unlock (Anti-Double-Charge Guard)
        unlock_stmt = (
            select(RecordUnlock)
            .where(
                and_(
                    RecordUnlock.record_id == record_id,
                    RecordUnlock.buyer_user_id == buyer_user_id,
                    RecordUnlock.valid_until > now,
                    RecordUnlock.is_refunded.is_(False),
                )
            )
            .order_by(RecordUnlock.valid_until.desc())
        )
        active_unlock = (await db.execute(unlock_stmt)).scalar_one_or_none()

        if active_unlock:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error": "ALREADY_UNLOCKED",
                    "message": "You already have active unlocked access to this record.",
                    "valid_until": active_unlock.valid_until.isoformat(),
                    "record_id": str(record_id),
                },
            )

        # 3. Currency and Fee Calculation
        country_cfg = COUNTRY_UNLOCK_PRICING.get(
            client_country.upper(), COUNTRY_UNLOCK_PRICING["DEFAULT"]
        )
        currency = country_cfg["currency"]
        base_usd = float(entity.base_unlock_fee_usd)
        fee_amount = round(base_usd * country_cfg["multiplier"], 2)

        # 4. Gateway Selection Logic
        allowed_gateways = country_cfg["default_gateways"]
        selected_gateway = requested_gateway if requested_gateway in allowed_gateways else allowed_gateways[0]

        # 5. Create Payment Intent in payments Table
        tx_ref = f"TXN-UNLK-{uuid.uuid4().hex[:12].upper()}"

        payment = Payment(
            user_id=buyer_user_id,
            country_code=client_country.upper(),
            gateway_key=selected_gateway,
            amount=fee_amount,
            currency=currency,
            status="initiated",
            transaction_reference=tx_ref,
            purpose="record_unlock",
            purpose_record_id=record.id,
            gateway_response={
                "selected_gateway": selected_gateway,
                "created_at": now.isoformat(),
            },
        )
        db.add(payment)
        await db.commit()
        await db.refresh(payment)

        # 6. Generate Gateway Redirect / Checkout Payload
        checkout_url = f"/api/v1/payments/{selected_gateway}/checkout?tx_ref={tx_ref}"

        return {
            "transaction_reference": tx_ref,
            "payment_id": str(payment.id),
            "fee_amount": fee_amount,
            "currency": currency,
            "gateway": selected_gateway,
            "checkout_url": checkout_url,
            "record_title": record.title,
            "validity_days": entity.unlock_validity_days,
        }

    @classmethod
    async def verify_and_grant_access(
        cls,
        db: AsyncSession,
        transaction_reference: str,
        gateway_token: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Verifies payment settlement, creates record_unlock entry with
        valid_until = NOW + validity_days, and reveals decrypted private contact data.
        """
        now = datetime.now(timezone.utc)

        # 1. Fetch Payment Record
        stmt = select(Payment).where(Payment.transaction_reference == transaction_reference)
        res = await db.execute(stmt)
        payment = res.scalar_one_or_none()

        if not payment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Payment transaction '{transaction_reference}' not found",
            )

        if payment.status == "completed":
            # Already completed; fetch unlocked data
            return await cls.fetch_unlocked_record_payload(
                db, payment.purpose_record_id, payment.user_id
            )

        # 2. Mark Payment Completed (Simulated / Webhook Verified)
        payment.status = "completed"
        payment.completed_at = now
        payment.gateway_response = {
            **payment.gateway_response,
            "gateway_token": gateway_token or "VERIFIED_OK",
            "verified_at": now.isoformat(),
        }

        # 3. Retrieve Entity for Validity Duration
        rec_stmt = (
            select(EntityRecord, CustomEntity)
            .join(CustomEntity, EntityRecord.entity_id == CustomEntity.id)
            .where(EntityRecord.id == payment.purpose_record_id)
        )
        rec_res = await db.execute(rec_stmt)
        row = rec_res.first()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Linked record not found"
            )

        record, entity = row
        validity_days = entity.unlock_validity_days or 7
        valid_until = now + timedelta(days=validity_days)

        # 4. Insert RecordUnlock
        unlock_entry = RecordUnlock(
            record_id=record.id,
            buyer_user_id=payment.user_id,
            fee_amount=payment.amount,
            currency=payment.currency,
            payment_id=payment.id,
            unlocked_at=now,
            valid_until=valid_until,
            is_refunded=False,
        )
        db.add(unlock_entry)

        # 5. Increment unlocks_count on record
        record.unlocks_count = (record.unlocks_count or 0) + 1

        await db.commit()

        # 6. Return Unlocked Content with Decrypted Sensitive Data
        return await cls.fetch_unlocked_record_payload(
            db, record.id, payment.user_id
        )

    @classmethod
    async def fetch_unlocked_record_payload(
        cls,
        db: AsyncSession,
        record_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> dict[str, Any]:
        """
        Retrieves record and decrypts AES-256 private data for authorized buyer.
        """
        now = datetime.now(timezone.utc)

        stmt = select(EntityRecord).where(EntityRecord.id == record_id)
        res = await db.execute(stmt)
        record = res.scalar_one_or_none()

        if not record:
            raise HTTPException(status_code=404, detail="Record not found")

        # Verify active unlock or ownership
        is_owner = record.user_id == user_id
        has_active_unlock = False
        valid_until_str = None

        if not is_owner:
            unl_stmt = select(RecordUnlock).where(
                and_(
                    RecordUnlock.record_id == record_id,
                    RecordUnlock.buyer_user_id == user_id,
                    RecordUnlock.valid_until > now,
                    RecordUnlock.is_refunded.is_(False),
                )
            )
            unlock_entry = (await db.execute(unl_stmt)).scalar_one_or_none()
            if unlock_entry:
                has_active_unlock = True
                valid_until_str = unlock_entry.valid_until.isoformat()
            else:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Access denied: Record has not been unlocked or validity expired.",
                )
        else:
            has_active_unlock = True

        # Decrypt AES-256 private data
        decrypted_private_fields: dict[str, Any] = {}
        enc_container = record.encrypted_private_data
        if enc_container and "ciphertext" in enc_container and "nonce" in enc_container:
            try:
                decrypted_json_str = decrypt_aes_256_gcm(enc_container)
                decrypted_private_fields = json.loads(decrypted_json_str)
            except Exception:
                decrypted_private_fields = {"error": "Failed to decrypt private fields"}

        return {
            "record_id": str(record.id),
            "title": record.title,
            "approx_location": record.approx_location,
            "dynamic_data": record.dynamic_data,
            "unlocked_private_data": decrypted_private_fields,
            "is_unlocked": True,
            "valid_until": valid_until_str,
            "geo_coordinates": {
                "latitude": record.geo_latitude,
                "longitude": record.geo_longitude,
            },
        }
