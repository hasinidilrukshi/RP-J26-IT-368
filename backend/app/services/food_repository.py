"""Data-access helpers for foods, users and scans."""
import logging
import uuid
from datetime import datetime, timezone
from typing import Dict, List, Optional

from pymongo import ReturnDocument

from .. import config
from ..database import get_db
from .food_loader import load_foods_from_excel

log = logging.getLogger(__name__)


def _clean(doc: Optional[Dict]) -> Optional[Dict]:
    if doc is not None:
        doc.pop("_id", None)
    return doc


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ---------------------------------------------------------------- foods
def seed_foods(force: bool = False) -> int:
    db = get_db()
    if not force and db.foods.count_documents({}) > 0:
        return 0
    docs = load_foods_from_excel(config.FOOD_DB_PATH)
    for d in docs:
        db.foods.replace_one({"key": d["key"]}, d, upsert=True)
    log.info("Seeded %d foods from %s", len(docs), config.FOOD_DB_PATH)
    return len(docs)


def find_food(label: str) -> Optional[Dict]:
    if not label:
        return None
    key = label.strip().lower().replace(" ", "_")
    db = get_db()
    doc = db.foods.find_one({"key": key}) or db.foods.find_one({"aliases": key})
    if doc is None and key.endswith("s"):
        doc = db.foods.find_one({"key": key[:-1]})
    return _clean(doc)


def list_foods(search: str = "") -> List[Dict]:
    query = {}
    if search:
        query = {"$or": [{"name": {"$regex": search, "$options": "i"}},
                         {"key": {"$regex": search, "$options": "i"}}]}
    return [_clean(d) for d in get_db().foods.find(query).sort("name", 1)]


# ---------------------------------------------------------------- users
def create_user(profile: Optional[Dict]) -> Dict:
    user = {
        "user_id": uuid.uuid4().hex,
        "profile": profile or {},
        "profile_completed": bool(profile),
        "created_at": now_iso(),
        "updated_at": now_iso(),
    }
    get_db().users.insert_one(dict(user))
    return user


def get_user(user_id: str) -> Optional[Dict]:
    return _clean(get_db().users.find_one({"user_id": user_id}))


def update_profile(user_id: str, profile: Dict) -> Optional[Dict]:
    doc = get_db().users.find_one_and_update(
        {"user_id": user_id},
        {"$set": {"profile": profile, "profile_completed": True, "updated_at": now_iso()},
         "$setOnInsert": {"created_at": now_iso()}},
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )
    return _clean(doc)


# ---------------------------------------------------------------- scans
def save_scan(scan: Dict) -> Dict:
    get_db().scans.insert_one(dict(scan))
    return scan


def update_scan(scan_id: str, fields: Dict) -> Optional[Dict]:
    doc = get_db().scans.find_one_and_update(
        {"scan_id": scan_id}, {"$set": fields}, return_document=ReturnDocument.AFTER
    )
    return _clean(doc)


def get_scan(scan_id: str) -> Optional[Dict]:
    return _clean(get_db().scans.find_one({"scan_id": scan_id}))


def list_scans(user_id: str, limit: int = 20) -> List[Dict]:
    cur = get_db().scans.find({"user_id": user_id}).sort("created_at", -1).limit(limit)
    return [_clean(d) for d in cur]


def delete_scan(scan_id: str, user_id: str) -> bool:
    return get_db().scans.delete_one({"scan_id": scan_id, "user_id": user_id}).deleted_count > 0
