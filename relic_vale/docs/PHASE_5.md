# Phase 5 — completed baseline

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
