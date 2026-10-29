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
from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from pymongo import DESCENDING, MongoClient
from pymongo.errors import ConfigurationError

from severity_model import assess, model_info
import speech

# Load backend/.env no matter which folder the server is started from
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))
log = logging.getLogger("ceylonpath")

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")


PUBLIC_DNS = ["8.8.8.8", "1.1.1.1"]  # Google, Cloudflare


def _use_public_dns() -> bool:
    """Some Wi-Fi / campus / mobile networks cannot look up the SRV records
    that a 'mongodb+srv://' Atlas address needs ("DNS query name does not
    exist"). Then we ask Google / Cloudflare DNS instead."""
    try:
        import dns.resolver
    except ImportError:
        return False
    r = dns.resolver.Resolver(configure=False)
    r.nameservers = PUBLIC_DNS
    dns.resolver.default_resolver = r
    return True


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
    try:
        return MongoClient(uri, **kwargs)
    except ConfigurationError as e:
        # 1st try used this computer's DNS. If the Atlas address could not be
        # found, try again with public DNS before giving up.
        if not uri.startswith("mongodb+srv://") or not _use_public_dns():
            raise
        print(f"[DB] This network's DNS could not find the Atlas cluster ({e}).")
        print(f"     Retrying with public DNS {', '.join(PUBLIC_DNS)} ...")
        try:
            client_ = MongoClient(uri, **kwargs)
            print("[DB] Atlas address found using public DNS.")
            return client_
        except ConfigurationError as e2:
            raise SystemExit(
                "\n[DB] Could not find the MongoDB Atlas cluster, even with public DNS.\n"
                f"     Error: {e2}\n"
                "     1. Copy the address again: Atlas -> Connect -> Drivers -> Python,\n"
                "        and paste it into MONGO_URI in backend/.env\n"
                "     2. Check that this computer has internet (try a phone hotspot).\n"
            ) from e2


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
    # Name / phone are OPTIONAL: a tourist in danger must never be blocked
    # by a form. The app sends them only if the tourist saved a profile.
    tourist_name: str = ""
    phone: str = ""
    nationality: str = ""
    emergency_contact: str = ""
    device_id: str = ""               # anonymous id of the phone (history)
    location_accuracy: Optional[float] = None
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


class DetailsIn(BaseModel):
    """OPTIONAL follow-up answers sent AFTER the SOS. Every field may be left
    out; only the fields that are sent are changed."""
    is_conscious: Optional[bool] = None
    is_breathing_normally: Optional[bool] = None
    has_heavy_bleeding: Optional[bool] = None
    is_in_danger: Optional[bool] = None
    people_affected: Optional[int] = Field(None, ge=1)
    extra_message: Optional[str] = None
    address: Optional[str] = None     # landmark typed after the SOS
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_accuracy: Optional[float] = None


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


# Approximate town-centre coordinates, used only to show "near Ella (3 km)"
# next to the GPS point. The exact GPS coordinates are always sent too.
PLACES = [
    ("Colombo", 6.9271, 79.8612), ("Negombo", 7.2083, 79.8358),
    ("Gampaha", 7.0917, 79.9999), ("Kelaniya", 6.9553, 79.9220),
    ("Biyagama", 6.9420, 79.9830), ("Kaduwela", 6.9330, 79.9840),
    ("Avissawella", 6.9533, 80.2100), ("Kitulgala", 6.9890, 80.4170),
    ("Ratnapura", 6.6828, 80.3992), ("Kandy", 7.2906, 80.6337),
    ("Nuwara Eliya", 6.9497, 80.7891), ("Horton Plains", 6.8020, 80.8070),
    ("Bandarawela", 6.8259, 80.9982), ("Ella", 6.8667, 81.0466),
    ("Badulla", 6.9934, 81.0550), ("Sigiriya", 7.9570, 80.7603),
    ("Dambulla", 7.8742, 80.6511), ("Polonnaruwa", 7.9403, 81.0188),
    ("Anuradhapura", 8.3114, 80.4037), ("Jaffna", 9.6615, 80.0255),
    ("Trincomalee", 8.5874, 81.2152), ("Arugam Bay", 6.8400, 81.8368),
    ("Yala", 6.3700, 81.5200), ("Tissamaharama", 6.2786, 81.2876),
    ("Matara", 5.9549, 80.5550), ("Mirissa", 5.9483, 80.4716),
    ("Galle", 6.0535, 80.2210), ("Unawatuna", 6.0100, 80.2497),
    ("Hikkaduwa", 6.1395, 80.1063), ("Bentota", 6.4210, 80.0000),
]


