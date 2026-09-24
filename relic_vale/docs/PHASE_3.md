# Phase 3 — combat, loot and builds

Completed 2026-09-08 in the existing Relic Vale project. The pre-change project was audited and run; phase 2 passed 78 integration and 8 pointer checks. Its source/assets were archived before changes. See PHASE_3_AUDIT.md.

## Preserved and extended

Preserved: Main scene, rotating orthographic camera, low-poly Willowmere, LPC sprite compositor, 49-chunk generator, meadow/forest/ruin biomes, POI scenes, merchants, four side quests, three-room crypt, moonseed return route, streaming and recoverable saves. Phase 3 extends these systems instead of rebuilding the map.

Combat now has anticipation, a single impact, recovery, critical numbers, hit flash, recoil, sparks, distinct sounds, short local hitstop and restrained camera impulses. Audio uses 16 reusable SFX voices and one music player on separate buses. Player/enemy/projectile/status/relic code shares the combat service. Modal menus pause cooldowns, AI and statuses.

## Five weapons

| Type | Suggested build | Anticipation / impact / recovery | Damage | Range |
| --- | --- | --- | --- | --- |
| Sword | Warrior | 0.09 / 0.06 / 0.33 s | ×1 | 2.4 |
| Greatsword | Warrior | 0.25 / 0.10 / 0.54 s | ×1.65 | 3.2 |
| Daggers | Rogue | 0.04 / 0.04 / 0.19 s | ×0.65 | 1.75 |
| Staff | Mage | 0.16 / 0.05 / 0.44 s | ×1.1 | 12 |
| Bow | Ranger | 0.18 / 0.04 / 0.39 s | ×1.05 | 16 |

Weapon profiles live in data/weapons.json. The original sword continues to work. Newly created travelers receive all five training styles; merchants also sell them for migrated characters. Ranged projectiles check physics segments against scenery and targets. Space uses facing, while left click aims at the ground cursor. Equipment displays a small held-weapon icon.

## Six active abilities

| Ability | Base cooldown | Effect |
| --- | --- | --- |
| Whirlwind | 6 s | Sweep every enemy around you. A broad physical strike. |
| Dash Strike | 8 s | Rush forward with brief protection, then deliver a heavy strike. |
| Fireball | 5 s | Launch an ember that explodes and burns nearby foes. |
| Frost Nova | 9 s | A ring of frost damages and slows nearby enemies for four seconds. |
| Arcane Missiles | 7 s | Three quick bolts fan toward enemies ahead of you. |
| Mending Light | 12 s | Restore 25% maximum HP, then regenerate another 12% over three seconds. |

Assign two slots with B; cast with 1/2 or the action strip. No fixed classes prevent mixing. Cooldown reduction is computed from equipment. The shared status component implements timed burn, poison, slow, stun and regeneration, plus internal temporary might/shield support. Effects refresh duration and expire, rather than creating unlimited timers.

## Encounters and boss

Slimes approach and strike; wolves telegraph leaps; skeletons make slower melee attacks; archers keep distance and loose arrows; witches cast poison fans; bats circle and dive; mimics wake from a coffer disguise. Elites receive exactly one deterministic modifier: Burning, Frozen, Vampiric, Explosive or Swift. Rings, palette and labels distinguish elites.

Biomes use different encounter pools; camps, ponds and shrines add themed encounters. Ordinary enemy level increases mildly with distance and caps at 10; ruins add a small offset. Seeded placement, finite extent and clear hub roads stay intact. Enemy HP bars appear after damage or while targeted nearby; dormant mimics show a coffer label.

**The Hollow Knight** replaces the old guardian's single attack in the existing final chamber: 1800 HP, phase I slash / locked-direction charge / marked slam, phase II radial projectiles / temporary burn zones / two skeletal sentinels. The gate seals the arena; death or leaving resets/cleans it safely. Ranged kiting prompts a charge rather than leaving the attack sequence stuck chasing. A dedicated native-resolution bar shows HP and phase. Boss victory persists and drops Legendary Heart of the Hollow Knight, affixed armor, shards, tonics and copper; the original final chest unlocks afterward.

