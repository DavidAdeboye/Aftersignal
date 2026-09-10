extends Interactable

## Displays an access code to the player who reads it. In co-op, one player
## finds this while the other stands at the matching keypad — they have to
## relay the code over the radio. This is the core "code-sharing" puzzle
## from the design doc's puzzle table.

@export var code: String = "4471"
@export var label: String = "DOOR ACCESS CODE"


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to read"


func interact(player: Node = null) -> void:
	PuzzleState.mark_act1_clue("access_code")
	if player and player.has_method("show_reading_panel"):
		player.show_reading_panel(label, "STORAGE CODE\n\n" + code + "\n\nTell your partner this code. They must enter it at the storage keypad.")
	else:
		_notify(player, label + ":\n" + code)
