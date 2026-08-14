extends Interactable

## A readable audio/text log left behind by the research crew.
## Set the `message` export in the editor to change the log's contents;
## this override just ensures it always surfaces on the player's HUD.

func _ready() -> void:
	if message == "":
		message = "LOG — Day 47:\n\"The crystal growth has accelerated again. Whatever's below the ice isn't just reacting to us anymore. It's reaching back.\""
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to read log"


func interact(player: Node = null) -> void:
	_notify(player, message)
	if DialogManager.instance:
		DialogManager.instance.play_dialog("DR. FARROW LOG", message, 6.0)
	if ObjectiveManager.instance:
		ObjectiveManager.instance.set_objective("OBJECTIVE: Proceed through Research Labs Airlock")
