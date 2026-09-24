import fs from 'node:fs';
const root='relic_vale/data/narrative/';
const read=n=>JSON.parse(fs.readFileSync(root+n+'.json','utf8'));
const C=read('companions'),Q=read('quests'),D=read('dialogue'),L=read('locations'),I=read('items'),B=read('lore');
const R=(type,id,value)=>({type,id,...(value===undefined?{}:{value})});
const E=(type,id,extra={})=>({type,id,...extra});
const ev=(event,id)=>E('event',id,{event});
const flag=(id,value=true)=>E('flag',id,{value});
const rep=(id,amount)=>E('reputation',id,{amount});
const approval=(id,amount,key)=>E('approval',id,{amount,key});
const choice=(id,text,effects=[],conditions=[],next='',tags=[])=>({id,text,effects,conditions,next,tags});
const node=(speaker,text,choices,extra={})=>({speaker,text,choices,...extra});
const step=(type,target,text,location='',extra={})=>({type,target,text,...(location?{location}:{}),...extra});
const obj=(id,name,text,model='box.glb',extra={})=>({id,name,text,model:'res://assets/3d/phase7/'+model,height:.55,...extra});
const site=(id,name,x,z,objects=[],extra={})=>L[id]={name,address:{x:String(x),z:String(z),local:[16,0,16]},objects,...extra};
const enemy=(id,archetype='skeleton',offset=[4,0,-4])=>({id,archetype,offset});
function quest(id,name,description,category,npc,stages,extra={}){
 Q[id]={id,name,description,type:'narrative',target:id,count:stages.length,chain:category.toLowerCase(),category,npc,stages,reward:{coins:25,xp:45,shards:0},...extra};
}
function personal(id,name,description,npc,stages,previous,amount=14,extra={}){
 quest(id,name,description,'Companion',npc,stages,{prerequisites:previous?[previous]:[],conditions:[R('recruited',npc)],effects:[approval(npc,amount,id+'_done')],...extra});
}
function token(id,name,description,stats){I[id]={id,name,description,kind:'accessory',slot:'Accessory',rarity:'Rare',icon:'ring',base_price:55,stats};}
function companion(id,name,model,role,faction,biography,tags,opposes,location,anchor,abilities,barks){
 C[id]={id,name,model:'res://assets/3d/phase4/adventurers/'+model+'.glb',portrait:'res://assets/ui/phase9/portraits/'+id+'.png',role,faction,biography,tags,opposes,location,camp_anchor:anchor,equipment:{Weapon:role==='ranged'?'oak_bow':role==='mage'?'apprentice_staff':'twin_daggers',Armor:'leather_vest',Accessory:''},abilities,recruitment:id+'_recruit',personal:[],signature:id+'_token',passive:'',barks};
}
const ability=(id,name,description,cooldown)=>({id,name,description,cooldown});
companion('tarin','Tarin Fen','Ranger','ranged','bough','An Elderbough pathfinder whose sister Lysa vanished from the Wardens’ rolls. He still marks the paths she taught him to read.',['merciful','wild','honest'],['authority','profit'],'tarin_meeting',[7,0,7],[ability('pinning_shot','Pinning Shot','Pins a rushing enemy with a slowing arrow.',10),ability('split_fletching','Split Fletching','Fires at up to three nearby threats.',15)],{forest:'Someone bent that fern against the wind. We are not the first here.',rain:'Rain hides a trail. It does not erase the reason for taking it.',night:'Lysa taught me the stars. I taught her how to cheat at cards.',ruin:'Stone keeps footprints longer than people think.',boss:'Keep it looking at you. I only need a moment.',camp:'I left the gate wide enough for a tired horse.'});
companion('ilyra','Ilyra Venn','Mage','mage','veil','A Keeper of the Veil who copied a forbidden annotation before her teacher ordered the page burned. She wants evidence more than absolution.',['honest','curious','mercy'],['secrecy','reckless'],'ilyra_meeting',[6,0,-5],[ability('frost_bind','Frost Bind','Slows a clustered group before it surrounds the party.',12),ability('ember_mark','Ember Mark','Marks a dangerous foe with lingering fire.',15)],{forest:'Roots cross without asking whose ground this is. Sensible of them.',rain:'Ink first. Hood second. There are priorities.',night:'That star was missing from the older charts.',ruin:'A warning and an instruction can share the same words.',boss:'It remembers an order. We can give it a reason to stop.',camp:'A shelf, a dry page, and no one burning either. Luxury.'});
companion('sera','Sera Reed','Rogue','support','hearth','A road healer who treated both sides of the ford dispute. Her old field ledger records who was turned away when medicine ran short.',['merciful','practical','honest'],['cruel','profit'],'sera_meeting',[-7,0,-4],[ability('field_dressing','Field Dressing','Restores the most injured ally nearby.',12),ability('steady_hands','Steady Hands','Clears harmful conditions and grants brief regeneration.',18)],{forest:'That plant helps a fever. The one beside it starts one.',rain:'Wet boots, then blisters, then complaints. We can prevent two of those.',night:'Wake me for a fever. Snoring is between you and your conscience.',ruin:'Leave a clean path back. Carrying someone changes the journey.',boss:'Still breathing? Good. We can work with that.',camp:'I put the medicine where sleepy people can find it.'});
C.bren.opposes=['cruel','profit'];
C.sera.equipment.Weapon='apprentice_staff'; C.ilyra.tags=['honest','curious','merciful'];
for(const [id,town,personal,story,combat] of [
 ['bren','Count the lit windows. That is what a watch is for.','I know this road. Give me a moment before we go on.','A promise should leave people somewhere to stand.','Stay behind my shield. I can hold this space.'],
 ['tarin','Every town has a path the map leaves out. Usually behind the bakery.','Lysa used to stop here. I thought I had forgotten.','We have opened a road. Now we have to keep it open.','Keep them moving. I have a clear shot.'],
 ['ilyra','Someone here knows a story that never reached our shelves.','These are the stones I wrote to Orsa about.','I have written down what we chose. In our own words this time.','Leave a little room. The next spell needs it.'],
 ['sera','Clean water first. The rest of a town can wait a moment.','I remember the people before I remember the place.','Tomorrow there will still be patients. Today we made room for them.','Stay where I can reach you.']
]) Object.assign(C[id].barks,{town,personal,story,combat});
site('tarin_meeting','Split Fern Camp',-2,2,[],{companion:'tarin'});
site('snare_hollow','Snare Hollow',-3,3,[obj('cut_snare','Abandoned snare','The cord is cut. A limping doe slips into the ferns.','resource-wood.glb',{requires:[R('defeated','snare_wolf')]})],{enemies:[enemy('snare_wolf','wolf')]});
site('lysa_trail','Lysa’s old crossing',-4,4,[obj('lysa_knot','A blue trail knot','A recent knot, tied left-handed. “Still taking the long way. L.”','signpost.glb')]);
site('reed_pass','Reed Pass',-5,4,[obj('reed_beacon','Trail beacon','A low lamp now marks the safe passage.','campfire-pit.glb',{requires:[R('defeated','reed_poacher')]})],{enemies:[enemy('reed_poacher','archer')],variant:'reed_outcome'});
site('ilyra_meeting','Quiet Scriptorium',2,-2,[],{companion:'ilyra'});
site('broken_annotation','Broken Inscription',3,-3,[obj('rubbing','Erased inscription','Under the warning is a second hand: “The binding answers consent. It cannot create it.”','signpost.glb')]);
site('glass_archive','Glass Archive',4,-4,[obj('archive_margin','Margin notes','Orsa’s first draft calls the binding a bargain, never a command.','box.glb'),obj('archive_record','Unsealed register','The Keeper who guarded this register had forgotten what was being protected.','chest.glb',{requires:[R('defeated','archive_keeper')]})],{enemies:[enemy('archive_keeper','witch')],variant:'archive_outcome'});
site('sera_meeting','Wayfarer’s Rest',-1,-2,[],{companion:'sera'});
site('field_patient','The fallen courier',-2,-3,[obj('patient','Injured courier','The courier drinks slowly. His breathing settles; he can make the shelter before dark.','bedroll.glb',{requires:[R('item','trail_tonic',1)],effects:[E('consume','trail_tonic',{amount:1})]})]);
site('reed_well','Reedside Well',-3,-4,[obj('well_sample','Clouded water','The well is fouled by a broken drain. The sickness began here, not in the travelers’ camp.','barrel.glb'),obj('well_repaired','New filter bed','Stone and fresh charcoal draw the cloud from the water.','box.glb',{requires:[R('item','stone',3)],effects:[E('consume','stone',{amount:3})]})],{variant:'well_outcome'});
site('field_hospital','The old field station',-4,-3,[obj('field_ledger','Sera’s field ledger','Names fill both columns. The dividing line was drawn by the quartermaster, after the treatment.','box.glb')],{enemies:[enemy('field_raider','skeleton')]});

