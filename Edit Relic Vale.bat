@echo off
cd /d "%~dp0"
set "APPDATA=%~dp0tools\godot\userdata"
if not exist "%APPDATA%" mkdir "%APPDATA%"
set "VALE_GODOT=%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%VALE_GODOT%" set "VALE_GODOT=godot.exe"
start "Relic Vale Editor" "%VALE_GODOT%" --editor --path "%~dp0relic_vale"
