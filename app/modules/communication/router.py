"""
Post-Unlock Real-Time Communication Engine.
Enforces:
1. Only users with active unlocked records (or post creators) can access conversations.
2. WebSocket connection rejects immediately with code 4003 if unlock validity has expired or was refunded.
3. Message history persistence and broadcast across connected sockets.
"""

import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set

from fastapi import (
    APIRouter,
    Depends,
    Header,
    HTTPException,
    Query,
    Request,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from sqlalchemy import and_, desc, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal, get_db
from app.core.security import decode_user_token
from app.modules.dynamic_engine.models import (
    Conversation,
    EntityRecord,
    Message,
    RecordUnlock,
    User,
)


logger = logging.getLogger("communication")
router = APIRouter(prefix="/api/v1", tags=["Real-time Communication"])


# ---------------------------------------------------------------------------
# WebSocket Connection Hub
# ---------------------------------------------------------------------------
class ChatConnectionHub:
    def __init__(self):
        # Maps conversation_id -> set of active WebSockets
        self.active_rooms: dict[str, set[WebSocket]] = {}

    async def connect(self, conversation_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        if conversation_id not in self.active_rooms:
            self.active_rooms[conversation_id] = set()
        self.active_rooms[conversation_id].add(websocket)
        logger.info(f"Socket connected to room {conversation_id}. Total: {len(self.active_rooms[conversation_id])}")

    def disconnect(self, conversation_id: str, websocket: WebSocket) -> None:
        if conversation_id in self.active_rooms:
            self.active_rooms[conversation_id].discard(websocket)
            if not self.active_rooms[conversation_id]:
                del self.active_rooms[conversation_id]
        logger.info(f"Socket disconnected from room {conversation_id}")

    async def broadcast_to_room(self, conversation_id: str, message_payload: dict[str, Any]) -> None:
        if conversation_id in self.active_rooms:
            dead_sockets = set()
            for ws in self.active_rooms[conversation_id]:
                try:
                    await ws.send_json(message_payload)
                except Exception:
                    dead_sockets.add(ws)
            for dead in dead_sockets:
                self.active_rooms[conversation_id].discard(dead)


chat_hub = ChatConnectionHub()


def resolve_user_from_token(token: Optional[str]) -> Optional[uuid.UUID]:
    """Decodes JWT Bearer token into user UUID."""
    if not token:
        return None
    try:
        clean_token = token.replace("Bearer ", "").strip()
        payload = decode_user_token(clean_token)
        return uuid.UUID(payload.get("sub"))
    except Exception:
        return None


# ---------------------------------------------------------------------------
# 1. GET /api/v1/conversations - List conversations for unlocked posts
# ---------------------------------------------------------------------------
@router.get("/conversations", status_code=status.HTTP_200_OK)
async def get_user_conversations(
    authorization: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
):
    """
    Returns active conversation channels where the caller is either:
    1. The buyer with an ACTIVE valid unlock record (valid_until > NOW, is_refunded=False)
    2. The seller / post author whose record was unlocked.
    """
    user_id = resolve_user_from_token(authorization) or (uuid.UUID(x_user_id) if x_user_id else None)
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required")

    now = datetime.now(timezone.utc)

    # Query conversations joined with RecordUnlock
    stmt = (
        select(Conversation, EntityRecord, RecordUnlock)
        .join(EntityRecord, Conversation.record_id == EntityRecord.id)
        .join(RecordUnlock, Conversation.unlock_id == RecordUnlock.id)
        .where(
            and_(
                Conversation.is_active.is_(True),
                or_(
                    Conversation.buyer_user_id == user_id,
                    Conversation.seller_user_id == user_id,
                ),
                RecordUnlock.valid_until > now,
                RecordUnlock.is_refunded.is_(False),
            )
        )
        .order_by(desc(Conversation.last_message_at))
    )

    results = (await db.execute(stmt)).all()

    conversation_list = []
    for conv, record, unlock in results:
        is_buyer = conv.buyer_user_id == user_id
        conversation_list.append({
            "conversation_id": str(conv.id),
            "record_id": str(record.id),
            "record_title": record.title,
            "approx_location": record.approx_location,
            "is_buyer": is_buyer,
            "other_participant_id": str(conv.seller_user_id if is_buyer else conv.buyer_user_id),
            "valid_until": unlock.valid_until.isoformat(),
            "last_message_at": conv.last_message_at.isoformat(),
        })

    return {
        "status": "success",
        "count": len(conversation_list),
        "conversations": conversation_list,
    }


# ---------------------------------------------------------------------------
# 2. GET /api/v1/conversations/{conversation_id}/messages - Chat History
# ---------------------------------------------------------------------------
@router.get("/conversations/{conversation_id}/messages", status_code=status.HTTP_200_OK)
async def get_conversation_history(
    conversation_id: uuid.UUID,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    authorization: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
):
    """Retrieves message history for a verified unlocked conversation."""
    user_id = resolve_user_from_token(authorization) or (uuid.UUID(x_user_id) if x_user_id else None)
    if not user_id:
        raise HTTPException(status_code=401, detail="Authentication required")

    now = datetime.now(timezone.utc)

    # Verify participant & active unlock
    stmt = (
        select(Conversation, RecordUnlock)
        .join(RecordUnlock, Conversation.unlock_id == RecordUnlock.id)
        .where(
            and_(
                Conversation.id == conversation_id,
                or_(
                    Conversation.buyer_user_id == user_id,
                    Conversation.seller_user_id == user_id,
                ),
                RecordUnlock.valid_until > now,
                RecordUnlock.is_refunded.is_(False),
            )
        )
    )
    row = (await db.execute(stmt)).first()
    if not row:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Conversation access denied: Not a participant or unlock validity expired.",
        )

    # Fetch messages
    msg_stmt = (
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(desc(Message.sent_at))
        .offset(offset)
        .limit(limit)
    )
    messages = (await db.execute(msg_stmt)).scalars().all()

    return {
        "conversation_id": str(conversation_id),
        "count": len(messages),
        "messages": [
            {
                "id": str(m.id),
                "sender_id": str(m.sender_user_id),
                "is_mine": m.sender_user_id == user_id,
                "text": m.message_text,
                "attachment_url": m.attachment_url,
                "sent_at": m.sent_at.isoformat(),
            }
            for m in reversed(messages)
        ],
    }


# ---------------------------------------------------------------------------
# 3. WebSocket /ws/chat/{conversation_id} - Real-time Post-Unlock Chat
# ---------------------------------------------------------------------------
@router.websocket("/ws/chat/{conversation_id}")
async def chat_websocket_endpoint(
    websocket: WebSocket,
    conversation_id: str,
    token: Optional[str] = Query(None),
    user_id_param: Optional[str] = Query(None),
):
    """
    Real-time Post-Unlock Chat WebSocket.
    SECURITY VERIFICATION ON HANDSHAKE:
    1. Resolves caller User ID from token or query param.
    2. Checks Conversation exists and user is buyer or seller.
    3. CHECKS record_unlocks: valid_until > NOW() AND is_refunded == FALSE.
       If expired or invalid, immediately closes connection with code 4003 (Forbidden).
    """
    # 1. Resolve User
    current_user_id = resolve_user_from_token(token) or (uuid.UUID(user_id_param) if user_id_param else None)
    if not current_user_id:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Authentication failed")
        return

    try:
        conv_uuid = uuid.UUID(conversation_id)
    except ValueError:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid conversation ID")
        return

    now = datetime.now(timezone.utc)

    # 2. Strict Database Verification of Record Unlock Validity
    async with AsyncSessionLocal() as session:
        stmt = (
            select(Conversation, RecordUnlock)
            .join(RecordUnlock, Conversation.unlock_id == RecordUnlock.id)
            .where(
                and_(
                    Conversation.id == conv_uuid,
                    or_(
                        Conversation.buyer_user_id == current_user_id,
                        Conversation.seller_user_id == current_user_id,
                    ),
                    RecordUnlock.valid_until > now,
                    RecordUnlock.is_refunded.is_(False),
                )
            )
        )
        row = (await session.execute(stmt)).first()

        if not row:
            logger.warning(
                f"WebSocket connection rejected for user {current_user_id} in {conversation_id}: No valid active unlock."
            )
            # 4003 = Custom Close code: Unlock Expired / Unauthorized
            await websocket.close(code=4003, reason="Record unlock validity expired or not authorized")
            return

    # 3. Connection Accepted
    await chat_hub.connect(conversation_id, websocket)

    try:
        # Send initial confirmation
        await websocket.send_json({
            "type": "connection_established",
            "conversation_id": conversation_id,
            "user_id": str(current_user_id),
            "status": "connected",
        })

        while True:
            # Receive incoming message payload
            raw_data = await websocket.receive_text()
            try:
                payload = json.loads(raw_data)
            except Exception:
                payload = {"text": raw_data}

            msg_text = str(payload.get("text", "")).strip()
            attachment = payload.get("attachment_url")

            if not msg_text and not attachment:
                continue

            # 4. Re-check Unlock Validity Before Saving & Broadcasting
            async with AsyncSessionLocal() as session:
                # Fast validity guard
                check_stmt = (
                    select(RecordUnlock.valid_until)
                    .join(Conversation, Conversation.unlock_id == RecordUnlock.id)
                    .where(
                        and_(
                            Conversation.id == conv_uuid,
                            RecordUnlock.valid_until > datetime.now(timezone.utc),
                            RecordUnlock.is_refunded.is_(False),
                        )
                    )
                )
                valid_until = (await session.execute(check_stmt)).scalar_one_or_none()
                if not valid_until:
                    await websocket.send_json({
                        "type": "error",
                        "code": "UNLOCK_EXPIRED",
                        "message": "Your 7-day unlock period has expired. Please renew unlock to continue chatting.",
                    })
                    await websocket.close(code=4003, reason="Unlock period expired during active session")
                    break

                # 5. Persist Message to DB
                new_msg = Message(
                    conversation_id=conv_uuid,
                    sender_user_id=current_user_id,
                    message_text=msg_text,
                    attachment_url=attachment,
                    sent_at=datetime.now(timezone.utc),
                )
                session.add(new_msg)

                # Update conversation last_message_at
                conv = (await session.execute(select(Conversation).where(Conversation.id == conv_uuid))).scalar_one()
                conv.last_message_at = datetime.now(timezone.utc)

                await session.commit()
                await session.refresh(new_msg)

                broadcast_payload = {
                    "type": "new_message",
                    "id": str(new_msg.id),
                    "conversation_id": conversation_id,
                    "sender_id": str(current_user_id),
                    "text": new_msg.message_text,
                    "attachment_url": new_msg.attachment_url,
                    "sent_at": new_msg.sent_at.isoformat(),
                }

            # 6. Real-time broadcast to both participants in room
            await chat_hub.broadcast_to_room(conversation_id, broadcast_payload)

    except WebSocketDisconnect:
        chat_hub.disconnect(conversation_id, websocket)
    except Exception as e:
        logger.error(f"WebSocket error in {conversation_id}: {str(e)}", exc_info=True)
        chat_hub.disconnect(conversation_id, websocket)