for(const [id,title,desc,stages,intro] of [
 ['tarin','A Cord in the Ferns','Help Tarin clear a snare line left across a game trail.',[step('defeat','snare_wolf','Drive off the wolf at Snare Hollow.','snare_hollow'),step('interact','cut_snare','Cut the abandoned snare.','snare_hollow'),step('choice','tarin_recruit_choice','Tell Tarin the trail is clear.','tarin_meeting')],'My sister hated snares. Someone has strung them across her old trail, and a wolf has learned to wait beside them. Help me clear it. Then we can talk about where you are going.'],
 ['ilyra','Words Under Words','Recover the erased annotation Ilyra could not safely read.',[step('interact','rubbing','Read the erased inscription.','broken_annotation'),step('choice','ilyra_recruit_choice','Bring the reading to Ilyra.','ilyra_meeting')],'Someone scraped a line from the eastern stone. I copied the warning above it, but the missing words matter more. Would you take a rubbing? I would rather meet an answer than another prohibition.'],
 ['sera','The Last Clean Bandage','Bring a trail tonic to the courier near Sera’s rest stop.',[step('interact','patient','Give the injured courier a trail tonic.','field_patient'),step('choice','sera_recruit_choice','Let Sera know the courier is stable.','sera_meeting')],'My last clean bandage went to the courier down the road. He needs a trail tonic and a patient hand. I can buy another bandage. I cannot buy another hour for him.']
]){
 quest(id+'_recruit',title,desc,'Companion',id,stages,{effects:[E('recruit',id),approval(id,12,id+'_joined')]});
 D[id+'_intro']=node(id,intro,[choice('help','I will help.',[E('start',id+'_recruit')]),choice('later','I need to prepare first.')]);
 D[id+'_recruit_choice']=node(id,{tarin:'The doe made it through. You cut every cord, even the ones that would have been worth selling. I would like to see what you do at the next crossroads.',ilyra:'Consent. One word changes the whole text. I have questions for my teacher, and you seem to find the roads questions live on.',sera:'He will live. That is a good enough beginning for a friendship. You are likely to need a healer if you keep stopping for strangers.'}[id],[choice('welcome','Travel with me. There is room at my fire.',[ev('choice',id+'_recruit_choice')]),choice('later','I will come back for you.')]);
}
personal('tarin_knots','The Way She Went','Tarin recognizes a trail sign his sister once used.','tarin',[step('talk','tarin_knots_start','Ask about Lysa at camp.','',{camp:true}),step('interact','lysa_knot','Find Lysa’s trail knot.','lysa_trail'),step('talk','tarin_knots_end','Bring Tarin the message.','',{camp:true})],'');
personal('tarin_pass','A Road Without a Toll','The Wardens want Reed Pass closed; Lysa guides displaced families through it.','tarin',[step('defeat','reed_poacher','Clear the ambush at Reed Pass.','reed_pass'),step('interact','reed_beacon','Light Lysa’s beacon.','reed_pass'),step('talk','tarin_pass_end','Tell Tarin the road can be used.','',{camp:true})],'tarin_knots');
personal('tarin_promise','The Longer Way Home','Tarin must decide whether to keep the Wardens’ boundary or his sister’s open trail.','tarin',[step('reach','lysa_trail','Walk Lysa’s crossing with Tarin.','lysa_trail',{conditions:[R('active','tarin')]}),step('choice','tarin_promise_choice','Choose the promise at camp.','',{camp:true})],'tarin_pass',18,{effects:[approval('tarin',18,'tarin_promise_done'),flag('tarin_personal_complete'),E('item','tarin_token')]});
personal('ilyra_margin','In Another Hand','Ilyra wants her teacher’s original notes, before the prohibitions were added.','ilyra',[step('interact','archive_margin','Recover the margin notes.','glass_archive'),step('talk','ilyra_margin_end','Read Orsa’s first draft at camp.','',{camp:true})],'');
personal('ilyra_keeper','The Keeper of an Empty Room','A bound archivist still guards the testimony no one is permitted to read.','ilyra',[step('defeat','archive_keeper','Release the bound archivist.','glass_archive'),step('interact','archive_record','Open the original register.','glass_archive'),step('talk','ilyra_keeper_end','Let Ilyra compare the names.','',{camp:true})],'ilyra_margin');
personal('ilyra_copy','A Copy for the Road','The surviving text explains how to end an oath. Ilyra must decide who gets to learn it.','ilyra',[step('choice','ilyra_copy_choice','Decide who should hold the text.','',{camp:true})],'ilyra_keeper',20,{effects:[approval('ilyra',20,'ilyra_copy_done'),flag('ilyra_personal_complete'),E('item','ilyra_token')]});
personal('sera_water','What the Water Carried','Sera doubts the claim that the travelers brought the fever.','sera',[step('interact','well_sample','Examine the clouded well.','reed_well'),step('collect','wild_herb','Gather three wild herbs.', '',{count:3}),step('talk','sera_water_end','Show Sera the sample at camp.','',{camp:true})],'');
personal('sera_names','The Line in the Ledger','Sera’s old ledger may prove treatment was given before allegiances were recorded.','sera',[step('defeat','field_raider','Clear the abandoned field station.','field_hospital'),step('interact','field_ledger','Find the original field ledger.','field_hospital'),step('talk','sera_names_end','Let Sera read the names.','',{camp:true})],'sera_water');
personal('sera_open','An Open Door','Sera can use the evidence to secure an open clinic or a Compact infirmary.','sera',[step('interact','well_repaired','Fit a new filter using three stone.','reed_well'),step('choice','sera_open_choice','Agree on the clinic charter.','',{camp:true})],'sera_names',20,{effects:[approval('sera',20,'sera_open_done'),flag('sera_personal_complete'),E('item','sera_token')]});
token('tarin_token','Lysa’s blue knot','A sign for travelers who cannot afford the shorter road.',{attack:4,crit:.04});
token('ilyra_token','The unburned page','A copy small enough to carry, and clear enough to understand.',{attack:5,max_hp:8});
token('sera_token','Sera’s clean ribbon','A promise that the next patient will be treated before their name is asked.',{max_hp:18,defense:2});
C.tarin.personal=['tarin_knots','tarin_pass','tarin_promise']; C.tarin.passive='Clear Passage · arrows pierce armor for 20% more damage';
C.ilyra.personal=['ilyra_margin','ilyra_keeper','ilyra_copy']; C.ilyra.passive='Open Hand · spell cooldowns recover 20% faster';
C.sera.personal=['sera_water','sera_names','sera_open']; C.sera.passive='No One Turned Away · Field Dressing heals both allies';
D.tarin_camp=node('tarin','I still look for her trail marks. Habits are stubborn things. Sometimes that is their best quality.',[],{variants:[{conditions:[R('completed','tarin_knots')],text:'Lysa is alive. I keep saying it, in case the years I thought otherwise are still listening.'}]});
D.ilyra_camp=node('ilyra','I have left space in the notebook. It is a small rebellion against certainty.',[]);
D.sera_camp=node('sera','Sit down. You can tell a great deal about someone by how long they pretend their feet do not hurt.',[]);
function offer(who,qid,text,conditions=[],startEvent=''){
 D[who+'_camp'].choices.push(choice('start_'+qid,text,[E('start',qid),...(startEvent?[ev('talk',startEvent)]:[])],[R('not_started',qid),...Q[qid].prerequisites.map(x=>R('completed',x)),...conditions]));
}
function turnin(who,qid,index,text,event,response){
 const nodeId=qid+'_answer';
 D[who+'_camp'].choices.push(choice('finish_'+qid,text,[ev('talk',event)],[R('stage',qid,index)],nodeId));
 D[nodeId]=node(who,response,[choice('understood','I am glad you told me.')]);
}
offer('tarin','tarin_knots','Tell me about your sister.',[],'tarin_knots_start');
turnin('tarin','tarin_knots',2,'I found a blue knot.','tarin_knots_end','She wrote it for me. Not a farewell. A direction. All this time I was searching the rolls instead of looking at the trees.');
offer('tarin','tarin_pass','We can make Reed Pass safe.',[R('approval','tarin',20)]);
turnin('tarin','tarin_pass',2,'The beacon is lit.','tarin_pass_end','Then she will see it. The Wardens call that road a breach. Lysa calls it a way home. I know which name sounds like a place people can live.');
offer('tarin','tarin_promise','Walk Lysa’s crossing with me.',[R('approval','tarin',30)]);
D.tarin_camp.choices.push(choice('promise','We walked her road. What promise do we keep?',[],[R('stage','tarin_promise',1)],'tarin_promise_choice'));
D.tarin_promise_choice=node('tarin','Aster will accept a marked seasonal route. Lysa wants it open all year. I can persuade one of them; I cannot pretend both asked for the same thing.',[
 choice('open','Keep it open. We will help the travelers care for it.',[flag('reed_outcome','shelter'),rep('bough',-8),rep('hearth',8),ev('choice','tarin_promise_choice')],[],'',['merciful']),
 choice('seasonal','Mark the safe season and keep a refuge at each end.',[flag('reed_outcome','garrison'),rep('bough',12),ev('choice','tarin_promise_choice')],[],'',['practical']),choice('later','Give me time to think.')]);
