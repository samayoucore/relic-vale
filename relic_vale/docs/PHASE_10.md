# Phase 10 — release preparation

Feature freeze is in effect. Relic Vale 0.10.0 is packaged for Windows x64 using Godot 4.7.2 stable and a per-user Inno Setup installer. The verified Phase 9 recovery archive and receipt remain in `downloads/` unchanged.

## Release issue register

| ID | Priority | Finding | Result |
| --- | --- | --- | --- |
| R01 | BLOCKER | No Windows export or installer | Closed: Release export, installer, uninstaller and portable ZIP built twice; installed/reinstalled on Windows 10. |
| R02 | BLOCKER | Developer shortcuts and test arguments accessible to players | Closed: Release runtime ignores test arguments and disables F3/F4/F7/F8/F10 and god mode. Release QA exercised these. |
| R03 | HIGH | Primary save could be replaced before the new snapshot and all referenced chunks were validated | Closed: temporary snapshot/chunks are fully checked, then replaced; valid backup is retained during corrupt-primary recovery. |
| R04 | HIGH | Invalid save/settings numbers and chunk corruption | Closed: finite/range checks, content hashes, atomic chunk write, backup recovery and 94 passing save cases. |
| R05 | HIGH | No release performance evidence | Closed for this Windows 10 machine: A–I benchmark, 1010-chunk stress run and 15-minute session are recorded in `PERFORMANCE.md`. High-speed streaming still has occasional frame spikes; see measured limits there. |
| R06 | MEDIUM | Version, support, credits and save previews | Closed: main-menu version, Help & Support, licenses/credits, manual-save preview and recovery messages. |
| R07 | MEDIUM | Debug hints and missing first-steps guidance | Closed: player-facing hints revised and short controls/onboarding page shown for a new traveler. |
| R08 | MEDIUM | Repeated whole-scene particle scans and costly map tiles | Closed: graphics traversal reduced, fog-aware shadows, map raster moved to worker jobs with bounded cache. |
| R09 | MEDIUM | Safe-mode settings changes did not persist | Closed: safe mode loads Minimal/windowed and saves deliberate later changes. |
| R10 | LOW | No release identity, legal files or checksums | Closed: icon, player documents, full attributions, SHA-256 checksums and build receipt. |

## Validation scope

The user selected this Windows 10 PC for acceptance. The final installer and portable ZIP were launched here, from outside the source directory, with their own game data directory. QA-instrumented Release exports exercised actual gameplay input and a new-process save reload; their extra test scripts are not in the distributable PCK. The final PCK contains 1118 entries; each digest was verified and development tests/docs were excluded. Two builds produced byte-identical PCKs. Installer and ZIP hashes can vary because their containers carry timestamps.

The visual and gameplay checks cover the starting area, forest, camp, procedural settlement, interior, combat, fishing, mounts, UI sizes, four graphics presets and Pixelated Render. The project contains additional biome, weather, dungeon and story combinations; automated checks do not replace a human playthrough of every combination. A 15-minute unattended game session checks stability but is not a claimed first-time human playtest. Clean Windows 11 and other hardware remain untested because the user chose this PC.

Detailed commands and evidence: `RELEASE_PROCESS.md`, `PERFORMANCE.md`, `QA_CHECKLIST.md`, `PHASE_10_REGRESSION.json`, `PHASE_10_STRESS_TESTS.json`, `PHASE_10_SAVE_TESTS.json`, and `PHASE_10_BUILD.json`.
