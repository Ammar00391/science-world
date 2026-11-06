@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or is not on PATH.
  echo Install Flutter 3.47.0 or newer, then reopen this terminal.
  exit /b 1
)

echo === Flutter version ===
flutter --version
if errorlevel 1 exit /b 1

echo === Flutter doctor ===
flutter doctor -v
rem Continue after doctor so optional IDE components do not block pub get.

echo === Clean old build output ===
flutter clean
if errorlevel 1 exit /b 1

echo === Download dependencies ===
flutter pub get
if errorlevel 1 exit /b 1

echo === Analyze source ===
flutter analyze
if errorlevel 1 exit /b 1

echo === Run tests ===
flutter test
if errorlevel 1 exit /b 1

echo.
echo Project dependency setup and source checks completed.
echo Build APK manually with: flutter build apk --release
endlocal