offer('ilyra','ilyra_margin','What did Orsa change in the notes?');
turnin('ilyra','ilyra_margin',1,'I found the first draft.','ilyra_margin_end','She began with a question: can a promise survive the people who made it? Later copies omit the question mark. That may be the most expensive mark we ever lost.');
offer('ilyra','ilyra_keeper','Let us open the guarded register.',[R('approval','ilyra',20)]);
turnin('ilyra','ilyra_keeper',2,'These are the original names.','ilyra_keeper_end','The witnesses could leave. Their successors were told they could not. We did not inherit an oath. We inherited someone else’s mistake in reading it.');
offer('ilyra','ilyra_copy','Who should be able to read the register?', [R('approval','ilyra',30)]);
D.ilyra_camp.choices.push(choice('copy','Let us decide where the copies go.',[],[R('stage','ilyra_copy',0)],'ilyra_copy_choice'));
D.ilyra_copy_choice=node('ilyra','Orsa asks for one sealed copy. The village school could use a plain account. I can write either. For the first time, I get to choose who the words are for.',[
 choice('public','Make a copy anyone can read.',[flag('archive_outcome','shelter'),rep('veil',-8),rep('bough',8),ev('choice','ilyra_copy_choice')],[],'',['honest','curious']),
 choice('guarded','Keep the dangerous method sealed; publish the history.',[flag('archive_outcome','garrison'),rep('veil',12),ev('choice','ilyra_copy_choice')],[],'',['practical']),choice('later','Let us read it once more.')]);
