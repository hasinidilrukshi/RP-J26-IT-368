"""Application configuration (read from environment / .env file)."""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BASE_DIR / ".env"

try:
    from dotenv import load_dotenv

    # Always read backend/.env, and let it win over old terminal variables.
    load_dotenv(ENV_FILE, override=True)
except ImportError:  # python-dotenv is optional
    pass

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "food_safety_ai")

MODEL_PATH = Path(os.getenv("MODEL_PATH", BASE_DIR / "models" / "best.pt"))
FOOD_DB_PATH = Path(os.getenv("FOOD_DB_PATH", BASE_DIR / "data" / "sri_lankan_food_database.xlsx"))
UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", BASE_DIR / "uploads"))

# YOLO inference settings
DETECTION_CONFIDENCE = float(os.getenv("DETECTION_CONFIDENCE", "0.25"))
LOW_CONFIDENCE_WARNING = float(os.getenv("LOW_CONFIDENCE_WARNING", "0.50"))
IMAGE_SIZE = int(os.getenv("IMAGE_SIZE", "640"))

MAX_UPLOAD_MB = int(os.getenv("MAX_UPLOAD_MB", "10"))

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)