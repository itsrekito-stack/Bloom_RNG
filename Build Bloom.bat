@echo off
setlocal EnableExtensions
title Bloom RNG - Rojo Build

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
echo [Bloom RNG] Building with:
echo "%ROJO%"
echo.

"%ROJO%" build "%ROOT%default.project.json" -o "%ROOT%BloomRNG.rbxl"
if errorlevel 1 (
  echo.
  echo [ERROR] Rojo build failed. See the error above.
  popd
  pause
  exit /b 1
)

echo.
echo [OK] Build finished:
echo "%ROOT%BloomRNG.rbxl"
popd
pause
