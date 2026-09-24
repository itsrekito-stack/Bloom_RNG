@echo off
setlocal
cd /d "%~dp0"
set PORT=8765
echo.
echo Bloom UI Studio
echo Project: %CD%
echo URL: http://127.0.0.1:%PORT%/tools/bloom-ui-editor/
echo.
start "" "http://127.0.0.1:%PORT%/tools/bloom-ui-editor/"

where py >nul 2>&1
if %errorlevel%==0 (
  py -m http.server %PORT% --bind 127.0.0.1
  goto :eof
)

where python >nul 2>&1
if %errorlevel%==0 (
  python -m http.server %PORT% --bind 127.0.0.1
  goto :eof
)

echo [ERROR] Python not found. Install Python or run any local static server from this folder.
pause
