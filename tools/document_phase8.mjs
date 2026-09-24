import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root='relic_vale', docs=root+'/docs';
const json=n=>JSON.parse(fs.readFileSync(root+'/data/'+n+'.json','utf8'));
const skills=json('professions'),fish=json('fish'),crops=json('crops'),recipes=json('cooking'),items=json('phase8_items'),resources=json('profession_resources');
const write=(name,text)=>fs.writeFileSync(docs+'/'+name,text.trim()+'\n');
const table=(heads,rows)=>'| '+heads.join(' | ')+' |\n| '+heads.map(()=>'---').join(' | ')+' |\n'+rows.map(r=>'| '+r.join(' | ')+' |').join('\n');
const friendly=s=>s.replaceAll('_',' '), name=id=>items[id]?.name||friendly(id), any=s=>s==='any'?'Any':s;
const effect=f=>`${friendly(f.stat)} +${f.stat==='max_hp'?f.value:Math.round(f.value*100)+'%'} / ${f.minutes} game minutes`;
write('PROFESSIONS.md',`# Professions — Phase 8

Open **P → Professions**. Woodcutting, Mining, Herbalism, Fishing, Cooking and Farming each start at level 1 and cap at 25. They are independent of combat/class level and camp resident experience. Progress is stored in save version 8; earlier saves receive level-1 defaults.

The cost to advance from level L is **40 + 12L + L² XP**: 53 XP at level 1, 260 at level 10 and 904 at level 24. Overflow carries into later levels; XP stops at level 25. XP is earned only on completed activities. Cancelled gathering, casts, watering and worker production cannot grant personal XP.

${table(['Profession','Level 5','Level 10','Level 15','Level 20'],Object.values(skills).map(s=>[s.name,...s.unlocks.map(u=>u.name)]))}

Unlock labels summarize the progression. Individual resources, crops, fish and recipes also have explicit minimum levels in their tables. A high-tier tool does not bypass skill requirements, and high skill does not bypass a required tool tier.

## Activity rewards

- Existing wood/ore/herb nodes: 8 + 3 × required hits XP on complete harvest. New resource rewards are in the table below.
- Successful fish: 14 + round(30 × difficulty) XP. Junk and cancelled catches grant no Fishing XP.
- Plant a seed: 3 Farming XP. Manual harvest: 18 + crop minimum level XP. Preparing and watering grant none.
- Cooking: each recipe grants its listed XP after consuming all ingredients at the correct physical station.
- Profession-XP food multiplies the completed activity reward. Camp residents earn their own existing worker XP and never advance player professions.

Woodcutting/Mining/Herbalism grant a 5% chance of one extra material at level 5, rising to 10% at level 20, and 10% faster gathering at level 15. Woodcutting 10 also allows resin drops. Farming 15 adds a 10% chance of an extra crop; level 20 improves returned-seed chance from 30% to 45%. Fishing level and rod tier widen the catch zone.

## Rare resources

${table(['Resource','Profession','Minimum level','Tool tier','Condition','XP'],Object.entries(resources).map(([id,r])=>[name(id),friendly(r.profession),r.min_level,r.tool?r.tool+' '+r.tool_tier:'Hand gathering',any(r.condition),r.xp]))}

Forest weights favor hardwood/ancient timber and forest herbs; rocky terrain favors coal/silver/star ore; banks favor river herbs/night bloom; meadows favor healing herbs/dawn flowers. High-level candidates have an additional rarity roll. Dawn means 05:00–08:00, night 20:00–05:00, and Star ore requires Storm. Nearby discoveries become persistent atlas notes.

New deposits use an independent seed stream and IDs containing /phase8/. Earlier generated resources retain their identities, hit counts and renewal records. Only loaded chunks instantiate their additional resource node. Existing inventory, tool slot, specialist trade, crafting and save/chunk storage are reused.

See [fishing](FISHING.md), [cooking](COOKING.md), [farming](FARMING.md), [mounts](MOUNTS.md) and [Phase 8 validation](PHASE_8.md).
`);
write('FISHING.md',`# Fishing — Phase 8

Buy a Willow fishing rod and bait from **Iona in Willowmere's provisions shop**, or the basic supplies from general/traveling/carpenter merchants. Equip the rod in **I → Tools → Equip to Tool**, choose bait in **P → Fishing**, stand on dry ground and face open freshwater. **E** casts when another interaction is not selected. Fish merchants also sell reinforced and Moonsteel rods.

The cast must reach genuine terrain water 2.5–6.5 metres ahead, outside the starting village footprint, with an unobstructed line from the bank. A depth check rejects dry ground and shallow road crossings. Three of four open-water samples classify a lake; narrower water is a river. This uses the streamed terrain's water field, so it also works outside the starting area.

The sequence is **cast → wait → bite → reel → catch/failure**. After the float bites, press Space/left mouse before the 2.2-second response window closes. Hold Space/left mouse to move the green catch zone right; release to move left. Keep the moving fish inside the zone to fill progress. Time outside raises tension and reduces progress. Higher difficulty needs more control. Escape, walking away/teleporting, opening another menu, stun, damage or changing tools cancels the activity. It awards nothing on cancellation.

Three bait types are consumed at cast time: dough for ordinary catches, insects for faster bites and a 25% preference for river species, and moon bait for stronger rare odds (Fishing 10 required). They do not bypass a fish's level/time/weather/water restrictions. Base selection weights are Common 1.0, Uncommon 0.4, Rare 0.16, Epic 0.045 and Legendary 0.012; insect/moon rare multipliers are 1.35 and 2.0. These are relative weights among eligible species, not fixed catch percentages. Rod tiers and personal skill widen the catch zone. Common species remain available in all weather and at all times.

## Species

${table(['Fish','Rarity','Level','Water','Time','Weather','Weight kg','Base sell copper'],Object.values(fish).map(f=>[f.name,f.rarity,f.min_level,any(f.water),any(f.time),any(f.weather),f.weight_min.toFixed(2)+'–'+f.weight_max.toFixed(2),f.sell_price]))}

Day: 07:00–19:00. Night: 20:00–05:00. Dawn: 05:00–08:00. Clear/Rain/Storm/Mist conditions refer to the existing world weather. All 20 species can be grilled; specific advanced recipes require their named fish. The table gives baseline sell values; existing merchant/reputation rules determine actual quotes.

The journal records caught species, count, largest weight/size, day, water type and logical location. Uncaught entries use the existing unknown-icon treatment. Catch results can also include a waterlogged boot, message bottle, chart fragments or a treasure chart. Three fragments can be assembled in **P → Exploration**. Charts mark approximate search areas on the atlas; caches reward only once.

## Assets and simulation

Quaternius Cute Fish Pack supplies 20 real fish models, three rods and lure models (CC0). Two nearby animated Tetra models use the pack's Swimming_Normal clip only while fishing; they are removed when the activity ends. The float and line are actual world objects. Catch/journal icons are transparent renders of the supplied models. Fantasy species names and ecology are game definitions rather than biological claims.

The player retains directional LPC sprites. The held rod follows normalized upper-arm pitch from Quaternius UAL2 Standard's OverhandThrow clip, adapted to the existing hand-prop system. This is a casting adaptation, not a fully retargeted humanoid fishing animation; the free Standard pack does not contain a dedicated fishing clip. Attribution and transformations are recorded in [asset credits](ASSET_CREDITS.md).
`);
write('FARMING.md',`# Farming and camp occupations — Phase 8

At **camp tier 3**, eight fixed beds appear in reserved ground beside the production chest. Higher camp stages preserve these beds and avoid their footprint. Buy seeds and a watering can from **Nell**, choose a seed in **P → Garden**, then use **E** at a bed to prepare, plant, water and eventually harvest. Equip the watering can in the Tool slot for watering. Preparation and planting use the character's hands.

## Crops

${table(['Crop','Minimum Farming','Moist game minutes','Normal yield'],Object.values(crops).map(c=>[c.name,c.min_level,c.minutes,c.yield]))}

Each crop has five visible stages: seed, young (12%), growing (38%), mature (70%) and harvestable (100%). Imported Quaternius Ultimate Crops stage models provide the growth visuals. The initial seed is a tiny crop mesh; sunpetal reuses a compatible crop variant, and the other species use their supplied growth families.

One watering keeps soil moist for eight game hours. Dry soil pauses growth; it does not destroy the crop. Rain and Storm water beds automatically. Only moist elapsed game minutes advance growth. The save stores crop, planting/progress times, moisture deadline, last processed time, replant seed preference and harvest count for each bed. Visible models are reconstructed from that state.

The clock resolver runs independently of the camp scene. Leaving several chunks away unloads the garden graphics but preserves its game-clock progression. Returning rebuilds the correct stages. A bounded catch-up loop processes 30-minute intervals, retaining any backlog and the weather history needed by unprocessed intervals. It does not use elapsed real-world time while the application is closed.

Manual harvest awards Farming XP and full crop yield. Seed recovery chance starts at 30% and improves to 45% at Farming 20. Farming 15 adds a 10% chance of one bonus crop. Crops remain useful for meals and specialist trading; rare cultivars stay primarily a player activity.

## Resident occupations

Use **G → Residents** (also linked from the Garden page) to select a continuing role. Roles reuse camp workers, skill values, levels, XP and the existing day/night actor system. A resident cannot have a continuing occupation and an expedition simultaneously; release one before assigning the other.

${table(['Role','Camp tier','Production'],[
['Farmer',3,'Waters, harvests and replants prepared beds using seeds from the production chest. Grows staples requiring Farming 5 or less.'],
['Cook',2,'Uses common fish/meat/carrot/forest ingredients from the production chest to make basic meals.'],
['Fisher',3,'Supplies common minnows only when a real fishing bank is found within 26 metres of camp.'],
['Forager',2,'Supplies small quantities of wild herbs.'],
['Woodworker',3,'Consumes 3 wood from the production chest to produce 1 plank.']])}

Supply seeds and ingredients through the physical production chest next to the beds, using the existing household storage interface. This is distinct from the camp's abstract food/material/gold meters. Workers deposit items in the same chest. Their normal production cycle takes 180 working game minutes, improved by up to 30% by existing worker skills. They work 06:00–20:00, return to shelter at night, and the farmer pauses tending during storms while rainfall keeps beds watered. Failed recipes cannot create output without inputs.

The farmer harvests one fewer crop than a manual harvest (at least one) and gains worker XP, never player XP. Catch-up is idempotent: resolving the same clock time again cannot repeat rewards. When the camp is visible, residents walk to their work locations and use compatible existing action poses. This is a deliberately modest local supply system with five occupations, not a city-wide production-chain simulation.
`);
write('COOKING.md',`# Cooking — Phase 8

Use a physical cooking station and select a recipe through the existing crafting interface. Campfire meals are available at the starting village and owned camp. A cooking pot is installed at camp tier 2; a kitchen is installed at tier 4. Player homes and taverns also contain kitchens. Recipes require the matching station within three metres, all ingredients and the listed Cooking level.

${table(['Recipe','Level','Station','Ingredients','Heal HP','Food effect','XP'],recipes.map(r=>[r.name,r.min_level,friendly(r.station),r.id==='cook_grilled_fish'?'Any fish ×1':Object.entries(r.input).map(([id,n])=>name(id)+' ×'+n).join(', '),items[r.output].heal,effect(items[r.output].food),r.xp]))}

Grilled fish accepts any caught species and selects the lowest-value carried fish; the crafting UI shows the actual ingredient before cooking. Other fish recipes require their named species. Harvest pie and Elder roast additionally require recipe knowledge, purchased from general/tavern merchants; treasure caches can teach Harvest pie.

Use cooked food from the inventory. It heals immediately and applies **one active food effect** until its game-clock deadline. Eating another meal replaces the old effect, including the same meal, so repeated use cannot stack bonuses. Possible effects improve health, damage, movement, gathering speed, fishing odds or profession XP. Expiry recalculates stats. The active meal and remaining game-clock deadline survive saving and loading.

Fish, harvested crops, herbs and raw meat connect gathering/fishing/farming to cooking. Wolves can drop raw meat and Nell sells it. Existing tavern/general shops also sell a few simple meals. Prepared-food prices are bounded below the cost of buying their ingredients even under best purchase/resale modifiers, preventing a buy/cook/sell money loop.

Meal models come from Quaternius Ultimate Food (CC0). The pot and dishes are real imported props; food icons are model renders. The recipe catalogue and balance live in data/cooking.json and data/phase8_items.json.
`);
write('MOUNTS.md',`# Mounts — Phase 8

At **camp tier 3**, purchase **Bramble** for **180 copper** through the stable interaction or **P → Mounts**. Ownership is persistent. The physical stable uses Quaternius OpenBarn plus an existing water barrel. The owned horse is visible in the stall while stabled and the camp is loaded.

**V** calls the horse onto clear nearby dry ground. Approach and press **E** to mount; E or V dismounts, and **Shift** gallops. The call binding can be changed to T or Y in Settings → Controls. The default controls are also displayed on the Mounts page. Walking speed is multiplied by **1.5 while riding** and **2.3 while galloping**.

The horse is the real Quaternius Ultimate Animated Animals Horse model with authored Idle, Walk and Gallop animations. The existing character remains visible, with a seated adaptation of its selected LPC appearance. The camera eases outward slightly while riding and retains Q/R orbit, right-drag orbit/limited tilt, wheel zoom and obstruction hiding.

Mounting is blocked inside buildings/dungeons, during another activity or close to combat threats. A larger mounted collision capsule uses the existing player movement and terrain collision. Attacks, abilities and gathering are blocked while mounted, including HUD buttons. Dismount searches for a clear nearby player position. Entering an interior parks the horse outside; respawn also safely parks it.

## Infinite world and saves

Mounted movement remains owned by the existing CharacterBody3D. The visual horse is parented to that player, so origin rebasing and logical teleports keep the rider together. An unmounted waiting horse is stored as a logical chunk-string address plus local coordinates; it is instantiated only near the current region and removed from the scene when far away. A nearby teleport reconstructs its render position from that address.

Save version 8 stores owned mounts, active ID, name, species, state and logical address. Saving while mounted captures the current address immediately. Loading a ridden state restores ownership in a safe stabled state; call the horse again with V. Ownership is not tied to a loaded camp scene. Billion-chunk coordinates, multi-chunk galloping, nearby/distant teleports, stabling, interior transitions and a fresh process reload are included in validation.

There is one purchasable species and one practical stall in this phase. The rider uses a seated sprite adaptation with a bareback mount; no separate saddle asset or rigged 3D rider is claimed. Horse breeding, equipment progression and mounted combat are outside this implementation.
`);

