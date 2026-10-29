# Ceylon Path SOS – Emergency Severity Assessment & Response

Flutter (Dart) mobile app · Python FastAPI backend · MongoDB · NLP model + Whisper voice.
Fall detection is **not** part of this module.

```
ceylon_path_emergency/
├── lib/                 Flutter app (screens, widgets, services, models)
├── android/             Android project (permissions already added)
├── web/                 Run in Chrome
├── backend/             FastAPI + MongoDB + ML
├── pubspec.yaml         Flutter packages
├── run_backend.bat      double-click: start the backend
├── run_app_chrome.bat   double-click: run the app in Chrome
└── run_app_phone.bat    double-click: run the app on an Android phone
```

> Put this folder somewhere **without spaces** in the path, e.g. `C:\projects\ceylon_path_emergency`.
> Android builds can fail when the path has spaces or brackets.

---

## 1. One-time setup on Windows

### 1.1 Flutter SDK

1. Download the Flutter SDK zip (Windows, Stable): https://docs.flutter.dev/install/archive
2. Extract it to `C:\src` so that `C:\src\flutter\bin\flutter.bat` exists.
3. Add `C:\src\flutter\bin` to **Path** (Edit the system environment variables →
   Environment Variables → User variables → Path → New).
4. If Git complains about "dubious ownership":
   ```powershell
   git config --global --add safe.directory C:/src/flutter
   ```
5. Close and reopen VS Code, then check:
   ```powershell
   flutter --version
   flutter doctor
   ```

### 1.2 Android (only for running on a phone)

1. Install **Android Studio** → open it once → let it install the Android SDK.
2. `flutter doctor --android-licenses` → answer `y` to all.
3. On the phone: Settings → About phone → tap **Build number** 7 times →
   Developer options → **USB debugging** ON → connect with USB → Allow.

### 1.3 Backend

```powershell
cd backend
pip install -r requirements.txt
python train_model.py
```
MongoDB must be running (local `mongodb://localhost:27017`) or set `MONGO_URI` in `backend/.env`.

---

## 2. Run

**Terminal 1 – backend** (or double-click `run_backend.bat`)
```powershell
cd backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
Check: http://localhost:8000/docs

**Terminal 2 – app** (in the project folder)
```powershell
flutter pub get
flutter run -d chrome          # Chrome
flutter run                    # Android emulator / phone
```

### Backend address (automatic)

| Running on | Address used |
|---|---|
| Chrome | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Real Android phone | your PC's Wi-Fi IP – see below |

For a **real phone** (phone and PC on the same Wi-Fi), either:
- run `flutter run --dart-define=API_URL=http://192.168.1.5:8000` (use your IP from `ipconfig`), or
- set `manualServerUrl` in `lib/services/emergency_api_service.dart`, or
- put your IP in `run_app_phone.bat` (`set PC_IP=192.168.1.5`).

If Windows Firewall asks, allow Python on private networks.

### What works where

| Feature | Android | Chrome |
|---|---|---|
| Typed message → NLP assessment | ✅ | ✅ |
| Voice SOS (Whisper) | ✅ | ❌ (shows a message) |
| GPS location | ✅ | ✅ |
| Call buttons | ✅ | ❌ |
| Listen to instructions (TTS) | ✅ | ✅ |

If the backend can't be reached, the app still works with an **offline estimate**.

### Build an APK to share
```powershell
flutter build apk --release --dart-define=API_URL=http://192.168.1.5:8000
```
APK: `build\app\outputs\flutter-apk\app-release.apk`

---

## 3. App flow (no forms in an emergency)

```
Open app ──► GPS starts automatically (chip shows "Location ready ±8 m")
   │
   ├─ 🎤 tap SPEAK, say what happened (any language), tap again → sent
   ├─ 👆 tap one quick button ("Someone drowning", "Bad injury" …) → sent
   └─ ⌨️ type a few words → Send
                │
                ▼   POST /api/sos  (text or voice + GPS + saved profile)
        Whisper → NLP model → red-flag safety rules → nearest services
                │
                ▼
   Result screen: severity · detected type · BIG "CALL 1990" button ·
   who should respond (nearest hospital, police, lifeguards …) ·
   GPS + "near Ella (0.5 km)" · Map · Share location by SMS ·
   what to do now (read aloud) · OPTIONAL quick yes/no questions
```

- Name / phone are **optional** and saved **once** in *My details* – never asked during an emergency.
- If a better GPS fix arrives after the SOS, the app sends it automatically.
- Optional answers ("Breathing normally? No") re-assess the emergency; they can only **raise** severity.
- No server? The phone estimates severity from red-flag words and still shows the hotlines to call.

### API used by the app

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/sos` | multipart: `message` and/or `audio` + `latitude`, `longitude`, `location_accuracy`, optional profile → `{report, services}` |
| PATCH | `/api/emergencies/{id}/details` | optional answers, landmark (`address`), better GPS → re-assessed `{report, services}` |
| GET | `/api/emergencies?device_id=…` | "My reports" on this phone |
| GET | `/api/emergencies/{id}` | live status (admin dashboard updates) |
| POST | `/api/emergencies/{id}/dispatch` | request a responder |
| PATCH | `/api/emergencies/{id}/status` | e.g. `resolved` ("I am safe now") |

## 4. ML pipeline

```
🎤 voice (any language) → Whisper (translate → English) ─┐
⌨️ typed message ─────────────────────────────────────────┴→ NLP model (TF-IDF + Logistic Regression)
     → severity · emergency type · authorities → red-flag phrases in the message + optional answers (can only raise) → response
```

| Model | Predicts | Score (unseen sentence templates) |
|---|---|---|
| Severity | Low / Medium / High / Critical | macro-F1 0.76 |
| Emergency type | Medical / Wildlife / Crime / Lost-Rescue / Ocean Safety | macro-F1 0.79 |
| Authorities | 1990, Police, Lifeguards, Coast Guard … | micro-F1 0.73 |

Full training report: `backend/models/training_report.txt` (created by `train_model.py`).

## 5. Common errors

| Error | Fix |
|---|---|
| `flutter` not recognized | Add `C:\src\flutter\bin` to Path, restart VS Code |
| "Select an app to open 'flutter'" | A stray file `C:\Windows\System32\flutter` – rename/delete it |
| `dubious ownership` | `git config --global --add safe.directory C:/src/flutter` |
| `minSdk` error | Already set to 23 in `android/app/build.gradle.kts` |
| App shows "Offline estimate" | Backend not running or wrong address (see table above) |
| `metadata_errors` from `/api/transcribe` | `pip install -U faster-whisper` and restart the backend |
| Package version conflict on `flutter pub get` | `flutter pub upgrade --major-versions` |
