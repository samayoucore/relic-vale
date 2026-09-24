import fs from 'node:fs';
import crypto from 'node:crypto';
const cases=[['phase7-acceptance.log','PHASE7_RESULT',34],['phase7-gui-final.log','PHASE7_RESULT',33],['phase7-extra.log','PHASE7_EXTRA_RESULT',23],['phase7-visual-final.log','PHASE7_VISUAL_RESULT',11],['phase7-reload-final.log','PHASE7_RESULT',6],['phase7-village-regression.log','PHASE6_VALIDATION_RESULT',26],['phase7-combat-regression.log','COMBAT3_RESULT',21],['phase7-camera-gui-final.log','PRESENTATION5_RESULT',38]];
const results=cases.map(([log,marker,count])=>{
 const text=fs.readFileSync('downloads/'+log,'utf8'),line=text.split(/\r?\n/).findLast(l=>l.includes(marker))||'';
 if(!line.includes(count+' passed')||!line.includes('0 failed')||/SCRIPT ERROR|ERROR:|FAIL:/.test(text))throw Error(log+' incomplete or failed: '+line);
 return {log,checks:count,result:line};
});
const originalHash='f148c10773d7df355c793bdc6c3dd74f369e875fd5e94801933f73e1dc30f125';
const actualHash=crypto.createHash('sha256').update(fs.readFileSync('tools/godot/userdata/Godot/app_userdata/RelicValePrototype/journey.json')).digest('hex');
if(originalHash!==actualHash)throw Error('Original journey changed since Phase 7 verification');
const steps=[
'Explore multiple actual regions: generated and charted 161 chunks across starter and distant regions.',
'Open the world atlas in the running graphical game.',
'Review terrain-derived forests, rivers, roads and settlement/service icons in atlas screenshots.',
'Create a saved custom marker; extended GUI run also uses a real right click and pointer rename.',
'Move to a clearing at logical chunk 6, −6, several chunks from the marker.',
'Travel back to the marker through the player travel service.',
'Assert at least 25 destination chunks are ready and the loading page closes before control resumes.',
'Find an open, dry, suitably flat camp masterplan site away from roads and other sites.',
'Establish a physical camp, reserve the site and verify the placement preview in the graphical run.',
'Advance two game minutes and verify a guaranteed physical traveler.',
'Recruit the first resident; final visual run also accepts a nearby traveler with actual mouse input.',
'Open the persistent task board, inspect categories and locked requirement explanations.',
'Assign a starter foraging contract to one resident with no upfront donation.',
'Advance game time past the mission end.',
'Receive independent camp supplies, Camp XP and resident XP exactly once.',
'Advance a game day and recruit the next visitor.',
'Assign and resolve a two-resident mission; extended tests also exercise parties of three and four.',
'Add enough Camp XP to reach the current upgrade threshold.',
'Assert upgrade_pending and Camp XP exactly at the threshold.',
'Complete another XP-producing firewood assignment.',
'Assert Camp XP remains unchanged while the upgrade is pending.',
'Assert mission resources still increase; implementation awards Food, Materials and Gold independently of XP.',
'Donate wood and personal coins with exact debit checks; player UI uses explicit confirmations.',
'Purchase an affordable camp upgrade using camp supplies.',
'Assert XP resets to zero and upgrade_pending clears, with no overflow banking.',
'Render the changed camp tier.',
'Render all five tiers; extended economy test reaches every tier with one resident and zero donations in 57 contracts.',
'Enter the player house, inspect veteran cottages/newcomer tents, verify a sleeping veteran inside their assigned home and enter the permanent workshop.',
'Move to logical chunk 1000000000002, −999999999998 and verify the camp scene is unloaded.',
'Travel back using the permanent camp marker and the same safe-loading pipeline.',
'Verify resident count and camp resource balances survived unloading.',
'Save a tier-5 camp with workers, markers, supplies and one active mission to an isolated integration slot.',
'Quit the test game after audio shutdown.',
'Start a fresh Godot process and load that saved integration slot.',
'Verify markers, camp tier, residents, active mission and resources; advance game time and verify rewards resolve once.'
];
fs.writeFileSync('relic_vale/docs/PHASE_7_ACCEPTANCE.md','# Phase 7 acceptance\n\nThe required 35-step scenario is covered by the final integration, graphical, extended and fresh-process runs. Tests automate public gameplay methods and game-clock advancement; marker editing and recruitment also have real pointer input checks. Terrain is actually streamed and scenes rendered. Visual-only tier previews use the provided debug-equivalent tier settings; an additional economic test independently earns all upgrades.\n\n'+steps.map((s,i)=>`${i+1}. ${s} PASS`).join('\n\n')+'\n\nSee PHASE_7_TEST_RESULTS.json for exact run logs. Earlier failing development runs are retained in downloads for traceability and are excluded from the passing release evidence. Extra/visual/reload tests now suppress automatic writes to the shared integration fixture, so state-mutating exploratory checks cannot change the restart test input.\n');
const value={date:'2026-09-11',passed:results.reduce((s,r)=>s+r.checks,0),failed:0,acceptance_steps:35,results,original_journey_sha256:actualHash,assets_manifest:'PHASE_7_ASSETS.json',limitations:['Chunk-based fog and schematic icons','Bounded synchronous terrain loading during travel','Five fixed camp layouts; abstract offscreen missions','Tents use abstract shelter occupancy; houses have visible interiors']};
fs.writeFileSync('relic_vale/docs/PHASE_7_TEST_RESULTS.json',JSON.stringify(value,null,2)+'\n');
console.log(JSON.stringify({passed:value.passed,failed:0,acceptance_steps:35,original_journey_unchanged:true}));
