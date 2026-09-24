# Camera and camp changes before Phase 10

## Controls and appearance

Hold the right mouse button and drag vertically, or hold Page Up / Page Down, to change the outdoor angle from 60° down to 18°. Q/R and horizontal right drag orbit; the wheel zooms. Home restores 50°, the original orbit direction and zoom. The camera uses a 50° perspective field of view; its distance preserves the old visible height at the traveler's focus plane. Interiors clamp the actual angle to at least 40° while retaining the chosen outdoor angle for the return trip. Mounted framing still expands smoothly.

The lowest angle exposes sky above the horizon. Haze reaches full opacity before the closest missing terrain tile, measured around the traveler. It accounts for tiles still under construction, all quality presets and floating-origin changes. Newly loaded terrain emerges gradually; lowering draw distance retains a finite limit even when extra old chunks are still cached. Sky and fully fogged geometry share the same color for each viewing direction, with day/night colors, concealing the edge instead of showing a hard cutoff.

Near foreground geometry receives a small Gaussian blur, strongest at low angles. The sharp focus region includes the player; the HUD lives outside the 3D viewport and stays sharp. The shader uses the scene depth buffer and works with the bundled OpenGL Compatibility renderer. Transparent particles draw after this opaque-scene effect. The implementation follows Godot's [depth-buffer post-processing guidance](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html).

Scenery no longer disappears along the line from the camera to the hero. Only entry of the camera eye into an eligible visual mesh triggers hiding. Mesh bounds provide a quick first check; triangle crossings distinguish the occupied volume from empty canopy corners. The visual returns when the eye exits, without changing the object's physical collision. A depleted resource stays depleted. Wind deformation is small and its containment uses the undeformed source mesh.

The supplied image guides the camera angle and foreground softness. This change retains the project's existing art and interface assets.

## Establishing camp

G opens camp management. Choose a site, move until the future hamlet boundary is green, then press Enter. Escape cancels.

Trees, harvestable rocks, bushes, logs and small natural decoration are cleared from the 34 × 34 metre future hamlet, including a 3 metre natural-scenery margin. Clearance removes scenery and trunk/rock collision, creates permanent depletion records for harvestables, and reserves the area during subsequent chunk generation. Grass and batched decoration are regenerated outside the reserve. It grants no gathering loot or profession experience.

Houses, village structures, crypt entrances, other landmarks and established narrative sites block placement. Unrecognized structural collisions are protected by default. Roads, water and steep terrain retain their placement restrictions. Validation happens before any clearance, so a rejected placement leaves all objects intact. No camp relocation or demolition feature is added.

## Horse

Reach camp tier 3, then open P → Mounts and buy a horse for 180 copper. V calls it. Approach and press E to mount; Shift gallops; E dismounts. Mounting is unavailable during nearby combat. A remapped call key is shown in the preferences and mount controls.

## Verification

Run --phase9-camera in the actual game for horizon projection, all draw-distance presets, floating-origin and incomplete-chunk coverage, camera/hero separation, curved-volume containment, rendered near/focus blur comparisons, protected structures and physical camp clearance. Run --phase9-camera-reload separately for a fresh load and sixty days of regrowth checks. The fixture is isolated from the personal journey. Screenshots and individual test receipts are in this docs folder; [Phase 9](PHASE_9.md) describes the broader narrative validation.
