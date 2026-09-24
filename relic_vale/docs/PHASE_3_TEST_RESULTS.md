# Phase 3 systems verification

Godot 4.7.2-stable (official); renderer Windows.

46 passed; 0 failed.

- PASS: Five weapon profiles and six abilities load from data
- PASS: A new traveler can try all five weapon styles immediately
- PASS: C opens character creation through input
- PASS: Confirmation applies name, skin, hair, outfit and cloak
- PASS: In-world character uses the confirmed animated appearance
- PASS: B opens the ability loadout
- PASS: Two independently chosen active abilities are equipped
- PASS: Shrine pool contains 8 Common, 8 Rare, 6 Epic and 3 Legendary relics
- PASS: Legendary equipment rolls three distinct affixes
- PASS: Each generated item has a unique ID and rarity-scaled affix count
- PASS: Equipment materializes affix: sharp
- PASS: Affix contributes computed stat: damage_percent
- PASS: Equipment materializes affix: swift
- PASS: Affix contributes computed stat: attack_speed
- PASS: Equipment materializes affix: heavy
- PASS: Affix contributes computed stat: damage_percent
- PASS: Affix contributes computed stat: attack_speed
- PASS: Equipment materializes affix: lucky
- PASS: Affix contributes computed stat: crit
- PASS: Equipment materializes affix: vampiric
- PASS: Affix contributes computed stat: vampiric
- PASS: Equipment materializes affix: burning
- PASS: Affix contributes computed stat: burn_chance
- PASS: Equipment materializes affix: frosted
- PASS: Affix contributes computed stat: slow_chance
- PASS: Inventory click equips affixed gear and changes damage
- PASS: Ground loot waits for pickup and shows a rarity beam
- PASS: Version 3 save writes affixes, appearance and unclaimed loot
- PASS: Version 3 save reloads successfully
- PASS: Generated recipes reconstruct identical equipped items
- PASS: Unclaimed loot and both ability slots survive reload
- PASS: Name and palette appearance survive reload
- PASS: Nearby pickup grants the saved legendary once
- PASS: Collected loot releases its scene and cannot duplicate rewards
- PASS: Old version 2 saves remain accepted
- PASS: Migration preserves old progress and supplies new defaults
- PASS: A migrated journey can be written as version 3
- PASS: Overflowing Cup turns excess healing into a shield
- PASS: Winter Clock adds a stun to Frost Nova
- PASS: Ember Crown supports a fire damage and burn build
- PASS: Shrine click commits one shard before its cinematic reveal
- PASS: Shrine buildup lasts beyond one second
- PASS: Skip reveals the committed item without charging again
- PASS: Pause opens controls and audio settings
- PASS: Master, Music and SFX have separate volume controls
- PASS: Music slider changes the live audio bus preference
