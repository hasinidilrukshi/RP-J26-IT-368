"""
Ceylon Path – Emergency Severity Assessment & Response API
FastAPI + MongoDB Atlas

Setup:
    1. Create backend/.env with:
         MONGO_URI=mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/ceylonpath?retryWrites=true&w=majority
         DB_NAME=ceylonpath
    2. pip install -r requirements.txt
    3. python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Docs: http://localhost:8000/docs
"""
import logging
import math
import os
import shutil
import uuid
from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId
from bson.errors import InvalidId
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from pymongo import DESCENDING, MongoClient

from severity_model import assess, model_info
import speech

# Load backend/.env no matter which folder the server is started from
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))
log = logging.getLogger("ceylonpath")

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")


def _make_client(uri: str) -> MongoClient:
    kwargs = {"serverSelectionTimeoutMS": 10000}
    if uri.startswith("mongodb+srv://"):
        # Atlas uses TLS. certifi's CA bundle avoids
        # "CERTIFICATE_VERIFY_FAILED" errors on some Windows PCs.
        try:
            import certifi
            kwargs["tlsCAFile"] = certifi.where()
        except ImportError:
            pass
    return MongoClient(uri, **kwargs)


client = _make_client(MONGO_URI)

# Database name: DB_NAME in .env -> name inside the URI (/ceylonpath) -> "ceylonpath"
_uri_db = None
try:
    _uri_db = client.get_default_database().name
except Exception:  # noqa: BLE001  (URI has no database name)
    pass
DB_NAME = os.getenv("DB_NAME") or _uri_db or "ceylonpath"

db = client[DB_NAME]
emergencies = db["emergencies"]
services = db["response_services"]
voice_notes = db["voice_notes"]

VOICE_DIR = os.path.join(os.path.dirname(__file__), "uploads", "voice")
os.makedirs(VOICE_DIR, exist_ok=True)

app = FastAPI(title="Ceylon Path Emergency API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # admin web dashboard + mobile
    allow_methods=["*"],
    allow_headers=["*"],
)

STATUS_FLOW = ["submitted", "assessed", "dispatched", "on_the_way", "resolved"]


# --------------------------------------------------------------------------- #
# Schemas
# --------------------------------------------------------------------------- #
class EmergencyIn(BaseModel):
    tourist_name: str
    phone: str
    nationality: str = ""
    emergency_type: str = "other"
    description: str = ""
    people_affected: int = Field(1, ge=1)
    is_conscious: bool = True
    is_breathing_normally: bool = True
    has_heavy_bleeding: bool = False
    is_in_danger: bool = False
    pain_level: int = Field(0, ge=0, le=10)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: str = ""
    input_mode: str = "text"          # text | voice
    audio_id: Optional[str] = None    # from /api/transcribe


class DispatchIn(BaseModel):
    service_id: str


class StatusIn(BaseModel):
    status: str


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def oid(id_: str) -> ObjectId:
    try:
        return ObjectId(id_)
    except (InvalidId, TypeError):
        raise HTTPException(400, "Invalid id")


def serialize(doc: dict) -> dict:
    doc = dict(doc)
    doc["id"] = str(doc.pop("_id"))
    for k in ("created_at", "updated_at"):
        if isinstance(doc.get(k), datetime):
            doc[k] = doc[k].replace(tzinfo=timezone.utc).isoformat()
    return doc


def haversine_km(lat1, lng1, lat2, lng2) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def service_view(s: dict, lat: float, lng: float) -> dict:
    out = serialize(s)
    if s.get("latitude") is not None and s.get("longitude") is not None:
        d = haversine_km(lat, lng, s["latitude"], s["longitude"])
        out["distance_km"] = round(d, 1)
        out["eta_minutes"] = int(d / 40 * 60) + 5  # ~40 km/h average + 5 min
    else:  # national hotline – no fixed location
        out["distance_km"] = 0
        out["eta_minutes"] = s.get("default_eta", 15)
    return out


