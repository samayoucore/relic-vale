import fs from 'node:fs';
const write=(p,s)=>fs.writeFileSync(p,s.trim()+'\n');
const data=f=>JSON.parse(fs.readFileSync('relic_vale/data/'+f+'.json','utf8'));
const items=data('items'), weapons=data('weapons'), abilities=data('abilities'), enemies=data('enemies'), relics=data('relics');
const weaponRows=Object.values(weapons).map(w=>`| ${w.display_name} | ${w.archetype} | ${w.anticipation.toFixed(2)} / ${w.impact.toFixed(2)} / ${w.recovery.toFixed(2)} s | ×${w.damage_multiplier} | ${w.range} |`).join('\n');
const abilityRows=Object.values(abilities).map(a=>`| ${a.name} | ${a.cooldown} s | ${a.description} |`).join('\n');
const relicRows=relics.rates.flatMap(r=>r.items.map(id=>`| ${items[id].name} | ${r.rarity} | ${items[id].description} |`)).join('\n');
write('README.md',`# Relic Vale · 0.3

Запуск: **Launch Relic Vale.bat**. Редактор: **Edit Relic Vale.bat**. Godot и все игровые ресурсы включены; интернет и аккаунт не нужны.

Третий этап завершён поверх существующего проекта: пять типов оружия, шесть активных способностей, эффекты состояний, восемь обычных/элитных архетипов врагов и двухфазный босс. Есть экипировка со случайными модификаторами, 25 реликвий, создание внешности, звук, музыка и сохранения версии 3 с переносом версии 2.

**WASD** — идти, **Shift** — бежать, **Ctrl** — уклониться, **Space / ЛКМ** — атаковать, **E** — взаимодействовать, **1 / 2** — способности. **B** — выбрать способности, **I** — экипировка, **C** — внешность, **H** — зелье. **Q / R / ПКМ** — камера; колесо — масштаб. **J** — задания, **Tab** — карта, **F6 / F9** — сохранить / загрузить, **Esc** — меню и громкость, **F3** — инструменты разработчика.

Начните с имени и внешности, поговорите с Роуэном у колодца и возьмите припасы. Все пять учебных видов оружия уже в сумке. Побеждайте слизней на восточной дороге, собирайте выпавшие предметы, усиливайте снаряжение и отправляйтесь в склеп. Игра продолжает последнее сохранение; Esc → New World начинает новый путь.

[Инструкция](relic_vale/README.md) · [Отчёт этапа 3](relic_vale/docs/PHASE_3.md) · [Проверки новых систем](relic_vale/docs/PHASE_3_TEST_RESULTS.md) · [Проверки прежнего игрового цикла](relic_vale/docs/PHASE_3_REGRESSION_RESULTS.md) · [Лицензии](relic_vale/docs/ASSET_CREDITS.md)

![Relic Vale](relic_vale/docs/screenshots/phase3-village.png)
`);
write('relic_vale/README.md',`# Relic Vale · 0.3

A playable local, single-player fantasy RPG built in Godot 4.7.2 / GDScript. The existing low-poly village, pixel characters, orbit camera and finite seeded world are preserved. Phase 3 adds a complete combat → loot → equipment → relic → dungeon loop.

![Willowmere](docs/screenshots/phase3-village.png)

## Play

Double-click **Launch Relic Vale.bat** in the parent directory. **Edit Relic Vale.bat** opens the project; F5 runs Main. The official standard Windows x64 engine and all required assets are included. No account, internet, .NET or extra downloads are required.

The launchers set APPDATA for their child process only. Runtime saves stay in tools/godot/userdata; the existing system Godot installation and global environment are unchanged. Scenery is assembled at runtime from editable scripts, asset scenes and reusable POI scenes. Run Main to see the complete world.

## Controls

| Action | Keys / mouse |
| --- | --- |
| Move relative to camera | WASD / arrows |
| Run / dodge | Shift / Ctrl |
| Primary attack | Space in facing direction; left click aims at ground cursor |
| Equipped abilities | 1 / 2 |
| Ability loadout / appearance | B / C |
| Interact / drink tonic | E / H |
| Inventory / quest journal / atlas | I / J / Tab |
| Camera orbit | Q / R, Alt+E clockwise, RMB drag |
| Zoom / reset camera | Wheel / Home |
| Save / load | F6 / F9 |
| Pause and volume settings | Esc |
| Developer tools | F3 |
| Pixel/crisp mode / fullscreen | P / F11 |

Menus stop movement and combat. The action strip and menu controls support the mouse. B assigns any two of the six abilities; changing weapon suggests Warrior, Rogue, Ranger or Mage without locking your build.

## Your first journey

1. Choose a name, skin, hair and outfit palette, with an optional cloak. Randomize previews the result; Confirm applies it to every animation and your portrait. C reopens this later.
2. Speak to Rowan by the well and take the supply chest. Your satchel already contains a sword, greatsword, daggers, staff and bow to try. Bram sells replacement weapons and armor; Mira buys materials and sells tonics.
3. Follow the lanterns east and defeat five mossling slimes. Return to Rowan for 80 XP, 35 copper and one Astral Shard. Slimes respawn after 45 active seconds. J also tracks herbs, the shrine keeper and the crypt.
4. Walk over dropped loot after its brief bounce, or press E nearby. Rare and better bundles show a rarity beam. Equipment can roll Sharp, Swift, Heavy, Lucky, Vampiric, Burning and Frosted modifiers. I sorts the pack and shows the stat changes from equipping a selection; scroll its detail pane for all effects.
5. Spend earned shards at a wishing stone: Common 55%, Rare 30%, Epic 12%, Legendary 3%. A wish costs one shard, with three provided initially. The 2.4-second reveal can be skipped; rewards are committed once before the animation. Equip one relic to shape your build.
6. Explore the three biomes, camps, ponds, ruins and crypt entrances. Distance gently raises enemy levels. Gather supplies, discover landmarks for XP and defeat elites for better loot.
7. Enter the three-room Forgotten Crypt. The Hollow Knight seals the final arena and gains shockwaves, hazards and two sentinels below half health. Watch the marked ground, dodge, then strike during recovery. Victory grants its Legendary Heart and armor; the final chest and moonseed complete the original route back to Rowan.

Weapons have different anticipation, impact and recovery times, reach, damage and critical chances. Staff and bow projectiles collide with scenery. Fireball, Frost Nova, Arcane Missiles, Whirlwind, Dash Strike and Mending Light share cooldown/status infrastructure. Burn and poison tick, frost slows, stun interrupts and regeneration heals.

## World and saves

The existing seed **20260907**, 49 chunks of 32 × 32 units, 224 × 224 boundary, village, three noise-based biomes, roads, streaming and POIs remain. At most 25 chunks are retained. No bigger world or replacement terrain was introduced.

F6 / Save Game writes **version 3** local JSON. Startup, F9 and Load Game accept v3 and migrate v2 saves while preserving progress. A temporary write and previous valid backup protect against partial writes. Equipment recipes reconstruct unique affixed items before inventory/equipment restoration; unclaimed ground loot, appearance, name, ability slots and audio preferences also persist. Derived stats are recalculated. Transient combat states, projectiles, enemy HP and ordinary respawn timers reset on loading.

With the supplied launcher, the directory is **tools/godot/userdata/Godot/app_userdata/RelicValePrototype/**, containing **journey.json** and **journey.json.bak**. Copy this folder to keep a permanent backup. Save & quit and window close save first. Wishes, unique caches and quest turn-ins also request a save. Ordinary combat is saved by F6 or on exit. There is one save slot.

Esc → New World starts over and replaces the primary save; its backup is the previous successful write, not an archive. F3 is a developer panel for seeds, XP/shards, healing, god mode, gear, enemy spawning, boss reset and teleporting; its actions affect the current journey.

## Verification and implementation

- [Phase 3](docs/PHASE_3.md): systems, content tables, architecture and limitations.
- [New systems](docs/PHASE_3_TEST_RESULTS.md): 46 engine checks, also exercised with actual mouse input in a graphical run.
- [Established journey](docs/PHASE_3_REGRESSION_RESULTS.md): 78 checks preserving the previous gameplay loop.
- [Boss playtest](docs/BOSS_PLAYTEST.md): ordinary damage, level 3 build, both phases.
- [Asset sources and licenses](docs/ASSET_CREDITS.md), [next steps](docs/NEXT_STEPS.md).

From PowerShell in the parent directory:

~~~powershell
$env:APPDATA = (Resolve-Path 'tools/godot/userdata').Path
& 'tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path relic_vale --import --quit
& 'tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path relic_vale --fixed-fps 60 -- --regression-check
& 'tools/godot/Godot_v4.7.2-stable_win64_console.exe' --path relic_vale --resolution 1280x720 --fixed-fps 60 -- --phase3-test
~~~

Other suites: **--combat-check** (21), **--encounter-check** (21), **--boss-playtest** (2). Tests use isolated save files and never overwrite journey.json. Graphical runs capture PNGs in docs/screenshots; headless UI checks invoke button signals because the headless display has no pointer surface. The graphical UI suite dispatches actual mouse events.

Verified on Windows / Radeon Vega 8 / OpenGL Compatibility. A restricted-environment root-certificate-store message appears on engine startup; the offline game does not access the network. Final gameplay checks and graphical runs are inspected for script errors. The bundled runtime launches the project directly; a standalone exported game EXE is not included.

## Current limits

This is a playable prototype. Terrain stays flat and finite. Enemies use local steering/chase rather than navigation meshes, so complex obstacles can still obstruct them. Four-direction LPC character animation and simple original enemy sprites remain; the weapon overlay is a compact icon, not a complete weapon-specific animation library. Music consists of short synthesized loops. Balance is sampled with automated encounters and needs broader human playtesting across seeds and builds. There is no crafting, controller support, procedural dungeon assembly, elevation, weather or full campaign yet. No payments, online accounts or multiplayer.

The source/assets of phases 1 and 2 remain archived in **../downloads/RelicVale-v0.1-baseline.zip** and **../downloads/RelicVale-v0.2-baseline.zip**.
`);
write('relic_vale/docs/PHASE_3.md',`# Phase 3 — combat, loot and builds

Completed 2026-09-08 in the existing Relic Vale project. The pre-change project was audited and run; phase 2 passed 78 integration and 8 pointer checks. Its source/assets were archived before changes. See PHASE_3_AUDIT.md.

## Preserved and extended

Preserved: Main scene, rotating orthographic camera, low-poly Willowmere, LPC sprite compositor, 49-chunk generator, meadow/forest/ruin biomes, POI scenes, merchants, four side quests, three-room crypt, moonseed return route, streaming and recoverable saves. Phase 3 extends these systems instead of rebuilding the map.

Combat now has anticipation, a single impact, recovery, critical numbers, hit flash, recoil, sparks, distinct sounds, short local hitstop and restrained camera impulses. Audio uses 16 reusable SFX voices and one music player on separate buses. Player/enemy/projectile/status/relic code shares the combat service. Modal menus pause cooldowns, AI and statuses.

## Five weapons

| Type | Suggested build | Anticipation / impact / recovery | Damage | Range |
| --- | --- | --- | --- | --- |
${weaponRows}

Weapon profiles live in data/weapons.json. The original sword continues to work. Newly created travelers receive all five training styles; merchants also sell them for migrated characters. Ranged projectiles check physics segments against scenery and targets. Space uses facing, while left click aims at the ground cursor. Equipment displays a small held-weapon icon.

## Six active abilities

| Ability | Base cooldown | Effect |
| --- | --- | --- |
${abilityRows}

Assign two slots with B; cast with 1/2 or the action strip. No fixed classes prevent mixing. Cooldown reduction is computed from equipment. The shared status component implements timed burn, poison, slow, stun and regeneration, plus internal temporary might/shield support. Effects refresh duration and expire, rather than creating unlimited timers.

## Encounters and boss

Slimes approach and strike; wolves telegraph leaps; skeletons make slower melee attacks; archers keep distance and loose arrows; witches cast poison fans; bats circle and dive; mimics wake from a coffer disguise. Elites receive exactly one deterministic modifier: Burning, Frozen, Vampiric, Explosive or Swift. Rings, palette and labels distinguish elites.

Biomes use different encounter pools; camps, ponds and shrines add themed encounters. Ordinary enemy level increases mildly with distance and caps at 10; ruins add a small offset. Seeded placement, finite extent and clear hub roads stay intact. Enemy HP bars appear after damage or while targeted nearby; dormant mimics show a coffer label.

**The Hollow Knight** replaces the old guardian's single attack in the existing final chamber: ${enemies.guardian.hp} HP, phase I slash / locked-direction charge / marked slam, phase II radial projectiles / temporary burn zones / two skeletal sentinels. The gate seals the arena; death or leaving resets/cleans it safely. Ranged kiting prompts a charge rather than leaving the attack sequence stuck chasing. A dedicated native-resolution bar shows HP and phase. Boss victory persists and drops Legendary Heart of the Hollow Knight, affixed armor, shards, tonics and copper; the original final chest unlocks afterward.

The normal-damage level-3 sword/fireball/heal playtest defeated both phases in approximately 65 seconds before the final graphical pass. See BOSS_PLAYTEST.md for the latest measured result. This is one automated build; broader human balance testing remains necessary.

## Loot and equipment

Loot bundles bounce on the ground, can be collected with E or within 1.9 units after a brief delay, and have beams from Rare upward. One bundle displays its highest rarity. Unclaimed bundles are saved; their visual nodes stream by distance and have an active cap of 50. Collection removes the persistent record before granting rewards.

Generated equipment stores a stable unique ID and a compact base/rarity/affix recipe. Uncommon/Rare roll one modifier, Epic two, Legendary three; plain Common bases remain useful starter/shop items. Modifiers: Sharp damage, Swift speed, Heavy stronger/slower attacks, Lucky crit, Vampiric healing, Burning DOT, Frosted slow. Rarity scales base attack/defense/HP. Inventory can sort by rarity, kind or name, shows all affix descriptions, computes stat differences against the equipped slot and supports long descriptions in a scroll pane. Generated equipment can remain in a saved ground bundle before being owned.

## Relics and simple builds

The earned-shard pool contains 25 outcomes: 8 Common, 8 Rare, 6 Epic and 3 Legendary. Existing non-pool relic IDs remain valid for older saves. One relic slot is preserved. Examples include Winter Clock + Frost Nova for control, Ember Crown + Fireball for burning, Overflowing Cup + Mending Light for shields, and Wind Step + daggers for dodge follow-ups. Relic effects are implemented through the same status/hit/heal events used by ordinary gear.

| Relic | Rarity | Effect |
| --- | --- | --- |
${relicRows}

Wishes commit one shard and their result before a 2.4-second glow/rarity reveal. Skip reveals that same result; it does not reroll or charge again. Closing early leaves the owned item in inventory. Rates are displayed. Opening a shrine gently changes camera zoom and restores it on closing.

## Appearance, presentation and sound

C opens an animated preview with a 20-character name, five skin palettes, five hair palettes, five outfit palettes, cloak toggle, randomize and confirmation. The existing six LPC layers are recolored at their native pixel resolution, including face and body; original eye pixels are retained. Appearance follows idle/walk/slash and the HUD portrait. Cache replacement bounds repeated preview generation.

Native UI, dark teal panels and cream/gold typography remain. Ability cooldowns are visible on the action strip; inventory details wrap and scroll. Master, Music and SFX sliders are in Esc. Village, crypt and boss use separate original music loops. Eleven selected OGG cues were downloaded from **Kenney RPG Audio**, https://kenney.nl/assets/rpg-audio, **CC0 1.0**. Nine cues and three music loops were synthesized locally; new enemy variants, projectiles, telegraphs, icons and loot effects are original code-created assets. The adapted LPC art remains **CC BY-SA 3.0** with all original credits. See ASSET_CREDITS.md and PHASE_3_AUDIO_MANIFEST.json.

## Save compatibility and debug

Save version 3 retains every v2 progression field and adds name, appearance, ability slots, generated gear recipes, pending ground bundles and audio settings. V2 migration uses safe appearance/ability defaults, preserves owned items/currency/quests, validates equip slots, and reconstructs derived stats. Existing temp/flush/backup/recovery logic is preserved. New World clears character/world progress; debug seed regeneration keeps progress.

F3 includes seed/position/biome/FPS/chunks/drops/statuses, manual/random seeds, village/arena teleport, nearby-enemy clearing, XP/shards, generated Legendary gear, enemy selection/spawning, heal/cleanse and god mode. These tools are hidden during ordinary play and are not a separate game mode.

## Verification

- 78 established-journey checks in tests/regression_phase3.gd: movement, camera, collisions, all biomes, deterministic layout, roads, quests, loot, equipment, crypt route, unique rewards, save/backup and new world.
- 21 weapon/ability/status/audio checks in tests/combat_phase3.gd.
- 21 boss/AI/elite checks in tests/encounter_phase3.gd, including phase transitions, projectiles/hazards, safe reset and ground reward collection.
- 46 new-system checks in tests/phase3_test.gd, including generated items, saved ground loot, v2 migration, appearance, builds, shrine reveal/skip and three volume buses. Graphical execution uses real mouse events; headless UI uses button signals.
- 2 normal-damage encounter checks in tests/boss_playtest.gd; no god mode, no forced boss HP changes. Initial loadout is prepared to isolate balance.

All suites use the actual engine and main scene. Production journey.json is protected by test-mode save isolation. Final PNGs are under docs/screenshots/phase3-*. Reports document their renderer and results; logs are in ../downloads/phase3-*.log. The environment's startup root-certificate-store message is unrelated to offline gameplay.

## Practical limitations and Phase 4

Simple steering can snag on geometry; terrain is flat and the map finite. Sprites are four-direction LPC and simple original enemy art. Weapon visuals use icons and shared slash poses. Music is short synthesized ambience. No optional level-up choice screen was added; levels grant immediate stats/healing and abilities are freely selected in B. No full skill tree, crafting, procedural dungeon assembler, controller navigation, export templates or standalone game executable. Continue with navigation, human balance passes, encounter budgets, authored combat animation, crafting and a polished export before increasing map size. Detailed priorities are in NEXT_STEPS.md.
`);
write('relic_vale/docs/NEXT_STEPS.md',`# Phase 4 priorities

Phase 3 now supports combat, different weapons, six abilities, statuses, elites, a two-phase boss, affixed gear, relic builds, character palettes and migrated saves. Preserve the existing scale, palette, controls and progression loop.

1. **Navigation and encounter fairness.** Add navigation around trees/ruins, obstacle-aware leashes and LOS-aware ranged movement. Playtest several seeds and full starter journeys with human players. Tune boss recovery, potion supply, drop rates and build outliers from observed results.
2. **Combat presentation.** Replace simple enemy frames with cohesive authored directional animations, add weapon-specific attack poses and better held-item alignment. Improve music transitions and longer original ambience; add motion/screen-shake accessibility settings.
3. **Progression depth.** Add a small choice at levels 2/4/6/8/10, two additional relic combinations and clear build-stat summaries. Keep a compatibility path for v3 gear IDs and saves.
4. **Crafting and storage.** Use existing herbs, gel, pelts and bones for tonic/gear recipes at current merchants. Add storage, sale of unused equipment and explicit multiple save slots before introducing more item volume.
5. **Dungeon content.** Extend tested room/door modules into a controlled procedural assembler with encounter budgets, checkpoints, boss variants and regional quest chains. Add a few strong POIs before enlarging the world.
6. **Delivery.** Add controller/menu navigation, window-size/accessibility tests, long-run memory profiling, official export templates and a standalone Windows build. Retain offline operation and asset provenance.

Later: shallow elevation with compatible roads, day/night/weather, building interiors, fishing/gardening, companions and larger settlements. Do not introduce network services or payment systems into this local single-player project.
`);
const creditPath='relic_vale/docs/ASSET_CREDITS.md';
let credits=fs.readFileSync(creditPath,'utf8');
if(!credits.includes('Phase 3 appearance and enemy variants')) credits+='\n\n### Phase 3 appearance and enemy variants\n\nSkin (body and modular face), hair and outfit recoloring and cloak selection are runtime adaptations of the same credited LPC layers. These adapted sprites remain under CC BY-SA 3.0; no extra LPC download or new attribution source was introduced. Bat, archer, witch, mimic, elite and larger crowned boss variants are original GDScript pixel drawings. Synthesized WAV cues/music and procedural VFX are project-authored work without third-party samples. Original download archives and exact pack license remain available locally.\n';
write(creditPath,credits);
write('relic_vale/docs/PHASE_3_WORKLOG.md',`# Phase 3 implementation record

- Audited and ran the completed v0.2 project; saved its source/assets archive.
- Added shared combat, projectile, status and feedback components; verified five weapons and six abilities.
- Extended enemy minds, biome encounters, elite modifiers and the existing final-room boss.
- Added physical persistent loot and unique affix recipes, then migrated save v2 to v3.
- Added appearance preview/name/palettes, ability loadout, inventory sorting/comparison, shrine buildup/skip and audio sliders.
- Fixed a freed-instance lookup in ground-loot streaming, revived-enemy death tweens, stale boss gates on load, status iteration during respawn and audio shutdown timing.
- Re-ran the 78-check established route. Ran 46 new-system checks with pointer events in the graphical main scene. Checked all combat/encounter suites and a timed boss fight with ordinary damage.
- Inspected graphical screenshots and corrected skin/head consistency, preview selector synchronization, portrait/name updates, wrapped ability descriptions, current shrine shard count and version footer.
- Updated launch/readme guidance, sources/licenses and Phase 4 priorities. Gameplay source, reusable scenes, assets, isolated tests and logs remain in the existing workspace.
`);
console.log('Phase 3 documentation updated.');
