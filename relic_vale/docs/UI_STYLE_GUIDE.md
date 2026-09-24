# Interface style guide

One primary UI family: Kenney UI Pack RPG Expansion, recolored through reusable StyleBoxTexture tinting. Palette: deep teal panels, desaturated green buttons, warm ivory text (#f4edd8), muted sage (#a5b8b0), gold accents (#dcc184). Avoid glossy gradients. Focus is a visible gold outline; hover/press and disabled states use the same family.

Theme: assets/ui/phase5/vale_theme.tres, reproducible with tools/build_ui_theme.gd. Rubik 16 for body, 26 for headings, 14 for secondary text. Press Start 2P 10 for short captions and rarity labels. Both bundled under SIL OFL; Latin, Cyrillic, numbers and punctuation verified. Rubik distance-field import supports scaling; Press Start 2P retains pixel-font import. Body text is never drawn into the pixelated 3D buffer.

Controls use container layout with 12 px flow spacing, 14 px horizontal/9 px vertical frame padding. Modal windows have 30 px canvas margins; main/pause menus use a narrow left column over the live village. Dialogue sits in the lower 38% of the view. Long content scrolls vertically. UI scale supports 80–150%. Native controls preserve keyboard Tab/Enter focus. Important status uses written labels as well as color.

Icons: 128×128 sources; inventory cells 66 px, detail art 88 px, hotbar icons 30 px, recipe icons 64 px. Drummyfish CC0 Fantasy RPG Icons provide painted equipment/ability icons. tools/ItemIconRenderer.tscn renders missing material thumbnails from actual imported scenery using a fixed orthographic camera/light, transparent background and 128×128 output. Source licenses follow the corresponding CC0 meshes. These images can be regenerated without a network service.

ValeInterface provides text, row, column, scroller, button, option and icon helpers. ValeInventoryPage, ValeJourneyPages, ValeEconomyPages and ValeMenuPages build reusable screens. ValeHUD retains the gameplay-facing API so quests, dialogue, combat and interactions continue to use the existing signals. Hidden legacy helper code remains for compatibility and stat formatting; normal players see the new pages.

Screens: title, pause, new world/name/seed/randomization, three save slots with metadata, loading, credits, settings (five tabs), HUD/hotbar, inventory/filter/sort/equipment comparison, appearance, abilities, quest/faction/side journal, trade Buy/Sell, crafting, shrine/reveal and discovered atlas. Boss/nameplate text uses the same body font. Subtle hover/click/equip sounds reuse the credited audio pipeline.
