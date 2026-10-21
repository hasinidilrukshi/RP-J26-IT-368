"""Rule-based safety engine.

Correlates a food document (from MongoDB) with the tourist's health profile and
produces:
  status   : SAFE | CAUTION | AVOID
  score    : 0-100 safety score (higher = safer)
  reasons  : why the verdict was given  (severity: avoid | caution | info | ok)
  benefits / risks : personalised health benefits and potential health risks

Each rule adds a penalty.  Any "avoid" rule forces AVOID; otherwise penalties
decide between SAFE and CAUTION.  Thresholds are per 100 g, matching the database.
"""
import re
from typing import Dict, List, Optional

ALLERGY_LABELS = {
    "peanuts": "peanuts", "tree_nuts": "tree nuts", "milk": "milk / dairy", "egg": "egg",
    "fish": "fish", "shellfish": "shellfish", "soy": "soy", "wheat_gluten": "gluten (wheat)",
    "sesame": "sesame", "coconut": "coconut",
}
# profile allergy code -> food allergen tag
ALLERGY_TO_TAG = {"wheat_gluten": "gluten"}

CONDITION_LABELS = {
    "diabetes": "Diabetes", "hypertension": "High blood pressure",
    "heart_disease": "Heart disease", "high_cholesterol": "High cholesterol",
    "kidney_disease": "Kidney disease", "gastritis": "Gastritis / IBS",
    "obesity": "Weight management", "pregnancy": "Pregnancy",
}
DIET_LABELS = {
    "vegetarian": "Vegetarian", "vegan": "Vegan",
    "non_vegetarian": "Non-vegetarian", "no_preference": "No specific preference",
}
RESTRICTION_LABELS = {
    "gluten_free": "Gluten-free", "low_sugar": "Low sugar",
    "low_salt": "Low salt", "low_fat": "Low fat",
}

SWEET_CATEGORIES = {"sweet", "dessert"}

# thresholds per 100 g
HIGH_SUGAR, VERY_HIGH_SUGAR = 10, 20
HIGH_CARBS = 30
HIGH_FAT, VERY_HIGH_FAT = 12, 25
HIGH_CALORIES = 250


class _Result:
    def __init__(self):
        self.penalty = 0
        self.avoid = False
        self.reasons: List[Dict] = []
        self.risks: List[str] = []

    def add(self, severity: str, text: str, penalty: int = 0, risk: Optional[str] = None):
        if severity == "avoid":
            self.avoid = True
        self.penalty += penalty
        self.reasons.append({"severity": severity, "text": text})
        if risk and risk not in self.risks:
            self.risks.append(risk)


def _short(ingredient: str) -> str:
    """'Fish (tuna/balaya)' -> 'fish', 'Seeni sambol (.. Maldive fish ..)' -> 'Maldive fish'."""
    low = ingredient.lower()
    if "maldive" in low:
        return "Maldive fish"
    return re.sub(r"\s*\(.*?\)", "", ingredient).strip().lower()


def _nut(food, field):
    return (food.get("nutrition") or {}).get(field) or 0


def profile_tags(profile: Dict) -> List[str]:
    tags = []
    diet = profile.get("diet", "no_preference")
    if diet != "no_preference":
        tags.append(DIET_LABELS.get(diet, diet))
    tags += [f"{ALLERGY_LABELS.get(a, a).capitalize()} allergy" for a in profile.get("allergies", [])]
    if profile.get("other_allergy"):
        tags.append(f"{profile['other_allergy'].strip().capitalize()} allergy")
    tags += [RESTRICTION_LABELS.get(r, r) for r in profile.get("restrictions", [])]
    tags += [CONDITION_LABELS.get(c, c) for c in profile.get("medical_conditions", [])]
    return tags


