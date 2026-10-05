"""
Country Resolver Middleware and Utility for SERVICE Platform.
Resolves client country from Cloudflare/CDN headers, custom headers, or IP geolocation.
Defaults to 'BD' (Bangladesh) for regional origin.
"""

from typing import Optional
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response


DEFAULT_COUNTRY_CODE = "BD"


def resolve_country_from_request(request: Request) -> str:
    """
    Extracts 2-letter ISO country code from request:
    1. Cloudflare header: 'CF-IPCountry'
    2. CDN / Proxy header: 'X-Country-Code', 'X-Geo-Country'
    3. Custom query param (for testing/founder override): '?country=US'
    4. Fallback: DEFAULT_COUNTRY_CODE ('BD')
    """
    # 1. Query override (useful for developer testing or client switch)
    query_country = request.query_params.get("country")
    if query_country and len(query_country) == 2:
        return query_country.upper()

    # 2. CDN headers
    cf_country = request.headers.get("cf-ipcountry")
    if cf_country and len(cf_country) == 2 and cf_country != "XX":
        return cf_country.upper()

    x_country = request.headers.get("x-country-code") or request.headers.get("x-geo-country")
    if x_country and len(x_country) == 2:
        return x_country.upper()

    # 3. Fallback
    return DEFAULT_COUNTRY_CODE


class CountryResolverMiddleware(BaseHTTPMiddleware):
    """
    Attaches resolved 2-letter uppercase country code to request.state.country_code.
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        country_code = resolve_country_from_request(request)
        request.state.country_code = country_code

        response = await call_next(request)
        response.headers["X-Resolved-Country"] = country_code
        return response
