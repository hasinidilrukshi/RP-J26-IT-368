# C4 - Smart Sri Lankan Street Food Safety & Personalization Engine

**Owner:** Serasinghe S. S. (IT23372412)  
**Component:** C4 - Smart Sri Lankan Street Food Safety & Personalization Engine  
**Part of:** CeylonPath (J26-IT-368)  
**Status date:** Progress Presentation 1 (PP1, October 2026)  

---

## 1. Problem and Research Gap
Foreign tourists in Sri Lanka face health risks from street food because ingredient, allergen and nutrition information is rarely available, and vendors often can't explain it. Existing food apps mainly recognise Western dishes and give generic nutrition. None combine Sri Lankan food recognition with personalised safety checks based on a tourist's allergies, diet and medical conditions.

## 2. Approach and Model(s)
* YOLOv8n object detection (transfer learning from COCO) identifies the dish from a photo.
* The dish is looked up in a MongoDB knowledge base of ingredients, allergens and nutrition.
* A rule-based safety engine matches the dish against the tourist's health profile and returns Safe / Caution / Avoid, a 0–100 score, reasons, benefits and risks.


Flutter App ──photo──► FastAPI ──► YOLOv8 (best.pt) ──► MongoDB (foods) ──► Safety Engine ──► Verdict


## 3. Dataset(s) and Source
* **Image dataset:** Self-built and annotated in Roboflow, with 40 Sri Lankan street food classes. The validation set has 320 images and 1,335 labelled items.
* **Food knowledge base:** A self-compiled Excel dataset of the same 40 dishes (ingredients, veg/vegan status, allergens, nutrition per 100 g, benefits, health concerns), imported into MongoDB.

## 4. Results So Far
| Metric | Value |
| :--- | :--- |
| Precision | 66.7% |
| Recall | 62.5% |
| mAP@50 | 66.9% |
| mAP@50-95 | 44.4% |
| Inference | ≈3.6 ms/image (T4 GPU) |
| Model size | 6.5 MB |

## 5. Status at PP1
| Item | Status |
| :--- | :--- |
| Figma UI and user feedback | ✅ Done[cite: 1] |
| Dataset (40 classes) and model training | ✅ Done[cite: 1] |
| Food knowledge base | ✅ Done[cite: 1] |
| FastAPI backend and REST API | ✅ Done[cite: 1] |
| Safety engine | ✅ Done[cite: 1] |
| MongoDB Atlas and Flutter app | ✅ Done[cite: 1] |
| Dataset expansion | 🔄 In progress[cite: 1] |
| Integration with the tourist app home page | 🔄 In progress[cite: 1] |
| GitHub documentation | 🔄 In progress[cite: 1] |
| Sodium, fibre, GI and spice parameters | 📅 Planned[cite: 1] |
| 60–80 dishes with cited sources | 📅 Planned[cite: 1] |
| Deployment, APK, SUS user testing | 📅 Planned[cite: 1] |

## 6. API Endpoints and MongoDB Collections
| Method | Endpoint | Purpose |
| :--- | :--- | :--- |
| POST | `/api/users` | Create user[cite: 1] |
| PUT | `/api/users/{id}/profile` | Save health profile[cite: 1] |
| POST | `/api/users/vectorize` | Profile → JSON and binary vector[cite: 1] |
| POST | `/api/food/analyze` | Photo → dish + safety verdict[cite: 1] |
| POST | `/api/food/evaluate` | Re-check a chosen dish[cite: 1] |
| GET | `/api/foods` | List dishes[cite: 1] |
| GET | `/api/scans?user_id=` | Scan history[cite: 1] |
| GET | `/api/health` | Server, DB and model status[cite: 1] |

### MongoDB Database: `food_safety_ai`[cite: 1]
* **`foods`**: The 40 dishes with ingredients, allergens and nutrition[cite: 1]
* **`users`**: Health profile and profile vectors[cite: 1]
* **`scans`**: Photo, detection, verdict and timestamp[cite: 1]

## 7. How to Run
```bash
# Backend
cd backend
pip install -r requirements.txt
copy .env.example .env        # add your MONGO_URI (never commit .env)
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Frontend
cd frontend
flutter pub get
flutter run -d chrome
---
To check it's working, open `http://localhost:8000/api/health` (should show `"foods": 40` and `"model_loaded": true`), or the API docs at `http://localhost:8000/docs`.

## 8. Limitations and Next Steps Until PP2
### Limitations
* Moderate accuracy (66.9% mAP50). Similar-looking dishes get confused.
* Recipes are fixed ("typical") recipes, but vendors vary them.
* The safety rules haven't been validated by a dietitian yet.
* Recognition runs on the server, so the app needs internet.
* Not yet tested on real street-stall photos or with tourists.

### Next Steps
* Expand and balance the dataset, compare YOLOv8n/s/YOLO11, and test on real-world photos.
* Add sodium, fibre, glycaemic index and spice level, and grow the database to 60–80 cited dishes.
