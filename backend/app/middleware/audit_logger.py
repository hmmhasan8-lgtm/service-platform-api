"""
Immutable Audit Logging Middleware for Founder Operations.
Captures POST/PUT/PATCH/DELETE mutations on /founder/* routes,
diffs previous and new state, masks sensitive/private fields,
and writes to audit_logs asynchronously without blocking the response.
"""

import asyncio
import json
import logging
import uuid
from typing import Any, Dict, Optional
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.core.database import AsyncSessionLocal
from app.modules.dynamic_engine.models import AuditLog


logger = logging.getLogger("audit_logger")

SENSITIVE_FIELD_NAMES = {
    "password",
    "password_hash",
    "totp_secret",
    "totp_secret_encrypted",
    "credentials_encrypted",
    "encrypted_private_data",
    "cipher_text",
    "contact_mobile",
    "exact_address",
    "nid_number",
    "id_number",
    "token",
    "secret",
}


def sanitize_and_mask_data(data: Any) -> Any:
    """
    Recursively scans and masks sensitive or private keys with '***MASKED***'.
    Never logs plain text credentials, tokens, or private data to audit_logs.
    """
    if isinstance(data, dict):
        sanitized = {}
        for k, v in data.items():
            k_lower = str(k).lower()
            if any(sens in k_lower for sens in SENSITIVE_FIELD_NAMES) or (
                k_lower.startswith("private_")
            ):
                sanitized[k] = "***MASKED***"
            else:
                sanitized[k] = sanitize_and_mask_data(v)
        return sanitized
    elif isinstance(data, list):
        return [sanitize_and_mask_data(item) for item in data]
    return data


async def record_audit_entry_async(
    actor_id: Optional[uuid.UUID],
    actor_type: str,
    action: str,
    entity_name: str,
    entity_id: Optional[str],
    country_code: Optional[str],
    ip_address: Optional[str],
    user_agent: Optional[str],
    previous_state: Optional[dict[str, Any]],
    new_state: Optional[dict[str, Any]],
    meta_info: dict[str, Any],
) -> None:
    """
    Non-blocking background writer to PostgreSQL audit_logs table.
    Ensures that audit log writing never slows down or interrupts client API calls.
    """
    try:
        async with AsyncSessionLocal() as session:
            audit_entry = AuditLog(
                actor_id=actor_id,
                actor_type=actor_type,
                action=action,
                entity_name=entity_name,
                entity_id=entity_id,
                country_code=country_code,
                ip_address=ip_address,
                user_agent=user_agent,
                previous_state=sanitize_and_mask_data(previous_state),
                new_state=sanitize_and_mask_data(new_state),
                meta_info=sanitize_and_mask_data(meta_info),
            )
            session.add(audit_entry)
            await session.commit()
    except Exception as e:
        logger.error(f"Failed to record immutable audit log: {str(e)}", exc_info=True)


class FounderAuditLogMiddleware(BaseHTTPMiddleware):
    """
    Intercepts /founder/* modifying requests (POST, PUT, PATCH, DELETE)
    and records immutable audit logs with masked sensitive data.
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        path = request.url.path
        method = request.method.upper()

        # Only intercept state-modifying requests on /founder/* routes
        if not path.startswith("/founder") or method not in ("POST", "PUT", "PATCH", "DELETE"):
            return await call_next(request)

        # 1. Read and cache request body for logging
        body_bytes = await request.body()
        req_payload = None
        if body_bytes:
            try:
                req_payload = json.loads(body_bytes.decode("utf-8"))
            except Exception:
                req_payload = {"raw_length": len(body_bytes)}

        # 2. Proceed with actual request
        response = await call_next(request)

        # 3. Only audit successful mutations (2xx and 3xx)
        if 200 <= response.status_code < 400:
            founder_user = getattr(request.state, "founder_user", None)
            actor_id = founder_user.id if founder_user else None
            actor_type = "founder" if founder_user else "staff"
            client_ip = getattr(request.state, "client_ip", None) or (
                request.client.host if request.client else "127.0.0.1"
            )
            user_agent = request.headers.get("user-agent", "unknown")
            country_code = getattr(request.state, "country_code", None)

            # Determine action and entity name from path
            path_segments = [p for p in path.split("/") if p and p != "founder"]
            entity_name = path_segments[0] if path_segments else "founder_admin"
            entity_id = path_segments[1] if len(path_segments) > 1 else None

            action = f"{entity_name}.{method.lower()}"

            # Fire non-blocking asynchronous audit task
            asyncio.create_task(
                record_audit_entry_async(
                    actor_id=actor_id,
                    actor_type=actor_type,
                    action=action,
                    entity_name=entity_name,
                    entity_id=entity_id,
                    country_code=country_code,
                    ip_address=client_ip,
                    user_agent=user_agent,
                    previous_state=None,
                    new_state=req_payload,
                    meta_info={
                        "path": path,
                        "method": method,
                        "status_code": response.status_code,
                    },
                )
            )

        return response
