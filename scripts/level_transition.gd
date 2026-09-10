extends Interactable
class_name LevelTransitionDoor

## Level transition airlock door that moves connected players to the next act/scene.

@export var next_scene_path: String = "res://scenes/wings/02_research_labs/02_research_labs.tscn"
@export var is_unlocked: bool = false
@export var locked_message: String = "AIRLOCK LOCKED: Dr. Farrow's Science Lab credentials required."

func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to enter Research Labs Airlock"


func interact(player: Node = null) -> void:
	var required_steps := ["roster", "keypad", "missing_room", "research_logs"]
	var missing: Array[String] = []
	for step in required_steps:
		if not PuzzleState.is_act1_step_complete(step):
			missing.append(step)
	if not missing.is_empty():
		_notify(player, "AIRLOCK LOCKED\n\nStill required: " + ", ".join(missing) + "\n\nFollow the objective banner and inspect each marked terminal after solving a puzzle.")
		return
	_notify(player, "Airlock Cycling... Transitioning to Research Labs.")

	if not multiplayer.has_multiplayer_peer():
		change_level_rpc(next_scene_path)
	elif multiplayer.is_server():
		change_level_rpc.rpc(next_scene_path)


@rpc("any_peer", "call_local", "reliable")
func change_level_rpc(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		var local_player := NetworkManager._get_local_player()
		if local_player and local_player.has_method("show_message"):
			local_player.show_message("ACT 1 COMPLETE - Research Labs content is not installed yet.", 6.0)
