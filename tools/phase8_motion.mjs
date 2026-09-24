import fs from 'node:fs';
const b=fs.readFileSync('downloads/UAL2_Standard.glb');
const jsonLength=b.readUInt32LE(12), j=JSON.parse(b.subarray(20,20+jsonLength));
const bin=b.subarray(28+jsonLength);
function values(index){const a=j.accessors[index],v=j.bufferViews[a.bufferView],n={SCALAR:1,VEC3:3,VEC4:4}[a.type];return Array.from({length:a.count},(_,i)=>Array.from({length:n},(_,k)=>bin.readFloatLE((v.byteOffset||0)+(a.byteOffset||0)+i*(v.byteStride||n*4)+k*4)));}
const result={source:'Quaternius Universal Animation Library 2 Standard (CC0)',adapter:'Normalized right upper-arm pitch sampled from authored clips drives the tool arc beside the existing LPC sprite.',clips:{}};
for(const anim of j.animations.filter(a=>/^(Farm_Harvest|Farm_PlantSeed|Farm_Watering|OverhandThrow)$/.test(a.name))){
 const channel=anim.channels.find(c=>c.target.node===48&&c.target.path==='rotation');
 const sampler=anim.samplers[channel.sampler], times=values(sampler.input).flat(), rotations=values(sampler.output);
 const angles=rotations.map(([x,y,z,w])=>Math.atan2(2*(w*x+y*z),1-2*(x*x+y*y)));
 // Unwrap the rotation across pi to preserve the artist's arc.
 for(let i=1;i<angles.length;i++){while(angles[i]-angles[i-1]>Math.PI)angles[i]-=Math.PI*2;while(angles[i]-angles[i-1]<-Math.PI)angles[i]+=Math.PI*2;}
 const baseline=angles[0],range=Math.max(.1,Math.max(...angles)-Math.min(...angles));
 result.clips[anim.name]={duration:times.at(-1),samples:times.map((t,i)=>[t/times.at(-1),Math.max(-1.1,Math.min(1.1,(angles[i]-baseline)/range*.9))])};
}
fs.writeFileSync('relic_vale/data/profession_motion.json',JSON.stringify(result));
console.log(Object.fromEntries(Object.entries(result.clips).map(([n,v])=>[n,v.samples.length])));
