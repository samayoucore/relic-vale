# Graphics settings

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

Pixelated Render is an independent art choice. It lowers only the 3D SubViewport with Subtle/Medium/Strong strength, nearest upscaling and no MSAA. UI remains on the native canvas with Rubik distance-field body text and pixel-font captions. Clean rendering uses native-window-scaled resolution and linear image sampling; it is not an enlarged pixel buffer. Resolution, Windowed/Borderless/Fullscreen, VSync, frame cap, UI scale and audio are independent preferences.

F3 shows FPS, CPU frame time, draw calls, node/instance/particle counts, active chunks, cache, current preset, render size and origin. GPU frame time is explicitly unavailable in this OpenGL measurement path. PHASE_5_PRESENTATION.json records the four-preset × two-style in-game matrix. Measurements on Vega 8 are observations, not a universal FPS guarantee. Lower density reduces geometry but this prototype still has substantial CPU/draw-call overhead.

Camera: Q/R or horizontal right drag orbit; vertical right drag or Page Up/Down tilts within 40–60 degrees; wheel zooms; Home resets all three. Blocking collision-linked visuals and their crowns/roofs hide temporarily, including when the camera is inside their visual bounds. Physics collision remains; visibility is restored when the view clears, and weak references handle streamed removal safely.

Renderer reference: [Godot renderer comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