offer('sera','sera_water','Do you believe the rumor about the fever?');
turnin('sera','sera_water',2,'The water was fouled upstream.','sera_water_end','A broken drain. All those arguments about who belonged here, when someone only needed to lift a loose stone. We can repair a drain. We should repair the story too.');
const herbsTurnin=D.sera_camp.choices.find(c=>c.id==='finish_sera_water');
herbsTurnin.conditions.push(R('item','wild_herb',3)); herbsTurnin.effects.unshift(E('consume','wild_herb',{amount:3}));
offer('sera','sera_names','Where is your original field ledger?', [R('approval','sera',20)]);
turnin('sera','sera_names',2,'I brought the ledger.','sera_names_end','The dividing line is not mine. I remember the quartermaster asking which column a child belonged in. I remember telling him to fetch more water.');
offer('sera','sera_open','Help me put the well and the story right.',[R('approval','sera',30)]);
D.sera_camp.choices.push(choice('charter','The filter is fitted. Let us agree on the clinic.',[],[R('stage','sera_open',1)],'sera_open_choice'));
D.sera_open_choice=node('sera','The Compact can supply a staffed infirmary. The travelers offer a smaller clinic with an open door. I want supplies. I also want the key to stay on this side of the door.',[
 choice('open','An open clinic. We will keep the shelves filled.',[flag('well_outcome','shelter'),rep('hearth',-8),rep('bough',10),ev('choice','sera_open_choice')],[],'',['merciful']),
 choice('compact','Take the supplies, with a written right to treat everyone.',[flag('well_outcome','garrison'),rep('hearth',12),ev('choice','sera_open_choice')],[],'',['practical']),choice('later','We should not rush the charter.')]);
for(const id of ['tarin','ilyra','sera']) D[id+'_camp'].choices.push(choice('goodbye','Rest while you can.'));
D.bren_camp.choices.find(x=>x.id==='letters').conditions=[R('not_started','bren_letters')];
D.bren_camp.variants=[{conditions:[R('flag','cinder_outcome','shelter')],text:'Three families slept under the new roof last night. I counted the bedrolls. For once, I liked the number.'},{conditions:[R('flag','cinder_outcome','garrison')],text:'The new watch has an open gate and a pot on the fire. I made them put both in the orders.'}];

