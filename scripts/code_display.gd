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
		player.show_reading_panel(label, "ACCESS CREDENTIAL\n\n" + code + "\n\nTEAM PROCEDURE\n1. Keep this terminal open.\n2. Tell your partner the four digits over voice/chat.\n3. Your partner enters the code at the sealed-door keypad.\n4. You both regroup at the newly opened storage door.")
	else:
		_notify(player, label + ":\n" + code)
