import fs from 'node:fs';
const base='https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/master/';
for(const p of ['sheet_definitions/body/body.json','sheet_definitions/legs/pants/legs_pants.json','sheet_definitions/torso/shirts/torso_clothes_tunic.json','sheet_definitions/hair/short/hair_plain.json']){
 const r=await fetch(base+p);const t=await r.text();console.log(p,r.status,t.slice(0,4000));fs.writeFileSync('downloads/'+p.split('/').at(-1),t);
}
// Request and consume the short-lived free download URL in one session.
const url='https://kaylousberg.itch.io/kaykit-medieval-builder-pack';
const resp=await fetch(url);const cookie=resp.headers.getSetCookie().map(c=>c.split(';')[0]).join('; ');const html=await resp.text();
const csrf=html.match(/name="csrf_token" value="([^"]+)"/)[1];
const reply=await fetch(url+'/download_url',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','Cookie':cookie,'Referer':url},body:new URLSearchParams({csrf_token:csrf})});
const d=await reply.json();const page=await fetch(d.url,{headers:{Cookie:cookie}});const t=await page.text();fs.writeFileSync('downloads/medieval-files.html',t);
const download=await fetch(url+'/file/4289072',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded',Cookie:cookie,Referer:d.url},body:new URLSearchParams({csrf_token:t.match(/name="csrf_token" value="([^"]+)"/)[1]})});
const file=await download.json();console.log('itch file',download.status,Object.keys(file));
if(file.url){const zip=await fetch(file.url);fs.writeFileSync('downloads/kaykit-medieval.zip',Buffer.from(await zip.arrayBuffer()));console.log('medieval downloaded');}
for(const p of ['sheet_definitions/head/heads/human/heads_human_male.json','sheet_definitions/feet/shoes/feet_shoes_basic.json','sheet_definitions/torso/shirts/longsleeve/torso_clothes_longsleeve.json']) {
 const r=await fetch(base+p);const t=await r.text();fs.writeFileSync('downloads/'+p.split('/').at(-1),t);console.log(p,t.slice(0,650));
}
