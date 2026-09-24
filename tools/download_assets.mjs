import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const dirs=['assets/3d/nature','assets/3d/medieval','assets/3d/dungeon','assets/2d/lpc','assets/ui','scenes/world','scenes/characters','scenes/ui','scripts','data','docs/licenses','docs/screenshots','shaders','tests'];
for(const dir of dirs) fs.mkdirSync('relic_vale/'+dir,{recursive:true});
async function download(url,file) {
 const response=await fetch(url);
 if(!response.ok) throw Error(`${response.status}: ${url}`);
 const data=Buffer.from(await response.arrayBuffer());
 fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,data);
 console.log(path.basename(file),data.length,crypto.createHash('sha256').update(data).digest('hex'));
}
const rel=JSON.parse(fs.readFileSync('downloads/godot-4-release.json'));
const exe=rel.assets.find(a=>a.name.endsWith('win64.exe.zip'));
const kenney=fs.readFileSync('downloads/kenney.html','utf8').match(/https[^'" ]+kenney_nature-kit\.zip/)[0];
await Promise.all([
 download(exe.browser_download_url,'downloads/'+exe.name),
 download(rel.assets.find(a=>a.name==='SHA512-SUMS.txt').browser_download_url,'downloads/SHA512-SUMS.txt'),
 download(kenney,'downloads/kenney_nature-kit.zip'),
 download('https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/master/CREDITS.csv','downloads/lpc-CREDITS.csv'),
 download('https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/master/LICENSE','downloads/lpc-LICENSE')
]);
const dt=JSON.parse(fs.readFileSync('downloads/dungeon-tree.json'));
const pick=['chest.glb','chest_gold.glb','barrel_large.gltf.glb','box_large.gltf.glb','torch_mounted.gltf.glb','pillar_decorated.gltf.glb','wall_doorway.gltf.glb','wall.gltf.glb','floor_tile_large.gltf.glb','banner_blue.gltf.glb','stairs.gltf.glb'];
const chosen=dt.tree.filter(x=>x.type==='blob'&&pick.includes(path.basename(x.path)));
chosen.push(...dt.tree.filter(x=>x.type==='blob'&&/Assets\/gltf\/.*\.png$/.test(x.path)));
chosen.push(dt.tree.find(x=>x.path==='LICENSE.txt'));
await Promise.all(chosen.map(x=>download('https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0/main/'+x.path,'relic_vale/assets/3d/dungeon/'+path.basename(x.path))));
// itch.io's free download endpoint. No purchase or account is involved.
try {
 const html=fs.readFileSync('downloads/medieval.html','utf8');
 const csrf=html.match(/name="csrf_token" value="([^"]+)"/)[1];
 const r=await fetch('https://kaylousberg.itch.io/kaykit-medieval-builder-pack/download_url',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({csrf_token:csrf})});
 const t=await r.text();fs.writeFileSync('downloads/medieval-download.json',t);console.log('Medieval endpoint:',r.status,t.slice(0,350));
} catch(error) {console.log('Medieval endpoint:',error.message);}
