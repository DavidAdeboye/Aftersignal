extends Interactable
class_name ChapterExit

@export_file("*.tscn") var next_scene_path: String

func _ready() -> void:
	prompt_text = "Press E to cycle the airlock"

func interact(player: Node = null) -> void:
	var wing := get_parent()
	if wing and wing.has_method("can_exit") and not wing.can_exit():
		_notify(player, "AIRLOCK LOCKED: Recover all three station records in this section.")
		return
	if next_scene_path.is_empty():
		_notify(player, "AFTERSIGNAL COMPLETE\n\nThe station falls quiet. Your final choice remains in the signal.")
		return
	if not ResourceLoader.exists(next_scene_path):
		_notify(player, "AIRLOCK ERROR: Destination scene is unavailable.")
		return
	if not multiplayer.has_multiplayer_peer():
		_change_level(next_scene_path)
	elif multiplayer.is_server():
		_change_level.rpc(next_scene_path)


@rpc("any_peer", "call_local", "reliable")
func _change_level(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
