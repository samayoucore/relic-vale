import fs from 'node:fs';
import crypto from 'node:crypto';
const wanted={cutefish:/^(FishingRod_Lvl[123]|Lure_[123]|Worm|Goldfish|BlueGoldfish|Koi|Tetra|ArmoredCatfish|Sunfish|Piranha|Betta|Anglerfish|RedSnapper|Turbot|Flatfish|Tuna|CardinalFish|CoralGrouper|FlowerHorn|Puffer|MandarinFish|BlueTang|RoyalGramma)\.fbx$/,ultimatecrops:/^(Apple|Beet|BushBerries|Carrot|Corn|Flower|Flowers|Wheat|Tomato|Potato|Pumpkin)_(1|2|3|4|Crop)\.fbx$/,ultimatefood:/^(Bread|Fish|ChickenLeg|CookingPot_Soup|CookingPot|FryingPan|Bottle1|Carrot|Egg_Fried|Apple|Croissant|Cheese_Singles)\.fbx$/};
const receipt=[];
for(const pack of Object.keys(wanted)){
 let entries=JSON.parse(fs.readFileSync(`downloads/phase8-${pack}-fbx.json`));
 if(pack==='ultimatecrops'){
  const folder=JSON.parse(fs.readFileSync(`downloads/phase8-${pack}-index.json`)).find(e=>e.name.startsWith('FBX '));
  const html=await(await fetch('https://drive.google.com/drive/folders/'+folder.id+'?sort=13&direction=d')).text();
  fs.writeFileSync('downloads/phase8-crops-reverse.html',html);
  const additional=[...html.matchAll(/data-id="([^"]+)"[\s\S]*?data-tooltip="([^"]+)"/g)].map(x=>({id:x[1],name:x[2].replace(/ Binary.*/, '')}));
  for(const e of additional)if(!entries.some(a=>a.id===e.id))entries.push(e);
  fs.writeFileSync(`downloads/phase8-${pack}-fbx.json`,JSON.stringify(entries,null,2));
 }
 const dir=`relic_vale/assets/3d/phase8/${pack}`; fs.mkdirSync(dir,{recursive:true});
 const selected=entries.filter(e=>wanted[pack].test(e.name));
 for(let i=0;i<selected.length;i+=4){
  await Promise.all(selected.slice(i,i+4).map(async e=>{
   const dest=dir+'/'+e.name;
   let b;
   if(fs.existsSync(dest)) b=fs.readFileSync(dest);
   else{
    const url='https://drive.usercontent.google.com/download?id='+e.id+'&export=download';
    const r=await fetch(url); b=Buffer.from(await r.arrayBuffer());
    if(!b.toString('utf8',0,25).includes('Kaydara FBX Binary'))throw Error('Invalid FBX '+e.name+' '+r.status);
    fs.writeFileSync(dest,b);
   }
   receipt.push({pack,name:e.name,source:'https://quaternius.com/packs/'+pack+'.html',fileId:e.id,bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex')});
  }));
 }
 const license=JSON.parse(fs.readFileSync(`downloads/phase8-${pack}-index.json`)).find(e=>e.name.startsWith('License'));
 const text=await(await fetch('https://drive.usercontent.google.com/download?id='+license.id+'&export=download')).text();
 fs.writeFileSync(dir+'/LICENSE.txt',text);
 console.log(pack,selected.length,selected.map(e=>e.name).join(', '));
}
fs.writeFileSync('downloads/phase8-assets-receipt.json',JSON.stringify(receipt,null,2));
