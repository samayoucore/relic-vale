# Phase 9 — companions and the lantern roads

The existing local RPG now has four authored companions, relationships and twelve personal chapters, a complete ten-chapter first act, nine faction chapters, eight contextual road events, persistent consequences and an expanded journal/lore interface. Four recruitment quests bring the added total to 35. Existing professions, camp workers, mounts, world streaming, combat, camera tilt and obstruction hiding remain integrated.

## Start playing

Use **Launch Relic Vale.bat** in the parent folder. Existing journeys migrate to save version 9. Speak to Rowan in Willowmere to begin the new lantern story; the option about the village retains the old tasks. Bren watches the road east of the village. Explore to meet Tarin Fen, Ilyra Venn and Sera Reed. Establish a camp and return to it for personal conversations.

**O** company/equipment, **Z** follow/wait/combat orders, **J** quest journal and lore, **Tab** atlas, **G** camp, **P** professions, **V** call horse, **E** interact/revive. **F10** narrative debug. Q/R or right drag orbit; vertical right drag/Page Up/Down tilt 18–60° outdoors; wheel zooms; Home resets to 50°. See [camera and camp changes](CAMERA_AND_CAMP.md).

The lowest perspective angle reveals the horizon. Distance haze completely conceals missing terrain at every draw-distance preset, including while chunks are building and after changing quality. Nearby foreground scenery softly blurs while the hero's focus plane and HUD remain sharp. A tree or roof hides only when the camera eye enters its mesh volume, with collision preserved; standing near an object or looking through it does not hide it. Houses and crypts keep the higher interior camera framing.

Establishing camp clears trees, rocks, bushes and small natural decoration from the future hamlet footprint and its margin. Houses, crypt entrances, village structures and story landmarks block placement. Clearance persists across streaming and save/load; it awards no gathering loot or profession XP.

To ride, reach camp tier 3, open **P → Mounts** and buy the horse for **180 copper**. Press **V** to call it, approach it and press **E** to mount. **Shift** gallops; **E** dismounts. Nearby combat temporarily prevents mounting.

| Companion | Model | Role | Abilities |
| --- | --- | --- | --- |
| Bren Alder | Knight.glb | melee | Shield Rush; Hold the Line |
| Tarin Fen | Ranger.glb | ranged | Pinning Shot; Split Fletching |
| Ilyra Venn | Mage.glb | mage | Frost Bind; Ember Mark |
| Sera Reed | Rogue.glb | support | Field Dressing; Steady Hands |

Every companion has recruitment, three personal quests, approval/tier gates, signature gear and a final passive. One companion travels and fights; others visibly keep camp routines. Final choices alter faction standing and authored location variants. Faction accords add merchandise at Friendly standing. Road stories use weather, time, biome, road/settlement/ruin context, faction standing and story progress.

## Architecture, assets and tests

See [Companions](COMPANION_SYSTEM.md), [Narrative](NARRATIVE_SYSTEM.md), [World events](WORLD_EVENTS.md), [asset credits](ASSET_CREDITS.md), [initial audit](PHASE_9_AUDIT.md) and [release checks](PHASE_9_RELEASE_CHECKS.json). Test receipts contain individual assertions; the release checks aggregate completed runs and engine-log checks.

The first companion was completed and tested before expanding the roster: the original headless slice passed 52 checks and a fresh graphical reload passed 7. The expanded story run completes all four recruitments, all personal arcs, all ten main chapters and all faction chains, using real interactables/dialogue and normal timed attacks. Its setup loads the completed first-companion fixture; test helpers teleport between objective sites and supply required materials. Combat checks use player invulnerability to isolate progression and companion AI; they are not a claim of human balance testing.

Reproduce inside the actual Godot scene by setting APPDATA to the bundled `tools/godot/userdata` and passing one flag after `--`: `--phase9-slice`, `--phase9-reload`, `--phase9-stories`, `--phase9-stories-reload`, `--phase9-events`, `--phase9-events-reload`, `--phase9-acceptance`. Run fresh-load flags in separate processes after their fixture-producing runs. `--phase9-portraits` rebuilds portraits and requires a subsequent editor import. Logs are in workspace `downloads`; images are in `docs/screenshots`. Personal saves are not test outputs.

The graphical acceptance run checks imported portraits/animations, actual movement input, mounted following, floating-origin shifts, a billion-chunk transition, home entry/exit, down/revive, inventory ownership and faction equipment. Event checks cover all eight outcomes, actual escort movement, camera/context spawn rules, expiration, reward uniqueness, bounded storage, malformed saves and fresh-process partial combat reconstruction. Additional flags --phase9-polish, --phase9-camera and --phase9-camera-reload exercise the 720p UI, camera containment, horizon rays, all four draw-distance presets, incomplete chunks, rendered blur/focus detail, protected camp placement, clearance and fresh-process persistence. The camera test produces the fixture consumed by its reload flag.

## Practical scope

This is a local single-player prototype, with one active companion and a complete first story act. Companion navigation uses a bounded local grid with safe hidden recovery, rather than a world-spanning navmesh. Important companions use real KayKit skeletal models; the player and ordinary residents retain the existing LPC rendering pipeline. The hand silhouette follows combat role, while gear statistics and affixes can change. Text is English and barks are text-only. Event templates are deliberately compact. Terrain/scenery draw calls still dominate on integrated graphics; use the existing graphics presets. GUI checks used the Dummy audio driver because the host audio output was unavailable; audible playback is not claimed as verified.

The version 0.8 baseline archive remains preserved. The 0.9 package includes source project, local engine, runtime assets, licenses, tests and documentation; it excludes personal saves and editor caches.

## Completed validation results

570 assertion executions passed across 11 completed runs, with no script/engine errors or warnings in their final logs. Individual checks are in [the test index](PHASE_9_TEST_RESULTS.json).

| Run | Passed | Failed |
| --- | ---: | ---: |
| [First companion slice](PHASE_9_SLICE_TESTS.json) | 52 | 0 |
| [First companion fresh reload](PHASE_9_RELOAD_TESTS.json) | 7 | 0 |
| [Complete expanded story](PHASE_9_STORIES_TESTS.json) | 215 | 0 |
| [Expanded story fresh reload](PHASE_9_STORIES_RELOAD_TESTS.json) | 40 | 0 |
| [Contextual world events](PHASE_9_EVENTS_TESTS.json) | 95 | 0 |
| [Events fresh reload](PHASE_9_EVENTS_RELOAD_TESTS.json) | 13 | 0 |
| [Companion gameplay and transitions](PHASE_9_ACCEPTANCE_TESTS.json) | 79 | 0 |
| [720p interface and input](PHASE_9_POLISH_TESTS.json) | 14 | 0 |
| [Horizon, foreground, containment and camp clearance](PHASE_9_CAMERA_TESTS.json) | 35 | 0 |
| [Camp clearance fresh reload](PHASE_9_CAMERA_RELOAD_TESTS.json) | 5 | 0 |
| Phase 8 profession/interior regression | 15 | 0 |

The clean project was imported without an editor cache and launched in a native Godot window. The release ZIP is verified entry by entry against source hashes; its receipt is beside the archive.
