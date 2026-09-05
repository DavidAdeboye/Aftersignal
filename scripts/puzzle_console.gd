extends Interactable
class_name PuzzleConsole

@export var action_id := "action"
@export var console_title := "CONTROL CONSOLE"

func _ready() -> void:
	prompt_text = "Press E to use " + console_title.to_lower()

func interact(player: Node = null) -> void:
	var wing := get_parent()
	if wing and wing.has_method("puzzle_action"):
		wing.puzzle_action(action_id, player)
