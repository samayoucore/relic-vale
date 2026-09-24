import fs from 'node:fs';
const root='relic_vale/';
const write=(p,s)=>fs.writeFileSync(p,s.trim()+'\n');
write('README.md',`
# Relic Vale · 0.6

Запуск: **Launch Relic Vale.bat**. Редактор: **Edit Relic Vale.bat**. Движок и все игровые ресурсы уже находятся в рабочей папке; интернет для игры не нужен.

Завершены этапы 1–6. Добавлены физическая добыча древесины, камня, руды, трав, волокна, грибов и кристаллов; настоящие модели топоров и кирок трёх уровней; торговля материалами у специалистов. В дома, магазин, кузницу, таверну и лавку алхимика можно войти. Жители ходят по расписанию, работают, общаются и отдыхают; на пастбищах и в лесу живут анимированные животные. Потоковый мир, задания, бой, подземелья и настройки предыдущих этапов сохранены.

**Добыча:** I → выбрать топор/кирку → Equip to Tool. Подойти к дереву или залежи и удерживать E. Растения собираются без инструмента. У дверей E входит/выходит; у торговца открывает разговор и магазин. Улучшенные инструменты продаёт кузнец Брам. F4 открывает средства проверки добычи, интерьеров, жителей и животных.

**Камера:** Q/R или горизонтальное движение с зажатой ПКМ — поворот; вертикальное движение ПКМ или Page Up/Down — небольшой наклон в пределах 40–60°. Колесо — приближение, Home — сброс. Закрывающие обзор деревья, крыши и другие препятствия временно скрываются и возвращаются, когда обзор свободен.

WASD — движение, Shift — бег, Ctrl — уклонение, Space/ЛКМ — удар, E — взаимодействие, 1/2 — умения, H — зелье. I — инвентарь, C — внешность, B — умения, J — задания, Tab — атлас, Esc — меню, F6/F9 — сохранить/загрузить, F3 — отладка мира, F11 — полный экран.

Сохранения: tools/godot/userdata/Godot/app_userdata/RelicValePrototype. Вместе с JSON нужно сохранять соответствующую папку .chunks. Формат 6 читает старые версии 2–5. Проверки используют отдельные файлы и не заменяют пользовательскую игру.

Подробности: [этап 6 и результаты](relic_vale/docs/PHASE_6.md), [полный игровой сценарий](relic_vale/docs/PHASE_6_ACCEPTANCE.md), [руководство](relic_vale/README.md), [лицензии ресурсов](relic_vale/docs/ASSET_CREDITS.md).
`);
write(root+'README.md',`
# Relic Vale · Phase 6

Run **Launch Relic Vale.bat** in the parent workspace. **Edit Relic Vale.bat** opens the source project. Godot 4.7.2 standard Windows and all runtime assets are bundled locally. The first launch imports assets if needed; no asset download or paid service is required.

The existing streamed world, procedural regions/dungeons, five weapon types, six abilities, affixed gear, relics, quests/factions, crafting, weather, atlas and graphics/settings are preserved. Phase 6 adds physical harvesting, visible tools, specialized resource trade, enterable buildings, household storage, indoor/outdoor resident activities and friendly farm/wild animals.

## Playing

WASD/arrows move, Shift runs, Ctrl dodges, Space/left click attacks, E interacts, H uses tonic. Abilities 1/2; B selects loadout. I opens inventory/equipment, C appearance, J journal, Tab atlas, Esc menu, F6 saves, F9 loads and F11 toggles fullscreen. F3 provides world diagnostics; F4 provides gathering, interior, resident and fauna controls.

Equip a crude axe in the Tool slot and hold E near a timber tree. Equip a pickaxe to mine stone, iron or crystals. Gather plants without a tool. Completed nodes give materials and visibly deplete. Sell wood to Tobin, ore to Bram and herbs to Liora for specialist prices. Bram's forge sells iron/steel tools. Approach a marked door and press E to enter; use the interior exit to return to the same exterior entrance. Tavern patrons arrive in the evening; residents return home at night. Household chests store items per building.

Q/R or horizontal right drag orbit the camera; vertical right drag or Page Up/Down tilts within 40–60 degrees. Wheel zooms and Home resets orbit, pitch and zoom. Blocking objects temporarily hide while preserving collision, and return when the view clears. Gathered trees stay depleted through this restoration. Interiors retain limited tilt and support orbit/zoom.

Settings → Graphics contains four quality presets plus Custom, render scale, shadows, foliage, distance, particles and water. Pixelated Render is independent of the preset. Window mode/resolution, frame cap, VSync, UI scale and audio preferences persist separately from progression.

## Saves and verification

Three journey slots provide metadata and recoverable backups. Save version 6 reads versions 2–5. Resource hit/renewal records use the existing content-addressed .chunks directory; resident identity, equipped tools, interior return and household storage persist. Copy the slot JSON and its .chunks folder together. With the launcher, saves remain under tools/godot/userdata/Godot/app_userdata/RelicValePrototype. The user's journey is never used as a test output.

See [Phase 6](docs/PHASE_6.md), [resources](docs/RESOURCE_SYSTEM.md), [interiors](docs/INTERIORS.md), [residents/fauna](docs/NPC_SIMULATION.md), [gameplay acceptance](docs/PHASE_6_ACCEPTANCE.md), [streaming architecture](docs/WORLD_STREAMING.md) and [asset credits](docs/ASSET_CREDITS.md).

Tests run inside the actual Godot scene. Set APPDATA to the bundled userdata directory and pass flags after --: --phase6-test, --phase6-acceptance followed by --phase6-acceptance-reload, --phase6-validation, --phase6-reload, --phase6-visual, --phase6-life-check. Existing --stream-test, --stress-world, --far-reload, --presentation-test and --combat-check remain available. GUI runs exercise native pointer equipment; headless tests exercise the same gameplay/state components. Test logs are in workspace downloads and screenshots in docs/screenshots.

This remains a local prototype. Humanoids retain LPC directional sprites with adapted poses and real hand props; they were not replaced with skeleton rigs. Room layouts have limited seeded variations. Wildlife is ambient, without taming/breeding. Rendering remains limited by draw calls on the tested Radeon Vega 8; graphics presets can reduce scenery detail. Audible output depends on a working host audio device; earlier sessions used the Dummy fallback. Optional tree-fall physics, durability and a farming economy were not added.
`);
write(root+'docs/NEXT_STEPS.md',`
# Completed baseline and future work

Phases 1–6 are complete in the existing project. The accepted camera tilt and obstruction hiding are included. No additional implementation prompt is pending. The Phase 6 report, exact 29-step gameplay acceptance, architecture documents and licensed-asset manifest accompany the source.

Potential future phases, requiring a new brief:

- Reduce draw calls with state-aware batching for intact resource groups and fewer material surfaces on furniture.
- Expand seeded room layouts and indoor activity pose variety while preserving the established character style.
- Add new quests that use gathering, household storage and settlement specialists.
- Consider farming, fishing, taming, tool durability or falling-tree animation only as deliberate new features.

Keep all prior archives, the user's journey and the current save migration path. Continue testing real controller movement, interiors, harvesting, NPC travel, streaming and fresh-process reload after future changes.
`);
const sources=[
 ['Core gathering / all five interiors','phase6-core-gui-final.log','PHASE6_CORE_RESULT'],
 ['Exact gameplay sequence, steps 1–27','phase6-acceptance-final.log','PHASE6_ACCEPTANCE_RESULT'],
 ['Fresh-process gameplay reload, steps 28–29','phase6-acceptance-reload.log','PHASE6_ACCEPTANCE_RELOAD_RESULT'],
 ['Migration / generated residents / partial and full harvest persistence','phase6-validation.log','PHASE6_VALIDATION_RESULT'],
 ['100 neighboring streamed chunks','phase6-stream-stress.log','STRESS5_RESULT'],
 ['Far fresh-process delta reload','phase6-far-reload.log','STRESS5_RESULT'],
 ['Fresh-process interior reload / storage / exact exit','phase6-interior-reload.log','PHASE6_RELOAD_RESULT'],
 ['Player avoidance / moving residents / farm origins','phase6-life-check.log','PHASE6_LIFE_RESULT'],
 ['Final interior poses / animal animation / F4','phase6-visual-final.log','PHASE6_VISUAL_RESULT'],
 ['Camera / graphics / native interface regression','phase6-presentation-regression.log','PRESENTATION5_RESULT'],
 ['Combat regression','phase6-combat-regression.log','COMBAT3_RESULT']
];
const rows=sources.map(([label,file,marker])=>{
 const text=fs.existsSync('downloads/'+file)?fs.readFileSync('downloads/'+file,'utf8'):'';
 const result=text.split(/\r?\n/).findLast(l=>l.includes(marker))||'Awaiting final run';
 return '| '+label+' | '+result+' | '+file+' |';
}).join('\n');
const metricsFile=root+'docs/PHASE_6_GUI_METRICS.json';
const metrics=fs.existsSync(metricsFile)?JSON.parse(fs.readFileSync(metricsFile)):[];
const metricRows=metrics.filter(x=>x.draw_calls>0).map(x=>'| '+x.scene+' | '+x.fps+' | '+x.draw_calls+' | '+x.nodes+' |').join('\n');
write(root+'docs/PHASE_6.md',`
# Phase 6 — physical and living world

Completed in the existing Relic Vale project, 10 September 2026. Phases 1–5 and the user's existing journey are preserved. The audit is in PHASE_6_AUDIT.md; the baseline is downloads/RelicVale-v0.6-baseline.zip. It includes the source, runtime assets, Windows launchers and bundled Godot engine for offline play. The archive excludes import caches, save files and downloaded source-pack archives. Extract it to a writable folder and run Launch Relic Vale.bat; the first run imports the local assets.

## Delivered systems

Resources: physical trees/logs, stone and mineral deposits, herbs, fiber, mushrooms and crystal. Crude/Iron/Steel axes and pickaxes use actual imported meshes, a Tool equipment slot, timed strike animation, impact foley, chips, node response, inventory feedback and visible depletion. Higher tiers reduce required strikes; steel grants a small yield bonus. Stable procedural IDs, partial damage and renewal days persist through chunk deltas and restart. See RESOURCE_SYSTEM.md for the data tables and controls.

Economy: the shared shop system sells harvested stacks, buys common supplies and sells better tools. Blacksmith, carpenter and alchemist preferences pay more for matching materials. Quest/equipped-item protection remains enforced. Price data and reputation feed one shared UI/transaction function; buying/reselling was checked across reputation tiers. No rare-crystal shop shortcut or unsafe bulk sale was introduced.

Interiors: house, general shop, forge, tavern and alchemist, each with imported furnishings, physical floor/furniture, lighting, appropriate ambience and household storage. A single active room loads behind a fade, with an exact logical exterior return. Outdoor simulation suspends while inside. Willowmere has five entrances; generated settlements have shops, tavern and farmhouse. INTERIORS.md explains records, loading, camera and persistence.

Residents: stable identities/home/work/tavern, exterior obstacle-aware walking, player/neighbor avoidance, time/weather destinations, indoor activity reservations, entry/exit movement and distance-based simulation. Merchants serve indoors, residents eat/drink/read/work/rest/sleep and react to nearby people. Willowmere has seven residents; small generated settlements have five or six. NPC_SIMULATION.md covers the concrete schedule and LOD.

Fauna: imported deer, stag, fox, cow, horse and alpaca; wildlife follows vegetated-biome rules and small groups, domestic animals belong to settlement farms. Idle/wander/graze/herd/flee/home/sleep states remain separate from enemy combat. Home/target positions survive origin shifts. Authored clips, bounded sounds, obstacle/water avoidance and distance throttling support ambient life without simulating an infinite population.

Camera: vertical right drag / Page Up–Down provides the requested modest 40–60 degree tilt, while existing horizontal orbit and wheel zoom remain. Blocking trees, roofs and objects hide temporarily and restore without resurrecting depleted resources. F3 world controls remain; F4 adds resource/interior/resident/fauna controls and path display.

## Assets and licensing

Quaternius Fantasy Props MegaKit Standard provides 32 selected tool/furniture/prop models; Ultimate Animated Animals provides the four new compatible animal models. Both are CC0. UAL2 Standard's 43 clips were downloaded and inspected; LPC sprites are not compatible with skeleton retargeting, so custom directional sprite/hand animation preserves the established look. The library is not represented as runtime retargeted motion.

Foley comes from rubberduck's 100 CC0 SFX #2; hoofbeats from EZduzziteh's Horse Trotting (CC0). The unmodified Mudchute cow recording by Secretlondon is CC BY-SA 3.0 with attribution and full license included. Existing Kenney/Quaternius scenery and LPC character credits remain. Tool thumbnails are rendered locally through the existing icon pipeline. Full URLs, selections, licenses and SHA-256 receipts are in ASSET_CREDITS.md and PHASE_6_ASSET_MANIFEST.json.

## Verification

| Check | Result | Workspace log |
| --- | --- | --- |
${rows}

PHASE_6_ACCEPTANCE.md records the exact requested 29-step sequence. The GUI run uses physics controller movement, keyboard door interaction and native pointer equipment; it physically walks the village/woodland, chops/mines, trades and follows Bram. Test/debug setup supplies time control and long-distance travel for unload checks. Reload occurs in a separate Godot process. The generated-world checks additionally cover partial harvest, full depletion/remnants, repeated unload/return, stable residents, malformed saves and old save formats. The real user journey is read-only and compared byte-for-byte after the run.

## Recorded GUI samples

Godot 4.7.2 Compatibility/OpenGL on Radeon Vega 8, 1280×720 window. FPS values are instantaneous scene samples, not a benchmark average; cold scene loads can be slower. The stress run was concurrent with acceptance and its timing includes that CPU contention. It traversed 100 chunks, retained bounded scenes/caches and peaked at 12,034 nodes; the largest recorded build stage was 60.448 ms under contention. This confirms bounds, not a guarantee of a hitch-free frame rate.

| Scene | FPS sample | Draw calls | Nodes |
| --- | ---: | ---: | ---: |
${metricRows}

Only one interior is instantiated. Imported scene/material resources are shared; noninteractive foliage remains batched; resident decisions and fauna simulation use distance throttling. The existing graphics presets remain functional. Raw GUI metrics are in PHASE_6_GUI_METRICS.json, and screenshots are in docs/screenshots/phase6-*.png.

## Practical limits

This is a playable local prototype. LPC humanoid actions use directional frames and simple seated/sleeping/working poses with imported hand props; there is no new humanoid skeleton. Interior decoration has a small set of seeded variations. Animals are ambient and noncombat, without breeding/taming or individually saved wilderness histories. Missing species-specific sleep clips use a rest pose. Optional falling-tree physics, durability and full farming/fishing systems remain outside this phase.

The test host has previously fallen back to Dummy audio, so automated playback checks do not establish audible sound quality. Rendering on this Vega 8 remains limited by scene/material draw calls; presets reduce cost but do not guarantee 60 FPS. All sources and runtime assets are local and no finishing download is required.
`);
console.log('Phase 6 README and report refreshed from actual test logs.');
