import fs from 'node:fs';
const root='relic_vale/scripts/';
const edit=(file,fn)=>fs.writeFileSync(root+file,fn(fs.readFileSync(root+file,'utf8').replaceAll('\r\n','\n')));
edit('save/save_system.gd',s=>s.replace('"version":VERSION,','"version":VERSION,"generated_items":State.generated_items.duplicate(true),"pending_loot":State.pending_loot.duplicate(true),"abilities":State.abilities.duplicate(),"character_name":State.character_name,"appearance":State.appearance.duplicate(),"appearance_confirmed":State.appearance_confirmed,"audio_settings":State.audio_settings.duplicate(),'));
edit('enemy.gd',s=>s.replace('var god_mode', 'var god_mode').replace('var player:', 'var death_tween: Tween\nvar player:').replace('var fade:=create_tween()','death_tween=create_tween()').replaceAll('fade.tween','death_tween.tween').replace('fade.parallel()','death_tween.parallel()').replace('func revive() -> void:\n','func revive() -> void:\n\tif death_tween and death_tween.is_valid(): death_tween.kill()\n'));
edit('hud.gd',s=>s.replace('func show_pause() -> void:',`func show_character() -> void:
\topen_modal("character","Before the road","YOUR TRAVELER  /  C")
\tmodal_panel.position=Vector2(240,105)
\tmodal_panel.size=Vector2(800,510)
\tmodal_button.position=Vector2(30,462)
\tmodal_button.text="Keep current look"
\tmodal_text.visible=false
\tvar creation:=ValeCreation.new()
\tcreation.hud=self
\trpg.add_child(creation)

func show_pause() -> void:`).replace('J  quests   TAB  atlas   F3  debug   ESC  pause','B abilities · C looks · J quests · TAB atlas · ESC pause'));
