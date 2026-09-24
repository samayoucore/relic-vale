@echo off
cd /d "%~dp0"
set "APPDATA=%~dp0tools\godot\userdata"
if not exist "%APPDATA%" mkdir "%APPDATA%"
set "VALE_GODOT=%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%VALE_GODOT%" (
  where godot.exe >nul 2>nul
  if errorlevel 1 (
    echo Godot 4.7.2 is missing. Install it or open relic_vale\project.godot manually.
    pause
    exit /b 1
  )
  set "VALE_GODOT=godot.exe"
)
if not exist "relic_vale\.godot\global_script_class_cache.cfg" (
  echo Preparing Relic Vale for its first journey...
  "%VALE_GODOT%" --headless --editor --path "%~dp0relic_vale" --import --quit
  if errorlevel 1 (
    echo Import failed. Open Edit Relic Vale.bat to inspect the project.
    pause
    exit /b 1
  )
)
start "Relic Vale" "%VALE_GODOT%" --path "%~dp0relic_vale"
