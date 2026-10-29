"""
Emergency assessment = NLP model on the tourist's message
                     + safety rules on the yes/no answers from the form.

models/severity_model.joblib is produced by train_model.py. If it is missing
or fails, a keyword/rule fallback is used so the app keeps working.
"""
import logging
import os

log = logging.getLogger("severity_model")

MODEL_PATH = os.getenv(
    "MODEL_PATH",
    os.path.join(os.path.dirname(__file__), "models", "severity_model.joblib"),
)
SEVERITIES = ["Low", "Medium", "High", "Critical"]

# dataset emergency_type  <->  app type id
TYPE_TO_ID = {
    "Medical": "medical", "Wildlife": "wildlife", "Crime": "crime",
    "Lost/Rescue": "lost", "Ocean Safety": "ocean",
}
ID_TO_TYPE = {v: k for k, v in TYPE_TO_ID.items()}
ID_TO_TYPE["other"] = "Other"

# dataset authority name  ->  response service type used by the app
AUTHORITY_TO_SERVICE = {
    "1990 Suwa Seriya Ambulance": "ambulance",
    "Nearest Hospital": "hospital",
    "Local Police": "police",
    "Tourist Police": "tourist_police",
    "Department of Wildlife Conservation": "wildlife",
    "Forest Department": "forest",
    "Lifeguards": "lifeguard",
    "Sri Lanka Navy / Coast Guard": "coast_guard",
    "Disaster Management Centre": "disaster",
}


def _load():
    if not os.path.exists(MODEL_PATH):
        log.warning("No model at %s – run train_model.py. Using rules.", MODEL_PATH)
        return None
    try:
        import joblib
        b = joblib.load(MODEL_PATH)
        log.warning("Loaded NLP model (trained %s, metrics %s)",
                    b.get("trained_at"), b.get("metrics"))
        return b
    except Exception as e:  # noqa: BLE001
        log.error("Could not load model (%s) – using rules", e)
        return None


BUNDLE = _load()


def model_info() -> dict:
    if not BUNDLE:
        return {"loaded": False}
    return {"loaded": True, "trained_at": BUNDLE.get("trained_at"),
            "rows": BUNDLE.get("rows"), "metrics": BUNDLE.get("metrics"),
            "sklearn_version": BUNDLE.get("sklearn_version")}


# --------------------------------------------------------------------------- #
# ML prediction
# --------------------------------------------------------------------------- #
def _ml(text: str):
    if BUNDLE is None or len(text.strip()) < 3:
        return None
    try:
        X = [text.lower().strip()]

        sev = BUNDLE["severity"]
        probs = sev.predict_proba(X)[0]
        classes = list(sev.classes_)
        severity = classes[probs.argmax()]
        level = sum(p * SEVERITIES.index(c) for p, c in zip(probs, classes))
        score = round(level / 3 * 100)
        confidence = round(float(probs.max()) * 100)

        tm = BUNDLE["emergency_type"]
        tprobs = tm.predict_proba(X)[0]
        etype = tm.classes_[tprobs.argmax()]
        type_conf = round(float(tprobs.max()) * 100)

        am = BUNDLE["authority"]
        aprobs = am.predict_proba(X)[0]
        labels = BUNDLE["authority_labels"]
        authorities = [labels[i] for i, p in enumerate(aprobs) if p >= 0.5]
        if not authorities:  # always suggest at least one
            authorities = [labels[int(aprobs.argmax())]]
        authorities.sort(key=lambda a: -aprobs[labels.index(a)])

        return {"severity": severity, "score": int(score), "confidence": confidence,
                "type": etype, "type_confidence": type_conf,
                "authorities": authorities}
    except Exception as e:  # noqa: BLE001
        log.error("ML prediction failed (%s) – using rules", e)
        return None


# --------------------------------------------------------------------------- #
# Rule fallback (no model)
# --------------------------------------------------------------------------- #
KEYWORDS = {
    "Critical": ["not breathing", "unconscious", "collapsed", "drowning", "knife",
                 "gun", "heart attack", "chest pain", "kidnap", "missing child",
                 "swept away", "attacked"],
    "High": ["bleeding", "broken", "fracture", "elephant", "snake bite", "bitten",
             "stuck", "trapped", "current", "robbed", "assault", "fell", "dark"],
    "Medium": ["snake", "sting", "stolen", "pain", "lost", "fever", "scam", "monkey"],
}
TYPE_WORDS = {
    "Medical": ["breath", "pain", "collapsed", "fever", "heart", "sick", "injur"],
    "Wildlife": ["elephant", "snake", "leopard", "monkey", "crocodile", "bear", "jellyfish", "dog"],
    "Crime": ["stole", "knife", "rob", "scam", "assault", "thief", "break in", "harass"],
    "Lost/Rescue": ["lost", "missing", "can't find", "stuck", "separated", "trail"],
    "Ocean Safety": ["beach", "sea", "wave", "current", "swim", "boat", "drown"],
}
TYPE_AUTHORITIES = {
    "Medical": ["1990 Suwa Seriya Ambulance", "Nearest Hospital"],
    "Wildlife": ["Department of Wildlife Conservation"],
    "Crime": ["Local Police", "Tourist Police"],
    "Lost/Rescue": ["Local Police"],
    "Ocean Safety": ["Lifeguards", "Sri Lanka Navy / Coast Guard"],
    "Other": ["Tourist Police"],
}


