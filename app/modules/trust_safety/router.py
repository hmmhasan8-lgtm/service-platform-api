"""
MODULE 1: Trust & Safety - NID + Face Verification.
Provides endpoints for:
1. POST /verifications/submit - Provider uploads NID + Selfie
2. GET /verifications/pending - Staff Panel sees pending queue
3. PUT /verifications/{id}/approve - Staff approves -> user.is_verified = True
4. PUT /verifications/{id}/reject - Staff rejects with note
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.dynamic_engine.models import ProviderVerification, User

router = APIRouter(prefix="/verifications", tags=["MODULE 1: Trust & Safety (NID & Selfie)"])


class SubmitVerificationPayload(BaseModel):
    user_id: uuid.UUID
    nid_front_image_url: str = Field(..., min_length=5)
    nid_back_image_url: str = Field(..., min_length=5)
    selfie_image_url: str = Field(..., min_length=5)


class RejectVerificationPayload(BaseModel):
    rejection_reason: str = Field("NID ছবি অস্পষ্ট বা মুখের সাথে মিলেনি", min_length=3)


@router.post("/submit", status_code=status.HTTP_201_CREATED)
async def submit_verification(
    payload: SubmitVerificationPayload,
    db: AsyncSession = Depends(get_db),
):
    """Provider uploads NID front, back, and selfie for Staff verification."""
    # Check if existing pending
    stmt = (
        select(ProviderVerification)
        .where(
            and_(
                ProviderVerification.user_id == payload.user_id,
                ProviderVerification.status == "pending",
            )
        )
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        return {
            "status": "pending",
            "message": "আপনার NID ভেরিফিকেশন ইতিমধ্যে অপেক্ষমান রয়েছে।",
            "verification_id": str(existing.id),
        }

    verification = ProviderVerification(
        user_id=payload.user_id,
        nid_front_image_url=payload.nid_front_image_url,
        nid_back_image_url=payload.nid_back_image_url,
        selfie_image_url=payload.selfie_image_url,
        status="pending",
    )
    db.add(verification)
    await db.commit()
    await db.refresh(verification)

    return {
        "status": "success",
        "message": "NID ও সেলফি সফলভাবে জমা হয়েছে। কর্মকর্তা পর্যালোচনার পর অনুমোদন দেওয়া হবে।",
        "verification_id": str(verification.id),
    }


@router.get("/pending")
async def list_pending_verifications(
    db: AsyncSession = Depends(get_db),
):
    """Staff Panel fetches pending verification requests."""
    stmt = (
        select(ProviderVerification)
        .where(ProviderVerification.status == "pending")
        .order_by(ProviderVerification.created_at.asc())
    )
    res = await db.execute(stmt)
    records = res.scalars().all()

    return {
        "status": "success",
        "count": len(records),
        "verifications": [
            {
                "id": str(v.id),
                "user_id": str(v.user_id),
                "nid_front_image_url": v.nid_front_image_url,
                "nid_back_image_url": v.nid_back_image_url,
                "selfie_image_url": v.selfie_image_url,
                "status": v.status,
                "created_at": v.created_at.isoformat(),
            }
            for v in records
        ],
    }


@router.put("/{verification_id}/approve")
async def approve_verification(
    verification_id: uuid.UUID,
    staff_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
):
    """Staff approves provider verification -> user.is_verified = True."""
    stmt = select(ProviderVerification).where(ProviderVerification.id == verification_id)
    verification = (await db.execute(stmt)).scalar_one_or_none()
    if not verification:
        raise HTTPException(status_code=404, detail="Verification request not found")

    now = datetime.now(timezone.utc)
    verification.status = "verified"
    verification.verified_at = now
    verification.verified_by_staff_id = staff_id

    # Update User table
    user_stmt = select(User).where(User.id == verification.user_id)
    user = (await db.execute(user_stmt)).scalar_one_or_none()
    if user:
        user.is_verified = True
        user.kyc_status = "verified"

    await db.commit()

    return {
        "status": "success",
        "message": "প্রোভাইডারের NID ও ফেস ভেরিফিকেশন সফলভাবে অনুমোদিত হয়েছে। এখন থেকে তিনি রিকোয়েস্ট পাবেন।",
        "verification_id": str(verification.id),
        "user_id": str(verification.user_id),
        "is_verified": True,
    }


@router.put("/{verification_id}/reject")
async def reject_verification(
    verification_id: uuid.UUID,
    payload: RejectVerificationPayload,
    staff_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
):
    """Staff rejects provider verification with reason."""
    stmt = select(ProviderVerification).where(ProviderVerification.id == verification_id)
    verification = (await db.execute(stmt)).scalar_one_or_none()
    if not verification:
        raise HTTPException(status_code=404, detail="Verification request not found")

    verification.status = "rejected"
    verification.rejection_reason = payload.rejection_reason
    verification.verified_by_staff_id = staff_id

    user_stmt = select(User).where(User.id == verification.user_id)
    user = (await db.execute(user_stmt)).scalar_one_or_none()
    if user:
        user.is_verified = False
        user.kyc_status = "rejected"

    await db.commit()

    return {
        "status": "success",
        "message": "ভেরিফিকেশন প্রত্যাখ্যাত হয়েছে। প্রোভাইডারকে পুনরায় আবেদন করতে হবে।",
        "verification_id": str(verification.id),
        "rejection_reason": payload.rejection_reason,
    }


@router.get("/status/{user_id}")
async def get_user_verification_status(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Checks if a provider is verified."""
    user_stmt = select(User).where(User.id == user_id)
    user = (await db.execute(user_stmt)).scalar_one_or_none()

    stmt = (
        select(ProviderVerification)
        .where(ProviderVerification.user_id == user_id)
        .order_by(ProviderVerification.created_at.desc())
    )
    v = (await db.execute(stmt)).scalars().first()

    is_verified = (user.is_verified if user else False) or (v.status == "verified" if v else False)

    return {
        "user_id": str(user_id),
        "is_verified": is_verified,
        "latest_verification_status": v.status if v else "not_submitted",
        "rejection_reason": v.rejection_reason if v else None,
    }
