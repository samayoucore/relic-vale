# Companions

Four named companions extend the existing interactable, combat and quest systems. Generated camp workers retain their separate Phase 7 identity and occupations. The player can take one combat companion; the other recruited characters live at the camp.

| Companion | Actual KayKit model | Role | Abilities |
| --- | --- | --- | --- |
| Bren Alder | Knight.glb | melee | Shield Rush; Hold the Line |
| Tarin Fen | Ranger.glb | ranged | Pinning Shot; Split Fletching |
| Ilyra Venn | Mage.glb | mage | Frost Bind; Ember Mark |
| Sera Reed | Rogue.glb | support | Field Dressing; Steady Hands |

## Data and recruitment

`data/narrative/companions.json` supplies stable IDs, models, portraits, biographies, personality tags, faction, default equipment, abilities, recruitment quest, three personal quests, camp anchors and contextual barks. Every companion is encountered at a persistent authored location and joins after their recruitment situation is resolved. Declining the invitation leaves it available for later. Bren watches the road east of Willowmere; Tarin stays at Split Fern Camp, Ilyra at the Quiet Scriptorium and Sera at Wayfarer's Rest. Dialogue and the journal provide the next objective.

`ValeParty` manages logical ownership and presentation. `ValeCompanionActor` uses CharacterBody3D movement, a capsule that does not block the player, a real skeletal model, and role-appropriate hand attachments. General/movement clips reuse the imported KayKit pipeline; CombatMelee, CombatRanged and Simulation add matching 23-bone clips. The portrait renderer in `tests/phase9_slice.gd` uses the same models and equipment in a controlled SubViewport. Four transparent 300 × 360 PNGs ship with the game.

## Following and combat

O opens the company roster; Z opens Follow, Wait, Passive, Defensive and Aggressive orders. The roster can activate or dismiss companions. Switching during a nearby fight is refused. Wait holds its world position until Follow or a loading transition. Dismissal moves ownership back to camp.

High-level target selection runs every 0.25 seconds. Navigation refreshes approximately every 0.85 seconds, using the existing resident route infrastructure: a clear direct segment or a bounded AStar grid. Movement and collisions run on physics ticks. A companion more than 26 metres behind may catch up only outside the camera view; landing searches dry, clear, low-slope ground near the player. Floating-origin shifts adjust cached positions; loading transitions reconstruct actors at canonical addresses. Interiors/dungeons keep the active companion nearby. Mounted travel uses the same follow system.

Defensive companions protect the nearby party; Aggressive companions select threats farther away. Melee attacks resolve after an animation windup. Bren closes with a short shield rush and can shield the injured player while drawing attacks. Tarin uses bow projectiles and slowing/multiple arrows. Ilyra uses magic projectiles, area slow and burning marks. Sera heals the more injured ally and clears harmful conditions. Enemies can target either player or companion. Allied attacks do not trigger the player's relic procs or hurt the other ally.

Companions have level-scaled health, attack, defense and critical chance. They catch up to the player's level. Weapon, Armor and Accessory slots transfer items out of shared inventory and return replaced gear. Weapon type must fit the role; the last item currently worn by the player cannot be transferred. The model retains its coherent role weapon silhouette rather than representing every affix as a new mesh.

At zero health the companion is downed, with no permanent loss. After danger clears, E nearby revives them; 12 quiet seconds also allow recovery. Out-of-combat regeneration and a short damage immunity interval prevent rapid repeated overlap damage. Loading preserves downed state.

## Relationships and personal stories

Approval is bounded to −100…100. Decisions react to personality tags; each authored reaction key is applied once. Reopening a panel or loading a save cannot farm approval. Tiers are Distant (<0), Acquaintance (0–19), Trusted (20–39), Close (40–64), Loyal (65+). Later personal conversations require approval and prior chapters; locked choices explain the requirement. Recruitment remains recoverable.

Each companion has three personal quests. Bren decides what Cinder Watch will become; Tarin follows Lysa's trail and settles its passage rules; Ilyra recovers an altered oath and decides who may read it; Sera investigates polluted water and the field ledger before choosing the clinic charter. The final decisions alter faction reputation and persistent scene variants, and award a signature accessory plus a passive improvement. The roster and journal show completion counts without future chapter titles.

Inactive recruited companions keep watch by day, gather around the fire in the evening, and use sleeping poses at night. Distant camp actors unload. Camp dialogue uses the existing UI and shared camp location. Text barks have long cooldowns, with weather, night, combat, settlement, personal-place and story context; no voice acting is required.

## Persistence and diagnostics

Version 9 stores each companion's recruitment, level, approval, equipment, health, downed/waiting/traveling state, logical address and camp routine in `narrative.companions`. The active ID, order, stance and approval keys live alongside it. Personal progress stays in the existing `quest_progress` and `completed_quests` dictionaries; outcome flags remain in `narrative.flags`. Version 2–8 journeys receive default companion fields.

F10 exposes recruitment, active selection, approval changes/tier selection, downing, regrouping and quest completion. It changes the current journey and is intended for development. See [Phase 9](PHASE_9.md) for reproducible test entry points.
