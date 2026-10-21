from typing import Optional

from fastapi import APIRouter, HTTPException

from ..schemas import (ALLERGY_OPTIONS, CONDITION_OPTIONS, RESTRICTION_OPTIONS,
                       CreateUserRequest, HealthProfile)
from ..services import food_repository as repo

router = APIRouter(prefix="/api/users", tags=["users"])


@router.post("")
def create_user(body: Optional[CreateUserRequest] = None):
    """Called once on first app launch; the app stores the returned user_id."""
    profile = body.profile.model_dump() if body and body.profile else None
    return repo.create_user(profile)


@router.get("/profile-options")
def profile_options():
    return {"allergies": ALLERGY_OPTIONS, "restrictions": RESTRICTION_OPTIONS,
            "medical_conditions": CONDITION_OPTIONS}


@router.get("/{user_id}")
def get_user(user_id: str):
    user = repo.get_user(user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return user


@router.put("/{user_id}/profile")
def save_profile(user_id: str, profile: HealthProfile):
    return repo.update_profile(user_id, profile.model_dump())