def ingredient_flags(food: Dict, profile: Dict) -> List[Dict]:
    """Mark every ingredient as ok / conflict for the ingredients screen."""
    diet = profile.get("diet", "no_preference")
    allergies = set(profile.get("allergies", []))
    other = (profile.get("other_allergy") or "").strip().lower()
    animal = {a["ingredient"]: a["group"] for a in food.get("animal_ingredients", [])}
    out = []
    for ing in food.get("ingredients", []):
        low = ing.lower()
        note = None
        group = animal.get(ing)
        if group and diet == "vegan":
            note = "Not vegan"
        elif group and group != "dairy" and diet == "vegetarian":
            note = "Not vegetarian"
        checks = {
            "egg": "egg" in low, "fish": group == "fish", "shellfish": group == "shellfish",
            "milk": group == "dairy" or "margarine" in low,
            "wheat_gluten": any(w in low for w in ("wheat", "bread")) or (low.startswith("flour")),
            "coconut": "coconut" in low, "peanuts": "peanut" in low,
            "tree_nuts": any(n in low for n in ("cashew", "almond")),
            "sesame": "sesame" in low, "soy": "soy" in low,
        }
        for allergy in allergies:
            if checks.get(allergy):
                note = f"Allergen: {ALLERGY_LABELS.get(allergy, allergy)}"
        if other and other in low:
            note = f"Allergen: {other}"
        out.append({"name": ing, "conflict": note is not None, "note": note})
    return out


