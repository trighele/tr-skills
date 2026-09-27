"""The API component.

Every route hangs off ROUTE_PREFIX. The router sends this component its traffic under that
prefix and does not strip it, so the path in a browser's network tab and the path written
here are the same string. It is "" while this component holds the root on its own, and "/api"
once a frontend holds the root instead — changing it here, and `route:` and `health_path:` in
pipeline.yaml, is the whole of moving it.
"""

from fastapi import APIRouter, FastAPI

ROUTE_PREFIX = "__ROUTE_PREFIX__"

router = APIRouter(prefix=ROUTE_PREFIX)


@router.get("/healthz")
def healthz():
    """What the release's health gate fetches. It must answer 2xx or the release rolls back."""
    return {"status": "ok"}


app = FastAPI(title="__APP_NAME__ api")
app.include_router(router)
