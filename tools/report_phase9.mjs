import fs from 'node:fs';
import crypto from 'node:crypto';
const dir='relic_vale/docs/';
const definitions=[
 ['First companion slice','SLICE','phase9-slice-final.log',52],
 ['First companion fresh reload','RELOAD','phase9-reload-final.log',7],
 ['Complete expanded story','STORIES','phase9-stories-final.log',215],
 ['Expanded story fresh reload','STORIES_RELOAD','phase9-stories-reload-final.log',40],
 ['Contextual world events','EVENTS','phase9-events-camera.log',95],
 ['Events fresh reload','EVENTS_RELOAD','phase9-events-reload-camera.log',13],
 ['Companion gameplay and transitions','ACCEPTANCE','phase9-acceptance-camera.log',79],
 ['720p interface and input','POLISH','phase9-polish-final.log',14],
 ['Horizon, foreground, containment and camp clearance','CAMERA','phase9-camera-final.log',35],
 ['Camp clearance fresh reload','CAMERA_RELOAD','phase9-camera-reload.log',5],
 ['Phase 8 profession/interior regression',null,'phase9-phase8-regression.log',15],
];
const runs=[];
for(const [name,suffix,log,expected] of definitions){
 const text=fs.readFileSync('downloads/'+log,'utf8');
 const match=[...text.matchAll(/(?:PHASE\d+[_A-Z]*RESULT)\s+(\d+)\s+passed\s*\/\s*(\d+)\s+failed/g)].at(-1);
 if(!match)throw new Error('Missing completed run: '+log);
 const passed=Number(match[1]),failed=Number(match[2]);
 const engine_errors=[...text.matchAll(/(?:SCRIPT ERROR:|ERROR:|WARNING:)/g)].length;
 if(passed!==expected||failed||engine_errors)throw new Error('Run failed or count changed: '+log+' '+JSON.stringify({passed,failed,expected,engine_errors}));
 const receipt=suffix?'PHASE_9_'+suffix+'_TESTS.json':null;
 if(receipt){const r=JSON.parse(fs.readFileSync(dir+receipt));if(r.passed!==passed||r.failed!==failed||r.checks.length!==passed||r.checks.some(c=>!c.pass))throw new Error('Mismatched receipt: '+receipt);}
 runs.push({name,passed,failed,engine_errors,receipt,log,log_sha256:crypto.createHash('sha256').update(text).digest('hex'),completed_at:fs.statSync('downloads/'+log).mtime.toISOString()});
}
const result={release:'0.9',date:'2026-09-14',passed:runs.reduce((n,r)=>n+r.passed,0),failed:0,runs,notes:[
 'The first-companion slice preceded roster expansion; the expanded run completes all 35 added quests.',
 'After the camera/camp changes, the event, acceptance, polish, camera, camera-reload and expanded-story-reload suites were run again.',
 'Tests use isolated fixtures, controlled teleportation/materials and player invulnerability; these are integration checks, not human balance playtesting.',
 'Graphical runs use the bundled OpenGL Compatibility renderer and Dummy audio; audible output is unverified.'
]};
fs.writeFileSync(dir+'PHASE_9_TEST_RESULTS.json',JSON.stringify(result,null,2)+'\n');
let report=fs.readFileSync(dir+'PHASE_9.md','utf8').split('## Completed validation results')[0].trimEnd();
report+='\n\n## Completed validation results\n\n'+result.passed+' assertion executions passed across '+runs.length+' completed runs, with no script/engine errors or warnings in their final logs. Individual checks are in [the test index](PHASE_9_TEST_RESULTS.json).\n\n| Run | Passed | Failed |\n| --- | ---: | ---: |\n'+runs.map(r=>'| '+(r.receipt?'['+r.name+']('+r.receipt+')':r.name)+' | '+r.passed+' | '+r.failed+' |').join('\n')+'\n\nThe clean project was imported without an editor cache and launched in a native Godot window. The release ZIP is verified entry by entry against source hashes; its receipt is beside the archive.\n';
fs.writeFileSync(dir+'PHASE_9.md',report);
console.log(JSON.stringify({passed:result.passed,runs:runs.length,failed:0}));
