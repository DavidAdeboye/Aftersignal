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
		_notify(player, _fallback_terminal_record())

func _fallback_terminal_record() -> String:
	var terminal_name := name.to_lower()
	if "power" in terminal_name or "generator" in terminal_name:
		return "POWER ROUTING RECORD\n\nContainment-door power is divided between two manual floor switches. Both inputs must remain active simultaneously.\n\nACTION: Regroup with your partner and occupy both pressure plates."
	if "hab" in terminal_name or "crew" in terminal_name:
		return "HABITATION AUDIT\n\nManifest count: 12. Constructed quarters: 11. Quarter 12 has no registered doorway or service conduit.\n\nACTION: Inspect the wall beyond Quarter 11 after opening storage."
	if "research" in terminal_name or "lab" in terminal_name:
		return "FARROW PROJECT INDEX\n\nThree records were removed from this terminal. A handwritten field note was issued before the storage lockdown.\n\nACTION: Find the notebook and follow its two-person override procedure."
	return "MAINTENANCE RELAY\n\nRemote credential display and sealed-door keypad are on separate circuits. Local keypad memory is intentionally blank.\n\nACTION: One player finds the access terminal and relays its code; the other enters it at the keypad."


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
