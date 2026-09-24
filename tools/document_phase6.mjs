import fs from 'node:fs';
import crypto from 'node:crypto';
const root='relic_vale/';
const write=(p,s)=>fs.writeFileSync(root+p,s.trim()+'\n');
const walk=p=>fs.readdirSync(p,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(p+'/'+e.name):[p+'/'+e.name]);
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
write('docs/RESOURCE_SYSTEM.md',`
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
`);
write('docs/INTERIORS.md',`
# Enterable buildings

ValeInteriors owns one active room. The existing exterior architecture and crypt/expedition systems remain in place. Enterable doors use E, a short black fade, physical room creation, player placement and fade-in. Returning restores the exact logical exterior address and camera orbit, pitch and zoom; nearby ground is loaded before the view is revealed. Time, weather, inventory and quest state continue across the transition.

## Building records

Stable IDs have the form settlement_id/building/index. Each record stores ID, settlement, template, title and exterior door address (decimal-string logical chunk coordinates plus a bounded local offset). Resident records refer to the building IDs for home, work and tavern. State.interior_data.active holds the building record, exterior return address and exterior camera settings. Household storage is keyed by building_id/storage.

Rooms occupy reserved local space at x=3000, independent of enormous world coordinates. This is a separate instantiated scene tree, not a seamless copy hidden inside each exterior. Outdoor chunk and authored-hub processing is suspended while indoors. Only the current room, its furnishings and current occupants are instantiated. Exit synchronously rebuilds the destination streaming window; leaving releases the previous room. Saving indoors and loading in a fresh process recreates the same template before play resumes.

## Templates

| Template | Distinct content |
| --- | --- |
| House | Beds, reading table/books, chairs, cabinet, food/drink props, hearth and household chest |
| Shop | Counter, mixed stock crates, apples, sacks, shelves and resident merchant |
| Blacksmith | Anvil/log, workbench, whetstone, real tools, forge recipes and Bram or the local smith |
| Tavern | Tables, mugs, plates, chairs, counter/barrels, hearth, bartender and evening patrons |
| Alchemist | Bottles, potion, cauldron, supplies, alchemy recipes and resident alchemist |

Five Willowmere doors use all five templates. Procedural settlements have a general shop, local specialist, tavern and farmhouse. Building ID deterministically varies rug colors and decoration choices. Imported furnishings are selected from Quaternius Fantasy Props MegaKit Standard (CC0); this coherent medieval selection was used instead of importing an unrelated modern interior set. Beds and work/rest anchors support residents who live in their workplace. Shelves, chairs and tables have meaningful placement; solid furniture and walls constrain movement. Blocking walls participate in the existing camera hiding system.

Warm local lights, a hearth and reduced outdoor fog create room lighting. Quiet dish sounds distinguish taverns, metal work distinguishes forges, water/bubbling suggests the alchemist, and wooden footsteps/room foley accompany homes. The existing project music continues. Only the active room emits these cues.

## Storage and occupants

The native household chest page deposits or withdraws one item at a time. Quest items and equipped items are excluded from deposit. Counts persist in the save and are validated on read. A chest belongs to its building, so storage does not follow the player into a different house.

Residents are reconstructed from persistent identity and current global schedule. Initial occupants start at their activity; new arrivals walk from the doorway to a free anchor. Departing occupants walk to the door. Anchors reserve Bed, Chair, TavernSeat, Market, Bookshelf, Workbench, Forge or Cauldron positions; only one resident claims an anchor. A shared obstacle grid provides paths. Sleep, work and rest transitions update while the room stays loaded.

F4 lists building IDs and offers enter, exit and reload commands. E remains the ordinary player flow. Interior boundaries, fade, camera, floor, storage and fresh-process return are covered by the included tests.
`);
write('docs/NPC_SIMULATION.md',`
# Residents and fauna

Persistent resident records are separate from streamed actors. They retain ID, displayed identity, NPC/trade ID, settlement, home, workplace and tavern. Willowmere has Rowan, Bram, Mira, Elowen, Liora, Hazel and Tobin. Generated settlements have five or six residents, including merchants, an innkeeper and farm workers; identities are deterministically named outside the authored quest settlements. Existing quest NPC IDs remain stable.

## Daily schedule

| Time | Destination |
| --- | --- |
| 00:00–06:00 | Home |
| 06:00–08:00 | Square |
| 08:00–12:00 | Workplace or outdoor work |
| 12:00–13:00 | Square/lunch |
| 13:00–18:00 | Workplace or outdoor work |
| 18:00–22:00 | Tavern |
| 22:00 onward | Home |

Storms direct residents home. Exterior actors walk between doors using a shared local AStarGrid2D with one-meter cells and static obstacle clearance. The grid belongs to the loaded settlement or room, never to huge global float coordinates. Temporary player/NPC avoidance allows passing rather than waiting forever at a doorway. Doors accept arrival within interaction distance. Origin changes shift stored paths and activity coordinates along with actors.

Near residents move and animate normally. High-level decisions run every 0.3 seconds nearby, or 2 seconds at distance. Beyond 55 meters an exterior route can be abstractly completed; unloaded settlements have no actor simulation. Re-entering reconstructs their scheduled destination from the clock. Cached navigation owners use weak references and are discarded after unloading.

Outdoors residents face nearby people, alternate conversation/listening poses, greet a nearby traveler at bounded intervals and react to nearby attacks. Tobin has a timber-working pose. Indoors they reserve activity anchors: sit/rest, eat/drink with a mug, read with a book, prepare supplies, serve customers, hammer at the anvil or lie on a bed. Real imported hand props accompany appropriate actions. These are simple LPC sprite poses and hand transforms, not unimplemented skeletal motion capture. Daytime fallback seats never put a patron to sleep in a bed.

## Friendly fauna

Deer, stag and fox provide wildlife; cows, alpacas and horses provide farm animals. All use imported Quaternius rigged models and authored locomotion/idle/eating clips where supplied. The existing noncombat fauna component is separate from enemy bodies, health/loot and combat AI. Unsupported species-specific sleep clips fall back to a quiet idle/rest pose.

Wilderness spawn candidates use vegetated biomes and approximately one selected chunk in five; some deer form a two-animal group. The authored forest trail has one small deer/stag group. A three-animal Willowmere pasture and small forest-settlement farms provide domestic animals; farm populations do not appear in dungeons. Homes and targets are shifted correctly during origin changes and interior returns.

States are Idle, Wandering, Grazing, Following herd, Fleeing, Returning home and Sleeping. Wildlife flees at close player range and from nearby attacks; farm animals tolerate a closer approach. Animals avoid water and physical obstacles, remain within their home range, return at night or in storms and use bounded vocal/hoofbeat cooldowns. Near AI updates continuously; beyond 32 meters decisions/movement are aggregated at 0.3-second intervals; beyond 65 meters animation and AI sleep. Outdoor processing stops during interiors and unloaded wildlife is not serialized individually.

F4 shows resident home/work/current activity/next route point and can draw paths or force hours. Fauna controls show species, state, group and LOD, and offer spawning, fleeing and clearing. F3 retains world/streaming diagnostics. These are development controls and affect the current session.
`);
let credits=fs.readFileSync(root+'docs/ASSET_CREDITS.md','utf8');
credits=credits.split('\n## Phase 6 assets')[0];
credits+=`
## Phase 6 assets

- **Fantasy Props MegaKit — Standard**, Quaternius, **CC0 1.0**. [Official page](https://quaternius.com/packs/fantasypropsmegakit.html), [author distribution](https://quaternius.itch.io/fantasy-props-megakit). 32 selected glTF models plus referenced binary buffers and textures in assets/3d/phase6/props. Includes Axe_Bronze, Pickaxe_Bronze, beds, tables, chairs, books, containers, forge and alchemy furnishings. Tools retain original geometry; iron/steel use material tints. Props use shared materials, disabled normal maps and 1024-pixel mipmapped runtime textures.
- **Ultimate Animated Animals**, Quaternius, **CC0 1.0**. [Official page](https://quaternius.com/packs/ultimateanimatedanimals.html). Cow, Fox, Horse and Alpaca glTFs added under assets/3d/phase6/animals. Existing Deer/Stag/Wolf remain credited in Phase 4. These compatible farm species were chosen from the animated-animal library; a separate Farm Animal Pack was not imported.
- **Universal Animation Library 2 — Standard**, Quaternius, **CC0 1.0**. [Official page](https://quaternius.com/packs/universalanimationlibrary2.html), [author distribution](https://quaternius.itch.io/universal-animation-library-2). Downloaded and audited 43 Standard clips, including TreeChopping_Loop and Farm_Harvest. Audit receipt retained; the library is **not used as runtime player animation** because LPC billboard sprites have no compatible humanoid skeleton. Original directional sprite frames plus custom hand/swing transforms preserve the existing character style. Existing LPC attribution/share-alike terms continue to apply.
- **100 CC0 SFX #2**, rubberduck, **CC0 1.0**. [Source](https://opengameart.org/content/100-cc0-sfx-2). Selected wood_hit_01, wood_03, stones_01, metal_hit_01, glass_01, door_01, footstep_wood_01 and loop_water_01 OGGs; used unmodified for gathering and room foley.
- **Horse Trotting**, EZduzziteh, **CC0 1.0**. [Source](https://opengameart.org/content/horse-trotting). Unmodified Trot.ogg renamed hoof.ogg.
- **Mudchute cow recording**, Secretlondon, submitted to OpenGameArt by qubodup. [Farm animals source](https://opengameart.org/content/farm-animals), [original collection](https://commons.wikimedia.org/wiki/Category:Mudchute_Park_and_Farm), [author](https://commons.wikimedia.org/wiki/User:Secretlondon). **CC BY-SA 3.0 selected from the offered dual license.** Only Mudchute_cow_1.ogg is shipped, unmodified, with original info.txt. Attribution and share-alike apply to the recording and adaptations; the full license is included in docs/licenses/CC-BY-SA-3.0.txt and [online](https://creativecommons.org/licenses/by-sa/3.0/). No endorsement is implied.
- **Original support work**: six transparent tool thumbnails rendered through the existing ItemIconRenderer from CC0 meshes; timed hand/swing tracks; resource particles; room layouts, anchor logic, lighting and code. Resource icons and Kenney tree/rock/plant meshes reuse the previous credited selection.

Exact selected files, byte sizes, SHA-256 hashes and download receipts are recorded in PHASE_6_ASSET_MANIFEST.json. The full source archives and the inspected UAL2 library stay in workspace downloads, outside the game runtime. No further asset download is needed to play.
`;
write('docs/ASSET_CREDITS.md',credits);
write('assets/audio/phase6/CREDITS.txt',`Audio attribution — Relic Vale Phase 6
100 CC0 SFX #2 — rubberduck — CC0 1.0 — https://opengameart.org/content/100-cc0-sfx-2
Horse Trotting — EZduzziteh — CC0 1.0 — https://opengameart.org/content/horse-trotting
Mudchute_cow_1.ogg — Secretlondon — CC BY-SA 3.0 — unmodified.
https://opengameart.org/content/farm-animals
https://commons.wikimedia.org/wiki/Category:Mudchute_Park_and_Farm
https://commons.wikimedia.org/wiki/User:Secretlondon
https://creativecommons.org/licenses/by-sa/3.0/
Full license: res://docs/licenses/CC-BY-SA-3.0.txt. Original attribution: info.txt.
`);
const files=[...walk(root+'assets/3d/phase6'),...walk(root+'assets/audio/phase6'),...walk(root+'assets/ui/phase5/rendered').filter(p=>/(crude|iron|steel)_(axe|pickaxe)\.png$/.test(p))].filter(p=>!p.endsWith('.import'));
const receipts=['props','animations','audio-foley','audio-hoof'].map(p=>JSON.parse(fs.readFileSync('downloads/phase6-'+p+(p.startsWith('audio')?'':'-download')+'.json')));
write('docs/PHASE_6_ASSET_MANIFEST.json',JSON.stringify({date:'2026-09-10',receipts,files:files.map(path=>({path:path.slice(root.length),bytes:fs.statSync(path).size,sha256:hash(path)}))},null,2));
console.log('Phase 6 architecture, attribution and asset manifest written.');
