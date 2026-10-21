import logging
import uuid

from fastapi import APIRouter, File, Form, HTTPException, Request, UploadFile

from .. import config
from ..schemas import EvaluateRequest
from ..services import food_repository as repo
from ..services.detector import detector
from ..services.safety_engine import evaluate

log = logging.getLogger(__name__)
router = APIRouter(prefix="/api", tags=["food"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif",
                 "application/octet-stream"}


def _food_summary(food):
    return {k: food.get(k) for k in (
        "key", "name", "category", "ingredients", "vegetarian", "vegan", "allergens",
        "allergen_tags", "possible_allergens", "nutrition", "benefits", "health_concerns")}


def _build_result(food, profile, confidence):
    return {
        "food_key": food["key"],
        "food": _food_summary(food),
        "recommendation": evaluate(food, profile, confidence, config.LOW_CONFIDENCE_WARNING),
    }


@router.get("/foods")
def foods(search: str = ""):
    return [_food_summary(f) for f in repo.list_foods(search)]


@router.get("/foods/{key}")
def food_detail(key: str):
    food = repo.find_food(key)
    if not food:
        raise HTTPException(404, "Food not found")
    return _food_summary(food)


@router.post("/food/analyze")
async def analyze_food(request: Request, user_id: str = Form(...), image: UploadFile = File(...)):
    """Main pipeline: image -> YOLO -> food database -> health profile -> verdict."""
    if image.content_type and image.content_type not in ALLOWED_TYPES:
        raise HTTPException(415, f"Unsupported image type {image.content_type}")
    data = await image.read()
    if not data:
        raise HTTPException(400, "Empty image")
    if len(data) > config.MAX_UPLOAD_MB * 1024 * 1024:
        raise HTTPException(413, "Image too large")

    user = repo.get_user(user_id)
    if not user:
        raise HTTPException(404, "User not found - create a profile first")
    profile = user.get("profile") or {}

    try:
        detection = detector.predict(data)
    except Exception as exc:  # corrupt image etc.
        log.exception("Detection failed")
        raise HTTPException(422, f"Could not process image: {exc}")

    scan_id = uuid.uuid4().hex
    image_path = config.UPLOAD_DIR / f"{scan_id}.jpg"
    image_path.write_bytes(data)

    scan = {
        "scan_id": scan_id,
        "user_id": user_id,
        "created_at": repo.now_iso(),
        "image_url": f"/uploads/{image_path.name}",
        "detection": detection,
        "recognized": False,
        "food_key": None,
        "food": None,
        "recommendation": None,
    }

    if detection["detected"]:
        food = repo.find_food(detection["label"])
        if food:
            scan.update(_build_result(food, profile, detection["confidence"]))
            scan["recognized"] = True
        else:
            log.warning("Model label %s not in food database", detection["label"])
    # add display names for alternatives so the app can offer "Not this dish?"
    for alt in detection.get("alternatives", []):
        f = repo.find_food(alt["label"])
        alt["name"] = f["name"] if f else alt["label"]

    repo.save_scan(scan)
    scan.pop("_id", None)
    return scan


@router.post("/food/evaluate")
def evaluate_food(body: EvaluateRequest):
    """Re-evaluate a food for a user (manual pick / corrected dish / profile changed)."""
    user = repo.get_user(body.user_id)
    if not user:
        raise HTTPException(404, "User not found")
    food = repo.find_food(body.food_key)
    if not food:
        raise HTTPException(404, "Food not found")
    result = _build_result(food, user.get("profile") or {}, None)
    if body.scan_id:
        scan = repo.update_scan(body.scan_id, {**result, "recognized": True, "corrected": True})
        if not scan:
            raise HTTPException(404, "Scan not found")
        return scan
    return {"scan_id": None, "user_id": body.user_id, "created_at": repo.now_iso(),
            "image_url": None, "detection": None, "recognized": True, **result}


@router.get("/scans")
def scans(user_id: str, limit: int = 20):
    return repo.list_scans(user_id, limit)


@router.get("/scans/{scan_id}")
def scan_detail(scan_id: str):
    scan = repo.get_scan(scan_id)
    if not scan:
        raise HTTPException(404, "Scan not found")
    return scan


@router.delete("/scans/{scan_id}")
def remove_scan(scan_id: str, user_id: str):
    if not repo.delete_scan(scan_id, user_id):
        raise HTTPException(404, "Scan not found")
    return {"deleted": True}
