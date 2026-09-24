import fs from 'node:fs';
const root='relic_vale/';
let hud=fs.readFileSync(root+'scripts/hud.gd','utf8');
hud=hud.replace(/func populate_inventory\(\) -> void:[\s\S]*?(?=func show_pause)/,'func populate_inventory() -> void:\n\trpg.inventory()\n\n');
fs.writeFileSync(root+'scripts/hud.gd',hud);
let state=fs.readFileSync(root+'scripts/game_state.gd','utf8');
state=state.replace('## Small session state. World nodes own behavior; this owns progression and UI events.','## Progression, computed equipment stats, quest events and UI signals. Serialized by ValeSave.');
fs.writeFileSync(root+'scripts/game_state.gd',state);
let launch=fs.readFileSync('Launch Relic Vale.bat','utf8');
launch=launch.replace('--import\n','--import --quit\n');
fs.writeFileSync('Launch Relic Vale.bat',launch);
const readme=`# Relic Vale · 0.2

A playable local, single-player fantasy RPG in Godot 4.7.2 / GDScript. The original low-poly village, pixel characters and rotating camera now sit inside a finite seeded wilderness.

![Willowmere](docs/screenshots/phase2-village.png)

## Play

Double-click **Launch Relic Vale.bat** in the parent folder. The official standard Windows x64 Godot runtime and every required asset are included. No account, internet, .NET or asset downloads are needed. **Edit Relic Vale.bat** opens the existing project in Godot; F5 runs it.

The launchers set APPDATA only for their child process, placing runtime data inside tools/godot/userdata. They do not change the system environment or your existing Godot installation. The editor is self-contained. Scenery is assembled at runtime from editable scripts, asset scenes and reusable POI scenes; run Main to see the complete world.

## Controls

| Action | Keys / mouse |
| --- | --- |
| Move relative to camera | WASD / arrows |
| Run / dodge | Shift / Ctrl |
| Strike / interact | Space or left click / E |
| Orbit | Q / R, Alt+E clockwise, or RMB drag |
| Zoom / reset camera | Mouse wheel / Home |
| Inventory and equipment | I |
| Drink tonic | H |
| Quest journal / world atlas | J / Tab |
| Save / load | F6 / F9 |
| World debug and seed | F3 |
| Pixel / crisp presentation | P |
| Fullscreen / pause | F11 / Esc |

E remains the established interaction key. Q/R are the primary orbit keys; Alt+Q/Alt+E also provide a Q/E fallback. Menus pause movement and combat. The action strip and menu buttons support the mouse.

## Start your journey

1. Talk to Rowan beside the well. Take the supply chest's two tonics and 25 copper.
2. Meet Bram the blacksmith, Mira the merchant and Elowen the shrine keeper. Bram sells a blade and vest; Mira sells tonics and buys materials.
3. Follow the lanterns east. Defeat five mossling slimes in Mossfall Wood or Briar Meadow, then return to Rowan for **80 XP, 35 copper and 1 Astral Shard**. Slimes respawn after 45 active seconds.
4. Open I, select an item and equip it. Your five slots are Weapon, Head, Body, Accessory and Relic. Only equipped items grant bonuses.
5. Visit a wishing stone to heal. Spend earned shards for relics: **Common 55%, Rare 30%, Epic 12%, Legendary 3%**. One wish costs one shard. Three shards are provided at the beginning. Duplicates stack; one relic may be worn.
6. Explore roads, camps, ponds, ruins, hidden silverleaf and rare dungeon entrances. First discoveries grant XP; caches and elites reward supplies and shards.
7. Enter the Forgotten Crypt from the original forest entrance or a generated stairway. Explore three connected rooms, defeat the Cryptwarden, open its treasure and recover the moonseed. The exit returns to the doorway you used. Bring the moonseed to Rowan.

J also tracks gathering three herbs, meeting the keeper and reaching the crypt. Return to Rowan to claim completed tasks. Enemy loot is collected automatically on defeat, with a visible burst and a summary; equipment, materials and shards go straight into your inventory.

## World and saves

The default seed is **20260907**. There are 49 chunks, each 32 × 32 units, covering 224 × 224 units. A handcrafted safe hub is surrounded by meadow, forest and ruined biomes selected with FastNoiseLite. Density noise shapes vegetation groups; clearings and paths connect authored POI scenes. Decorative plants and rocks use MultiMesh batches. Nine nearby chunks are initially loaded, with a one-chunk unloading margin; at most 25 remain active. New chunks are built over successive frames.

**Esc → New World** accepts a seed and resets the journey. **F3 → Generate seed** is a developer tool that changes the terrain while keeping the character's progress; Village and Clear enemies are also available. A rocky perimeter marks the finite boundary.

**F6** or **Esc → Save Game** writes a local version-2 JSON save. **F9** or **Load Game** restores it. Normal startup resumes a valid saved journey. Save & quit and the window close button save before exiting; if saving fails, the game stays open and reports it. Wishes, unique caches and claimed side quests also request a save. Ordinary movement/combat is saved by F6 or on exit, not continuously.

With the supplied launcher, saves are under **tools/godot/userdata/Godot/app_userdata/RelicValePrototype/**. The primary file is **journey.json**, with a previous valid **journey.json.bak** and a temporary file during writes. The game validates input, recomputes derived equipment stats and can recover a damaged primary from the backup. Copy this folder to keep your progress. A New World replaces the primary; the backup is the previous successful save, not a permanent archive.

Saved: seed, position and dungeon return point, level/XP/HP, computed stats, inventory, equipment, copper, shards, story flags, quest progress/completions, discoveries, gathered resources, opened unique caches and defeated unique enemies. Ordinary enemy health and respawn timers reset when chunks reload. There is one local save slot. Phase 1 had no saves to migrate.

## Implementation and verification

- [PHASE_2.md](docs/PHASE_2.md): generation, gameplay, data files, persistence and implementation details.
- [PHASE_2_TEST_RESULTS.md](docs/PHASE_2_TEST_RESULTS.md): full real-engine integration journey.
- [UI_TEST_RESULTS.md](docs/UI_TEST_RESULTS.md): real mouse input, equipment, trades and summon animation.
- [PHASE_2_AUDIT.md](docs/PHASE_2_AUDIT.md): audit before changes.
- [ASSET_CREDITS.md](docs/ASSET_CREDITS.md): sources and licenses.
- [NEXT_STEPS.md](docs/NEXT_STEPS.md): future development priorities.

From PowerShell in the parent folder:

~~~powershell
$env:APPDATA = (Resolve-Path 'tools/godot/userdata').Path
& 'tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path relic_vale --import --quit
& 'tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path relic_vale --fixed-fps 60 -- --phase2-test
~~~

Omit --headless and add --resolution 1280x720 to render the integration journey and its screenshots. Use --ui-check instead of --phase2-test for the mouse-driven presentation checks. Tests use an isolated phase2-test.json and never overwrite journey.json. The old --smoke-test entry point runs the updated integration suite. The original 32-check baseline report and source archive remain available.

Verified with the bundled engine on Windows 10 / Radeon Vega 8 / OpenGL Compatibility. During the initial three-biome capture, batching reduced loaded node counts from roughly 2,900–3,900 to 1,700–1,900; the expanded dungeon adds a modest fixed node cost. Around 29–30 FPS was observed on this machine in the capture configuration, not a guarantee for other hardware. No gameplay script errors remained in the verified runs. The restricted Windows environment logs a root-certificate-store warning at startup; the game does not use networking.

## Current limits

This is an RPG foundation, not a finished campaign. Terrain is flat with blended biome colors and clustered scenery, and the world is finite. AI uses direct chase/leash behavior and can be obstructed by complex geometry. Characters have four supported animation directions; wolf/skeleton icons and sprites are original simple pixel placeholders. Combat uses an immediate melee hit with a cooldown, not a detailed hitbox animation system. There is no audio, crafting, procedural dungeon generation, day/night, character creator or building interiors yet. Shrine results are local earned loot; there are no purchases, servers or real-money systems.

The phase-1 source and assets are preserved in **../downloads/RelicVale-v0.1-baseline.zip**. This phase extends that project rather than replacing it.
`;
fs.writeFileSync(root+'README.md',readme);
fs.writeFileSync('README.md',`# Relic Vale · 0.2

Запуск: **Launch Relic Vale.bat**. Редактор: **Edit Relic Vale.bat**.

Готова локальная одиночная RPG: исходная деревня, процедурный мир по seed, три биома, бой, добыча, экипировка, задания, святилище реликвий и трёхкомнатный склеп.

**WASD** — движение, **E** — взаимодействие, **Space** — удар, **Q / R** — камера, **Ctrl** — рывок. **I** — инвентарь, **J** — задания, **Tab** — карта. **F6 / F9** — сохранить / загрузить, **Esc** — меню, **F3** — seed и отладка.

Начните с разговора с Роуэном у колодца. Игра продолжает последнее сохранение; новый мир создаётся через Esc → New World.

Godot и все необходимые ресурсы уже включены. Интернет и аккаунт не нужны.

[Подробная инструкция](relic_vale/README.md) · [Описание фазы 2](relic_vale/docs/PHASE_2.md) · [Проверки](relic_vale/docs/PHASE_2_TEST_RESULTS.md)

![Relic Vale](relic_vale/docs/screenshots/phase2-village.png)
`);
fs.writeFileSync(root+'docs/PHASE_2.md',`# Phase 2: a world to return to

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
`);
fs.writeFileSync(root+'docs/NEXT_STEPS.md',`# Relic Vale roadmap after phase 2

The current milestone is playable: procedural exploration, equipment, quests, a complete crypt and local persistence. Preserve the village scale, palette, camera and readable native UI.

## Next practical milestone

1. Improve combat feedback: footsteps, ambient loops, strike/hit/UI sounds, a timed weapon hit phase, clearer enemy windup indicators and improved directional enemy sprites. Keep controls responsive.
2. Add navigation for wolves and sentinels around ruins; introduce encounter budgets and stronger leash/return behavior. Playtest balance using ordinary progression and several seeds.
3. Improve terrain and exploration: more natural road edges, shallow elevation, richer biome transitions, clear world boundaries, authored merchant camps and additional POI compositions. Then add towns in generated regions.
4. Add crafting using existing herbs, gel, pelts and bones. Start with tonic and equipment recipes at the current merchants; add storage and save slots with migration/version tests.
5. Expand the crypt with a boss attack pattern and authored encounter variations, then build procedural dungeon assembly from the tested room/door modules.

## Later systems

- Farming, gardening, resource gathering professions and fishing at ponds.
- Day/night, gentle weather, regional ambience and NPC schedules.
- LPC-based character customization with attribution retained for each selected layer.
- Skills and classes built around the existing stats, equipment and relic effects.
- Mounts and companions once larger terrain and navigation are stable.
- More bosses, relic synergies, regional quest chains and building interiors.
- Better world generation with elevation-aware roads, watercourses, biome ecotones and towns.

## Delivery and stability

Add official export templates and an exported Windows build when content stabilizes. The included engine launcher already works offline. Verify a clean import, test backups and save migrations, profile chunk creation on slower hardware and add an adjustable draw radius only when it is needed. Keep unique rewards stable across streaming. Avoid multiplayer, payment systems and service dependencies; this project remains a local single-player journey.
`);
fs.writeFileSync(root+'docs/PHASE_2_WORKLOG.md',`# Phase 2 work log

- Completed and preserved phase 1: playable prototype, all requested packs, 32 baseline checks, credits and seven original screenshots.
- Archived source/assets in ../downloads/RelicVale-v0.1-baseline.zip; audited and ran the project before incremental edits.
- Improved dash and camera obstruction handling while preserving movement, sprites, village and visual style.
- Added deterministic finite generation, three biomes, reusable POIs, roads, streaming, MultiMesh decoration and debug seed controls. Inspected actual biome renders before building menus.
- Added configurable enemies, computed RPG stats, loot, grid inventory and five equipment slots.
- Added versioned saves with backup recovery and a New World flow.
- Added four NPC roles, basic shops, four quest condition types, discovery/resources, elite rewards, and an expanded three-room crypt with a unique guardian.
- Added earned-shard shrine rates, actual relic bonuses/procs and an animated result card.
- Ran the full integration journey headless and with OpenGL; repaired a procedural road approach issue and verified the route again.
- Inspected screenshots of the village, each biome, inventory, quest log, atlas, shrine result and dungeon. Verified mouse-driven equipment/trades/summon and documented the finished phase.

Current reports: PHASE_2_TEST_RESULTS.md and UI_TEST_RESULTS.md.
`);
let credits=fs.readFileSync(root+'docs/ASSET_CREDITS.md','utf8');
if(!credits.includes('Phase 2 original artwork')) credits+='\n## Phase 2 original artwork\n\nThe wolf, skeleton/guardian variants, inventory icon shapes, loot sparks, map drawing, road meshes and generated POI arrangements are original code-created additions in this project. No new third-party art packs or external services were introduced in phase 2. The existing LPC and scenery attributions above still apply.\n';
fs.writeFileSync(root+'docs/ASSET_CREDITS.md',credits);
console.log('Phase 2 documentation updated; obsolete inventory implementation removed.');
