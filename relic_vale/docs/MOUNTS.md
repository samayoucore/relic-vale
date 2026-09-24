# Mounts — Phase 8

At **camp tier 3**, purchase **Bramble** for **180 copper** through the stable interaction or **P → Mounts**. Ownership is persistent. The physical stable uses Quaternius OpenBarn plus an existing water barrel. The owned horse is visible in the stall while stabled and the camp is loaded.

**V** calls the horse onto clear nearby dry ground. Approach and press **E** to mount; E or V dismounts, and **Shift** gallops. The call binding can be changed to T or Y in Settings → Controls. The default controls are also displayed on the Mounts page. Walking speed is multiplied by **1.5 while riding** and **2.3 while galloping**.

The horse is the real Quaternius Ultimate Animated Animals Horse model with authored Idle, Walk and Gallop animations. The existing character remains visible, with a seated adaptation of its selected LPC appearance. The camera eases outward slightly while riding and retains Q/R orbit, right-drag orbit/limited tilt, wheel zoom and obstruction hiding.

Mounting is blocked inside buildings/dungeons, during another activity or close to combat threats. A larger mounted collision capsule uses the existing player movement and terrain collision. Attacks, abilities and gathering are blocked while mounted, including HUD buttons. Dismount searches for a clear nearby player position. Entering an interior parks the horse outside; respawn also safely parks it.

## Infinite world and saves

Mounted movement remains owned by the existing CharacterBody3D. The visual horse is parented to that player, so origin rebasing and logical teleports keep the rider together. An unmounted waiting horse is stored as a logical chunk-string address plus local coordinates; it is instantiated only near the current region and removed from the scene when far away. A nearby teleport reconstructs its render position from that address.

Save version 8 stores owned mounts, active ID, name, species, state and logical address. Saving while mounted captures the current address immediately. Loading a ridden state restores ownership in a safe stabled state; call the horse again with V. Ownership is not tied to a loaded camp scene. Billion-chunk coordinates, multi-chunk galloping, nearby/distant teleports, stabling, interior transitions and a fresh process reload are included in validation.

There is one purchasable species and one practical stall in this phase. The rider uses a seated sprite adaptation with a bareback mount; no separate saddle asset or rigged 3D rider is claimed. Horse breeding, equipment progression and mounted combat are outside this implementation.
