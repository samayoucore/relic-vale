import fs from 'node:fs';
import crypto from 'node:crypto';
const records=[];
async function download(url,path){const b=Buffer.from(await(await fetch(url)).arrayBuffer());fs.mkdirSync(path.slice(0,path.lastIndexOf('/')),{recursive:true});fs.writeFileSync(path,b);records.push({path,bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex')});return b;}
const can=await download('https://static.poly.pizza/e8a92bbc-c343-47c6-bd13-b6d107795d97.glb','relic_vale/assets/3d/phase8/tools/WateringCan.glb');
if(can.toString('utf8',0,4)!=='glTF')throw Error('Invalid watering can');
fs.writeFileSync('relic_vale/assets/3d/phase8/tools/LICENSE.txt','Watering Can by Isa Lousberg. CC0 / Public Domain.\nhttps://poly.pizza/m/hybuUvYsri\nhttps://creativecommons.org/publicdomain/zero/1.0/\n');
const crops=JSON.parse(fs.readFileSync('downloads/phase8-ultimatecrops-fbx.json'));
for(const e of crops.filter(e=>/^(Bamboo|Cactus)_(1|2|3|4|Crop)\.fbx$/.test(e.name)))await download('https://drive.usercontent.google.com/download?id='+e.id+'&export=download','relic_vale/assets/3d/phase8/ultimatecrops/'+e.name);
const html=fs.readFileSync('downloads/phase8-farm.html','utf8');
const folder=html.match(/https:\/\/drive.google.com\/drive\/folders\/[^'?]+/)[0];
async function entries(url){const h=await(await fetch(url)).text();return [...h.matchAll(/data-id="([^"]+)"[\s\S]*?data-tooltip="([^"]+)"/g)].map(x=>({id:x[1],name:x[2]}));}
const root=await entries(folder); console.log('Farm root',root);
const fbx=root.find(e=>e.name.startsWith('FBX '));
if(fbx){const files=await entries('https://drive.google.com/drive/folders/'+fbx.id);fs.writeFileSync('downloads/phase8-farm-fbx.json',JSON.stringify(files,null,2));console.log(files);}
fs.writeFileSync('downloads/phase8-extra-assets-receipt.json',JSON.stringify(records,null,2));
