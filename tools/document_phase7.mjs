import fs from 'node:fs';
import crypto from 'node:crypto';
const root='relic_vale/', config=JSON.parse(fs.readFileSync(root+'data/camp.json','utf8'));
const write=(path,text)=>fs.writeFileSync(root+'docs/'+path,text.trim()+'\n');
write('MAP_SYSTEM.md',`
# World map, minimap and travel

The atlas and north-up minimap are two instances of ValeAtlas (scripts/ui/world_atlas.gd). ValeCartography rasterizes actual ValeRegionPlan terrain weights, noise, rivers, lake shores and roads into 32×32 textures for 32 m chunks. It does not render another 3D scene or invent a separate world. The same seed and integer coordinates drive scenery and cartography. Existing discovered records supply coarse road/water representations while detailed tiles build.

Coordinates stay in an integer chunk anchor plus a bounded pixel pan. Pixel = viewport center + pan + ((logical chunk − anchor) + local offset / 32) × zoom. The integer subtraction happens before float conversion. Mouse-to-world uses floor and positive modulo, including negative coordinates. Panning rebases accumulated offsets into the integer anchor. Tests round-trip ±10^12 addresses and travel across that distance.

Only discovered chunks are drawn; unseen terrain remains dark. Actual generated POIs and persistent service building entrances supply icons. Quest NPCs, the player, custom markers and the owned camp share the chart. Houses identify settlements/services, triangles identify danger/dungeons, flags identify landmarks/markers and ! identifies quests. Original vector symbols have no external license dependency. Hover reveals names and service types. Overlapping labels are suppressed while their icons remain selectable. Settlement, dungeon, landmark, quest, marker and camp filters work independently.

The shared LRU holds at most 512 tiny textures (about 1.5 MiB raw RGB plus texture overhead). At most four new textures are built per render frame. Detailed tiles cover the central 20×20 chunk window; zoomed-out margins use the existing actual biome/road/water records. This bounds memory and avoids repeatedly rasterizing an entire explored world. F7 regenerates the cache, reveals loaded chunks or clears discovery. New discoveries are charted automatically.

Atlas: Tab; left drag pans; wheel selects 20–320 pixels/chunk; Center player resets the view. Right-click discovered ground to create a marker; click its icon to rename it, change Flag/Home/Danger/Treasure/Resource, delete it with confirmation, or travel. Maximum 32 custom markers. IDs, names, icons, creation game time and full logical addresses persist in the save. The automatic camp marker is separate and cannot be deleted. The minimap uses 50/100/200 pixels/chunk, hides under modal panels and scales to available HUD height.

Travel rejects recent attacks/damage, nearby live enemies, defeated players, dungeon instances and active interior transitions. Leave an interior before traveling. The pipeline cancels attacks/gathering, freezes gameplay with the established loading page, fades out, synchronously builds the generator's preload window (normally 25 chunks), reconstructs a nearby camp, waits for physics synchronization and searches up to 12 m around the requested point. Ground must have a real collision surface, a walkable normal, no water, no blocking capsule overlap and no enemy within 12 m. Success reveals the scene and resumes control; failure rebuilds the original location and reports why. The completion path explicitly releases the protected loading page.

Limits: fog is chunk based; cartographic icons are schematic; unknown ground is not a fast-travel destination. There is no map routing/wayfinding solver or minimap 3D camera. Distant unseen terrain is not precomputed. Large transitions synchronously build the bounded local window under the loading screen.
`);
write('CAMP_SYSTEM.md',`
# Owned camp simulation

G opens camp management. Before founding, Choose a camp site enables a translucent 34×34 m masterplan preview; move to position it, Enter confirms and Esc cancels. The entire site must be dry, away from roads, landmarks and settlements, reasonably flat (maximum sampled height spread 2.2 m), and free of blocking scenery. Sparse deterministic natural meadow clearings make founding practical. They retain original blueprint generation order and resource identifiers. F7 can locate a clearing for testing.

The camp has one persistent logical address, name and ID. Its full expansion footprint is reserved across streaming reloads: scenery, foliage and resource spawns are excluded there, with a wider 25 m exclusion for hostile spawn points. Other world resources keep their stable IDs. A nearby Node3D holds models, doors and residents. Outside 78 m or the nearby chunk window it is detached and freed. Only the small game-clock simulation remains. Origin shifts move the physical root and invalidate cached NPC paths.

| Level | Stage | XP to cap | Upgrade Food / Materials / Gold | Population | Job slots | Visible facilities |
|---|---|---:|---|---:|---:|---|
${config.levels.map(l=>`| ${l.level} | ${l.name} | ${l.xp||'Final'} | ${l.cost.food} / ${l.cost.materials} / ${l.cost.gold} | ${l.population} | ${l.slots} | ${l.description} |`).join('\n')}

Food, Materials and Camp Gold are independent of the player's purse and XP. Tasks fund every stage without mandatory donations; a deterministic test reaches tier 5 with one resident in 57 starter contracts. Optional Storage contributions convert wood/stone/ore into Materials, mushrooms/herbs into Food, or personal coins into Camp Gold. Every player-facing transfer asks for confirmation and debits the exact source amount. Camp XP cannot be donated. Conversion tables and level costs are in data/camp.json.

At the current XP threshold, upgrade_pending becomes true and XP stays exactly at the cap. Subsequent mission XP is discarded, not banked; Food, Materials, Gold and worker XP continue. Confirming an affordable upgrade spends all three listed resources, advances the tier, resets Camp XP to zero and resumes accumulation. Tier 5 is final.

The first traveler is guaranteed after one game minute. Later candidates arrive approximately once per game day, subject to population capacity. They physically approach the board. Walk up to one and press E; accept or decline in the recruitment page. Declining produces a departing actor and schedules a different later candidate. Full camps explain their capacity limit. F7 exposes spawn/recruit tools for testing.

Workers persist stable IDs, names, appearance, five skills, level/XP, join time, residence, activity and assignment. They reuse LPC character layers/animations, camera-relative facing and the Phase 6 shared navigation grid. Residents walk among the board, storage, fire, meals and workbench; carrying has a crate prop and working uses existing action frames. At night or during storms they walk to shelter. Experienced/long-serving residents receive up to three veteran cottages, with visible inhabitants inside at night; newcomers retain tents. The player house and permanent workshop use the existing playable house/blacksmith interiors. Hamlet trader Rook uses the existing shop system.

Version 7 saves persist camp resources, pending upgrades, workers, visitor schedule, offers, mission records, contribution totals and building records. Versions 2–6 load with empty camp/map defaults. Numeric values, addresses, tasks and assignment consistency are validated before loading. House chests continue to use per-building Phase 6 storage; visit the actual chest to use it.

Limits: one owned camp, five predefined masterplans and ten residents; workers are abstract while on missions or far away. Mission activities are simple reusable animations, not a new animation library. Tents use abstract sleeping occupancy; houses have visible interiors. This phase does not implement freeform construction, agriculture, raids or a real-time offline production clock.
`);
write('CAMP_TASKS.md',`
# Camp task board

The board contains 12 visible contracts from 11 categories. The persistent cycle and seed vary duration and gold modestly; reopening the UI never rerolls offers. Accepting a contract replenishes that slot with a fresh stable contract ID while preserving the remaining offers. Refresh asks for confirmation and costs ${config.refresh_gold} Camp Gold; F7 offers a free debug refresh.

| Contract | Category | Camp level | Residents | Minimum resident level / skill | Base game hours | XP / Food / Materials / Gold |
|---|---|---:|---:|---|---:|---|
${config.tasks.map(t=>`| ${t.name} | ${t.category} | ${t.level} | ${t.workers} | ${t.worker_level} / ${t.skill} ${t.skill_level} | ${t.minutes/60} | ${t.rewards.xp} / ${t.rewards.food} / ${t.rewards.materials} / ${t.rewards.gold} |`).join('\n')}

The UI shows exact unmet camp level, facility, supply, mission-slot, worker-level and worker-skill requirements. Choose residents opens a picker with availability and the relevant skill. Server-side assignment repeats those checks, rejects duplicate/unknown workers and wrong party sizes, consumes task costs, marks every selected resident unavailable and records start/end game minutes. One to four residents are supported; starter forage/logging/stone/supply tasks require only one and no upfront supplies.

Mission time is (day−1)×1440 + minute from ValeLife. It progresses outdoors, in interiors and while the camp is unloaded, but not with wall-clock time while the application is closed. Workers visibly depart before being abstracted and return with supplies at completion. Resolution removes the pending record before granting rewards, records a bounded completion ledger, frees worker assignments and awards each worker XP. Worker level-ups improve skills. Saving after completion cannot replay the same reward; saving mid-task preserves its end time.

At upgrade_pending, mission Food/Materials/Gold and worker XP continue; Camp XP is discarded at its cap. No overflow survives a later upgrade. The final tier continues resource missions with no further camp level. Balance, costs, facilities, caps, offer durations, skill requirements and rewards are editable in data/camp.json.
`);
write('PHASE_7.md',`
# Phase 7 — cartography, travel and an owned hamlet

Implemented in the existing Godot project; the v0.6 runnable archive remains preserved. No account, paid asset or online service is needed to play.

The real map and minimap share terrain-derived tiles, fog, readable roads/water, service/quest icons, filters, bounded caching and integer logical coordinates. Up to 32 saved custom markers support names/icons/deletion and guarded travel. Loading covers synchronous destination streaming and a physical safe-landing check, including huge logical distances.

The owned camp has a validated/reserved expansion site, five visual stages, a permanent map marker, independent Food/Materials/Gold/XP, optional confirmed donations and capped XP until an affordable upgrade is confirmed. Its first physical traveler is guaranteed; residents have persistent appearance, skills, levels, assignments, daily activities and tent/cottage homes. The high-tier player house, veteran houses and workshop are enterable; Rook provides a hamlet shop.

Twelve task offers cover foraging, logging, mining, hunting, salvage, trading, patrol, exploration, supply, construction and special expeditions. Requirements explain locked tasks, the picker supports 1–4 residents, refresh costs Camp Gold, and saved game-clock missions grant rewards exactly once. A one-resident economy test reaches every tier without player donations.

Controls: Tab atlas, right-click charted ground for a marker, wheel map/minimap zoom, G camp, E interaction, Enter/Esc camp placement confirm/cancel, F7 Phase 7 tools. Existing camera orbit, 40–60° tilt, wheel zoom and obstruction hiding remain active.

New external assets: selected Kenney Survival Kit 2.0 GLBs plus their palette, CC0; source https://kenney.nl/assets/survival-kit . Existing KayKit Medieval Builder houses, Phase 6 furniture and licensed LPC sprites are reused. Terrain cartography and symbols are original code-generated assets. See ASSET_CREDITS.md and PHASE_7_ASSETS.json for provenance and checksums.

Validation is recorded in PHASE_7_TEST_RESULTS.json and the exact 35-step acceptance mapping in PHASE_7_ACCEPTANCE.md. The game was run graphically and screenshots reviewed; extended tests cover worker movement/shelter, actual pointer marker/recruitment controls, 3/4-worker missions, no-donation progression, malformed saves and older versions. A separate process tests reloaded jobs and one-time reward resolution. All tests use isolated test saves; the real journey is preserved.

Architecture and practical limits: MAP_SYSTEM.md, CAMP_SYSTEM.md and CAMP_TASKS.md. Important limits are chunk-based discovery, schematic icons, synchronous bounded travel loading, predefined camp layouts and abstract offscreen assignments. This is a local playable prototype, not a freeform colony builder.
`);
write('NEXT_STEPS.md',`
# Completed baseline and future work

Phases 1–7 are implemented in the existing project, including the requested limited camera tilt and obstruction hiding. Phase 7 adds terrain cartography, shared minimap, marker travel, persistent camp growth, residents and game-clock missions. Current results and exact acceptance coverage accompany PHASE_7.md.

Potential later briefs: optimize terrain tile sampling and world draw calls; expand camp layout/animation variants; add quests around camp residents or expeditions; consider building placement, farming, fishing or raids only as deliberate new features. Preserve old baseline archives, player saves, stable logical IDs and migration paths. Repeat the camera/combat/gathering/interior/streaming checks after structural changes.
`);
for(const file of ['README.md',root+'README.md']){
 let s=fs.readFileSync(file,'utf8').replace('Relic Vale · 0.6','Relic Vale · 0.7').replace('Relic Vale · Phase 6','Relic Vale · Phase 7').replace('Завершены этапы 1–6.','Завершены этапы 1–7.').replace('Формат 6 читает старые версии 2–5.','Формат 7 читает старые версии 2–6.').replace('Save version 6 reads versions 2–5.','Save version 7 reads versions 2–6.');
 const paragraph=file=== 'README.md'?'**Фаза 7:** настоящая карта и миникарта, сохраняемые метки и безопасное перемещение; собственный лагерь с пятью стадиями, жителями, заданиями и отдельными ресурсами. **Tab** — карта, **ПКМ по карте** — метка, **G** — лагерь, **F7** — отладка. При размещении зелёная площадка подтверждается **Enter**, отмена — **Esc**. [Отчёт фазы 7](relic_vale/docs/PHASE_7.md).':'**Phase 7:** terrain-derived atlas/minimap, persistent markers and guarded fast travel; an owned five-tier camp, physical residents, independent supplies, XP caps, contributions and game-clock tasks. **Tab** atlas, **right-click map** marker, **G** camp, **F7** diagnostics; **Enter/Esc** confirms/cancels a camp preview. See [Phase 7 report](docs/PHASE_7.md), [map](docs/MAP_SYSTEM.md), [camp](docs/CAMP_SYSTEM.md) and [tasks](docs/CAMP_TASKS.md).';
 if(!s.includes('**Фаза 7:**')&&!s.includes('**Phase 7:**')) s=s.replace(/^(#[^\n]*\n)/,'$1\n'+paragraph+'\n'); fs.writeFileSync(file,s);
}
const credit=root+'docs/ASSET_CREDITS.md';
let credits=fs.readFileSync(credit,'utf8');
if(!credits.includes('## Phase 7 — Survival Kit')) fs.appendFileSync(credit,'\n## Phase 7 — Survival Kit\n\nKenney, Survival Kit 2.0, downloaded 2026-09-10 from [the official pack page](https://kenney.nl/assets/survival-kit) and its linked ZIP. License: **CC0 1.0**, preserved in `assets/3d/phase7/LICENSE.txt`. Selected tents, fire pit/stand, chest, crates, barrels, bedroll, workbench, fences, signpost, wood pile and market canopy are used. Original GLBs and their `Textures/colormap.png` palette are retained; runtime code normalizes size and places them. The full download SHA256 is `C3586341B5932C87EB43D75D915434F47DAED168B17ED36A03E8CA9977C7443E`.\n\nLate-tier houses reuse KayKit Medieval Builder (CC0); room furniture reuses Phase 6 assets. Camp characters adapt the existing credited LPC layers under their recorded CC BY-SA terms, using the existing palette/animation pipeline. Atlas symbols and terrain tiles are original GDScript-generated graphics. Detailed selected-file hashes are in PHASE_7_ASSETS.json. No generative image service was used.\n');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const dir=root+'assets/3d/phase7/';
const files=fs.readdirSync(dir).filter(f=>f.endsWith('.glb')).map(f=>({file:'assets/3d/phase7/'+f,bytes:fs.statSync(dir+f).size,sha256:hash(dir+f)}));
write('PHASE_7_ASSETS.json',JSON.stringify({source:'https://kenney.nl/assets/survival-kit',download:'https://kenney.nl/media/pages/assets/survival-kit/4065a8185b-1712149243/kenney_survival-kit.zip',license:'CC0-1.0',date:'2026-09-10',archive_sha256:hash('downloads/kenney_survival-kit.zip'),files},null,2));
console.log('Phase 7 architecture, player documentation and asset provenance written.');
