import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const project='relic_vale', docs=project+'/docs/';
const read=name=>JSON.parse(fs.readFileSync(project+'/data/narrative/'+name+'.json','utf8'));
const C=read('companions'),Q=read('quests'),D=read('dialogue'),E=read('events');
const write=(name,text)=>fs.writeFileSync(docs+name,text.trim()+'\n');
const companions=Object.values(C).map(c=>`| ${c.name} | ${c.model.split('/').at(-1)} | ${c.role} | ${c.abilities.map(a=>a.name).join('; ')} |`).join('\n');
const quests=Object.values(Q).filter(q=>q.category==='Main').map((q,i)=>`| ${i+1} | ${q.name} | ${q.stages.map(s=>s.type).join(' → ')} |`).join('\n');
write('COMPANION_SYSTEM.md',`
# Companions

Four named companions extend the existing interactable, combat and quest systems. Generated camp workers retain their separate Phase 7 identity and occupations. The player can take one combat companion; the other recruited characters live at the camp.

| Companion | Actual KayKit model | Role | Abilities |
| --- | --- | --- | --- |
${companions}

## Data and recruitment

\`data/narrative/companions.json\` supplies stable IDs, models, portraits, biographies, personality tags, faction, default equipment, abilities, recruitment quest, three personal quests, camp anchors and contextual barks. Every companion is encountered at a persistent authored location and joins after their recruitment situation is resolved. Declining the invitation leaves it available for later. Bren watches the road east of Willowmere; Tarin stays at Split Fern Camp, Ilyra at the Quiet Scriptorium and Sera at Wayfarer's Rest. Dialogue and the journal provide the next objective.

\`ValeParty\` manages logical ownership and presentation. \`ValeCompanionActor\` uses CharacterBody3D movement, a capsule that does not block the player, a real skeletal model, and role-appropriate hand attachments. General/movement clips reuse the imported KayKit pipeline; CombatMelee, CombatRanged and Simulation add matching 23-bone clips. The portrait renderer in \`tests/phase9_slice.gd\` uses the same models and equipment in a controlled SubViewport. Four transparent 300 × 360 PNGs ship with the game.

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

Version 9 stores each companion's recruitment, level, approval, equipment, health, downed/waiting/traveling state, logical address and camp routine in \`narrative.companions\`. The active ID, order, stance and approval keys live alongside it. Personal progress stays in the existing \`quest_progress\` and \`completed_quests\` dictionaries; outcome flags remain in \`narrative.flags\`. Version 2–8 journeys receive default companion fields.

F10 exposes recruitment, active selection, approval changes/tier selection, downing, regrouping and quest completion. It changes the current journey and is intended for development. See [Phase 9](PHASE_9.md) for reproducible test entry points.
`);
write('NARRATIVE_SYSTEM.md',`
# Narrative architecture and content

Phase 9 extends the existing quest ledger, State signals, interactables, factions and journal. It adds no competing reputation or quest database. Authored content is in eight JSON files under \`data/narrative/\`: companions, quests, dialogue, locations, contacts, items, lore and events. Stable object/quest/dialogue IDs support future localization; this build's text is English.

## Quest stages

There are ${Object.keys(Q).length} added quests: four recruitment quests, twelve personal chapters, ten Act I chapters and nine faction chapters. A narrative quest uses the existing integer \`quest_progress[id]\` as its current stage. Stages support talk, interact, defeat, reach, collect, camp, recruit and choice objectives. \`State.objective_event\` feeds \`ValeNarrative.on_event\`; completion claims the existing quest reward once, then applies authored effects. Reconciliation recognizes already defeated unique enemies, inspected objects, collected materials, an established camp or a recruited companion, so exploring early cannot strand a quest.

The journal has Main, Companion, Faction, Side, Active and Completed views. It shows current stage text and personal chain counts. Track selects one primary narrative marker; Show on map selects that quest and centers its canonical location. Unstarted future narrative titles remain hidden. Side tasks from the original game remain available through the village conversation.

## Act I: the lantern covenant

The old road lights are failing because a freely witnessed oath was copied without its right of release. Rowan asks the traveler to investigate. Elowen and three faction contacts supply competing accounts. The journey uses exploration, recruitment, camp provisions, repairs, the existing multi-room crypt/boss and a defended crossing before a final charter.

| Chapter | Quest | Objective sequence |
| --- | --- | --- |
${quests}

The road policy supports either Compact oversight or Warden access with reputation tradeoffs. The ending can distribute the light to settlements, place it under a central charter, or establish joint witnesses if all three factions have sufficient standing. Persistent flags select epilogue text and physical location variants. The first act is complete; further acts are future content.

## Dialogue

${Object.keys(D).length} authored dialogue nodes contain speaker, text, ordered choices, conditions, effects, next node and personality tags. Conditional text variants react to resolved story/events. The UI shows speaker portraits for companions, requirement reasons, choices and a bounded recent-conversation history.

Conditions: flag, recruited companion, active companion, approval threshold, completed/not-completed/not-started quest, exact stage, profession level, faction reputation, carried item, camp tier, being at camp and defeated unique enemy. Effects: start quest, emit objective event, set flag, adjust approval/reputation, grant/consume item, recruit, unlock lore, grant coins. Consequential terminal nodes are locked after resolution, including stale-panel attempts. Camp conversations require physical camp proximity.

## Factions and consequences

Hester Vane (Lantern Compact), Warden Yew (Elderbough Wardens) and Orsa Venn (Keepers of the Veil) meet at Three Promises. Each offers three authored tasks. Stores/bridges, waterways/game trails and the corrected oath lead to different charter choices. These preserve competing practical interests. Completion adds reputation and an accord unlock. At Friendly standing (30+), existing merchants of that faction sell a signature accessory; hostile merchants refuse trade. Existing reputation price discounts remain in effect.

Authored sites have stable IDs and seed-deterministic canonical addresses. New placement searches for dry ground with enough space; existing saved addresses remain unchanged. Streaming creates/removes only presentation. Quest objects retain their inspected flags and unique enemies remain defeated. Cinder Watch, Reed Pass, the archive, well and crossing reconstruct their chosen variants from flags. The procedural terrain seed and base-generation random stream are untouched.

People, Factions, Places, Creatures, Relics and History entries unlock from meetings, exploration and quests. The lore screen filters these categories. Entries are concise and support the conversations.

## Save and tools

Version 9 adds \`narrative\` to the existing snapshot. Faction reputation, stock and unlocks stay in \`life\`; quest progress and completed rewards use their original fields. Validation rejects malformed identities, equipment slots, nonfinite/bad ranges, unknown events and invalid logical addresses. Versions 2–8 remain readable.

F10 can start/advance/complete/reset quests, inspect/set flags, set relationship and reputation tiers, and visit objectives. Reset is a developer operation; it does not reverse inventory rewards or every related world flag. Narrative source generation is \`tools/phase9_content.mjs\`; the earlier first-companion generator is an audit artifact and must not be rerun over expanded content.
`);
write('WORLD_EVENTS.md',`
# World events

Eight road stories extend \`State.life_data.events\`; the earlier traveling-merchant record remains supported. \`ValeWorldEvents\` reads templates from \`data/narrative/events.json\` and creates serial \`encounter_N\` records. These are temporary situations rather than new permanent procedural POIs.

| Event | World context | Resolution | Persistent effect |
| --- | --- | --- | --- |
${Object.values(E).map(e=>`| ${e.name} | ${e.where}; ${e.time}; ${e.weather.join('/')||'any weather'} | ${e.action} | ${e.outcome}; ${e.reward.faction} +${e.reward.reputation} |`).join('\n')}

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
`);
write('PHASE_9.md',`
# Phase 9 — companions and the lantern roads

The existing local RPG now has four authored companions, relationships and twelve personal chapters, a complete ten-chapter first act, nine faction chapters, eight contextual road events, persistent consequences and an expanded journal/lore interface. Four recruitment quests bring the added total to 35. Existing professions, camp workers, mounts, world streaming, combat, camera tilt and obstruction hiding remain integrated.

## Start playing

Use **Launch Relic Vale.bat** in the parent folder. Existing journeys migrate to save version 9. Speak to Rowan in Willowmere to begin the new lantern story; the option about the village retains the old tasks. Bren watches the road east of the village. Explore to meet Tarin Fen, Ilyra Venn and Sera Reed. Establish a camp and return to it for personal conversations.

**O** company/equipment, **Z** follow/wait/combat orders, **J** quest journal and lore, **Tab** atlas, **G** camp, **P** professions, **V** call horse, **E** interact/revive. **F10** narrative debug. Q/R or right drag orbit; vertical right drag/Page Up/Down tilt 18–60° outdoors; wheel zooms; Home resets to 50°. See [camera and camp changes](CAMERA_AND_CAMP.md).

The lowest perspective angle reveals the horizon. Distance haze completely conceals missing terrain at every draw-distance preset, including while chunks are building and after changing quality. Nearby foreground scenery softly blurs while the hero's focus plane and HUD remain sharp. A tree or roof hides only when the camera eye enters its mesh volume, with collision preserved; standing near an object or looking through it does not hide it. Houses and crypts keep the higher interior camera framing.

Establishing camp clears trees, rocks, bushes and small natural decoration from the future hamlet footprint and its margin. Houses, crypt entrances, village structures and story landmarks block placement. Clearance persists across streaming and save/load; it awards no gathering loot or profession XP.

To ride, reach camp tier 3, open **P → Mounts** and buy the horse for **180 copper**. Press **V** to call it, approach it and press **E** to mount. **Shift** gallops; **E** dismounts. Nearby combat temporarily prevents mounting.

| Companion | Model | Role | Abilities |
| --- | --- | --- | --- |
${companions}

Every companion has recruitment, three personal quests, approval/tier gates, signature gear and a final passive. One companion travels and fights; others visibly keep camp routines. Final choices alter faction standing and authored location variants. Faction accords add merchandise at Friendly standing. Road stories use weather, time, biome, road/settlement/ruin context, faction standing and story progress.

## Architecture, assets and tests

See [Companions](COMPANION_SYSTEM.md), [Narrative](NARRATIVE_SYSTEM.md), [World events](WORLD_EVENTS.md), [asset credits](ASSET_CREDITS.md), [initial audit](PHASE_9_AUDIT.md) and [release checks](PHASE_9_RELEASE_CHECKS.json). Test receipts contain individual assertions; the release checks aggregate completed runs and engine-log checks.

The first companion was completed and tested before expanding the roster: the original headless slice passed 52 checks and a fresh graphical reload passed 7. The expanded story run completes all four recruitments, all personal arcs, all ten main chapters and all faction chains, using real interactables/dialogue and normal timed attacks. Its setup loads the completed first-companion fixture; test helpers teleport between objective sites and supply required materials. Combat checks use player invulnerability to isolate progression and companion AI; they are not a claim of human balance testing.

Reproduce inside the actual Godot scene by setting APPDATA to the bundled \`tools/godot/userdata\` and passing one flag after \`--\`: \`--phase9-slice\`, \`--phase9-reload\`, \`--phase9-stories\`, \`--phase9-stories-reload\`, \`--phase9-events\`, \`--phase9-events-reload\`, \`--phase9-acceptance\`. Run fresh-load flags in separate processes after their fixture-producing runs. \`--phase9-portraits\` rebuilds portraits and requires a subsequent editor import. Logs are in workspace \`downloads\`; images are in \`docs/screenshots\`. Personal saves are not test outputs.

The graphical acceptance run checks imported portraits/animations, actual movement input, mounted following, floating-origin shifts, a billion-chunk transition, home entry/exit, down/revive, inventory ownership and faction equipment. Event checks cover all eight outcomes, actual escort movement, camera/context spawn rules, expiration, reward uniqueness, bounded storage, malformed saves and fresh-process partial combat reconstruction. Additional flags --phase9-polish, --phase9-camera and --phase9-camera-reload exercise the 720p UI, camera containment, horizon rays, all four draw-distance presets, incomplete chunks, rendered blur/focus detail, protected camp placement, clearance and fresh-process persistence. The camera test produces the fixture consumed by its reload flag.

## Practical scope

This is a local single-player prototype, with one active companion and a complete first story act. Companion navigation uses a bounded local grid with safe hidden recovery, rather than a world-spanning navmesh. Important companions use real KayKit skeletal models; the player and ordinary residents retain the existing LPC rendering pipeline. The hand silhouette follows combat role, while gear statistics and affixes can change. Text is English and barks are text-only. Event templates are deliberately compact. Terrain/scenery draw calls still dominate on integrated graphics; use the existing graphics presets. GUI checks used the Dummy audio driver because the host audio output was unavailable; audible playback is not claimed as verified.

The version 0.8 baseline archive remains preserved. The 0.9 package includes source project, local engine, runtime assets, licenses, tests and documentation; it excludes personal saves and editor caches.
`);
write('NEXT_STEPS.md',`
# Completed baseline and future work

Phases 1–9 extend the same RPG. Phase 9 adds four authored companions, approval and personal quests, the complete first lantern-story act, faction charters/stock, contextual events and persistent narrative presentation. See [Phase 9](PHASE_9.md) and its validation receipts.

Future work can expand later acts, add more event variants and authored camp exchanges, tune encounters with human playtesting, profile terrain draw calls, improve long obstacle routes and add more equipment silhouettes. Additional active companions would require formation, encounter-balance and UI work. Voice acting, romance, additional mount species and a localization translation are separate content scopes.

The requested camera horizon, foreground blur, camera-entry hiding and persistent camp clearance are included in this baseline. Phase 10 has not started; its scope will follow the next brief.

Preserve canonical IDs, old baseline archives and player saves. Keep each journey JSON with its .chunks folder; retain migrations from versions 2–8. Recheck companion transitions, camera obstruction restoration, gathering, interiors, mount travel, economy and narrative reward uniqueness after structural changes. Add content through the current quest/reputation/event systems and retain all source license notices.
`);
const creditTitle='## Phase 9 — named companions and compatible skeletal animations';
let credits=fs.readFileSync(docs+'ASSET_CREDITS.md','utf8').split(creditTitle)[0].trimEnd();
credits+=`\n\n${creditTitle}\n\n| Asset / creator | Primary source | License | Use |\n| --- | --- | --- | --- |\n| KayKit Adventurers 2.0 — Kay Lousberg | [Official pack](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | Existing Knight, Ranger and Mage reused; Rogue, its texture and compatible sword/shield/bow/staff/dagger meshes selected from the already downloaded pack |\n| KayKit Character Animations 1.1 — Kay Lousberg | [Official pack](https://kaylousberg.itch.io/kaykit-character-animations) | CC0 1.0 | Rig_Medium CombatMelee, CombatRanged and Simulation clips on the matching 23-bone Adventurers rigs; existing General and MovementBasic packs reused |\n| Kenney Survival Kit 2.0 | [Official pack](https://kenney.nl/assets/survival-kit) | CC0 1.0 | Previously credited tents, bedrolls, signs, chests, supplies and campfires reused for story/event locations |\n\nThe new animation ZIP is 14,858,957 bytes; SHA-256 \`65882F31F905AD2E953819648A59287CDEAB8F623908D5EF701971D3758BE20F\`. The source receipt and skeleton/clip audit are in workspace downloads. Pack notices are retained beside the imported animation and equipment files. No ripped models or paid content were used. The coherent existing KayKit family was chosen to avoid mixing humanoid rigs and styles. This phase does not claim new full-body Quaternius UAL retargeting.\n\nFour transparent 300 × 360 companion portraits were rendered locally in Godot from the actual credited models and hand equipment; no unrelated portrait illustration or image-generation service was used. Narrative text, JSON definitions, dialogue/atlas integration and runtime behavior are project-authored. Ordinary event NPCs continue to use the credited LPC pipeline under its existing attribution/share-alike terms. File hashes are in [PHASE_9_ASSETS.json](PHASE_9_ASSETS.json).\n`;
fs.writeFileSync(docs+'ASSET_CREDITS.md',credits);
const files=new Set(Object.values(C).flatMap(c=>[c.model.replace('res://',''),c.portrait.replace('res://','')]));
function walk(folder){for(const entry of fs.readdirSync(folder,{withFileTypes:true})){const p=path.join(folder,entry.name);if(entry.isDirectory())walk(p);else if(!p.endsWith('.import'))files.add(path.relative(project,p).replaceAll('\\','/'));}}
walk(project+'/assets/3d/phase9'); files.add('assets/3d/phase4/adventurers/rogue_texture.png');
fs.writeFileSync(docs+'PHASE_9_ASSETS.json',JSON.stringify({portraits:4,companions:4,license:'CC0 for KayKit/Kenney selections; existing LPC terms for ordinary residents',files:[...files].sort().map(file=>({file,bytes:fs.statSync(project+'/'+file).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(project+'/'+file)).digest('hex')}))},null,2)+'\n');
let manual=fs.readFileSync(project+'/README.md','utf8');
manual=manual.replace(/^# Relic Vale · Phase \d+/,'# Relic Vale · Phase 9');
manual=manual.replace(/\*\*Phase 8:\*\*[^\n]+/, '**Phase 9:** four named companions, twelve personal chapters, ten main-story chapters, nine faction chapters and eight contextual world events. **O** company, **Z** commands, **J** journal/lore, **F10** narrative tools. Speak to Rowan in Willowmere to begin. See [Phase 9](docs/PHASE_9.md), [companions](docs/COMPANION_SYSTEM.md), [narrative](docs/NARRATIVE_SYSTEM.md) and [events](docs/WORLD_EVENTS.md). Phase 8 professions, fishing, cooking, farming and mounts remain available through **P**, with **G** for camp and **Tab** for atlas.');
manual=manual.replace('Save version 8 reads versions 2–7 and defaults new profession/activity fields.','Save version 9 reads versions 2–8 and defaults companion/narrative/event fields.');
manual=manual.replace('Humanoids retain LPC directional sprites with adapted poses and real hand props; they were not replaced with skeleton rigs.','The player and ordinary residents retain LPC directional sprites with adapted poses and real hand props. Named companions use coherent KayKit skeletal models and compatible animations.');
if(!manual.includes('Phase 9 test flags:'))manual+='\nPhase 9 test flags: --phase9-slice, --phase9-reload, --phase9-stories, --phase9-stories-reload, --phase9-events, --phase9-events-reload and --phase9-acceptance. Full instructions and test limitations are in docs/PHASE_9.md.\n';
fs.writeFileSync(project+'/README.md',manual);
manual=manual.replace(/^Q\/R or horizontal right drag[^\n]+/m,'Q/R or horizontal right drag orbit the camera; vertical right drag or Page Up/Down tilts within 18–60 degrees outdoors, revealing the horizon at the lowest angle. Wheel zooms; Home resets to 50 degrees. Distance haze hides unloaded terrain, and near foreground scenery blurs. Only objects containing the camera eye disappear temporarily; collision remains. Interiors keep at least 40 degrees of downward tilt. Camp establishment clears natural obstacles while protecting houses and landmarks. See [camera and camp details](docs/CAMERA_AND_CAMP.md).');
fs.writeFileSync(project+'/README.md',manual);
let outer=fs.readFileSync('README.md','utf8').replace(/^# Relic Vale · 0\.\d+/,'# Relic Vale · 0.9');
outer=outer.replace(/\*\*Фаза 8 завершена:\*\*[^\n]+/,'**Фаза 9:** четыре именованных спутника, отношения, 12 личных глав, 10 глав первого сюжетного акта, девять фракционных заданий и восемь событий в мире. [Отчёт и проверки](relic_vale/docs/PHASE_9.md). **O** — спутники и их снаряжение, **Z** — команды, **J** — задания и знания, **F10** — отладка историй. Начните новый сюжет разговором с Роуэном в Уиллоумере; Брен дежурит к востоку от деревни.');
outer=outer.replace('Формат 8 читает версии 2–7.','Формат 9 читает версии 2–8.');
outer=outer.replace(/^\*\*Камера:\*\*[^\n]+/m,'**Камера:** Q/R или горизонтальное движение с зажатой ПКМ — поворот; вертикальное движение ПКМ или Page Up/Down — наклон 18–60°. Внизу виден горизонт; дымка скрывает непрогруженную даль. Близкий передний план размывается, объект скрывается только при попадании камеры внутрь его объёма. Колесо — приближение, Home — сброс. При установке лагеря природные препятствия расчищаются; дома, деревни, входы и сюжетные места защищены. [Подробности](relic_vale/docs/CAMERA_AND_CAMP.md).');
fs.writeFileSync('README.md',outer);
console.log('Phase 9 documentation and asset manifest written.');