The normal-damage level-3 sword/fireball/heal playtest defeated both phases in approximately 65 seconds before the final graphical pass. See BOSS_PLAYTEST.md for the latest measured result. This is one automated build; broader human balance testing remains necessary.

## Loot and equipment

Loot bundles bounce on the ground, can be collected with E or within 1.9 units after a brief delay, and have beams from Rare upward. One bundle displays its highest rarity. Unclaimed bundles are saved; their visual nodes stream by distance and have an active cap of 50. Collection removes the persistent record before granting rewards.

Generated equipment stores a stable unique ID and a compact base/rarity/affix recipe. Uncommon/Rare roll one modifier, Epic two, Legendary three; plain Common bases remain useful starter/shop items. Modifiers: Sharp damage, Swift speed, Heavy stronger/slower attacks, Lucky crit, Vampiric healing, Burning DOT, Frosted slow. Rarity scales base attack/defense/HP. Inventory can sort by rarity, kind or name, shows all affix descriptions, computes stat differences against the equipped slot and supports long descriptions in a scroll pane. Generated equipment can remain in a saved ground bundle before being owned.

## Relics and simple builds

The earned-shard pool contains 25 outcomes: 8 Common, 8 Rare, 6 Epic and 3 Legendary. Existing non-pool relic IDs remain valid for older saves. One relic slot is preserved. Examples include Winter Clock + Frost Nova for control, Ember Crown + Fireball for burning, Overflowing Cup + Mending Light for shields, and Wind Step + daggers for dodge follow-ups. Relic effects are implemented through the same status/hit/heal events used by ordinary gear.

| Relic | Rarity | Effect |
| --- | --- | --- |
| Traveler's Coin | Common | Every road feels a little shorter. +3% movement speed. |
| Dew Bead | Common | Tonics restore 20% more health. |
| Stone Button | Common | A tiny shield against the road. +2 defense. |
| Reed Whistle | Common | Dodge recovers 15% sooner. |
| Moss Seed | Common | Each defeated enemy restores 2 HP. |
| Last Candle | Common | Fire damage gains 5% power. |
| Acorn Shell | Common | Dodging grants a 5-point shield for three seconds. |
| Silver Thread | Common | While standing still outside danger, slowly recover health. |
| Ember Ring | Rare | Sword strikes carry an additional 8% fire damage. |
| Hunter's Eye | Rare | See the opening between heartbeats. +5% critical chance. |
| Windstep Feather | Rare | After dodging, your next hit within three seconds deals 25% more damage. |
| Frostleaf | Rare | Hits have a 20% chance to slow enemies. |
| Serpent's Tooth | Rare | Hits have a 20% chance to poison enemies for five seconds. |
| Drinking Moon | Rare | Tonics also regenerate 3 HP each second for three seconds. |
| Quartz Guard | Rare | Critical hits briefly stun ordinary enemies. Bosses resist the stun. |
| Spellknot | Rare | Abilities recover 12% sooner. |
| Moonstone Heart | Epic | A quiet pulse of moonlight. +15 maximum HP, +5% critical chance. |
| Storm Charm | Epic | 10% chance on each sword swing to deal 8 bonus lightning damage. |
| Arcane Mirror | Epic | Critical hits release a small secondary arcane bolt. |
| Overflowing Cup | Epic | Healing beyond maximum HP becomes a temporary shield, up to 30 points. |
| Ember Crown | Epic | Fire spells burn their targets, with +15% fire damage. |
| Winter Clock | Epic | Frost Nova reaches 30% farther and freezes ordinary foes briefly. |
| Heart of the Fallen King | Legendary | Kills have a 20% chance to reset your primary attack and one ability cooldown. |
| Echo of the Void | Legendary | Every fifth sword swing releases an echo: 50% attack damage to all enemies within 3.4m. |
| Heart of the Hollow Knight | Legendary | Defeating an enemy grants +25% damage for six seconds. A memory of the Cryptwarden. |

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
