import fs from 'node:fs';
const packs=[['nature','https://quaternius.itch.io/stylized-nature-megakit'],['props','https://quaternius.itch.io/fantasy-props-megakit'],['village','https://quaternius.itch.io/medieval-village-megakit'],['monsters','https://quaternius.itch.io/lowpoly-animated-monsters'],['adventurers','https://kaylousberg.itch.io/kaykit-adventurers']];
await Promise.all(packs.map(async ([name,url])=>{
 try {
  const page=await fetch(url);const html=await page.text();
  fs.writeFileSync('downloads/phase4-itch-'+name+'.html',html);
  const csrf=html.match(/name="csrf_token" value="([^"]+)"/)?.[1];
  if(!csrf) throw Error('No free-download form');
  const r=await fetch(url+'/download_url',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({csrf_token:csrf})});
  const result=await r.json();
  if(!result.url) throw Error(JSON.stringify(result));
  const downloadHtml=await (await fetch(result.url)).text();
  fs.writeFileSync('downloads/phase4-download-'+name+'.html',downloadHtml);
  const uploadLines=[...downloadHtml.matchAll(/data-upload_id="(\d+)"[\s\S]{0,700}/g)].map(m=>m[0].replace(/<[^>]*>/g,' ').slice(0,350));
  const metadata={url,downloadPage:result.url,uploads:uploadLines};
  fs.writeFileSync('downloads/phase4-index-'+name+'.json',JSON.stringify(metadata,null,2));
  console.log(name,uploadLines);
 } catch(e){console.log(name,e.message);}
}));
