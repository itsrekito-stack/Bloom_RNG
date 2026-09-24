@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "PORT=8765"
set "EDITOR=tools/bloom-ui-editor/index.html"
set "SERVER=%~dp0tools\bloom-ui-editor\server.ps1"

if not exist "%EDITOR%" (
  echo.
  echo [ERROR] Bloom UI Studio files are missing:
  echo   %CD%\%EDITOR%
  echo.
  echo Run Update from GitHub.bat first.
  pause
  exit /b 1
)

call :PORTFREE %PORT%
if errorlevel 1 (
  set "PORT=8766"
  call :PORTFREE %PORT%
  if errorlevel 1 (
    set "PORT=8767"
  )
)

set "URL=http://127.0.0.1:%PORT%/%EDITOR%"

echo.
echo ============================================================
echo   Bloom UI Studio
echo ============================================================
echo   Project: %CD%
echo   URL:     %URL%
echo.

where py.exe >nul 2>&1
if not errorlevel 1 (
  echo Starting Python server...
  start "Bloom UI Studio Server" /min cmd.exe /c "cd /d "%CD%" && py.exe -m http.server %PORT% --bind 127.0.0.1"
  goto :WAIT
)

where python.exe >nul 2>&1
if not errorlevel 1 (
  echo Starting Python server...
  start "Bloom UI Studio Server" /min cmd.exe /c "cd /d "%CD%" && python.exe -m http.server %PORT% --bind 127.0.0.1"
  goto :WAIT
)

if not exist "%SERVER%" (
  echo [ERROR] Python not found and PowerShell fallback is missing.
  echo Try:
  echo   py --version
  echo.
  pause
  exit /b 1
)

echo Python not found. Starting PowerShell fallback...
start "Bloom UI Studio Server" /min powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SERVER%" -Root "%CD%" -Port %PORT%

:WAIT
for /L %%I in (1,1,30) do (
  call :PORTOPEN %PORT%
  if not errorlevel 1 goto :OPEN
  >nul ping 127.0.0.1 -n 1 -w 100
)

echo.
echo [ERROR] Local server did not open port %PORT%.
echo.
echo Check Python manually:
echo   py --version
echo.
echo Then try:
echo   cd /d "%CD%"
echo   py -m http.server %PORT% --bind 127.0.0.1
echo.
pause
exit /b 1

:OPEN
echo Server ready.
start "" "%URL%"
exit /b 0

:PORTOPEN
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object System.Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',%1); exit 0}catch{exit 1}finally{$c.Dispose()}" >nul 2>&1
exit /b %errorlevel%

:PORTFREE
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object System.Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',%1); exit 1}catch{exit 0}finally{$c.Dispose()}" >nul 2>&1
exit /b %errorlevel%
