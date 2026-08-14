extends Interactable
class_name ReadableLog

## A physical note/notepad the player picks up and reads in a dedicated
## full-screen reading panel, instead of a quick HUD popup. Stays in the
## world after reading unless remove_after_read is enabled.

@export var log_title: String = "RESEARCH LOG"
@export var next_objective: String = ""
@export var remove_after_read: bool = false


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to pick up and read"


func interact(player: Node = null) -> void:
	if player and player.has_method("show_reading_panel"):
		player.show_reading_panel(log_title, message)
	else:
		_notify(player, message)

	if next_objective != "" and ObjectiveManager.instance:
		ObjectiveManager.instance.set_objective(next_objective)

	if remove_after_read:
		queue_free()
