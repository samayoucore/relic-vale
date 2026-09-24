import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root='relic_vale';
const data=n=>JSON.parse(fs.readFileSync(root+'/data/'+n+'.json'));
let checks=0;
function check(value,description){if(!value)throw Error(description);checks++;}
const fish=data('fish'), crops=data('crops'), recipes=data('cooking'), items=data('phase8_items');
check(Object.keys(data('professions')).length===6,'Six professions');
check(Object.keys(fish).length===20,'Twenty fish');
check(Object.keys(crops).length===8,'Eight crops');
check(recipes.length===24,'Twenty-four recipes');
for(const item of Object.values(items))if(item.model)check(fs.existsSync(item.model.replace('res://',root+'/')),'Missing model '+item.id);
for(const f of Object.values(fish)){
 check(fs.existsSync(root+'/assets/ui/phase8/icons/'+f.id+'.png'),'Missing fish icon '+f.id);
 check(f.min_level>=1&&f.min_level<=25,'Fish level bounds');
}
for(const c of Object.values(crops))for(let stage=1;stage<=4;stage++)check(fs.existsSync(root+'/assets/3d/phase8/ultimatecrops/'+c.model+'_'+stage+'.glb'),'Missing crop stage '+c.id+'/'+stage);
const assets=JSON.parse(fs.readFileSync(root+'/docs/PHASE_8_ASSETS.json'));
check(assets.models===82&&assets.icons===60,'Runtime model/icon counts');
for(const entry of assets.files){const p=root+'/'+entry.file;check(fs.existsSync(p),'Missing runtime file '+p);check(crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex')===entry.sha256,'Asset digest mismatch '+p);if(p.endsWith('.glb')){const b=fs.readFileSync(p);check(b.toString('ascii',0,4)==='glTF','Invalid GLB');const j=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)));check(j.meshes?.some(m=>m.primitives?.length),'GLB has no visible geometry');check(j.materials.every(m=>(m.pbrMetallicRoughness?.baseColorFactor?.[3]??1)>0),'Invisible GLB material');}}
const results=JSON.parse(fs.readFileSync(root+'/docs/PHASE_8_TEST_RESULTS.json'));
check(results.runs.length===9,'All nine release validation runs must finish');
check(results.failed===0&&results.runs.every(r=>r.engine_errors===0),'Clean runtime validation');
for(const name of ['PHASE_8.md','PROFESSIONS.md','FISHING.md','FARMING.md','MOUNTS.md','COOKING.md','ASSET_CREDITS.md','NEXT_STEPS.md']){
 const p=root+'/docs/'+name;check(fs.existsSync(p),'Missing required document');
 for(const m of fs.readFileSync(p,'utf8').matchAll(/\]\(([^)]+)\)/g)){if(/^(https?:|#)/.test(m[1]))continue;check(fs.existsSync(path.resolve(path.dirname(p),m[1])),'Broken local document link '+m[1]);}
}
const preserved=JSON.parse(fs.readFileSync('downloads/RelicVale-v0.7-baseline.receipt.json','utf8').replace(/^\uFEFF/,''));
check(crypto.createHash('sha256').update(fs.readFileSync('downloads/'+preserved.archive)).digest('hex').toUpperCase()===preserved.sha256,'Phase 7 archive changed');
for(const log of ['phase8-clean-import.log','phase8-clean-startup.log']){
 check(fs.existsSync('downloads/'+log),'Missing clean-copy verification log');
 check(!/(SCRIPT ERROR:|ERROR:|WARNING:)/.test(fs.readFileSync('downloads/'+log,'utf8')),'Clean-copy engine error');
}
const receipt={release:'0.8',static_checks:checks,assertion_executions:results.passed,failed:results.failed,models:assets.models,icons:assets.icons,clean_import:true,clean_startup:true,clean_copy_separate_userdata:true,phase7_archive_unchanged:true};
fs.writeFileSync(root+'/docs/PHASE_8_RELEASE_CHECKS.json',JSON.stringify(receipt,null,2));
console.log(JSON.stringify(receipt));