def _rules(text: str, type_id: str):
    t = text.lower()
    severity = "Low"
    for level in ("Critical", "High", "Medium"):
        if any(k in t for k in KEYWORDS[level]):
            severity = level
            break
    etype = ID_TO_TYPE.get(type_id, "Other")
    if etype == "Other":
        best = max(TYPE_WORDS, key=lambda k: sum(w in t for w in TYPE_WORDS[k]))
        if any(w in t for w in TYPE_WORDS[best]):
            etype = best
    score = {"Low": 15, "Medium": 40, "High": 65, "Critical": 90}[severity]
    return {"severity": severity, "score": score, "confidence": None,
            "type": etype, "type_confidence": None,
            "authorities": TYPE_AUTHORITIES.get(etype, ["Tourist Police"])}


# --------------------------------------------------------------------------- #
# Public function used by main.py
# --------------------------------------------------------------------------- #
def assess(r: dict) -> dict:
    text = r.get("description") or ""
    selected = r.get("emergency_type", "other")

    res = _ml(text)
    method = "ml" if res else "rules"
    if not res:
        res = _rules(text, selected)

    severity, score = res["severity"], res["score"]
    authorities = list(res["authorities"])
    adjustments = []

    # ---- safety rules from the form answers (can only RAISE severity) ----
    def raise_to(level, min_score, why):
        nonlocal severity, score
        if SEVERITIES.index(level) > SEVERITIES.index(severity):
            severity = level
            adjustments.append(why)
        score = max(score, min_score)

    if not r.get("is_breathing_normally", True):
        raise_to("Critical", 85, "not breathing normally")
    if not r.get("is_conscious", True):
        raise_to("Critical", 80, "unconscious")
    if r.get("has_heavy_bleeding", False):
        raise_to("High", 65, "heavy bleeding")
    if r.get("is_in_danger", False):
        raise_to("High", 60, "still in danger")
    if int(r.get("pain_level", 0)) >= 8:
        raise_to("High", 55, "severe pain")
    if int(r.get("people_affected", 1)) >= 3:
        raise_to("High", 55, "several people affected")

    if (not r.get("is_breathing_normally", True) or not r.get("is_conscious", True)
            or r.get("has_heavy_bleeding", False)):
        if "1990 Suwa Seriya Ambulance" not in authorities:
            authorities.insert(0, "1990 Suwa Seriya Ambulance")

    services = []
    for a in authorities:
        s = AUTHORITY_TO_SERVICE.get(a)
        if s and s not in services:
            services.append(s)

    # ---- recommendations ----
    recs = []
    if not r.get("is_breathing_normally", True):
        recs.append("Keep the airway open and start CPR if you are trained.")
    if r.get("has_heavy_bleeding", False):
        recs.append("Press firmly on the wound with a clean cloth.")
    if not r.get("is_conscious", True):
        recs.append("Place the person on their side (recovery position).")
    if r.get("is_in_danger", False):
        recs.append("Move to a safe place if you can do so safely.")
    recs += {
        "Wildlife": ["Keep a safe distance from the animal and do not provoke it."],
        "Ocean Safety": ["Do not enter the water to rescue someone unless trained; throw something that floats."],
        "Crime": ["Go to a busy, well-lit place and keep your passport copy safe."],
        "Lost/Rescue": ["Stay where you are, keep warm and save phone battery."],
        "Medical": ["Do not give food or drink to a seriously injured person."],
    }.get(res["type"], [])
    recs.append("Keep your phone on and the line free so responders can call you.")

    type_label = res["type"]
    summary = f"{severity} severity {type_label.lower()} emergency."
    if res["confidence"] is not None:
        summary += f" AI confidence {res['confidence']}%."
    if adjustments:
        summary += " Raised because: " + ", ".join(adjustments) + "."

    return {
        "severity": severity,
        "score": int(min(100, score)),
        "summary": summary,
        "recommendations": recs,
        "recommended_services": services,
        "authorities": authorities,
        "predicted_type": TYPE_TO_ID.get(type_label, "other"),
        "predicted_type_label": type_label,
        "type_confidence": res["type_confidence"],
        "confidence": res["confidence"],
        "method": method,
        "ml_severity": res["severity"] if method == "ml" else None,
        "adjustments": adjustments,
    }
