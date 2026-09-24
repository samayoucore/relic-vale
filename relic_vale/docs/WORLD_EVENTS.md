# World events

Eight road stories extend `State.life_data.events`; the earlier traveling-merchant record remains supported. `ValeWorldEvents` reads templates from `data/narrative/events.json` and creates serial `encounter_N` records. These are temporary situations rather than new permanent procedural POIs.

| Event | World context | Resolution | Persistent effect |
| --- | --- | --- | --- |
| A wheel in the mud | road; day; Clear/Cloudy/Fog | Repair the wheel | helped_carters; hearth +5 |
| A voice among the ferns | forest; any; Fog/Rain/Cloudy | Lead the traveler to the road | guided_travelers; bough +6 |
| Grain under guard | road; any; any weather | Let the grain cart pass | grain_delivered; hearth +7 |
| The empty medicine pouch | road; any; any weather | Give three wild herbs | medicine_shared; hearth +5 |
| The patrol at the boundary | settlement; day; any weather | Witness the travelers’ passage | patrol_parley; bough +5 |
| A voice in the old stone | ruin; night; any weather | Close the circle | echoes_released; veil +7 |
| A fire out of the rain | road; any; Rain/Storm | Share two dry wood | road_shelters; bough +5 |
| The first free lanterns | road; night; Clear/Cloudy/Fog | Light the last lantern | first_vigil; veil +5 |

## Placement and pacing

During exploration, attempts are spaced by 35 real seconds and at least 120 elapsed game minutes since the last spawn. At most two events are unresolved. Indoors and near an ongoing fight, new events are suspended. Candidate sites lie 27–53 metres from the player in loaded chunks. They must satisfy template biome/road/POI, time, weather, faction and progress conditions; dry ground, terrain reservations, spacing from another event and camera-frustum probes also apply. No suitable ground means no event. Debug spawning may bypass context deliberately.

The patrol requires non-hostile Wardens; the free-lantern vigil requires the Act I ending. A lost traveler's destination must be an actual nearby road. There is deliberately quiet travel between encounters.

## Playing and outcomes

Approaching discovers the temporary atlas marker. E opens the encounter's conversation. A repair/help action checks proximity and carried materials before consuming them. A combat encounter requires its actual enemies to be defeated. The traveler follows a bounded obstacle route, and the escort completes only when both traveler and player reach the marked road. Events cannot resolve remotely or pay twice.

Rewards include modest copper, experience, faction standing and occasional items. Unique personality approval is bounded to once per event kind/companion. The grain ambush adds three camp food; shared field medicine gives a permanent 10% trail-tonic retail discount; the released echo unlocks an oathbound lore entry. Hester, Yew and Orsa can acknowledge outcomes in later dialogue. Ignoring a meeting allows it to expire without granting its rewards.

## Lifetime and persistence

Each record stores canonical address, kind, created/expiry times, state, discovered flag, stage, defeated enemy IDs, and escort destination/walker address. The lifetime is 240 game minutes. There are at most 64 retained records; pruning removes old resolved/expired records while preserving unresolved encounters. Completion/expiry removes the atlas marker immediately. Visible presentation is disposed once out of view or on unload, avoiding sudden disappearance.

Loaded relevant chunks reconstruct unresolved events. Killed event enemies stay absent, using the bounded encounter record rather than adding to the global unique-enemy ledger. The persistent consequence flags remain after the encounter record is pruned. Save version 9 validates the ledger, lifetime, enemy indices and two-active-event budget. Escort movement does not run while the relevant chunk is unloaded.

F10 lists active and retained events and provides specific spawn, visit, resolve and expire controls. Automated tests use isolated journey files and disable autonomous spawning for repeatability; production placement is also tested with its context/camera rules enabled.
