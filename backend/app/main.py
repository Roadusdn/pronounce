from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.routers.analyzes import router as analyze_router
from app.routers.attempts import router as attempts_router
from app.routers.catalog import router as catalog_router
from app.routers.users import router as users_router


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CLIPS_DIR = PROJECT_ROOT / "data" / "clips"
CLIPS_DIR.mkdir(parents=True, exist_ok=True)

app.mount("/api/clips", StaticFiles(directory=str(CLIPS_DIR)), name="clips")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(analyze_router, prefix="/api")
app.include_router(attempts_router)
app.include_router(catalog_router)
app.include_router(users_router)