// Act I has ten chapters; old village quests and the original moonseed journey remain available.
const contacts={rowan:{entry:'rowan_stories'},keeper:{entry:'keeper_stories'},hester:{name:'Hester Vane',role:'Lantern quartermaster',faction:'hearth',dialogue:'A road is only useful if people can afford to use it.',entry:'hester_stories'},yew:{name:'Warden Yew',role:'Elderbough envoy',faction:'bough',dialogue:'The vale does not end where a fence is built.',entry:'yew_stories'},orsa:{name:'Orsa Venn',role:'Veil archivist',faction:'veil',dialogue:'I have corrected this account before. I hope I am better at it now.',entry:'orsa_stories'}};
site('cold_milestone','The Cold Milestone',1,1,[obj('cold_lantern','A cold road lantern','The oil is full. The wick is dry. A thin silver root has curled around the stone below it.','campfire-stand.glb')]);
site('root_testimony','Roots of the First Road',2,2,[obj('root_name','Moss-covered name','“Ena, first witness. A light freely given may be freely returned.”','signpost.glb')]);
site('three_promises','The Three Roads Meeting',3,1,[],{npcs:[{id:'hester',offset:[-4,0,0]},{id:'yew',offset:[0,0,3]},{id:'orsa',offset:[4,0,0]}]});
site('oath_vault','The First Witness Vault',6,2,[obj('vault_door','Enter the Witness Vault','The stair follows the oldest roots.','signpost.glb',{action:'dungeon',dungeon:'story_oath_vault'}),obj('oath_cradle','The returned light','The guardian’s seal is broken. A patient silver glow fills the cradle.','chest.glb',{requires:[R('defeated','story_oath_vault/guardian')]})]);
site('lantern_crossing','Lantern Crossing',4,0,[obj('crossing_beacon','Crossing beacon','The road has a steady light again.','campfire-stand.glb',{requires:[R('defeated','crossing_0'),R('defeated','crossing_1'),R('defeated','crossing_2')]})],{enemies:[enemy('crossing_0','skeleton',[-4,0,3]),enemy('crossing_1','archer',[4,0,3]),enemy('crossing_2','skeleton',[0,0,-5])],enemy_conditions:[R('completed','act1_08')],variant:'lantern_covenant'});
site('willowmere_well','Willowmere Well',0,0,[],{fixed:true,address:{x:'0',z:'0',local:[0,0,4]}});
site('shrine_contact','Willowmere Shrine',0,0,[],{fixed:true,address:{x:'0',z:'0',local:[-9,0,-2]}});
quest('act1_01','The Lantern That Went Cold','A road lamp has gone cold without using its oil. Rowan asks you to look before the rumor grows.','Main','rowan',[step('interact','cold_lantern','Examine the cold lantern.','cold_milestone'),step('talk','rowan','Tell Rowan what you found.','willowmere_well')]);
quest('act1_02','A Name Beneath the Moss','The silver root points toward the name of the first witness. Elowen may recognize the words.','Main','keeper',[step('interact','root_name','Read the first witness’s stone.','root_testimony'),step('talk','keeper','Ask Elowen about the freely given light.','shrine_contact')],{prerequisites:['act1_01']});
quest('act1_03','Company for the Road','The road beyond Willowmere is safer shared. Find someone with a reason to travel beside you.','Main','rowan',[step('recruit','*','Recruit one traveling companion.','bren_watch'),step('talk','rowan','Tell Rowan who is coming with you.','willowmere_well')],{prerequisites:['act1_02']});
quest('act1_04','Three Promises','The Compact, Wardens and Keepers remember different parts of the first oath. Hear each account.','Main','rowan',[step('talk','hester','Hear the Compact’s request.','three_promises'),step('talk','yew','Hear the Wardens’ warning.','three_promises'),step('talk','orsa','Hear the Keeper’s correction.','three_promises'),step('talk','rowan','Bring the three accounts to Rowan.','willowmere_well')],{prerequisites:['act1_03']});
quest('act1_05','Room on the Road','A new supply road could protect caravans or preserve the older woodland route. Choose where the work begins.','Main','rowan',[step('choice','road_policy','Agree on the road plan with Rowan.','willowmere_well')],{prerequisites:['act1_04']});
quest('act1_06','A Fire That Stays','A camp is needed where travelers can stop while the vault is opened. Build it, then supply the first watch.','Main','rowan',[step('camp','established','Establish your camp on safe open ground.'),step('choice','watch_supplies','Bring six wood and three herbs to the camp watch.','',{camp:true})],{prerequisites:['act1_05']});
quest('act1_07','The Oath Beneath Stone','Elowen has found the entrance to the First Witness Vault. Its guardian still enforces an order no living person gave.','Main','keeper',[step('defeat','story_oath_vault/guardian','Enter the Witness Vault and defeat its guardian.','oath_vault')],{prerequisites:['act1_06'],reward:{coins:75,xp:120,shards:2}});
quest('act1_08','The Borrowed Dawn','The guardian’s seal has fallen. Recover the light from the cradle at the vault entrance.','Main','keeper',[step('interact','oath_cradle','Recover the returned light.','oath_vault'),step('talk','keeper','Let Elowen read the witness’s answer.','shrine_contact')],{prerequisites:['act1_07']});
quest('act1_09','Night on the Road','The broken oath has drawn its last sentries to Lantern Crossing. Hold the road while the new beacon is lit.','Main','rowan',[step('defeat','crossing_0','Defeat the first oathbound sentry.','lantern_crossing'),step('defeat','crossing_1','Silence the oathbound archer.','lantern_crossing'),step('defeat','crossing_2','Defeat the last sentry.','lantern_crossing'),step('interact','crossing_beacon','Light the crossing beacon.','lantern_crossing')],{prerequisites:['act1_08']});
quest('act1_10','Whose Light Is It?','The road is safe. The light can be placed under one charter or entrusted to each settlement. Make a promise the living can keep.','Main','rowan',[step('choice','lantern_covenant','Settle the lantern charter with Rowan.','willowmere_well')],{prerequisites:['act1_09'],reward:{coins:120,xp:160,shards:3},effects:[flag('act1_complete'),E('lore','first_oath'),E('item','witness_ring')]});
token('witness_ring','Ring of the First Witness','A plain band, given freely and carrying no claim of obedience.',{max_hp:20,defense:3});
D.rowan_stories=node('rowan','The roads have carried enough old orders. I would like to hear what the people walking them need now.',[]);
D.keeper_stories=node('keeper','The wishing stone remembers what was offered. We must learn whether anyone was free to refuse.',[]);
for(const id of ['hester','yew','orsa']) D[id+'_stories']=node(id,contacts[id].dialogue,[]);
function contactOffer(npc,qid,text){D[contacts[npc].entry].choices.push(choice('offer_'+qid,text,[E('start',qid)],[R('not_started',qid),...(Q[qid].prerequisites??[]).map(x=>R('completed',x)),...(Q[qid].conditions??[])]));}
function report(npc,qid,index,text,response){
 const name=qid+'_'+npc+'_report';
 D[contacts[npc].entry].choices.push(choice(name,text,[ev('talk',npc)],[R('stage',qid,index)],name));
 D[name]=node(npc,response,[choice('continue','I understand.')]);
}
for(const [npc,id,text] of [['rowan','act1_01','Tell me about the cold lantern.'],['keeper','act1_02','Who was the first witness?'],['rowan','act1_03','I should not take this road alone.'],['rowan','act1_04','Let us hear the three factions.'],['rowan','act1_05','We need to decide where the road goes.'],['rowan','act1_06','We will need a place to make camp.'],['keeper','act1_07','Where is the First Witness Vault?'],['keeper','act1_08','The guardian is at rest.'],['rowan','act1_09','The crossing must hold tonight.'],['rowan','act1_10','The beacon is lit. We should settle the charter.']]) contactOffer(npc,id,text);
report('rowan','act1_01',1,'The oil is full. Silver roots closed the lamp.','Roots, not thieves. Thank you for looking before reaching for a culprit. Elowen remembers a stone east of here with silver roots around a name.');
report('keeper','act1_02',1,'The stone says the light may be returned.','Ena was a witness, not a queen. The first light was a gift to the road. The later charters treat it as a debt. Find company before you follow that disagreement underground.');
report('rowan','act1_03',1,'I have found someone to travel with.','Then you already know something the old charter forgot. People stand beside us by choice. The three envoys are waiting where the roads meet east of the village.');
report('hester','act1_04',0,'What does the Compact ask of the light?','A supply road we can keep open through winter. I have ledgers full of villages that were warm in summer. I need them warm in February.');
report('yew','act1_04',1,'What would the Wardens protect?','The stream under that road feeds six clearings. A straight line on a map can be a crooked bargain on the ground. Keep the old crossing; repair what is already there.');
report('orsa','act1_04',2,'What did the first oath actually promise?','A light freely offered, witnessed by three people. We preserved the witnesses’ titles and lost their right to leave. I helped copy that mistake. I intend to help correct it.');
report('rowan','act1_04',3,'I have heard all three accounts.','Winter stores, living water, and a promise that can end. None is a foolish thing to ask for. We still have to choose where tomorrow’s workers begin.');
report('keeper','act1_08',1,'The cradle released its light.','It waited for a witness who could leave. You returned anyway. That is the part of the oath we can keep. Take the light to Lantern Crossing; its last sentries will follow it.');
D.rowan_stories.choices.push(choice('road','Let us choose the road plan.',[],[R('stage','act1_05',0)],'road_policy'));
D.road_policy=node('rowan','Hester can secure the straight supply road. Yew can reopen the winding woodland crossing. Both will carry food; the cost falls in different places.',[
 choice('compact','Build the supply road and protect the wells.',[flag('road_policy','compact'),rep('hearth',18),rep('bough',-12),ev('choice','road_policy')],[],'',['practical','authority']),
 choice('wardens','Repair the woodland crossing. Keep the stream free.',[flag('road_policy','wardens'),rep('bough',18),rep('hearth',-12),ev('choice','road_policy')],[],'',['wild','merciful'])]);
