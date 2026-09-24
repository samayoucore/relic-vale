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
