import fs from 'node:fs';
import crypto from 'node:crypto';
const base='relic_vale/';
const write=(name,text)=>fs.writeFileSync(base+name,text);
write('docs/WORLD_STREAMING.md',`# World streaming

The existing village and combat are retained. ValeStreamingGenerator extends the earlier generator; ValeRegionPlan is a pure-data worker and ValeInfiniteLandscape samples its continuous fields.

## Addresses and regions

Chunks are 32 metres square. The authoritative origin uses GDScript signed 64-bit integers, serialized as decimal strings, plus a local position within a chunk. Addresses are converted by subtracting integer chunk coordinates before constructing floating Vector3 positions. Regional plans cover 8×8 chunks (256 metres). Region zero contains the unique authored starting landscape. Other regions choose biome fields, landmarks and occasional settlements; shared edge portals connect their arterial roads. Rivers meander continuously across north/south chunk borders, with regional lakes and road bridges. This is stylized geography, without hydraulic erosion or a simulated drainage basin.

The seed and logical coordinates generate identical base scenery. Context includes adjacent regions; terrain shares a 2 m sampling lattice and roads are clipped onto the same triangles as collision. Hash-based scalar noise avoids far-coordinate Vector2 precision loss. Vegetation and feature positions are planned in chunk-local coordinates. Stable IDs identify resources, treasure, discoveries and unique enemies.

## Lifecycle and memory

Unseen → requested → worker data generation → ready → staged main-thread instantiation → active → cached → unloaded. Two WorkerThreadPool tasks operate only on private RefCounted data: fields, placements, terrain/road/water vertices, normals and colors. Every task is joined before disposal. Nodes, collision and rendering resources are created on the main thread, yielding after a soft 3 ms stage budget. One imported scene or collision operation can exceed that soft limit.

Gameplay radius: 1 chunk. Minimal/Medium preload radius: 2, unload radius: 3 (25 initial chunks, at most 49 retained). High/Ultra preload: 3, unload: 4 (49 initial chunks, at most 81 retained). This exceeds the orthographic camera's useful footprint. Unfinished chunks remain hidden until ready; atmospheric haze softens distance. Gameplay processing is disabled for preloaded distant chunks. No permanent mountain border remains.

The data cache retains 48 recently unloaded blueprints in addition to loaded/pending data. Height cache is capped at 18,000 entries, local samplers at 80. Distant scene roots leave the tree and are freed. The unique authored village is one bounded cached scene, detached when far away and reattached only near its original address. Reserved interior scenes remain independent of outdoor origin shifting.

When local outdoor coordinates exceed 128 metres, the world shifts by whole chunks. Player, camera interpolation, active chunks, enemies' origins, NPC paths, wildlife origins, loot, effects and dungeon return positions move together. Burst effects use local child tweens so their animation endpoints survive a shift. Debug teleports replace the local window; they never position the character at huge raw coordinates.

## Persistence

Save format 5 reads formats 2–4. The main JSON stores character progress, world metadata, local position, logical origin and an atomic manifest. Each slot has a separate .chunks directory of SHA-256 named delta records. Only changes and charted map data are stored; ordinary generated trees and terrain are regenerated. Unchanged records are reused. After a successful atomic save, unreferenced generated records are pruned while both current and backup manifests remain recoverable. Invalid hashes, malformed map data and invalid logical addresses are rejected.

Discovered areas store biome, known landmark and clipped road/water map geometry. The draggable, zoomable atlas draws visited cells only. Exploration history necessarily grows as new land is charted; active scene/cache memory stays bounded.

Tests: 100 neighboring chunk transitions, far teleports at (100,100), (1000,-500), (10000,10000), (1000000000,-1000000000), actual new-process far save/reload, plus continuous controller travel. Detailed measured results are in PHASE_5_STRESS.md, PHASE_5_FAR_RELOAD.md and PHASE_5_FINAL_TEST.md. The billion-chunk test is the verified coordinate envelope; the prototype does not claim every possible signed-integer endpoint.

References: [Godot thread safety](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html), [WorkerThreadPool](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html).
`);
write('docs/GRAPHICS_SETTINGS.md',`# Graphics settings

Open Esc → Settings → Graphics. Preferences are stored in user://preferences.cfg, independently of world slots. The default is Medium. Safe settings apply at runtime. Changing an advanced setting selects Custom; named presets restore their values without changing Pixelated Render.

| Setting | Minimal | Medium | High | Ultra |
|---|---:|---:|---:|---:|
| Clean render scale | 70% | 85% | 100% | 100% |
| Directional shadow atlas | 1024 | 2048 | 4096 | 8192 |
| Shadow splits | 2 | 2 | 4 | 4 |
| Ground-cover instances | 40% | 70% | 90% | 100% |
| Foliage view range from camera | 118 m | 135 m | 155 m | 175 m |
| Cosmetic particle multiplier | 0.4 | 0.7 | 1.0 | 1.4 |
| Outdoor preload radius | 2 | 2 | 3 | 3 |
| Water | simple | ripples | shore/normal detail | rain detail |
| Normal-mode AA | none | MSAA 2× | MSAA 4× | MSAA 4× |

All settings retain terrain collision, nearby landmarks/resources, enemy attack telegraphs, loot and quest information. Geometry is batched through MultiMesh for ground cover. Distant gameplay simulation is disabled. Shadows, density, shader detail, view distance and cosmetic particles scale progressively; the environment remains recognizable at every preset.

The bundled renderer is OpenGL Compatibility. Distance haze, directional shadows, ambient color, day/night lighting, stylized surface shaders and ordinary particles work here. SSAO, SSIL, SSR and volumetric fog are not supported by this renderer; the manager capability-gates them for a future Forward+ configuration. No unsupported effect is presented as active. Filmic tonemapping was visually tested and rejected because it washed out this palette; the final rendering uses linear tonemapping and the existing day/weather lighting.

Terrain shader: shared biome colors, periodic macro/micro surface variation and global rain darkening/roughness. Ground cover: texture alpha cutout, anchored gusts, instance tints, proximity bending and wetness. Leaf-only wind affects crown material without moving trunks. Water: shared world phase, depth/bank color, ripple highlights, quality-gated normal perturbation, shoreline foam approximation and rain glints. These shaders are original project code, not copied third-party shaders. Periodic logical-origin offsets keep patterns aligned during outdoor shifts.

Pixelated Render is an independent art choice. It lowers only the 3D SubViewport with Subtle/Medium/Strong strength, nearest upscaling and no MSAA. UI remains on the native canvas with Rubik/Press Start 2P distance-field fonts. Clean rendering uses native-window-scaled resolution and linear image sampling; it is not an enlarged pixel buffer. Resolution, Windowed/Borderless/Fullscreen, VSync, frame cap, UI scale and audio are independent preferences.

F3 shows FPS, CPU frame time, draw calls, node/instance/particle counts, active chunks, cache, current preset, render size and origin. GPU frame time is explicitly unavailable in this OpenGL measurement path. PHASE_5_PRESENTATION.json records the four-preset × two-style in-game matrix. Measurements on Vega 8 are observations, not a universal FPS guarantee. Lower density reduces geometry but this prototype still has substantial CPU/draw-call overhead.

Camera: Q/R or horizontal right drag orbit; vertical right drag or Page Up/Down tilts within 40–60 degrees; wheel zooms; Home resets all three. Blocking collision-linked visuals and their crowns/roofs hide temporarily, including when the camera is inside their visual bounds. Physics collision remains; visibility is restored when the view clears, and weak references handle streamed removal safely.

Renderer reference: [Godot renderer comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
`);
write('docs/UI_STYLE_GUIDE.md',`# Interface style guide

One primary UI family: Kenney UI Pack RPG Expansion, recolored through reusable StyleBoxTexture tinting. Palette: deep teal panels, desaturated green buttons, warm ivory text (#f4edd8), muted sage (#a5b8b0), gold accents (#dcc184). Avoid glossy gradients. Focus is a visible gold outline; hover/press and disabled states use the same family.

Theme: assets/ui/phase5/vale_theme.tres, reproducible with tools/build_ui_theme.gd. Rubik 16 for body, 26 for headings, 14 for secondary text. Press Start 2P 10 for short captions and rarity labels. Both bundled under SIL OFL; Latin, Cyrillic, numbers and punctuation verified. Distance-field import supports scaling. Body text is never drawn into the pixelated 3D buffer.

Controls use container layout with 12 px flow spacing, 14 px horizontal/9 px vertical frame padding. Modal windows have 30 px canvas margins; main/pause menus use a narrow left column over the live village. Dialogue sits in the lower 38% of the view. Long content scrolls vertically. UI scale supports 80–150%. Native controls preserve keyboard Tab/Enter focus. Important status uses written labels as well as color.

Icons: 128×128 sources; inventory cells 66 px, detail art 88 px, hotbar icons 30 px, recipe icons 64 px. Drummyfish CC0 Fantasy RPG Icons provide painted equipment/ability icons. tools/ItemIconRenderer.tscn renders missing material thumbnails from actual imported scenery using a fixed orthographic camera/light, transparent background and 128×128 output. Source licenses follow the corresponding CC0 meshes. These images can be regenerated without a network service.

ValeInterface provides text, row, column, scroller, button, option and icon helpers. ValeInventoryPage, ValeJourneyPages, ValeEconomyPages and ValeMenuPages build reusable screens. ValeHUD retains the gameplay-facing API so quests, dialogue, combat and interactions continue to use the existing signals. Hidden legacy helper code remains for compatibility and stat formatting; normal players see the new pages.

Screens: title, pause, new world/name/seed/randomization, three save slots with metadata, loading, credits, settings (five tabs), HUD/hotbar, inventory/filter/sort/equipment comparison, appearance, abilities, quest/faction/side journal, trade Buy/Sell, crafting, shrine/reveal and discovered atlas. Boss/nameplate text uses the same body font. Subtle hover/click/equip sounds reuse the credited audio pipeline.
`);
let credits=fs.readFileSync(base+'docs/ASSET_CREDITS.md','utf8');
credits=credits.replace('- UI typography uses Windows system fonts (Segoe UI and Georgia, with fallbacks). No font files are copied or redistributed.','- Phase 1 used Windows system fonts. Phase 5 replaces normal player-facing typography with bundled OFL Rubik and Press Start 2P, credited below.').replace('- No audio assets are included.','- Audio was added in phases 3–4; see the credits below.');
if(!credits.includes('## Phase 5 interface assets'))credits+=`\n## Phase 5 interface assets\n\n- **UI Pack RPG Expansion**, Kenney, CC0. [Official page](https://kenney.nl/assets/ui-pack-rpg-expansion). Selected blue panels/buttons, focus/support icons and arrows; tinting through the Godot Theme. License bundled in assets/ui/phase5/Kenney-CC0.txt.\n- **Fantasy RPG Icons**, Drummyfish, CC0. [Author's asset page](https://opengameart.org/content/fantasy-rpg-icons-0). Selected 128×128 equipment/ability images. Original download: https://opengameart.org/sites/default/files/fantasy_rpg_icons.zip.\n- **Rubik**, Google Fonts upstream, SIL OFL. [Source](https://github.com/google/fonts/tree/main/ofl/rubik). Font and exact OFL bundled.\n- **Press Start 2P**, Google Fonts upstream, SIL OFL. [Source](https://github.com/google/fonts/tree/main/ofl/pressstart2p). Font and exact OFL bundled.\n- **Original material thumbnails**: wood, stone, ore, herb, fiber, mushrooms and crystal; generated by the included Godot ItemIconRenderer from previously credited Kenney/Quaternius CC0 meshes. No new third-party source.\n- **Original shaders**: terrain detail, leaf wind, grass/proximity response and water depth/ripple/shore/rain shading; no external shader code copied.\n\nArchive and selected-file SHA-256 receipts: PHASE_5_ASSET_MANIFEST.json.\n`;
write('docs/ASSET_CREDITS.md',credits);
function files(path){return fs.readdirSync(path,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path+'/'+e.name):[path+'/'+e.name]);}
const hash=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const archives=['downloads/phase5-kenney-ui.zip','downloads/phase5-icons.zip'];
write('docs/PHASE_5_ASSET_MANIFEST.json',JSON.stringify({archives:archives.map(f=>({path:f,sha256:hash(f),bytes:fs.statSync(f).size})),files:files(base+'assets/ui/phase5').filter(f=>!f.endsWith('.import')).map(f=>({path:f.slice(base.length),sha256:hash(f),bytes:fs.statSync(f).size}))},null,2));
console.log('Phase 5 architecture, graphics, style guide and asset documentation written.');
