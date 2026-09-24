import fs from 'node:fs';
for(const pack of ['cutefish','ultimatecrops','ultimatefood']){
 const root=JSON.parse(fs.readFileSync(`downloads/phase8-${pack}-index.json`));
 const folder=root.find(e=>e.name.startsWith('FBX '));
 const html=await(await fetch('https://drive.google.com/drive/folders/'+folder.id)).text();
 fs.writeFileSync(`downloads/phase8-${pack}-fbx.html`,html);
 const entries=[...html.matchAll(/data-id="([^"]+)"[\s\S]*?data-tooltip="([^"]+)"/g)].map(x=>({id:x[1],name:x[2].replace(/ Shared.*| Binary.*| Compressed.*| Text.*| Image.*/, '')})).filter(e=>e.id!=='_gd');
 fs.writeFileSync(`downloads/phase8-${pack}-fbx.json`,JSON.stringify(entries,null,2));
 console.log(pack,entries);
}