D.rowan_stories.choices.push(choice('charter','Let us choose the lantern charter.',[],[R('stage','act1_10',0)],'lantern_covenant'));
D.lantern_covenant=node('rowan','One charter would promise equal stores, kept by the Compact. Separate lights would belong to the settlements, with no one able to demand them back. We can make either promise honestly.',[
 choice('shared','Let each settlement hold its own light.',[flag('lantern_covenant','shelter'),rep('bough',16),rep('veil',8),rep('hearth',-6),ev('choice','lantern_covenant')],[],'',['honest','merciful']),
 choice('charter','Keep one public charter, with the right for any settlement to leave.',[flag('lantern_covenant','garrison'),rep('hearth',16),rep('veil',8),rep('bough',-6),ev('choice','lantern_covenant')],[],'',['practical']),
 choice('witnessed','Have all three factions witness a shared charter.',[flag('lantern_covenant','shelter'),flag('three_witnesses'),rep('hearth',12),rep('bough',12),rep('veil',12),ev('choice','lantern_covenant')],[R('reputation','hearth',10),R('reputation','bough',10),R('reputation','veil',10)],'',['honest'])]);
D.rowan_stories.variants=[{conditions:[R('flag','act1_complete'),R('flag','three_witnesses')],text:'Three names on the new charter, and none above the others. The road will test it. That is how promises become useful.'},{conditions:[R('flag','act1_complete'),R('flag','lantern_covenant','shelter')],text:'The settlement lamps were lit separately. For the first time, no one counted that as disobedience. There is still work on the road. It belongs to the living now.'},{conditions:[R('flag','act1_complete')],text:'Hester sent the new charter to every settlement. The right to leave is in the first paragraph. I checked. The light will have to earn its welcome.'}];
for(const id of Object.keys(C)) {
 D[id+'_camp'].choices=D[id+'_camp'].choices.filter(x=>x.id!=='watch_supplies');
 D[id+'_camp'].choices.unshift(choice('watch_supplies','Here are supplies for the first camp watch.',[E('consume','wood',{amount:6}),E('consume','wild_herb',{amount:3}),ev('choice','watch_supplies')],[R('stage','act1_06',1),R('item','wood',6),R('item','wild_herb',3)]));
}

