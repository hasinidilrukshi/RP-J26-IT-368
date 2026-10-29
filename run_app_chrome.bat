@echo off
REM ---- Run the Flutter app in Chrome (no phone needed) ----
cd /d "%~dp0"
call flutter pub get
call flutter run -d chrome
pause
