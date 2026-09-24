# Farming and camp occupations — Phase 8

At **camp tier 3**, eight fixed beds appear in reserved ground beside the production chest. Higher camp stages preserve these beds and avoid their footprint. Buy seeds and a watering can from **Nell**, choose a seed in **P → Garden**, then use **E** at a bed to prepare, plant, water and eventually harvest. Equip the watering can in the Tool slot for watering. Preparation and planting use the character's hands.

## Crops

| Crop | Minimum Farming | Moist game minutes | Normal yield |
| --- | --- | --- | --- |
| Carrot | 1 | 180 | 3 |
| Beet | 1 | 240 | 3 |
| Corn | 5 | 420 | 4 |
| Berries | 5 | 480 | 4 |
| Bamboo shoots | 10 | 540 | 3 |
| Apple | 10 | 720 | 4 |
| Prickly pear | 12 | 600 | 3 |
| Sunpetal | 15 | 660 | 3 |

Each crop has five visible stages: seed, young (12%), growing (38%), mature (70%) and harvestable (100%). Imported Quaternius Ultimate Crops stage models provide the growth visuals. The initial seed is a tiny crop mesh; sunpetal reuses a compatible crop variant, and the other species use their supplied growth families.

One watering keeps soil moist for eight game hours. Dry soil pauses growth; it does not destroy the crop. Rain and Storm water beds automatically. Only moist elapsed game minutes advance growth. The save stores crop, planting/progress times, moisture deadline, last processed time, replant seed preference and harvest count for each bed. Visible models are reconstructed from that state.

The clock resolver runs independently of the camp scene. Leaving several chunks away unloads the garden graphics but preserves its game-clock progression. Returning rebuilds the correct stages. A bounded catch-up loop processes 30-minute intervals, retaining any backlog and the weather history needed by unprocessed intervals. It does not use elapsed real-world time while the application is closed.

Manual harvest awards Farming XP and full crop yield. Seed recovery chance starts at 30% and improves to 45% at Farming 20. Farming 15 adds a 10% chance of one bonus crop. Crops remain useful for meals and specialist trading; rare cultivars stay primarily a player activity.

## Resident occupations

Use **G → Residents** (also linked from the Garden page) to select a continuing role. Roles reuse camp workers, skill values, levels, XP and the existing day/night actor system. A resident cannot have a continuing occupation and an expedition simultaneously; release one before assigning the other.

| Role | Camp tier | Production |
| --- | --- | --- |
| Farmer | 3 | Waters, harvests and replants prepared beds using seeds from the production chest. Grows staples requiring Farming 5 or less. |
| Cook | 2 | Uses common fish/meat/carrot/forest ingredients from the production chest to make basic meals. |
| Fisher | 3 | Supplies common minnows only when a real fishing bank is found within 26 metres of camp. |
| Forager | 2 | Supplies small quantities of wild herbs. |
| Woodworker | 3 | Consumes 3 wood from the production chest to produce 1 plank. |

Supply seeds and ingredients through the physical production chest next to the beds, using the existing household storage interface. This is distinct from the camp's abstract food/material/gold meters. Workers deposit items in the same chest. Their normal production cycle takes 180 working game minutes, improved by up to 30% by existing worker skills. They work 06:00–20:00, return to shelter at night, and the farmer pauses tending during storms while rainfall keeps beds watered. Failed recipes cannot create output without inputs.

The farmer harvests one fewer crop than a manual harvest (at least one) and gains worker XP, never player XP. Catch-up is idempotent: resolving the same clock time again cannot repeat rewards. When the camp is visible, residents walk to their work locations and use compatible existing action poses. This is a deliberately modest local supply system with five occupations, not a city-wide production-chain simulation.
