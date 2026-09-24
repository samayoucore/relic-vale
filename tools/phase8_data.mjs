import fs from 'node:fs';
const read=f=>JSON.parse(fs.readFileSync('relic_vale/data/'+f+'.json'));
const write=(f,v)=>fs.writeFileSync('relic_vale/data/'+f+'.json',JSON.stringify(v,null,2)+'\n');
const root='res://assets/3d/phase8/';
const items={};
function item(id,name,price,extra={}){items[id]={id,name,kind:'material',rarity:'Common',description:name+'. A trade good from the living vale.',icon:'leaf',base_price:price,...extra};}
const professions={};
for(const [id,name,icon,unlocks] of [
 ['woodcutting','Woodcutting','wood',['Yield +5%','Resin and hardwood','Gather speed +10%','Ancient timber']],
 ['mining','Mining','iron_ore',['Yield +5%','Silver ore','Gather speed +10%','Star ore']],
 ['herbalism','Herbalism','wild_herb',['Healing herbs','River herbs','Gather speed +10%','Dawn flowers']],
 ['fishing','Fishing','fish_minnow',['Skilled river fish','Rare bait','Large lake fish','Legendary catches']],
 ['cooking','Cooking','meal_grilled_fish',['Cooking pot meals','Hearty dishes','Kitchen meals','Signature recipes']],
 ['farming','Farming','crop_carrot',['Berries and corn','Bamboo and fruit','Yield +10%','Seed recovery +15%']]]){
 professions[id]={name,icon,max_level:25,xp_base:40,xp_linear:12,xp_square:1,unlocks:unlocks.map((name,i)=>({level:5+i*5,name}))};
}
write('professions',professions);
const fish={};
const rows=[
 ['minnow','Silver minnow','Tetra',1,'Common','any','any','any',.10,5],
 ['golden_dace','Golden dace','Goldfish',1,'Common','river','any','any',.14,6],
 ['pond_carp','Pond carp','Koi',1,'Common','lake','any','any',.18,7],
 ['sun_perch','Sun perch','Sunfish',1,'Common','any','any','any',.20,7],
 ['mud_loach','Mud loach','ArmoredCatfish',3,'Common','river','any','any',.22,8],
 ['ruby_fin','Ruby fin','CardinalFish',5,'Uncommon','river','day','any',.30,12],
 ['reed_betta','Reed betta','Betta',5,'Uncommon','lake','any','any',.32,13],
 ['blue_carp','Blue carp','BlueGoldfish',6,'Uncommon','lake','dawn','any',.35,14],
 ['thorn_pike','Thorn pike','Piranha',7,'Uncommon','river','any','Rain',.40,17],
 ['amber_bream','Amber bream','FlowerHorn',8,'Uncommon','any','day','any',.38,16],
 ['moon_koi','Moon koi','Koi',10,'Rare','lake','night','any',.46,28],
 ['mist_darter','Mist darter','BlueTang',10,'Rare','river','any','Fog',.48,28],
 ['stone_flatfish','Stone flatfish','Flatfish',12,'Rare','river','any','any',.50,25],
 ['copper_snapper','Copper snapper','RedSnapper',12,'Rare','lake','day','any',.52,29],
 ['elder_grouper','Elder grouper','CoralGrouper',15,'Rare','lake','any','any',.56,35],
 ['river_giant','River giant','Tuna',15,'Rare','river','any','Rain',.60,40],
 ['violet_turbot','Violet turbot','Turbot',17,'Epic','lake','night','any',.64,50],
 ['lantern_fish','Lantern fish','Anglerfish',20,'Epic','any','night','Fog',.72,65],
 ['storm_puffer','Storm puffer','Puffer',20,'Epic','lake','any','Storm',.74,70],
 ['dawn_mandarin','Dawn mandarin','MandarinFish',23,'Legendary','river','dawn','Clear',.80,95]];
