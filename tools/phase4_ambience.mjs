import fs from 'node:fs';
const dir='relic_vale/assets/audio/phase4/';fs.mkdirSync(dir,{recursive:true});
const rate=22050,seconds=8,N=rate*seconds;
for(const zone of ['wind','forest','water','night','rain','village']){
 let seed=17123,low=0;const noise=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/2147483648-1;};
 const b=Buffer.alloc(44+N*2);b.write('RIFF');b.writeUInt32LE(b.length-8,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(1,22);b.writeUInt32LE(rate,24);b.writeUInt32LE(rate*2,28);b.writeUInt16LE(2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(N*2,40);
 for(let i=0;i<N;i++){
  const t=i/rate,n=noise();low=low*.965+n*.035;let v=low*.7;
  if(zone==='rain')v=n*.18+low*.8;
  if(zone==='water')v=low*1.4+n*.06+Math.sin(t*75+Math.sin(t*4))*Math.max(0,Math.sin(t*3))*.025;
  if(zone==='forest'){const p=t%2;v=low*.3+(p<.32?Math.sin(t*(4200+800*Math.sin(p*14)))*Math.sin(p/.32*Math.PI)*.16:0);}
  if(zone==='night')v=low*.16+Math.sin(t*11000)*Math.max(0,Math.sin(t*15))*.06;
  if(zone==='village'){const beat=t%1;v=low*.25+(beat<.08?Math.sin(t*390)*Math.exp(-beat*65)*.15:0);}
  const fade=Math.min(1,t/.08,(seconds-t)/.08);b.writeInt16LE(Math.round(Math.max(-.9,Math.min(.9,v))*fade*32767),44+i*2);
 }
 fs.writeFileSync(dir+zone+'.wav',b);
 fs.writeFileSync(dir+zone+'.wav.import',`[remap]\nimporter="wav"\ntype="AudioStreamWAV"\npath="res://.godot/imported/${zone}.wav-phase4.sample"\n\n[deps]\nsource_file="res://assets/audio/phase4/${zone}.wav"\ndest_files=["res://.godot/imported/${zone}.wav-phase4.sample"]\n\n[params]\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\n`);
}
console.log('Six original looping ambient sound beds generated');
