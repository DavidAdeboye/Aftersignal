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
	if not PuzzleState.is_act1_complete():
		_notify(player, "AIRLOCK LOCKED: Complete the Wing 1 investigation and puzzles first.")
		return
	if not is_unlocked:
		_notify(player, locked_message)
		return
		
	_notify(player, "Airlock Cycling... Transitioning to Research Labs.")
	
	if multiplayer.is_server():
		change_level_rpc.rpc(next_scene_path)


@rpc("any_peer", "call_local", "reliable")
func change_level_rpc(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		var local_player := NetworkManager._get_local_player()
		if local_player and local_player.has_method("show_message"):
			local_player.show_message("ACT 1 COMPLETE - Research Labs content is not installed yet.", 6.0)
