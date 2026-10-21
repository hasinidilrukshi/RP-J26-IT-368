"""Quick check that best.pt loads and recognises a photo.

Usage (from the backend folder):
    python -m scripts.test_model path/to/food.jpg
"""
import json
import sys

from app.services.detector import detector

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Classes:", detector.class_names)
        sys.exit("Give an image path to run a prediction")
    with open(sys.argv[1], "rb") as f:
        print(json.dumps(detector.predict(f.read()), indent=2))
