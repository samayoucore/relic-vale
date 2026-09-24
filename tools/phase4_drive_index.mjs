import fs from 'node:fs';
for(const name of ['rpgcharacters','ultimateanimatedanimals','animatedmonster']){
 const s=fs.readFileSync('downloads/phase4-source-'+name+'.html','utf8');
 const u=s.match(/https:\/\/drive.google.com\/drive\/folders\/[^'?]+/)[0];
 const h=await (await fetch(u)).text();
 fs.writeFileSync('downloads/phase4-drive-'+name+'.html',h);
 console.log(name,h.length,[...h.matchAll(/.{0,95}\.zip.{0,100}/g)].map(x=>x[0]).slice(0,20));
}
