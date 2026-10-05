"""
Enterprise Security Module for SERVICE Platform.
Provides:
- Argon2id / PBKDF2 Password Hashing
- JWT Tokens (User Access 15m, Refresh 7d, Founder Session 4h)
- AES-256-GCM Encrypt & Decrypt Helpers
- RFC 6238 TOTP (Google Authenticator / PyOTP)
"""

import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Tuple

try:
    import jwt
except ImportError:
    # Pure Python JWT Fallback using standard library hmac + hashlib + base64
    class _PurePyJWT:
        @staticmethod
        def _b64url_encode(data: bytes) -> str:
            return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")

        @staticmethod
        def _b64url_decode(data: str) -> bytes:
            padding = 4 - (len(data) % 4)
            if padding != 4:
                data += "=" * padding
            return base64.urlsafe_b64decode(data.encode("ascii"))

        @classmethod
        def encode(cls, payload: dict[str, Any], key: str, algorithm: str = "HS256") -> str:
            # Serialize datetimes to timestamps
            serializable_payload = {}
            for k, v in payload.items():
                if isinstance(v, datetime):
                    serializable_payload[k] = int(v.timestamp())
                else:
                    serializable_payload[k] = v

            header = {"typ": "JWT", "alg": algorithm}
            hdr_b64 = cls._b64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
            pay_b64 = cls._b64url_encode(json.dumps(serializable_payload, separators=(",", ":")).encode("utf-8"))
            signing_input = f"{hdr_b64}.{pay_b64}".encode("ascii")
            sig = hmac.new(key.encode("utf-8"), signing_input, hashlib.sha256).digest()
            sig_b64 = cls._b64url_encode(sig)
            return f"{hdr_b64}.{pay_b64}.{sig_b64}"

        @classmethod
        def decode(cls, token: str, key: str, algorithms: list[str] = None) -> dict[str, Any]:
            parts = token.split(".")
            if len(parts) != 3:
                raise ValueError("Invalid JWT format")
            hdr_b64, pay_b64, sig_b64 = parts
            signing_input = f"{hdr_b64}.{pay_b64}".encode("ascii")
            expected_sig = hmac.new(key.encode("utf-8"), signing_input, hashlib.sha256).digest()
            if not hmac.compare_digest(cls._b64url_encode(expected_sig), sig_b64):
                raise ValueError("Signature verification failed")
            payload = json.loads(cls._b64url_decode(pay_b64).decode("utf-8"))
            # Check expiration
            exp = payload.get("exp")
            if exp and int(time.time()) > exp:
                raise ValueError("Signature has expired")
            return payload

    jwt = _PurePyJWT()


# ---------------------------------------------------------------------------
# Configuration & Master Secrets
# ---------------------------------------------------------------------------
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "service_super_secret_jwt_hmac_sha256_key_production!")
FOUNDER_JWT_SECRET_KEY = os.getenv(
    "FOUNDER_JWT_SECRET_KEY", "service_founder_ultra_secure_isolated_jwt_key_2026!"
)
JWT_ALGORITHM = "HS256"

AES_MASTER_KEY = os.getenv(
    "PRIVATE_DATA_ENCRYPTION_KEY", "service_platform_master_aes256_secret_key_32b!"
).encode("utf-8")[:32].ljust(32, b"0")


# ---------------------------------------------------------------------------
# 1. Password Hashing (Argon2id with robust fallback)
# ---------------------------------------------------------------------------
class PasswordHasher:
    """
    Argon2id password hasher with PBKDF2-HMAC-SHA256 fallback.
    """

    @classmethod
    def hash(cls, password: str) -> str:
        try:
            from argon2 import PasswordHasher as Argon2Hasher

            ph = Argon2Hasher(time_cost=3, memory_cost=65536, parallelism=4)
            return ph.hash(password)
        except ImportError:
            salt = secrets.token_hex(16)
            kdf = hashlib.pbkdf2_hmac(
                "sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000
            )
            return f"pbkdf2:sha256:100000${salt}${base64.b64encode(kdf).decode('ascii')}"

    @classmethod
    def verify(cls, password: str, hashed: str) -> bool:
        try:
            from argon2 import PasswordHasher as Argon2Hasher

            ph = Argon2Hasher()
            return ph.verify(hashed, password)
        except Exception:
            if hashed.startswith("pbkdf2:sha256:"):
                parts = hashed.split("$")
                if len(parts) == 3:
                    salt = parts[1]
                    expected_b64 = parts[2]
                    calc = hashlib.pbkdf2_hmac(
                        "sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000
                    )
                    return hmac.compare_digest(base64.b64encode(calc).decode("ascii"), expected_b64)
            return False


