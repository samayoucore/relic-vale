import fs from 'node:fs';
const r=JSON.parse(fs.readFileSync('downloads/godot-4-release.json'));
console.log('GODOT',r.assets.filter(a=>/win64.exe.zip|SHA512/.test(a.name)).map(a=>[a.name,a.browser_download_url]));
for(const [file,pattern] of [['dungeon-tree.json',/gltf|LICENSE|\.png$/],['lpc-tree.json',/^(spritesheets\/body\/|spritesheets\/torso\/clothes\/|spritesheets\/legs\/|spritesheets\/hair\/|LICENSE|CREDITS|sheet_definitions\/body)/]]) {
const d=JSON.parse(fs.readFileSync('downloads/'+file));
console.log(file,d.tree.filter(x=>pattern.test(x.path)).map(x=>x.path).slice(0,130));
}
