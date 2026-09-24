# Asset credits and provenance

All packs were obtained from the requested creators or their official repositories on 2026-09-07. Only freely available content is included. No paid tiers, account-only content, or assets from a copyrighted commercial game are used.

## 3D environment

| Pack | Creator and official source | License | Included location and use |
| --- | --- | --- | --- |
| Nature Kit | Kenney — https://kenney.nl/assets/nature-kit | CC0 1.0 | `assets/3d/nature/`: trees, rocks, shrubs, flowers, mushrooms, grass; a few additional scenery pieces are retained for editing. |
| Medieval Builder Pack 1.0 | Kay Lousberg — https://kaylousberg.itch.io/kaykit-medieval-builder-pack | CC0 1.0 | `assets/3d/medieval/`: houses, watermill, lumbermill, market, well, farm plot; mine/watchtower retained for editing. |
| Dungeon Remastered / Dungeon Pack | Kay Lousberg — https://kaylousberg.itch.io/kaykit-dungeon-pack and https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0 | CC0 1.0 | `assets/3d/dungeon/`: chest, barrels, crates, columns, torches, stairs, and other small dungeon pieces. |

The original pack license files are kept beside the models. CC0 does not require attribution; the authors are credited here as a courtesy. The Medieval Builder pack is the exact requested legacy pack, downloaded through its free itch.io flow. Dungeon models came from the creator’s official free repository.

Models remain GLB. No format conversion or external textures are required. Runtime modifications normalize model bounds, adjust placement and scale, set nonmetallic matte materials, and harmonize selected nature/building colors. Terrain, paths, pond, dock, arch, some walls, fences, pennants, crystals, water shader, and particles were authored in GDScript/shaders for this project.

## LPC characters — attribution required

Source: [Universal LPC Spritesheet Character Generator](https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/), maintained at https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator.

Six source layers are included for the male player and keeper. Each has idle (2 frames), walk (9 frames), and slash (6 frames), in north/west/south/east rows. The six assets are offered under multiple licenses by upstream; this project uses the **CC BY-SA 3.0** option common to all six.

License: https://creativecommons.org/licenses/by-sa/3.0/ — full legal text is included in `docs/licenses/CC-BY-SA-3.0.txt`. Keep attribution, indicate changes, and preserve this license for distributed adapted LPC sprite artwork. This asset license is recorded separately from the game code and other packs.

Original PNG layers are unmodified under `assets/2d/lpc/`. `scripts/pixel_art.gd` composites them at runtime, recolors shoes, trousers, shirt and hair, and adds an original small traveling cloak to the player. The resulting character artwork is an adaptation of the credited LPC assets and is provided under CC BY-SA 3.0. The keeper reuses the same source layers with different shirt/hair colors.

### Included layers and their original credits

#### 0: Body Color

Source directory: `spritesheets/body/bodies/male/`

Authors: bluecarrot16; JaidynReiman; Benjamin K. Smith (BenCreating); Evert; Eliza Wyatt (ElizaWy); TheraHedwig; MuffinElZangano; Durrani; Johannes Sjölund (wulax); Stephen Challener (Redshrike).

Upstream notes: see details at https://opengameart.org/content/lpc-character-bases; 'Thick' Male Revised Run/Climb by JaidynReiman (based on ElizaWy's LPC Revised).

Original source pages:

- https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
- https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
- https://opengameart.org/content/lpc-male-jumping-animation-by-durrani
- https://opengameart.org/content/lpc-runcycle-and-diagonal-walkcycle
- https://opengameart.org/content/lpc-revised-character-basics
- https://opengameart.org/content/lpc-be-seated
- https://opengameart.org/content/lpc-runcycle-for-male-muscular-and-pregnant-character-bases-with-modular-heads
- https://opengameart.org/content/lpc-jump-expanded
- https://opengameart.org/content/lpc-character-bases

#### 1: Basic Shoes

Source directory: `spritesheets/feet/shoes/basic/male/`

Authors: JaidynReiman; bluecarrot16; Johannes Sjölund (wulax).

Upstream notes: original by wulax, edited for v3 base by bluecarrot16, Jump/Sit/Emote/Run/Revised Combat by JaidynReiman.

Original source pages:

- https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
- http://opengameart.org/content/lpc-clothing-updates
- https://opengameart.org/content/lpc-expanded-socks-shoes

#### 2: Pants

Source directory: `spritesheets/legs/pants/male/`

