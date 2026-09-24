import fs from 'node:fs';
const dir='relic_vale/data/';
const write=(n,v)=>fs.writeFileSync(dir+n+'.json',JSON.stringify(v,null,2)+'\n');
const items=JSON.parse(fs.readFileSync(dir+'items.json'));
const materials={wood:['Seasoned wood','leaf'],stone:['River stone','gem'],iron_ore:['Iron ore','gem'],mushroom:['Forest mushroom','leaf'],crystal:['Veil crystal','gem'],iron_ingot:['Iron ingot','sword'],plank:['Timber plank','leaf'],charcoal:['Charcoal','gem'],leather:['Cured leather','armor']};
for(const [id,[name,icon]] of Object.entries(materials))items[id]={id,name,icon,kind:'material',rarity:'Common',description:'Gathered and worked by the craftspeople of the vale.'};
for(const [id,name,heal,status] of [['mushroom_stew','Woodland stew',25,'regeneration'],['greater_tonic','Restorative draught',80,''],['ward_tonic','Stoneward draught',20,'shield'],['swift_tonic','Windleaf infusion',20,'swift']])items[id]={id,name,heal,status,kind:'consumable',rarity:'Uncommon',icon:'bottle',description:`Restores ${heal} health.`+(status==='regeneration'?' Also restores 3 HP per second for eight seconds.':status==='shield'?' Grants a 25-point shield for twelve seconds.':status==='swift'?' Grants 20% movement speed for twelve seconds.':'')};
for(const [id,base,name,stats] of [['forged_blade','iron_sword','Tempered ironwood blade',{attack:13,crit:.02}],['ranger_bow','oak_bow','Elderwood longbow',{attack:10,crit:.03}],['mining_mail','leather_vest','Ironvein brigandine',{defense:5,max_hp:18}],['rune_staff','apprentice_staff','Veilbound staff',{attack:11,cooldown_reduction:.08}],['reinforced_hood','linen_hood','Stitched ranger hood',{defense:3,max_hp:8}]])items[id]={...items[base],id,name,stats,rarity:'Rare',description:'A commissioned craft, built to endure the roads beyond Willowmere.'};
write('items',items);
const recipes=[];
const recipe=(id,name,station,input,out,count=1,extra={})=>recipes.push({id,name,station,input,output:out,count,cost:2,...extra});
recipe('planks','Saw timber','workbench',{wood:2},'plank',3);
recipe('charcoal','Burn charcoal','campfire',{wood:2},'charcoal',2);
recipe('iron','Smelt iron','forge',{iron_ore:2,charcoal:1},'iron_ingot');
recipe('leather','Cure hides','workbench',{wolf_pelt:1,wild_herb:1},'leather',2);
recipe('tonic','Brew trail tonic','alchemy',{wild_herb:2,slime_gel:1},'trail_tonic',2);
recipe('stew','Simmer woodland stew','campfire',{mushroom:2,wild_herb:1},'mushroom_stew',2);
recipe('greater','Restorative draught','alchemy',{wild_herb:3,mushroom:2},'greater_tonic');
recipe('ward','Stoneward draught','alchemy',{stone:2,slime_gel:2},'ward_tonic');
recipe('swift','Windleaf infusion','alchemy',{wild_herb:2,crystal:1},'swift_tonic');
recipe('sword','Forge ironwood blade','forge',{iron_ingot:3,wood:1},'iron_sword');
recipe('greatsword','Forge greatsword','forge',{iron_ingot:4,leather:1},'iron_greatsword');
recipe('daggers','Balance twin daggers','forge',{iron_ingot:2,leather:1},'twin_daggers');
recipe('bow','Carve willow bow','workbench',{plank:3,leather:1},'oak_bow');
recipe('vest','Stitch leather vest','workbench',{leather:3,wood:1},'leather_vest');
recipe('hood','Reinforce traveler hood','workbench',{linen_hood:1,leather:2},'reinforced_hood');
recipe('helm','Forge warden helm','forge',{iron_ingot:3,crystal:1},'iron_helm');
recipe('temper','Temper an ironwood blade','forge',{iron_sword:1,iron_ingot:2,crystal:1},'forged_blade',1,{unlock:'hearth_3'});
recipe('longbow','Craft elderwood longbow','workbench',{oak_bow:1,plank:3,leather:2},'ranger_bow',1,{unlock:'bough_3'});
recipe('mail','Rivet ironvein brigandine','forge',{leather_vest:1,iron_ingot:4},'mining_mail');
recipe('runes','Inscribe veilbound staff','alchemy',{apprentice_staff:1,crystal:3,ancient_bone:2},'rune_staff',1,{unlock:'veil_3'});
write('crafting',recipes);
write('factions',{hearth:{name:'Lantern Compact',description:'Willowmere and the Ironvein workers keep roads and winter stores safe.'},bough:{name:'Elderbough Wardens',description:'Rangers protect groves, waterways and the creatures of the vale.'},veil:{name:'Keepers of the Veil',description:'Elowen and the ruin scholars study the lost oaths beneath the earth.'}});
const q={};
function chain(prefix,npc,entries){entries.forEach(([name,type,target,count,description],i)=>{const id=prefix+'_'+(i+1);q[id]={name,type,target,count,description,chain:prefix,npc,prerequisites:i?[prefix+'_'+i]:[],next:i<entries.length-1?prefix+'_'+(i+2):'',reputation_requirement:i*10,reward:{xp:35+i*25,coins:15+i*15,shards:i===entries.length-1?1:0,reputation:15,faction:prefix,unlock:i===entries.length-1?id:''}};});}
chain('hearth','rowan',[
 ['Winter timber','collect','wood',4,'Gather four wood from fallen logs. Rowan needs dry stores for the lantern road.'],
 ['Word from Ironvein','talk','ironvein_smith',1,'Visit the Ironvein smith. Follow the marked road on the atlas.'],
 ['The old mine oath','dungeon','mine',1,'Defeat the mine guardian and recover the sealed work ledger. Return to Rowan.']]);
