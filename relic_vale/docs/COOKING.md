# Cooking — Phase 8

Use a physical cooking station and select a recipe through the existing crafting interface. Campfire meals are available at the starting village and owned camp. A cooking pot is installed at camp tier 2; a kitchen is installed at tier 4. Player homes and taverns also contain kitchens. Recipes require the matching station within three metres, all ingredients and the listed Cooking level.

| Recipe | Level | Station | Ingredients | Heal HP | Food effect | XP |
| --- | --- | --- | --- | --- | --- | --- |
| Grilled fish | 1 | campfire | Any fish ×1 | 20 | gather speed +5% / 132 game minutes | 14 |
| Perch skewer | 1 | campfire | Sun perch ×1, wood ×1 | 25 | max hp +8 / 132 game minutes | 14 |
| Roast meat | 1 | campfire | Game meat ×1 | 30 | damage percent +5% / 132 game minutes | 14 |
| Roast carrot | 1 | campfire | Carrot ×2 | 18 | move percent +4% / 132 game minutes | 14 |
| Forest bites | 1 | campfire | mushroom ×2 | 18 | profession xp +5% / 132 game minutes | 14 |
| Beet broth | 3 | campfire | Beet ×2, wild herb ×1 | 22 | max hp +10 / 156 game minutes | 18 |
| Herb carp | 5 | cooking pot | Pond carp ×1, wild herb ×1 | 32 | fishing luck +8% / 180 game minutes | 22 |
| River stew | 5 | cooking pot | Golden dace ×1, Carrot ×1 | 35 | gather speed +8% / 180 game minutes | 22 |
| Hunter soup | 5 | cooking pot | Game meat ×1, mushroom ×2 | 40 | max hp +15 / 180 game minutes | 22 |
| Corn chowder | 6 | cooking pot | Corn ×2, Beet ×1 | 30 | profession xp +8% / 192 game minutes | 24 |
| Berry bread | 7 | cooking pot | Berries ×2, Corn ×1 | 25 | move percent +6% / 204 game minutes | 26 |
| Peppered loach | 8 | cooking pot | Mud loach ×1, Sunpetal ×1 | 38 | damage percent +8% / 216 game minutes | 28 |
| Garden pot | 8 | cooking pot | Carrot ×1, Beet ×1, mushroom ×1 | 35 | max hp +18 / 216 game minutes | 28 |
| Bamboo broth | 10 | cooking pot | Bamboo shoots ×2, wild herb ×1 | 35 | fishing luck +12% / 240 game minutes | 32 |
| Apple glazed roast | 10 | cooking pot | Apple ×2, Game meat ×1 | 45 | gather speed +10% / 240 game minutes | 32 |
| Ruby fillet | 11 | cooking pot | Ruby fin ×1, Heartleaf ×1 | 40 | damage percent +10% / 252 game minutes | 34 |
| Prickly pear tea | 12 | cooking pot | Prickly pear ×2, River mint ×1 | 30 | move percent +8% / 264 game minutes | 36 |
| Moon koi soup | 15 | kitchen | Moon koi ×1, Night bloom ×1 | 55 | fishing luck +18% / 300 game minutes | 42 |
| Mist supper | 15 | kitchen | Mist darter ×1, Bamboo shoots ×1 | 50 | profession xp +12% / 300 game minutes | 42 |
| Harvest pie | 16 | kitchen | Apple ×1, Berries ×1, Corn ×2 | 50 | max hp +25 / 312 game minutes | 44 |
| River giant feast | 18 | kitchen | River giant ×1, Carrot ×2 | 60 | gather speed +14% / 336 game minutes | 48 |
| Elderwood roast | 20 | kitchen | Game meat ×2, Dawn flower ×1, Beet ×1 | 65 | damage percent +14% / 360 game minutes | 52 |
| Lantern bisque | 22 | kitchen | Lantern fish ×1, Sunpetal ×1 | 70 | profession xp +15% / 384 game minutes | 56 |
| Dawn banquet | 25 | kitchen | Dawn mandarin ×1, Dawn flower ×1, Apple ×2 | 80 | fishing luck +22% / 420 game minutes | 62 |

Grilled fish accepts any caught species and selects the lowest-value carried fish; the crafting UI shows the actual ingredient before cooking. Other fish recipes require their named species. Harvest pie and Elder roast additionally require recipe knowledge, purchased from general/tavern merchants; treasure caches can teach Harvest pie.

Use cooked food from the inventory. It heals immediately and applies **one active food effect** until its game-clock deadline. Eating another meal replaces the old effect, including the same meal, so repeated use cannot stack bonuses. Possible effects improve health, damage, movement, gathering speed, fishing odds or profession XP. Expiry recalculates stats. The active meal and remaining game-clock deadline survive saving and loading.

Fish, harvested crops, herbs and raw meat connect gathering/fishing/farming to cooking. Wolves can drop raw meat and Nell sells it. Existing tavern/general shops also sell a few simple meals. Prepared-food prices are bounded below the cost of buying their ingredients even under best purchase/resale modifiers, preventing a buy/cook/sell money loop.

Meal models come from Quaternius Ultimate Food (CC0). The pot and dishes are real imported props; food icons are model renders. The recipe catalogue and balance live in data/cooking.json and data/phase8_items.json.
