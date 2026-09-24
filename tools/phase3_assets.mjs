import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const out='relic_vale/assets/audio'; fs.mkdirSync(out,{recursive:true});
function files(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path.join(dir,e.name)):[path.join(dir,e.name)]);}
const all=files('downloads/kenney-rpg-audio');
for(const name of ['footstep00.ogg','footstep01.ogg','knifeSlice.ogg','knifeSlice2.ogg','chop.ogg','drawKnife1.ogg','cloth1.ogg','handleCoins.ogg','metalClick.ogg','creak1.ogg','bookOpen.ogg','License.txt']){
 const source=all.find(p=>path.basename(p)===name); if(!source)throw Error(name);fs.copyFileSync(source,path.join(out,name==='License.txt'?'KENNEY-LICENSE.txt':name));
}
function wav(name,seconds,sample){
 const rate=22050,n=Math.floor(seconds*rate),data=Buffer.alloc(44+n*2);data.write('RIFF');data.writeUInt32LE(36+n*2,4);data.write('WAVEfmt ',8);data.writeUInt32LE(16,16);data.writeUInt16LE(1,20);data.writeUInt16LE(1,22);data.writeUInt32LE(rate,24);data.writeUInt32LE(rate*2,28);data.writeUInt16LE(2,32);data.writeUInt16LE(16,34);data.write('data',36);data.writeUInt32LE(n*2,40);
 let peak=0;for(let i=0;i<n;i++){const t=i/rate,v=Math.max(-.92,Math.min(.92,sample(t,i,seconds)));peak=Math.max(peak,Math.abs(v));data.writeInt16LE(Math.round(v*32767),44+i*2);}fs.writeFileSync(path.join(out,name+'.wav'),data);console.log(name,n,peak.toFixed(3));
}
const sin=(f,t)=>Math.sin(Math.PI*2*f*t);const env=(t,d)=>Math.min(1,t/.012)*Math.max(0,1-t/d)**2;
let noiseSeed=381;const noise=()=>{noiseSeed=(Math.imul(noiseSeed,1664525)+1013904223)>>>0;return noiseSeed/2147483648-1;};
wav('spell',.45,(t,i,d)=>(sin(360+900*t,t)*.3+noise()*.10)*env(t,d));
wav('bow',.18,(t,i,d)=>(sin(150-500*t,t)*.45+noise()*.22)*env(t,d));
wav('critical',.32,(t,i,d)=>(sin(830,t)+sin(1245,t)*.6)*.3*env(t,d));
wav('heal',.7,(t,i,d)=>(sin(523,t)+sin(659,t)+sin(784,t))*.16*env(t,d));
wav('level',1.05,(t,i,d)=>sin([392,494,587,784][Math.min(3,Math.floor(t/.23))],t)*.42*env(t,d));
wav('shrine',1.5,(t,i,d)=>(sin(261.63,t)+sin(392,t)+sin(523.25,t))*Math.sin(Math.PI*t/d)*.13);
wav('hurt',.22,(t,i,d)=>(sin(135-160*t,t)*.38+noise()*.15)*env(t,d));
wav('death',.35,(t,i,d)=>(sin(180-250*t,t)*.32+noise()*.10)*env(t,d));
wav('slam',.65,(t,i,d)=>(sin(55+35*Math.exp(-t*8),t)*.5+noise()*.28)*env(t,d));
for(const [name,notes] of [['vale_music',[146.83,196,220,293.66]],['crypt_music',[98,116.54,146.83,196]],['boss_music',[73.42,110,146.83,174.61]]]){
 wav(name,16,(t)=>{const fade=Math.min(1,t/.15,(16-t)/.15);let v=0;for(let j=0;j<notes.length;j++)v+=sin(notes[j],t)*.027*(.7+.3*sin(.125,t+j));const beat=t%2;v+=sin(notes[Math.floor(t/2)%4]*2,t)*Math.exp(-beat*2)*.055;if(name==='boss_music')v+=sin(65,t)*Math.exp(-(t%.5)*24)*.10;return v*fade;});
}
const zip=fs.readFileSync('downloads/kenney_rpg-audio.zip');
fs.writeFileSync('relic_vale/docs/PHASE_3_AUDIO_MANIFEST.json',JSON.stringify({source:'https://kenney.nl/assets/rpg-audio',archive:'https://kenney.nl/media/pages/assets/rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip',license:'CC0 1.0',sha256:crypto.createHash('sha256').update(zip).digest('hex'),files:fs.readdirSync(out),generated:'Original synthesized WAV cues and three ambient musical loops; source tools/phase3_assets.mjs'},null,2));
