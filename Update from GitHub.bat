@echo off
cd /d "%~dp0"
git pull --ff-only origin main
if errorlevel 1 (
  echo.
  echo [ERROR] Pull failed. Do not delete your local changes.
) else (
  echo.
  echo [OK] Bloom RNG updated from GitHub.
)
pause
