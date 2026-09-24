import fs from 'node:fs';
const defs=['body.json','feet_shoes_basic.json','legs_pants.json','torso_clothes_longsleeve.json','heads_human_male.json','hair_plain.json'];
const records=[];
for(const [index,file] of defs.entries()) {
 const def=JSON.parse(fs.readFileSync('downloads/'+file)); const part=def.layer_1.male;
 records.push({index,part,definition:def});
 fs.copyFileSync('downloads/'+file,'relic_vale/docs/licenses/lpc-'+file);
 await Promise.all(['idle','walk','slash'].map(async(anim)=>{
  const r=await fetch('https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/master/spritesheets/'+part+anim+'.png');
  if(!r.ok) throw Error(part+anim+' '+r.status);
  const data=Buffer.from(await r.arrayBuffer());fs.writeFileSync(`relic_vale/assets/2d/lpc/${index}_${anim}.png`,data);
  console.log(index,anim,data.readUInt32BE(16),data.readUInt32BE(20));
 }));
}
fs.writeFileSync('relic_vale/assets/2d/lpc/sources.json',JSON.stringify(records,null,2));
const credits=[];
for(const row of records) for(const c of row.definition.credits) if(row.part.startsWith(c.file+'/')||row.part.startsWith(c.file)) credits.push(c);
fs.writeFileSync('relic_vale/docs/licenses/LPC_SELECTED_CREDITS.json',JSON.stringify(credits,null,2));
const license=await fetch('https://creativecommons.org/licenses/by-sa/3.0/legalcode.txt');
fs.writeFileSync('relic_vale/docs/licenses/CC-BY-SA-3.0.txt',await license.text());
