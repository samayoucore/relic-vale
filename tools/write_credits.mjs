import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root='relic_vale';
const lpc=JSON.parse(fs.readFileSync(root+'/assets/2d/lpc/sources.json'));
const credits=JSON.parse(fs.readFileSync(root+'/docs/licenses/LPC_SELECTED_CREDITS.json'));
const natureUrl=fs.readFileSync('downloads/kenney.html','utf8').match(/https[^'" ]+kenney_nature-kit\.zip/)[0];
const lines=[
'# Asset credits and provenance','',
'All packs were obtained from the requested creators or their official repositories on 2026-09-07. Only freely available content is included. No paid tiers, account-only content, or assets from a copyrighted commercial game are used.','',
'## 3D environment','',
'| Pack | Creator and official source | License | Included location and use |',
'| --- | --- | --- | --- |',
'| Nature Kit | Kenney — https://kenney.nl/assets/nature-kit | CC0 1.0 | `assets/3d/nature/`: trees, rocks, shrubs, flowers, mushrooms, grass; a few additional scenery pieces are retained for editing. |',
'| Medieval Builder Pack 1.0 | Kay Lousberg — https://kaylousberg.itch.io/kaykit-medieval-builder-pack | CC0 1.0 | `assets/3d/medieval/`: houses, watermill, lumbermill, market, well, farm plot; mine/watchtower retained for editing. |',
'| Dungeon Remastered / Dungeon Pack | Kay Lousberg — https://kaylousberg.itch.io/kaykit-dungeon-pack and https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0 | CC0 1.0 | `assets/3d/dungeon/`: chest, barrels, crates, columns, torches, stairs, and other small dungeon pieces. |','',
'The original pack license files are kept beside the models. CC0 does not require attribution; the authors are credited here as a courtesy. The Medieval Builder pack is the exact requested legacy pack, downloaded through its free itch.io flow. Dungeon models came from the creator’s official free repository.','',
'Models remain GLB. No format conversion or external textures are required. Runtime modifications normalize model bounds, adjust placement and scale, set nonmetallic matte materials, and harmonize selected nature/building colors. Terrain, paths, pond, dock, arch, some walls, fences, pennants, crystals, water shader, and particles were authored in GDScript/shaders for this project.','',
'## LPC characters — attribution required','',
'Source: [Universal LPC Spritesheet Character Generator](https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/), maintained at https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator.','',
'Six source layers are included for the male player and keeper. Each has idle (2 frames), walk (9 frames), and slash (6 frames), in north/west/south/east rows. The six assets are offered under multiple licenses by upstream; this project uses the **CC BY-SA 3.0** option common to all six.','',
'License: https://creativecommons.org/licenses/by-sa/3.0/ — full legal text is included in `docs/licenses/CC-BY-SA-3.0.txt`. Keep attribution, indicate changes, and preserve this license for distributed adapted LPC sprite artwork. This asset license is recorded separately from the game code and other packs.','',
'Original PNG layers are unmodified under `assets/2d/lpc/`. `scripts/pixel_art.gd` composites them at runtime, recolors shoes, trousers, shirt and hair, and adds an original small traveling cloak to the player. The resulting character artwork is an adaptation of the credited LPC assets and is provided under CC BY-SA 3.0. The keeper reuses the same source layers with different shirt/hair colors.','',
'### Included layers and their original credits',''
];
for(const record of lpc){
 lines.push('#### '+record.index+': '+record.definition.name, '', 'Source directory: `spritesheets/'+record.part+'`', '');
 const matches=record.definition.credits.filter(c=>record.part.startsWith(c.file));
 for(const c of matches){
  lines.push('Authors: '+c.authors.join('; ')+'.','');
  if(c.notes) lines.push('Upstream notes: '+c.notes+'.','');
  lines.push('Original source pages:','',...c.urls.map(u=>'- '+u),'');
 }
}
lines.push('The exact upstream sheet definitions and the selected machine-readable credit records are preserved in `docs/licenses/lpc-*.json` and `docs/licenses/LPC_SELECTED_CREDITS.json`. Per-file SHA-256 hashes and the source tree identifiers are recorded in `docs/ASSET_MANIFEST.json`.','','## Original art, fonts, and runtime','',
'- Mossling sprites, sword arc, soft contact-shadow texture, terrain geometry, and UI layout are original project-authored code/art. The mossling is the explicitly allowed compatible placeholder approach; it is not taken from another game.',
'- UI typography uses Windows system fonts (Segoe UI and Georgia, with fallbacks). No font files are copied or redistributed.',
'- Godot Engine 4.7.2 standard Windows x64 was downloaded from the official release: https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable, linked by https://godotengine.org/download/windows/. Godot is MIT-licensed; see `docs/licenses/GODOT-LICENSE.txt` and https://godotengine.org/license/. The downloaded archive was verified against the official SHA512-SUMS.txt.',
'- No audio assets are included.','','## Download status / manual steps','',
'**No manual asset downloads or finishing steps remain.** The LPC character generation is automated by the local compositor, and all requested environment packs are integrated.','',
'If you need to restore a damaged asset folder, the original environment ZIP archives remain in `../downloads/`; the hashes below identify the downloaded files. Copy the selected GLBs from their matching source folder, keeping the pack license. All selected files are listed in `ASSET_MANIFEST.json`.','',
'| Original archive | Source / source folder | SHA-256 |','| --- | --- | --- |'
);
const hash=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
for(const [file,url] of [['kenney_nature-kit.zip',natureUrl],['kaykit-medieval.zip','https://kaylousberg.itch.io/kaykit-medieval-builder-pack — Models/objects/gltf'],['Godot_v4.7.2-stable_win64.exe.zip','https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable']]) lines.push('| '+file+' | '+url+' | `'+hash('downloads/'+file)+'` |');
fs.writeFileSync(root+'/docs/ASSET_CREDITS.md',lines.join('\n')+'\n');
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);}
const manifest={retrieved:'2026-09-07',nature_archive:natureUrl,medieval_page:'https://kaylousberg.itch.io/kaykit-medieval-builder-pack',dungeon_tree_sha:JSON.parse(fs.readFileSync('downloads/dungeon-tree.json')).sha,lpc_tree_sha:JSON.parse(fs.readFileSync('downloads/lpc-tree.json')).sha,files:walk(root+'/assets').filter(f=>/\.(glb|png|json|txt)$/i.test(f)).map(f=>({path:f.slice(root.length+1).replaceAll('\\','/'),sha256:hash(f)}))};
fs.writeFileSync(root+'/docs/ASSET_MANIFEST.json',JSON.stringify(manifest,null,2)+'\n');
const response=await fetch('https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt');
if(!response.ok) throw Error('Godot license download: '+response.status);
fs.writeFileSync(root+'/docs/licenses/GODOT-LICENSE.txt',await response.text());
console.log('Credits, asset manifest, and Godot license written.');
