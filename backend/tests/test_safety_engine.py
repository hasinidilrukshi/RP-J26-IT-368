"""Run with:  python -m pytest tests  (no MongoDB or model needed)."""
from pathlib import Path

from app.services.food_loader import load_foods_from_excel
from app.services.safety_engine import evaluate

DATA = Path(__file__).resolve().parent.parent / "data" / "sri_lankan_food_database.xlsx"
FOODS = {d["key"]: d for d in load_foods_from_excel(DATA)}


def test_all_rows_loaded():
    assert len(FOODS) == 40
    assert "plain_hoppers" in FOODS["plain_hopper"]["aliases"]


def test_vegetarian_kottu_is_avoid():
    r = evaluate(FOODS["kottu"], {"diet": "vegetarian", "allergies": ["peanuts"]}, 0.92)
    assert r["status"] == "AVOID"
    texts = " ".join(x["text"] for x in r["reasons"])
    assert "chicken" in texts and "egg" in texts and "gluten" in texts


def test_dhal_curry_safe_for_vegan():
    assert evaluate(FOODS["dhal_curry"], {"diet": "vegan"}, 0.9)["status"] == "SAFE"


def test_gluten_allergy():
    r = evaluate(FOODS["samosa"], {"allergies": ["wheat_gluten"]}, 0.9)
    assert r["status"] == "AVOID"


def test_possible_gluten_is_caution():
    r = evaluate(FOODS["fish_cutlet"], {"restrictions": ["gluten_free"]}, 0.9)
    assert r["status"] == "CAUTION"


def test_diabetes_sweets():
    assert evaluate(FOODS["halapa"], {"medical_conditions": ["diabetes"]})["status"] == "AVOID"
    assert evaluate(FOODS["string_hoppers"], {"medical_conditions": ["diabetes"]})["status"] == "CAUTION"


def test_low_confidence_adds_caution():
    r = evaluate(FOODS["plain_hopper"], {}, 0.3)
    assert r["status"] == "CAUTION"
