@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

echo.
echo ============================================================
echo   Bloom RNG safe updater
echo ============================================================

set "RECOVERY_DIR=%~dp0.recovery"
if not exist "%RECOVERY_DIR%" mkdir "%RECOVERY_DIR%" >nul 2>&1
for /f "tokens=1-4 delims=/-. " %%a in ("%date%") do set "DATESTAMP=%%d%%b%%c"
for /f "tokens=1-3 delims=:,. " %%a in ("%time%") do set "TIMESTAMP=%%a%%b%%c"
set "TIMESTAMP=%TIMESTAMP: =0%"
if exist "src\StarterGui\BloomUI.model.json" (
  copy /Y "src\StarterGui\BloomUI.model.json" "%RECOVERY_DIR%\BloomUI.model.before-update.%DATESTAMP%-%TIMESTAMP%.json" >nul
  echo [BACKUP] BloomUI.model.json copied to .recovery before Git operations.
)

set "HAD_CHANGES=0"
for /f "delims=" %%A in ('git status --porcelain') do set "HAD_CHANGES=1"

if "%HAD_CHANGES%"=="1" (
  echo [INFO] Local changes detected. Saving them temporarily...
  git stash push -u -m "Bloom RNG updater temporary stash"
  if errorlevel 1 (
    echo.
    echo [ERROR] Could not stash local changes. Nothing was deleted.
    pause
    exit /b 1
  )
)

echo [INFO] Pulling origin/main...
git pull --ff-only origin main
if errorlevel 1 (
  echo.
  echo [ERROR] Pull failed.
  if "%HAD_CHANGES%"=="1" (
    echo [INFO] Restoring your local changes...
    git stash apply stash@{0}
    if not errorlevel 1 git stash drop stash@{0}
  )
  echo Your local work was not intentionally deleted.
  pause
  exit /b 1
)

if "%HAD_CHANGES%"=="1" (
  echo [INFO] Restoring your local changes...
  git stash apply stash@{0}
  if errorlevel 1 (
    echo.
    echo [WARNING] Update succeeded, but restoring local changes caused a conflict.
    echo Your stash is still preserved as stash@{0}.
    echo Do NOT delete it until conflicts are resolved.
    pause
    exit /b 1
  )
  git stash drop stash@{0}
)

echo.
echo [OK] Bloom RNG updated from GitHub.
pause