Authors: bluecarrot16; JaidynReiman; ElizaWy; Matthew Krohn (makrohn); Johannes Sjölund (wulax); Stephen Challener (Redshrike).

Upstream notes: original male pants by wulax, recolors and edits to v3 base by bluecarrot16, climb/jump/run/sit/emotes/revised combat by JaidynReiman based on ElizaWy's LPC Revised.

Original source pages:

- https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
- https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
- https://opengameart.org/content/lpc-expanded-pants

#### 3: Longsleeve

Source directory: `spritesheets/torso/clothes/longsleeve/longsleeve/male/`

Authors: JaidynReiman; Johannes Sjölund (wulax).

Upstream notes: original by wulax; tweaks and further recolors by bluecarrot16; cleanup and climb/jump/run/sit/emote/revised combat adapted from LPC Revised by JaidynReiman.

Original source pages:

- https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
- http://opengameart.org/content/lpc-clothing-updates
- https://opengameart.org/content/lpc-revised-character-basics
- https://github.com/ElizaWy/LPC/tree/main/Characters/Clothing
- https://opengameart.org/content/lpc-expanded-sit-run-jump-more
- https://opengameart.org/content/lpc-expanded-simple-shirts

#### 4: Human Male

Source directory: `spritesheets/head/heads/human/male/`

Authors: bluecarrot16; Benjamin K. Smith (BenCreating); Stephen Challener (Redshrike).

Upstream notes: original head by Redshrike, tweaks by BenCreating, modular version by bluecarrot16.

Original source pages:

- https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
- https://opengameart.org/content/lpc-character-bases

#### 5: Plain

Source directory: `spritesheets/hair/plain/adult/`

Authors: JaidynReiman; Manuel Riecke (MrBeast); Joe White.

Original source pages:

- https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
- https://opengameart.org/content/ponytail-and-plain-hairstyles
- https://opengameart.org/content/lpc-expanded-hair

The exact upstream sheet definitions and the selected machine-readable credit records are preserved in `docs/licenses/lpc-*.json` and `docs/licenses/LPC_SELECTED_CREDITS.json`. Per-file SHA-256 hashes and the source tree identifiers are recorded in `docs/ASSET_MANIFEST.json`.

## Original art, fonts, and runtime

- Mossling sprites, sword arc, soft contact-shadow texture, terrain geometry, and UI layout are original project-authored code/art. The mossling is the explicitly allowed compatible placeholder approach; it is not taken from another game.
- Phase 1 used Windows system fonts. Phase 5 replaces normal player-facing typography with bundled OFL Rubik and Press Start 2P, credited below.
- Godot Engine 4.7.2 standard Windows x64 was downloaded from the official release: https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable, linked by https://godotengine.org/download/windows/. Godot is MIT-licensed; see `docs/licenses/GODOT-LICENSE.txt` and https://godotengine.org/license/. The downloaded archive was verified against the official SHA512-SUMS.txt.
- Audio was added in phases 3–4; see the credits below.

## Download status / manual steps

**No manual asset downloads or finishing steps remain.** The LPC character generation is automated by the local compositor, and all requested environment packs are integrated.

If you need to restore a damaged asset folder, the original environment ZIP archives remain in `../downloads/`; the hashes below identify the downloaded files. Copy the selected GLBs from their matching source folder, keeping the pack license. All selected files are listed in `ASSET_MANIFEST.json`.

| Original archive | Source / source folder | SHA-256 |
| --- | --- | --- |
| kenney_nature-kit.zip | https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip | `fa7974a0d342bfe63c38664ba9f8ec1a4aab8ea25f099bdc56870e33588c4d9d` |
| kaykit-medieval.zip | https://kaylousberg.itch.io/kaykit-medieval-builder-pack — Models/objects/gltf | `588d931b62a33d71bb114078f0a7c02309a97a25c51a47083cf077bd97edaa3e` |
| Godot_v4.7.2-stable_win64.exe.zip | https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable | `731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953` |

## Phase 2 original artwork

The wolf, skeleton/guardian variants, inventory icon shapes, loot sparks, map drawing, road meshes and generated POI arrangements are original code-created additions in this project. No new third-party art packs or external services were introduced in phase 2. The existing LPC and scenery attributions above still apply.

## Phase 3 audio and generated support assets

