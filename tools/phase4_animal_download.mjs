import fs from 'node:fs';
const folder='https://drive.google.com/drive/folders/1yJXdB1iSrI8Db7hG77zxZ66vKsqIt0ry';
const h=await (await fetch(folder)).text();
fs.writeFileSync('downloads/phase4-animals-gltf.html',h);
const entries=[...h.matchAll(/data-id="([^"]+)"[\s\S]*?data-tooltip="([^"]+)"/g)].map(x=>({id:x[1],name:x[2]}));
console.log(entries);
fs.writeFileSync('downloads/phase4-animals-index.json',JSON.stringify(entries,null,2));
