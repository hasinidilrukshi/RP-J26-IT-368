@echo off
REM ---- Ceylon Path backend (FastAPI + MongoDB + ML) ----
cd /d "%~dp0backend"
if not exist models\severity_model.joblib (
  echo Training the ML model for the first time...
  python train_model.py
)
echo.
echo Backend: http://localhost:8000/docs
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause
