import fs from 'node:fs';
const names=['cutefish','ultimatecrops','ultimatefood'];
for(const name of names){
 const html=await (await fetch(`https://quaternius.com/packs/${name}.html`)).text();
 fs.writeFileSync(`downloads/phase8-source-${name}.html`,html);
 const folder=html.match(/https:\/\/drive.google.com\/drive\/folders\/[^'?]+/)?.[0];
 if(!folder) throw Error('No official folder '+name);
 const index=await(await fetch(folder)).text();
 fs.writeFileSync(`downloads/phase8-drive-${name}.html`,index);
 const entries=[...index.matchAll(/data-id="([^"]+)"[\s\S]*?data-tooltip="([^"]+)"/g)].map(x=>({id:x[1],name:x[2]}));
 fs.writeFileSync(`downloads/phase8-${name}-index.json`,JSON.stringify(entries,null,2));
 console.log(name,folder,entries);
}
