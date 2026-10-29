@echo off
REM ---- Run the Flutter app on a connected Android phone / emulator ----
REM For a REAL phone, set your PC's Wi-Fi IP below (find it with: ipconfig)
set PC_IP=
cd /d "%~dp0"
call flutter pub get
if "%PC_IP%"=="" (
  call flutter run
) else (
  call flutter run --dart-define=API_URL=http://%PC_IP%:8000
)
pause
