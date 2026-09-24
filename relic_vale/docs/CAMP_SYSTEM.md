# Owned camp simulation

G opens camp management. Before founding, Choose a camp site enables a translucent 34×34 m masterplan preview; move to position it, Enter confirms and Esc cancels. The entire site must be dry, away from roads, landmarks and settlements, reasonably flat (maximum sampled height spread 2.2 m), and free of blocking scenery. Sparse deterministic natural meadow clearings make founding practical. They retain original blueprint generation order and resource identifiers. F7 can locate a clearing for testing.

The camp has one persistent logical address, name and ID. Its full expansion footprint is reserved across streaming reloads: scenery, foliage and resource spawns are excluded there, with a wider 25 m exclusion for hostile spawn points. Other world resources keep their stable IDs. A nearby Node3D holds models, doors and residents. Outside 78 m or the nearby chunk window it is detached and freed. Only the small game-clock simulation remains. Origin shifts move the physical root and invalidate cached NPC paths.

| Level | Stage | XP to cap | Upgrade Food / Materials / Gold | Population | Job slots | Visible facilities |
|---|---|---:|---|---:|---:|---|
| 1 | Campfire | 60 | 8 / 14 / 5 | 2 | 1 | Fire, two tents, storage and task board |
| 2 | Wayside Camp | 130 | 24 / 40 / 18 | 4 | 2 | Extra tents, storage yard, work areas and paths |
| 3 | Outpost | 240 | 50 / 85 / 40 | 6 | 2 | Permanent workshop, fences and an outpost hall |
| 4 | Homestead | 400 | 90 / 150 / 75 | 8 | 3 | Enterable player home and veteran cottages |
| 5 | Hamlet | Final | 0 / 0 / 0 | 10 | 4 | Leader house, veteran homes, newcomer tents and market |

Food, Materials and Camp Gold are independent of the player's purse and XP. Tasks fund every stage without mandatory donations; a deterministic test reaches tier 5 with one resident in 57 starter contracts. Optional Storage contributions convert wood/stone/ore into Materials, mushrooms/herbs into Food, or personal coins into Camp Gold. Every player-facing transfer asks for confirmation and debits the exact source amount. Camp XP cannot be donated. Conversion tables and level costs are in data/camp.json.

At the current XP threshold, upgrade_pending becomes true and XP stays exactly at the cap. Subsequent mission XP is discarded, not banked; Food, Materials, Gold and worker XP continue. Confirming an affordable upgrade spends all three listed resources, advances the tier, resets Camp XP to zero and resumes accumulation. Tier 5 is final.

The first traveler is guaranteed after one game minute. Later candidates arrive approximately once per game day, subject to population capacity. They physically approach the board. Walk up to one and press E; accept or decline in the recruitment page. Declining produces a departing actor and schedules a different later candidate. Full camps explain their capacity limit. F7 exposes spawn/recruit tools for testing.

Workers persist stable IDs, names, appearance, five skills, level/XP, join time, residence, activity and assignment. They reuse LPC character layers/animations, camera-relative facing and the Phase 6 shared navigation grid. Residents walk among the board, storage, fire, meals and workbench; carrying has a crate prop and working uses existing action frames. At night or during storms they walk to shelter. Experienced/long-serving residents receive up to three veteran cottages, with visible inhabitants inside at night; newcomers retain tents. The player house and permanent workshop use the existing playable house/blacksmith interiors. Hamlet trader Rook uses the existing shop system.

Version 7 saves persist camp resources, pending upgrades, workers, visitor schedule, offers, mission records, contribution totals and building records. Versions 2–6 load with empty camp/map defaults. Numeric values, addresses, tasks and assignment consistency are validated before loading. House chests continue to use per-building Phase 6 storage; visit the actual chest to use it.

Limits: one owned camp, five predefined masterplans and ten residents; workers are abstract while on missions or far away. Mission activities are simple reusable animations, not a new animation library. Tents use abstract sleeping occupancy; houses have visible interiors. This phase does not implement freeform construction, agriculture, raids or a real-time offline production clock.
