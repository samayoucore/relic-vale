import fs from 'node:fs';
import path from 'node:path';
const runtime=path.resolve('relic_vale/assets/3d/phase8');
const archive=path.resolve('downloads/phase8-original-fbx');
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);}
for(const file of walk(runtime).filter(f=>f.endsWith('.fbx'))){
 const glb=file.replace(/\.fbx$/,'.glb');
 if(!fs.existsSync(glb)||fs.readFileSync(glb).toString('utf8',0,4)!=='glTF')throw Error('Missing converted asset '+file);
 const dest=path.join(archive,path.relative(runtime,file)); fs.mkdirSync(path.dirname(dest),{recursive:true}); fs.copyFileSync(file,dest);
 if(!file.startsWith(runtime+path.sep))throw Error('Outside asset directory');
 fs.unlinkSync(file);
 if(fs.existsSync(file+'.import'))fs.unlinkSync(file+'.import');
}
for(const file of ['tools/phase8_data.mjs',...['fishing','cultivation','mounts'].map(n=>'relic_vale/scripts/professions/'+n+'.gd')]) fs.writeFileSync(file,fs.readFileSync(file,'utf8').replaceAll('.fbx','.glb'));
console.log('Converted glTF installed; source FBX retained under downloads/phase8-original-fbx.');
