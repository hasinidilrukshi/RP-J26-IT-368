from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from motor.motor_asyncio import AsyncIOMotorClient
import datetime
import os

router = APIRouter()

# MongoDB Connection
MONGO_URI = "mongodb+srv://ceylonpath:CeylonPath2026%23@cluster0.fxyrh.mongodb.net/ceylonpath?retryWrites=true&w=majority"
client = AsyncIOMotorClient(MONGO_URI)
db = client.ceylonpath
hazards_collection = db.hazards

class Hazard(BaseModel):
    title: str
    location: str
    severity: str
    description: str

@router.post("/hazards")
async def create_hazard(hazard: Hazard):
    hazard_dict = hazard.dict()
    hazard_dict["date"] = datetime.datetime.now().strftime("%b %d, %Y")

    try:
        result = await hazards_collection.insert_one(hazard_dict)
        if result.inserted_id:
            return {"status": "success", "message": "Hazard added successfully", "id": str(result.inserted_id)}
        raise HTTPException(status_code=500, detail="Failed to add hazard")
    except Exception as e:
        print(f"MongoDB Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/hazards")
async def get_hazards():
    try:
        hazards = []
        cursor = hazards_collection.find().sort("_id", -1) # newest first
        async for document in cursor:
            document["id"] = str(document["_id"])
            del document["_id"]
            hazards.append(document)
        return hazards
    except Exception as e:
        print(f"MongoDB Error: {e}")
        return []