chain('bough','fernwatch_ranger',[
 ['A ranger’s welcome','collect','wild_herb',3,'Bring three silverleaf herbs to the Fernwatch ranger.'],
 ['Teeth on the trail','kill','wolf',3,'Thin the hostile wolves along forest trails. Leave the deer in peace.'],
 ['A quiet grove','discover','grove',1,'Find the ancient grove, then report to Fernwatch for the longbow pattern.']]);
chain('veil','keeper',[
 ['Letters in bone','collect','ancient_bone',2,'Recover two runed bones from skeletons in the Fallen March.'],
 ['Blue light below','collect','crystal',3,'Gather three veil crystals from ruins or underground deposits.'],
 ['An oath remembered','dungeon','crypt',1,'Defeat the guardian in a generated crypt and return to Elowen.']]);
write('quest_chains',q);
write('merchants',{
 blacksmith:{faction:'hearth',offers:[['iron_sword',45],['leather_vest',50],['iron_greatsword',55],['twin_daggers',35],['iron_ore',5],['iron_ingot',13]]},
 alchemist:{faction:'bough',offers:[['trail_tonic',12],['wild_herb',4],['mushroom',4],['greater_tonic',25],['ward_tonic',22],['swift_tonic',24]]},
 general:{faction:'hearth',offers:[['trail_tonic',12],['wood',3],['stone',3],['plank',5],['leather',8],['oak_bow',35]]},
 relic:{faction:'veil',offers:[['crystal',14],['copper_leaf',75],['moon_glass',140],['astral_shard',90],['recipe:runes',100],['recipe:temper',100],['recipe:longbow',100]]},
 traveling:{faction:'bough',offers:[['wolf_pelt',6],['ancient_bone',8],['greater_tonic',20],['crystal',12],['astral_shard',80]]}
});
const npcs=JSON.parse(fs.readFileSync(dir+'npcs.json'));
npcs.smith.category='blacksmith';npcs.merchant.category='general';npcs.keeper.category='relic';npcs.keeper.shop=true;
for(const [id,name,role,category,faction,dialogue] of [
 ['fernwatch_ranger','Aster','Ranger','general','bough','Our paths follow living roots. Earn the Wardens’ trust and I will teach you the elderwood bow.'],
 ['fernwatch_alchemist','Nessa','Herbalist','alchemist','bough','Silverleaf grows along the banks. Rain brings a little extra harvest.'],
 ['ironvein_smith','Orrin','Mining smith','blacksmith','hearth','The old mine has gone silent. Its work ledger is sealed behind a guardian’s oath.'],
 ['crossroads_trader','Tamsin','Road merchant','general','hearth','Every road meets another. My stall keeps the caravans supplied.'],
 ['traveling','Peregrin','Traveling merchant','traveling','bough','Only here until dusk. A small pack means a few unusual bargains.']])npcs[id]={name,role,category,faction,dialogue,shop:true};
write('npcs',npcs);
console.log('20 recipes, 9 chain quests, 3 factions, 5 merchant categories');