def evaluate(food: Dict, profile: Dict, confidence: Optional[float] = None,
             low_confidence: float = 0.5) -> Dict:
    r = _Result()
    profile = profile or {}
    diet = profile.get("diet", "no_preference")
    allergies = set(profile.get("allergies", []))
    restrictions = set(profile.get("restrictions", []))
    conditions = set(profile.get("medical_conditions", []))
    tags = set(food.get("allergen_tags", []))
    possible = set(food.get("possible_allergens", []))
    flags = set(food.get("flags", []))
    category = str(food.get("category") or "").lower()
    animal = food.get("animal_ingredients", [])
    sugar, carbs, fat, kcal = (_nut(food, f) for f in ("sugar", "carbohydrates", "fat", "calories"))

    # 1. Allergies (most important) -------------------------------------
    for allergy in sorted(allergies):
        tag = ALLERGY_TO_TAG.get(allergy, allergy)
        label = ALLERGY_LABELS.get(allergy, allergy)
        if tag in tags:
            r.add("avoid", f"Contains {label} - you are allergic", 60,
                  f"Allergic reaction risk ({label})")
        elif tag in possible:
            r.add("caution", f"May contain {label} depending on the recipe", 25,
                  f"Possible hidden {label}")
    other_allergy = (profile.get("other_allergy") or "").strip().lower()
    if other_allergy:
        if any(other_allergy in i.lower() for i in food.get("ingredients", [])):
            r.add("avoid", f"Contains {other_allergy} - you are allergic", 60,
                  f"Allergic reaction risk ({other_allergy})")

    # 2. Diet ----------------------------------------------------------
    if diet == "vegetarian" and not food.get("vegetarian", True):
        for a in animal:
            if a["group"] != "dairy":
                r.add("avoid", f"Contains {_short(a['ingredient'])} (not vegetarian)", 40)
        if not any(x["severity"] == "avoid" and "vegetarian" in x["text"] for x in r.reasons):
            r.add("avoid", "Not suitable for a vegetarian diet", 40)
    elif diet == "vegan" and not food.get("vegan", True):
        for a in animal:
            r.add("avoid", f"Contains {_short(a['ingredient'])} (not vegan)", 40)
        if not animal:
            r.add("avoid", "Contains animal products such as butter or milk (not vegan)", 40)

    # 3. Dietary restrictions ------------------------------------------
    if "gluten_free" in restrictions:
        if "gluten" in tags:
            r.add("avoid", "Contains gluten (wheat) - not gluten-free", 50, "Gluten exposure")
        elif "gluten" in possible:
            r.add("caution", "May contain gluten (e.g. breadcrumbs)", 20, "Possible gluten")
    if "low_sugar" in restrictions and (sugar >= HIGH_SUGAR or category in SWEET_CATEGORIES):
        r.add("caution", f"High in sugar ({sugar:g} g per 100 g)", 20, "High sugar content")
    if "low_salt" in restrictions and ("high_sodium" in flags or "sambol" in food.get("key", "")):
        r.add("caution", "Likely high in salt / sodium", 20, "High sodium")
    if "low_fat" in restrictions and fat >= HIGH_FAT:
        r.add("caution", f"High in fat ({fat:g} g per 100 g)", 20, "High fat content")

    # 4. Medical conditions --------------------------------------------
    if "diabetes" in conditions:
        if sugar >= VERY_HIGH_SUGAR:
            r.add("avoid", f"Very high sugar ({sugar:g} g/100 g) - unsafe with diabetes", 45,
                  "Blood sugar spike")
        elif sugar >= HIGH_SUGAR or category in SWEET_CATEGORIES:
            r.add("caution", "Sweet dish - may raise blood sugar", 25, "Blood sugar spike")
        elif carbs >= HIGH_CARBS:
            r.add("caution", f"High in carbohydrates ({carbs:g} g/100 g)", 15,
                  "Raises blood sugar quickly")
        elif "refined_carbs" in flags:
            r.add("caution", "Made with refined flour / rice - may raise blood sugar", 10,
                  "Raises blood sugar quickly")
    if "hypertension" in conditions and ("high_sodium" in flags or "sambol" in food.get("key", "")):
        r.add("caution", "High sodium may raise blood pressure", 20, "Raised blood pressure")
    if conditions & {"heart_disease", "high_cholesterol"}:
        if fat >= VERY_HIGH_FAT:
            r.add("avoid", f"Very high fat ({fat:g} g/100 g) - not heart friendly", 40,
                  "Heart health risk (saturated fat)")
        elif fat >= HIGH_FAT or "saturated_fat" in flags or "fried" in flags:
            r.add("caution", "Contains saturated fat / oil - limit portion", 15,
                  "Saturated fat raises cholesterol")
    if "kidney_disease" in conditions:
        if "high_sodium" in flags:
            r.add("caution", "High sodium is hard on the kidneys", 20, "Kidney strain (sodium)")
        if _nut(food, "protein") >= 10:
            r.add("caution", "High protein - check with your diet plan", 10, "Kidney strain (protein)")
    if "gastritis" in conditions and (flags & {"spicy", "bloating", "fried"}):
        r.add("caution", "Spicy / oily food may upset the stomach", 15, "Stomach irritation")
    if "obesity" in conditions and (kcal >= HIGH_CALORIES or fat >= HIGH_FAT):
        r.add("caution", f"Energy-dense ({kcal:g} kcal per 100 g)", 15, "High calorie intake")
    if "pregnancy" in conditions and any(a["group"] in ("fish", "shellfish", "egg") for a in animal):
        r.add("info", "Pregnancy: make sure fish / eggs are freshly and fully cooked", 5,
              "Food-borne illness if undercooked")

    # 5. Model confidence ----------------------------------------------
    if confidence is not None and confidence < low_confidence:
        r.add("caution", f"Low recognition confidence ({confidence:.0%}) - confirm the dish", 10)

    # 6. Other common allergens present (informational) -----------------
    flagged = {ALLERGY_TO_TAG.get(a, a) for a in allergies}
    others = [t for t in sorted(tags) if t not in flagged and t != "coconut"]
    if others:
        names = {"gluten": "gluten (wheat)", "milk": "milk / dairy"}
        r.add("info", "Also contains: " + ", ".join(names.get(t, t.replace("_", " ")) for t in others))

    # 7. Generic risks from the database (not personal) -------------------
    general_risks = list(food.get("health_concerns", []))

    # ---------------------------------------------------------------
    score = max(0, min(100, 100 - r.penalty))
    if r.avoid:
        status = "AVOID"
        score = min(score, 30)
    elif score < 85 or any(x["severity"] == "caution" for x in r.reasons):
        status = "CAUTION"
        score = max(40, min(score, 79))
    else:
        status = "SAFE"
        score = max(score, 80)

    if not any(x["severity"] in ("avoid", "caution") for x in r.reasons):
        r.reasons.insert(0, {"severity": "ok", "text": "No conflicts with your dietary profile"})
    if not r.reasons[1:] and r.reasons[0]["severity"] == "ok":
        if food.get("vegetarian"):
            r.reasons.append({"severity": "ok", "text": "Vegetarian friendly"})
        if "gluten" not in tags:
            r.reasons.append({"severity": "ok", "text": "Gluten free"})

    titles = {"SAFE": "SAFE TO EAT", "CAUTION": "EAT WITH CAUTION", "AVOID": "NOT RECOMMENDED"}
    return {
        "status": status,
        "title": titles[status],
        "score": score,
        "reasons": r.reasons,
        "personal_risks": r.risks,
        "general_risks": general_risks,
        "benefits": list(food.get("benefits", [])),
        "profile_tags": profile_tags(profile),
        "ingredients": ingredient_flags(food, profile),
        "note": "Preparation may vary between vendors. Confirm ingredients before eating. "
                "This is guidance only, not medical advice.",
    }