const credits=`## Phase 8 — professions, fishing, crops, food and mounts

| Pack / creator | Primary source | License | Integrated use |
| --- | --- | --- | --- |
| Cute Fish Pack — Quaternius | [Official page](https://quaternius.com/packs/cutefish.html) | CC0 1.0 | 20 species, three rod tiers, lure/float, Swimming_Normal fish clips |
| Ultimate Crops — Quaternius | [Official page](https://quaternius.com/packs/ultimatecrops.html) | CC0 1.0 | Imported crop families and stages, harvested crop models |
| Ultimate Food — Quaternius | [Official page](https://quaternius.com/packs/ultimatefood.html) | CC0 1.0 | Cooking pot, dish/ingredient models and meal icons |
| Farm Buildings — Quaternius | [Official page](https://quaternius.com/packs/farmbuildings.html) | CC0 1.0 | OpenBarn stable and fence model selection |
| Watering Can — Isa Lousberg | [Author's model page](https://poly.pizza/m/hybuUvYsri) | CC0 / public domain | Actual held watering-can mesh |
| Universal Animation Library 2 Standard — Quaternius | [Official page](https://quaternius.com/packs/universalanimationlibrary2.html) | CC0 1.0 | Farm_Harvest, Farm_PlantSeed, Farm_Watering and OverhandThrow upper-arm samples |
| Ultimate Animated Animals — Quaternius | [Official page](https://quaternius.com/packs/ultimateanimatedanimals.html) | CC0 1.0 | Existing Horse glTF reused with authored Idle/Walk/Gallop clips |

The free Standard UAL2 distribution contains 43 clips. Phase 6 audited it without runtime use; **Phase 8 now uses normalized right upper-arm pitch samples** to drive the existing held-tool adapter. It does not retarget an entire humanoid skeleton and does not claim a dedicated fishing clip. The torso retains compatible directional LPC frames. Seated rider frames are runtime adaptations of the same LPC layers and remain covered by the LPC attribution/share-alike terms above.

81 selected Quaternius FBX models were converted to GLB in Blender 5.2 with authored animations retained. Empty source mesh nodes were removed and the source FBX alpha interpretation was corrected to opaque while preserving material colors. The watering can is the author's original GLB. Runtime assets include pack notices and the existing CC0 license. Source FBXs, download receipts and conversion records stay in workspace downloads; the release needs only the converted runtime selection.

**Generated support assets:** 60 transparent PNG icons rendered in Godot from the credited meshes; a sampled motion JSON; the procedural fishing line/meter, soil patches and map symbols; runtime seated LPC frame adaptation. These are support work, not generated replacement fish/crop/horse models. No generative image service was used. Model/icon/motion hashes are listed in PHASE_8_ASSETS.json. Existing hoof/water/gathering sounds reuse Phase 6 credited recordings.
`;
let oldCredits=fs.readFileSync(docs+'/ASSET_CREDITS.md','utf8').split('## Phase 8 —')[0];
fs.writeFileSync(docs+'/ASSET_CREDITS.md',oldCredits.trimEnd()+'\n\n'+credits);
const files=[];
function walk(dir){for(const f of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,f.name); if(f.isDirectory())walk(p);else if(!p.endsWith('.import'))files.push(p);}}
walk(root+'/assets/3d/phase8');walk(root+'/assets/ui/phase8');files.push(root+'/data/profession_motion.json');
write('PHASE_8_ASSETS.json',JSON.stringify({phase:8,models:files.filter(f=>f.endsWith('.glb')).length,icons:files.filter(f=>f.endsWith('.png')&&f.replaceAll('\\','/').includes('/ui/phase8/')).length,files:files.map(file=>({file:file.replaceAll('\\','/').replace(root+'/',''),bytes:fs.statSync(file).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')}))},null,2));

const logSpecs=[['Gameplay, native GUI','phase8-gui-validation.log'],['Gameplay, headless','phase8-test-development2.log'],['Fresh process reload','phase8-fresh-reload.log'],['Edge cases, native GUI','phase8-edge-release.log'],['Phase 7 real save migration','phase8-phase7-reload.log'],['Gathering/residents/economy regression','phase8-phase6-regression.log'],['Combat regression','phase8-combat-regression.log'],['Camera/graphics/UI regression, native GUI','phase8-presentation-regression.log'],['Final bait/cooking/kitchen checks, native GUI','phase8-final-check.log']];
const runs=[];
for(const [suite,file] of logSpecs){const p='downloads/'+file;if(!fs.existsSync(p))continue;const text=fs.readFileSync(p,'utf8');const m=text.match(/\b\w*RESULT:?\s+(\d+) passed\s*[,/]?\s*(\d+) failed/);if(!m)continue;runs.push({suite,log:file,passed:+m[1],failed:+m[2],engine_errors:(text.match(/(?:SCRIPT ERROR:|ERROR:)/g)||[]).length,checks:text.split(/\r?\n/).filter(l=>/^(PHASE8 )?(PASS|FAIL)[: ]/.test(l))});}
const total={passed:runs.reduce((n,r)=>n+r.passed,0),failed:runs.reduce((n,r)=>n+r.failed,0)};
if(runs.some(r=>r.log==='phase8-presentation-regression.log'))write('PHASE_8_PERFORMANCE.json',JSON.stringify({note:'Snapshots during automated scene/preset transitions on Radeon Vega 8 with fixed simulation FPS. These are not a controlled steady-state benchmark.',...JSON.parse(fs.readFileSync(docs+'/PHASE_6_PRESENTATION.json'))},null,2));
write('PHASE_8_TEST_RESULTS.json',JSON.stringify({phase:8,...total,note:'Counts are assertions across the listed runs; the GUI and headless gameplay suites intentionally exercise the same 74 assertions in different modes.',runs},null,2));
write('PHASE_8.md',`# Phase 8 — implemented release

The existing Godot project now includes six independent professions, 20 fish species with an interactive fishing loop, 24 cooking recipes, eight crops, five continuing camp occupations, a persistent animated horse, rare profession resources and treasure charts. Phase 7 atlas/camp systems and the earlier limited camera tilt/obstruction hiding remain in place. All new models and runtime data are bundled locally.

## Play

Launch **Launch Relic Vale.bat** from the workspace root. **P** opens professions, journal, garden, mounts and exploration; **I** equips rods/tools; **E** casts or interacts; **Space/left mouse** controls the fishing zone; **V** calls/dismounts the horse; **Shift** gallops; **G** manages resident occupations. **F8** contains test controls for skill levels, supplies, water/bites, crop stages/rain, camp farm, mounts and charts. Normal progression does not require debug controls.

Buy a rod/bait from Iona and seeds/watering can from Nell in Willowmere's shop. Basic supplies are also available from existing merchants. Establish and raise a camp through the existing tier system; tier 3 unlocks beds and the stable. Cook at the campfire, tier-2 cooking pot or a kitchen. See [professions](PROFESSIONS.md), [fishing species and rules](FISHING.md), [cooking recipes](COOKING.md), [farming and residents](FARMING.md) and [mounts](MOUNTS.md).

## Validation

Tests ran inside the actual Godot 4.7.2 scene, including native-window rendering on AMD Radeon Vega 8. The main gameplay script uses physical gathering actions, actual cast/bite/reel input, manual planting/watering/harvesting, three recipes and food replacement/expiry, then leaves the farm unloaded, advances the world clock, returns and verifies worker production. It purchases/mounts the horse and physically gallops through at least three chunks before testing teleport, treasure rewards and saves. A separate Godot process reloads that save.

${table(['Run','Passed','Failed','Engine errors'],runs.map(r=>[r.suite,r.passed,r.failed,r.engine_errors]))}

Recorded assertion executions: **${total.passed} passed / ${total.failed} failed** across ${runs.length} completed runs. GUI/headless gameplay assertions overlap intentionally. Exact checks and log names are in [PHASE_8_TEST_RESULTS.json](PHASE_8_TEST_RESULTS.json). Workspace logs remain under downloads; release documents include the result manifest and screenshots.

Edge cases cover occupation/expedition exclusion, cook/forager/woodworker/fisher catch-up, no personal worker XP, dry soil/rain, level AND tool gates, level cap, malformed saves, schemas 2–7, merchant arbitrage, all 20 rendered fish icons, mount binding, invalid casts, animation instantiation, cancellation, direct HUD combat restrictions, billion-chunk ownership, nearby horse repositioning, all five dashboard pages, player-home kitchen, full hamlet layout and 150% UI scale.

Test outputs use separate journey filenames. The player's journey is read only for compatibility and is never used as a test output. Save schema 8 accepts schemas 2–7 and defaults the new fields. Keep each journey JSON together with its .chunks folder. The phase-7 baseline ZIP remains preserved; the phase-8 ZIP includes the engine, launchers, source and assets, with no personal saves or import cache. Its external receipt contains the final SHA-256 and per-file ZIP verification count.

Release gates also verify a fresh editor import and main-scene startup in a separate project copy with separate userdata, without relying on the working project's import cache. [Release checks](PHASE_8_RELEASE_CHECKS.json) record the clean result and asset/link validation. [Performance snapshots](PHASE_8_PERFORMANCE.json) retain scene/preset measurements; they are transition-time diagnostics rather than a controlled benchmark.

## Visual evidence

![Fishing in the running game](screenshots/phase8-cast-final.png)
![Eight beds in the full camp](screenshots/phase8-farm-world-final.png)
![Seated rider on animated horse](screenshots/phase8-rider-final.png)
![Journal with model icons](screenshots/phase8-fishing-final.png)
![Garden page at 150 percent scale](screenshots/phase8-ui-150.png)
![Usable kitchen and visible cooking pot](screenshots/phase8-home-kitchen-final.png)

## Scope and practical limits

- Fish ecology and rarity are fantasy gameplay rules. Two fish animate near an active cast; there is no permanent ecosystem simulation in unloaded water.
- Humanoids retain LPC sprites. Imported UAL2 arm curves drive held tools; riding uses a seated sprite adaptation. This is not full skeletal retargeting. The horse itself and nearby fish use authored skeletal animations.
- Eight camp beds, one purchasable horse and a basic barn stall are implemented. Crop/resident catch-up follows game time, not real-world time while the game is closed. Residents produce small quantities of common supplies and do not train player professions.
- Rare deposits reuse compatible earlier tree/rock/plant meshes with material variants. Source models/animations, conversions, generated icons and their licenses are detailed in [asset credits](ASSET_CREDITS.md) and [PHASE_8_ASSETS.json](PHASE_8_ASSETS.json).
- Rendering shares the existing draw-call limits on Vega 8. Lower graphics presets remain available; this phase does not promise a fixed frame rate on every device. Active chunk limits, two near-cast fish and bounded catch-up prevent far-away production from creating unbounded scene actors.
`);
write('NEXT_STEPS.md',`# Completed baseline and future work

Phases 1–8 are implemented in the existing project, including limited camera tilt and obstruction hiding. Phase 8 adds six personal professions, fishing/journal, cooking/food effects, crop growth/rain, continuing camp occupations, persistent animated mounted travel and treasure exploration. See PHASE_8.md for recorded validation, controls and practical limits.

Possible future work: profile terrain/scenery draw calls on integrated GPUs; refine LPC action and seated poses; expand NPC work props and crop layout options; add authored quests around fishing/camp residents; consider additional mount species or recipe content in a new brief. Current crop/worker progression intentionally uses the world clock without offline wall-clock rewards. Keep economic rewards modest and preserve occupation/expedition exclusion.

Preserve baseline archives, player saves, stable resource IDs and logical coordinates. Keep the journey JSON with its .chunks folder, retain migrations from versions 2–7 and repeat targeted camera/combat/gathering/interior/streaming checks after structural changes. Source assets and license notices must accompany future packaging.
`);

let readme=fs.readFileSync(root+'/README.md','utf8');
readme=readme.replace(/^# Relic Vale · Phase \d+/, '# Relic Vale · Phase 8');
readme=readme.replace(/\*\*Phase 7:\*\*[^\n]+/, '**Phase 8:** six personal professions, skill-based fishing with 20 species, 24 recipes, eight crops, five camp occupations, animated mounted travel and treasure exploration. **P** professions/journal/garden/mounts, **V** call horse, **E** cast/mount/interact, **Shift** gallop, **F8** diagnostics. See [Phase 8](docs/PHASE_8.md), [professions](docs/PROFESSIONS.md), [fishing](docs/FISHING.md), [cooking](docs/COOKING.md), [farming](docs/FARMING.md) and [mounts](docs/MOUNTS.md). **Tab** still opens the atlas, **G** the camp and **F7** camp/map diagnostics.');
readme=readme.replace('Save version 7 reads versions 2–6.','Save version 8 reads versions 2–7 and defaults new profession/activity fields.');
readme=readme.replace('Optional tree-fall physics, durability and a farming economy were not added.','Optional tree-fall physics and durability remain outside this phase. Farming and cooking now form a modest supply economy.');
if(!readme.includes('Phase 8 test flags:'))readme+='\nPhase 8 test flags: --phase8-test, then --phase8-reload in a fresh process, and --phase8-edges. Test outputs use separate filenames. --phase8-icons rebuilds icons from the imported models and should be followed by an editor import.\n';
fs.writeFileSync(root+'/README.md',readme);
fs.writeFileSync('README.md',`# Relic Vale · 0.8

**Фаза 8 завершена:** шесть профессий, рыбалка с 20 видами рыб, 24 рецепта, восемь культур, постоянные занятия жителей, верховая езда и поиск кладов. [Отчёт и проверки](relic_vale/docs/PHASE_8.md). Предыдущие системы карты, лагеря, боя, интерьеров и потокового мира сохранены.

Запуск: **Launch Relic Vale.bat**. Редактор: **Edit Relic Vale.bat**. Движок и все игровые ресурсы включены; интернет для игры не нужен. При первом запуске выполняется импорт ресурсов.

**P** — профессии, рыболовный журнал, огород, лошадь и карты сокровищ. **I** — экипировать удочку или лейку. У Ионы в лавке Уиллоумера продаются удочки и наживка, у Нелл — семена и лейка. На сухом берегу повернуться к воде и нажать **E**; при поклёвке нажать **Space/ЛКМ**, затем удерживать/отпускать, чтобы держать рыбу в зелёной зоне. **Esc** отменяет рыбалку.

На третьей стадии лагеря доступны восемь грядок и конюшня. **E** у грядки — подготовить, посадить, полить или собрать; семена выбираются в P. Дождь поливает растения. **G → Residents** назначает фермера, повара, рыбака, собирателя или деревообработчика; материалы кладутся в производственный сундук. **V** — позвать лошадь, **E** рядом — сесть/слезть, **Shift** — галоп. Лошадь стоит 180 медных монет.

**Камера:** Q/R или горизонтальное движение с зажатой ПКМ — поворот; вертикальное движение ПКМ или Page Up/Down — небольшой наклон в пределах 40–60°. Колесо — приближение, Home — сброс. Закрывающие обзор деревья, крыши и другие препятствия временно скрываются и возвращаются, когда обзор свободен.

WASD — движение, Ctrl — уклонение, Space/ЛКМ — удар, 1/2 — умения, H — зелье. C — внешность, B — умения, J — задания, Tab — атлас, Esc — меню, F6/F9 — сохранить/загрузить, F11 — полный экран. F3/F4 — отладка мира/добычи, F7 — карты/лагеря, **F8** — систем фазы 8.

Сохранения: tools/godot/userdata/Godot/app_userdata/RelicValePrototype. Вместе с JSON сохраняйте соответствующую папку .chunks. Формат 8 читает версии 2–7. Проверки используют отдельные файлы. Рост и работа жителей продолжаются при выгрузке лагеря по игровому времени; награды за реальное время при закрытой игре не начисляются.

[Руководство](relic_vale/README.md) · [Профессии](relic_vale/docs/PROFESSIONS.md) · [Рыбалка](relic_vale/docs/FISHING.md) · [Рецепты](relic_vale/docs/COOKING.md) · [Огород](relic_vale/docs/FARMING.md) · [Верховая езда](relic_vale/docs/MOUNTS.md) · [Лицензии](relic_vale/docs/ASSET_CREDITS.md).
`);
console.log(JSON.stringify({docs:'Phase 8 documentation generated',runs:runs.length,...total,assets:files.length}));
