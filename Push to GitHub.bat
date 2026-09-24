@echo off
setlocal
cd /d "%~dp0"
git add -A
git diff --cached --quiet
if not errorlevel 1 (
  echo No changes to commit.
  pause
  exit /b 0
)
set "MSG="
set /p "MSG=Commit message: "
if not defined MSG set "MSG=Local Bloom RNG changes"
git commit -m "%MSG%"
if errorlevel 1 (
  pause
  exit /b 1
)
git push origin main
pause
