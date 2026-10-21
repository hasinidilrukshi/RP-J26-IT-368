"""MongoDB connection helpers."""
import logging
import re

from pymongo import ASCENDING, DESCENDING, MongoClient

from . import config

log = logging.getLogger(__name__)
_client = None
_db = None


def _safe_uri(uri: str) -> str:
    """Hide the password when logging the connection string."""
    return re.sub(r"//([^:/@]+):[^@]*@", r"//\1:****@", uri)


def get_db():
    """Return a (cached) handle to the application database."""
    global _client, _db
    if _db is None:
        if config.MONGO_URI.startswith("mongomock://"):
            # In-memory MongoDB for quick tests:  MONGO_URI=mongomock://localhost
            import mongomock

            _client = mongomock.MongoClient()
        else:
            kwargs = {"serverSelectionTimeoutMS": 20000}
            if config.MONGO_URI.startswith("mongodb+srv://") or "mongodb.net" in config.MONGO_URI:
                import certifi  # trusted CA list - avoids SSL errors with Atlas on Windows

                kwargs["tlsCAFile"] = certifi.where()
            _client = MongoClient(config.MONGO_URI, **kwargs)
        log.info("MongoDB: %s  (database '%s', .env found: %s)",
                 _safe_uri(config.MONGO_URI), config.MONGO_DB_NAME, config.ENV_FILE.exists())
        _db = _client[config.MONGO_DB_NAME]
    return _db


def init_indexes():
    db = get_db()
    db.foods.create_index([("key", ASCENDING)], unique=True)
    db.foods.create_index([("aliases", ASCENDING)])
    db.users.create_index([("user_id", ASCENDING)], unique=True)
    db.scans.create_index([("user_id", ASCENDING), ("created_at", DESCENDING)])
    db.scans.create_index([("scan_id", ASCENDING)], unique=True)


def close():
    global _client, _db
    if _client is not None:
        _client.close()
    _client, _db = None, None