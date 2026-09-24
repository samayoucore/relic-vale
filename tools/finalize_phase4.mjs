import fs from 'node:fs';
const write=(p,s)=>fs.writeFileSync(p,s.trim()+'\n');
write('README.md',`# Relic Vale · 0.4

Запуск: **Launch Relic Vale.bat**. Редактор: **Edit Relic Vale.bat**. Godot и все ресурсы включены, интернет не нужен.

Этап 4 развивает прежний проект: единый рельеф и растительность, анимированные 3D-враги, река и озеро, три поселения, расписания жителей, пять типов торговцев, три фракции и девять заданий в цепочках. Шесть природных ресурсов, 20 рецептов, четыре вида станций, смена суток и пять состояний погоды. Две темы процедурных подземелий дополняют первоначальный склеп.

**WASD** — идти, **Shift** — бежать, **Ctrl** — уклониться, **Space / ЛКМ** — удар, **1 / 2** — способности, **E** — взаимодействовать. **I** — сумка, **B** — способности, **C** — внешность, **J** — задания, **Tab** — карта. **Q / R / ПКМ** — камера, колесо — масштаб. **F6 / F9** — сохранение / загрузка, **Esc** — меню, **F3** — отладка.

Поговорите с Роуэном у колодца. Карта показывает Фернвотч, Айронвейн и торговое поселение; цепочки открывают рецепты. Сохранения версий 2 и 3 переносятся в версию 4.

[Инструкция](relic_vale/README.md) · [Отчёт этапа 4](relic_vale/docs/PHASE_4.md) · [Лицензии](relic_vale/docs/ASSET_CREDITS.md)
`);
write('relic_vale/README.md',`# Relic Vale · 0.4

A local single-player Godot 4.7.2 fantasy RPG. Run **Launch Relic Vale.bat** in the parent folder. The standard Windows x64 runtime is bundled. **Edit Relic Vale.bat** opens the editable project. All required assets are local.

## Play

Move with WASD/arrows, run with Shift, dodge with Ctrl, attack with Space/left click, interact with E. Q/R or right-drag orbit the camera; wheel zooms. Abilities: 1/2; ability selection: B. Inventory: I; appearance: C; tonic: H; quests/factions: J; atlas: Tab. F6 saves, F9 loads, Esc opens the menu, F3 opens development controls. P switches the current pixel presentation; F11 toggles fullscreen.

Start by talking to Rowan. Follow atlas roads to Fernwatch (forest), Ironvein (mining), and Crossroads (trade). Gather logs, herbs, mushrooms, stone, ore and crystals. Four stations in Willowmere offer workbench, forge, alchemy and campfire recipes. Three faction chains unlock advanced patterns. Merchants sell specialized stock, buy individual items, change prices with reputation and replenish stock daily. Residents walk between work, square and home; shops close when their residents go inside.

The original Forgotten Crypt remains at the eastern forest entrance. Mine and chapel/cave POIs lead to seeded eight-room expeditions with branches, a loop, treasure, traps, shrine and two-phase guardian. Surface exits preserve the return position. Explore by day or night through Clear, Cloudy, Rain, Fog and Storm weather.

The five weapon types, six combat abilities, affixed gear, 25 relics, original quests, inventory, appearance and combat from earlier phases remain available.

## Saves and checks

The launcher sets APPDATA only for its process. Saves stay under **tools/godot/userdata/Godot/app_userdata/RelicValePrototype**. Production progression uses journey.json with a recoverable backup; v2/v3 migrate to v4. Tests use separate files.

Set APPDATA to the bundled userdata folder when invoking Godot manually. Import with --headless --editor --path relic_vale --import --quit. Run -- --phase4-test for the 62-check integration suite; --phase4-extra checks all faction rewards, 20 recipes and real UI pointer input; --phase4-startup reloads the integration save in a new process; --walk-phase4 traverses physical roads/bridges/outer watersheds and checks overlays. Graphical tests write screenshots. --combat-check exercises the existing 21-check combat suite.

See [Phase 4](docs/PHASE_4.md), [test results](docs/PHASE_4_TEST_RESULTS.md), [additional checks](docs/PHASE_4_EXTRA.md), [visual gate](docs/PHASE_4_VISUAL_GATE.md), and [asset credits](docs/ASSET_CREDITS.md).

## Prototype limits

This version has a finite 224 m square wilderness. NPC A* paths use small authored waypoint graphs; enemies use local steering. Houses are scenery and residents disappear at their door after returning home. Gathering is one interaction per persistent node; its shared batched scenery remains. Dungeon geometry uses modular floors/walls, with two themed decoration palettes. Audio consists of original synthesized loops and effects. Balance needs broader human playtesting.

Verified with the bundled standard engine and OpenGL Compatibility on Radeon Vega 8. Some host sessions could not open the Windows audio output and used Godot's dummy driver; sound assets and mixer wiring were tested, but those runs do not verify audible quality. The restricted host emits a root certificate-store warning; offline gameplay does not use the network.
`);
write('relic_vale/docs/PHASE_4.md',`# Phase 4 — living landscape

Built on the existing project; source snapshots of phases 1–3 are retained under downloads. Visual unification was completed and inspected before gameplay expansion, as recorded in PHASE_4_AUDIT.md and PHASE_4_VISUAL_GATE.md.

## Landscape and art

One master terrain material carries the village palette into smoothly blended meadow, forest and ruins. Triangulated 2 m terrain vertices share exact collision heights. Roads are clipped to terrain triangles, including the original village-to-procedural road connection. Flat settlement/POI footprints blend into slopes. Imported textured ground-cover MultiMeshes use per-instance color, varied scales and wind. Trees anchor understory clusters with shrubs, logs, rocks, flowers and mushrooms. A continuous rocky watershed masks the finite border at every camera angle. A curved river, shallow bridge crossings and a lake share coherent banks. Imported deer/stag wander and flee.

Slime, skeleton, bat, wolf, witch, elite and guardian visuals now use imported skinned models and animations. The original pixel player and its customization are preserved. A clip adapter connects existing combat states to imported animation libraries. Camera framing remains stable after moving the orthographic camera back to prevent mountain near-plane clipping.

## Gameplay

Three settlements have distinct forest, mining and trading layouts, NPCs, stations, yards and lights. Shared A* schedules cover work, evening square and nighttime/storm shelter. Five merchant categories offer individual buy/sell transactions with bounded daily stock. Lantern Compact, Elderbough Wardens and Keepers of the Veil each have a three-stage quest chain, reputation tiers, trade consequences and an earned advanced pattern.

Six principal gathered resources feed 20 data recipes at four station categories. Crafting validates station identity, proximity, pattern, inputs and copper before consuming materials. New consumables grant healing, regeneration, shield or haste. Already learned merchant patterns cannot be purchased again. Quest rewards cannot be claimed twice; earlier dungeon clears and discovered quest landmarks receive credit when a later objective activates.

Day/night light and window lamps, five deterministic weather states, rain/storm particles, rare lightning and six mixed environmental audio loops share a saved clock. Rain improves herb yield. A rare traveling merchant event records its location for same-day restoration. Eleven contextual story POI additions supplement the five original templates; quest-critical grove, mine and chapel destinations are guaranteed.

Seeded eight-room expeditions have a main route, branch and connected loop. A library of eleven room scene types supports entrance, combat, large combat, crossroads, elite, boss, treasure, shrine, trap, corridor and corner. Narrow connectors are built between room doors. Crypt and mine decoration themes retain the original combat/boss rules and stable treasure/resource IDs. The original Forgotten Crypt is preserved.

## Persistence and tools

Save v4 includes clock, weather, reputation, stock, unlocks, events, settlement and dungeon records. Versions 2 and 3 migrate safely. Generated interiors rebuild before physics on both in-session load and process startup. New World clears old expedition content. Freed settlement lights are pruned from the lighting registry.

F3 adds time/weather controls, settlement/POI teleport, resource grants/spawn, chunk rebuild, procedural dungeon entry, reputation and event controls. Six overlays inspect biome weights, density, exclusions, chunks, roads and rivers. The normal atlas labels settlements and quest landmarks and draws the river.

## Verification

Actual graphical integration: **62 passed, 0 failed** (PHASE_4_TEST_RESULTS.md). Additional graphical quest/crafting/pointer checks: **34 passed, 0 failed** (PHASE_4_EXTRA.md). Fresh-process dungeon load and New World cleanup: **3 passed, 0 failed** (PHASE_4_STARTUP.md). Physical traversal: **20 passed, 0 failed** (PHASE_4_TRAVERSAL.md). Existing weapon/ability/status suite rerun: **21 passed, 0 failed**, downloads/phase4-legacy-combat.log. Imported mesh/animation visual gate: **18 passed**.

Screenshots in docs/screenshots cover hub/biome transitions, landmarks, imported enemies, watershed camera headings, all settlements, night, trade, crafting, journal, rain/fog/storm, both expedition themes, roads and bridges. Graphics runs use real Godot rendering and physics. Forced damage in dungeon structural tests checks phase transitions and persistence; it is not evidence of player combat balance. Earlier Phase 3 normal-damage boss playtest remains documented separately.

Typical phase4 scenes measured 24–29 FPS at 1280×720 output / 768×432 world on this Vega 8 host; the nine-actor gallery was about 18 FPS. This is a baseline for Phase 5 performance work, not a 60 FPS claim. Host root-certificate warnings are unrelated to this offline game. Some latest sessions had WASAPI unavailable; they validated audio loading/mixing but did not audition sound.

## Assets and limits

Exact sources, permissive licenses and selected-file hashes are in ASSET_CREDITS.md and PHASE_4_ASSET_MANIFEST.json. New original ambience WAVs are generated by tools/phase4_ambience.mjs. Shaders and procedural builders are original code. No full unrelated asset packs are runtime dependencies.

World is still finite in v0.4. NPC navigation is deliberately small; houses have no interiors yet. Shared batched resource scenery does not change after harvest. Enemy avoidance is local, not a navigation mesh. Only the tested seed/camera samples have visual evidence; arbitrary seeds may need further tuning. Phase 5 addresses world streaming, UI and rendering; Phase 6 is queued for tools, physical gathering and enterable living buildings.
`);
write('relic_vale/docs/NEXT_STEPS.md',`# Accepted development sequence

1. Phase 4 completed and preserved as the v0.4 baseline.
2. Phase 5: effectively unbounded deterministic regions/chunks, floating origin, background planning, staged streaming, bounded cache and delta persistence; expanding discovered map; coherent UI theme/icons/fonts; independent user settings and scalable graphics/pixel rendering; far-world and preset tests.
3. Phase 6: physical gathering and tools, resource economy, enterable buildings/interiors, richer NPC behavior and friendly settlement animals. Implement only after the Phase 5 audit, integration and tests are complete.

Continue to preserve the original village, combat, quests, appearance, relics, dungeon and existing user save. Prioritize verified playable behavior over adding untested content.
`);
const credits='relic_vale/docs/ASSET_CREDITS.md';
const marker='## Phase 4 original ambience';
let text=fs.readFileSync(credits,'utf8').split(marker)[0];
fs.writeFileSync(credits,text+'\n'+marker+'\n\nSix original 8-second mono WAV loops (wind, forest birds, water, night insects, rain, village work) generated by tools/phase4_ambience.mjs. No third-party samples. They loop through the SFX bus with smooth proximity/day/weather mixing. Terrain, vegetation and water shader changes are original project code.\n');
