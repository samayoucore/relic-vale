# Phase 6 — physical and living world

Completed in the existing Relic Vale project, 10 September 2026. Phases 1–5 and the user's existing journey are preserved. The audit is in PHASE_6_AUDIT.md; the baseline is downloads/RelicVale-v0.6-baseline.zip. It includes the source, runtime assets, Windows launchers and bundled Godot engine for offline play. The archive excludes import caches, save files and downloaded source-pack archives. Extract it to a writable folder and run Launch Relic Vale.bat; the first run imports the local assets.

## Delivered systems

Resources: physical trees/logs, stone and mineral deposits, herbs, fiber, mushrooms and crystal. Crude/Iron/Steel axes and pickaxes use actual imported meshes, a Tool equipment slot, timed strike animation, impact foley, chips, node response, inventory feedback and visible depletion. Higher tiers reduce required strikes; steel grants a small yield bonus. Stable procedural IDs, partial damage and renewal days persist through chunk deltas and restart. See RESOURCE_SYSTEM.md for the data tables and controls.

Economy: the shared shop system sells harvested stacks, buys common supplies and sells better tools. Blacksmith, carpenter and alchemist preferences pay more for matching materials. Quest/equipped-item protection remains enforced. Price data and reputation feed one shared UI/transaction function; buying/reselling was checked across reputation tiers. No rare-crystal shop shortcut or unsafe bulk sale was introduced.

Interiors: house, general shop, forge, tavern and alchemist, each with imported furnishings, physical floor/furniture, lighting, appropriate ambience and household storage. A single active room loads behind a fade, with an exact logical exterior return. Outdoor simulation suspends while inside. Willowmere has five entrances; generated settlements have shops, tavern and farmhouse. INTERIORS.md explains records, loading, camera and persistence.

Residents: stable identities/home/work/tavern, exterior obstacle-aware walking, player/neighbor avoidance, time/weather destinations, indoor activity reservations, entry/exit movement and distance-based simulation. Merchants serve indoors, residents eat/drink/read/work/rest/sleep and react to nearby people. Willowmere has seven residents; small generated settlements have five or six. NPC_SIMULATION.md covers the concrete schedule and LOD.

Fauna: imported deer, stag, fox, cow, horse and alpaca; wildlife follows vegetated-biome rules and small groups, domestic animals belong to settlement farms. Idle/wander/graze/herd/flee/home/sleep states remain separate from enemy combat. Home/target positions survive origin shifts. Authored clips, bounded sounds, obstacle/water avoidance and distance throttling support ambient life without simulating an infinite population.

Camera: vertical right drag / Page Up–Down provides the requested modest 40–60 degree tilt, while existing horizontal orbit and wheel zoom remain. Blocking trees, roofs and objects hide temporarily and restore without resurrecting depleted resources. F3 world controls remain; F4 adds resource/interior/resident/fauna controls and path display.

## Assets and licensing

Quaternius Fantasy Props MegaKit Standard provides 32 selected tool/furniture/prop models; Ultimate Animated Animals provides the four new compatible animal models. Both are CC0. UAL2 Standard's 43 clips were downloaded and inspected; LPC sprites are not compatible with skeleton retargeting, so custom directional sprite/hand animation preserves the established look. The library is not represented as runtime retargeted motion.

Foley comes from rubberduck's 100 CC0 SFX #2; hoofbeats from EZduzziteh's Horse Trotting (CC0). The unmodified Mudchute cow recording by Secretlondon is CC BY-SA 3.0 with attribution and full license included. Existing Kenney/Quaternius scenery and LPC character credits remain. Tool thumbnails are rendered locally through the existing icon pipeline. Full URLs, selections, licenses and SHA-256 receipts are in ASSET_CREDITS.md and PHASE_6_ASSET_MANIFEST.json.

## Verification

