"""
Train the TravelBuddy emergency NLP models from data/dataset.csv

Dataset columns:
    user_message    – what the tourist typed            (input)
    emergency_type  – Medical / Wildlife / Crime / Lost/Rescue / Ocean Safety
    severity        – Low / Medium / High / Critical
    location        – (not used by the model)
    authority       – one or more authorities separated by ';'

Three models are trained on the message text:
    1. severity        (4 classes)
    2. emergency_type  (5 classes)
    3. authorities     (multi-label: can predict more than one)

Run:
    python train_model.py                     # uses data/dataset.csv
    python train_model.py path/to/file.csv

Output: models/severity_model.joblib
"""
import os
import re
import sys
import warnings
from datetime import datetime

import joblib
import numpy as np
import pandas as pd
import sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, f1_score
from sklearn.model_selection import GroupKFold, cross_val_predict
from sklearn.multiclass import OneVsRestClassifier
from sklearn.pipeline import FeatureUnion, Pipeline
from sklearn.preprocessing import MultiLabelBinarizer

warnings.filterwarnings("ignore")

SEVERITIES = ["Low", "Medium", "High", "Critical"]
FILLER = {"sos", "pls", "please", "help", "urgent", "asap", "hi", "hello",
          "hey", "thanks", "thank", "you", "now", "quick", "omg", "plz"}


def clean(text: str) -> str:
    return str(text).lower().strip()


def text_features():
    # word n-grams catch meaning ("not breathing"), char n-grams catch
    # typos and place-name variants ("Polonnaruuwa", "pls", "theres")
    return FeatureUnion([
        ("word", TfidfVectorizer(ngram_range=(1, 2), sublinear_tf=True)),
        ("char", TfidfVectorizer(analyzer="char_wb", ngram_range=(3, 5),
                                 sublinear_tf=True)),
    ])


def classifier():
    return LogisticRegression(C=10, max_iter=3000, class_weight="balanced")


def template_groups(df: pd.DataFrame) -> pd.Series:
    """Group messages that come from the same sentence template (only the
    place name changes) so cross-validation never tests on a sentence the
    model has already seen with a different town. Without this the score
    looks like 100 %, which is misleading."""
    locs = {w.lower() for l in df["location"].unique()
            for w in re.findall(r"[A-Za-z]+", str(l))}

    def key(s):
        words = [t for t in re.findall(r"[a-z]+", s.lower())
                 if t not in FILLER and t not in locs]
        return " ".join(words[:5])

    return df["user_message"].apply(key)


def split_authorities(s: str) -> list:
    return [a.strip() for a in str(s).split(";") if a.strip()]


def main(csv_path: str):
    df = pd.read_csv(csv_path).dropna(subset=["user_message", "severity"])
    X = df["user_message"].map(clean)
    groups = template_groups(df)
    cv = GroupKFold(n_splits=5)
    print(f"Rows: {len(df)} | sentence templates: {groups.nunique()}\n")

    # ---------------- 1. severity ----------------
    sev_model = Pipeline([("features", text_features()), ("clf", classifier())])
    pred = cross_val_predict(sev_model, X, df["severity"], groups=groups, cv=cv)
    print("=== SEVERITY (5-fold, unseen templates) ===")
    print(classification_report(df["severity"], pred, labels=SEVERITIES, digits=3))
    cm = pd.DataFrame(confusion_matrix(df["severity"], pred, labels=SEVERITIES),
                      index=[f"true {s}" for s in SEVERITIES], columns=SEVERITIES)
    print(cm, "\n")
    lvl = {s: i for i, s in enumerate(SEVERITIES)}
    diff = np.array([lvl[p] - lvl[t] for t, p in zip(df["severity"], pred)])
    print(f"Under-rated: {(diff < 0).mean():.1%} | Over-rated: {(diff > 0).mean():.1%}\n")
    sev_f1 = f1_score(df["severity"], pred, average="macro")

    # ---------------- 2. emergency type ----------------
    type_model = Pipeline([("features", text_features()), ("clf", classifier())])
    pred = cross_val_predict(type_model, X, df["emergency_type"], groups=groups, cv=cv)
    print("=== EMERGENCY TYPE ===")
    print(classification_report(df["emergency_type"], pred, digits=3))
    type_f1 = f1_score(df["emergency_type"], pred, average="macro")

    # ---------------- 3. authorities (multi-label) ----------------
    mlb = MultiLabelBinarizer()
    Y = mlb.fit_transform(df["authority"].map(split_authorities))
    auth_model = Pipeline([("features", text_features()),
                           ("clf", OneVsRestClassifier(classifier()))])
    pred = cross_val_predict(auth_model, X, Y, groups=groups, cv=cv)
    auth_micro = f1_score(Y, pred, average="micro")
    print("=== AUTHORITIES ===")
    print(f"micro-F1 {auth_micro:.3f} | macro-F1 {f1_score(Y, pred, average='macro'):.3f}"
          f" | exact match {(pred == Y).all(axis=1).mean():.3f}\n")

    # ---------------- fit on all data & save ----------------
    sev_model.fit(X, df["severity"])
    type_model.fit(X, df["emergency_type"])
    auth_model.fit(X, Y)

    bundle = {
        "severity": sev_model,
        "emergency_type": type_model,
        "authority": auth_model,
        "authority_labels": list(mlb.classes_),
        "metrics": {"severity_macro_f1": round(sev_f1, 3),
                    "type_macro_f1": round(type_f1, 3),
                    "authority_micro_f1": round(auth_micro, 3)},
        "trained_at": datetime.now().isoformat(timespec="seconds"),
        "sklearn_version": sklearn.__version__,
        "rows": int(len(df)),
    }
    os.makedirs("models", exist_ok=True)
    joblib.dump(bundle, "models/severity_model.joblib")
    print("Saved -> models/severity_model.joblib")
    print("Metrics:", bundle["metrics"])


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data/dataset.csv")