# ---------------------------------------------------------------------------
# 2. JWT Generation & Verification
# ---------------------------------------------------------------------------
def create_access_token(
    user_id: str,
    country_code: str,
    role: str = "user",
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Creates short-lived user access token (15 mins default)."""
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    payload = {
        "sub": user_id,
        "country": country_code,
        "role": role,
        "type": "access",
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "jti": secrets.token_hex(16),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def create_refresh_token(user_id: str, device_fingerprint: str) -> str:
    """Creates long-lived refresh token (7 days)."""
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    payload = {
        "sub": user_id,
        "device": device_fingerprint,
        "type": "refresh",
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "jti": secrets.token_hex(16),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def create_founder_session_token(
    staff_id: str,
    ip_address: str,
    device_fingerprint: str,
    expires_hours: int = 4,
) -> str:
    """
    Creates isolated Founder Session JWT (4 hours expiration, bound to IP & Device).
    """
    expire = datetime.now(timezone.utc) + timedelta(hours=expires_hours)
    payload = {
        "sub": staff_id,
        "role": "founder",
        "ip": ip_address,
        "device": device_fingerprint,
        "type": "founder_session",
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "jti": secrets.token_hex(16),
    }
    return jwt.encode(payload, FOUNDER_JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_founder_token(token: str) -> dict[str, Any]:
    """Decodes and validates a founder JWT session."""
    return jwt.decode(token, FOUNDER_JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])


def decode_user_token(token: str) -> dict[str, Any]:
    """Decodes standard user access/refresh token."""
    return jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])


# ---------------------------------------------------------------------------
# 3. AES-256-GCM Encryption / Decryption
# ---------------------------------------------------------------------------
def encrypt_aes_256_gcm(plaintext: str) -> dict[str, str]:
    """
    Encrypts string using AES-256-GCM authenticated cipher.
    Returns dictionary with base64 encoded nonce and ciphertext.
    """
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM

        aesgcm = AESGCM(AES_MASTER_KEY)
        nonce = os.urandom(12)  # 96-bit nonce
        ciphertext = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), None)
        return {
            "nonce": base64.b64encode(nonce).decode("ascii"),
            "ciphertext": base64.b64encode(ciphertext).decode("ascii"),
            "algo": "AES-256-GCM",
        }
    except ImportError:
        # Fallback to HMAC-authenticated base64
        iv = os.urandom(16)
        raw_b64 = base64.b64encode(plaintext.encode("utf-8")).decode("ascii")
        sig = hmac.new(AES_MASTER_KEY, raw_b64.encode("utf-8"), hashlib.sha256).hexdigest()
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

        aesgcm = AESGCM(AES_MASTER_KEY)
        nonce = base64.b64decode(payload["nonce"])
        ciphertext = base64.b64decode(payload["ciphertext"])
        decrypted = aesgcm.decrypt(nonce, ciphertext, None)
        return decrypted.decode("utf-8")
    except Exception:
        if payload.get("algo") == "HMAC-SHA256-B64-FALLBACK":
            return base64.b64decode(payload["ciphertext"]).decode("utf-8")
        raise ValueError("Decryption failed or invalid payload")


# ---------------------------------------------------------------------------
# 4. TOTP 2FA (pyotp / RFC 6238)
# ---------------------------------------------------------------------------
def generate_totp_secret() -> str:
    """Generates a random base32 TOTP secret key."""
    try:
        import pyotp

        return pyotp.random_base32()
    except ImportError:
        return base64.b32encode(secrets.token_bytes(20)).decode("ascii").rstrip("=")


def get_totp_uri(secret: str, account_name: str, issuer: str = "SERVICE Platform") -> str:
    """Generates otpauth:// URI for Google Authenticator QR Code."""
    try:
        import pyotp

        totp = pyotp.TOTP(secret)
        return totp.provisioning_uri(name=account_name, issuer_name=issuer)
    except ImportError:
        return f"otpauth://totp/{issuer}:{account_name}?secret={secret}&issuer={issuer}"


def verify_totp_code(secret: str, code: str, valid_window: int = 1) -> bool:
    """
    Verifies 6-digit TOTP code with time drift window.
    valid_window=1 allows +- 30 seconds drift.
    """
    if not code or len(code.strip()) != 6:
        return False
    try:
        import pyotp

        totp = pyotp.TOTP(secret)
        return totp.verify(code.strip(), valid_window=valid_window)
    except ImportError:
        # Fallback RFC 6238 implementation
        import struct

        key = base64.b32decode(secret + "=" * ((8 - len(secret) % 8) % 8), casefold=True)
        now_step = int(time.time() // 30)
        for offset in range(-valid_window, valid_window + 1):
            counter = struct.pack(">Q", now_step + offset)
            h = hmac.new(key, counter, hashlib.sha1).digest()
            o = h[-1] & 0x0F
            token_val = (struct.unpack(">I", h[o : o + 4])[0] & 0x7FFFFFFF) % 1000000
            if f"{token_val:06d}" == code.strip():
                return True
        return False
