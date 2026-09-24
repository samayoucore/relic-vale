import fs from 'node:fs';
import crypto from 'node:crypto';
for(const name of ['nature','monsters','adventurers']){
 const index=JSON.parse(fs.readFileSync('downloads/phase4-index-'+name+'.json','utf8'));
 const html=fs.readFileSync('downloads/phase4-download-'+name+'.html','utf8');
 const upload=html.match(/data-upload_id="(\d+)"/)[1];
 const csrf=html.match(/name="csrf_token" value="([^"]+)"/)?.[1];
 const r=await fetch(index.url+'/file/'+upload,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({csrf_token:csrf})});
 const result=await r.json();
 if(!result.url) {console.log(name,r.status,JSON.stringify(result));continue;}
 const bytes=Buffer.from(await (await fetch(result.url)).arrayBuffer());
 if(bytes.readUInt16LE(0)!==0x4b50) throw Error(name+' was not a ZIP');
 fs.writeFileSync('downloads/phase4-'+name+'.zip',bytes);
 const record={pack:name,source:index.url,upload,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),license:'CC0 1.0'};
 fs.writeFileSync('downloads/phase4-'+name+'-download.json',JSON.stringify(record,null,2));
 console.log(record);
}
