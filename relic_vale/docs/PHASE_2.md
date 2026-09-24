# Phase 2: a world to return to

This phase extends the working visual prototype. The baseline was inspected, run, tested and archived before edits; see PHASE_2_AUDIT.md. The village layout, imported packs, LPC compositor, pixel viewport, native HUD, warm/cool lighting and moonseed story remain.

## Generation and streaming

ValeGenerator in scripts/world_generation/world_generator.gd owns pure deterministic layout data. The 7 × 7 finite map uses 32-unit chunks at coordinates -3 through 3. FastNoiseLite layers choose biomes (frequency .012, three octaves), vegetation density (.055) and ground/road variation (.032). Seeded local RNGs are salted per chunk, so runtime combat RNG and chunk load order do not affect placement. Same seed plus the same generator version recreates the same layout.

The original 74 × 62 hub footprint is protected. Trees have minimum 4.5m spacing within a chunk and inset margins across seams. Bushes and stones cluster around trees; rocks and flowers form small groups. Props avoid hub margins, POI clearings and road corridors. Enemies use biome-specific tables and avoid both the safe spawn and tree trunks. Ranked noise anchors ensure all three biome types, even for seeds with narrow noise ranges.

Five reusable scenes under scenes/poi define an abandoned camp, ruined tower, woodland shrine, quiet pond and crypt entrance. Their relative arrangements are authored; their positions and presence are seeded. Ruins can contain an elite, while caches, silverleaf and discoveries use stable IDs. Rare entrance placement always includes at least two generated crypt entrances. Each POI's southern access connects into a nearest-neighbor road network with mild noise bends; road ribbons are clipped per chunk. Ground colors interpolate neighboring biome palettes. A batched rocky rim and simple bounds enclose the world.

The player activates a radius of one chunk (up to 9). Chunks beyond radius two unload, providing hysteresis and a 25-chunk ceiling. A pending queue builds one chunk every two rendered frames; initial generation, explicit teleports and load use synchronous creation. Pure layout stays in memory. Noninteractive vegetation/rocks use per-mesh MultiMesh batches; trees retain individual trunk colliders and fadeable visuals. Only significant scenery has physics. Interiors use reserved x≈1000 coordinates, avoiding the expanded overworld.

F3 shows seed, coordinates, current chunk/biome, FPS and active count. Regenerate/random seed keep progression, Village returns safely, and Clear enemies grants no rewards. Esc → New World resets progression and writes the new seed. Tab shows the complete finite atlas and live position.

## Controls and camera

The existing accelerated, camera-relative CharacterBody3D movement and LPC idle/walk/slash remain. Ctrl adds an 0.18s directional dash, 1.15s recovery and brief invulnerability. Four sprite directions are the available art's best supported orientations. Q/R, Alt+E or RMB smoothly orbit; wheel zoom is clamped 12–32; Home restores the 42° default yaw and zoom 24. The pitch remains 50°. Ray checks fade tagged foreground buildings/walls and preserve character visibility. Menus block movement and enemy combat.

## Combat, stats and loot

data/enemies.json configures slow slimes, fast wolves and stronger skeletal sentinels, plus a unique Briar elder and the Cryptwarden. The existing controller now reads HP, attack, speed, detection, range, windup, cooldown, XP and respawn from data. Enemies chase, telegraph, strike, take knockback and die. Normal enemies respawn after active-time cooldowns; unique deaths persist. Normal state resets on chunk reload.

State.stats() computes Level, XP, Max HP, Attack, Defense, Move Speed and Critical Chance. Base HP is 100 with +10 per level; base attack 10 with +3 per level plus equipped weapon; defense gains 1 per level; speed is 5; base critical chance 5%. A critical hit deals 1.5× physical damage. Defense reduces incoming damage with a minimum of 1. XP requirement is level × 60, and large rewards can advance several levels. Level-up fully restores HP. Defeat returns the player to Willowmere without destroying possessions.

data/loot_tables.json supplies independent drop probabilities and coin ranges for enemies and chests. ValeLoot rolls a reusable bundle and grants it with automatic collection and a visible sparkle/notification. Common, Uncommon, Rare, Epic and Legendary colors appear consistently in the UI. Unique chest contents use stable IDs and seeded rolls; opening persists before another interaction can repeat the reward.

## Inventory, equipment and NPCs