for(const [id,name,model,level,rarity,water,time,weather,difficulty,price] of rows){
 const key='fish_'+id;
 fish[key]={id:key,name,icon:key,model:root+'cutefish/'+model+'.glb',rarity,water,biome:water==='any'?'Freshwater':water==='river'?'Riverbank':'Lakeshore',time,weather,min_level:level,difficulty,sell_price:Math.floor(price*.4),cooking:true,weight_min:.1+level*.04,weight_max:.5+level*.35};
 item(key,name,price,{rarity,model:fish[key].model,material_category:'Fish',description:`${rarity} fish. ${water==='any'?'Fresh water':water} · ${time} · ${weather}. Cooking ingredient. Fishing ${level}.`});
}
write('fish',fish);
for(const [id,name,wait,rare,level,price,model] of [['basic','Dough bait',1,1,1,2,'Lure_1'],['insect','River insect bait',.7,1.35,1,3,'Worm'],['rare','Moon lure bait',.55,2,10,5,'Lure_3']]) item('bait_'+id,name,price,{material_category:'Fishing',model:root+'cutefish/'+model+'.glb',description:name+(id==='insect'?'. Faster bites; favors river species.':id==='rare'?'. Improved rare odds. Fishing 10 required.':'. Everyday freshwater bait.'),bait:{wait,rare,min_level:level,target_water:id==='insect'?'river':'any'}});
for(let tier=1;tier<=3;tier++)item('fishing_rod_'+tier,['Willow fishing rod','Reinforced fishing rod','Moonsteel fishing rod'][tier-1],[15,80,220][tier-1],{kind:'tool',slot:'Tool',tool:'rod',tier,stats:{},model:root+`cutefish/FishingRod_Lvl${tier}.glb`,icon:'staff',description:'Equip in Tool. Face fresh water and press E to cast. Hold Space / left mouse to move the catch zone right; release to move left.'});
// The watering can model is supplied by the asset preparation step.
item('watering_can','Watering can',18,{kind:'tool',slot:'Tool',tool:'watering',tier:1,stats:{},model:root+'tools/WateringCan.glb',description:'Equip in Tool and use E at a planted bed. One watering keeps soil moist for 8 game hours.'});
const crops={};
for(const [id,name,model,level,minutes,yieldCount,price,height] of [
 ['carrot','Carrot','Carrot',1,180,3,4,.5],['beet','Beet','Beet',1,240,3,5,.55],['corn','Corn','Corn',5,420,4,5,1.3],['berries','Berries','BushBerries',5,480,4,7,.8],['bamboo','Bamboo shoots','Bamboo',10,540,3,9,1.4],['apple','Apple','Apple',10,720,4,8,1.55],['cactus','Prickly pear','Cactus',12,600,3,10,.9],['flower','Sunpetal','Flower',15,660,3,12,.75]]){
 crops[id]={id,name,min_level:level,minutes,yield:yieldCount,seed:'seed_'+id,item:'crop_'+id,model,height,stages:[0,.12,.38,.7,1]};
 item('seed_'+id,name+' seeds',Math.max(2,Math.floor(price*.6)),{material_category:'Seeds',description:`Plant in a prepared camp bed. Farming ${level}; ${minutes} moist game minutes to harvest.`});
 item('crop_'+id,name,price,{material_category:'Crops',model:root+'ultimatecrops/'+(id==='flower'?'Flowers':model)+'_Crop.glb'});
}
write('crops',crops);
const recipes=[];
const meals=[
 ['grilled_fish','Grilled fish',{fish_minnow:1},1,'campfire',20,'gather_speed',.05,'Fish'],
 ['perch_skewer','Perch skewer',{fish_sun_perch:1,wood:1},1,'campfire',25,'max_hp',8,'Fish'],
 ['roast_meat','Roast meat',{raw_meat:1},1,'campfire',30,'damage_percent',.05,'ChickenLeg'],
 ['roast_carrot','Roast carrot',{crop_carrot:2},1,'campfire',18,'move_percent',.04,'Carrot'],
 ['forest_bites','Forest bites',{mushroom:2},1,'campfire',18,'profession_xp',.05,'Bread'],
 ['beet_broth','Beet broth',{crop_beet:2,wild_herb:1},3,'campfire',22,'max_hp',10,'CookingPot_Soup'],
 ['herb_carp','Herb carp',{fish_pond_carp:1,wild_herb:1},5,'cooking_pot',32,'fishing_luck',.08,'Fish'],
 ['river_stew','River stew',{fish_golden_dace:1,crop_carrot:1},5,'cooking_pot',35,'gather_speed',.08,'CookingPot_Soup'],
 ['hunters_soup','Hunter soup',{raw_meat:1,mushroom:2},5,'cooking_pot',40,'max_hp',15,'CookingPot_Soup'],
 ['corn_chowder','Corn chowder',{crop_corn:2,crop_beet:1},6,'cooking_pot',30,'profession_xp',.08,'CookingPot_Soup'],
 ['berry_bread','Berry bread',{crop_berries:2,crop_corn:1},7,'cooking_pot',25,'move_percent',.06,'Bread'],
 ['peppered_loach','Peppered loach',{fish_mud_loach:1,crop_flower:1},8,'cooking_pot',38,'damage_percent',.08,'Fish'],
 ['garden_pot','Garden pot',{crop_carrot:1,crop_beet:1,mushroom:1},8,'cooking_pot',35,'max_hp',18,'CookingPot_Soup'],
 ['bamboo_broth','Bamboo broth',{crop_bamboo:2,wild_herb:1},10,'cooking_pot',35,'fishing_luck',.12,'CookingPot_Soup'],
 ['apple_glaze','Apple glazed roast',{crop_apple:2,raw_meat:1},10,'cooking_pot',45,'gather_speed',.10,'ChickenLeg'],
 ['ruby_fillet','Ruby fillet',{fish_ruby_fin:1,healing_herb:1},11,'cooking_pot',40,'damage_percent',.10,'Fish'],
 ['cactus_tea','Prickly pear tea',{crop_cactus:2,river_herb:1},12,'cooking_pot',30,'move_percent',.08,'Bottle1'],
 ['moon_soup','Moon koi soup',{fish_moon_koi:1,night_bloom:1},15,'kitchen',55,'fishing_luck',.18,'CookingPot_Soup'],
 ['mist_supper','Mist supper',{fish_mist_darter:1,crop_bamboo:1},15,'kitchen',50,'profession_xp',.12,'Fish'],
 ['harvest_pie','Harvest pie',{crop_apple:1,crop_berries:1,crop_corn:2},16,'kitchen',50,'max_hp',25,'Croissant'],
 ['giant_feast','River giant feast',{fish_river_giant:1,crop_carrot:2},18,'kitchen',60,'gather_speed',.14,'Fish'],
 ['elder_roast','Elderwood roast',{raw_meat:2,dawn_flower:1,crop_beet:1},20,'kitchen',65,'damage_percent',.14,'ChickenLeg'],
 ['lantern_bisque','Lantern bisque',{fish_lantern_fish:1,crop_flower:1},22,'kitchen',70,'profession_xp',.15,'CookingPot_Soup'],
 ['dawn_banquet','Dawn banquet',{fish_dawn_mandarin:1,dawn_flower:1,crop_apple:2},25,'kitchen',80,'fishing_luck',.22,'Fish']];
