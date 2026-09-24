import fs from 'node:fs';
const write=(p,s)=>fs.writeFileSync(p,s);
write('README.md',`# Relic Vale · 0.5

Запуск: **Launch Relic Vale.bat**. Редактор: **Edit Relic Vale.bat**. Движок и ресурсы включены, интернет для игры не нужен.

Этап 5: бесконечный потоковый мир, логические координаты и сдвиг начала координат, региональные дороги и реки, отдельные записи изменений чанков и расширяющийся атлас. Новый интерфейс, три слота сохранений, меню и настройки; четыре графических пресета и независимый Pixelated Render.

Камера: Q/R и горизонтальное движение с зажатой ПКМ — поворот; вертикальное движение ПКМ или Page Up/Down — наклон в пределах 40–60°. Колесо — приближение, Home — сброс. Препятствия перед камерой временно скрываются и восстанавливаются при свободном обзоре.

WASD — движение, Shift — бег, Ctrl — уклонение, Space/ЛКМ — удар, E — взаимодействие, 1/2 — умения, H — зелье. I — инвентарь, C — внешность, B — умения, J — задания, Tab — атлас, Esc — меню, F6/F9 — сохранить/загрузить, F3 — отладка.

Подробности: [руководство](relic_vale/README.md), [этап 5](relic_vale/docs/PHASE_5.md), [потоковый мир](relic_vale/docs/WORLD_STREAMING.md), [графика](relic_vale/docs/GRAPHICS_SETTINGS.md), [источники ресурсов](relic_vale/docs/ASSET_CREDITS.md).

Следующий принятый этап — физическая добыча, инструменты, интерьеры и живая жизнь поселений (Phase 6).
`);
write('relic_vale/README.md',`# Relic Vale · Phase 5

Run **Launch Relic Vale.bat** from the parent directory. The official Godot 4.7.2 standard engine is bundled; all game assets are local. Edit Relic Vale.bat opens the source project.

The existing village, five weapon types, six abilities, affixed gear, 25 relics, quests/factions, crafting, weather, wildlife and procedural dungeons are preserved. The wilderness now streams indefinitely through deterministic regional plans, with stable logical addresses and a floating origin. The atlas charts explored land and supports pan/zoom.

## Controls

WASD/arrows move, Shift runs, Ctrl dodges, Space/left click attacks, E interacts, H uses tonic. Abilities 1/2; B selects loadout. I inventory/equipment, C appearance, J journal, Tab atlas. Q/R or horizontal right drag orbit; vertical right drag or Page Up/Down tilts between 40 and 60 degrees. Wheel zooms; Home resets orbit, tilt and zoom. Blocking trees/roofs/objects temporarily disappear while obscuring the view, retaining collision. Esc opens the menu, F6 saves, F9 loads, F3 development controls, F11 fullscreen.

Pixelated Render now lives in Settings → Graphics. Four quality presets plus Custom control resolution scale, shadows, foliage, distance, particles and water. Pixelated Render is independent of preset. Settings include window resolution/mode, VSync, frame cap, UI scale and audio, saved separately from progression.

## Journeys and saves

The title screen provides Continue, New Game (name/seed/randomization), Load Game, Settings, Credits and Quit. Three journey slots have metadata and recoverable backups. Save format 5 migrates older v2–v4 files. Chunk changes are content-addressed under each slot's .chunks folder; both main save and those records must be copied together. Preferences live in preferences.cfg.

The launcher sets APPDATA for its process. Files remain under tools/godot/userdata/Godot/app_userdata/RelicValePrototype. Tests use their own saves and do not replace the user's journey.

## Verification and documentation

See [Phase 5](docs/PHASE_5.md), [streaming](docs/WORLD_STREAMING.md), [graphics](docs/GRAPHICS_SETTINGS.md), [UI style](docs/UI_STYLE_GUIDE.md) and [credits](docs/ASSET_CREDITS.md). The source includes streaming, camera, UI, save, real controller travel and preset tests. Pass --stream-test, --stress-world, --far-reload, --presentation-test, --final-phase5 or --ui-phase5-final after the Godot -- separator. --combat-check runs the existing 21-check combat regression. Set APPDATA to the bundled userdata directory when invoking the engine manually.

Typical recorded dense-scene performance is 24–26 FPS on this Radeon Vega 8/OpenGL host. Presets visibly change density/shadow detail and render cost; CPU/draw-call overhead still limits FPS. OpenGL does not support SSAO/SSIL/SSR/volumetric fog here. Some host sessions fall back to Dummy audio, so those runs do not verify audible output. The certificate-store startup warning is unrelated to offline gameplay.

Phase 6 follows this verified baseline: physical gathering with tools, interiors, NPC activities and farm animals. Until then, houses are scenery, resource harvesting uses the earlier interaction system, and residents have the earlier lightweight schedules. Enemy movement uses local steering. These are prototype limitations, not completed Phase 6 features.
`);
write('relic_vale/docs/PHASE_5.md',`# Phase 5 — completed baseline

The prior project was extended in place. No user journey was replaced. Phase 4 is preserved in RelicVale-v0.4-baseline.zip; the Phase 5 source/assets baseline is RelicVale-v0.5-baseline.zip.

## World

Unbounded deterministic 32 m chunks; 8×8 macro-regions, shared road portals, continuous water/biome/height fields, preserved unique starter area. Signed integer logical origin plus in-chunk position; local scene shifts past 128 m. Two background data workers prepare geometry/placements; one staged scene builder yields on a soft budget. Active/preload/unload radii are separate. Unloaded scenes are freed, data LRU bounded. Separate hash-verified chunk deltas and an atomic main manifest preserve changes without saving base scenery. Discovered atlas supports pan/zoom and known quest NPC markers. Details in WORLD_STREAMING.md.

## Presentation

Kenney RPG Expansion Theme, Rubik body text, Press Start 2P accents, Drummyfish equipment/ability icons and locally rendered CC0 material thumbnails. Rebuilt HUD, inventory/equipment/comparison, journal, character, abilities, shop, crafting, shrine, dialogue, main/pause/loading/world creation/save slots/settings/credits. Containers and 80–150% UI scale; focus/hover feedback; actual 720p/1080p/1440p/2160p image dimensions checked. Rubik uses distance-field import for body scaling; pixel captions retain their pixel-font import.

Minimal/Medium/High/Ultra/Custom settings apply at runtime. Pixelated Render independently changes the world SubViewport while UI stays sharp. Original terrain, grass, leaf wind and water shader work incorporates shared weather and logical-origin phase. Unsupported renderer features are explicitly gated. Camera now adds limited tilt and hides view-obstructing visuals, including canopies and camera-inside cases; visibility is restored without disabling collision.

## Evidence

| Suite | Result |
|---|---|
| Logical streaming, billion-chunk teleports, roundtrips | 22 / 0 failures |
| 100 adjacent chunk transitions, bounded cache, far resource save | 15 / 0 |
| Actual new-process far save reload | 4 / 0 |
| GUI camera, pointer inventory/shrine, four presets × both pixel states | 38 / 0 |
| Controller road travel, far dungeon exit, save GC, menu guards, resolutions | 25 / 0 |
| Final HUD scale and actual framebuffer-size checks | 5 / 0 |
| Existing weapons/abilities/status/audio wiring regression | 21 / 0 |

Continuous ordinary controller movement traversed 255.2 m through 11 chunks with a maximum 36 active chunks. The automated 100-transition stress recorded a maximum 7,022 nodes, 12.565 ms worst main build stage and 98.49 ms last worker plan on this host after moving mesh calculations off the main thread. These are test measurements, not hard realtime guarantees. Discovered history grows intentionally; scene/data caches remain bounded. Hash-record garbage collection retains current and backup references.

Screenshots: docs/screenshots/phase5-* and phase2-phase5-* (historical helper prefix). They include menus, all UI pages, material icons, camera 40°/60°, forest/water/crypt across all presets and pixel states, physical road traversal, and native outputs up to 4K. PHASE_5_PRESENTATION.json contains recorded metrics; PHASE_5_FINAL_TEST.md records physical traversal. The new-process resource evidence is PHASE_5_FAR_RELOAD.md.

## Practical limits

Dense scenes remain CPU/draw-call limited around 24–26 FPS on Vega 8, with over 1,000 draw calls in sampled views. The soft frame budget can be exceeded by one imported object or collision construction. Geography is stylized and rivers do not simulate erosion or confluences. A single unique authored hub remains as a bounded detached scene cache. Discovered history necessarily grows as the player explores. OpenGL advanced screen-space/volumetric features are unavailable. Sound was audibly available in some graphical runs; later host WASAPI failures used Dummy audio and validate mixer/asset wiring only. The UI is English with Cyrillic-capable fonts; full localization is not claimed.

Physical tool gathering, enterable homes and fuller resident/animal behavior are the next accepted Phase 6 scope, not claimed as part of this baseline.
`);
write('relic_vale/docs/NEXT_STEPS.md',`# Accepted development sequence

Phases 1–5 are completed baselines. Phase 5 adds the requested camera tilt and occluder hiding, tested in the actual game.

Continue Phase 6 from this project: physical gathering nodes, real imported tools and adapted gathering animation; specialized resource economy; separate enterable house/shop/forge/tavern/alchemist interiors; resident anchors/activities/interior schedules and simulation LOD; compatible animated wildlife and farm animals. Preserve streaming, logical addresses, deltas, combat, quests, UI/settings and the user's existing journey. Perform the exact supplied end-to-end playtest and document assets, persistence and known limits before completion.
`);
for(const f of ['relic_vale/docs/GRAPHICS_SETTINGS.md','relic_vale/docs/UI_STYLE_GUIDE.md']){let s=fs.readFileSync(f,'utf8').replace('Rubik/Press Start 2P distance-field fonts','Rubik distance-field body text and pixel-font captions').replace('Distance-field import supports scaling.','Rubik distance-field import supports scaling; Press Start 2P retains pixel-font import.');fs.writeFileSync(f,s);}
console.log('Phase 5 baseline documentation finalized.');