# --------------------------------------------------------------------------- #
# Seed data (runs once when the collection is empty)
# NOTE: hotline numbers are Sri Lanka national numbers. Replace the hospital
# phone numbers with verified direct numbers before real use.
# --------------------------------------------------------------------------- #
SEED_SERVICES = [
    {"name": "Suwa Seriya Ambulance (1990)", "type": "ambulance", "phone": "1990",
     "address": "National free ambulance service", "default_eta": 15},
    {"name": "Police Emergency", "type": "police", "phone": "119",
     "address": "Sri Lanka Police", "default_eta": 15},
    {"name": "Tourist Police", "type": "tourist_police", "phone": "+94112421052",
     "address": "Sri Lanka Tourist Police, Colombo", "default_eta": 20},
    {"name": "Tourist Hotline (SLTDA)", "type": "tourist_police", "phone": "1912",
     "address": "Sri Lanka Tourism 24h hotline", "default_eta": 20},
    {"name": "Wildlife Hotline", "type": "wildlife", "phone": "1992",
     "address": "Dept. of Wildlife Conservation / Wildlife Ministry 24h", "default_eta": 30},
    {"name": "Forest & Wildlife Hotline", "type": "forest", "phone": "1992",
     "address": "Report forest emergencies (24h)", "default_eta": 30},
    {"name": "Sri Lanka Coast Guard", "type": "coast_guard", "phone": "106",
     "address": "Maritime distress hotline", "default_eta": 25},
    {"name": "Sri Lanka Navy", "type": "coast_guard", "phone": "105",
     "address": "Navy HQ maritime incident hotline", "default_eta": 30},
    {"name": "Beach Lifeguards", "type": "lifeguard", "phone": "119",
     "address": "No national number – alert the nearest lifeguard tower or call Police 119",
     "default_eta": 5},
    {"name": "Disaster Management Centre", "type": "disaster", "phone": "117",
     "address": "Floods, landslides, storms (24h)", "default_eta": 30},
    {"name": "Fire & Rescue", "type": "fire", "phone": "110",
     "address": "Emergency and rescue services", "default_eta": 20},
    {"name": "National Hospital of Sri Lanka", "type": "hospital", "phone": "1990",
     "address": "Colombo 10", "latitude": 6.9188, "longitude": 79.8681},
    {"name": "Teaching Hospital Kandy", "type": "hospital", "phone": "1990",
     "address": "Kandy", "latitude": 7.2866, "longitude": 80.6326},
    {"name": "Teaching Hospital Karapitiya", "type": "hospital", "phone": "1990",
     "address": "Galle", "latitude": 6.0659, "longitude": 80.2247},
    {"name": "District General Hospital Matale", "type": "hospital", "phone": "1990",
     "address": "Matale (near Sigiriya / Dambulla)", "latitude": 7.4675, "longitude": 80.6234},
    {"name": "Provincial General Hospital Badulla", "type": "hospital", "phone": "1990",
     "address": "Badulla (near Ella)", "latitude": 6.9848, "longitude": 81.0560},
]


def _hidden_uri(uri: str) -> str:
    """Hide the password when printing the connection string."""
    if "@" in uri and "://" in uri:
        scheme, rest = uri.split("://", 1)
        return f"{scheme}://***:***@{rest.split('@', 1)[1]}"
    return uri


@app.on_event("startup")
def seed():
    try:
        client.admin.command("ping")
        print(f"[DB] Connected to MongoDB -> database '{DB_NAME}' ({_hidden_uri(MONGO_URI)})")
        # upsert by name: adds new services without touching edited ones
        for s in SEED_SERVICES:
            services.update_one({"name": s["name"]}, {"$setOnInsert": dict(s)}, upsert=True)
        emergencies.create_index([("created_at", DESCENDING)])
        emergencies.create_index("phone")
    except Exception as e:  # noqa: BLE001
        print("[DB] Could NOT connect to MongoDB:", e)
        print("     Check MONGO_URI in backend/.env, the username/password, and that your")
        print("     IP is allowed in Atlas -> Network Access (0.0.0.0/0 for testing).")
    speech.warm_up()


# --------------------------------------------------------------------------- #
# Routes
# --------------------------------------------------------------------------- #
@app.get("/")
def root():
    return {"status": "ok", "service": "Ceylon Path Emergency API"}


@app.get("/api/health")
def health():
    """Quick check that the API and the database are reachable."""
    try:
        client.admin.command("ping")
        return {"api": "ok", "database": DB_NAME, "mongodb": "connected"}
    except Exception as e:  # noqa: BLE001
        return {"api": "ok", "database": DB_NAME, "mongodb": f"error: {e}"}


@app.post("/api/emergencies", status_code=201)
def create_emergency(body: EmergencyIn):
    data = body.model_dump()
    now = datetime.utcnow()
    assessment = assess(data)
    if data.get("emergency_type", "other") == "other":
        data["emergency_type"] = assessment["predicted_type"]  # AI fills it in
    if data.get("audio_id"):
        v = voice_notes.find_one({"_id": data["audio_id"]})
        if v:
            data["voice"] = {k: v.get(k) for k in (
                "original_text", "text", "language", "language_name",
                "language_probability", "duration")}
            data["voice"]["audio_url"] = f"/api/voice/{data['audio_id']}"
    data.update(
        assessment=assessment,
        status="assessed",
        assigned_service=None,
        created_at=now,
        updated_at=now,
    )
    res = emergencies.insert_one(data)
    return serialize(emergencies.find_one({"_id": res.inserted_id}))


