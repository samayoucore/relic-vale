import fs from 'node:fs';
const root='relic_vale/data/';
const levels=[
['Campfire',60,[8,14,5],2,1,[],'Fire, two tents, storage and task board'],
['Wayside Camp',130,[24,40,18],4,2,['store'],'Extra tents, storage yard, work areas and paths'],
['Outpost',240,[50,85,40],6,2,['store','workshop'],'Permanent workshop, fences and an outpost hall'],
['Homestead',400,[90,150,75],8,3,['store','workshop','house'],'Enterable player home and veteran cottages'],
['Hamlet',0,[0,0,0],10,4,['store','workshop','house','market'],'Leader house, veteran homes, newcomer tents and market']
].map((r,i)=>({level:i+1,tier:i+1,name:r[0],xp:r[1],cost:{food:r[2][0],materials:r[2][1],gold:r[2][2]},population:r[3],slots:r[4],facilities:r[5],description:r[6]}));
const raw=[
['firewood','Gather firewood','Logging',1,1,1,'gathering',0,90,[12,1,8,2],[],{}],
['forage','Forage the meadow','Foraging',1,1,1,'gathering',0,120,[14,10,2,2],[],{}],
['stone','Collect loose stone','Mining',1,1,1,'mining',0,150,[15,2,10,2],[],{}],
['supply','Carry local supplies','Supply',1,1,1,'trading',0,180,[16,5,4,8],[],{}],
['hunt','Hunt woodland game','Hunting',1,2,1,'hunting',1,300,[25,20,4,8],[],{food:2}],
['salvage','Salvage the old caravan','Salvage',2,2,2,'scouting',2,420,[35,5,28,12],['store'],{food:4}],
['trade','Trade with a neighboring village','Trading',2,2,2,'trading',2,600,[40,12,4,32],['store'],{materials:5}],
['patrol','Patrol the western road','Patrol',2,2,2,'hunting',2,480,[36,9,10,20],[],{food:4}],
['explore','Survey the distant hills','Exploration',3,3,3,'scouting',3,1440,[70,24,35,35],['workshop'],{food:8}],
['ore','Work a rich ore seam','Mining',3,3,3,'mining',3,1080,[60,8,60,20],['workshop'],{food:6,gold:3}],
['build','Help rebuild a hamlet bridge','Construction',3,3,3,'gathering',3,1800,[90,35,50,65],['workshop'],{materials:12}],
['expedition','Escort the northern expedition','Special',4,4,4,'scouting',4,2880,[120,60,90,90],['house'],{food:15,gold:10}]
];
const tasks=raw.map(r=>({id:r[0],name:r[1],category:r[2],level:r[3],workers:r[4],worker_level:r[5],skill:r[6],skill_level:r[7],minutes:r[8],rewards:{xp:r[9][0],food:r[9][1],materials:r[9][2],gold:r[9][3],worker_xp:30+r[3]*15},facilities:r[10],cost:r[11]}));
fs.writeFileSync(root+'camp.json',JSON.stringify({levels,tasks,refresh_gold:5,traveler_minutes:1440,first_traveler_minutes:1,reserve_radius:17,contributions:{wood:{materials:2},stone:{materials:2},iron_ore:{materials:4},wild_mushroom:{food:3},mushroom:{food:3},wild_herb:{food:1}}},null,2)+'\n');
