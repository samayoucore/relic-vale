import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const project='relic_vale';
const read=n=>JSON.parse(fs.readFileSync(project+'/data/'+n+'.json','utf8'));
const C=read('narrative/companions'),Q=read('narrative/quests'),D=read('narrative/dialogue'),L=read('narrative/locations'),E=read('narrative/events'),B=read('narrative/lore');
const I={...read('items'),...read('phase8_items'),...read('narrative/items')},F=read('factions'),P=read('professions'),N={...read('npcs'),...read('narrative/contacts'),...C};
let count=0; const issues=[];
function check(ok,label){count++;if(!ok)issues.push(label);}
const file=p=>p.startsWith('res://')&&fs.existsSync(p.replace('res://',project+'/'));
check(Object.keys(C).length===4,'Four companions');check(Object.keys(Q).length===35,'35 added quests');check(Object.keys(E).length===8,'Eight events');
check(Object.values(Q).filter(q=>q.category==='Main').length===10,'Ten main quests');check(Object.values(Q).filter(q=>q.category==='Faction').length===9,'Nine faction quests');
const conditionTypes=['flag','recruited','active','approval','completed','not_completed','not_started','stage','profession','reputation','item','camp','at_camp','defeated'];
const effectTypes=['start','event','flag','approval','reputation','item','consume','recruit','lore','coins'];
const enemies=new Set(Object.values(L).flatMap(l=>(l.enemies??[]).map(e=>e.id)).concat(['story_oath_vault/guardian']));
function conditions(rules=[],where){for(const r of rules){check(conditionTypes.includes(r.type),where+' condition '+r.type);if(['recruited','active','approval'].includes(r.type))check(C[r.id],where+' companion '+r.id);if(['completed','not_completed','not_started','stage'].includes(r.type))check(Q[r.id],where+' quest '+r.id);if(r.type==='profession')check(P[r.id],where+' profession '+r.id);if(r.type==='reputation')check(F[r.id],where+' faction '+r.id);if(r.type==='item')check(I[r.id],where+' item '+r.id);if(r.type==='defeated')check(enemies.has(r.id),where+' enemy '+r.id);}}
function effects(actions=[],where){for(const e of actions){check(effectTypes.includes(e.type),where+' effect '+e.type);if(e.type==='start')check(Q[e.id],where+' quest '+e.id);if(['recruit','approval'].includes(e.type))check(C[e.id],where+' companion '+e.id);if(e.type==='reputation')check(F[e.id],where+' faction '+e.id);if(['item','consume'].includes(e.type))check(I[e.id],where+' item '+e.id);if(e.type==='lore')check(B[e.id],where+' lore '+e.id);}}
for(const c of Object.values(C)){
 check(c.id&&c.name&&c.biography&&F[c.faction],'Companion identity '+c.id);
 check(file(c.model)&&file(c.portrait),'Companion assets '+c.id);check(Q[c.recruitment],'Recruitment '+c.id);
 check(c.personal.length===3&&c.personal.every(id=>Q[id]),'Personal trilogy '+c.id);
 for(const id of Object.values(c.equipment))check(!id||I[id],'Default equipment '+id);
 check(c.abilities.length===2&&c.abilities.every(a=>a.id&&a.cooldown>0),'Two role abilities '+c.id);
 for(const key of ['forest','rain','night','ruin','boss','camp','town','personal','story','combat'])check(c.barks[key],c.id+' bark '+key);
}
function ancestry(id,stack=[]){check(!stack.includes(id),'Quest dependency cycle '+id);if(stack.includes(id))return;for(const p of Q[id].prerequisites??[]){check(Q[p],'Missing prerequisite '+p);if(Q[p])ancestry(p,[...stack,id]);}}
for(const [id,q] of Object.entries(Q)){
 check(N[q.npc]&&q.id===id&&q.count===q.stages.length,'Quest identity/count '+id);ancestry(id);conditions(q.conditions,id);effects(q.effects,id);
 for(const s of q.stages){check(['talk','interact','defeat','reach','collect','camp','recruit','choice'].includes(s.type),'Stage kind '+id);if(s.location)check(L[s.location],'Objective location '+id);conditions(s.conditions,id);if(s.type==='defeat')check(enemies.has(s.target),'Enemy target '+s.target);if(s.type==='interact')check(L[s.location]?.objects?.some(o=>o.id===s.target),'Physical objective '+s.target);}
}
for(const [id,d] of Object.entries(D)){
 check(N[d.speaker]&&d.text?.length>0,'Dialogue speaker/text '+id);check(new Set(d.choices.map(c=>c.id)).size===d.choices.length,'Unique choice IDs '+id);
 conditions(d.conditions,id);for(const v of d.variants??[])conditions(v.conditions,id);
 for(const c of d.choices){check(c.text?.length>0,'Choice text '+id);check(!c.next||c.next==='@legacy'||D[c.next],'Dialogue link '+id+' → '+c.next);conditions(c.conditions,id);effects(c.effects,id);}
}
for(const [id,l] of Object.entries(L)){
 check(/^[-]?\d+$/.test(l.address.x)&&/^[-]?\d+$/.test(l.address.z),'Canonical site address '+id);
 for(const o of l.objects??[]){check(file(o.model),'Story object model '+o.id);conditions(o.requires,o.id);effects(o.effects,o.id);}
 for(const e of l.enemies??[])check(read('enemies')[e.archetype],'Enemy archetype '+e.id);
 conditions(l.enemy_conditions,id);
}
for(const [id,e] of Object.entries(E)){
 check(file('res://assets/3d/phase7/'+e.model),'Event prop '+id);check(F[e.reward.faction]&&e.reward.coins>=0,'Event reward '+id);conditions(e.conditions,id);
 for(const item of Object.keys(e.cost))check(I[item]&&e.cost[item]>0,'Event cost '+id);for(const kind of e.enemies)check(read('enemies')[kind],'Event enemy '+id);
}
const text=JSON.stringify({C,Q,D,L,E,B});check(!/(Lorem ipsum|TODO|placeholder|implementation detail)/i.test(text),'No placeholder narrative text');
check(new Set(Object.values(B).map(b=>b.category)).size===6,'Six lore categories');
const manifest=JSON.parse(fs.readFileSync(project+'/docs/PHASE_9_ASSETS.json','utf8'));
for(const entry of manifest.files)check(crypto.createHash('sha256').update(fs.readFileSync(project+'/'+entry.file)).digest('hex')===entry.sha256,'Asset hash '+entry.file);
const receiptPath=project+'/docs/PHASE_9_TEST_RESULTS.json';
if(!process.argv.includes('--content-only')){
 const results=JSON.parse(fs.readFileSync(receiptPath,'utf8'));check(results.failed===0&&results.runs.length>=7,'Completed gameplay suite');
 for(const r of results.runs)check(r.failed===0&&r.engine_errors===0,'Runtime log '+r.name);
 for(const name of ['PHASE_9.md','COMPANION_SYSTEM.md','NARRATIVE_SYSTEM.md','WORLD_EVENTS.md','CAMERA_AND_CAMP.md','NEXT_STEPS.md','ASSET_CREDITS.md']){
  const p=project+'/docs/'+name;check(fs.existsSync(p),'Document '+name);
  for(const link of fs.readFileSync(p,'utf8').matchAll(/\]\(([^)]+)\)/g)){if(/^(https?:|#)/.test(link[1])||link[1]==='PHASE_9_RELEASE_CHECKS.json')continue;check(fs.existsSync(path.resolve(path.dirname(p),link[1])),'Document link '+link[1]);}
 }
 for(const log of ['phase9-clean-import.log','phase9-clean-startup.log'])check(fs.existsSync('downloads/'+log)&&!/(SCRIPT ERROR:|ERROR:|WARNING:)/.test(fs.readFileSync('downloads/'+log,'utf8')),'Clean-copy verification '+log);
 const old=JSON.parse(fs.readFileSync('downloads/RelicVale-v0.8-baseline.receipt.json','utf8').replace(/^\uFEFF/,''));check(crypto.createHash('sha256').update(fs.readFileSync('downloads/'+old.archive)).digest('hex').toUpperCase()===old.sha256,'Preserved Phase 8 archive');
 if(issues.length===0)fs.writeFileSync(project+'/docs/PHASE_9_RELEASE_CHECKS.json',JSON.stringify({release:'0.9',static_checks:count,assertion_executions:results.passed,failed:0,companions:4,quests:35,events:8,portraits:4,clean_import:true,clean_startup:true,previous_archive_preserved:true},null,2)+'\n');
}
console.log(JSON.stringify({static_checks:count,issues},null,2));if(issues.length)process.exitCode=1;