@app.get("/api/emergencies")
def list_emergencies(phone: Optional[str] = None, status: Optional[str] = None,
                     limit: int = 100):
    q = {}
    if phone:
        q["phone"] = phone
    if status:
        q["status"] = status
    cur = emergencies.find(q).sort("created_at", DESCENDING).limit(limit)
    return [serialize(d) for d in cur]


@app.get("/api/emergencies/{emergency_id}")
def get_emergency(emergency_id: str):
    doc = emergencies.find_one({"_id": oid(emergency_id)})
    if not doc:
        raise HTTPException(404, "Emergency not found")
    return serialize(doc)


@app.post("/api/emergencies/{emergency_id}/dispatch")
def dispatch(emergency_id: str, body: DispatchIn):
    e = emergencies.find_one({"_id": oid(emergency_id)})
    if not e:
        raise HTTPException(404, "Emergency not found")
    s = services.find_one({"_id": oid(body.service_id)})
    if not s:
        raise HTTPException(404, "Service not found")
    view = service_view(s, e.get("latitude") or 7.8731, e.get("longitude") or 80.7718)
    emergencies.update_one(
        {"_id": e["_id"]},
        {"$set": {"assigned_service": view, "status": "dispatched",
                  "updated_at": datetime.utcnow()}},
    )
    return serialize(emergencies.find_one({"_id": e["_id"]}))


@app.patch("/api/emergencies/{emergency_id}/status")
def update_status(emergency_id: str, body: StatusIn):
    if body.status not in STATUS_FLOW:
        raise HTTPException(400, f"status must be one of {STATUS_FLOW}")
    res = emergencies.update_one(
        {"_id": oid(emergency_id)},
        {"$set": {"status": body.status, "updated_at": datetime.utcnow()}},
    )
    if res.matched_count == 0:
        raise HTTPException(404, "Emergency not found")
    return serialize(emergencies.find_one({"_id": oid(emergency_id)}))


@app.get("/api/services/nearby")
def nearby_services(lat: float, lng: float, emergency_type: str = "other",
                    services_param: Optional[str] = Query(None, alias="services"),
                    limit: int = 12):
    """`services` = comma list from the assessment, e.g. ambulance,hospital"""
    if services_param:
        rec = [s.strip() for s in services_param.split(",") if s.strip()]
    else:
        rec = assess({"emergency_type": emergency_type})["recommended_services"]
    items = [service_view(s, lat, lng) for s in services.find()]
    hospitals = sorted([i for i in items if i["type"] == "hospital"],
                       key=lambda s: s["distance_km"])[:2]
    recommended = [i for t in rec for i in items if i["type"] == t and i["type"] != "hospital"]
    if "hospital" in rec:
        recommended += hospitals
    rest = [i for i in items if i not in recommended
            and (i["type"] != "hospital" or i in hospitals)]
    return (recommended + rest)[:limit]


@app.post("/api/transcribe")
def transcribe_voice(audio: UploadFile = File(...)):
    """Upload a voice note -> Whisper -> English text + AI preview."""
    ext = os.path.splitext(audio.filename or "")[1].lower() or ".m4a"
    if ext not in (".m4a", ".aac", ".mp3", ".wav", ".ogg", ".webm", ".3gp", ".mp4"):
        raise HTTPException(400, f"Unsupported audio type {ext}")
    audio_id = uuid.uuid4().hex
    path = os.path.join(VOICE_DIR, audio_id + ext)
    with open(path, "wb") as f:
        shutil.copyfileobj(audio.file, f)
    try:
        result = speech.transcribe(path)
    except speech.SpeechUnavailable as e:
        raise HTTPException(503, str(e))
    except Exception as e:  # noqa: BLE001
        raise HTTPException(422, f"Could not read the audio: {e}")
    if not result["text"]:
        raise HTTPException(422, "No speech detected. Please try again closer to the phone.")
    voice_notes.insert_one({"_id": audio_id, "path": path,
                            "created_at": datetime.utcnow(), **result})
    preview = assess({"description": result["text"]})
    return {"audio_id": audio_id, **result,
            "preview": {k: preview[k] for k in
                        ("severity", "predicted_type", "predicted_type_label", "confidence")}}


@app.get("/api/voice/{audio_id}")
def get_voice(audio_id: str):
    """Play the original voice note (for the admin dashboard)."""
    v = voice_notes.find_one({"_id": audio_id})
    if not v or not os.path.exists(v["path"]):
        raise HTTPException(404, "Voice note not found")
    return FileResponse(v["path"])


@app.post("/api/assess")
def assess_only(body: EmergencyIn):
    """Run the model without saving – handy for testing in /docs."""
    return assess(body.model_dump())


@app.get("/api/model/info")
def get_model_info():
    return model_info()