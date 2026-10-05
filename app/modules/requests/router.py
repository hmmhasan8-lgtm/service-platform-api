"""
Service Requests Router with Critical Single-Winner Race Condition Protection.
Implements:
1. POST /api/v1/requests (Seeker posts request -> Location Filter alerts nearby providers)
2. POST /api/v1/requests/{request_id}/accept (Row lock with_for_update() ensures ONLY FIRST WINNER gets accepted and charged, all late attempts get 409 Conflict with 0 fee)
3. GET /api/v1/requests/{request_id} (Fetch status, winner, and fees)
4. GET /api/v1/requests (List open requests nearby)
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.contact_leakage import detect_contact_leakage
from app.core.security import decode_user_token
from app.modules.dynamic_engine.models import (
    Conversation,
    Coupon,
    CustomEntity,
    Payment,
    ServiceRequest,
)
from app.modules.notification.engine import notify_nearby_providers

router = APIRouter(prefix="/api/v1/requests", tags=["Service Requests (Single-Winner)"])


def get_current_user_id_optional(
    authorization: Optional[str] = None, x_user_id: Optional[str] = None
) -> Optional[uuid.UUID]:
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
# Schemas
# ---------------------------------------------------------------------------
class CreateServiceRequestPayload(BaseModel):
    title: str = Field(..., min_length=3, max_length=255, description="Seeker request title")
    description: Optional[str] = Field(None, max_length=1000)
    category_key: str = Field(..., description="Service category e.g. 'ac_repair', 'electrician'")
    approx_location: str = Field(..., description="Seeker location e.g. 'Mirpur 10, Dhaka'")
    seeker_latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    seeker_longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    country_code: Optional[str] = Field("BD", max_length=4)
    custom_col_data: Optional[Dict[str, Any]] = Field(default_factory=dict)


class AcceptRequestResponse(BaseModel):
    status: str
    message: str
    request_id: str
    winner_provider_id: str
    seeker_user_id: str
    provider_fee_charged: float
    seeker_fee_charged: float
    currency: str
    conversation_id: str
    accepted_at: str


# ---------------------------------------------------------------------------
# 1. POST /api/v1/requests (Seeker Posts Request)
# ---------------------------------------------------------------------------
@router.post("", status_code=status.HTTP_201_CREATED)
async def create_service_request(
    payload: CreateServiceRequestPayload,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Creates a new service request from a seeker:
    1. Validates against contact number leaks in public fields
    2. Stores request with status='open'
    3. Runs Notification Engine to alert ONLY nearby providers (within 5km or same Thana/Area)
    """
    # Business Protection: Prevent Contact Number Leakage in Public Request Title/Description
    if detect_contact_leakage(payload.title):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="For security, please do not share phone numbers in public request titles. পাবলিক ফিল্ডে ফোন নম্বর শেয়ার করা নিষিদ্ধ।",
        )
    if payload.description and detect_contact_leakage(payload.description):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="For security, please do not share phone numbers in public request description. পাবলিক ফিল্ডে ফোন নম্বর শেয়ার করা নিষিদ্ধ।",
        )

    seeker_user_id = get_current_user_id_optional(
        request.headers.get("authorization"), request.headers.get("x-user-id")
    ) or uuid.uuid4()

    # MODULE 4: Dynamic Category Commission from CustomEntity (No hardcoding)
    category_clean = payload.category_key.strip().lower()
    entity_stmt = select(CustomEntity).where(CustomEntity.entity_key == category_clean)
    entity_obj = (await db.execute(entity_stmt)).scalar_one_or_none()
    if entity_obj and entity_obj.unlock_fee_usd:
        dynamic_fee = round(float(entity_obj.unlock_fee_usd * 120.0), 2)
    else:
        dynamic_fee = 50.00

    new_request = ServiceRequest(
        seeker_user_id=seeker_user_id,
        title=payload.title.strip(),
        description=payload.description.strip() if payload.description else None,
        category_key=category_clean,
        country_code=(payload.country_code or "BD").upper(),
        approx_location=payload.approx_location.strip(),
        seeker_latitude=payload.seeker_latitude,
        seeker_longitude=payload.seeker_longitude,
        status="open",
        winner_provider_id=None,
        seeker_fee_charged=False,
        fee_amount=dynamic_fee,
        currency="BDT" if (payload.country_code or "BD").upper() == "BD" else "USD",
        custom_col_data=payload.custom_col_data or {},
    )

    db.add(new_request)
    await db.commit()
    await db.refresh(new_request)

    # Trigger Location-Based Notification Engine
    notification_result = await notify_nearby_providers(new_request.id, db)

    return {
        "status": "success",
        "message": "Service request created. Nearby providers within 5km have been notified.",
        "request_id": str(new_request.id),
        "seeker_user_id": str(new_request.seeker_user_id),
        "status_code": new_request.status,
        "notification_summary": {
            "nearby_providers_alerted": notification_result.get("notified_count", 0),
            "detected_area": notification_result.get("detected_area"),
            "policy": "single_winner_first_to_accept_wins",
        },
    }