data/items.json contains consumables, materials, weapons, armor, accessories, relics and the moonseed. PixelArt produces small original icons cached by shape/color. The inventory is a scrollable five-column grid with counts, rarity borders, hover text, a detail card, equip/use controls, character statistics and five slots. Inventory includes equipped items; the E marker identifies them. Bonuses are applied only from occupied equipment slots. One relic is active at once.

The shared ValeInteractable scene handles NPCs using npc_id and data/npcs.json (name, role, dialogue, shop/quest flags). Rowan gives quests, Bram sells equipment, Mira buys materials/sells tonics, and Elowen explains the shrine. Merchants have simple functional stock rather than a full economy.

## Quests and exploration

data/quests.json declares kill, collect, talk and reach conditions. State.quest_event updates accepted tasks, clamps counters and excludes completed tasks. Rowan accepts all four starter tasks. Trouble in the Woods requires five slime kills and grants 80 XP, 35 copper and 1 shard once. Herbs, meeting Elowen and entering the crypt demonstrate the remaining condition types. J lists progress and whether rewards await Rowan. The original moonseed delivery uses its preserved story flags and remains a separate complete journey.

First POI discovery grants 10 XP. Caches offer equipment, tonics, copper and shards; hidden silverleaf can be collected once per world; ruined towers may have a unique elite. Stable seed/POI IDs preserve these outcomes through unload and save/load.

## Forgotten Crypt

The original entrance chamber is preserved, moved away from the overworld, and connected to the authored scenes/dungeons/ForgottenCrypt.tscn extension. A gallery and final reliquary form three connected rooms with clear doorways, several skeletal enemies, blue lamps, columns, rubble, a moonseed altar and a stronger 230-HP Cryptwarden. The final chest remains sealed until the guardian falls and grants a rare blade, relic, copper and shards. The warden drops Epic armor. All entrances lead to this same dungeon; the stairway returns to the entrance actually used. Boss and final treasure are unique per journey.

## Shrine

data/relics.json holds cost and all rarity weights: Common 55, Rare 30, Epic 12, Legendary 3. Players start with 3 earned-gameplay shards; more come from quests, drops and caches. The shrine heals for free; a wish costs 1 shard. The result is added and a save requested before its glow/reveal animation. Duplicate presses during the animation are blocked, and closing early cannot refund the cost. Duplicates stack. The result card offers Equip relic.

Traveler's Coin gives +3% speed; Ember Ring adds 8% attack as fire damage; Hunter's Eye adds 5% crit; Moonstone Heart adds 15 HP and 5% crit; Storm Charm has 10% chance for +8 damage per swing; Heart of the Fallen King has 20% chance on a kill to reset attack cooldown; Echo of the Void adds a 50%-attack pulse within 3.4m every fifth swing. The original three prototype charms remain supported as equippable items. Fire/lightning are additional damage effects; enemies do not yet have elemental resistance tables. The system is entirely local with no payments or services.

## Persistence

scripts/save/save_system.gd uses version-2 UTF-8 JSON in user://journey.json. A temporary write is flushed before replacement; a previous valid save is copied to .bak. Invalid primary data can recover from the backup. Unsupported versions are refused, malformed structures are checked, item IDs/slots are validated, numbers are clamped and derived stats are recomputed. Safe position bounds cover the overworld and crypt. There is one save slot.

The save includes position, dungeon return, world seed, level/XP/HP, derived stats, inventory/equipment, coins/shards, attack counter, story flags, accepted/completed quests, discovery/resource/chest IDs and unique enemy deaths. Startup restores a valid save. F6/F9 and pause provide explicit save/load. Exit, wishes, caches and side-quest claims save as described in README. Normal enemy state is deliberately ephemeral. Tests use a separate file and suppress production autosaves.

## Verification and remaining limits

See PHASE_2_TEST_RESULTS.md and UI_TEST_RESULTS.md for current real-engine results, plus docs/screenshots/phase2-*.png for inspected visual evidence. The integration journey tests movement, collision, orbit/zoom/dash, three biomes, chunk bounds/determinism, road traversal, each enemy archetype, XP/loot, equipment, all quest event types, shrine economy/effects, three-room traversal, boss/treasure, original story, save/reload/backup and New World. The mouse suite tests equip/unequip, wish animation/double click protection and shop buttons.

Known limits: finite flat terrain; simple direct-chase AI; four-direction art; basic original enemy placeholders and icon shapes; no audio or full combat animation hit phases; a shared handcrafted dungeon rather than procedural interiors; one save slot; ordinary enemy reset on streaming; no crafting, character creator or village interiors. These are documented prototype boundaries, not missing dependencies.
