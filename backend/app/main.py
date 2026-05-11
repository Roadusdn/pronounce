from fastapi import FastAPI

from app.routers.analyze import router as analyze_router
from app.routers.attempts import router as attempts_router
from app.routers.catalog import router as catalog_router


app = FastAPI()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(analyze_router)
app.include_router(attempts_router)
app.include_router(catalog_router)