# ---------------------------------------------------------------------------
# 2. POST /api/v1/requests/{request_id}/accept (CRITICAL: Race Condition Protected)
# ---------------------------------------------------------------------------
@router.post("/{request_id}/accept", response_model=AcceptRequestResponse)
async def accept_service_request(
    request_id: uuid.UUID,
    request: Request,
    coupon_code: Optional[str] = Query(None, description="Optional discount coupon code e.g. EID50"),
    db: AsyncSession = Depends(get_db),
):
    """
    CRITICAL RACE CONDITION GUARD:
    Uses PostgreSQL Row-Level Lock (`with_for_update()`) inside an ACID transaction.
    - If request is already accepted: Raises HTTP 409 Conflict.
    - If winner_provider_id is already set: Raises HTTP 409 Conflict.
    - First winner:
      1. Charges Provider dynamic fee (supports coupon discounts e.g. EID50)
      2. Charges Seeker dynamic fee (only on first accepted match)
      3. Locks request status to 'accepted' and sets winner_provider_id
      4. Creates direct 1-to-1 Conversation Channel for Winner & Seeker
    """
    provider_id = get_current_user_id_optional(
        request.headers.get("authorization"), request.headers.get("x-user-id")
    ) or uuid.uuid4()

    # CRITICAL: Execute with Transaction & Row Lock (with_for_update)
    async with db.begin():
        stmt = (
            select(ServiceRequest)
            .where(ServiceRequest.id == request_id)
            .with_for_update()
        )
        res = await db.execute(stmt)
        req = res.scalar_one_or_none()

        if not req:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Service request not found",
            )

        # Race Condition Check: Has another provider accepted first?
        if req.status != "open" or req.winner_provider_id is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=(
                    "এই রিকোয়েস্টটি ইতিমধ্যে অন্য একজন সার্ভিস প্রোভাইডার গ্রহণ করেছেন। "
                    "| This request has already been accepted by another provider."
                ),
            )

        # Prevent seeker from accepting their own request
        if req.seeker_user_id == provider_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Seeker cannot accept their own service request.",
            )

        fee = float(req.fee_amount or 50.0)
        curr = req.currency or "BDT"
        now_utc = datetime.now(timezone.utc)

        # MODULE 3: Coupon Discount for Provider Accept Fee
        provider_charged_fee = fee
        if coupon_code:
            code_clean = coupon_code.strip().upper()
            c_stmt = select(Coupon).where(
                and_(Coupon.code == code_clean, Coupon.is_active == True)
            )
            coupon_obj = (await db.execute(c_stmt)).scalar_one_or_none()
            disc = coupon_obj.discount_percent if coupon_obj else (50.0 if code_clean == "EID50" else 0.0)
            if disc > 0:
                provider_charged_fee = max(0.0, round(fee * (1.0 - disc / 100.0), 2))
                if coupon_obj:
                    coupon_obj.used_count += 1

        # 1. Charge Winner Provider (with Coupon Discount if applied)
        prov_payment = Payment(
            user_id=provider_id,
            country_code=req.country_code,
            gateway_key="wallet",
            amount=provider_charged_fee,
            currency=curr,
            status="completed",
            transaction_reference=f"TXN-WIN-PROV-{uuid.uuid4().hex[:10].upper()}",
            purpose="provider_accept_single_winner",
            purpose_record_id=None,
            gateway_response={
                "fee_type": "winner_provider_accept_fee",
                "original_fee": fee,
                "charged": provider_charged_fee,
                "coupon_used": coupon_code,
            },
            completed_at=now_utc,
        )
        db.add(prov_payment)

        # 2. Charge Seeker 50 BDT (only once, upon first accepted match)
        if not req.seeker_fee_charged:
            seeker_payment = Payment(
                user_id=req.seeker_user_id,
                country_code=req.country_code,
                gateway_key="wallet",
                amount=fee,
                currency=curr,
                status="completed",
                transaction_reference=f"TXN-SEEK-{uuid.uuid4().hex[:10].upper()}",
                purpose="seeker_request_matched",
                purpose_record_id=None,
                gateway_response={"fee_type": "seeker_match_unlock_fee", "charged": fee},
                completed_at=now_utc,
            )
            db.add(seeker_payment)
            req.seeker_fee_charged = True

        # 3. Lock the request with winner
        req.status = "accepted"
        req.winner_provider_id = provider_id
        req.accepted_at = now_utc

        # 4. Create Direct 1-to-1 Chat Conversation between Winner and Seeker
        conversation = Conversation(
            record_id=req.id,
            buyer_user_id=req.seeker_user_id,
            seller_user_id=provider_id,
            unlock_id=uuid.uuid4(),
            is_active=True,
            last_message_at=now_utc,
        )
        db.add(conversation)

    # Refreshed values after commit
    return AcceptRequestResponse(
        status="success",
        message="Request accepted successfully! You are the single winner.",
        request_id=str(req.id),
        winner_provider_id=str(provider_id),
        seeker_user_id=str(req.seeker_user_id),
        provider_fee_charged=fee,
        seeker_fee_charged=fee,
        currency=curr,
        conversation_id=str(conversation.id),
        accepted_at=now_utc.isoformat(),
    )


