# Physical resources

ValeResource extends the established interactable component. Each node owns the real imported scenery, a trunk/deposit collider where appropriate, and a depletion remnant. Trees and logs supply wood; rocks supply stone, iron and crystals; ground vegetation supplies herbs, fiber and mushrooms. Ore has muted mineral fragments embedded in the imported rock, without glowing markers.

| Material | Base copper | Hits | Yield | Renewal |
| --- | ---: | ---: | --- | --- |
| Wood | 5 | 3, or 5 for large trees | 3–6 | 3 days |
| Stone | 5 | 3 | 2–4 | 5 days |
| Iron ore | 9 | 5 | 2–5 | 7 days |
| Wild herbs | 6 | 1 | 2–4 | 2 days |
| Fiber | 4 | 1 | 2–5 | 2 days |
| Mushrooms | 7 | 1 | 1–3 | 2 days |
| Crystal | 24 | 5 | 1–2 | Permanent depletion |

Definitions live in data/resources.json; item prices, icons and equipment fields live in data/items.json. Forest tree groups retain their logs, plants and small rocks. Rocky/ruined biomes favor ore and crystals. Herbs/fiber belong to vegetated regions; rare deposits also occur in expeditions. Decoration is still batched where it is not interactive. The authored woodland and generated chunks use the same harvesting component.

## Tools and input

Equip an axe or pickaxe in the inventory's Tool slot. Crude / Iron / Steel have gathering power 1 / 2 / 3 and cost 8 / 45 / 120 copper at neutral reputation. Steel also grants one extra material per completed node. Plants use a bare-hand action. Starter inventory contains a crude axe and pickaxe. Hold E near a matching node to repeat strikes. Space/left click retain combat input.

Each strike lasts 0.85 seconds and applies its impact at 0.42 seconds. Yield is a deterministic integer drawn from the material's range using node ID and current game day, plus the tool bonus. Materials arrive only on depletion. Wind-up, impact and recovery animate the actual Quaternius Axe_Bronze / Pickaxe_Bronze mesh at a camera-relative hand attachment while the existing LPC slash frames play. The player remains a directional billboard, with no humanoid Skeleton3D. UAL2 Standard was inspected, but its skeleton tracks are not falsely presented as retargeted LPC animation.

Wrong tools are rejected. Stun, a modal, leaving reach, changing equipment or respawning cancel the action. Movement and combat cannot overlap a gathering strike. The final hit replaces trees with a short log/stump remnant and rocks with debris, hides plants and removes their collision. Camera occlusion cannot restore a depleted model. Chips, a small object response, material feedback and licensed wood/stone/plant sounds use the existing bounded feedback system. No durability system was added.

## Persistence and economy

IDs combine world seed, logical chunk/POI and deterministic local index. Authored nodes have seed/resource/hub IDs. Resource state contains remaining hits and a respawn day. Phase 6 save version 6 includes these records in the existing content-addressed chunk delta manifest. A partially damaged node survives unloading; a depleted node remains depleted until its renewal day, including after a process restart. Legacy boolean-only gathered records remain depleted when no renewal timestamp exists. Undisturbed scenery is regenerated rather than serialized.

Inventory offers Materials, Wood, Stone, Ore, Plants and Rare materials filters and ordinary stacks. Bram/blacksmiths buy ore, stone, ingots and charcoal at a premium; Tobin/carpenters favor wood, planks and fiber; alchemists favor herbs, mushrooms and crystal. The shared ValeLife.item_price function drives both the shop display and transaction. Reputation modifies prices and specialists apply demand within a resale cap. Common materials and tools can be bought with limited daily stock. Crystals are exploration rewards and were removed from routine merchant stock. Quest items and the last equipped item cannot be sold; no unconfirmed bulk-sale action was added.

F4 includes tool grants, +100 wood/stone, material clearing, physical node spawning and regrowth. The existing item-icon scene renders transparent thumbnails from actual imported meshes.
