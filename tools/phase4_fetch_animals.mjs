import fs from 'node:fs';
import crypto from 'node:crypto';
fs.mkdirSync('relic_vale/assets/3d/phase4/animals',{recursive:true});
for(const e of JSON.parse(fs.readFileSync('downloads/phase4-animals-index.json'))){
 if(!/^(Wolf|Deer|Stag)\.gltf/.test(e.name))continue;
 const url='https://drive.usercontent.google.com/download?id='+e.id+'&export=download';
 const r=await fetch(url), b=Buffer.from(await r.arrayBuffer());
 const filename=e.name.split(' ')[0];
 if(b[0]!==123 && b.toString('utf8',0,4)!=='glTF')throw Error('Not glTF '+r.status+' '+b.toString('utf8',0,100));
 fs.writeFileSync('relic_vale/assets/3d/phase4/animals/'+filename,b);
 console.log(filename,b.length,crypto.createHash('sha256').update(b).digest('hex'));
}