for(const [id,name,input,level,station,heal,stat,value,model] of meals){
 const output='meal_'+id; const duration=120+level*12;
 item(output,name,8+level*5,{kind:'consumable',heal,model:root+'ultimatefood/'+model+'.glb',food:{stat,value,minutes:duration},description:`Restores ${heal} HP. ${stat.replaceAll('_',' ')} +${stat==='max_hp'?value:Math.round(value*100)+'%'} for ${duration} game minutes. Replaces your current food buff. Cooking ${level} · ${station.replaceAll('_',' ')}.`});
 const recipe={id:'cook_'+id,name,station,input,output,count:1,cost:0,profession:'cooking',min_level:level,xp:12+level*2};
 if(['harvest_pie','elder_roast'].includes(id))recipe.unlock=recipe.id;
 recipes.push(recipe);
}
write('cooking',recipes);
const resources={};
for(const [id,name,prof,level,tier,price,color,condition] of [
 ['hardwood','Hardwood','woodcutting',10,2,9,'98754f','any'],['ancient_wood','Ancient timber','woodcutting',20,3,24,'9d8d63','any'],['coal','Coal','mining',1,1,5,'515359','any'],['silver_ore','Silver ore','mining',10,2,15,'bdc5cc','any'],['star_ore','Star ore','mining',20,3,35,'83b5c4','Storm'],['healing_herb','Heartleaf','herbalism',5,0,10,'8ac893','any'],['river_herb','River mint','herbalism',10,0,12,'719cba','any'],['night_bloom','Night bloom','herbalism',15,0,22,'b7a1c5','night'],['dawn_flower','Dawn flower','herbalism',20,0,28,'dbba82','dawn']]){
 item(id,name,price,{rarity:level>=20?'Rare':'Uncommon',material_category:prof==='woodcutting'?'Wood':prof==='mining'?'Ore':'Plants'});
 resources[id]={hits:prof==='herbalism'?1:5,yield_min:1,yield_max:3,respawn_days:3,tool:prof==='woodcutting'?'axe':prof==='mining'?'pickaxe':'',color,category:items[id].material_category,profession:prof,min_level:level,tool_tier:tier,condition,xp:16+level*2};
}
item('resin','Amber resin',16,{rarity:'Uncommon',material_category:'Rare materials'});
item('raw_meat','Game meat',8,{material_category:'Food'});
item('old_boot','Waterlogged boot',1,{description:'A disappointing catch. A merchant might take it.'});
item('message_bottle','Message in a bottle',7,{model:root+'ultimatefood/Bottle1.glb',description:'A river tale and a fragment of an old route.'});
item('map_fragment','Weathered map fragment',6,{material_category:'Treasure',description:'Three fragments can be pieced together in Professions → Exploration.'});
item('treasure_map','Weathered treasure chart',1,{kind:'quest',description:'An approximate search area is marked on the atlas. Read it in Professions → Exploration.'});
// Prepared food remains valuable to eat, but cannot be bought/crafted/resold for a vendor loop.
const allItems={...read('items'),...items};
for(const recipe of recipes){const ingredientValue=Object.entries(recipe.input).reduce((sum,[id,n])=>sum+(allItems[id].base_price||10)*n,0);items[recipe.output].base_price=Math.max(4,Math.floor(ingredientValue*.95));}
write('profession_resources',resources); write('phase8_items',items);
console.log('Data:',Object.keys(professions).length,'professions,',Object.keys(fish).length,'fish,',Object.keys(crops).length,'crops,',recipes.length,'recipes,',Object.keys(items).length,'items');
