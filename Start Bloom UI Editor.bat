@echo off
setlocal
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

if not exist "%SERVER%" (
  echo [ERROR] Server script is missing:
  echo %SERVER%
  echo.
  echo Run Update from GitHub.bat first.
  pause
  exit /b 1
)

rem If the port is already open, reuse the running server.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object System.Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',%PORT%); exit 0}catch{exit 1}finally{$c.Dispose()}" >nul 2>&1
if not errorlevel 1 goto :OPEN

echo Starting local server...
start "Bloom UI Studio Server" /min powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SERVER%" -Root "%~dp0" -Port %PORT%

rem Wait until the server really accepts TCP connections.
for /L %%I in (1,1,40) do (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object System.Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',%PORT%); exit 0}catch{exit 1}finally{$c.Dispose()}" >nul 2>&1
  if not errorlevel 1 goto :OPEN
  >nul ping 127.0.0.1 -n 1 -w 200
)

echo.
echo [ERROR] Bloom UI Studio server did not start.
echo.
echo Try this command manually to see the exact PowerShell error:
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SERVER%" -Root "%~dp0" -Port %PORT%
echo.
pause
exit /b 1

:OPEN
echo Server ready.
start "" "%URL%"
exit /b 0
