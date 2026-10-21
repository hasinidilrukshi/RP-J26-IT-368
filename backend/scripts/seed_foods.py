"""Import / refresh the Sri Lankan food database into MongoDB.

Usage (from the backend folder):
    python -m scripts.seed_foods          # import (overwrites existing foods)
"""
from app import database
from app.services.food_repository import seed_foods

if __name__ == "__main__":
    database.init_indexes()
    n = seed_foods(force=True)
    print(f"Imported {n} foods into MongoDB collection 'foods'.")
