# Phase 2 starting audit

The original project was inspected and run before phase 2 changes. A source-and-assets snapshot is preserved at `../downloads/RelicVale-v0.1-baseline.zip`.

## Working baseline

- Godot 4.7.2 standard / GDScript / OpenGL Compatibility, verified on Radeon Vega 8.
- A handcrafted village, connected forest, entrance, and small crypt.
- Camera-relative accelerated movement, collision, four-direction LPC animation, smooth orbit and zoom, RMB rotation, a 50-degree fixed pitch, and pixel/crisp rendering modes.
- NPC dialogue, one-time supplies, consumables, a free relic, melee combat with windup/knockback, XP, a moonseed delivery quest, and safe respawn.
- Readable native HUD/nameplates, minimap, inventory, dialogue, and pause.
- All asset sources and licenses are recorded. No asset-download blockers.
- 32 baseline integration checks passed. Seven rendered screenshots were inspected.

## Gaps and safe extension points

- The map has fixed outer collision walls; these must give way to finite generated territory while preserving its hub and original trail.
- The old crypt lives at x=110, which would collide with an expanded overworld. Move only the interior to a distant reserved coordinate and preserve its existing room as the first room.
- `world.gd` already has reusable model-placement and simple geometry helpers. Extend their optional parent support so chunk roots can own and unload their content.
- The sprite compositor and current controller remain useful. Add dodge and camera obstruction handling without replacing them; four directions are the best supported source art.
- Enemy parameters and loot are hardcoded. Extend the existing enemy scene with data-driven archetypes instead of adding unrelated controllers.
- State owns session flags and inventory. Extend it with computed stats, equipment, quests, persistent IDs and versioned save data.
- The current XP handler supports only one level per call. Use a loop for larger rewards.
- Shrine weights are duplicated in code and item data. Consolidate them into an explicit summon table.
- The inventory is a list with no selection/equipment. Replace only its contents with an icon grid, details, and slot controls while retaining the HUD style and modal behavior.
- There are no critical gameplay errors in the baseline. The restricted Windows environment reports a root-certificate-store error at engine startup; gameplay is offline and unaffected.

## Implementation order

1. Preserve controls/visuals; add dodge and obstruction handling.
2. Seeded, finite 32-unit chunks with noise biomes, authored POI templates, connected roads, and safe hub exclusions.
3. Verify streamed exploration visually before extending menus.
4. Enemy archetypes, stats, loot, inventory and equipment.
5. Versioned local saves.
6. NPC/quest foundation, expanded crypt, earned-shard summons.
7. Full gameplay regression, deterministic-generation/save tests, screenshots, and documentation.