- **RPG Audio**, Kenney. Source: https://kenney.nl/assets/rpg-audio. License: **CC0 1.0**, no attribution required (credit retained voluntarily). Selected footsteps, blade/cloth sounds, hit, coins, creak and UI/handling cues are used for movement, melee, pickups and interaction. The official page and included KENNEY-LICENSE.txt confirm the license. Archive/source hashes and selected filenames are in PHASE_3_AUDIO_MANIFEST.json.
- **Original synthesized cues and musical loops**, created locally for this project by tools/phase3_assets.mjs: spell, bow, critical, heal, level, shrine, hurt, death, slam, and vale/crypt/boss loops. No third-party samples or melodies.
- **Original procedural combat visuals**: ring telegraphs, slash trails, sparks, projectile icons and rarity effects, generated in GDScript. Existing LPC layer attributions remain unchanged.


### Phase 3 appearance and enemy variants

Skin (body and modular face), hair and outfit recoloring and cloak selection are runtime adaptations of the same credited LPC layers. These adapted sprites remain under CC BY-SA 3.0; no extra LPC download or new attribution source was introduced. Bat, archer, witch, mimic, elite and larger crowned boss variants are original GDScript pixel drawings. Synthesized WAV cues/music and procedural VFX are project-authored work without third-party samples. Original download archives and exact pack license remain available locally.

## Phase 4 assets

Only selected models and referenced textures are imported. Full downloaded archives stay outside the Godot project, in `downloads/`. Exact file hashes and purposes are in `PHASE_4_ASSET_MANIFEST.json`.

