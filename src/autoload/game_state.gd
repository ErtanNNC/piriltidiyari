extends Node
## The running game's single PlayerData plus helpers the scenes share.

signal dialogue_requested(npc_id: String)
signal lines_requested(lines: Array, then: Dictionary)
signal dialogue_closed
signal shop_requested(shop_id: String)
signal toast(text: String, icon: String)

var data := PlayerData.new()
## True while a dialogue box is open: mobs and bosses hold their attacks,
## because the player can't move then.
var in_dialogue := false
## Timed potion buffs: name → the `clock` time they end. Kept here, not on the
## Player, so a potion goes on through a house door or a boat trip (both
## rebuild the Player). Belongs to one PlayerData: emptied when `data` is
## replaced (new game, another save, Bölüm seç).
var buffs := {}
var _buffs_for: PlayerData
## Pus Kovucu: mobs notice you from much closer until this time (seconds).
var repel_until: float:
	get: return buff_until("kovucu")
	set(v): set_buff_until("kovucu", v)
## Game seconds: stands still in Mola, on the level-up cards and while
## someone talks, so a potion never runs out behind a panel.
var clock := 0.0


func _process(delta: float) -> void:
	if not get_tree().paused and not in_dialogue:
		clock += delta
	_own_buffs()


func _own_buffs() -> void:
	if _buffs_for != data:
		_buffs_for = data
		buffs.clear()


## The game-clock time a potion buff ends (0 = not running).
func buff_until(buff: String) -> float:
	_own_buffs()
	return float(buffs.get(buff, 0.0))


func set_buff_until(buff: String, until: float) -> void:
	_own_buffs()
	buffs[buff] = until


## Multiplier for how far mobs notice the player (Pus Kovucu → 0.4).
func notice_factor() -> float:
	return 0.4 if clock < repel_until else 1.0


## Await this before an attack: returns when no dialogue is open.
func wait_dialogue_closed() -> void:
	while in_dialogue:
		await get_tree().process_frame


## Asks the HUD to open an NPC's current conversation.
func talk_to(npc_id: String) -> void:
	dialogue_requested.emit(npc_id)


## Plays a short monologue from content/<chapter>/barks.json.
func bark(bark_id: String, then := {}) -> void:
	var lines: Array = Content.barks.get(bark_id, [])
	if lines.is_empty():
		push_warning("GameState: bark yok %s" % bark_id)
		return
	lines_requested.emit(resolve_speakers(lines), then)


## "oyuncu" in content means whoever the player is (Fıstık or the keeper).
func resolve_speakers(lines: Array) -> Array:
	var out := []
	for l: Dictionary in lines:
		if l.get("speaker", "") == "oyuncu":
			l = l.duplicate()
			l["speaker"] = data.character_id
		out.append(l)
	return out


## A world event: "defeat" + mob kind, "reach" + area id, "talk" + npc id.
func notify(event_type: String, target: String) -> void:
	data.notify(event_type, target, Content.quests)


func apply_dialogue_effects(then: Dictionary) -> void:
	var events := DialogueRules.apply(then, data, Content.quests)
	for e in events:
		if e.begins_with("item:"):
			var id := e.substr(5)
			toast.emit(TranslationServer.translate("%s ×%d aldın") % [Content.item_name(id), int(then["give_items"][id])], "piril")
			continue
		if e == "stones":
			toast.emit(TranslationServer.translate("Hikâye Taşları: %d/%d") % [data.item_count("hikaye_tasi"), PlayerData.STORY_STONES], "star")
			continue
		if e.begins_with("shop:"):
			shop_requested.emit(e.substr(5))
			continue
		if e.begins_with("goto:"):
			SceneFlow.go_to(e.substr(5))
			continue
		match e:
			"quest_started":
				toast.emit(TranslationServer.translate("Yeni görev: %s") % TranslationServer.translate(Content.quests[then["start_quest"]]["title"]), "quest")
			"quest_completed":
				toast.emit("Görev tamam!", "star")
			"delivered":
				toast.emit(TranslationServer.translate("%s teslim edildi") % Content.item_name(then["deliver"]["item"]), "lantern")


## The quest the HUD tracker shows: the first active/ready one.
## The quest shown on the HUD: an open quest of the chapter that is loaded,
## in the chapter's order (main quest first). A side quest left open in
## another chapter has no text here, so it is skipped instead of leaving an
## empty panel.
func tracked_quest() -> String:
	return data.tracked_quest(Content.quests)
