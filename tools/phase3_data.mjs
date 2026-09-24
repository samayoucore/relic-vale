import fs from 'node:fs';
const dir='relic_vale/data/';
const items=JSON.parse(fs.readFileSync(dir+'items.json'));
for(const id of ['rustic_sword','iron_sword','moon_blade'])items[id].weapon_type='sword';
const weapon=(name,type,attack,rarity,description)=>({name,kind:'weapon',slot:'Weapon',weapon_type:type,rarity,description,icon:type,stats:{attack}});
items.iron_greatsword=weapon('Iron greatsword','greatsword',9,'Common','A broad, deliberate sweep. Slow recovery, strong recoil and reach.');
items.twin_daggers=weapon('Twin briar daggers','daggers',2,'Common','Short reach, quick strikes and an extra 8% critical chance.');
items.apprentice_staff=weapon('Apprentice staff','staff',4,'Common','Fires a small arcane bolt along your facing direction.');
items.oak_bow=weapon('Willow bow','bow',5,'Common','A steady bow with a long-reaching arrow. Face your target before firing.');
const relic=(name,rarity,description,icon,stats={},proc='')=>({name,kind:'relic',slot:'Relic',rarity,description,icon,stats,...(proc?{proc}:{})});
Object.assign(items,{
 dew_bead:relic('Dew Bead','Common','Tonics restore 20% more health.','bottle',{tonic_bonus:.2}),
 stone_button:relic('Stone Button','Common','A tiny shield against the road. +2 defense.','coin',{defense:2}),
 reed_whistle:relic('Reed Whistle','Common','Dodge recovers 15% sooner.','leaf',{dodge_reduction:.15}),
 moss_seed:relic('Moss Seed','Common','Each defeated enemy restores 2 HP.','leaf',{},'moss'),
 candle_stub:relic('Last Candle','Common','Fire damage gains 5% power.','bolt',{fire_percent:.05}),
 acorn_shell:relic('Acorn Shell','Common','Dodging grants a 5-point shield for three seconds.','hood',{},'acorn'),
 silver_thread:relic('Silver Thread','Common','While standing still outside danger, slowly recover health.','ring',{},'thread'),
 wind_step:relic('Windstep Feather','Rare','After dodging, your next hit within three seconds deals 25% more damage.','leaf',{},'windstep'),
 frost_leaf:relic('Frostleaf','Rare','Hits have a 20% chance to slow enemies.','leaf',{slow_chance:.2}),
 serpent_tooth:relic("Serpent's Tooth",'Rare','Hits have a 20% chance to poison enemies for five seconds.','sword',{},'serpent'),
 drinking_moon:relic('Drinking Moon','Rare','Tonics also regenerate 3 HP each second for three seconds.','bottle',{},'drinking_moon'),
 quartz_guard:relic('Quartz Guard','Rare','Critical hits briefly stun ordinary enemies. Bosses resist the stun.','gem',{},'quartz'),
 spell_knot:relic('Spellknot','Rare','Abilities recover 12% sooner.','ring',{cooldown_reduction:.12}),
 arcane_mirror:relic('Arcane Mirror','Epic','Critical hits release a small secondary arcane bolt.','gem',{},'mirror'),
 overflowing_cup:relic('Overflowing Cup','Epic','Healing beyond maximum HP becomes a temporary shield, up to 30 points.','bottle',{},'overflow'),
 ember_crown:relic('Ember Crown','Epic','Fire spells burn their targets, with +15% fire damage.','hood',{fire_percent:.15},'ember_crown'),
 winter_clock:relic('Winter Clock','Epic','Frost Nova reaches 30% farther and freezes ordinary foes briefly.','ring',{},'winter'),
 hollow_heart:relic('Heart of the Hollow Knight','Legendary','Defeating an enemy grants +25% damage for six seconds. A memory of the Cryptwarden.','heart',{},'hollow')
});
items.fallen_king.description='Kills have a 20% chance to reset your primary attack and one ability cooldown.';
for(const id of Object.keys(items))items[id].id=id;
fs.writeFileSync(dir+'items.json',JSON.stringify(items,null,2));
const pool={cost:1,rates:[
 {rarity:'Common',weight:55,items:['travelers_coin','dew_bead','stone_button','reed_whistle','moss_seed','candle_stub','acorn_shell','silver_thread']},
 {rarity:'Rare',weight:30,items:['ember_ring','hunters_eye','wind_step','frost_leaf','serpent_tooth','drinking_moon','quartz_guard','spell_knot']},
 {rarity:'Epic',weight:12,items:['moonstone_heart','storm_charm','arcane_mirror','overflowing_cup','ember_crown','winter_clock']},
 {rarity:'Legendary',weight:3,items:['fallen_king','void_echo','hollow_heart']}
]};fs.writeFileSync(dir+'relics.json',JSON.stringify(pool,null,2));
let credits=fs.readFileSync('relic_vale/docs/ASSET_CREDITS.md','utf8');
if(!credits.includes('Phase 3 audio'))credits+='\n## Phase 3 audio and generated support assets\n\n- **RPG Audio**, Kenney. Source: https://kenney.nl/assets/rpg-audio. License: **CC0 1.0**, no attribution required (credit retained voluntarily). Selected footsteps, blade/cloth sounds, hit, coins, creak and UI/handling cues are used for movement, melee, pickups and interaction. The official page and included KENNEY-LICENSE.txt confirm the license. Archive/source hashes and selected filenames are in PHASE_3_AUDIO_MANIFEST.json.\n- **Original synthesized cues and musical loops**, created locally for this project by tools/phase3_assets.mjs: spell, bow, critical, heal, level, shrine, hurt, death, slam, and vale/crypt/boss loops. No third-party samples or melodies.\n- **Original procedural combat visuals**: ring telegraphs, slash trails, sparks, projectile icons and rarity effects, generated in GDScript. Existing LPC layer attributions remain unchanged.\n';
fs.writeFileSync('relic_vale/docs/ASSET_CREDITS.md',credits);
