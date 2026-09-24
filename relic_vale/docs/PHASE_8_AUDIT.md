# Phase 8 — baseline audit

2026-09-11. The existing project was run graphically before implementation. The Phase 7 physical camp/interaction suite passed **11 / 11** checks; log: `downloads/phase8-baseline-audit.log`. Version 0.7 is preserved in `downloads/RelicVale-v0.7-baseline.zip` with its verification receipt.

Extension points inspected: State item/equipment/stat databases, ValeGathering tool hand adapter, persistent ValeResource hit/respawn records, ValeLife clock/weather/crafting/merchant economy, camp physical master plan and resident schedules, role-compatible worker records, streamed terrain/water and logical coordinates, existing horse animations, map rendering, versioned saves and the Phase 5 UI theme.

The player is a layered LPC AnimatedSprite3D, not a skeleton. Quaternius UAL2 Standard includes farming clips but no fishing clips. Its skeletal clips cannot be directly retargeted to this character; any adapted tool motion will be credited accurately. The animated horse is already available locally.

Implementation will extend existing systems. Personal profession progress remains separate from combat XP and worker levels. Production uses the existing world clock and persistent camp records; unloaded camps and mounts will not run full actor simulation. New features must preserve old world resource identities, save migration, camera controls and origin shifting.
