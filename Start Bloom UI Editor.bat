@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "PORT=8765"
set "URL=http://127.0.0.1:%PORT%/tools/bloom-ui-editor/"
set "SERVER=%~dp0tools\bloom-ui-editor\server.ps1"

echo.
echo ============================================================
echo   Bloom UI Studio
echo ============================================================
echo   Project: %CD%
echo   URL:     %URL%
echo.

rem Fast path: reuse a server that is already running.
where curl.exe >nul 2>&1
if not errorlevel 1 (
  curl.exe -s --head --max-time 1 "%URL%" >nul 2>&1
  if not errorlevel 1 goto :OPEN
)

rem Prefer Python: starts much faster than the PowerShell fallback.
where py.exe >nul 2>&1
if not errorlevel 1 (
  echo Starting fast Python server...
  start "Bloom UI Studio Server" /min py.exe -m http.server %PORT% --bind 127.0.0.1 --directory "%~dp0"
  goto :WAIT
)

where python.exe >nul 2>&1
if not errorlevel 1 (
  echo Starting fast Python server...
  start "Bloom UI Studio Server" /min python.exe -m http.server %PORT% --bind 127.0.0.1 --directory "%~dp0"
  goto :WAIT
)

rem No Python: dependency-free PowerShell fallback.
if not exist "%SERVER%" (
  echo [ERROR] Neither Python nor the PowerShell fallback server was found.
  echo Run Update from GitHub.bat and make sure Python is installed.
  pause
  exit /b 1
)

echo Python not found. Starting PowerShell fallback...
start "Bloom UI Studio Server" /min powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SERVER%" -Root "%~dp0" -Port %PORT%

:WAIT
rem Usually Python is ready on the first or second pass.
for /L %%I in (1,1,20) do (
  where curl.exe >nul 2>&1
  if not errorlevel 1 (
    curl.exe -s --head --max-time 1 "%URL%" >nul 2>&1
    if not errorlevel 1 goto :OPEN
  ) else (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object System.Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',%PORT%); exit 0}catch{exit 1}finally{$c.Dispose()}" >nul 2>&1
    if not errorlevel 1 goto :OPEN
  )
  >nul ping 127.0.0.1 -n 1 -w 100
)

echo.
echo [ERROR] Bloom UI Studio server did not start on port %PORT%.
echo.
echo Check whether another program is using the port, then try again.
echo Python check:
echo   py --version
echo.
pause
exit /b 1

:OPEN
echo Server ready.
start "" "%URL%"
exit /b 0
