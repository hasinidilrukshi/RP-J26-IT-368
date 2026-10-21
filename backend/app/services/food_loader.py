"""Convert the Sri Lankan food spreadsheet into MongoDB documents.

Each spreadsheet row becomes one document in the `foods` collection.  On top of
the raw columns we add normalised fields that the safety engine relies on:
  * allergen_tags      - canonical allergen codes  (gluten, egg, milk, fish ...)
  * possible_allergens - allergens that only appear in some recipes ("if breadcrumbed")
  * animal_ingredients - ingredients that make a dish non-vegetarian / non-vegan
  * flags              - spicy, fried, high_sodium, coconut ...
"""
import re
from pathlib import Path
from typing import Dict, List

import openpyxl

# Model label -> nicer name shown in the app (others are title-cased automatically)
DISPLAY_NAMES = {
    "kottu": "Kottu Roti",
    "egg_hoppers": "Egg Hoppers",
    "plain_hopper": "Plain Hoppers",
    "pan_cake": "Pancake",
    "sandwitch": "Sandwich",
    "manioc": "Manioc (Cassava)",
    "milk_rice": "Milk Rice (Kiribath)",
    "kola_kanda": "Kola Kanda",
    "dhal_wade": "Dhal Wade (Parippu Vadai)",
    "isso_wade": "Isso Wade (Prawn Vadai)",
    "uludu_wade": "Ulundu Wade",
    "asmi": "Aasmi",
}

# Spreadsheet name -> other names the YOLO model may output for the same dish
ALIASES = {
    "plain_hopper": ["plain_hoppers", "hoppers", "appa"],
    "kottu": ["kottu_roti"],
    "sandwitch": ["sandwich"],
    "pan_cake": ["pancake"],
}

ALLERGEN_PATTERNS = {
    "gluten": r"gluten|wheat",
    "egg": r"\begg",
    "milk": r"\bmilk|dairy|butter",
    "fish": r"\bfish|maldive",
    "shellfish": r"shellfish|prawn|shrimp|crab",
    "peanuts": r"peanut",
    "tree_nuts": r"tree ?nut|cashew|almond",
    "soy": r"\bsoy",
    "sesame": r"sesame|gingelly",
}

# Ingredient keyword -> (allergen tag) used as a safety net on the ingredient list
INGREDIENT_ALLERGENS = {
    "coconut": r"coconut",
    "peanuts": r"peanut",
    "tree_nuts": r"cashew|almond",
    "sesame": r"sesame|gingelly",
    "soy": r"\bsoy",
}

ANIMAL_PATTERNS = {
    "meat": r"chicken|beef|pork|mutton|sausage|meat",
    "fish": r"fish|mackerel|tuna|balaya|maldive",
    "shellfish": r"prawn|shrimp|crab|cuttlefish",
    "egg": r"\begg",
    "dairy": r"\bmilk\b(?!.*coconut)|butter|cheese|ghee|curd|yogurt",
}

FLAG_PATTERNS = {
    "spicy": r"chil+i|pepper|curry powder",
    "fried": r"\boil\b|fried|deep",
    "coconut": r"coconut",
    "high_sodium": r"sodium|salty",
    "saturated_fat": r"saturated",
    "refined_carbs": r"refined|glycaemic|glycemic|blood sugar",
    "bloating": r"bloat|gas",
}


def _split_list(text) -> List[str]:
    if text is None:
        return []
    parts = re.split(r",(?![^()]*\))", str(text))
    return [p.strip() for p in parts if p.strip() and p.strip().lower() != "none"]


def _split_sentences(text) -> List[str]:
    if not text:
        return []
    parts = re.split(r";|\.\s", str(text))
    out = []
    for p in parts:
        p = p.strip().rstrip(".")
        if p:
            out.append(p[0].upper() + p[1:])
    return out


def _num(v):
    try:
        return round(float(v), 2)
    except (TypeError, ValueError):
        return None


def _yes(v) -> bool:
    return str(v).strip().lower() in ("yes", "y", "true", "1")


def display_name(key: str) -> str:
    return DISPLAY_NAMES.get(key, key.replace("_", " ").title())


def build_food_doc(row: Dict) -> Dict:
    key = str(row["Food_Name"]).strip().lower()
    ingredients = _split_list(row.get("Ingredients"))
    allergens_raw = _split_list(row.get("Allergens"))
    ingredients_text = " ".join(ingredients).lower()

    allergen_tags, possible = set(), set()
    for raw in allergens_raw:
        low = raw.lower()
        conditional = "if " in low or "may" in low
        for tag, pat in ALLERGEN_PATTERNS.items():
            if re.search(pat, low):
                (possible if conditional else allergen_tags).add(tag)
    for tag, pat in INGREDIENT_ALLERGENS.items():
        if re.search(pat, ingredients_text):
            allergen_tags.add(tag)
    possible -= allergen_tags

    animal = []
    for ing in ingredients:
        low = ing.lower()
        if "coconut milk" in low:
            continue
        for group, pat in ANIMAL_PATTERNS.items():
            if re.search(pat, low):
                animal.append({"ingredient": ing, "group": group})
                break

    concerns_text = str(row.get("Health_Concerns") or "").lower()
    flags = sorted(
        {f for f, pat in FLAG_PATTERNS.items() if re.search(pat, ingredients_text + " " + concerns_text)}
    )

    return {
        "food_id": row.get("Food_ID"),
        "key": key,
        "aliases": ALIASES.get(key, []),
        "name": display_name(key),
        "category": row.get("Category"),
        "ingredients": ingredients,
        "vegetarian": _yes(row.get("Vegetarian")),
        "vegan": _yes(row.get("Vegan")),
        "allergens": allergens_raw,
        "allergen_tags": sorted(allergen_tags),
        "possible_allergens": sorted(possible),
        "animal_ingredients": animal,
        "flags": flags,
        "nutrition": {
            "serving": row.get("Quantity") or "100g",
            "calories": _num(row.get("Calories (kcal)")),
            "carbohydrates": _num(row.get("Carbohydrates")),
            "protein": _num(row.get("Protein")),
            "fat": _num(row.get("Fat")),
            "sugar": _num(row.get("Sugar")),
        },
        "benefits": _split_sentences(row.get("Benefits")),
        "health_concerns": _split_sentences(row.get("Health_Concerns")),
    }


def load_foods_from_excel(path: Path) -> List[Dict]:
    wb = openpyxl.load_workbook(path, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    header = [str(h).strip() for h in rows[0]]
    docs = []
    for values in rows[1:]:
        if not values or not values[1]:
            continue
        docs.append(build_food_doc(dict(zip(header, values))))
    return docs
