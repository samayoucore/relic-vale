import fs from 'node:fs';
const cases=[['phase6-core-gui-final.log','PHASE6_CORE_RESULT',64],['phase6-acceptance-final.log','PHASE6_ACCEPTANCE_RESULT',29],['phase6-acceptance-reload.log','PHASE6_ACCEPTANCE_RELOAD_RESULT',6],['phase6-validation.log','PHASE6_VALIDATION_RESULT',26],['phase6-stream-stress.log','STRESS5_RESULT',15],['phase6-far-reload.log','STRESS5_RESULT',4],['phase6-interior-reload.log','PHASE6_RELOAD_RESULT',6],['phase6-life-check.log','PHASE6_LIFE_RESULT',8],['phase6-visual-final.log','PHASE6_VISUAL_RESULT',4],['phase6-presentation-regression.log','PRESENTATION5_RESULT',38],['phase6-combat-regression.log','COMBAT3_RESULT',21]];
const results=cases.map(([name,marker,count])=>{
 const log=fs.readFileSync('downloads/'+name,'utf8');
 const line=log.split(/\r?\n/).findLast(l=>l.includes(marker))||'';
 if(!line.includes(count+' passed')||!line.includes('0 failed')||/SCRIPT ERROR|ERROR:|FAIL:/.test(log))throw new Error(name+': final check failed or incomplete. '+line);
 return {log:name,checks:count,result:line};
});
const report=fs.readFileSync('relic_vale/docs/PHASE_6_ACCEPTANCE.md','utf8');
for(let i=1;i<=29;i++)if(!new RegExp('^'+i+'\\. .*PASS$','m').test(report))throw new Error('Missing acceptance step '+i);
for(const file of ['README.md','docs/PHASE_6.md','docs/RESOURCE_SYSTEM.md','docs/NPC_SIMULATION.md','docs/INTERIORS.md','docs/ASSET_CREDITS.md','docs/NEXT_STEPS.md']){
 if(/Awaiting final run/.test(fs.readFileSync('relic_vale/'+file,'utf8')))throw new Error(file+' is incomplete');
}
const value={date:'2026-09-10',passed:results.reduce((n,r)=>n+r.checks,0),failed:0,acceptance_steps:29,streamed_steps:100,results};
fs.writeFileSync('relic_vale/docs/PHASE_6_TEST_RESULTS.json',JSON.stringify(value,null,2)+'\n');
console.log(JSON.stringify({passed:value.passed,failed:0,acceptance_steps:29,streamed_steps:100}));
