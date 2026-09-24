import fs from 'node:fs';
import crypto from 'node:crypto';
const root='relic_vale/assets/ui/phase5';
fs.mkdirSync(root,{recursive:true});
const assets=[
 ['https://kenney.nl/media/pages/assets/ui-pack-rpg-expansion/7ec4a46657-1677661824/kenney_ui-pack-rpg-expansion.zip','downloads/phase5-kenney-ui.zip'],
 ['https://raw.githubusercontent.com/google/fonts/main/ofl/rubik/Rubik%5Bwght%5D.ttf',root+'/Rubik.ttf'],
 ['https://raw.githubusercontent.com/google/fonts/main/ofl/rubik/OFL.txt',root+'/Rubik-OFL.txt'],
 ['https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/PressStart2P-Regular.ttf',root+'/PressStart2P.ttf'],
 ['https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/OFL.txt',root+'/PressStart2P-OFL.txt']
];
const records=await Promise.all(assets.map(async([url,path])=>{
 const response=await fetch(url);
 if(!response.ok) throw Error(response.status+' '+url);
 const bytes=Buffer.from(await response.arrayBuffer());fs.writeFileSync(path,bytes);
 return {url,path,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
}));
fs.writeFileSync('downloads/phase5-ui-receipts.json',JSON.stringify(records,null,2));
console.log(records);
