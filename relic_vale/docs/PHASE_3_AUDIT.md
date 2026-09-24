# Phase 3 starting audit

Phase 2 was completed before this phase began. Its source, data, assets, scenes, screenshots and documentation are preserved in `../downloads/RelicVale-v0.2-baseline.zip`.

The current project was inspected and run headless and graphically with Godot 4.7.2. The complete integration journey passed 78 checks, including movement/camera, deterministic three-biome streaming, combat/loot/equipment, all four quest conditions, three-room dungeon traversal, unique rewards, shrine effects, save/load/backup recovery and New World. Eight additional pointer-driven checks passed for equipment, trading, wish animation and duplicate-input protection. Screenshots of gameplay and every main menu were inspected.

## Extend these systems

- Keep the LPC compositor, 2D billboards, handcrafted village, pixel viewport, native HUD, lighting and rotatable camera.
- Extend the existing player attack with anticipation, impact and recovery. Add a shared status component, small reusable VFX/audio service and projectile scene.
- Use existing item/equipment IDs, adding weapon profiles and unique affixed item instances rather than a second inventory.
- Extend the same enemy controller and JSON data with ranged, circling, dormant and boss behaviors. Preserve its death/XP/quest hooks.
- Keep the 224-unit finite world, adding seeded encounters and mild distance difficulty to existing chunks. Do not expand the map.
- Extend the Cryptwarden into a telegraphed, two-phase encounter in the current final room.
- Extend the relic data and equip/proc hooks, keeping earned shards and local-only rolls.
- Add palette customization to the existing LPC layers, retaining their attribution.
- Migrate version-2 saves when adding appearance, abilities and affixed items. Existing story, quest, unique-reward and world IDs must remain valid.

## Gaps addressed this phase

The current sword hits immediately with one profile. There are no ranged weapons, abilities, shared statuses, ground pickups, audio, affixes or appearance controls. Wolves and skeletons have distinct stats but mostly share chase behavior; the current guardian has one melee attack. Relics have seven functional summon outcomes. Inventory lacks comparison/sorting. These are extension points, not reasons to rebuild working systems.

## Implementation order

Combat timing/feedback and audio → weapon profiles/projectiles/six abilities → enemy behavior and elites → readable boss phases → physical affixed loot and builds → expanded relic pool/reveal → character appearance and creation → inventory/ability/debug UI → save migration, full integration and final visual/audio review.
