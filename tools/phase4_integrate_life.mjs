import fs from 'node:fs';
function edit(file,changes){let s=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');for(const [a,b] of changes){if(!s.includes(a))throw Error(file+' missing '+a.slice(0,80));s=s.replace(a,b);}fs.writeFileSync(file,s);}
edit('relic_vale/scripts/game_state.gd',[
 ['var hp: int = 100','var life_data: Dictionary=ValeLife.defaults()\nvar faction_data: Dictionary={}\nvar merchant_data: Dictionary={}\nvar crafting_data: Dictionary={}\nvar hp: int = 100'],
 ['func reset_progress(seed_value: int) -> void:','func reset_progress(seed_value: int) -> void:\n\tlife_data=ValeLife.defaults()'],
 ['\trecalculate()\n\nfunc stats','\tquest_data.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/quest_chains.json")))\n\tfaction_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/factions.json"))\n\tmerchant_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/merchants.json"))\n\tfor recipe in JSON.parse_string(FileAccess.get_file_as_string("res://data/crafting.json")): crafting_data[recipe.id]=recipe\n\trecalculate()\n\nfunc stats'],
 ['if not quest_progress.has(id) and not completed_quests.has(id): quest_progress[id]=0','if not quest_data[id].has("chain") and not quest_progress.has(id) and not completed_quests.has(id): quest_progress[id]=0'],
 ['if claim_quest(id): rewards.append(quest_data[id].name)','if not quest_data[id].has("chain") and claim_quest(id): rewards.append(quest_data[id].name)'],
 ['\tgain_xp(int(q.reward.xp))\n\treturn true','\tgain_xp(int(q.reward.xp))\n\tif q.reward.has("faction"):\n\t\tvar faction: String=q.reward.faction\n\t\tlife_data.reputation[faction]=clampi(int(life_data.reputation.get(faction,0))+int(q.reward.reputation),-100,100)\n\t\tif not q.reward.get("unlock","").is_empty(): life_data.unlocks[q.reward.unlock]=true\n\treturn true'],
 ['\tquest_event("talk",id)\n\tif id=="rowan":','\tquest_event("talk",id)\n\tvar chain_rewards: Array[String]=ValeLife.quest_talk(id)\n\tif not chain_rewards.is_empty(): notification.emit("Completed: "+", ".join(chain_rewards))\n\tif id=="rowan":'],
 ['conversation.emit(npc.name+" · "+npc.role,npc.dialogue)','var message: String=npc.dialogue\n\tif npc.has("category"):\n\t\tvar faction: String=merchant_data[npc.category].faction\n\t\tmessage+="\\n\\n"+faction_data[faction].name+" · "+ValeLife.tier(ValeLife.reputation(faction))+" ("+str(ValeLife.reputation(faction))+")"\n\tfor qid in quest_progress:\n\t\tif quest_data[qid].get("npc","")==id and not completed_quests.has(qid): message+="\\n\\n"+quest_data[qid].name+": "+quest_data[qid].description\n\tconversation.emit(npc.name+" · "+npc.role,message)']
]);
edit('relic_vale/scripts/main.gd',[
 ['var loot_manager: ValeLootManager','var life: ValeLife\nvar expedition: ValeExpedition\nvar loot_manager: ValeLootManager'],
 ['\tworld.add_child(generator)','\tworld.add_child(generator)\n\tlife=ValeLife.new()\n\tworld.add_child(life)\n\texpedition=ValeExpedition.new()\n\tworld.add_child(expedition)'],
 ['\t\tvar d: float=player.global_position.distance_to(candidate.global_position)','\t\tif not candidate.is_visible_in_tree(): continue\n\t\tvar d: float=player.global_position.distance_to(candidate.global_position)'],
 ['\tgenerator.regenerate(State.world_seed)\n\tfor enemy','\tgenerator.regenerate(State.world_seed)\n\tif position.x>1500 and not State.life_data.dungeons.get("active",{}).is_empty(): expedition.generate(State.life_data.dungeons.active.id,State.life_data.dungeons.active.theme)\n\tfor enemy']
]);
edit('relic_vale/scripts/save/save_system.gd',[
 ['const VERSION: int=3','const VERSION: int=4'],
 ['return {"version":VERSION,','return {"life":State.life_data.duplicate(true),"version":VERSION,'],
 ['not in [2,VERSION]','not in [2,3,VERSION]'],
 ['for key in ["generated_items","pending_loot","appearance","audio_settings"]','for key in ["life","generated_items","pending_loot","appearance","audio_settings"]'],
 ['\tState.level=clampi(int(data.level),1,100)','\tvar life: Dictionary=data.get("life",{})\n\tfor key in ["reputation","unlocks","stock","dungeons","settlements","events"]:\n\t\tif life.get(key,{}) is Dictionary: State.life_data[key]=life.get(key,State.life_data[key]).duplicate(true)\n\tfor faction in State.faction_data: State.life_data.reputation[faction]=clampi(int(State.life_data.reputation.get(faction,0)),-100,100)\n\tState.life_data.minute=clampf(float(life.get("minute",540)),0,1439.99)\n\tState.life_data.day=maxi(1,int(life.get("day",1)))\n\tState.life_data.weather=life.get("weather","Clear") if life.get("weather","Clear") in ValeLife.WEATHER else "Clear"\n\tState.life_data.weather_block=int(life.get("weather_block",-1))\n\tState.level=clampi(int(data.level),1,100)'],
 ['\tif pos.x>=992','\tif pos.x>=1990 and pos.x<=2150 and pos.z>=-100 and pos.z<=100: return Vector3(pos.x,clampf(pos.y,-2,8),pos.z)\n\tif pos.x>=992'],
 ['return Vector3(pos.x,clampf(pos.y,0,3),pos.z)\n\treturn Vector3(0,0,3.6)','return Vector3(pos.x,clampf(pos.y,-3,20),pos.z)\n\treturn Vector3(0,0,3.6)']
]);
edit('relic_vale/scripts/interactable.gd',[
 ['"resource": return "Gather silverleaf" if not State.gathered_resources.has(persistent_id) else "Silverleaf gathered"','"resource": return "Gather "+title if not State.gathered_resources.has(persistent_id) else title+" gathered"\n\t\t"station": return "Use "+title\n\t\t"dungeon": return "Enter "+title'],
 ['if npc_id in ["smith","merchant"]:','if State.npc_data.get(npc_id,{}).get("shop",false):'],
 ['\t\t"chest":\n\t\t\tif State.open_chest():','\t\t"station": ValeLifeMenus.open_crafting(get_tree().current_scene.hud,self)\n\t\t"dungeon": get_tree().current_scene.expedition.enter(persistent_id,get_meta("theme","crypt"))\n\t\t"chest":\n\t\t\tif State.open_chest():'],
 ['\t\t\tState.add_item("wild_herb")\n\t\t\tState.notification.emit("Silverleaf gathered  ·  +1 herb")','\t\t\tvar item: String=get_meta("resource","wild_herb")\n\t\t\tvar amount: int=2 if item=="wild_herb" and State.life_data.weather=="Rain" else 1\n\t\t\tState.add_item(item,amount)\n\t\t\tState.notification.emit(title+" gathered  ·  +"+str(amount))\n\t\t\tif is_instance_valid(model): model.scale*=.65\n\t\t\tState.save_requested.emit()']
]);
edit('relic_vale/scripts/ui/rpg_menus.gd',[
 ['func quests() -> void:\n','func quests() -> void:\n\tValeLifeMenus.open_journal(hud)\n\nfunc legacy_quests() -> void:\n'],
 ['func shop(npc_id: String) -> void:\n','func shop(npc_id: String) -> void:\n\tValeLifeMenus.open_shop(hud,npc_id)\n\nfunc legacy_shop(npc_id: String) -> void:\n'],
 ['elif item.kind=="consumable": button("Drink  ·  +45 HP",Vector2(395,459),Vector2(260,36),State.drink_tonic)','elif item.kind=="consumable": button("Use  ·  +%d HP" % int(item.get("heal",0)),Vector2(395,459),Vector2(260,36),func(): ValeLife.use_item(selected); inventory())']
]);
