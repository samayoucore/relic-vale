# Phase 6 audit, 9 September 2026

Baseline: verified v0.5 archive. The Godot project runs offline with a streamed 3D environment and LPC billboard characters. The player has no humanoid skeleton; imported humanoid animation libraries cannot directly animate its sprite. Keep its directional attack frames and attach imported tool meshes to a camera-relative hand pivot with explicit wind-up, impact and recovery tracks.

Resources previously were invisible one-click markers beside instanced scenery, with boolean save flags and no physical depletion. Trees were scenery only. Replace resource-owned props before batching, retain stable legacy identifiers, add hit state and renewable depletion timestamps.

Equipment has no tool slot or durability. Add a tool slot and three simple power tiers; durability is out of scope. Existing material sale prices depend on merchant offer lists and otherwise default to ten copper. Centralize item-aware prices and specialist demand.

Buildings currently have solid exteriors with no entrances. Five authored Willowmere buildings can host house, general shop, forge, tavern and alchemist templates. Stream only the active interior in reserved space, store its logical exterior address, suspend exterior simulation and restore it on exit. Preserve the existing crypt and expeditions.

Existing NPC schedules use four waypoint positions and hide residents at home. Extend them with stable resident records, building destinations, occupied activity anchors, observable work/social/rest states and time-based reconstruction after unloading. Generated settlements currently reuse quest NPC IDs and need unique identities outside authored settlements.

Deer and stags already use imported skeleton clips, but their AI is a sinusoidal wander/graze loop and wildlife is too frequent. Reuse the independent fauna component with explicit states, group homes, distance-based updates and settlement farm populations.

Baseline validation: Phase 5 GUI presentation, camera pitch/occlusion, continuous walking across eleven chunks, far dungeon return, save reload, 100-step streaming stress and combat regression all pass. Preserve these checks while adding gathering, economy, interiors and living-world acceptance coverage.
