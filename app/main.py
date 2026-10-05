"""
Main FastAPI Application Entrypoint for SERVICE Platform.
Mounts all modular routers, security guards, and event middlewares.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.middleware.audit_logger import FounderAuditLogMiddleware
from app.middleware.country_resolver import CountryResolverMiddleware
from app.middleware.feature_flag import FeatureFlagMiddleware
from app.modules.communication.router import router as communication_router
from app.modules.dynamic_engine.router import router as dynamic_engine_router
from app.modules.founder.router import router as founder_router
from app.modules.requests.router import router as requests_router
from app.modules.trust_safety.router import router as trust_safety_router
from app.modules.gamification.router import router as gamification_router
from app.modules.marketing.router import router as marketing_router
from app.modules.monetization.gateways.bkash_gateway import router as bkash_router
from app.modules.monetization.gateways.nagad_gateway import router as nagad_router
from app.modules.monetization.gateways.stripe_gateway import router as stripe_router

app = FastAPI(
    title="SERVICE - Universal Commercial Communication Platform",
    description="Metadata-driven dynamic modular platform with verified contact unlocks and country-wise feature flags.",
    version="1.0.0",
)

# 1. CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. Platform Security & Context Middlewares
app.add_middleware(FounderAuditLogMiddleware)
app.add_middleware(FeatureFlagMiddleware)
app.add_middleware(CountryResolverMiddleware)

# 3. Mount Business Module Routers
app.include_router(dynamic_engine_router)
app.include_router(founder_router)
app.include_router(bkash_router)
app.include_router(nagad_router)
app.include_router(stripe_router)
app.include_router(communication_router)
app.include_router(requests_router)
app.include_router(trust_safety_router)
app.include_router(gamification_router)
app.include_router(marketing_router)


@app.get("/health", tags=["System Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "SERVICE Platform Engine",
        "engine": "FastAPI + PostgreSQL + Redis",
    }


@app.get("/", tags=["Root"])
async def root():
    return {
        "message": "Welcome to SERVICE Universal Commercial Platform API",
        "docs_url": "/docs",
        "health_url": "/health",
    }
