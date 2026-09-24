import fs from 'node:fs';
import crypto from 'node:crypto';
const sources=[['foley','https://opengameart.org/content/100-cc0-sfx-2','.zip'],['hoof','https://opengameart.org/content/horse-trotting','.ogg']];
for(const [id,url,ext] of sources){
 const page=await(await fetch(url)).text();
 fs.writeFileSync('downloads/phase6-audio-'+id+'.html',page);
 const links=[...page.matchAll(/href="([^"]+)"/g)].map(m=>m[1].replaceAll('&amp;','&'));
 const link=links.find(l=>l.includes('/files/')&&l.toLowerCase().endsWith(ext));
 if(!link)throw Error('No download: '+id);
 const bytes=Buffer.from(await(await fetch(new URL(link,url))).arrayBuffer());
 fs.writeFileSync('downloads/phase6-audio-'+id+ext,bytes);
 fs.writeFileSync('downloads/phase6-audio-'+id+'.json',JSON.stringify({source:url,download:link,license:'CC0 1.0',bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')},null,2));
 console.log(id,bytes.length);
}
