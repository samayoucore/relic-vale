# Phase 5 starting audit

Baseline: completed phase 4, preserved in downloads/RelicVale-v0.4-baseline.zip (46,040,463 bytes). Actual graphical runs inspected the original village, forest, three settlements, roads/bridge, mine/crypt, journal, crafting and merchant controls. Integration, pointer, new-process load, traversal and combat checks passed before architecture changes.

The old generator builds a finite 7×7 layout eagerly, instantiates up to nine surrounding 32 m chunks and retains up to 25, with a permanent watershed wall. Terrain, roads and vegetation use local Vector2 positions; dungeons are distinguished by reserved x coordinates. Saves v4 store absolute local positions and aggregate object-delta dictionaries. These assumptions must be separated from logical global addresses before expanding travel.

The renderer is Godot 4.7.2 standard x64 OpenGL Compatibility on Radeon Vega 8. The world SubViewport is fixed at 768×432 with nearest upscaling into 1280×720; UI uses native drawing at a fixed design canvas. The current P toggle changes the viewport to 1280×720. SSAO, SSIL, SSR and volumetric fog are not available on this renderer and must remain honestly capability-gated. Existing low-poly assets, player animation, imported creature clips, combat and day/weather lighting are retained.

The UI has teal/gold local styles, system fonts and many absolute coordinates; it needs a shared Theme, licensed fonts/icons and responsive container screens. No independent SettingsManager exists; audio is tied to progression. Typical dense phase4 scenes: 24–29 FPS, with 18 FPS in the nine-creature gallery. Streaming changes must reduce scene churn, bound data and scene caches, and report costs rather than assume hardware performance.

Implementation order: address/region planning → floating origin → staged preload/unload → chunk deltas → far-world stress → theme/screens → independent settings/presets → shaders → visual matrix and final documentation. Phase 6 remains queued until these checks finish.
