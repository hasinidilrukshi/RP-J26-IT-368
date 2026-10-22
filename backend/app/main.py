from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import route_api, hazard_api # Import the new API route

app = FastAPI(title="Travel Buddy API")

# Setup CORS for Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to your app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Welcome to Travel Buddy API"}

# Include the APIs
app.include_router(route_api.router, prefix="/api", tags=["Routes"])
app.include_router(hazard_api.router, prefix="/api", tags=["Hazards"])
