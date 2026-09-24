@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "PORT=8765"
set "EDITOR=tools/bloom-ui-editor/index.html"
set "SERVER=%~dp0tools\bloom-ui-editor\server.ps1"

if not exist "%~dp0%EDITOR%" (
  echo.
  echo [ERROR] Bloom UI Studio files are missing:
  echo   %~dp0%EDITOR%
  echo.
  echo Run Update from GitHub.bat first.
  pause
  exit /b 1
)

call :SETURL

echo.
echo ============================================================
echo   Bloom UI Studio
echo ============================================================
echo   Project: %CD%
echo.

rem Reuse only a server that can actually return Bloom UI Studio.
curl.exe -fsS --max-time 1 "%URL%" >nul 2>&1
if not errorlevel 1 goto :OPEN

rem If something else is already serving 8765, use 8766 instead.
curl.exe -sS --max-time 1 "http://127.0.0.1:%PORT%/" >nul 2>&1
if not errorlevel 1 (
  echo Port %PORT% is occupied by another local server.
  set "PORT=8766"
  call :SETURL

  curl.exe -fsS --max-time 1 "%URL%" >nul 2>&1
  if not errorlevel 1 goto :OPEN
)

echo   URL: %URL%
echo.

rem Prefer Python: it starts much faster than the PowerShell fallback.
where py.exe >nul 2>&1
if not errorlevel 1 (
  echo Starting fast Python server on port %PORT%...
  start "Bloom UI Studio Server" /min py.exe -m http.server %PORT% --bind 127.0.0.1 --directory "%~dp0"
  goto :WAIT
)

where python.exe >nul 2>&1
if not errorlevel 1 (
  echo Starting fast Python server on port %PORT%...
  start "Bloom UI Studio Server" /min python.exe -m http.server %PORT% --bind 127.0.0.1 --directory "%~dp0"
  goto :WAIT
)

rem No Python: dependency-free PowerShell fallback.
if not exist "%SERVER%" (
  echo [ERROR] Neither Python nor the PowerShell fallback server was found.
  pause
  exit /b 1
)

echo Python not found. Starting PowerShell fallback...
start "Bloom UI Studio Server" /min powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SERVER%" -Root "%~dp0" -Port %PORT%

:WAIT
for /L %%I in (1,1,30) do (
  curl.exe -fsS --max-time 1 "%URL%" >nul 2>&1
  if not errorlevel 1 goto :OPEN
  >nul ping 127.0.0.1 -n 1 -w 100
)

echo.
echo [ERROR] Server started, but the editor page was not reachable.
echo Expected local file:
echo   %~dp0%EDITOR%
echo Expected URL:
echo   %URL%
echo.
pause
exit /b 1

:OPEN
echo Server ready: %URL%
start "" "%URL%"
exit /b 0

:SETURL
set "URL=http://127.0.0.1:%PORT%/%EDITOR%"
exit /b 0
