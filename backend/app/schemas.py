"""Pydantic request / response models."""
from typing import List, Literal, Optional

from pydantic import BaseModel, Field

Diet = Literal["vegetarian", "vegan", "non_vegetarian", "no_preference"]

ALLERGY_OPTIONS = [
    "peanuts", "tree_nuts", "milk", "egg", "fish",
    "shellfish", "soy", "wheat_gluten", "sesame", "coconut",
]
RESTRICTION_OPTIONS = ["gluten_free", "low_sugar", "low_salt", "low_fat"]
CONDITION_OPTIONS = [
    "diabetes", "hypertension", "heart_disease", "high_cholesterol",
    "kidney_disease", "gastritis", "obesity", "pregnancy",
]


class HealthProfile(BaseModel):
    name: Optional[str] = None
    diet: Diet = "no_preference"
    allergies: List[str] = Field(default_factory=list)
    other_allergy: str = ""
    restrictions: List[str] = Field(default_factory=list)
    other_restriction: str = ""
    medical_conditions: List[str] = Field(default_factory=list)
    other_condition: str = ""


class CreateUserRequest(BaseModel):
    profile: Optional[HealthProfile] = None


class EvaluateRequest(BaseModel):
    user_id: str
    food_key: str
    scan_id: Optional[str] = None  # if given, the scan is corrected to this food
