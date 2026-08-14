extends Node
class_name ObjectiveManager

## Manages top-of-screen narrative objective banners and syncs them across players.

signal objective_updated(text: String)

static var instance: ObjectiveManager = null
var current_objective: String = ""

func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	# Set default starting objective for Act 1
	if current_objective.is_empty():
		set_objective("OBJECTIVE: Investigate Habitation Wing & Locate Crew Manifest")


func set_objective(new_text: String) -> void:
	current_objective = new_text
	objective_updated.emit(new_text)
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		sync_objective_rpc.rpc(new_text)


@rpc("any_peer", "call_local", "reliable")
func sync_objective_rpc(new_text: String) -> void:
	current_objective = new_text
	objective_updated.emit(new_text)