def nearest_place(lat: Optional[float], lng: Optional[float]) -> Optional[dict]:
    if lat is None or lng is None:
        return None
    name, plat, plng = min(PLACES, key=lambda p: haversine_km(lat, lng, p[1], p[2]))
    return {"name": name, "distance_km": round(haversine_km(lat, lng, plat, plng), 1)}


def services_for(lat: Optional[float], lng: Optional[float], rec: list,
                 limit: int = 12) -> list:
    """Recommended services first (in the order the AI chose), then the rest.
    Hospitals are ranked by distance from the tourist."""
    if lat is None or lng is None:
        lat, lng = 7.8731, 80.7718  # centre of Sri Lanka -> distances unknown
    items = [service_view(s, lat, lng) for s in services.find()]
    hospitals = sorted([i for i in items if i["type"] == "hospital"],
                       key=lambda s: s["distance_km"])[:2]
    recommended = [i for t in rec for i in items if i["type"] == t and i["type"] != "hospital"]
    if "hospital" in rec:
        recommended += hospitals
    for i in recommended:
        i["recommended"] = True
    # nearest hospitals right after the recommended ones, then the hotlines
    rest = [h for h in hospitals if h not in recommended]
    rest += [i for i in items if i not in recommended and i["type"] != "hospital"]
    return (recommended + rest)[:limit]


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
        nearest_place=nearest_place(data.get("latitude"), data.get("longitude")),
        status="assessed",
        assigned_service=None,
        created_at=now,
        updated_at=now,
    )
    res = emergencies.insert_one(data)
    return serialize(emergencies.find_one({"_id": res.inserted_id}))


@app.get("/api/emergencies")
def list_emergencies(phone: Optional[str] = None, status: Optional[str] = None,
                     device_id: Optional[str] = None, limit: int = 100):
    q = {}
    if phone:
        q["phone"] = phone
    if device_id:
        q["device_id"] = device_id
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
    return services_for(lat, lng, rec, limit)


# --------------------------------------------------------------------------- #
# ONE-STEP SOS: text OR voice + GPS  ->  assessment + who to call
# --------------------------------------------------------------------------- #
def _opt_float(v: Optional[str]) -> Optional[float]:
    try:
        return float(v) if v not in (None, "", "null") else None
    except ValueError:
        return None


