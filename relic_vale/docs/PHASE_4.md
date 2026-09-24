# Phase 4 — living landscape

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
