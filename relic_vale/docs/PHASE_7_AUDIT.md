# Phase 7 baseline audit

The unmodified v0.6 game was run in a graphical Godot 4.7.2 session on 10 September 2026. The eight NPC route, pasture and floating-origin life checks passed (`downloads/phase7-baseline-audit.log`). The v0.6 archive and real journey save are preserved.

The existing streaming generator already supplies deterministic terrain, roads, water, POIs, integer logical addresses, chunk discovery and synchronous preload. The existing atlas only paints biome squares, sampled water dots and generic POI dots. There is no shared terrain minimap, marker storage, safe player fast travel or owned settlement economy.

Phase 7 extends `ValeAtlas`, reuses `ValeRegionPlan` for cartographic tiles, `ValeStreamingGenerator` for relocation, Phase 5 UI and camera, Phase 6 interiors and LPC inhabitants. Camp state remains independent of player XP and currency; offscreen work uses the existing game clock. New camp models are Kenney Survival Kit (CC0), with existing medieval houses for later stages.
