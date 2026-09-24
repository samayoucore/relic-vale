import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const groups={nature:{creator:'Quaternius',name:'Stylized Nature MegaKit — Standard',source:'https://quaternius.com/packs/stylizednaturemegakit.html',purpose:'Geometric grass, ferns, clover, flowers, mushrooms, pebbles and compatible undergrowth'},monsters:{creator:'Quaternius',name:'LowPoly Animated Monsters',source:'https://quaternius.itch.io/lowpoly-animated-monsters',purpose:'Rigged and animated slime, skeleton and bat enemy presentation'},animals:{creator:'Quaternius',name:'Ultimate Animated Animals',source:'https://quaternius.com/packs/ultimateanimatedanimals.html',purpose:'Animated wolf enemies, deer and stag wildlife'},adventurers:{creator:'Kay Lousberg',name:'KayKit Adventurers 2.0 Free',source:'https://kaylousberg.itch.io/kaykit-adventurers',purpose:'Mage and knight skins with General and MovementBasic animation libraries'}};
const manifest=[];
for(const [folder,g] of Object.entries(groups)){
 for(const file of fs.readdirSync('relic_vale/assets/3d/phase4/'+folder)){
  if(file.endsWith('.import'))continue;
  const rel='assets/3d/phase4/'+folder+'/'+file,b=fs.readFileSync('relic_vale/'+rel);
  manifest.push({file:rel,...g,license:'CC0 1.0',bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex')});
 }
}
fs.writeFileSync('relic_vale/docs/PHASE_4_ASSET_MANIFEST.json',JSON.stringify(manifest,null,2));
const credit='relic_vale/docs/ASSET_CREDITS.md';
let s=fs.readFileSync(credit,'utf8');
if(s.includes('## Phase 4 assets'))s=s.slice(0,s.indexOf('## Phase 4 assets'));
s+='\n## Phase 4 assets\n\nOnly selected models and referenced textures are imported. Full downloaded archives stay outside the Godot project, in `downloads/`. Exact file hashes and purposes are in `PHASE_4_ASSET_MANIFEST.json`.\n\n';
for(const g of Object.values(groups))s+=`- **${g.name}**, ${g.creator}. [Official source](${g.source}). CC0 1.0. ${g.purpose}.\n`;
s+='\nKenney Nature Kit `log.glb` was additionally selected from the previously credited CC0 archive. The handcrafted village keeps its established Kenney/KayKit assets and palette. Quaternius village/props paid or full packs were not imported; compatibility with the existing village family takes priority. Master terrain, wind shader, river/bank meshes and continuous ridge mesh are original project code. Existing LPC character licenses remain unchanged.\n';
fs.writeFileSync(credit,s);
console.log(manifest.length+' selected source files documented');
