import fs from 'node:fs';
const urls=[
'https://quaternius.com/packs/stylizednaturemegakit.html',
'https://quaternius.com/packs/medievalvillagemegakit.html',
'https://quaternius.com/packs/fantasypropsmegakit.html',
'https://quaternius.com/packs/animatedmonster.html',
'https://quaternius.com/packs/rpgcharacters.html',
'https://quaternius.com/packs/ultimateanimatedanimals.html',
'https://quaternius.itch.io/lowpoly-animated-monsters/purchase'];
await Promise.all(urls.map(async url=>{
 const r=await fetch(url);const html=await r.text();
 const name=url.split('/').filter(Boolean).at(-1).replace('.html','');
 fs.writeFileSync('downloads/phase4-source-'+name+'.html',html);
 const links=[...html.matchAll(/(?:href|src)=["']([^"']+)["']/g)].map(x=>x[1]).filter(x=>/zip|drive.google|dropbox|itch.io|download|source|poly.pizza/i.test(x));
 console.log(JSON.stringify({url,status:r.status,links:[...new Set(links)]}));
}));
