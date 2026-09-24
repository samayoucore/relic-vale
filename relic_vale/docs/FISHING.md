# Fishing — Phase 8

Buy a Willow fishing rod and bait from **Iona in Willowmere's provisions shop**, or the basic supplies from general/traveling/carpenter merchants. Equip the rod in **I → Tools → Equip to Tool**, choose bait in **P → Fishing**, stand on dry ground and face open freshwater. **E** casts when another interaction is not selected. Fish merchants also sell reinforced and Moonsteel rods.

The cast must reach genuine terrain water 2.5–6.5 metres ahead, outside the starting village footprint, with an unobstructed line from the bank. A depth check rejects dry ground and shallow road crossings. Three of four open-water samples classify a lake; narrower water is a river. This uses the streamed terrain's water field, so it also works outside the starting area.

The sequence is **cast → wait → bite → reel → catch/failure**. After the float bites, press Space/left mouse before the 2.2-second response window closes. Hold Space/left mouse to move the green catch zone right; release to move left. Keep the moving fish inside the zone to fill progress. Time outside raises tension and reduces progress. Higher difficulty needs more control. Escape, walking away/teleporting, opening another menu, stun, damage or changing tools cancels the activity. It awards nothing on cancellation.

Three bait types are consumed at cast time: dough for ordinary catches, insects for faster bites and a 25% preference for river species, and moon bait for stronger rare odds (Fishing 10 required). They do not bypass a fish's level/time/weather/water restrictions. Base selection weights are Common 1.0, Uncommon 0.4, Rare 0.16, Epic 0.045 and Legendary 0.012; insect/moon rare multipliers are 1.35 and 2.0. These are relative weights among eligible species, not fixed catch percentages. Rod tiers and personal skill widen the catch zone. Common species remain available in all weather and at all times.

## Species

| Fish | Rarity | Level | Water | Time | Weather | Weight kg | Base sell copper |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Silver minnow | Common | 1 | Any | Any | Any | 0.14–0.85 | 2 |
| Golden dace | Common | 1 | river | Any | Any | 0.14–0.85 | 2 |
| Pond carp | Common | 1 | lake | Any | Any | 0.14–0.85 | 2 |
| Sun perch | Common | 1 | Any | Any | Any | 0.14–0.85 | 2 |
| Mud loach | Common | 3 | river | Any | Any | 0.22–1.55 | 3 |
| Ruby fin | Uncommon | 5 | river | day | Any | 0.30–2.25 | 4 |
| Reed betta | Uncommon | 5 | lake | Any | Any | 0.30–2.25 | 5 |
| Blue carp | Uncommon | 6 | lake | dawn | Any | 0.34–2.60 | 5 |
| Thorn pike | Uncommon | 7 | river | Any | Rain | 0.38–2.95 | 6 |
| Amber bream | Uncommon | 8 | Any | day | Any | 0.42–3.30 | 6 |
| Moon koi | Rare | 10 | lake | night | Any | 0.50–4.00 | 11 |
| Mist darter | Rare | 10 | river | Any | Fog | 0.50–4.00 | 11 |
| Stone flatfish | Rare | 12 | river | Any | Any | 0.58–4.70 | 10 |
| Copper snapper | Rare | 12 | lake | day | Any | 0.58–4.70 | 11 |
| Elder grouper | Rare | 15 | lake | Any | Any | 0.70–5.75 | 14 |
| River giant | Rare | 15 | river | Any | Rain | 0.70–5.75 | 16 |
| Violet turbot | Epic | 17 | lake | night | Any | 0.78–6.45 | 20 |
| Lantern fish | Epic | 20 | Any | night | Fog | 0.90–7.50 | 26 |
| Storm puffer | Epic | 20 | lake | Any | Storm | 0.90–7.50 | 28 |
| Dawn mandarin | Legendary | 23 | river | dawn | Clear | 1.02–8.55 | 38 |

Day: 07:00–19:00. Night: 20:00–05:00. Dawn: 05:00–08:00. Clear/Rain/Storm/Mist conditions refer to the existing world weather. All 20 species can be grilled; specific advanced recipes require their named fish. The table gives baseline sell values; existing merchant/reputation rules determine actual quotes.

The journal records caught species, count, largest weight/size, day, water type and logical location. Uncaught entries use the existing unknown-icon treatment. Catch results can also include a waterlogged boot, message bottle, chart fragments or a treasure chart. Three fragments can be assembled in **P → Exploration**. Charts mark approximate search areas on the atlas; caches reward only once.

## Assets and simulation

Quaternius Cute Fish Pack supplies 20 real fish models, three rods and lure models (CC0). Two nearby animated Tetra models use the pack's Swimming_Normal clip only while fishing; they are removed when the activity ends. The float and line are actual world objects. Catch/journal icons are transparent renders of the supplied models. Fantasy species names and ecology are game definitions rather than biological claims.

The player retains directional LPC sprites. The held rod follows normalized upper-arm pitch from Quaternius UAL2 Standard's OverhandThrow clip, adapted to the existing hand-prop system. This is a casting adaptation, not a fully retargeted humanoid fishing animation; the free Standard pack does not contain a dedicated fishing clip. Attribution and transformations are recorded in [asset credits](ASSET_CREDITS.md).
