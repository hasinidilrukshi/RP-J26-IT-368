## C2 – AI-Based Tourist Emergency Severity Assessment and Response

**Member:** Sewwandi K.L. (IT23365100)  
**Branch:** [`feature/tourist-emergency-response`](https://github.com/hasinidilrukshi/RP-J26-IT-368/tree/feature/tourist-emergency-response)  
**Stack:** Flutter (Dart) · FastAPI (Python) · scikit-learn · faster-whisper · MongoDB Atlas

---

### 1. Problem and research gap

Tourists in Sri Lanka can face medical emergencies, accidents, wildlife incidents, getting lost or ocean dangers, but they often do not know which Sri Lankan authority to contact for each situation. They lose time finding the right service and explaining what happened, often with a language barrier. Existing travel and SOS apps only offer a panic button or one fixed number. None of them automatically assess the severity of a free-text or voice report and match it to the correct Sri Lankan response service.

**Novelty:** AI-based emergency-to-response matching:
`Tourist emergency → AI assessment → type + severity → location → Sri Lankan response service → contact / alert`

---

### 2. Approach and model(s)

| Part | Method |
|---|---|
| Voice input | **faster-whisper** (`base`, CPU, int8) with `task="translate"`: any spoken language → English text |
| Text features | **TF-IDF**: word 1–2 grams + character 3–5 grams (`FeatureUnion`, `sublinear_tf`) |
| Severity model | **Logistic Regression** (`C=10`, `class_weight="balanced"`), 4 classes: Low / Medium / High / Critical |
| Emergency type model | **Logistic Regression**, 5 classes: Medical, Wildlife, Crime, Lost/Rescue, Ocean Safety |
| Authority model | **One-vs-Rest Logistic Regression** (multi-label): 9 Sri Lankan authorities, threshold 0.5, at least one always returned |
| Safety rules | Form answers (not breathing, unconscious, heavy bleeding, in danger, pain ≥ 8, ≥ 3 people) can only **raise** the severity, never lower it |
| Response mapping | Predicted authorities → service types; nearest hospitals and services by **haversine distance** with ETA |
| Fallback | Keyword rules if the model file is missing, and an offline estimate in the app if the backend cannot be reached |

**Flow:** report (text / voice) → Whisper → 3 NLP models → safety rules → recommended services + nearest help → saved to MongoDB → shown on the admin dashboard → tourist tracks the status.

---

### 3. Dataset(s) and source

| Dataset | Size | Source |
|---|---|---|
| `backend/data/dataset.csv` | 1,000 messages · 209 sentence templates | [Describe how it was created, e.g. self-created tourist emergency scenarios for Sri Lankan locations] |
| Columns | `user_message`, `emergency_type`, `severity`, `location`, `authority` (multiple values separated by `;`) | |
| Class balance | Type: 200 rows each · Severity: Low 197, Medium 204, High 331, Critical 268 | |
| Response services | 16 seeded services (1990, 119, Tourist Police, Wildlife 1992, Coast Guard 106, DMC 117, hospitals…) | Sri Lankan national hotlines |

---

### 4. Results so far

Evaluated with **GroupKFold (5-fold, grouped by sentence template)**. A random split gave about 100% accuracy because the same template appeared in both train and test (data leakage), so grouped cross-validation is used to test on unseen sentences.

| Model | Metric | Score |
|---|---|---|
| Severity | Accuracy | **75.1%** |
| Severity | Macro-F1 | **0.76** |
| Emergency type | Macro-F1 | **0.79** |
| Authorities | Micro-F1 / Macro-F1 / Exact match | **0.73** / 0.63 / 0.57 |
| Safety | Under-rated / Over-rated severity | **9.2%** / 15.7% |

Most severity errors are between **High ↔ Critical**. The model errs more often on the safer side (over-rating).

**Example:** *"I fell while hiking and cannot walk. I'm in a remote hiking area."* → **Medical · Critical (86% confidence) · 1990 Suwa Seriya Ambulance + Local Police**

Full report: `backend/models/training_report.txt`

**Screenshots:**

| Home | Report (voice / text) | AI assessment | Status |
|---|---|---|---|
| ![Home](docs/home.png) | ![Report](docs/report.png) | ![Result](docs/result.png) | ![Status](docs/status.png) |

---

### 5. Status at PP1

| Status | Items |
|---|---|
| ✅ **Done** | Maroon UI (Flutter) · emergency dataset (1,000) · 3 NLP models trained and evaluated · Whisper voice input · FastAPI backend and REST API · MongoDB Atlas · nearby services with ETA · one-tap call · live status tracking · offline fallback |
| 🔄 **In progress** | Explainable results (why a severity or service was chosen) · location-aware response mapping (remote / hiking / beach areas) |
| 📅 **Planned** | Sri Lanka response knowledge base (verified hotlines and step-by-step guides) · dataset expansion (accidents, Sinhala / Tamil) · user feedback testing · integration with the admin dashboard |

---

### 6. API endpoints and MongoDB collections

Base URL: `http://<host>:8000` · Swagger docs: `/docs`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/health` | Server and database status |
| GET | `/api/model/info` | Whether the ML model is loaded, training date and metrics |
| POST | `/api/transcribe` | Upload a voice note → Whisper → English text + quick AI preview |
| GET | `/api/voice/{audio_id}` | Play the original voice note (admin) |
| POST | `/api/assess` | Run the AI assessment without saving (testing) |
| POST | `/api/emergencies` | Create an emergency: assess and save |
| GET | `/api/emergencies` | List emergencies (filters: `phone`, `status`, `limit`) |
| GET | `/api/emergencies/{id}` | Get one emergency |
| POST | `/api/emergencies/{id}/dispatch` | Assign a response service |
| PATCH | `/api/emergencies/{id}/status` | Update status: `submitted → assessed → dispatched → on_the_way → resolved` |
| GET | `/api/services/nearby` | Nearest recommended services (`lat`, `lng`, `services`) |

**Database:** `ceylonpath` (MongoDB Atlas)

| Collection | Stores |
|---|---|
| `emergencies` | Tourist report, form answers, location, `assessment` (severity, score, type, authorities, recommendations, method), `voice`, `status`, `assigned_service`, timestamps |
| `voice_notes` | Audio file path, English text, original text, detected language, duration |
| `services` | Sri Lankan response services: name, type, phone, address, coordinates, default ETA |

---

### 7. How to run

**Backend**

```bash
cd backend
python -m venv venv
venv\Scripts\activate            # Windows  (macOS/Linux: source venv/bin/activate)
pip install -r requirements.txt
copy .env.example .env           # then add your own MongoDB Atlas URI
python train_model.py            # first time only → models/severity_model.joblib
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

```
Open `http://localhost:8000/docs`. `/api/model/info` should return `"loaded": true`.
App
```bash
flutter pub get
flutter run -d chrome                                          # web
flutter run                                                    # Android emulator
flutter run --dart-define=API\_URL=http://<PC-IP>:8000          # real phone (same Wi-Fi)
```
On Windows you can also use `run\_backend.bat`, `run\_app\_chrome.bat` and `run\_app\_phone.bat`.
> ⚠️ Never commit `backend/.env` (it contains database credentials). Only `.env.example` is in the repo.
---
8. Limitations and next steps until PP2
Limitations
1.The dataset is template-based (1,000 rows), so real tourist messages may be phrased differently.
2.Severity accuracy is 75%, and the most confusion is between High and Critical.
3.Very short messages (e.g. "help") give low-confidence predictions.
4.Voice recognition is weaker for Sinhala and Tamil.
5.The authority is predicted from the text, and location is only used to find the nearest services.
6.There is no authentication on the API yet, and hospital phone numbers are placeholders.
---

Next steps until PP2
1.Location-aware response mapping: use GPS and the area type (remote, hiking, beach) to choose the rescue service.
2.Explainable AI results: show the key words and reasons behind the severity and the chosen service.
3.Sri Lanka response knowledge base: verified hotlines and step-by-step guides for each situation.
4.Dataset expansion: more scenarios (road accidents, fire, natural disasters) and Sinhala / Tamil messages, then retrain.
5.User feedback: test the prototype with tourists and guides, and refine the UI.
6.Integration: connect with the team's admin dashboard and add authentication.



