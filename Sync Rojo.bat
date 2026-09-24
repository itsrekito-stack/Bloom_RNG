@echo off
setlocal EnableExtensions
title Bloom RNG - Rojo Serve

set "ROOT=%~dp0"
pushd "%ROOT%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Could not open project folder:
  echo "%ROOT%"
  pause
  exit /b 1
)

set "ROJO=%USERPROFILE%\Desktop\Rojo\rojo.exe"
if exist "%ROJO%" goto rojo_found

if exist "%ROOT%rojo.exe" (
  set "ROJO=%ROOT%rojo.exe"
  goto rojo_found
)

where rojo >nul 2>&1
if not errorlevel 1 (
  set "ROJO=rojo"
  goto rojo_found
)

echo [ERROR] Rojo was not found.
echo Expected one of:
echo "%USERPROFILE%\Desktop\Rojo\rojo.exe"
echo "%ROOT%rojo.exe"
echo or rojo.exe available in PATH.
popd
pause
exit /b 1

:rojo_found
echo [Bloom RNG] Working directory:
echo "%CD%"
echo.
echo [Bloom RNG] Serving with:
echo "%ROJO%"
echo.

"%ROJO%" serve "%ROOT%default.project.json"
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" echo [ERROR] Rojo stopped with exit code %EXITCODE%.
popd
pause
exit /b %EXITCODE%
