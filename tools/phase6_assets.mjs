import fs from 'node:fs';
import crypto from 'node:crypto';
fs.mkdirSync('relic_vale/assets/3d/phase6/animals',{recursive:true});
await Promise.all(['props','animations'].map(async name=>{
 const url='https://quaternius.itch.io/'+(name==='props'?'fantasy-props-megakit':'universal-animation-library-2');
 try {
 const html=await(await fetch(url)).text();
 const csrf=html.match(/name="csrf_token" value="([^"]+)"/)?.[1];
 const index=await(await fetch(url+'/download_url',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({csrf_token:csrf})})).json();
 const page=await(await fetch(index.url)).text();
 fs.writeFileSync('downloads/phase6-'+name+'-index.html',page);
 const upload=page.match(/data-upload_id="(\d+)"/)[1];
 const token=page.match(/name="csrf_token" value="([^"]+)"/)[1];
 const link=await(await fetch(url+'/file/'+upload,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({csrf_token:token})})).json();
 const bytes=Buffer.from(await(await fetch(link.url)).arrayBuffer());
 if(bytes.readUInt16LE(0)!==0x4b50) throw Error('Not ZIP');
 fs.writeFileSync('downloads/phase6-'+name+'.zip',bytes);
 const record={source:url,upload,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),license:'CC0 1.0'};
 fs.writeFileSync('downloads/phase6-'+name+'-download.json',JSON.stringify(record,null,2)); console.log(name,record);
 } catch(e){console.log(name,e.message);}
}));
const animals=JSON.parse(fs.readFileSync('downloads/phase4-animals-index.json'));
for(const kind of ['Cow','Fox','Horse','Alpaca']){
 const entry=animals.find(e=>e.name===kind+'.gltf Binary');
 const bytes=Buffer.from(await(await fetch('https://drive.usercontent.google.com/download?id='+entry.id+'&export=download')).arrayBuffer());
 JSON.parse(bytes.toString());
 fs.writeFileSync('relic_vale/assets/3d/phase6/animals/'+kind+'.gltf',bytes);
 console.log(kind,bytes.length);
}
