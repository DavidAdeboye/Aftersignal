extends Interactable
class_name ChapterExit

@export_file("*.tscn") var next_scene_path: String

func _ready() -> void:
	prompt_text = "Press E to cycle the airlock"

func interact(player: Node = null) -> void:
	# Act 1 uses the shared clue chain rather than the later chapter-record
	# counter. Keep the airlock locked until the player has followed the route.
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path.ends_with("landing_bay.tscn"):
		var required_steps := ["roster", "keypad", "missing_room", "research_logs"]
		var missing: Array[String] = []
		for step in required_steps:
			if not PuzzleState.is_act1_step_complete(step):
				missing.append(step)
		if not missing.is_empty():
			_notify(player, "AIRLOCK LOCKED\n\nFinish these steps first:\n" + "\n".join(missing) + "\n\nFollow the marked clues.")
			return
	var wing := get_parent()
	if wing and wing.has_method("can_exit") and not wing.can_exit():
		_notify(player, "AIRLOCK LOCKED: Recover all three station records in this section.")
		return
	if next_scene_path.is_empty():
		_notify(player, "GAME COMPLETE\n\nYour choice has been recorded. Returning to the main menu...")
		await get_tree().create_timer(4.0).timeout
		if is_inside_tree():
			get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
		return
	if not ResourceLoader.exists(next_scene_path):
		_notify(player, "AIRLOCK ERROR: Destination scene is unavailable.")
		return
	if not multiplayer.has_multiplayer_peer():
		_notify(player, "ACT 1 COMPLETE\n\nYou found the crew list, the missing room, and Dr. Farrow's warning. The Research Labs are ahead.")
		_change_level(next_scene_path)
	elif multiplayer.is_server():
		_notify(player, "ACT 1 COMPLETE\n\nYou found the crew list, the missing room, and Dr. Farrow's warning. The Research Labs are ahead.")
		_change_level.rpc(next_scene_path)


@rpc("any_peer", "call_local", "reliable")
func _change_level(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
