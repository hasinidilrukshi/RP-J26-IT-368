from fastapi import APIRouter
from typing import List, Optional
from pydantic import BaseModel
from app.ml.travelbuddy_core import generate_travel_plan
from google import genai
import os

router = APIRouter()

# Initialize Gemini Client explicitly
client = genai.Client(api_key="YOUR_GEMINI_API_KEY_HERE")

class RouteRequest(BaseModel):
    climates: List[str]
    cities: List[str]
    start_date: str
    end_date: str
    budget: float
    people: int
    days: int

@router.post("/generate-route")
def generate_route(request: RouteRequest):
    print(f"Received request for {request.people} people for {request.days} days")

    # Map Flutter inputs to the format expected by the NSGA-II engine
    primary_climate = request.climates[0] if request.climates else "Tropical"

    inputs = {
        "days": request.days if request.days > 0 else 3,
        "places_per_day": 2,
        "budget_usd": request.budget,
        "team_members": request.people,
        "preferred_climate": primary_climate,
        "preferred_vibe": "Nature",
        "must_visit": request.cities # Add must visit cities to inputs
    }

    # 1. Run the real NSGA-II Optimization
    try:
        print("Starting NSGA-II processing...")
        optimization_result = generate_travel_plan(inputs)
        print("NSGA-II processing complete.")

        # 2. Call Gemini for Suggested Places and Budget Tips
        try:
            print("Connecting to Gemini API...")

            prompt = f"""
            Act as an expert Sri Lankan travel agent named 'TravelBuddy'.

            A user is taking a trip with these details:
            - Duration: {inputs['days']} days
            - Budget: ${inputs['budget_usd']} for {inputs['team_members']} people
            - Preferred Climate: {inputs['preferred_climate']}

            Based on the above, I need you to generate a JSON response EXACTLY matching this format, with NO markdown formatting, NO backticks, and NO extra text:
            {{
              "suggested_places": [
                {{
                  "name": "Name of Place 1",
                  "description": "Short exciting description matching the preferred climate.",
                  "image": "Use the word 'cool', 'tropical', 'historical', 'sunny', or 'wild' to describe it"
                }},
                {{
                  "name": "Name of Place 2",
                  "description": "Short exciting description matching the preferred climate.",
                  "image": "Use the word 'cool', 'tropical', 'historical', 'sunny', or 'wild' to describe it"
                }}
              ],
              "budget_tips": [
                {{
                  "title": "Transport Tip",
                  "description": "A specific budget tip about transport in Sri Lanka.",
                  "cost": "$X.XX"
                }},
                {{
                  "title": "Food Tip",
                  "description": "A specific budget tip about local food.",
                  "cost": "$X.XX"
                }}
              ]
            }}
            """

            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
            )

            import json
            # Clean the response in case Gemini includes markdown blocks
            clean_json_str = response.text.replace('```json', '').replace('```', '').strip()
            ai_data = json.loads(clean_json_str)

            optimization_result["ai_suggestions"] = ai_data["suggested_places"]
            optimization_result["ai_tips"] = ai_data["budget_tips"]
            print("Gemini processing complete.")

        except Exception as ai_e:
            print(f"Gemini API failed: {ai_e}")
            # Fallbacks if Gemini fails to connect
            optimization_result["ai_suggestions"] = [
                 {
                  "name": "Nuwara Eliya",
                  "description": "Since you love cool climates, visit Little England! Colonial architecture and strawberry farms.",
                  "image": "cool"
                }
            ]
            optimization_result["ai_tips"] = [
                 {
                  "title": "Transport",
                  "description": "Take local trains instead of private cabs.",
                  "cost": "$2.00"
                }
            ]

        return optimization_result

    except Exception as e:
        print(f"Error generating plan: {e}")
        import traceback
        traceback.print_exc()
        return {"status": "error", "message": str(e)}
