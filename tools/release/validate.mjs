import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const project=path.join(root,'relic_vale');
const failures=[];let checks=0;
function check(ok,message){checks++;if(!ok)failures.push(message);}
const read=p=>fs.readFileSync(path.join(project,p),'utf8');
const required=['project.godot','export_presets.cfg','scenes/Main.tscn','scenes/world/World.tscn','scenes/characters/Player.tscn','assets/ui/relic_vale.ico','assets/ui/relic_vale_icon.svg','THIRD_PARTY_LICENSES.txt'];
for(const p of required)check(fs.existsSync(path.join(project,p)),`Missing ${p}`);
const config=read('project.godot');
check(/config\/version="\d+\.\d+\.\d+"/.test(config),'Missing semantic version');
check(!config.includes('ReleaseQA='),'QA autoload must never ship');
check(config.includes('renderer/rendering_method="gl_compatibility"'),'Renderer unexpectedly changed');
check(read('export_presets.cfg').includes('tests/*,docs/*'),'Tests and developer docs must be excluded');
const walk=p=>fs.readdirSync(p,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(p,e.name)):[path.join(p,e.name)]);
for(const file of walk(path.join(project,'scripts'))){
  if(!file.endsWith('.gd'))continue;
  const text=fs.readFileSync(file,'utf8');
  check(!/-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----|sk-[A-Za-z0-9]{30,}|ghp_[A-Za-z0-9]{30,}/.test(text),`Credential pattern in ${file}`);
  check(!/[A-Z]:[\\/](?:Users|Program Files)[\\/]/.test(text),`Build-machine path in ${file}`);
  for(const m of text.matchAll(/(?:preload|load)\("(res:\/\/[^"\n]+)"\)/g)){
    if(m[1].includes('+'))continue;
    check(fs.existsSync(path.join(project,m[1].slice(6))),`Missing literal resource ${m[1]}`);
  }
}
const main=read('scripts/main.gd');
for(const key of ['F3','F4','F7','F8','F10'])check(new RegExp(`OS.is_debug_build\\(\\).*KEY_${key}\\b`).test(main),`Unguarded developer key ${key}`);
check(main.includes('if not OS.is_debug_build(): return'),'Developer argument dispatcher is unguarded');
const report={checks,failed:failures.length,failures,time:new Date().toISOString()};
fs.writeFileSync(path.join(project,'docs/PHASE_10_STATIC_CHECKS.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify(report));if(failures.length)process.exit(1);