| Check | Result | Workspace log |
| --- | --- | --- |
| Core gathering / all five interiors | PHASE6_CORE_RESULT 64 passed / 0 failed | phase6-core-gui-final.log |
| Exact gameplay sequence, steps 1–27 | PHASE6_ACCEPTANCE_RESULT 29 passed / 0 failed; walked 170.012407134287 | phase6-acceptance-final.log |
| Fresh-process gameplay reload, steps 28–29 | PHASE6_ACCEPTANCE_RELOAD_RESULT 6 passed / 0 failed | phase6-acceptance-reload.log |
| Migration / generated residents / partial and full harvest persistence | PHASE6_VALIDATION_RESULT 26 passed / 0 failed | phase6-validation.log |
| 100 neighboring streamed chunks | STRESS5_RESULT 15 passed 0 failed | phase6-stream-stress.log |
| Far fresh-process delta reload | STRESS5_RESULT 4 passed 0 failed | phase6-far-reload.log |
| Fresh-process interior reload / storage / exact exit | PHASE6_RELOAD_RESULT 6 passed / 0 failed | phase6-interior-reload.log |
| Player avoidance / moving residents / farm origins | PHASE6_LIFE_RESULT 8 passed / 0 failed | phase6-life-check.log |
| Final interior poses / animal animation / F4 | PHASE6_VISUAL_RESULT 4 passed / 0 failed | phase6-visual-final.log |
| Camera / graphics / native interface regression | PRESENTATION5_RESULT 38 passed 0 failed | phase6-presentation-regression.log |
| Combat regression | COMBAT3_RESULT: 21 passed, 0 failed | phase6-combat-regression.log |

PHASE_6_ACCEPTANCE.md records the exact requested 29-step sequence. The GUI run uses physics controller movement, keyboard door interaction and native pointer equipment; it physically walks the village/woodland, chops/mines, trades and follows Bram. Test/debug setup supplies time control and long-distance travel for unload checks. Reload occurs in a separate Godot process. The generated-world checks additionally cover partial harvest, full depletion/remnants, repeated unload/return, stable residents, malformed saves and old save formats. The real user journey is read-only and compared byte-for-byte after the run.

## Recorded GUI samples

Godot 4.7.2 Compatibility/OpenGL on Radeon Vega 8, 1280×720 window. FPS values are instantaneous scene samples, not a benchmark average; cold scene loads can be slower. The stress run was concurrent with acceptance and its timing includes that CPU contention. It traversed 100 chunks, retained bounded scenes/caches and peaked at 12,034 nodes; the largest recorded build stage was 60.448 ms under contention. This confirms bounds, not a guarantee of a hitch-free frame rate.

| Scene | FPS sample | Draw calls | Nodes |
| --- | ---: | ---: | ---: |
| village | 28 | 1091 | 8368 |
| house | 75 | 170 | 9522 |
| tavern | 67 | 231 | 9515 |
| blacksmith | 39 | 187 | 9795 |
| tool-inventory | 27 | 256 | 9893 |
| alchemist | 74 | 176 | 9294 |
| shop | 74 | 176 | 9535 |
| harvest-wood | 5 | 1413 | 8380 |
| harvest-stone | 32 | 1418 | 8391 |
| harvest-iron_ore | 32 | 1422 | 8410 |
| harvest-wild_herb | 33 | 1426 | 8415 |
| harvest-fiber | 29 | 1424 | 8419 |
| pasture | 26 | 1336 | 8419 |

Only one interior is instantiated. Imported scene/material resources are shared; noninteractive foliage remains batched; resident decisions and fauna simulation use distance throttling. The existing graphics presets remain functional. Raw GUI metrics are in PHASE_6_GUI_METRICS.json, and screenshots are in docs/screenshots/phase6-*.png.

## Practical limits

This is a playable local prototype. LPC humanoid actions use directional frames and simple seated/sleeping/working poses with imported hand props; there is no new humanoid skeleton. Interior decoration has a small set of seeded variations. Animals are ambient and noncombat, without breeding/taming or individually saved wilderness histories. Missing species-specific sleep clips use a rest pose. Optional falling-tree physics, durability and full farming/fishing systems remain outside this phase.

The test host has previously fallen back to Dummy audio, so automated playback checks do not establish audible sound quality. Rendering on this Vega 8 remains limited by scene/material draw calls; presets reduce cost but do not guarantee 60 FPS. All sources and runtime assets are local and no finishing download is required.
