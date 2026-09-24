import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root='relic_vale/assets/3d/phase8';
const files=fs.readdirSync(root,{recursive:true}).filter(f=>f.endsWith('.glb')&&!f.startsWith('tools'));
const report=[];
for(const file of files){
 const filename=path.join(root,file), b=fs.readFileSync(filename), n=b.readUInt32LE(12), j=JSON.parse(b.subarray(20,20+n));
 // Legacy Quaternius FBX transparency was inverted by Blender's importer.
 // These are solid-color, opaque meshes; preserve RGB and repair only the alpha conversion.
 for(const material of j.materials||[]){
  const color=material.pbrMetallicRoughness?.baseColorFactor;
  if(color)color[3]=1;
  material.alphaMode='OPAQUE'; delete material.alphaCutoff;
 }
 const encoded=Buffer.from(JSON.stringify(j)), padded=Buffer.alloc(Math.ceil(encoded.length/4)*4,32);encoded.copy(padded);
 const header=Buffer.alloc(20); b.copy(header,0,0,12);header.writeUInt32LE(20+padded.length+b.length-20-n,8);header.writeUInt32LE(padded.length,12);header.write('JSON',16);
 const result=Buffer.concat([header,padded,b.subarray(20+n)]);fs.writeFileSync(filename,result);
 report.push({file:filename,sha256:crypto.createHash('sha256').update(result).digest('hex')});
}
fs.writeFileSync('downloads/phase8-runtime-assets.json',JSON.stringify(report,null,2));console.log('Opaque glTF materials repaired:',report.length);
