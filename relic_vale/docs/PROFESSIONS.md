# Professions — Phase 8

Open **P → Professions**. Woodcutting, Mining, Herbalism, Fishing, Cooking and Farming each start at level 1 and cap at 25. They are independent of combat/class level and camp resident experience. Progress is stored in save version 8; earlier saves receive level-1 defaults.

The cost to advance from level L is **40 + 12L + L² XP**: 53 XP at level 1, 260 at level 10 and 904 at level 24. Overflow carries into later levels; XP stops at level 25. XP is earned only on completed activities. Cancelled gathering, casts, watering and worker production cannot grant personal XP.

| Profession | Level 5 | Level 10 | Level 15 | Level 20 |
| --- | --- | --- | --- | --- |
| Woodcutting | Yield +5% | Resin and hardwood | Gather speed +10% | Ancient timber |
| Mining | Yield +5% | Silver ore | Gather speed +10% | Star ore |
| Herbalism | Healing herbs | River herbs | Gather speed +10% | Dawn flowers |
| Fishing | Skilled river fish | Rare bait | Large lake fish | Legendary catches |
| Cooking | Cooking pot meals | Hearty dishes | Kitchen meals | Signature recipes |
| Farming | Berries and corn | Bamboo and fruit | Yield +10% | Seed recovery +15% |

Unlock labels summarize the progression. Individual resources, crops, fish and recipes also have explicit minimum levels in their tables. A high-tier tool does not bypass skill requirements, and high skill does not bypass a required tool tier.

## Activity rewards

- Existing wood/ore/herb nodes: 8 + 3 × required hits XP on complete harvest. New resource rewards are in the table below.
- Successful fish: 14 + round(30 × difficulty) XP. Junk and cancelled catches grant no Fishing XP.
- Plant a seed: 3 Farming XP. Manual harvest: 18 + crop minimum level XP. Preparing and watering grant none.
- Cooking: each recipe grants its listed XP after consuming all ingredients at the correct physical station.
- Profession-XP food multiplies the completed activity reward. Camp residents earn their own existing worker XP and never advance player professions.

Woodcutting/Mining/Herbalism grant a 5% chance of one extra material at level 5, rising to 10% at level 20, and 10% faster gathering at level 15. Woodcutting 10 also allows resin drops. Farming 15 adds a 10% chance of an extra crop; level 20 improves returned-seed chance from 30% to 45%. Fishing level and rod tier widen the catch zone.

## Rare resources

| Resource | Profession | Minimum level | Tool tier | Condition | XP |
| --- | --- | --- | --- | --- | --- |
| Hardwood | woodcutting | 10 | axe 2 | Any | 36 |
| Ancient timber | woodcutting | 20 | axe 3 | Any | 56 |
| Coal | mining | 1 | pickaxe 1 | Any | 18 |
| Silver ore | mining | 10 | pickaxe 2 | Any | 36 |
| Star ore | mining | 20 | pickaxe 3 | Storm | 56 |
| Heartleaf | herbalism | 5 | Hand gathering | Any | 26 |
| River mint | herbalism | 10 | Hand gathering | Any | 36 |
| Night bloom | herbalism | 15 | Hand gathering | night | 46 |
| Dawn flower | herbalism | 20 | Hand gathering | dawn | 56 |

Forest weights favor hardwood/ancient timber and forest herbs; rocky terrain favors coal/silver/star ore; banks favor river herbs/night bloom; meadows favor healing herbs/dawn flowers. High-level candidates have an additional rarity roll. Dawn means 05:00–08:00, night 20:00–05:00, and Star ore requires Storm. Nearby discoveries become persistent atlas notes.

New deposits use an independent seed stream and IDs containing /phase8/. Earlier generated resources retain their identities, hit counts and renewal records. Only loaded chunks instantiate their additional resource node. Existing inventory, tool slot, specialist trade, crafting and save/chunk storage are reused.

See [fishing](FISHING.md), [cooking](COOKING.md), [farming](FARMING.md), [mounts](MOUNTS.md) and [Phase 8 validation](PHASE_8.md).
