import fs from 'node:fs';
const read=p=>{const b=fs.readFileSync(p); return JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString())};
const out={};
for(const file of fs.readdirSync('relic_vale/assets/3d/phase9/animations').filter(x=>x.endsWith('.glb'))) {
 const data=read('relic_vale/assets/3d/phase9/animations/'+file);
 out[file]={clips:data.animations.map(a=>a.name),bones:data.skins?.[0].joints.map(i=>data.nodes[i].name)};
}
out.character=read('relic_vale/assets/3d/phase4/adventurers/Knight.glb').nodes.map(n=>n.name);
fs.writeFileSync('downloads/phase9-animation-audit.json',JSON.stringify(out,null,2)); console.log(JSON.stringify(out,null,2));
