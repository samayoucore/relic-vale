# Phase 7 — cartography, travel and an owned hamlet

Implemented in the existing Godot project; the v0.6 runnable archive remains preserved. No account, paid asset or online service is needed to play.

The real map and minimap share terrain-derived tiles, fog, readable roads/water, service/quest icons, filters, bounded caching and integer logical coordinates. Up to 32 saved custom markers support names/icons/deletion and guarded travel. Loading covers synchronous destination streaming and a physical safe-landing check, including huge logical distances.

The owned camp has a validated/reserved expansion site, five visual stages, a permanent map marker, independent Food/Materials/Gold/XP, optional confirmed donations and capped XP until an affordable upgrade is confirmed. Its first physical traveler is guaranteed; residents have persistent appearance, skills, levels, assignments, daily activities and tent/cottage homes. The high-tier player house, veteran houses and workshop are enterable; Rook provides a hamlet shop.

Twelve task offers cover foraging, logging, mining, hunting, salvage, trading, patrol, exploration, supply, construction and special expeditions. Requirements explain locked tasks, the picker supports 1–4 residents, refresh costs Camp Gold, and saved game-clock missions grant rewards exactly once. A one-resident economy test reaches every tier without player donations.

Controls: Tab atlas, right-click charted ground for a marker, wheel map/minimap zoom, G camp, E interaction, Enter/Esc camp placement confirm/cancel, F7 Phase 7 tools. Existing camera orbit, 40–60° tilt, wheel zoom and obstruction hiding remain active.

New external assets: selected Kenney Survival Kit 2.0 GLBs plus their palette, CC0; source https://kenney.nl/assets/survival-kit . Existing KayKit Medieval Builder houses, Phase 6 furniture and licensed LPC sprites are reused. Terrain cartography and symbols are original code-generated assets. See ASSET_CREDITS.md and PHASE_7_ASSETS.json for provenance and checksums.

Validation is recorded in PHASE_7_TEST_RESULTS.json and the exact 35-step acceptance mapping in PHASE_7_ACCEPTANCE.md. The game was run graphically and screenshots reviewed; extended tests cover worker movement/shelter, actual pointer marker/recruitment controls, 3/4-worker missions, no-donation progression, malformed saves and older versions. A separate process tests reloaded jobs and one-time reward resolution. All tests use isolated test saves; the real journey is preserved.

Architecture and practical limits: MAP_SYSTEM.md, CAMP_SYSTEM.md and CAMP_TASKS.md. Important limits are chunk-based discovery, schematic icons, synchronous bounded travel loading, predefined camp layouts and abstract offscreen assignments. This is a local playable prototype, not a freeform colony builder.
