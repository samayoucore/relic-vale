# World streaming

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