// Three new quests for each established faction, sharing the existing reputation/economy.
site('bridge_stores','Winter Bridge Stores',5,1,[obj('bridge_plank','Bridge stores','Dry boards will keep the bridge passable through the first frost.','resource-wood.glb',{requires:[R('item','wood',5)],effects:[E('consume','wood',{amount:5})]})]);
site('poisoned_sluice','The Blocked Sluice',-1,5,[obj('sluice','Clogged woodland sluice','The old channel opens. Clear water slips under the stone.','barrel.glb',{requires:[R('item','stone',3)],effects:[E('consume','stone',{amount:3})]})]);
site('witness_stone','The Third Witness',5,-2,[obj('third_witness','The third witness’s tablet','“If the road ceases to shelter strangers, its guardians shall lay down their arms.”','signpost.glb')],{enemies:[enemy('tablet_guard','skeleton')]});
const factionRows=[
 ['hearth','hester','Dry Boards for Winter','Carry five wood to the winter bridge stores.',[step('interact','bridge_plank','Supply the bridge stores with five wood.','bridge_stores'),step('talk','hester','Report to Hester.','three_promises')]],
 ['hearth','hester','The Cost of a Straight Road','Inspect the water channel before Hester’s workers move in.',[step('interact','sluice','Clear the sluice with three stone.','poisoned_sluice'),step('talk','hester','Show Hester the water route.','three_promises')]],
 ['hearth','hester','A Ledger with Open Pages','Settle who may inspect the Compact’s winter stores.',[step('choice','hearth_charter','Agree on the stores charter.','three_promises')]],
 ['bough','yew','Water Before Borders','Clear the blocked sluice that feeds the southern clearings.',[step('interact','sluice','Reopen the sluice with three stone.','poisoned_sluice'),step('talk','yew','Tell Yew where the water runs.','three_promises')]],
 ['bough','yew','An Unhunted Path','Clear the snare line and leave a safe game trail.',[step('defeat','snare_wolf','Drive off the wolf near the snares.','snare_hollow'),step('interact','cut_snare','Remove the snare.','snare_hollow'),step('talk','yew','Report the safe trail to Yew.','three_promises')]],
 ['bough','yew','The Gate in the Boundary','Choose whether winter travelers need a Warden’s permit.',[step('choice','bough_charter','Agree on passage with Yew.','three_promises')]],
 ['veil','orsa','A Third Name','Read the third witness’s stone before another copy is made.',[step('interact','third_witness','Read the third witness’s tablet.','witness_stone'),step('talk','orsa','Bring the wording to Orsa.','three_promises')]],
 ['veil','orsa','An Order Without a Voice','Free the old sentry from an order that has outlived its purpose.',[step('defeat','tablet_guard','Release the tablet’s guardian.','witness_stone'),step('talk','orsa','Report to Orsa.','three_promises')]],
 ['veil','orsa','The Public Record','Decide how the corrected oath will be taught.',[step('choice','veil_charter','Settle the corrected record with Orsa.','three_promises')]]
];
const counts={};
for(const [f,npc,title,desc,stages] of factionRows){
 const index=counts[f]=(counts[f]??0)+1, id=f+'_story_'+index;
 quest(id,title,desc,'Faction',npc,stages,{prerequisites:index>1?[f+'_story_'+(index-1)]:[],conditions:[R('reputation',f,-49)],reward:{coins:35,xp:50,shards:index===3?1:0,faction:f,reputation:15,unlock:index===3?f+'_accord':''}});
 contactOffer(npc,id,title+'.');
 if(index<3) report(npc,id,stages.length-1,'Report: '+title+'.',{hearth:index===1?'Five boards are a small entry in a ledger. They are a whole bridge to someone crossing in the snow. I will put the workers on the water survey next.':'The water runs farther than our boundary stones. I have moved the stores uphill. There is one more thing a useful road needs: people willing to trust its keeper.',bough:index===1?'The channel was older than the fence. Thank you for remembering which one should move. There is a snare line farther north that needs the same care.':'A safe game trail is also a safe path for a hungry traveler. I would like our rules to remember that.',veil:index===1?'“Shall lay down their arms.” That clause is missing from our oath. I know whose hand copied the page. Mine.':'The sentry can rest. We should decide what the next apprentice learns before they are handed another incomplete order.'}[f]);
 else D[contacts[npc].entry].choices.push(choice('charter_'+f,'Let us settle the '+({hearth:'stores',bough:'passage',veil:'record'}[f])+' charter.',[],[R('stage',id,0)],f+'_charter'));
}
D.hearth_charter=node('hester','Open ledgers will make my work slower. Closed ones will make every shortage look like theft. Which trouble should I take on?',[
 choice('open','Let village stewards inspect the stores.',[flag('hearth_open_books'),rep('bough',8),ev('choice','hearth_charter')],[],'',['honest']),
 choice('audit','Appoint one sworn auditor from each faction.',[flag('hearth_auditors'),rep('veil',8),ev('choice','hearth_charter')],[],'',['practical'])]);
