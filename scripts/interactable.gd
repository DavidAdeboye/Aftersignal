extends Node3D
class_name Interactable

## Base class for anything the player can interact with —
## logs, terminals, buttons, pickups. Attach a script that
## extends this to any object, and override interact().
##
## The player passes itself into interact() so the interactable can
## surface feedback on the player's HUD via player.show_message().

## Text shown in the "Press E to interact" prompt while looking at this object.
@export var prompt_text: String = "Press E to interact"

## Optional multiline text shown on the player's HUD when interacted with.
@export_multiline var message: String = ""


func interact(player: Node = null) -> void:
	# Default behavior: show the configured message on the player's HUD.
	# Override in child scripts/scenes for custom behavior.
	if message != "":
		_notify(player, message)
	else:
		print("Interacted with: ", name)


## Helper — routes a message to the interacting player's HUD if possible,
## otherwise falls back to a console print.
func _notify(player: Node, text: String) -> void:
	if player != null and player.has_method("show_message"):
		player.show_message(text)
	else:
		print(text)


## Returns the prompt text configured for this interactable.
func get_prompt_text() -> String:
	return prompt_text


## Checks whether a non-empty message payload is configured.
func has_message() -> bool:
	return not message.is_empty()