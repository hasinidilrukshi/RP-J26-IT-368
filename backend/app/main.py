"""FoodSafety AI backend - run with:  uvicorn app.main:app --host 0.0.0.0 --port 8000"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import config, database
from .routers import food, users
from .services import food_repository as repo
from .services.detector import detector

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("app")


@asynccontextmanager
async def lifespan(app: FastAPI):
    database.init_indexes()
    seeded = repo.seed_foods()
    if seeded:
        log.info("Food collection was empty - imported %d foods", seeded)
    try:
        detector.load()
        log.info("Model ready with %d classes", len(detector.class_names))
    except Exception:
        log.exception("Model failed to load - /api/food/analyze will not work")
    yield
    database.close()


app = FastAPI(title="FoodSafety AI - Sri Lankan Street Food", version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.mount("/uploads", StaticFiles(directory=str(config.UPLOAD_DIR)), name="uploads")
app.include_router(users.router)
app.include_router(food.router)


@app.get("/api/health")
def health():
    db_ok = True
    try:
        database.get_db().command("ping")
    except Exception:
        db_ok = False
    return {
        "status": "ok",
        "database": db_ok,
        "model_loaded": detector._model is not None,
        "foods": database.get_db().foods.count_documents({}) if db_ok else 0,
    }


@app.get("/api/model/classes")
def model_classes():
    return {"classes": detector.class_names}
