# Enterable buildings

ValeInteriors owns one active room. The existing exterior architecture and crypt/expedition systems remain in place. Enterable doors use E, a short black fade, physical room creation, player placement and fade-in. Returning restores the exact logical exterior address and camera orbit, pitch and zoom; nearby ground is loaded before the view is revealed. Time, weather, inventory and quest state continue across the transition.

## Building records

Stable IDs have the form settlement_id/building/index. Each record stores ID, settlement, template, title and exterior door address (decimal-string logical chunk coordinates plus a bounded local offset). Resident records refer to the building IDs for home, work and tavern. State.interior_data.active holds the building record, exterior return address and exterior camera settings. Household storage is keyed by building_id/storage.

Rooms occupy reserved local space at x=3000, independent of enormous world coordinates. This is a separate instantiated scene tree, not a seamless copy hidden inside each exterior. Outdoor chunk and authored-hub processing is suspended while indoors. Only the current room, its furnishings and current occupants are instantiated. Exit synchronously rebuilds the destination streaming window; leaving releases the previous room. Saving indoors and loading in a fresh process recreates the same template before play resumes.

## Templates

| Template | Distinct content |
| --- | --- |
| House | Beds, reading table/books, chairs, cabinet, food/drink props, hearth and household chest |
| Shop | Counter, mixed stock crates, apples, sacks, shelves and resident merchant |
| Blacksmith | Anvil/log, workbench, whetstone, real tools, forge recipes and Bram or the local smith |
| Tavern | Tables, mugs, plates, chairs, counter/barrels, hearth, bartender and evening patrons |
| Alchemist | Bottles, potion, cauldron, supplies, alchemy recipes and resident alchemist |

Five Willowmere doors use all five templates. Procedural settlements have a general shop, local specialist, tavern and farmhouse. Building ID deterministically varies rug colors and decoration choices. Imported furnishings are selected from Quaternius Fantasy Props MegaKit Standard (CC0); this coherent medieval selection was used instead of importing an unrelated modern interior set. Beds and work/rest anchors support residents who live in their workplace. Shelves, chairs and tables have meaningful placement; solid furniture and walls constrain movement. Blocking walls participate in the existing camera hiding system.

Warm local lights, a hearth and reduced outdoor fog create room lighting. Quiet dish sounds distinguish taverns, metal work distinguishes forges, water/bubbling suggests the alchemist, and wooden footsteps/room foley accompany homes. The existing project music continues. Only the active room emits these cues.

## Storage and occupants

The native household chest page deposits or withdraws one item at a time. Quest items and equipped items are excluded from deposit. Counts persist in the save and are validated on read. A chest belongs to its building, so storage does not follow the player into a different house.

Residents are reconstructed from persistent identity and current global schedule. Initial occupants start at their activity; new arrivals walk from the doorway to a free anchor. Departing occupants walk to the door. Anchors reserve Bed, Chair, TavernSeat, Market, Bookshelf, Workbench, Forge or Cauldron positions; only one resident claims an anchor. A shared obstacle grid provides paths. Sleep, work and rest transitions update while the room stays loaded.

F4 lists building IDs and offers enter, exit and reload commands. E remains the ordinary player flow. Interior boundaries, fade, camera, floor, storage and fresh-process return are covered by the included tests.
