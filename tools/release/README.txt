RELIC VALE 0.10.0
A single-player fantasy journey

Windows 10 x64 (1809 or later), OpenGL 3.3 capable graphics and current GPU drivers.
Windows 10 Enterprise 22H2, Ryzen 3 3200G and Radeon Vega 8 are the acceptance platform.
Other Windows/hardware configurations have not been certified in this release.
No Godot editor, Python, .NET, Git or development tools are needed to play.

INSTALL: Run RelicVale-0.10.0-Setup.exe. Installation is per-user; no administrator rights required.
PORTABLE: Extract the entire ZIP into any writable folder, then run RelicVale.exe.
Keep RelicVale.exe and RelicVale.pck together. Portable saves still use your Windows profile.

WASD/arrows: move. Shift: run. Ctrl: dodge.
E: interact. Space/left click: attack. 1/2: abilities. H: tonic.
I: inventory. J: quests. Tab: atlas. B: abilities. C: appearance.
G: camp. P: professions, fishing, farming and mounts. O: company. Z: companion commands.
Q/R: orbit. Right mouse drag: orbit/tilt. Wheel: zoom. Page Up/Down: tilt. Home: reset.
F6: save. F9: reload. Esc: pause/settings. F11: fullscreen.
Speak to Rowan by the starting village well for your first task.

HORSE: Reach camp tier 3, then buy the horse for 180 copper in P > Mounts.
Press V to call it, approach and press E to mount. Press V to dismount on open ground.
V can be changed to T or Y in Settings > Controls. Mounting is unavailable near enemies or indoors.

SAVE AND SETTINGS LOCATION:
%APPDATA%\Godot\app_userdata\RelicValePrototype\
journey.json, journey-slot2.json, journey-slot3.json are independent slots.
Each slot's .chunks folder is part of its save. Back up the JSON, .bak and .chunks together.
preferences.cfg holds graphics/audio/control settings separately from worlds.
Uninstalling and reinstalling keeps this folder, saves and settings.
The old internal folder name is retained for compatibility with earlier versions.

TROUBLESHOOTING:
Use the Start Menu 'Relic Vale - Safe Mode' shortcut for a 1280x720 window and Minimal graphics.
For portable mode: RelicVale.exe -- --safe-mode
Safe Mode preserves worlds; changing settings intentionally saves the new configuration.
If a primary save is damaged, its last valid backup is recovered automatically.
Help & Support can copy version/hardware information and open save/log folders.
Logs are under the save folder's logs directory, with five rolling log files.
For slower hardware, select Minimal or reduce render scale; Pixelated Render leaves UI text sharp.
The package is unsigned unless explicitly noted in its build receipt. No publisher certificate is claimed.

Third-party attributions and licenses are in THIRD_PARTY_LICENSES.txt and the in-game Credits page.