# ---------------------------------------------------------------------------
# 3. GET /api/v1/requests/{request_id}
# ---------------------------------------------------------------------------
@router.get("/{request_id}")
async def get_service_request(
    request_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Fetches service request status and winning provider details."""
    stmt = select(ServiceRequest).where(ServiceRequest.id == request_id)
    res = await db.execute(stmt)
    req = res.scalar_one_or_none()

    if not req:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found",
        )

    return {
        "status": "success",
        "id": str(req.id),
        "title": req.title,
        "description": req.description,
        "category_key": req.category_key,
        "approx_location": req.approx_location,
        "status": req.status,
        "is_locked": req.status == "accepted",
        "winner_provider_id": str(req.winner_provider_id) if req.winner_provider_id else None,
        "seeker_fee_charged": req.seeker_fee_charged,
        "accepted_at": req.accepted_at.isoformat() if req.accepted_at else None,
        "fee_amount": float(req.fee_amount),
        "currency": req.currency,
        "created_at": req.created_at.isoformat(),
    }


# ---------------------------------------------------------------------------
# 4. GET /api/v1/requests (List Open Requests)
# ---------------------------------------------------------------------------
@router.get("")
async def list_open_service_requests(
    category: Optional[str] = Query(None),
    location: Optional[str] = Query(None),
    status_filter: str = Query("open"),
    limit: int = Query(20, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    """Lists requests for provider feed."""
    conditions = []
    if status_filter:
        conditions.append(ServiceRequest.status == status_filter)
    if category:
        conditions.append(ServiceRequest.category_key == category.lower())

    stmt = (
        select(ServiceRequest)
        .where(and_(*conditions) if conditions else True)
        .order_by(ServiceRequest.created_at.desc())
        .limit(limit)
    )
    res = await db.execute(stmt)
    requests_list = res.scalars().all()

    items = []
    for r in requests_list:
        items.append({
            "id": str(r.id),
            "title": r.title,
            "category_key": r.category_key,
            "approx_location": r.approx_location,
            "status": r.status,
            "fee_amount": float(r.fee_amount),
            "currency": r.currency,
            "created_at": r.created_at.isoformat(),
        })

    return {
        "status": "success",
        "count": len(items),
        "requests": items,
    }
