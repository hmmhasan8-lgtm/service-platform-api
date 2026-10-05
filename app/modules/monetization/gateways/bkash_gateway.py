"""
bKash Payment Gateway Adapter & Webhook Handler.
Verifies bKash Tokenized Checkout / Webhook callbacks with SHA-256 HMAC cryptographic signature.
Upon verification, calls MonetizationService.verify_and_grant_access.
"""

import base64
import hashlib
import hmac
import json
import logging
import os
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.modules.monetization.service import MonetizationService


logger = logging.getLogger("bkash_gateway")
router = APIRouter(prefix="/api/v1/payments/bkash", tags=["bKash Payment Gateway"])

BKASH_WEBHOOK_SECRET = os.getenv("BKASH_WEBHOOK_SECRET", "bkash_live_webhook_hmac_secret_key_2026")


def verify_bkash_signature(payload_bytes: bytes, signature_header: Optional[str]) -> bool:
    """
    Verifies bKash webhook HMAC-SHA256 signature against webhook secret.
    """
    if not signature_header:
        # Development / Sandbox lenient mode if key is default
        if BKASH_WEBHOOK_SECRET == "bkash_live_webhook_hmac_secret_key_2026":
            return True
        return False

    computed_sig = hmac.new(
        BKASH_WEBHOOK_SECRET.encode("utf-8"), payload_bytes, hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(computed_sig, signature_header.strip())


@router.post("/webhook", status_code=status.HTTP_200_OK)
async def bkash_payment_webhook(
    request: Request,
    x_bkash_signature: Optional[str] = Header(None, alias="X-bKash-Signature"),
    db: AsyncSession = Depends(get_db),
):
    """
    bKash Tokenized Checkout Webhook Endpoint:
    Expects bKash transaction confirmation payload:
    {
       "paymentID": "TR0011...",
       "trxID": "BKH99812739",
       "transactionStatus": "Completed",
       "amount": "60.00",
       "currency": "BDT",
       "merchantInvoiceNumber": "TXN-UNLK-XXXXXX"
    }
    """
    raw_body = await request.body()

    # 1. Signature Verification
    if not verify_bkash_signature(raw_body, x_bkash_signature):
        logger.warning("bKash Webhook Rejected: Invalid HMAC signature")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid bKash cryptographic webhook signature",
        )

    try:
        data = json.loads(raw_body.decode("utf-8"))
    except Exception:
        raise HTTPException(status_code=400, detail="Malformed JSON payload")

    trx_status = data.get("transactionStatus")
    merchant_invoice = data.get("merchantInvoiceNumber") or data.get("invoice_number")
    trx_id = data.get("trxID") or data.get("paymentID")

    if not merchant_invoice:
        raise HTTPException(
            status_code=400, detail="Missing merchantInvoiceNumber (transaction_reference)"
        )

    # 2. Check Transaction Outcome
    if trx_status != "Completed":
        logger.info(f"bKash transaction {trx_id} ended with status: {trx_status}")
        return {
            "status": "acknowledged",
            "message": f"bKash transaction {trx_status}",
            "trxID": trx_id,
        }

    # 3. Call MonetizationService to grant unlock & decrypt
    unlocked_result = await MonetizationService.verify_and_grant_access(
        db=db,
        transaction_reference=merchant_invoice,
        gateway_token=trx_id,
    )

    logger.info(f"bKash payment verified for invoice {merchant_invoice}, post unlocked successfully")

    return {
        "status": "success",
        "gateway": "bkash",
        "trxID": trx_id,
        "invoice": merchant_invoice,
        "unlocked_record": unlocked_result,
    }
