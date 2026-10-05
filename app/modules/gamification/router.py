"""
MODULE 2: Rating & Gamification - Two-Way Rating + Level System.
Provides endpoints for:
1. POST /requests/{id}/rate - Both seeker and provider can rate each other
2. GET /users/{id}/profile - Returns avg_rating, level (New/Silver/Gold/Platinum), total_jobs
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.dynamic_engine.models import Rating, ServiceRequest, User, UserStats

router = APIRouter(prefix="", tags=["MODULE 2: Rating & Gamification"])


class SubmitRatingPayload(BaseModel):
    rater_user_id: uuid.UUID
    rated_user_id: uuid.UUID
    rating: int = Field(..., ge=1, le=5, description="Star rating between 1 and 5")
    review_text: Optional[str] = Field(None, max_length=500)
    role: str = Field(..., description="'seeker_to_provider' or 'provider_to_seeker'")


def calculate_user_level(total_jobs: int) -> str:
    """
    Gamification Level Progression:
    0-9 jobs = New
    10-49 jobs = Silver
    50-99 jobs = Gold
    100+ jobs = Platinum
    """
    if total_jobs >= 100:
        return "Platinum"
    elif total_jobs >= 50:
        return "Gold"
    elif total_jobs >= 10:
        return "Silver"
    return "New"


@router.post("/requests/{request_id}/rate", status_code=status.HTTP_201_CREATED)
async def submit_rating(
    request_id: uuid.UUID,
    payload: SubmitRatingPayload,
    db: AsyncSession = Depends(get_db),
):
    """
    Submits a rating and updates the rated user's stats and level.
    Marks the request as 'completed' if not already marked.
    """
    # 1. Verify Request exists
    req_stmt = select(ServiceRequest).where(ServiceRequest.id == request_id)
    req = (await db.execute(req_stmt)).scalar_one_or_none()
    if req:
        # Mark as completed
        req.status = "completed"

    # 2. Check if already rated by this rater for this request
    existing_stmt = select(Rating).where(
        and_(
            Rating.request_id == request_id,
            Rating.rater_user_id == payload.rater_user_id,
            Rating.rated_user_id == payload.rated_user_id,
        )
    )
    existing = (await db.execute(existing_stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=400, detail="You have already rated this user for this service."
        )

    new_rating = Rating(
        request_id=request_id,
        rater_user_id=payload.rater_user_id,
        rated_user_id=payload.rated_user_id,
        rating=payload.rating,
        review_text=payload.review_text.strip() if payload.review_text else None,
        role=payload.role,
    )
    db.add(new_rating)
    await db.flush()

    # 3. Update UserStats
    stats_stmt = select(UserStats).where(UserStats.user_id == payload.rated_user_id)
    stats = (await db.execute(stats_stmt)).scalar_one_or_none()

    if not stats:
        stats = UserStats(
            user_id=payload.rated_user_id,
            total_jobs_completed=1,
            avg_rating=float(payload.rating),
            total_reviews=1,
            level="New",
        )
        db.add(stats)
    else:
        stats.total_jobs_completed += 1
        stats.total_reviews += 1
        # Recalculate average rating
        avg_stmt = select(func.avg(Rating.rating)).where(Rating.rated_user_id == payload.rated_user_id)
        avg_res = (await db.execute(avg_stmt)).scalar()
        stats.avg_rating = round(float(avg_res or payload.rating), 2)
        stats.level = calculate_user_level(stats.total_jobs_completed)

    await db.commit()

    return {
        "status": "success",
        "message": "রেটিং সফলভাবে জমা হয়েছে!",
        "rated_user_id": str(payload.rated_user_id),
        "new_avg_rating": stats.avg_rating,
        "total_jobs_completed": stats.total_jobs_completed,
        "level": stats.level,
    }


@router.get("/users/{user_id}/profile")
async def get_user_profile(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Returns user rating, level, completed jobs, and verification badge."""
    user_stmt = select(User).where(User.id == user_id)
    user = (await db.execute(user_stmt)).scalar_one_or_none()

    stats_stmt = select(UserStats).where(UserStats.user_id == user_id)
    stats = (await db.execute(stats_stmt)).scalar_one_or_none()

    total_jobs = stats.total_jobs_completed if stats else 0
    avg_rating = stats.avg_rating if stats else 5.0
    level = stats.level if stats else calculate_user_level(total_jobs)
    total_reviews = stats.total_reviews if stats else 0
    is_verified = user.is_verified if user else False

    return {
        "user_id": str(user_id),
        "full_name": user.full_name if user else "ব্যবহারকারী",
        "is_verified": is_verified,
        "avg_rating": avg_rating,
        "total_reviews": total_reviews,
        "total_jobs_completed": total_jobs,
        "level": level,  # 'New' | 'Silver' | 'Gold' | 'Platinum'
        "badge_text": f"⭐ {avg_rating:.1f} ({total_reviews} reviews) | {level} Level",
    }
