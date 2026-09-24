# Windows 10 release QA — Relic Vale 0.10.0

Platform: Windows 10 Enterprise 22H2 (19045), x64, Ryzen 3 3200G, Radeon Vega 8, approximately 14 GB RAM, OpenGL Compatibility renderer, Godot 4.7.2 stable. The user selected this PC as the acceptance platform.

| Area | Result | Evidence / scope |
| --- | --- | --- |
| Import and static release audit | Pass | Final build: 272 static checks, no failures; resource import and release export logs have no errors. |
| Save integrity, migration and recovery | Pass | `PHASE_10_SAVE_TESTS.json`: 94/0; corrupt primary/chunks, backup recovery, nonfinite values, large inventory/currency and legacy data directory. |
| Earlier feature regressions | Pass | `PHASE_10_REGRESSION.json`: six suites, 162/0; Phase 9 companion 79/0 and camera 35/0 also passed. |
| Streaming/floating origin | Pass | `PHASE_10_STRESS_TESTS.json`: 262/0, 1010 unique chunks, 25 origin shifts, 12 far-return and 12 interior cycles. Cache stayed bounded at 512 map tiles. |
| Exported Release gameplay | Pass | Instrumented x64 Release export: 157/0 checks, including real movement/attack/gathering/fishing/horse input, camp, UI and story-save migration. Separate process reload: 7/0 checks. These QA PCKs add test scripts and are not the distributable PCK. |
| Safe Mode | Pass | Release QA with malformed settings: Minimal, 1280×720 window, ignored developer argument, new setting persisted; eight Boolean checks true. Final portable also launched with `--safe-mode` without errors. |
| Visual UI captures | Pass within scope | Saved engine screenshots include menu, first steps, atlas, inventory, interior, developed camp, mounted view, each preset with Pixelated Render on/off, 1280×720 through 3840×2160, alternate 1280×800 and UI scale 0.8/1.0/1.5. Font glyph checks covered Cyrillic, Latin, digits and punctuation. |
| Build repeatability/package audit | Pass | Two complete one-command builds. Both final PCKs have the same SHA-256 and 1118 validated entries. PE imports do not include Visual C++ or MinGW builder runtimes. All six `dist/SHA256SUMS.txt` entries match. |
| Installer | Pass on this PC | Installed into a path with Cyrillic and spaces. All six game files matched staging hashes; four Start Menu shortcuts created; normal unmodified executable started outside the source tree, exited cleanly and logged no errors. |
| Uninstall/reinstall | Pass on this PC | Game executable removed; all 41 test save files remained byte-identical by SHA-256. Reinstallation restored the executable and shortcuts; another unmodified launch exited 0 with clean log. |
| Portable | Pass on this PC | ZIP extracted into a separate Cyrillic folder, all six files matched staging hashes, normal and safe-mode launches exited 0 from outside project directory with clean logs. |
| Final local installation | Pass on this PC | After the Cyrillic-path tests, installed the final package at `%LOCALAPPDATA%\Programs\Relic Vale`; Start Menu game and Safe Mode shortcuts resolve there. The unmodified game launched from outside the project and exited 0 with a clean log. |
| Performance/long session | See `PERFORMANCE.md` | Frame time, FPS, draw calls, process memory, long travel and 15-minute run are recorded with hardware limitations. |

The actual installed/portable Release packages were launched and their package bytes were checked. In-depth game actions were exercised by the separate instrumented Release exports; the Windows 10 computer-control surface did not expose Godot's game window for reliable manual clicking. Thus first-time human play, every authored dungeon/biome combination, other GPUs, Windows 11, and a clean PC without development tools have not been personally observed in this test run. The final executable's PE imports and self-contained package reduce, but do not remove, the need for a clean-PC compatibility test before a public release.
