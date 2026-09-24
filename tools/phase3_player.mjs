import fs from 'node:fs';
const path='relic_vale/scripts/player.gd';let s=fs.readFileSync(path,'utf8');
s=s.replace(/func attack\(\) -> void:[\s\S]*?(?=func take_damage)/,'func attack() -> void:\n\tcombat.start()\n\n');
fs.writeFileSync(path,s);
