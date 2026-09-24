# Phase 9 baseline audit

The existing game was run in a native Godot window before implementation. The final Phase 8 integration check passed 15/15 assertions; log: downloads/phase9-baseline-audit.log. The verified 0.8 archive remains unchanged.

The supplied brief repeats the same Phase 9 specification twice. The implementation target is four authored companions, three personal quests each, a complete ten-quest first story arc, three quests for each of the existing three factions, and eight context-sensitive world events. One companion must pass the complete recruitment/combat/camp/personal-story slice before the roster expands.

Existing integration points: State.quest_data/quest_progress/completed_quests and quest_event; ValeLife faction reputation and world clock; existing dialogue and journal pages; ValeCombat/Mossling/status/projectile components; ValeResidents grid navigation; camp activity anchors; logical chunk-string addresses, streaming/origin rebasing and versioned save data.

The existing models are KayKit Adventurers 2.0 (CC0), not Quaternius RPG Characters. Knight, Ranger and Mage and their compatible General/MovementBasic skeletal clips are already imported. The local original archive also includes Rogue. Reuse this established art family and compatible animation adapter; do not duplicate the existing player or generic camp worker systems. Portraits will be rendered from the actual companion models. Existing Quaternius UAL2 Standard is available for animation adaptation where compatible.

This document records the starting audit. Implementation and final validation are documented separately in [Phase 9](PHASE_9.md), [camera/camp changes](CAMERA_AND_CAMP.md) and the release receipts.