@app.post("/api/sos", status_code=201)
def sos(
    message: str = Form(""),
    audio: Optional[UploadFile] = File(None),
    latitude: Optional[str] = Form(None),
    longitude: Optional[str] = Form(None),
    location_accuracy: Optional[str] = Form(None),
    address: str = Form(""),
    tourist_name: str = Form(""),
    phone: str = Form(""),
    nationality: str = Form(""),
    emergency_contact: str = Form(""),
    device_id: str = Form(""),
):
    """The tourist only types a message OR records a voice note.
    Everything else (GPS, type, severity, responders) is worked out here."""
    text = (message or "").strip()
    voice = None
    audio_id = None

    if audio is not None and audio.filename:
        ext = os.path.splitext(audio.filename)[1].lower() or ".m4a"
        if ext not in (".m4a", ".aac", ".mp3", ".wav", ".ogg", ".webm", ".3gp", ".mp4"):
            raise HTTPException(400, f"Unsupported audio type {ext}")
        audio_id = uuid.uuid4().hex
        path = os.path.join(VOICE_DIR, audio_id + ext)
        with open(path, "wb") as f:
            shutil.copyfileobj(audio.file, f)
        try:
            result = speech.transcribe(path)
        except speech.SpeechUnavailable as e:
            if not text:
                raise HTTPException(503, str(e))
            result = None
        except Exception as e:  # noqa: BLE001
            if not text:
                raise HTTPException(422, f"Could not read the audio: {e}")
            result = None
        if result and result.get("text"):
            voice_notes.insert_one({"_id": audio_id, "path": path,
                                    "created_at": datetime.utcnow(), **result})
            voice = {k: result.get(k) for k in (
                "original_text", "text", "language", "language_name",
                "language_probability", "duration")}
            voice["audio_url"] = f"/api/voice/{audio_id}"
            # typed words (if any) + what was said
            text = f"{text}. {result['text']}".strip(". ") if text else result["text"]
        elif not text:
            raise HTTPException(422, "No speech detected. Please speak closer to the phone or type.")

    if len(text) < 2:
        raise HTTPException(422, "Please type or say what happened.")

    lat, lng = _opt_float(latitude), _opt_float(longitude)
    data = EmergencyIn(
        tourist_name=tourist_name, phone=phone, nationality=nationality,
        emergency_contact=emergency_contact, device_id=device_id,
        description=text, latitude=lat, longitude=lng,
        location_accuracy=_opt_float(location_accuracy), address=address,
        input_mode="voice" if voice else "text", audio_id=audio_id if voice else None,
    ).model_dump()

    assessment = assess(data)
    data["emergency_type"] = assessment["predicted_type"]  # AI decides the type
    now = datetime.utcnow()
    data.update(
        assessment=assessment,
        nearest_place=nearest_place(lat, lng),
        status="assessed",
        assigned_service=None,
        created_at=now,
        updated_at=now,
    )
    if voice:
        data["voice"] = voice
    res = emergencies.insert_one(data)
    report = serialize(emergencies.find_one({"_id": res.inserted_id}))
    return {"report": report,
            "services": services_for(lat, lng, assessment["recommended_services"])}


@app.patch("/api/emergencies/{emergency_id}/details")
def add_details(emergency_id: str, body: DetailsIn):
    """Optional answers / better GPS sent after the SOS -> re-assess."""
    e = emergencies.find_one({"_id": oid(emergency_id)})
    if not e:
        raise HTTPException(404, "Emergency not found")
    upd = {k: v for k, v in body.model_dump().items()
           if v is not None and k != "extra_message"}
    if body.extra_message and body.extra_message.strip():
        upd["description"] = f"{e.get('description', '')}. {body.extra_message.strip()}".strip(". ")
    merged = {**e, **upd}
    assessment = assess(merged)
    old = (e.get("assessment") or {}).get("severity", "Low")
    sev = ["Low", "Medium", "High", "Critical"]
    # answers may only RAISE the urgency of an open emergency, never lower it
    if sev.index(assessment["severity"]) < sev.index(old):
        new = assessment["severity"]
        if assessment["summary"].startswith(new):
            assessment["summary"] = old + assessment["summary"][len(new):]
        assessment["severity"] = old
        assessment["score"] = max(assessment["score"], (e.get("assessment") or {}).get("score", 0))
    upd.update(assessment=assessment,
               emergency_type=assessment["predicted_type"],
               nearest_place=nearest_place(merged.get("latitude"), merged.get("longitude")),
               updated_at=datetime.utcnow())
    emergencies.update_one({"_id": e["_id"]}, {"$set": upd})
    report = serialize(emergencies.find_one({"_id": e["_id"]}))
    return {"report": report,
            "services": services_for(merged.get("latitude"), merged.get("longitude"),
                                     assessment["recommended_services"])}


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