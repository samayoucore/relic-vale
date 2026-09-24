# Phase 4 baseline audit

The v0.3 source is preserved in `downloads/RelicVale-v0.3-baseline.zip`. The actual game was launched and the original lantern road traversed with physics/input. Five environments and four boundary camera headings were captured in `screenshots/phase4-before-*.png`.

Primary reference: `ValeWorld.terrain()` uses 2 m tiles, flat vertex colors between #788957 and #839362, becoming #5e795b–#70845a toward the eastern forest. Its material uses vertex albedo and roughness 1. Village assets have shared, subdued foliage, wood and stone materials. Paths, yards, flowers and clustered trees give scale and intentional open spaces.

`ValeGenerator.build_ground()` instead used a flat collision box and smooth vertex colors across a uniform chunk plane. Its separate biome palette and low-frequency interpolation erased the village's tile texture. Decoration was only 4–15 trees and a few isolated micro-props per 1024 m²; no dense geometric ground cover. The edge consisted of a rectangular flat skirt and widely spaced rock columns, exposing a step and gaps in every orbit sample. Enemy sprites were generated pixel placeholders.

Preserve the original village terrain colors, layout, buildings, pond, paths and lighting as the art reference. Extend its material into rolling terrain, continuous world-space biome influences, layered clustered cover, natural waterways and a continuous enclosing ridge. Imported rigged creature presentation must preserve existing combat behavior.

Baseline notes: the original path from the square to the crypt approach was passable. Two audit waypoints east of that approach hit the existing crypt wall at x≈40; they were an invalid straight-line route, not a generated road. Future road connections must route around that structure. Warm baseline screenshots reported approximately 22–30 FPS and 1962–2397 nodes on this host; initial village capture was still warming shaders. Compare final captures after warmup. Engine emits the host's existing root certificate store warning.