- **Stylized Nature MegaKit — Standard**, Quaternius. [Official source](https://quaternius.com/packs/stylizednaturemegakit.html). CC0 1.0. Geometric grass, ferns, clover, flowers, mushrooms, pebbles and compatible undergrowth.
- **LowPoly Animated Monsters**, Quaternius. [Official source](https://quaternius.itch.io/lowpoly-animated-monsters). CC0 1.0. Rigged and animated slime, skeleton and bat enemy presentation.
- **Ultimate Animated Animals**, Quaternius. [Official source](https://quaternius.com/packs/ultimateanimatedanimals.html). CC0 1.0. Animated wolf enemies, deer and stag wildlife.
- **KayKit Adventurers 2.0 Free**, Kay Lousberg. [Official source](https://kaylousberg.itch.io/kaykit-adventurers). CC0 1.0. Mage and knight skins with General and MovementBasic animation libraries.

Kenney Nature Kit `log.glb` was additionally selected from the previously credited CC0 archive. The handcrafted village keeps its established Kenney/KayKit assets and palette. Quaternius village/props paid or full packs were not imported; compatibility with the existing village family takes priority. Master terrain, wind shader, river/bank meshes and continuous ridge mesh are original project code. Existing LPC character licenses remain unchanged.

## Phase 4 original ambience

Six original 8-second mono WAV loops (wind, forest birds, water, night insects, rain, village work) generated by tools/phase4_ambience.mjs. No third-party samples. They loop through the SFX bus with smooth proximity/day/weather mixing. Terrain, vegetation and water shader changes are original project code.

## Phase 5 interface assets

- **UI Pack RPG Expansion**, Kenney, CC0. [Official page](https://kenney.nl/assets/ui-pack-rpg-expansion). Selected blue panels/buttons, focus/support icons and arrows; tinting through the Godot Theme. License bundled in assets/ui/phase5/Kenney-CC0.txt.
- **Fantasy RPG Icons**, Drummyfish, CC0. [Author's asset page](https://opengameart.org/content/fantasy-rpg-icons-0). Selected 128×128 equipment/ability images. Original download: https://opengameart.org/sites/default/files/fantasy_rpg_icons.zip.
- **Rubik**, Google Fonts upstream, SIL OFL. [Source](https://github.com/google/fonts/tree/main/ofl/rubik). Font and exact OFL bundled.
- **Press Start 2P**, Google Fonts upstream, SIL OFL. [Source](https://github.com/google/fonts/tree/main/ofl/pressstart2p). Font and exact OFL bundled.
- **Original material thumbnails**: wood, stone, ore, herb, fiber, mushrooms and crystal; generated by the included Godot ItemIconRenderer from previously credited Kenney/Quaternius CC0 meshes. No new third-party source.
- **Original shaders**: terrain detail, leaf wind, grass/proximity response and water depth/ripple/shore/rain shading; no external shader code copied.

Archive and selected-file SHA-256 receipts: PHASE_5_ASSET_MANIFEST.json.

## Phase 6 assets

- **Fantasy Props MegaKit — Standard**, Quaternius, **CC0 1.0**. [Official page](https://quaternius.com/packs/fantasypropsmegakit.html), [author distribution](https://quaternius.itch.io/fantasy-props-megakit). 32 selected glTF models plus referenced binary buffers and textures in assets/3d/phase6/props. Includes Axe_Bronze, Pickaxe_Bronze, beds, tables, chairs, books, containers, forge and alchemy furnishings. Tools retain original geometry; iron/steel use material tints. Props use shared materials, disabled normal maps and 1024-pixel mipmapped runtime textures.
- **Ultimate Animated Animals**, Quaternius, **CC0 1.0**. [Official page](https://quaternius.com/packs/ultimateanimatedanimals.html). Cow, Fox, Horse and Alpaca glTFs added under assets/3d/phase6/animals. Existing Deer/Stag/Wolf remain credited in Phase 4. These compatible farm species were chosen from the animated-animal library; a separate Farm Animal Pack was not imported.
- **Universal Animation Library 2 — Standard**, Quaternius, **CC0 1.0**. [Official page](https://quaternius.com/packs/universalanimationlibrary2.html), [author distribution](https://quaternius.itch.io/universal-animation-library-2). Downloaded and audited 43 Standard clips, including TreeChopping_Loop and Farm_Harvest. Audit receipt retained; the library is **not used as runtime player animation** because LPC billboard sprites have no compatible humanoid skeleton. Original directional sprite frames plus custom hand/swing transforms preserve the existing character style. Existing LPC attribution/share-alike terms continue to apply.
- **100 CC0 SFX #2**, rubberduck, **CC0 1.0**. [Source](https://opengameart.org/content/100-cc0-sfx-2). Selected wood_hit_01, wood_03, stones_01, metal_hit_01, glass_01, door_01, footstep_wood_01 and loop_water_01 OGGs; used unmodified for gathering and room foley.
- **Horse Trotting**, EZduzziteh, **CC0 1.0**. [Source](https://opengameart.org/content/horse-trotting). Unmodified Trot.ogg renamed hoof.ogg.
- **Mudchute cow recording**, Secretlondon, submitted to OpenGameArt by qubodup. [Farm animals source](https://opengameart.org/content/farm-animals), [original collection](https://commons.wikimedia.org/wiki/Category:Mudchute_Park_and_Farm), [author](https://commons.wikimedia.org/wiki/User:Secretlondon). **CC BY-SA 3.0 selected from the offered dual license.** Only Mudchute_cow_1.ogg is shipped, unmodified, with original info.txt. Attribution and share-alike apply to the recording and adaptations; the full license is included in docs/licenses/CC-BY-SA-3.0.txt and [online](https://creativecommons.org/licenses/by-sa/3.0/). No endorsement is implied.
- **Original support work**: six transparent tool thumbnails rendered through the existing ItemIconRenderer from CC0 meshes; timed hand/swing tracks; resource particles; room layouts, anchor logic, lighting and code. Resource icons and Kenney tree/rock/plant meshes reuse the previous credited selection.

Exact selected files, byte sizes, SHA-256 hashes and download receipts are recorded in PHASE_6_ASSET_MANIFEST.json. The full source archives and the inspected UAL2 library stay in workspace downloads, outside the game runtime. No further asset download is needed to play.

## Phase 7 — Survival Kit

Kenney, Survival Kit 2.0, downloaded 2026-09-10 from [the official pack page](https://kenney.nl/assets/survival-kit) and its linked ZIP. License: **CC0 1.0**, preserved in `assets/3d/phase7/LICENSE.txt`. Selected tents, fire pit/stand, chest, crates, barrels, bedroll, workbench, fences, signpost, wood pile and market canopy are used. Original GLBs and their `Textures/colormap.png` palette are retained; runtime code normalizes size and places them. The full download SHA256 is `C3586341B5932C87EB43D75D915434F47DAED168B17ED36A03E8CA9977C7443E`.

Late-tier houses reuse KayKit Medieval Builder (CC0); room furniture reuses Phase 6 assets. Camp characters adapt the existing credited LPC layers under their recorded CC BY-SA terms, using the existing palette/animation pipeline. Atlas symbols and terrain tiles are original GDScript-generated graphics. Detailed selected-file hashes are in PHASE_7_ASSETS.json. No generative image service was used.

## Phase 8 — professions, fishing, crops, food and mounts

| Pack / creator | Primary source | License | Integrated use |
| --- | --- | --- | --- |
| Cute Fish Pack — Quaternius | [Official page](https://quaternius.com/packs/cutefish.html) | CC0 1.0 | 20 species, three rod tiers, lure/float, Swimming_Normal fish clips |
| Ultimate Crops — Quaternius | [Official page](https://quaternius.com/packs/ultimatecrops.html) | CC0 1.0 | Imported crop families and stages, harvested crop models |
| Ultimate Food — Quaternius | [Official page](https://quaternius.com/packs/ultimatefood.html) | CC0 1.0 | Cooking pot, dish/ingredient models and meal icons |
| Farm Buildings — Quaternius | [Official page](https://quaternius.com/packs/farmbuildings.html) | CC0 1.0 | OpenBarn stable and fence model selection |
| Watering Can — Isa Lousberg | [Author's model page](https://poly.pizza/m/hybuUvYsri) | CC0 / public domain | Actual held watering-can mesh |
| Universal Animation Library 2 Standard — Quaternius | [Official page](https://quaternius.com/packs/universalanimationlibrary2.html) | CC0 1.0 | Farm_Harvest, Farm_PlantSeed, Farm_Watering and OverhandThrow upper-arm samples |
| Ultimate Animated Animals — Quaternius | [Official page](https://quaternius.com/packs/ultimateanimatedanimals.html) | CC0 1.0 | Existing Horse glTF reused with authored Idle/Walk/Gallop clips |

The free Standard UAL2 distribution contains 43 clips. Phase 6 audited it without runtime use; **Phase 8 now uses normalized right upper-arm pitch samples** to drive the existing held-tool adapter. It does not retarget an entire humanoid skeleton and does not claim a dedicated fishing clip. The torso retains compatible directional LPC frames. Seated rider frames are runtime adaptations of the same LPC layers and remain covered by the LPC attribution/share-alike terms above.

81 selected Quaternius FBX models were converted to GLB in Blender 5.2 with authored animations retained. Empty source mesh nodes were removed and the source FBX alpha interpretation was corrected to opaque while preserving material colors. The watering can is the author's original GLB. Runtime assets include pack notices and the existing CC0 license. Source FBXs, download receipts and conversion records stay in workspace downloads; the release needs only the converted runtime selection.

**Generated support assets:** 60 transparent PNG icons rendered in Godot from the credited meshes; a sampled motion JSON; the procedural fishing line/meter, soil patches and map symbols; runtime seated LPC frame adaptation. These are support work, not generated replacement fish/crop/horse models. No generative image service was used. Model/icon/motion hashes are listed in PHASE_8_ASSETS.json. Existing hoof/water/gathering sounds reuse Phase 6 credited recordings.

## Phase 9 — named companions and compatible skeletal animations

| Asset / creator | Primary source | License | Use |
| --- | --- | --- | --- |
| KayKit Adventurers 2.0 — Kay Lousberg | [Official pack](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | Existing Knight, Ranger and Mage reused; Rogue, its texture and compatible sword/shield/bow/staff/dagger meshes selected from the already downloaded pack |
| KayKit Character Animations 1.1 — Kay Lousberg | [Official pack](https://kaylousberg.itch.io/kaykit-character-animations) | CC0 1.0 | Rig_Medium CombatMelee, CombatRanged and Simulation clips on the matching 23-bone Adventurers rigs; existing General and MovementBasic packs reused |
| Kenney Survival Kit 2.0 | [Official pack](https://kenney.nl/assets/survival-kit) | CC0 1.0 | Previously credited tents, bedrolls, signs, chests, supplies and campfires reused for story/event locations |

The new animation ZIP is 14,858,957 bytes; SHA-256 `65882F31F905AD2E953819648A59287CDEAB8F623908D5EF701971D3758BE20F`. The source receipt and skeleton/clip audit are in workspace downloads. Pack notices are retained beside the imported animation and equipment files. No ripped models or paid content were used. The coherent existing KayKit family was chosen to avoid mixing humanoid rigs and styles. This phase does not claim new full-body Quaternius UAL retargeting.

Four transparent 300 × 360 companion portraits were rendered locally in Godot from the actual credited models and hand equipment; no unrelated portrait illustration or image-generation service was used. Narrative text, JSON definitions, dialogue/atlas integration and runtime behavior are project-authored. Ordinary event NPCs continue to use the credited LPC pipeline under its existing attribution/share-alike terms. File hashes are in [PHASE_9_ASSETS.json](PHASE_9_ASSETS.json).