D.bough_charter=node('yew','A permit lets us count travelers. An open gate asks us to trust them. After the work you have done, I can argue for either.',[
 choice('open','Keep the gate open and publish the safe paths.',[flag('bough_open_gate'),rep('hearth',8),ev('choice','bough_charter')],[],'',['merciful']),
 choice('permits','Issue free permits at every refuge.',[flag('bough_free_permits'),rep('veil',8),ev('choice','bough_charter')],[],'',['practical'])]);
D.veil_charter=node('orsa','We can publish the whole corrected oath or begin by teaching its history. Either way, the correction bears my name.',[
 choice('whole','Publish it in full. People can read a promise for themselves.',[flag('veil_public_oath'),rep('bough',8),ev('choice','veil_charter')],[],'',['honest','curious']),
 choice('history','Teach the history first, with the binding kept under witness.',[flag('veil_witnessed_teaching'),rep('hearth',8),ev('choice','veil_charter')],[],'',['practical'])]);
for(const id of ['rowan','keeper']) D[contacts[id].entry].choices.push(choice('village','Let us talk about the village and the old tasks.',[],[],'@legacy'));
D.hester_stories.variants=[{conditions:[R('flag','grain_delivered')],text:'The grain cart reached us. Three sacks have gone to your camp stores. I wrote down the driver’s name beside yours.'},{conditions:[R('flag','helped_carters')],text:'The carter told me who braced the wheel. A ledger never shows quite how much work stands behind a delivered sack.'}];
D.yew_stories.variants=[{conditions:[R('flag','guided_travelers')],text:'The traveler you guided found the marked road. We are replacing the old signs before the next fog.'},{conditions:[R('flag','road_shelters')],text:'Two travelers told us where you shared dry timber. There is room for that fire on our road map.'}];
D.orsa_stories.variants=[{conditions:[R('flag','echoes_released')],text:'The echo has fallen quiet. I have recorded the unfinished sentence with a blank at the end. It is more honest than inventing the missing words.'}];
D.bren_intro.text=D.bren_intro.text.replace('dispatch satchel','dispatch case');
L.dispatch.objects[0].name='Mud-stained dispatch case'; Q.bren_recruit.stages[0].text='Search the fallen dispatch case.';
for(const siteId of ['glass_archive','field_hospital','witness_stone']) for(const object of L[siteId].objects) {
 if(['archive_margin','archive_record','field_ledger','third_witness'].includes(object.id)) { object.model='res://assets/3d/phase6/props/Book_Stack_1.gltf'; object.height=.45; }
}
for(const id of Object.keys(contacts)) D[contacts[id].entry].choices.push(choice('goodbye','Until we meet again.'));
for(const [id,c] of Object.entries(C)) B[id]={id,category:'People',title:c.name,text:c.biography};
for(const [id,title,text] of [['hearth','The Lantern Compact','The Compact keeps winter stores and patrols the roads. Its ledgers can be a promise of fair shares or a reason to turn someone away.'],['bough','The Elderbough Wardens','The Wardens maintain woodland paths and living water. Their oldest rules protect travelers as well as the forest.'],['veil','The Keepers of the Veil','The Keepers preserve relics and old promises. A missing sentence can turn preservation into imprisonment.']]) B[id]={id,category:'Factions',title,text};
Object.assign(B,{first_oath:{id:'first_oath',category:'History',title:'The First Oath',text:'Three witnesses accepted a light freely offered to the road. The surviving original gives every witness the right to leave. Later copies preserved the guardians and omitted the release.'},witness_light:{id:'witness_light',category:'Relics',title:'The Borrowed Dawn',text:'The first road lantern was lit by a gift, not a tribute. Its light dims when its custodians mistake an agreement for ownership.'},oathbound:{id:'oathbound',category:'Creatures',title:'Oathbound Sentries',text:'These guardians remember instructions more clearly than faces. Breaking a binding releases the memory; it does not awaken the person who once carried it.'}});
for(const id of Object.keys(L)) if(!B[id]) B[id]={id,category:'Places',title:L[id].name,text:'A place remembered along the lantern roads. '+(L[id].objects?.[0]?.text??'Travelers bring their own reasons for stopping here.')};
for(const [f,name,stats] of [['hearth','Lantern steward’s badge',{max_hp:15,defense:3}],['bough','Open-path charm',{move_percent:.06,crit:.03}],['veil','Witness seal',{cooldown_reduction:.06,attack:3}]]) {
 token(f+'_accord_token',name,'Offered by allied merchants after the '+({hearth:'stores',bough:'passage',veil:'record'}[f])+' charter. Requires Friendly standing.',stats);
 Q[f+'_story_3'].description+=' The accord opens signature equipment at Friendly faction merchants.';
}
for(const [name,data] of Object.entries({companions:C,quests:Q,dialogue:D,locations:L,items:I,lore:B,contacts})) fs.writeFileSync(root+name+'.json',JSON.stringify(data,null,2)+'\n');
console.log({companions:Object.keys(C).length,quests:Object.keys(Q).length,main:Object.values(Q).filter(q=>q.category==='Main').length,faction:Object.values(Q).filter(q=>q.category==='Faction').length,personal:Object.values(C).reduce((n,c)=>n+c.personal.length,0),dialogues:Object.keys(D).length,locations:Object.keys(L).length});
