# Narrative architecture and content

Phase 9 extends the existing quest ledger, State signals, interactables, factions and journal. It adds no competing reputation or quest database. Authored content is in eight JSON files under `data/narrative/`: companions, quests, dialogue, locations, contacts, items, lore and events. Stable object/quest/dialogue IDs support future localization; this build's text is English.

## Quest stages

There are 35 added quests: four recruitment quests, twelve personal chapters, ten Act I chapters and nine faction chapters. A narrative quest uses the existing integer `quest_progress[id]` as its current stage. Stages support talk, interact, defeat, reach, collect, camp, recruit and choice objectives. `State.objective_event` feeds `ValeNarrative.on_event`; completion claims the existing quest reward once, then applies authored effects. Reconciliation recognizes already defeated unique enemies, inspected objects, collected materials, an established camp or a recruited companion, so exploring early cannot strand a quest.

The journal has Main, Companion, Faction, Side, Active and Completed views. It shows current stage text and personal chain counts. Track selects one primary narrative marker; Show on map selects that quest and centers its canonical location. Unstarted future narrative titles remain hidden. Side tasks from the original game remain available through the village conversation.

## Act I: the lantern covenant

The old road lights are failing because a freely witnessed oath was copied without its right of release. Rowan asks the traveler to investigate. Elowen and three faction contacts supply competing accounts. The journey uses exploration, recruitment, camp provisions, repairs, the existing multi-room crypt/boss and a defended crossing before a final charter.

| Chapter | Quest | Objective sequence |
| --- | --- | --- |
| 1 | The Lantern That Went Cold | interact → talk |
| 2 | A Name Beneath the Moss | interact → talk |
| 3 | Company for the Road | recruit → talk |
| 4 | Three Promises | talk → talk → talk → talk |
| 5 | Room on the Road | choice |
| 6 | A Fire That Stays | camp → choice |
| 7 | The Oath Beneath Stone | defeat |
| 8 | The Borrowed Dawn | interact → talk |
| 9 | Night on the Road | defeat → defeat → defeat → interact |
| 10 | Whose Light Is It? | choice |

The road policy supports either Compact oversight or Warden access with reputation tradeoffs. The ending can distribute the light to settlements, place it under a central charter, or establish joint witnesses if all three factions have sufficient standing. Persistent flags select epilogue text and physical location variants. The first act is complete; further acts are future content.

## Dialogue

49 authored dialogue nodes contain speaker, text, ordered choices, conditions, effects, next node and personality tags. Conditional text variants react to resolved story/events. The UI shows speaker portraits for companions, requirement reasons, choices and a bounded recent-conversation history.

Conditions: flag, recruited companion, active companion, approval threshold, completed/not-completed/not-started quest, exact stage, profession level, faction reputation, carried item, camp tier, being at camp and defeated unique enemy. Effects: start quest, emit objective event, set flag, adjust approval/reputation, grant/consume item, recruit, unlock lore, grant coins. Consequential terminal nodes are locked after resolution, including stale-panel attempts. Camp conversations require physical camp proximity.

## Factions and consequences

Hester Vane (Lantern Compact), Warden Yew (Elderbough Wardens) and Orsa Venn (Keepers of the Veil) meet at Three Promises. Each offers three authored tasks. Stores/bridges, waterways/game trails and the corrected oath lead to different charter choices. These preserve competing practical interests. Completion adds reputation and an accord unlock. At Friendly standing (30+), existing merchants of that faction sell a signature accessory; hostile merchants refuse trade. Existing reputation price discounts remain in effect.

Authored sites have stable IDs and seed-deterministic canonical addresses. New placement searches for dry ground with enough space; existing saved addresses remain unchanged. Streaming creates/removes only presentation. Quest objects retain their inspected flags and unique enemies remain defeated. Cinder Watch, Reed Pass, the archive, well and crossing reconstruct their chosen variants from flags. The procedural terrain seed and base-generation random stream are untouched.

People, Factions, Places, Creatures, Relics and History entries unlock from meetings, exploration and quests. The lore screen filters these categories. Entries are concise and support the conversations.

## Save and tools

Version 9 adds `narrative` to the existing snapshot. Faction reputation, stock and unlocks stay in `life`; quest progress and completed rewards use their original fields. Validation rejects malformed identities, equipment slots, nonfinite/bad ranges, unknown events and invalid logical addresses. Versions 2–8 remain readable.

F10 can start/advance/complete/reset quests, inspect/set flags, set relationship and reputation tiers, and visit objectives. Reset is a developer operation; it does not reverse inventory rewards or every related world flag. Narrative source generation is `tools/phase9_content.mjs`; the earlier first-companion generator is an audit artifact and must not be rerun over expanded content.
